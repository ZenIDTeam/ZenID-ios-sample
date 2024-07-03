//
//  SelfieViewModel.swift
//  ZenID Sample
//
//  Created by Vladimir Belohradsky on 13.12.2024.
//  Copyright © 2024 ZenID s.r.o. All rights reserved.
//


import Foundation
import RecogLib_iOS
import OSLog

@MainActor class SelfieViewModel: @preconcurrency SampleViewModel {
    
    @Published var state: ScanningState = .scanning
    
    var publishedState: Published<ScanningState>.Publisher { $state }
    
    var selfieController: SelfieController?
    
    func setup(cameraView: RecogLib_iOS.CameraView) {
        Task { @MainActor in
            guard await authorizeZenId() else { return } // See `SampleViewModel` extension.
            
            selfieController = SelfieController(camera: Camera(),
                                                view: cameraView,
                                                modelsUrl: URL.modelsFace)
            let configuration = SelfieControllerConfiguration(showVisualisation: true, showHelperVisualisation: true, showDebugVisualisation: false)
            _ = ZenidSecurity.selectProfile(name: Profile.current) // If not called then `Default` profile is used.
            selfieController?.delegate = self
            try? selfieController?.configure(configuration: configuration)
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
                        "expectedSampleType": "Selfie",
                        "fileName": "\(UUID().uuidString).jpg",
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

extension SelfieViewModel: SelfieControllerDelegate {
    
    /// This method is called when a selfie was captured.
    nonisolated func controller(_ controller: RecogLib_iOS.SelfieController, didScan result: RecogLib_iOS.SelfieResult) {
        guard result.selfieState == .Ok else { return }
        
        if let image = result.signature?.image, let signature = result.signature?.signature.data(using: .utf8) {
            Task { @MainActor in
                os_log(.info, "Selfie capture successfull")
                processResultData(image + signature)
            }
        }
    }
    
    /// Update UI based on verifier state inside `result` parameter.
    nonisolated func controller(_ controller: RecogLib_iOS.SelfieController, didUpdate result: RecogLib_iOS.SelfieResult) {}
}
