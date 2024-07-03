//
//  UploadSampleResponse.swift
//  ZenID Sample
//
//  Created by Vladimir Belohradsky on 13.12.2024.
//  Copyright © 2024 ZenID s.r.o. All rights reserved.
//

import Foundation
import CoreGraphics

// MARK: - ZenidWeb.UploadSampleResponse
struct UploadSampleResponse: Codable {
    var sampleID: String?
    var customData: String?
    var uploadSessionID: String?
    var sampleType: SampleType?
    var minedData: MineAllResult?
    var rawFieldsOcr: [FieldOcrResult]?
    var state: SampleState?
    var projectedImage: Hash?
    var parentSampleID: String?
    var anonymizedImage: Hash?
    var imageUrlFormat: String?
    var imagePageCount: Int?
    var documentOutlineInOriginalImage: [PointF]?
    var subsamples: [UploadSampleResponse]?
    var uploadTime: String?
    var errorCode: ErrorCode?
    var errorText: String?
    var processingTimeMs: Int?
    var messageType: String?
}
