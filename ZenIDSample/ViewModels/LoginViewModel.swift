//
//  LoginViewModel.swift
//  ZenID Sample
//
//  Created by Vladimir Belohradsky on 02.12.2024.
//  Copyright © 2024 ZenID s.r.o. All rights reserved.
//

import Foundation
import Combine

@MainActor class LoginViewModel {
    
    /// Process data from QR code.
    /// 
    /// - Parameter qrCode: QR code data as String.
    /// - Returns: `True` if QR code is valid.
    func processData(from qrCode: String) -> Bool {
        let data = qrCode.split(separator: " ")
        guard data.count == 2,
            let urlPath = data.first, //?.replacingOccurrences(of: "/api", with: ""),
            let url = URL(string: String(urlPath)),
              let key = data.last
        else {
            Haptics.shared.playError()
            return false
        }
        
        do {
            try Credentials(url: url, key: String(key)).save(key: storageCredentials)
        } catch {
            Haptics.shared.playError()
            return false
        }
        
        Haptics.shared.playSuccess()
        return true
    }
    
}
