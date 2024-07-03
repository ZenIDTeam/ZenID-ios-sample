//
//  ProfilesResponse.swift
//  ZenID Sample
//
//  Created by Vladimir Belohradsky on 16.12.2024.
//  Copyright © 2024 ZenID s.r.o. All rights reserved.
//

import Foundation

struct ProfilesResponse: Codable {
    let results: [String]?
    let errorCode: ErrorCode?
    let errorText: String?
    let processingTimeMs: Int?
    let messageType: String?
}
