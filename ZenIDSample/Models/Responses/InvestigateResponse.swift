//
//  InvestigateResponse.swift
//  ZenID Sample
//
//  Created by Vladimir Belohradsky on 13.12.2024.
//  Copyright © 2024 ZenID s.r.o. All rights reserved.
//

import Foundation
import CoreGraphics

// MARK: - ZenidWeb.InvestigateResponse
struct InvestigateResponse: Codable, Hashable {
    var investigationID: Int?
    var customData: String?
    var minedData: MineAllResult?
    var documentsData: [MineAllResult]?
    var investigationUrl: String?
    var rank: RankDetail?
    var time: String?
    var validatorResults: [InvestigationValidatorResponse]?
    var state: InvestigationState?
    var eDokladyTransaction: EDokladyTransactionResult?
    var errorCode: ErrorCode?
    var errorText: String?
    var processingTimeMs: Int?
    var messageType: String?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(investigationID)
    }
    
    static func == (lhs: InvestigateResponse, rhs: InvestigateResponse) -> Bool {
        lhs.investigationID == rhs.investigationID
    }
}

