# 📝 Guía Paso a Paso - Migración Definitiva del Proyecto

## 🎯 Objetivo
Mover el proyecto GYM-main de la carpeta "A.móviles" (con caracteres especiales) a una nueva ubicación sin caracteres especiales para resolver el problema de compilación de Android.

---

## ⚠️ Antes de Comenzar

### 1. Cerrar Todas las Aplicaciones
- ✅ Cerrar VS Code / Cursor
- ✅ Cerrar Android Studio (si está abierto)
- ✅ Cerrar cualquier terminal que esté usando el proyecto
- ✅ Cerrar cualquier otra aplicación relacionada con el proyecto

### 2. Verificar que Git está Actualizado (si usas control de versiones)
```powershell
cd "C:\Users\solej\Desktop\A.móviles\GYM-main"
git status
```

---

## 🚀 Método Recomendado: Script Automatizado

### Paso 1: Abrir PowerShell como Administrador
1. Presiona `Win + X`
2. Selecciona "Windows PowerShell (Administrador)" o "Terminal (Administrador)"

### Paso 2: Navegar al Proyecto
```powershell
cd "C:\Users\solej\Desktop\A.móviles\GYM-main"
```

### Paso 3: Ejecutar el Script
```powershell
.\migrar_proyecto.ps1
```

### Paso 4: Seguir las Instrucciones del Script
- El script te preguntará si deseas continuar en varios puntos
- Responde "S" para continuar cuando se te pregunte
- Espera a que termine la copia (puede tardar varios minutos)

### Paso 5: Verificar la Migración
El script automáticamente:
- ✅ Crea la nueva carpeta en `C:\Users\solej\Desktop\GYM-main`
- ✅ Copia todos los archivos
- ✅ Elimina la solución temporal de `gradle.properties`
- ✅ Limpia el proyecto
- ✅ Obtiene las dependencias

### Paso 6: Probar la Compilación
```powershell
cd "C:\Users\solej\Desktop\GYM-main"
flutter build apk --debug
```

Si la compilación funciona correctamente, ¡la migración fue exitosa!

---

## 🔧 Método Alternativo: Migración Manual

### Paso 1: Crear Nueva Carpeta
```powershell
cd C:\Users\solej\Desktop
mkdir GYM-main
```

### Paso 2: Copiar Archivos con Robocopy
```powershell
robocopy "A.móviles\GYM-main" "GYM-main" /E /XD build .dart_tool .git .idea .vscode /XF migrar_proyecto.ps1
```

**Explicación de parámetros:**
- `/E` - Copiar todos los subdirectorios, incluyendo vacíos
- `/XD` - Excluir directorios (build, .dart_tool, .git, etc.)
- `/XF` - Excluir archivos específicos

### Paso 3: Eliminar Solución Temporal
Abrir `GYM-main\android\gradle.properties` y eliminar estas líneas:
```properties
# Solución temporal para rutas con caracteres no ASCII (ej: "A.móviles")
# NOTA: La solución recomendada es mover el proyecto a una carpeta sin caracteres especiales
android.overridePathCheck=true
```

### Paso 4: Limpiar y Verificar
```powershell
cd GYM-main
flutter clean
flutter pub get
flutter build apk --debug
```

---

## ✅ Verificación Post-Migración

### 1. Verificar Estructura de Carpetas
```powershell
cd "C:\Users\solej\Desktop\GYM-main"
Get-ChildItem -Recurse -Depth 2 | Select-Object FullName
```

### 2. Verificar Archivos Importantes
- ✅ `pubspec.yaml` existe
- ✅ `lib/main.dart` existe
- ✅ `android/gradle.properties` no tiene `android.overridePathCheck=true`
- ✅ Carpeta `lib/` con todos los archivos

### 3. Verificar Git (si aplica)
```powershell
git status
git remote -v
```

### 4. Probar Compilación
```powershell
flutter clean
flutter pub get
flutter build apk --debug
```

### 5. Probar en Dispositivo/Emulador
```powershell
flutter run
```

---

## 🔄 Actualizar Referencias

### 1. Actualizar Bookmarks/Favoritos en tu IDE
- VS Code / Cursor: Agregar nueva carpeta a workspace
- Android Studio: Abrir proyecto desde nueva ubicación

### 2. Actualizar Rutas Absolutas (si las hay)
Buscar en el proyecto referencias a la ruta antigua:
```powershell
cd "C:\Users\solej\Desktop\GYM-main"
Select-String -Path "*.dart" -Pattern "A.móviles" -Recurse
Select-String -Path "*.yaml" -Pattern "A.móviles" -Recurse
Select-String -Path "*.json" -Pattern "A.móviles" -Recurse
```

### 3. Actualizar Git Remote (si es necesario)
```powershell
git remote -v
# Si necesitas cambiar la URL:
# git remote set-url origin [nueva-url]
```

---

## 🗑️ Eliminar Carpeta Antigua (Opcional)

**⚠️ IMPORTANTE: Solo haz esto DESPUÉS de verificar que todo funciona correctamente en la nueva ubicación.**

### Paso 1: Verificar que Todo Funciona
- ✅ Proyecto compila correctamente
- ✅ Aplicación funciona en dispositivo/emulador
- ✅ Git funciona correctamente (si aplica)
- ✅ No hay errores

### Paso 2: Hacer Backup (Recomendado)
```powershell
# Renombrar carpeta antigua como backup
Rename-Item "C:\Users\solej\Desktop\A.móviles\GYM-main" "GYM-main-backup"
```

### Paso 3: Eliminar Después de un Tiempo
Después de algunas semanas, si todo funciona bien:
```powershell
Remove-Item "C:\Users\solej\Desktop\A.móviles\GYM-main-backup" -Recurse -Force
```

---

## 🆘 Solución de Problemas

### Problema: "No se puede acceder al archivo porque está en uso"
**Solución:**
1. Cerrar todas las aplicaciones relacionadas
2. Reiniciar el equipo
3. Intentar de nuevo

### Problema: "Flutter no se encuentra"
**Solución:**
```powershell
# Verificar que Flutter está en el PATH
flutter --version

# Si no funciona, agregar Flutter al PATH
$env:PATH += ";C:\path\to\flutter\bin"
```

### Problema: "Error al compilar después de la migración"
**Solución:**
```powershell
flutter clean
flutter pub get
flutter doctor
flutter build apk --debug
```

### Problema: "Git no funciona después de la migración"
**Solución:**
```powershell
# Verificar que la carpeta .git se copió correctamente
Test-Path ".git"

# Si no existe, inicializar git de nuevo (pero perderás historial)
git init
git remote add origin [url-del-repositorio]
```

---

## ✅ Checklist Final

- [ ] Nueva carpeta creada sin caracteres especiales
- [ ] Todos los archivos copiados correctamente
- [ ] `gradle.properties` actualizado (sin solución temporal)
- [ ] `flutter clean` ejecutado
- [ ] `flutter pub get` ejecutado
- [ ] `flutter build apk --debug` funciona
- [ ] Aplicación funciona en dispositivo/emulador
- [ ] Git funciona correctamente (si aplica)
- [ ] Bookmarks/Workspace actualizados
- [ ] Carpeta antigua renombrada/eliminada (después de verificar)

---

## 📞 Soporte

Si encuentras algún problema durante la migración:
1. Revisa los logs del script
2. Verifica que todas las aplicaciones estén cerradas
3. Intenta el método manual
4. Consulta la sección "Solución de Problemas"

---

**¡Migración completada exitosamente!** 🎉

