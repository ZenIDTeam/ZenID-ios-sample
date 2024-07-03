//
//  SampleViewModel.swift
//  ZenID Sample
//
//  Created by Vladimir Belohradsky on 13.12.2024.
//  Copyright © 2024 ZenID s.r.o. All rights reserved.
//

import Foundation
import RecogLib_iOS
import OSLog

protocol SampleViewModel {
        
    var publishedState: Published<ScanningState>.Publisher { get }
    
    func setup(cameraView: CameraView)
    
}

enum ScanningState {    
    case scanning
    case uploading
    case investigating
    case done(_ investigateResponse: InvestigateResponse)
}


extension SampleViewModel {
    
    func authorizeZenId() async -> Bool {
        guard let credentials = await Credentials.load(key: storageCredentials) else {
            os_log(.error, "Missing credentials")
            return false
        }
        do {
            let token = try await API.shared.authorize(url: credentials.url, apiKey: credentials.key)
            guard ZenidSecurity.authorize(responseToken: token) == true else {
                os_log(.debug, "Can't authorize")
                return false
            }
        } catch {
            os_log(.error, "Error retrieving token: \(error)")
            return false
        }
        os_log(.info, "Authorized")
        return true
    }
    
}
