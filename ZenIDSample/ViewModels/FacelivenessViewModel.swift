//
//  FacelivenessViewModel.swift
//  ZenID Sample
//
//  Created by Vladimir Belohradsky on 13.12.2024.
//  Copyright © 2024 ZenID s.r.o. All rights reserved.
//

import Foundation
import RecogLib_iOS
import OSLog

@MainActor class FacelivenessViewModel: @preconcurrency SampleViewModel {
    
    @Published var state: ScanningState = .scanning
    
    var publishedState: Published<ScanningState>.Publisher { $state }
    
    let isLegacy: Bool
    
    init (isLegacy: Bool = false) {
        self.isLegacy = isLegacy
    }
    
    var facelivenessController: FacelivenessController?
    
    func setup(cameraView: RecogLib_iOS.CameraView) {
        Task { @MainActor in
            guard await authorizeZenId() else { return } // See `SampleViewModel` extension.
            
            facelivenessController = FacelivenessController(camera: Camera(),
                                                            view: cameraView,
                                                            modelsUrl: URL.modelsFace)
            let configuration = FacelivenessControllerConfiguration(showVisualisation: true,
                                                                    showHelperVisualisation: true,
                                                                    showDebugVisualisation: false,
                                                                    dataType: .video,
                                                                    settings: .init(isLegacyModeEnabled: isLegacy))
            _ = ZenidSecurity.selectProfile(name: Profile.current) // If not called then `Default` profile is used.
            facelivenessController?.delegate = self
            try? facelivenessController?.configure(configuration: configuration)
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
                        "expectedSampleType": "SelfieVideo",
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

extension FacelivenessViewModel:FacelivenessControllerDelegate {
    
    nonisolated func controller(_ controller: RecogLib_iOS.FacelivenessController, didScan result: RecogLib_iOS.FaceLivenessResult) {}
    
    nonisolated func controller(_ controller: RecogLib_iOS.FacelivenessController, didRecord videoURL: URL, result: RecogLib_iOS.FaceLivenessResult) {
        do {
            let data = try Data(contentsOf: videoURL)
            Task { @MainActor in
                processResultData(data)
            }
        } catch {
            os_log(.error, "Can't read hologram video file: \(error)")
        }
    }
    
    nonisolated func controller(_ controller: RecogLib_iOS.FacelivenessController, didUpdate result: RecogLib_iOS.FaceLivenessResult) {}
    
}
