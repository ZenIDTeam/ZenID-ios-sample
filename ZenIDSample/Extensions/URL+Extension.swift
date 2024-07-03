//
//  URL+Extension.swift
//  ZenID Sample
//
//  Created by Vladimir Belohradsky on 15.12.2024.
//  Copyright © 2024 ZenID s.r.o. All rights reserved.
//

import Foundation

extension URL {
    static let modelsFolder = Bundle.main.bundleURL.appendingPathComponent("Models")
    static let modelsDocuments = modelsFolder.appendingPathComponent("documents")
    static let modelsFace = modelsFolder.appendingPathComponent("face")
    static let mrzModels = modelsFolder.appendingPathComponent("mrz")
}
