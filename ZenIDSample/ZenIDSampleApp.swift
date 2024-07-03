//
//  ZenID_SampleApp.swift
//  ZenID Sample
//
//  Created by Vladimir Belohradsky on 02.12.2024.
//  Copyright © 2024 ZenID s.r.o. All rights reserved.
//

import SwiftUI
import OSLog

let storageCredentials = "zenid.sample.credentials"
let storageConfiguration = "zenid.sample.configuration"

@main
struct ZenIDSampleApp: App {
        
    @StateObject var navigationManager = NavigationManager()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $navigationManager.path) {
                MainScreen()
                .navigationDestination(for: Screen.self) { screen in
                    switch screen {
                    case .login:
                        LoginScreen()
                    case .profile:
                        PickerScreen(viewModel: PickerViewModel(configurationValue: .profile))
                    case .pickCountry:
                        PickerScreen(viewModel: PickerViewModel(configurationValue: .country))
                    case .pickRole:
                        PickerScreen(viewModel: PickerViewModel(configurationValue: .role))
                    case .pickPage:
                        PickerScreen(viewModel: PickerViewModel(configurationValue: .page))
                    case .documentScanner:
                        SampleScreen(viewModel: DocumentViewModel())
                    case .hologramCheck:
                        SampleScreen(viewModel: HologramViewModel())
                    case .facelivenessCheck:
                        SampleScreen(viewModel: FacelivenessViewModel())
                    case .facelivenessLegacyCheck:
                        SampleScreen(viewModel: FacelivenessViewModel(isLegacy: true))
                    case .selfieCheck:
                        SampleScreen(viewModel: SelfieViewModel())
                    case .result(let investigateResponse):
                        ResultScreen(investigation: investigateResponse)
                    }
                }
            }
            .environmentObject(navigationManager)
        }
    }
    
}
