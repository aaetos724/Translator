//
//  TextToSignView.swift
//  translator
//
//  Created by Elisa Guadalupe Alejos Torres on 10/11/25.
//

import SwiftUI

struct TextToSignView: View {
    @StateObject private var translator = SignLanguageTranslator()
    @State private var inputText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var translationTask: DispatchWorkItem?
    
    var body: some View {
        VStack(spacing: 0) {
            // Título "Translate" con estilo Large Title
            VStack(alignment: .leading, spacing: 0) {
                Text("Translate")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            
            // Contenedor principal con dos cuadros
            VStack(spacing: 0) {
                    // Primer Cuadro: Input (English)
                    VStack(alignment: .leading, spacing: 8) {
                        // Encabezado pequeño
                        Text("English")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                        
                        // Área de texto con botón de limpiar
                        ZStack(alignment: .topTrailing) {
                            // TextEditor con placeholder
                            ZStack(alignment: .topLeading) {
                                if inputText.isEmpty {
                                    Text("Enter text to translate...")
                                        .font(.body)
                                        .foregroundColor(Color(.placeholderText))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 20)
                                        .allowsHitTesting(false)
                                }
                                
                                TextEditor(text: $inputText)
                                    .font(.body)
                                    .padding(8)
                                    .frame(minHeight: 120)
                                    .background(Color.clear)
                                    .scrollContentBackground(.hidden)
                                    .focused($isTextFieldFocused)
                            }
                            
                            // Botón de limpiar (X)
                            if !inputText.isEmpty {
                                Button(action: clearText) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.secondary)
                                        .background(Color(.systemGray6))
                                        .clipShape(Circle())
                                }
                                .padding(12)
                                .padding(.top, 12)
                            }
                        }
                        .onChange(of: inputText) { oldValue, newValue in
                            // Cancelar traducción anterior si existe
                            translationTask?.cancel()
                            
                            // Si el texto está vacío, limpiar traducción
                            if newValue.isEmpty {
                                translator.clear()
                                return
                            }
                            
                            // Programar traducción después de un breve delay
                            let task = DispatchWorkItem {
                                translateText()
                            }
                            translationTask = task
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task)
                        }
                    }
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 0.5)
                    )
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    
                    // Segundo Cuadro: Output (Hand Sign Language)
                    VStack(alignment: .leading, spacing: 8) {
                        // Encabezado pequeño
                        Text("Hand Sign Language")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                        
                        // Área de visualización de señales
                        ZStack {
                            // Fondo del cuadro
                            Color(.systemBackground)
                            
                            if translator.translatedSigns.isEmpty {
                                // Estado vacío
                                VStack(spacing: 12) {
                                    Image(systemName: "hand.raised.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(Color(.systemGray4))
                                    Text("Translation will appear here")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .frame(minHeight: 200)
                            } else {
                                // Visualización secuencial con animación
                                SequentialSignView(translator: translator)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .frame(minHeight: 200)
                                    .padding(16)
                            }
                        }
                        .frame(minHeight: 200)
                    }
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 0.5)
                    )
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 20)
            
            Spacer()
        }
        .background(Color(.systemBackground))
    }
    
    private func translateText() {
        // Traducir solo si hay texto
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            translator.clear()
            return
        }
        translator.translate(inputText)
    }
    
    private func clearText() {
        translationTask?.cancel()
        inputText = ""
        translator.clear()
        isTextFieldFocused = false
    }
}

