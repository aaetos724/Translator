//
//  SignLanguageModel.swift
//  translator
//
//  Created by Elisa Guadalupe Alejos Torres on 10/11/25.
//

import Foundation
import SwiftUI
import Combine

/// Modelo para manejar la traducción de texto a imágenes de lengua de signos
class SignLanguageTranslator: ObservableObject {
    @Published var translatedSigns: [String] = []
    @Published var currentSignIndex: Int = -1
    @Published var isAnimating: Bool = false
    
    private var animationTask: DispatchWorkItem?
    
    /// Traduce un texto a una secuencia de letras y números para mostrar sus señales
    /// - Parameter text: El texto a traducir
    func translate(_ text: String) {
        // Detener cualquier animación en curso
        stopAnimation()
        
        // Convertir el texto a mayúsculas
        let uppercaseText = text.uppercased()
        
        // Filtrar letras (A-Z) y números (1-9)
        let characters = uppercaseText.filter { character in
            character.isLetter || (character.isNumber && character != "0")
        }
        
        // Convertir cada carácter en su nombre de imagen correspondiente
        translatedSigns = characters.map { String($0) }
        currentSignIndex = -1
        
        // Iniciar animación secuencial si hay caracteres
        if !translatedSigns.isEmpty {
            startSequentialAnimation()
        }
    }
    
    /// Inicia la animación secuencial de las señales
    private func startSequentialAnimation() {
        isAnimating = true
        currentSignIndex = -1
        
        // Mostrar la primera imagen después de un breve delay
        let firstTask = DispatchWorkItem { [weak self] in
            guard let self = self, !self.translatedSigns.isEmpty else { return }
            self.currentSignIndex = 0
            self.continueAnimation()
        }
        animationTask = firstTask
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: firstTask)
    }
    
    /// Continúa la animación mostrando la siguiente imagen
    private func continueAnimation() {
        guard currentSignIndex < translatedSigns.count - 1 else {
            // Animación completada
            isAnimating = false
            return
        }
        
        // Esperar antes de mostrar la siguiente imagen
        // La animación fade es de 0.5s (0.4-0.6s como se solicitó)
        // Después del fade out/in completo, hay un pequeño delay antes de la siguiente
        // Total: ~1.2s entre cambios (fade out 0.5s + delay 0.2s + fade in 0.5s)
        let nextTask = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.currentSignIndex += 1
            self.continueAnimation()
        }
        animationTask = nextTask
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: nextTask)
    }
    
    /// Detiene la animación en curso
    func stopAnimation() {
        animationTask?.cancel()
        animationTask = nil
        isAnimating = false
        currentSignIndex = -1
    }
    
    /// Limpia todas las traducciones
    func clear() {
        stopAnimation()
        translatedSigns = []
        currentSignIndex = -1
    }
    
    /// Obtiene el nombre de la imagen para una letra o número específico
    /// - Parameter character: La letra (A-Z) o número (1-9)
    /// - Returns: El nombre de la imagen en Assets (ej: "A", "B", "1", "2")
    static func imageName(for character: String) -> String {
        let uppercaseCharacter = character.uppercased()
        // Las imágenes en Assets tienen el nombre directo de la letra/número en mayúsculas
        return uppercaseCharacter
    }
    
    /// Obtiene el carácter actual que se está mostrando
    var currentCharacter: String? {
        guard currentSignIndex >= 0 && currentSignIndex < translatedSigns.count else {
            return nil
        }
        return translatedSigns[currentSignIndex]
    }
}

/// Estructura para representar una señal de lengua de signos
struct SignImage: Identifiable {
    let id = UUID()
    let character: String
    let imageName: String
    
    init(character: String) {
        self.character = character.uppercased()
        self.imageName = SignLanguageTranslator.imageName(for: character)
    }
}

