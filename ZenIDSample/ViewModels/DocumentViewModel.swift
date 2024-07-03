//
//  DocumentViewModel.swift
//  ZenID Sample
//
//  Created by Vladimir Belohradsky on 13.12.2024.
//  Copyright © 2024 ZenID s.r.o. All rights reserved.
//

import Foundation
import RecogLib_iOS
import OSLog
import CoreNFC

@MainActor class DocumentViewModel: @preconcurrency SampleViewModel {
    
    @Published var state: ScanningState = .scanning
    
    private let config: DocumentConfiguration = .load(key: storageConfiguration, defaultValue: DocumentConfiguration(country: .Cz))!
    
    var publishedState: Published<ScanningState>.Publisher { $state }
    
    var documentController: DocumentController?
    
    func setup(cameraView: RecogLib_iOS.CameraView) {
        Task { @MainActor in
            guard await authorizeZenId() else { return } // See `SampleViewModel` extension.
            
            documentController = DocumentController(camera: Camera(),
                                                    view: cameraView,
                                                    modelsUrl: URL.modelsDocuments,
                                                    mrzModelsUrl: URL.mrzModels)
            let configuration = DocumentControllerConfiguration(showVisualisation: true,
                                                                showHelperVisualisation: true,
                                                                showDebugVisualisation: false,
                                                                dataType: .picture,
                                                                role: config.role,
                                                                country: config.country,
                                                                page: config.page,
                                                                code: nil,
                                                                documents: nil,
                                                                settings: nil)
            _ = ZenidSecurity.selectProfile(name: Profile.current) // If not called then `Default` profile is used.
            documentController?.delegate = self
            try? documentController?.configure(configuration: configuration)
        }
    }
    
    /// Process `Data` provided by verifier.
    ///
    /// In this sample application, data is uploaded to the ZenID service, and then it is called for an investigation.
    ///
    /// - Important: An investigation call can remain connected until the processing of sample(s) is complete.
    ///
    /// - Parameter data: Data to be processed.
    private func processResultData(_ data: Data) {
        let country = config.country.description
        let role = config.role?.description
        let page = config.page?.description
        let profile = Profile.current
        Task.detached {
            do {
                await MainActor.run {
                    os_log(.info, "Start uploading")
                    self.state = .uploading
                }
                let sample = try await API.shared.uploadSample(data: data, parameters: [
                        "expectedSampleType": "DocumentPicture",
                        "fileName": "\(UUID().uuidString).jpg",
                        "country": country,
                        "role": role ?? "",
                        "pageCode": page ?? "",
                        "profile": profile
                ])
                await MainActor.run {
                    os_log(.info, "Start investigating")
                    self.state = .investigating
                }
                let investigation = try await API.shared.investigate(samples: [sample])
                await MainActor.run {
                    os_log(.info, "Done!")
                    self.state = .done(investigation)
                }
            } catch {
                os_log(.error, "Upload sample problem: \(error.localizedDescription)")
            }
        }
    }
}

extension DocumentViewModel: DocumentControllerDelegate {
    
    /// This method is called when an nfc code was detected.
    ///
    /// - Important: To make NFC reading working you need also add NFC Tag reading support to `Entitlements` and add usage description and
    /// NFC document codes into `Info.plist`. Please see source code for those files in this project.
    nonisolated func controller(_ controller: RecogLib_iOS.DocumentController, didScan result: RecogLib_iOS.DocumentResult, nfcCode: String) {
        guard result.state == .Nfc else { return }
        let mrzKey = nfcCode
        
        Task { @MainActor [weak self]  in
            if NFCNDEFReaderSession.readingAvailable {
                os_log(.info, "Will read NFC")
                guard let self = self, let controller = self.documentController else { return }
                _ = controller.getNfcSettings()
                let nfcReader = NfcDocumentReader(mrzKey: mrzKey)
                do {
                    let nfcData = try await nfcReader.read()
                    //let nfcDocument = nfcData.document
                    let result = controller.processNfcResult(nfcData: nfcData, status: .Ok)
                    if let image = result?.signature?.image, let signature = result?.signature?.signature.data(using: .utf8, allowLossyConversion: false) {
                        os_log(.info, "NFC reading successfull")
                        processResultData(image + signature)
                    }
                } catch {
                    os_log(.error, "NFC reading failed: \(error.localizedDescription)")
                }
            } else {
                os_log(.error, "Device can't read NFC")
            }
        }
    }
    
    /// This method is called when an document without nfc code was scanned.
    nonisolated func controller(_ controller: RecogLib_iOS.DocumentController, didScan result: RecogLib_iOS.DocumentResult) {
        guard result.state == .Ok else { return }
        
        if let image = result.signature?.image, let signature = result.signature?.signature.data(using: .utf8) {
            Task { @MainActor in
                os_log(.info, "Document reading successfull")
                processResultData(image + signature)
            }
        }
    }
    
    /// This method is used only for hologram
    nonisolated func controller(_ controller: RecogLib_iOS.DocumentController, didRecord videoURL: URL) {}
    
    /// Update UI based on verifier state inside `result` parameter.
    nonisolated func controller(_ controller: RecogLib_iOS.DocumentController, didUpdate result: RecogLib_iOS.DocumentResult) {}
    
}
