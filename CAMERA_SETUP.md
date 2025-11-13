# Configuración de Permisos de Cámara

## Permisos Requeridos

Para que la aplicación funcione correctamente, necesitas configurar los permisos de cámara en el proyecto de Xcode.

### Pasos para Configurar Permisos:

1. **Abre el proyecto en Xcode**: Abre `translator.xcodeproj` en Xcode.

2. **Selecciona el Target**: En el navegador de proyectos, selecciona el target "translator".

3. **Ve a la pestaña "Info"**: 
   - Haz clic en el target "translator"
   - Selecciona la pestaña "Info"
   - Busca la sección "Custom iOS Target Properties"

4. **Agrega la clave de privacidad de cámara**:
   - Haz clic en el botón "+" para agregar una nueva entrada
   - Agrega la clave: `Privacy - Camera Usage Description` (o `NSCameraUsageDescription`)
   - Agrega el valor: `"This app needs access to your camera to recognize sign language gestures in real-time."`

### Alternativa: Agregar directamente al Info.plist

Si prefieres usar un archivo Info.plist:

1. Crea un archivo `Info.plist` en la carpeta `translator/`
2. Agrega el siguiente contenido:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSCameraUsageDescription</key>
    <string>This app needs access to your camera to recognize sign language gestures in real-time.</string>
</dict>
</plist>
```

3. En el proyecto de Xcode, en la configuración del target, asegúrate de que el "Info.plist File" apunte a este archivo.

### Verificación

Después de configurar los permisos, la aplicación debería:
- Solicitar permiso de cámara la primera vez que se abra la pestaña "Camera"
- Mostrar la vista previa de la cámara cuando se conceda el permiso
- Mostrar un mensaje de error si se deniega el permiso

## Integración del Modelo ML

✅ **El código de reconocimiento ya está implementado**. Solo necesitas agregar tu modelo Core ML.

### Pasos para Integrar tu Modelo Core ML:

1. **Agrega tu modelo `Translator.mlmodel`** al proyecto:
   - Arrastra el archivo `Translator.mlmodel` a la carpeta del proyecto en Xcode
   - **IMPORTANTE**: El modelo debe llamarse exactamente `Translator.mlmodel`
   - Asegúrate de que esté incluido en el target "translator"
   - Xcode compilará automáticamente el modelo y generará la clase `Translator`

2. **Verifica que el modelo se cargue correctamente**:
   - El código en `CameraManager.swift` ya está configurado para cargar el modelo `Translator`
   - Cuando ejecutes la app, verás en la consola: `✅ Modelo Core ML 'Translator' cargado correctamente`
   - Si hay un error, verás un mensaje detallado con instrucciones

3. **El código ya incluye**:
   - ✅ Carga del modelo usando Vision y Core ML
   - ✅ Procesamiento de frames de video en tiempo real
   - ✅ Reconocimiento de gestos usando `VNCoreMLRequest`
   - ✅ Filtrado por confianza (mínimo 0.5 por defecto)
   - ✅ Sistema de buffer para estabilizar predicciones
   - ✅ Throttling para limitar la frecuencia de reconocimiento (10 FPS)
   - ✅ Actualización de UI en el hilo principal

### Configuración del Modelo

El modelo debe:
- Ser un modelo de clasificación de imágenes (Image Classifier)
- Aceptar imágenes como entrada (CVPixelBuffer)
- Devolver clasificaciones con identificadores de texto (ej: "A", "B", "HELLO")
- Estar entrenado para reconocer gestos de lengua de signos

### Ajuste de Confianza

Puedes ajustar el umbral de confianza en `CameraManager.swift`:

```swift
let minimumConfidence: Float = 0.5  // Ajusta este valor (0.0 - 1.0)
```

- **Valores más altos (0.7-0.9)**: Más estricto, solo predicciones muy seguras
- **Valores más bajos (0.3-0.5)**: Más permisivo, acepta más predicciones
- **Recomendado**: 0.5 para un balance entre precisión y sensibilidad

### Preprocesamiento de Frames

Vision Framework maneja automáticamente:
- ✅ Redimensionado al tamaño de entrada del modelo
- ✅ Conversión de formato de píxeles
- ✅ Normalización básica

Si tu modelo requiere preprocesamiento adicional, puedes modificar `performHandSignRecognition()` en `CameraManager.swift`.

## Notas Adicionales

- La aplicación incluye un sistema de buffer para estabilizar las predicciones y evitar parpadeos
- El procesamiento ML se realiza en un hilo en segundo plano para no bloquear la UI
- Las actualizaciones de la UI se realizan en el hilo principal

