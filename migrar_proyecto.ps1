# Script de Migración - GYM Manager
# Este script mueve el proyecto a una nueva ubicación sin caracteres especiales
# para resolver el problema de compilación de Android en Windows

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Migración de Proyecto GYM Manager" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuración
$rutaActual = $PSScriptRoot
$rutaPadre = Split-Path -Parent $rutaActual
$nombreNuevaCarpeta = "GYM-main"
$rutaNueva = Join-Path $rutaPadre $nombreNuevaCarpeta

Write-Host "Ruta actual: $rutaActual" -ForegroundColor Yellow
Write-Host "Ruta nueva:  $rutaNueva" -ForegroundColor Yellow
Write-Host ""

# Verificar que estamos en el directorio correcto
if (-not (Test-Path (Join-Path $rutaActual "pubspec.yaml"))) {
    Write-Host "ERROR: No se encontró pubspec.yaml en la ruta actual." -ForegroundColor Red
    Write-Host "Por favor, ejecuta este script desde la raíz del proyecto GYM-main." -ForegroundColor Red
    pause
    exit 1
}

# Verificar si la carpeta destino ya existe
if (Test-Path $rutaNueva) {
    Write-Host "ADVERTENCIA: La carpeta destino ya existe: $rutaNueva" -ForegroundColor Yellow
    $respuesta = Read-Host "¿Deseas eliminarla y continuar? (S/N)"
    if ($respuesta -eq "S" -or $respuesta -eq "s") {
        Write-Host "Eliminando carpeta existente..." -ForegroundColor Yellow
        Remove-Item -Path $rutaNueva -Recurse -Force
    } else {
        Write-Host "Operación cancelada." -ForegroundColor Red
        pause
        exit 1
    }
}

# Verificar que no haya procesos usando el proyecto
Write-Host ""
Write-Host "Verificando procesos activos..." -ForegroundColor Cyan
$procesos = @("Code", "Cursor", "dart", "flutter", "java", "gradle")
$procesosActivos = $false

foreach ($proceso in $procesos) {
    $instancias = Get-Process -Name $proceso -ErrorAction SilentlyContinue
    if ($instancias) {
        Write-Host "ADVERTENCIA: Se encontraron instancias de $proceso ejecutándose." -ForegroundColor Yellow
        $procesosActivos = $true
    }
}

if ($procesosActivos) {
    Write-Host ""
    Write-Host "ADVERTENCIA: Hay procesos activos que podrían estar usando el proyecto." -ForegroundColor Yellow
    Write-Host "Se recomienda cerrarlos antes de continuar." -ForegroundColor Yellow
    $respuesta = Read-Host "¿Deseas continuar de todas formas? (S/N)"
    if ($respuesta -ne "S" -and $respuesta -ne "s") {
        Write-Host "Operación cancelada." -ForegroundColor Red
        pause
        exit 1
    }
}

# Crear nueva carpeta
Write-Host ""
Write-Host "Creando nueva carpeta..." -ForegroundColor Cyan
try {
    New-Item -ItemType Directory -Path $rutaNueva -Force | Out-Null
    Write-Host "✅ Carpeta creada: $rutaNueva" -ForegroundColor Green
} catch {
    Write-Host "ERROR: No se pudo crear la carpeta destino." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    pause
    exit 1
}

# Copiar archivos
Write-Host ""
Write-Host "Copiando archivos del proyecto..." -ForegroundColor Cyan
Write-Host "Esto puede tardar varios minutos..." -ForegroundColor Yellow

try {
    # Excluir carpetas que no necesitamos copiar
    $excluir = @("build", ".dart_tool", ".idea", ".vscode", ".git")
    
    # Obtener todos los items a copiar
    $items = Get-ChildItem -Path $rutaActual -Force
    
    $totalItems = $items.Count
    $contador = 0
    
    foreach ($item in $items) {
        $contador++
        $porcentaje = [math]::Round(($contador / $totalItems) * 100, 2)
        Write-Progress -Activity "Copiando archivos" -Status "$porcentaje% completado" -PercentComplete $porcentaje
        
        # Saltar carpetas excluidas
        if ($excluir -contains $item.Name) {
            continue
        }
        
        # Saltar si es el script actual
        if ($item.Name -eq "migrar_proyecto.ps1") {
            continue
        }
        
        $destino = Join-Path $rutaNueva $item.Name
        
        if ($item.PSIsContainer) {
            # Es una carpeta
            Copy-Item -Path $item.FullName -Destination $destino -Recurse -Force
        } else {
            # Es un archivo
            Copy-Item -Path $item.FullName -Destination $destino -Force
        }
    }
    
    Write-Progress -Activity "Copiando archivos" -Completed
    Write-Host "✅ Archivos copiados correctamente" -ForegroundColor Green
} catch {
    Write-Host "ERROR: No se pudieron copiar los archivos." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    pause
    exit 1
}

# Eliminar solución temporal de gradle.properties
Write-Host ""
Write-Host "Eliminando solución temporal de gradle.properties..." -ForegroundColor Cyan
$gradleProperties = Join-Path $rutaNueva "android\gradle.properties"

if (Test-Path $gradleProperties) {
    try {
        $contenido = Get-Content $gradleProperties
        # Filtrar líneas que contengan la solución temporal
        $nuevoContenido = @()
        foreach ($linea in $contenido) {
            # Excluir líneas relacionadas con la solución temporal
            if ($linea -notmatch "android.overridePathCheck" -and 
                $linea -notmatch "# SOLUCIÓN TEMPORAL" -and 
                $linea -notmatch "# Solución temporal" -and 
                $linea -notmatch "# NOTA:" -and 
                $linea -notmatch "# Ver SOLUCION_RUTA_DEFINITIVA" -and
                $linea.Trim() -ne "") {
                $nuevoContenido += $linea
            }
        }
        Set-Content -Path $gradleProperties -Value $nuevoContenido
        Write-Host "✅ Solución temporal eliminada de gradle.properties" -ForegroundColor Green
    } catch {
        Write-Host "ADVERTENCIA: No se pudo modificar gradle.properties." -ForegroundColor Yellow
        Write-Host "Por favor, elimina manualmente la línea 'android.overridePathCheck=true'" -ForegroundColor Yellow
    }
} else {
    Write-Host "ADVERTENCIA: No se encontró gradle.properties" -ForegroundColor Yellow
}

# Verificar Flutter
Write-Host ""
Write-Host "Verificando instalación de Flutter..." -ForegroundColor Cyan
try {
    $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
    Write-Host "✅ Flutter encontrado: $flutterVersion" -ForegroundColor Green
} catch {
    Write-Host "ADVERTENCIA: Flutter no se encontró en el PATH." -ForegroundColor Yellow
}

# Limpiar y obtener dependencias
Write-Host ""
Write-Host "Limpiando proyecto..." -ForegroundColor Cyan
Set-Location $rutaNueva
try {
    flutter clean 2>&1 | Out-Null
    Write-Host "✅ Proyecto limpiado" -ForegroundColor Green
} catch {
    Write-Host "ADVERTENCIA: No se pudo limpiar el proyecto." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Obteniendo dependencias..." -ForegroundColor Cyan
try {
    flutter pub get 2>&1 | Out-Null
    Write-Host "✅ Dependencias obtenidas" -ForegroundColor Green
} catch {
    Write-Host "ADVERTENCIA: No se pudieron obtener las dependencias." -ForegroundColor Yellow
}

# Resumen final
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Migración Completada" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Proyecto migrado exitosamente a:" -ForegroundColor Green
Write-Host "   $rutaNueva" -ForegroundColor White
Write-Host ""
Write-Host "Próximos pasos:" -ForegroundColor Yellow
Write-Host "1. Abre el proyecto desde la nueva ubicación" -ForegroundColor White
Write-Host "2. Verifica que todo funcione correctamente" -ForegroundColor White
Write-Host "3. Prueba compilar la APK: flutter build apk --debug" -ForegroundColor White
Write-Host "4. (Opcional) Elimina la carpeta antigua después de verificar" -ForegroundColor White
Write-Host ""
Write-Host "NOTA: La carpeta original NO se eliminará automáticamente." -ForegroundColor Yellow
Write-Host "      Elimínala manualmente después de verificar que todo funciona." -ForegroundColor Yellow
Write-Host ""

# Preguntar si desea abrir la nueva carpeta
$abrir = Read-Host "¿Deseas abrir la nueva carpeta en el explorador? (S/N)"
if ($abrir -eq "S" -or $abrir -eq "s") {
    Start-Process explorer.exe -ArgumentList $rutaNueva
}

Write-Host ""
Write-Host "Presiona cualquier tecla para salir..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

