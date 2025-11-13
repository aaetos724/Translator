import Foundation
import AVFoundation
import UIKit
import CoreML
import Vision
import Combine // Importado para @Published y ObservableObject
import CoreML

// La clase principal ahora gestiona la detección de pose y la clasificación ML.
class CameraManager: NSObject, ObservableObject {
    
    // Propiedades de SwiftUI (hilo principal)
    @Published var translatedText: String = ""
    @Published var isAuthorized: Bool = false
    @Published var errorMessage: String?
    
    // Configuración de captura y concurrencia
    var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    let sessionQueue = DispatchQueue(label: "camera.session.queue")
    // Usamos una cola separada para la inferencia, por eso es safe usar @preconcurrency
    private let processingQueue = DispatchQueue(label: "camera.processing.queue")
    
    // Modelo Core ML (se usa directamente para clasificar los keypoints)
    private var mlModel: MLModel?
    
    // Propiedades de estabilización y Throttling (ajustables)
    private var predictionBuffer: [String] = []
    private let bufferSize = 10 // Aumentado para mayor estabilidad
    private var stablePrediction: String = ""
    private var lastUpdateTime: Date = Date()
    private let updateThreshold: TimeInterval = 0.5
    
    private var lastRecognitionTime: Date = Date()
    private let recognitionInterval: TimeInterval = 0.1 // 10 FPS
    private var isProcessing: Bool = false
    private let minimumConfidence: Float = 0.6 // Nivel de confianza razonable para la detección
    
    override init() {
        super.init()
        loadCoreMLModel()
        setupCamera()
    }
    
    // Cambiado el nombre para reflejar que se carga el MLModel para el clasificador de pose
    private func loadCoreMLModel() {
        do {
            // Cargar la clase generada por Core ML directamente
            let model = try HandPoseClassifier(configuration: MLModelConfiguration())
            self.mlModel = model.model
            print("✅ Modelo Core ML 'HandPoseClassifier' cargado correctamente")
        } catch {
            print("❌ Error al cargar el modelo Core ML 'HandPoseClassifier': \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.errorMessage = "Error al cargar el modelo de reconocimiento. Verifica que 'HandPoseClassifier.mlmodel' esté agregado al proyecto."
            }
        }
    }
    
    // MARK: - Permisos y Configuración de Cámara
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async { self.isAuthorized = true }
            if captureSession == nil { setupCamera() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { self.startSession() }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                    if granted {
                        if self.captureSession == nil { self.setupCamera() }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { self.startSession() }
                    } else {
                        self.errorMessage = "Camera access is required for sign language recognition"
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.isAuthorized = false
                self.errorMessage = "Camera access denied. Please enable it in Settings."
            }
        @unknown default:
            DispatchQueue.main.async {
                self.isAuthorized = false
                self.errorMessage = "Unknown camera authorization status"
            }
        }
    }
    
    private func setupCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let session = AVCaptureSession()
            session.sessionPreset = .high
            
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) ??
                                    AVCaptureDevice.default(for: .video) else {
                DispatchQueue.main.async { self.errorMessage = "Camera not available" }
                return
            }
            
            do {
                let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                if session.canAddInput(videoInput) { session.addInput(videoInput) }
                
                let output = AVCaptureVideoDataOutput()
                // El formato de 32BGRA es estándar para iOS/Vision
                output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
                // Establecemos el delegado en la cola de procesamiento
                output.setSampleBufferDelegate(self, queue: self.processingQueue)
                
                if session.canAddOutput(output) {
                    session.addOutput(output)
                    self.videoOutput = output
                }
                self.captureSession = session
            } catch {
                DispatchQueue.main.async { self.errorMessage = "Error setting up camera: \(error.localizedDescription)" }
            }
        }
    }
    
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if let session = self.captureSession, !session.isRunning {
                session.startRunning()
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }
    
    // MARK: - Procesamiento y Pose de Mano
    
    // Función de entrada principal para cada frame de video
    private func processFrame(_ pixelBuffer: CVPixelBuffer) {
        // Throttling: Limita a 10 FPS
        let now = Date()
        guard now.timeIntervalSince(lastRecognitionTime) >= recognitionInterval,
                !isProcessing else {
            return
        }
        
        lastRecognitionTime = now
        isProcessing = true
        
        // Ejecuta la detección de pose nativa de Vision
        detectHandPose(pixelBuffer: pixelBuffer)
    }
    
    private func detectHandPose(pixelBuffer: CVPixelBuffer) {
        
        // Solicitud nativa de Vision para encontrar puntos clave de la mano
        let handPoseRequest = VNDetectHumanHandPoseRequest { [weak self] request, error in
            guard let self = self else { return }
            defer { self.isProcessing = false }
            
            if let error = error {
                print("❌ Error en la detección de pose de mano: \(error.localizedDescription)")
                self.updateTranslatedText("") // Limpiar si hay error
                return
            }
            
            guard let observations = request.results as? [VNHumanHandPoseObservation],
                  let topHandObservation = observations.first else {
                self.updateTranslatedText("") // Limpiar si no hay mano
                return
            }
            
            // La mano fue detectada: intentar clasificar su pose
            do {
                // keypointsMultiArray() es el formato de entrada que tu modelo espera
                let keypointsMultiArray = try topHandObservation.keypointsMultiArray()
                
                // Clasificar la pose con el modelo Core ML
                self.classifyPose(keypoints: keypointsMultiArray)
                
            } catch {
                print("❌ Error al extraer puntos clave o clasificar: \(error.localizedDescription)")
            }
        }
        
        // ⚠️ Ajuste de Orientación: Usamos '.upMirrored' por defecto para la cámara frontal
        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .rightMirrored, // Probar con .right, .left, .down si no funciona
            options: [:]
        )
        
        processingQueue.async {
            do {
                try handler.perform([handPoseRequest])
            } catch {
                print("❌ Error al ejecutar el handler de pose: \(error.localizedDescription)")
                self.isProcessing = false
            }
        }
    }
    
    // MARK: - Clasificación Core ML
    
    private func classifyPose(keypoints: MLMultiArray) {
        guard let model = mlModel else { return }
        
        do {
            // Crear la entrada usando la clase generada por el modelo
            // ⚠️ AJUSTE AQUI: Asumiendo que la entrada del modelo se llama 'input'
            let input = HandPoseClassifierInput(poses: keypoints)
            
            // Ejecutar la predicción
            let output = try model.prediction(from: input)
            
            // Extraer la etiqueta y la confianza
            // ⚠️ AJUSTE AQUI: Asumiendo que la salida de la etiqueta es 'label' y las probabilidades son 'labelProbs'
            let recognizedSign = output.featureValue(for: "label")?.stringValue ?? ""
            let confidenceDictionary = output.featureValue(for: "labelProbs")?.dictionaryValue as? [String: Double]
            
            // Intentar obtener la confianza de la predicción más alta
            let confidence = confidenceDictionary?[recognizedSign] ?? 0.0
            let floatConfidence = Float(confidence)
            
            
            guard floatConfidence >= minimumConfidence else {
                 // Limpiar el texto si la confianza es baja
                 self.updateTranslatedText("")
                 return
             }
            
            print("✅ Seña clasificada: \(recognizedSign) (confianza: \(String(format: "%.2f", floatConfidence)))")
            
            // Actualizar el texto traducido usando el sistema de buffer
            self.updateTranslatedText(recognizedSign)
            
        } catch {
            print("❌ Error al clasificar la pose con Core ML: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Estabilización de Texto
    
    private func updateTranslatedText(_ prediction: String) {
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Agregar predicción o un string vacío si no hubo detección
            self.predictionBuffer.append(prediction)
            
            if self.predictionBuffer.count > self.bufferSize {
                self.predictionBuffer.removeFirst()
            }
            
            let mostCommon = self.predictionBuffer.mostFrequent()
            
            let now = Date()
            if mostCommon == self.stablePrediction {
                if now.timeIntervalSince(self.lastUpdateTime) >= self.updateThreshold {
                    DispatchQueue.main.async { // Siempre en Main Thread para la UI
                        // Solo actualizar si la nueva predicción no está vacía,
                        // a menos que la predicción estable anterior fuera vacía.
                        if !mostCommon.isEmpty || self.stablePrediction.isEmpty {
                            self.translatedText = mostCommon
                            self.lastUpdateTime = now
                        }
                    }
                }
            } else {
                self.stablePrediction = mostCommon
                self.lastUpdateTime = now
                
                // Si la nueva predicción es diferente e instantáneamente estable, actualizar
                if self.predictionBuffer.allSatisfy({ $0 == mostCommon }) {
                     DispatchQueue.main.async {
                         self.translatedText = mostCommon
                         self.lastUpdateTime = now
                     }
                 }
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

// Usamos @preconcurrency porque gestionamos la concurrencia con processingQueue
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        processFrame(pixelBuffer)
    }
}

// MARK: - Helper Extension

extension Array where Element == String {
    func mostFrequent() -> String {
        let counts = Dictionary(grouping: self, by: { $0 })
             .mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key ?? ""
    }
}
