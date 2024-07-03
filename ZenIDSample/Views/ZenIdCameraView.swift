//
//  ZenIdCameraView.swift
//  ZenID Sample
//
//  Created by Vladimir Belohradsky on 13.12.2024.
//  Copyright © 2024 ZenID s.r.o. All rights reserved.
//

import SwiftUI
import RecogLib_iOS

struct ZenIdCameraView: UIViewRepresentable {

    let cameraView = CameraView()
    
    func makeUIView(context: Context) -> some UIView {
        return cameraView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
    
}
