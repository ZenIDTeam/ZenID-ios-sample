//
//  MainScreen.swift
//  ZenID Sample
//
//  Created by Vladimir Belohradsky on 02.12.2024.
//  Copyright © 2024 ZenID s.r.o. All rights reserved.
//

import SwiftUI

struct MainScreen: View, IdentifiableScreen {
    
    @State var serverTitle: String = "None"
    @State var profile: String = "Default"
    @State var country: String = "Cz"
    @State var role: String?
    @State var page: String?
    
    var body: some View {
        List {
            Section {
                OptionRow(title: "Server", value: serverTitle, systemImage: "qrcode.viewfinder", screen: .login)
                    .onAppear {
                        serverTitle = Credentials.load(key: storageCredentials)?.url.host ?? "Select server"
                    }
                OptionRow(title: "Profile", value: profile, systemImage: "document.badge.gearshape", screen: .profile)
                    .onAppear {
                        let currentProfile = Profile.current
                        profile = currentProfile == "" ? "Default" : currentProfile
                    }
            }
            Section(header: Text("Document scanner settings")) {
                OptionRow(title: "Country",
                          value: country,
                          systemImage: "globe.americas.fill",
                          screen: .pickCountry)
                OptionRow(title: "Role",
                          value: role,
                          systemImage: "questionmark.text.page",
                          screen: .pickRole)
                OptionRow(title: "Page",
                          value: page,
                          systemImage: "book.pages",
                          screen: .pickPage)
            }
            Section(header: Text("Verifiers"), footer: Text("version \(String.appVersion)")) {
                OptionRow(title: "Document scanning",
                          systemImage: "person.text.rectangle",
                          screen: .documentScanner)
                OptionRow(title: "Hologram checking",
                          systemImage: "creditcard.trianglebadge.exclamationmark",
                          screen: .hologramCheck)
                OptionRow(title: "Faceliveness",
                          systemImage: "person.and.arrow.left.and.arrow.right.outward",
                          screen: .facelivenessCheck)
                OptionRow(title: "Faceliveness legacy",
                          systemImage: "person.and.arrow.left.and.arrow.right.outward",
                          screen: .facelivenessLegacyCheck)
                OptionRow(title: "Selfie",
                          systemImage: "person",
                          screen: .selfieCheck)
            }
        }
        .navigationTitle("ZenID Sample")
        .onAppear {
            let config = DocumentConfiguration.load(key: storageConfiguration, defaultValue: DocumentConfiguration(country: .Cz))!
            country = "\(config.country)"
            role = config.role == nil ? "None" : "\(config.role!)"
            page = config.page == nil ? "None" : "\(config.page!)"
        }
    }
}

#Preview {
    MainScreen()
}
