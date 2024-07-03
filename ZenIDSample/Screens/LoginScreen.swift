//
//  LoginScreen.swift
//  ZenID Sample
//
//  Created by Vladimir Belohradsky on 02.12.2024.
//  Copyright © 2024 ZenID s.r.o. All rights reserved.
//

import SwiftUI

struct LoginScreen: View, IdentifiableScreen {
    
    let viewModel = LoginViewModel()
    
    @EnvironmentObject var navigationManager: NavigationManager
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                QRScanner { code in
                    let success = viewModel.processData(from: code)
                    if success {
                        navigationManager.pop()
                    }
                    return success
                }.frame(width: geo.size.width, height: geo.size.height)
                
                Image(systemName: "square.dashed")
                    .resizable()
                    .frame(width: 200, height: 200)
                    .scaledToFit()
                    .font(.system(size: 200, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.2))
            }
        }
        .navigationTitle("Login with QR")
    }
}

#Preview {
    LoginScreen()
}
