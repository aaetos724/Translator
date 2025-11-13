# Translator: Hand Sign Language to English

Una aplicación móvil para iOS que traduce entre texto y lengua de signos manual (American Sign Language), diseñada siguiendo estrictamente las Human Interface Guidelines (HIG) de Apple.

## Características

### Pestaña "Text" (Texto a Señales)
- ✨ Diseño minimalista y moderno adhiriéndose a las HIG de Apple
- 📝 Traducción de texto a imágenes de lengua de signos
- 🎨 Interfaz limpia con tipografía San Francisco (estilo Apple Translator)
- 🎬 Animaciones secuenciales suaves con transiciones fade
- 🔄 Placeholders elegantes para imágenes faltantes

### Pestaña "Camera" (Reconocimiento en Tiempo Real)
- 📷 Vista previa de cámara en vivo
- 🤖 Reconocimiento de gestos de manos en tiempo real usando Core ML
- 📊 Sistema de buffer para estabilizar predicciones y evitar parpadeos
- 🎨 Superposición de texto translúcido para mostrar traducciones
- ⚡ Procesamiento en segundo plano para no bloquear la UI

## Estructura del Proyecto

```
translator/
├── translator/
│   ├── translatorApp.swift         # Punto de entrada de la aplicación
│   ├── MainTabView.swift           # Vista principal con TabView
│   ├── TextToSignView.swift        # Vista de texto a señales
│   ├── CameraView.swift            # Vista de cámara en vivo
│   ├── CameraManager.swift         # Gestor de cámara y reconocimiento ML
│   ├── CameraPreviewView.swift     # Vista previa de la cámara
│   ├── SignLanguageModel.swift     # Modelo para manejar traducciones
│   ├── SignViews.swift             # Componentes visuales de señales
│   └── Assets.xcassets/            # Recursos (imágenes, colores, etc.)
└── translator.xcodeproj/           # Proyecto Xcode
```

## Imágenes de Lengua de Signos

La aplicación está configurada para usar imágenes que ya están en el catálogo de Assets. Las imágenes deben tener los siguientes nombres:

### Nombres de Imágenes:

- **Letras**: `A`, `B`, `C`, ..., `Z` (en mayúsculas)
- **Números**: `1`, `2`, `3`, `4`, `5`, `6`, `7`, `8`, `9`

Las imágenes en Assets.xcassets deben llamarse exactamente con el nombre de la letra o número en mayúsculas (ej: "A", "B", "1", "2").

### Formatos Recomendados:

- Formato: PNG (preferido) o JPEG
- Tamaño recomendado: 240x240 puntos (para @1x)
- Variantes: 480x480 (@2x) y 720x720 (@3x) para diferentes densidades de pantalla
- Xcode manejará automáticamente las variantes (@2x, @3x) si las proporcionas

## Diseño y HIG

La aplicación está diseñada siguiendo las Human Interface Guidelines de Apple:

- **Tipografía**: Usa la tipografía del sistema (San Francisco) con estilos apropiados
- **Colores**: Utiliza colores del sistema que se adaptan automáticamente al modo claro/oscuro
- **Espaciado**: Sigue las guías de espaciado de iOS
- **Componentes**: Usa componentes nativos de SwiftUI
- **Navegación**: Diseño de vista única sin barras de navegación innecesarias

## Requisitos

- iOS 15.0 o posterior
- Xcode 14.0 o posterior
- Swift 5.0 o posterior
- Dispositivo iOS con cámara (para la funcionalidad de reconocimiento)

## Configuración de Permisos

Para que la funcionalidad de cámara funcione correctamente, necesitas configurar los permisos de cámara:

1. Abre el proyecto en Xcode
2. Selecciona el target "translator"
3. Ve a la pestaña "Info"
4. Agrega la clave `Privacy - Camera Usage Description` (NSCameraUsageDescription)
5. Agrega el valor: "This app needs access to your camera to recognize sign language gestures in real-time."

Para más detalles, consulta el archivo `CAMERA_SETUP.md`.

## Uso

### Pestaña "Text"
1. Abre la aplicación y selecciona la pestaña "Text"
2. Escribe texto en el campo de entrada "English"
3. Las imágenes de lengua de signos aparecerán automáticamente en el cuadro "Hand Sign Language"
4. Cada letra del texto se traduce a su imagen correspondiente con animaciones secuenciales

### Pestaña "Camera"
1. Selecciona la pestaña "Camera"
2. Concede permiso de cámara cuando se solicite
3. Apunta la cámara hacia gestos de manos
4. El texto traducido aparecerá en la parte inferior de la pantalla en tiempo real

## Integración del Modelo ML

La aplicación incluye un placeholder para integrar tu modelo Core ML entrenado:

1. Agrega tu modelo `.mlmodel` o `.mlmodelc` al proyecto
2. Actualiza `CameraManager.swift`:
   - Descomenta y completa la función `loadMLModel()`
   - Reemplaza `YourSignLanguageModel` con el nombre de tu modelo
   - Actualiza la función `processFrame()` para usar tu modelo real

Para más detalles, consulta el archivo `CAMERA_SETUP.md`.

## Notas

- Se traducen letras del alfabeto (A-Z) y números (1-9).
- El número 0 no está incluido, ya que en ASL se usa la misma señal que la letra "O".
- Los espacios y caracteres especiales se ignoran en la traducción.
- Si una imagen no está disponible, se mostrará un placeholder elegante con el carácter correspondiente.
- La aplicación está optimizada para iPhone y iPad.

## Licencia

Este proyecto es de uso educativo y personal.

