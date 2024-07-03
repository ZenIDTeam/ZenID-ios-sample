//
//  API.swift
//  ZenID Sample
//
//  Created by Vladimir Belohradsky on 02.12.2024.
//  Copyright © 2024 ZenID s.r.o. All rights reserved.
//

import Foundation
import RecogLib_iOS
import OSLog

/// ZenID API service.
actor API {
    
    static var shared: API = .init()
    
    private var urlSession = {
        var configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 600
        configuration.timeoutIntervalForResource = 600
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return URLSession(configuration: configuration)
    }()
    
    private var url: URL?
    
    /// Authorize with ZenID API.
    ///
    /// get /api/initSdk
    ///
    /// - Important: Add your app bundle ID to the allowed iOS apps on the ZenID server configuration to avoid authentication failure.
    ///
    /// - Parameters:
    ///   - url: Server URL.
    ///   - apiKey: Service key.
    func authorize(url: URL, apiKey: String) async throws -> String {
        self.url = url
        guard let challengeToken = ZenidSecurity.getChallengeToken() else { throw ZenIDAPIError.cantGetChallengeToken }
        guard var components = URLComponents(url: url.appendingPathComponent("initSdk"), resolvingAgainstBaseURL: false) else { throw ZenIDAPIError.missingUrl }
        components.queryItems = [URLQueryItem(name: "token", value: challengeToken)]
        guard let initURL = components.url else { throw ZenIDAPIError.missingUrl }
        if let cookie = HTTPCookie(properties: [
            HTTPCookiePropertyKey.name : "api_key",
            HTTPCookiePropertyKey.value : apiKey,
            HTTPCookiePropertyKey.originURL : url,
            HTTPCookiePropertyKey.path : url.path
        ]) {
            urlSession.configuration.httpCookieStorage?.setCookie(cookie)
        }
        
        var request = URLRequest(url: initURL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("0", forHTTPHeaderField: "Content-Length")
        
        let (data, _) = try await urlSession.data(for: request)
        //let (data, _) = try await urlSession.data(from: initURL)
        let initSdkResponse = try JSONDecoder.zenid.decode(InitSdkResponse.self, from: data)
        os_log(.debug, "Response: \(initSdkResponse.response!)")
        return initSdkResponse.response!
    }
    
    /// Upload Sample.
    ///
    /// post /api/sample
    ///
    /// - Parameters:
    ///   - data: Sample data + signature.
    func uploadSample(data: Data, parameters: [String : String]) async throws -> UploadSampleResponse {
        guard ZenidSecurity.isAuthorized() else { throw ZenIDAPIError.notAuthorized }
        guard let url else { throw ZenIDAPIError.missingUrl }
        
        guard var components = URLComponents(url: url.appendingPathComponent("sample"), resolvingAgainstBaseURL: false) else { throw ZenIDAPIError.missingUrl }
        components.queryItems = parameters.map({ (key: String, value: String) in URLQueryItem(name: key, value: value) })
        guard let requestURL = components.url else { throw ZenIDAPIError.missingUrl }
        
        var request = URLRequest(url: requestURL)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.httpMethod = "POST"
        request.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        
        let (data, _) = try await urlSession.data(for: request)
        let output = String(data: data, encoding: .utf8)!
        os_log(.info, "Output: \(output)")
        return try JSONDecoder.zenid.decode(UploadSampleResponse.self, from: data)
    }
    
    /// Investigate list of Samples.
    ///
    /// get /api/investigateSamples
    ///
    /// - Parameter samples: List of Samples.
    /// - Returns: Investigation overview.
    func investigate(samples: [UploadSampleResponse]) async throws -> InvestigateResponse {
        return try await investigate(identifiers: samples.compactMap { $0.sampleID })
    }
    
    /// Investigate list of Sample identifiers.
    ///
    /// get /api/investigateSamples
    ///
    /// - Parameter identifiers: List of sample identifiers.
    /// - Returns: Investigation overview.
    func investigate(identifiers: [String]) async throws -> InvestigateResponse {
        guard ZenidSecurity.isAuthorized() else { throw ZenIDAPIError.notAuthorized }
        guard !identifiers.isEmpty else { throw ZenIDAPIError.emptyInvestigation }
        guard let url else { throw ZenIDAPIError.missingUrl }
        guard var components = URLComponents(url: url.appendingPathComponent("investigateSamples"), resolvingAgainstBaseURL: false) else { throw ZenIDAPIError.missingUrl }
        let sampleIDs = identifiers.joined(separator: ",")
        components.queryItems = [URLQueryItem(name: "sampleIDs", value: sampleIDs)]
        guard let investigateUrl = components.url else { throw ZenIDAPIError.missingUrl }
        
        let (data, _) = try await urlSession.data(from: investigateUrl)
        
        return try JSONDecoder.zenid.decode(InvestigateResponse.self, from: data)
    }
    
    /// Retrieve list of verifier profiles.
    ///
    /// get /api/profiles
    ///
    /// - Returns: List of profile names.
    func listProfiles() async throws -> [String] {
        guard ZenidSecurity.isAuthorized() else { throw ZenIDAPIError.notAuthorized }
        
        guard let url else { throw ZenIDAPIError.missingUrl }
        let profilesUrl = url.appendingPathComponent("profiles")
        
        let (data, _) = try await urlSession.data(from: profilesUrl)        
        
        return try JSONDecoder.zenid.decode(ProfilesResponse.self, from: data).results ?? []
    }
    
}

/// List of possible API errors.
enum ZenIDAPIError: Error {

    /// Can't get challenge token.
    case cantGetChallengeToken
    
    /// Missing or invalid token.
    case notAuthorized
    
    /// At least one sample needs to be investigated.
    case emptyInvestigation
    
    /// Url is missing.
    case missingUrl
}
