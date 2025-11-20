---
description: Construir y ejecutar aplicación Flutter para escritorio
---

# Flujo de trabajo para habilitar soporte de escritorio y compilar/ejecutar la app en Windows, macOS y Linux.

1. **Habilitar plataformas de escritorio**
   ```bash
   flutter config --enable-windows
   flutter config --enable-macos
   flutter config --enable-linux
   ```
   // turbo-all
2. **Verificar que las plataformas están habilitadas**
   ```bash
   flutter devices
   ```
3. **Actualizar dependencias para escritorio** (si es necesario, por ejemplo `sqflite_common_ffi` ya está incluido).
   ```bash
   flutter pub get
   ```
4. **Ejecutar la app en una plataforma de escritorio**
   - Windows:
     ```bash
     flutter run -d windows
     ```
   - macOS:
     ```bash
     flutter run -d macos
     ```
   - Linux:
     ```bash
     flutter run -d linux
     ```
5. **Construir binarios de release**
   - Windows:
     ```bash
     flutter build windows --release
     ```
   - macOS:
     ```bash
     flutter build macos --release
     ```
   - Linux:
     ```bash
     flutter build linux --release
     ```
6. **Ubicación de los ejecutables generados**
   - Windows: `build/windows/runner/Release/`
   - macOS: `build/macos/Build/Products/Release/`
   - Linux: `build/linux/x64/release/bundle/`

**Opcional**: Añadir configuración específica de escritorio (por ejemplo, íconos, splash screens) usando `flutter_launcher_icons` y `flutter_native_splash` con las secciones correspondientes para cada plataforma.

**Consejo**: Para probar en Linux, puede ser necesario instalar `libgtk-3-dev` y otras dependencias mediante el gestor de paquetes.
