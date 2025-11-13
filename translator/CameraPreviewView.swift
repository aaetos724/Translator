//
//  CameraPreviewView.swift
//  translator
//
//  Created by Elisa Guadalupe Alejos Torres on 10/11/25.
//

import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var cameraManager: CameraManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        let previewLayer = AVCaptureVideoPreviewLayer()
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        context.coordinator.previewLayer = previewLayer
        context.coordinator.cameraManager = cameraManager
        
        // Configurar la sesión cuando esté disponible
        context.coordinator.updateSession()
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = context.coordinator.previewLayer {
            // Actualizar el frame
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            previewLayer.frame = uiView.bounds
            CATransaction.commit()
            
            // Actualizar la sesión si cambió
            context.coordinator.updateSession()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        var previewLayer: AVCaptureVideoPreviewLayer?
        weak var cameraManager: CameraManager?
        
        func updateSession() {
            guard let previewLayer = previewLayer,
                  let cameraManager = cameraManager else { return }
            
            // Si la sesión cambió, actualizarla
            if previewLayer.session != cameraManager.captureSession {
                if let session = cameraManager.captureSession {
                    DispatchQueue.main.async {
                        previewLayer.session = session
                    }
                }
            }
        }
    }
}


