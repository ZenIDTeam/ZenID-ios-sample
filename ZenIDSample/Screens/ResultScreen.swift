//
//  ResultScreen.swift
//  ZenID Sample
//
//  Created by Vladimir Belohradsky on 16.12.2024.
//  Copyright © 2024 ZenID s.r.o. All rights reserved.
//

import SwiftUI

struct ResultScreen: View {
    
    @EnvironmentObject var navigationManager: NavigationManager
    
    let investigation: InvestigateResponse
    
    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading) {
                    let text = "\(investigation)".replacingOccurrences(of: "Optional", with: "")
                    Text(text)
                        .padding()
                }
                .frame(maxWidth: .infinity)
                .background(.secondary.opacity(0.2))
                .clipShape(RoundedRectangle(cornerSize: CGSize(width: 20, height: 5)))
                .padding()
            }
            Spacer()
            Button {
                navigationManager.pop(steps: 2)
            } label: {
                Text("Close")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
        }
        .navigationTitle("Investigation")
    }
    
}

#Preview {
    ResultScreen(investigation: InvestigateResponse(investigationID: 123456789))
}
