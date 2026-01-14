# 🔧 Solución Definitiva para Problema de Ruta con Caracteres Especiales

## ❌ Problema
La carpeta "A.móviles" contiene caracteres no ASCII (ó) que causan problemas con Gradle en Windows, impidiendo compilar la APK.

## ✅ Solución Definitiva
Mover el proyecto a una nueva ubicación sin caracteres especiales.

---

## 📋 Opción 1: Script Automatizado (Recomendado)

He creado un script de PowerShell que automatiza el proceso completo.

### Pasos:
1. Ejecutar el script `migrar_proyecto.ps1`
2. El script creará una nueva carpeta sin caracteres especiales
3. Copiará todos los archivos del proyecto
4. Eliminará la solución temporal de `gradle.properties`
5. Verificará que todo funcione correctamente

---

## 📋 Opción 2: Migración Manual

### Paso 1: Crear Nueva Carpeta
```powershell
# Desde el directorio padre (Desktop)
cd C:\Users\solej\Desktop
mkdir GYM-main
```

### Paso 2: Copiar Todo el Contenido
```powershell
# Copiar todos los archivos (excepto .git si quieres mantener el historial)
xcopy "A.móviles\GYM-main\*" "GYM-main\" /E /I /H /Y
```

O usar robocopy (más robusto):
```powershell
robocopy "A.móviles\GYM-main" "GYM-main" /E /XD .git build
```

### Paso 3: Eliminar Solución Temporal
Eliminar la línea `android.overridePathCheck=true` de `android/gradle.properties`

### Paso 4: Verificar
```powershell
cd GYM-main
flutter clean
flutter pub get
flutter build apk --debug
```

### Paso 5: Actualizar Repositorio Git (si aplica)
```powershell
cd GYM-main
git remote -v  # Verificar remoto
# Si necesitas cambiar la URL del remoto:
# git remote set-url origin [nueva-url]
```

---

## 📋 Opción 3: Renombrar Carpeta Actual

### Paso 1: Cerrar TODOS los programas
- Cerrar VS Code / Cursor
- Cerrar Android Studio
- Cerrar cualquier terminal que esté usando el proyecto

### Paso 2: Renombrar la Carpeta
```powershell
# Desde el directorio padre
cd C:\Users\solej\Desktop
Rename-Item "A.móviles" "A.moviles"
```

### Paso 3: Eliminar Solución Temporal
Eliminar la línea `android.overridePathCheck=true` de `android/gradle.properties`

### Paso 4: Verificar
```powershell
cd "A.moviles\GYM-main"
flutter clean
flutter pub get
flutter build apk --debug
```

---

## ⚠️ Importante

1. **Cerrar todas las aplicaciones** que estén usando el proyecto antes de mover/renombrar
2. **Verificar rutas absolutas** en archivos de configuración si las hay
3. **Actualizar bookmarks/favoritos** en tu IDE
4. **Verificar que Git funcione** correctamente después de la migración

---

## 🎯 Recomendación Final

**Usar la Opción 1 (Script Automatizado)** - Es la más segura y completa.

El script:
- ✅ Crea la nueva carpeta automáticamente
- ✅ Copia todos los archivos preservando estructura
- ✅ Elimina la solución temporal
- ✅ Verifica que Flutter funcione correctamente
- ✅ Maneja errores y proporciona feedback claro

