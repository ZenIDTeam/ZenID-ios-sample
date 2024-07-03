//
//  HologramViewModel.swift
//  ZenID Sample
//
//  Created by Vladimir Belohradsky on 13.12.2024.
//  Copyright © 2024 ZenID s.r.o. All rights reserved.
//

import Foundation
import RecogLib_iOS
import OSLog

@MainActor class HologramViewModel: @preconcurrency SampleViewModel {
    
    @Published var state: ScanningState = .scanning
    
    var publishedState: Published<ScanningState>.Publisher { $state }
    
    var documentController: DocumentController?
    
    func setup(cameraView: RecogLib_iOS.CameraView) {
        Task {
            guard await authorizeZenId() else { return } // See `SampleViewModel` extension.
            
            documentController = DocumentController(camera: Camera(),
                                                    view: cameraView,
                                                    modelsUrl: URL.modelsDocuments,
                                                    mrzModelsUrl: URL.mrzModels)
            let configuration = DocumentControllerConfiguration(showVisualisation: true,
                                                                showHelperVisualisation: true,
                                                                showDebugVisualisation: false,
                                                                dataType: .video,
                                                                role: nil,
                                                                country: nil,
                                                                page: nil,
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
        let profile = Profile.current
        
        Task.detached {
            do {
                await MainActor.run {
                    os_log(.info, "Start uploading")
                    self.state = .uploading
                }
                let sample = try await API.shared.uploadSample(data: data, parameters: [
                        "expectedSampleType": "DocumentVideo",
                        "fileName": "\(UUID().uuidString).mp4",
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

extension HologramViewModel: DocumentControllerDelegate {
    
    /// This method is called when an nfc code was detected.
    nonisolated func controller(_ controller: RecogLib_iOS.DocumentController, didScan result: RecogLib_iOS.DocumentResult, nfcCode: String) {}
    
    /// This method is called when an document without nfc code was scanned.
    nonisolated func controller(_ controller: RecogLib_iOS.DocumentController, didScan result: RecogLib_iOS.DocumentResult) {}
    
    /// This method is used only for hologram
    nonisolated func controller(_ controller: RecogLib_iOS.DocumentController, didRecord videoURL: URL) {
        do {
            let data = try Data(contentsOf: videoURL)
            Task { @MainActor in
                processResultData(data)
            }
        } catch {
            os_log(.error, "Can't read hologram video file: \(error)")
        }
    }
    
    /// Update UI based on verifier state inside `result` parameter.
    nonisolated func controller(_ controller: RecogLib_iOS.DocumentController, didUpdate result: RecogLib_iOS.DocumentResult) {}
    
}
