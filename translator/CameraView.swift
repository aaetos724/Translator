//
//  CameraView.swift
//  translator
//
//  Created by Elisa Guadalupe Alejos Torres on 10/11/25.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    
    var body: some View {
        ZStack {
            if cameraManager.isAuthorized {
                // Vista de la cámara
                CameraPreviewView(cameraManager: cameraManager)
                    .ignoresSafeArea()
                
                // Superposición de texto en la parte inferior
                VStack {
                    Spacer()
                    
                    // Banner translúcido para el texto traducido
                    if !cameraManager.translatedText.isEmpty {
                        VStack(spacing: 8) {
                            Text(cameraManager.translatedText)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                        }
                        .frame(maxWidth: .infinity)
                        .background(
                            .ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.easeInOut, value: cameraManager.translatedText)
            } else {
                // Estado de error o sin permisos
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    
                    if let errorMessage = cameraManager.errorMessage {
                        Text(errorMessage)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    } else {
                        Text("Camera access is required")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Button("Grant Permission") {
                        cameraManager.checkPermission()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .onAppear {
            cameraManager.checkPermission()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
}

#Preview {
    CameraView()
}

