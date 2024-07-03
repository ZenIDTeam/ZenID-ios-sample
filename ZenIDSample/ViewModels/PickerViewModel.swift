//
//  PickerViewModel.swift
//  ZenID Sample
//
//  Created by Vladimir Belohradsky on 17.12.2024.
//  Copyright © 2024 ZenID s.r.o. All rights reserved.
//

import Foundation
import OSLog
import RecogLib_iOS
import Combine

@MainActor class PickerViewModel: ObservableObject {
    
    @Published var state: State = .loading
    
    @Published var options: [String] = []
    
    @Published var selectedOption: String = ""
    
    private var config: DocumentConfiguration = .load(key: storageConfiguration, defaultValue: DocumentConfiguration(country: .Cz))!
    
    let configurationValue: ConfigurationValue
    
    var title: String {
        switch configurationValue {
        case .profile: "Profile"
        case .country: "Country"
        case .role: "Role"
        case .page: "Page"
        }
    }
    
    init(configurationValue: ConfigurationValue) {
        self.configurationValue = configurationValue
        Task { @MainActor in
            guard await authorizeZenId() else {
                state = .failure
                return
            }
            switch configurationValue {
            case .profile:
                self.options = try await API.shared.listProfiles()
                self.selectedOption = Profile.current
            case .country:
                self.options = ZenidSecurity.supportedCountries()?.map({ "\($0)" }) ?? []
                self.selectedOption = "\(config.country)"
            case .role:
                self.options = ZenidSecurity.supportedDocuments(for: config.country)?.map({ "\($0)" }) ?? []
                if let role = config.role {
                    self.selectedOption = "\(role)"
                }
            case .page:
                if let role = config.role {
                    self.options = ZenidSecurity
                        .supportedDocumentPageCodes(for: config.country, documentRole: role)?
                        .sorted(by: { $0.rawValue < $1.rawValue })
                        .map({ "\($0)" }) ?? []
                    if let page = config.page {
                        self.selectedOption = "\(page)"
                    }
                }
                
            }
            os_log(.error, "Options loaded")
            state = .done
        }
    }
    
    func selectOption(_ option: String) {
        selectedOption = option
        switch self.configurationValue {
        case .profile:
            Profile.current = option
        case .country:
            config.country = ZenidSecurity.supportedCountries()?.first(where: { "\($0)" == option }) ?? .Cz
            config.role = nil
            config.page = nil
        case .role:
            config.role = ZenidSecurity.supportedDocuments(for: config.country)?.first(where: { "\($0)" == option })
            if config.role == nil {
                config.page = nil
            } else {
                config.page = ZenidSecurity.supportedDocumentPageCodes(for: config.country, documentRole: config.role!)?.sorted(by: { $0.rawValue < $1.rawValue }).first
            }
        case .page:
            if let role = config.role {
                config.page = ZenidSecurity.supportedDocumentPageCodes(for: config.country, documentRole: role)?.first(where: { "\($0)" == option })
            }
        }
        do {
            try config.save(key: storageConfiguration)
        } catch {
            os_log(.error, "Can't save configuration: \(error)")
        }
    }
    
    func authorizeZenId() async -> Bool {
        guard let credentials = Credentials.load(key: storageCredentials) else {
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
    
    enum State {
        case loading
        case failure
        case done
    }
    
    enum ConfigurationValue {
        case profile
        case country
        case role
        case page
    }
}
