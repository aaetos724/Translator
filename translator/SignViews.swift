//
//  SignViews.swift
//  translator
//
//  Created by Elisa Guadalupe Alejos Torres on 10/11/25.
//

import SwiftUI
import UIKit

/// Vista para mostrar la secuencia de señales con animación fade
struct SequentialSignView: View {
    @ObservedObject var translator: SignLanguageTranslator
    @State private var displayedCharacter: String?
    @State private var opacity: Double = 1.0
    @State private var previousIndex: Int = -1
    
    var body: some View {
        ZStack {
            if let character = displayedCharacter {
                SignImageView(character: character)
                    .opacity(opacity)
                    .transition(.opacity)
            } else if !translator.translatedSigns.isEmpty, 
                      !translator.isAnimating,
                      let lastCharacter = translator.translatedSigns.last {
                // Mostrar la última imagen si hay traducciones pero no hay animación activa
                SignImageView(character: lastCharacter)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: displayedCharacter)
        .animation(.easeInOut(duration: 0.5), value: opacity)
        .onChange(of: translator.currentSignIndex) { oldValue, newValue in
            handleIndexChange(newValue)
        }
        .onAppear {
            // Inicializar cuando aparece la vista
            if translator.currentSignIndex >= 0,
               translator.currentSignIndex < translator.translatedSigns.count {
                let character = translator.translatedSigns[translator.currentSignIndex]
                displayedCharacter = character
                opacity = 1.0
                previousIndex = translator.currentSignIndex
            }
        }
    }
    
    private func handleIndexChange(_ newIndex: Int) {
        // Si el índice es -1, limpiar la vista
        if newIndex < 0 {
            withAnimation(.easeInOut(duration: 0.3)) {
                opacity = 0.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                displayedCharacter = nil
                previousIndex = -1
            }
            return
        }
        
        guard newIndex < translator.translatedSigns.count else {
            return
        }
        
        let newCharacter = translator.translatedSigns[newIndex]
        
        // Si es la primera vez o cambió el índice
        if previousIndex != newIndex {
            // Si ya hay un carácter mostrado, hacer fade out primero
            if displayedCharacter != nil {
                // Fade out con duración de 0.5 segundos (rango 0.4-0.6s como se solicitó)
                withAnimation(.easeInOut(duration: 0.5)) {
                    opacity = 0.0
                }
                
                // Después de fade out, cambiar caracter y fade in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    displayedCharacter = newCharacter
                    previousIndex = newIndex
                    
                    // Fade in con duración de 0.5 segundos
                    withAnimation(.easeInOut(duration: 0.5)) {
                        opacity = 1.0
                    }
                }
            } else {
                // Primera vez, mostrar directamente con fade in
                displayedCharacter = newCharacter
                previousIndex = newIndex
                withAnimation(.easeInOut(duration: 0.5)) {
                    opacity = 1.0
                }
            }
        }
    }
}

/// Vista para mostrar una imagen de señal de lengua de signos individual
struct SignImageView: View {
    let character: String
    private let imageName: String
    @State private var imageExists: Bool = false
    
    init(character: String) {
        self.character = character.uppercased()
        self.imageName = SignLanguageTranslator.imageName(for: character)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Imagen de la señal o placeholder
            Group {
                if imageExists {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    // Placeholder cuando la imagen no existe
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                        VStack(spacing: 8) {
                            Image(systemName: "hand.raised.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            Text(character)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: 200, maxHeight: 200)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            
            // Carácter correspondiente (letra o número)
            Text(character)
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            checkImageExists()
        }
    }
    
    private func checkImageExists() {
        // Verificar si la imagen existe en el bundle
        if UIImage(named: imageName) != nil {
            imageExists = true
        }
    }
}

