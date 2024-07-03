//
//  SampleScreen.swift
//  ZenID Sample
//
//  Created by Vladimir Belohradsky on 13.12.2024.
//  Copyright © 2024 ZenID s.r.o. All rights reserved.
//

import SwiftUI

struct SampleScreen: View, IdentifiableScreen {
    
    @EnvironmentObject var navigationManager: NavigationManager
        
    var viewModel: SampleViewModel
    
    let cameraView = ZenIdCameraView()
    
    @State var state: ScanningState = .scanning
    
    var body: some View {
        ZStack {
            cameraView
            switch state {
            case .uploading:
                WaitView(title: "Uploading...", icon: "icloud.and.arrow.up")
            case .investigating:
                WaitView(title: "Investigating...", icon: "mail.and.text.magnifyingglass")
            case .done(_):
                WaitView(title: "Done!", icon: "checkmark.circle")
            default: Spacer()
            }
        }
        .onAppear {
            viewModel.setup(cameraView: cameraView.cameraView)
        }
        .onReceive(viewModel.publishedState) { value in
            withAnimation {
                state = value
            }
            switch value {
            case .done(let investigateResult):
                navigationManager.navigate(to: Screen.result(investigateResult))
            default: break
            }
        }
    }
}
