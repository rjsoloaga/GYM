# Script de Verificación - Pre-Migración
# Verifica que todo esté listo para la migración

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Verificación Pre-Migración" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$errores = 0
$advertencias = 0

# 1. Verificar que estamos en el directorio correcto
Write-Host "1. Verificando directorio del proyecto..." -ForegroundColor Yellow
if (Test-Path "pubspec.yaml") {
    Write-Host "   ✅ pubspec.yaml encontrado" -ForegroundColor Green
} else {
    Write-Host "   ❌ pubspec.yaml NO encontrado" -ForegroundColor Red
    $errores++
}

# 2. Verificar que el script de migración existe
Write-Host ""
Write-Host "2. Verificando script de migración..." -ForegroundColor Yellow
if (Test-Path "migrar_proyecto.ps1") {
    Write-Host "   ✅ migrar_proyecto.ps1 encontrado" -ForegroundColor Green
    
    # Verificar que el script tenga contenido
    $contenido = Get-Content "migrar_proyecto.ps1" -Raw
    if ($contenido.Length -gt 100) {
        Write-Host "   ✅ Script tiene contenido válido" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Script parece estar vacío o corrupto" -ForegroundColor Yellow
        $advertencias++
    }
} else {
    Write-Host "   ❌ migrar_proyecto.ps1 NO encontrado" -ForegroundColor Red
    $errores++
}

# 3. Verificar archivos de documentación
Write-Host ""
Write-Host "3. Verificando documentación..." -ForegroundColor Yellow
$docs = @(
    "SOLUCION_RUTA_DEFINITIVA.md",
    "MIGRACION_PASO_A_PASO.md",
    "INSTRUCCIONES_MIGRACION.md"
)

foreach ($doc in $docs) {
    if (Test-Path $doc) {
        Write-Host "   ✅ $doc encontrado" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  $doc NO encontrado" -ForegroundColor Yellow
        $advertencias++
    }
}

# 4. Verificar gradle.properties
Write-Host ""
Write-Host "4. Verificando gradle.properties..." -ForegroundColor Yellow
$gradleProps = "android\gradle.properties"
if (Test-Path $gradleProps) {
    Write-Host "   ✅ gradle.properties encontrado" -ForegroundColor Green
    
    $contenido = Get-Content $gradleProps -Raw
    if ($contenido -match "android.overridePathCheck=true") {
        Write-Host "   ✅ Solución temporal encontrada (será eliminada en migración)" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Solución temporal no encontrada" -ForegroundColor Yellow
        $advertencias++
    }
} else {
    Write-Host "   ❌ gradle.properties NO encontrado" -ForegroundColor Red
    $errores++
}

# 5. Verificar estructura de carpetas principales
Write-Host ""
Write-Host "5. Verificando estructura del proyecto..." -ForegroundColor Yellow
$carpetas = @("lib", "android", "ios", "web")
foreach ($carpeta in $carpetas) {
    if (Test-Path $carpeta) {
        Write-Host "   ✅ Carpeta $carpeta encontrada" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Carpeta $carpeta NO encontrada" -ForegroundColor Yellow
        $advertencias++
    }
}

# 6. Verificar Flutter
Write-Host ""
Write-Host "6. Verificando Flutter..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Flutter encontrado: $flutterVersion" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Flutter no se puede ejecutar" -ForegroundColor Red
        $errores++
    }
} catch {
    Write-Host "   ❌ Flutter no encontrado en PATH" -ForegroundColor Red
    $errores++
}

# 7. Verificar que podemos acceder a la ruta padre
Write-Host ""
Write-Host "7. Verificando ruta destino..." -ForegroundColor Yellow
try {
    $rutaActual = Get-Location
    $rutaPadre = Split-Path -Parent $rutaActual.Path
    $rutaNueva = Join-Path $rutaPadre "GYM-main"
    
    Write-Host "   📍 Ruta actual: $rutaActual" -ForegroundColor Cyan
    Write-Host "   📍 Ruta destino: $rutaNueva" -ForegroundColor Cyan
    
    # Verificar que podemos escribir en la ruta padre
    if (Test-Path $rutaPadre) {
        Write-Host "   ✅ Ruta padre accesible" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Ruta padre NO accesible" -ForegroundColor Red
        $errores++
    }
    
    # Verificar si la carpeta destino ya existe
    if (Test-Path $rutaNueva) {
        Write-Host "   ⚠️  Carpeta destino YA EXISTE (se preguntará si desea sobrescribir)" -ForegroundColor Yellow
        $advertencias++
    } else {
        Write-Host "   ✅ Carpeta destino disponible" -ForegroundColor Green
    }
} catch {
    Write-Host "   ❌ Error al verificar rutas: $_" -ForegroundColor Red
    $errores++
}

# 8. Verificar procesos activos
Write-Host ""
Write-Host "8. Verificando procesos activos..." -ForegroundColor Yellow
$procesos = @("Code", "Cursor", "dart", "flutter", "java", "gradle")
$procesosEncontrados = @()

foreach ($proceso in $procesos) {
    $instancias = Get-Process -Name $proceso -ErrorAction SilentlyContinue
    if ($instancias) {
        $procesosEncontrados += $proceso
    }
}

if ($procesosEncontrados.Count -eq 0) {
    Write-Host "   ✅ No hay procesos activos que puedan interferir" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Procesos activos encontrados: $($procesosEncontrados -join ', ')" -ForegroundColor Yellow
    Write-Host "      Se recomienda cerrarlos antes de migrar" -ForegroundColor Yellow
    $advertencias++
}

# Resumen
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Resumen de Verificación" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($errores -eq 0 -and $advertencias -eq 0) {
    Write-Host "✅ Todo está listo para la migración" -ForegroundColor Green
    Write-Host ""
    Write-Host "Próximo paso: Ejecutar .\migrar_proyecto.ps1" -ForegroundColor Cyan
} elseif ($errores -eq 0) {
    Write-Host "⚠️  Listo para migración con $advertencias advertencia(s)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Próximo paso: Revisar advertencias y luego ejecutar .\migrar_proyecto.ps1" -ForegroundColor Cyan
} else {
    Write-Host "❌ Se encontraron $errores error(es) y $advertencias advertencia(s)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Por favor, corrige los errores antes de proceder con la migración" -ForegroundColor Red
}

Write-Host ""
Write-Host "Presiona cualquier tecla para continuar..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

