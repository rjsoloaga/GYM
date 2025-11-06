@echo off
REM Script de ayuda para ejecutar Docker con GYM App (Windows)

setlocal enabledelayedexpansion

echo 🐳 GYM App - Docker Helper
echo.

REM Verificar si Docker está instalado
where docker >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Docker no está instalado. Por favor instálalo primero.
    exit /b 1
)

where docker-compose >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Docker Compose no está instalado. Por favor instálalo primero.
    exit /b 1
)

REM Procesar comandos
if "%1"=="" goto :help
if "%1"=="dev" goto :dev
if "%1"=="prod" goto :prod
if "%1"=="build" goto :build
if "%1"=="stop" goto :stop
if "%1"=="clean" goto :clean
if "%1"=="logs" goto :logs
if "%1"=="shell" goto :shell
if "%1"=="doctor" goto :doctor
if "%1"=="test" goto :test
if "%1"=="help" goto :help
goto :help

:dev
echo 🚀 Iniciando modo desarrollo...
echo 📱 La app estará disponible en: http://localhost:39421
echo.
docker-compose up flutter-dev
goto :end

:prod
echo 🏭 Iniciando modo producción...
echo 📱 La app estará disponible en: http://localhost:8080
echo.
docker-compose --profile production up flutter-prod
goto :end

:build
echo 🔨 Construyendo imágenes Docker...
echo.
docker-compose build
goto :end

:stop
echo ⏹️  Deteniendo contenedores...
echo.
docker-compose down
goto :end

:clean
echo 🧹 Limpiando contenedores y volúmenes...
echo.
docker-compose down -v
echo ✅ Limpieza completada
goto :end

:logs
echo 📋 Mostrando logs...
echo.
docker-compose logs -f flutter-dev
goto :end

:shell
echo 🐚 Abriendo shell en el contenedor...
echo.
docker-compose exec flutter-dev bash
goto :end

:doctor
echo 🏥 Ejecutando Flutter Doctor...
echo.
docker-compose exec flutter-dev flutter doctor -v
goto :end

:test
echo 🧪 Ejecutando tests...
echo.
docker-compose exec flutter-dev flutter test
goto :end

:help
echo Uso: docker-run.bat [comando]
echo.
echo Comandos disponibles:
echo   dev          - Ejecutar en modo desarrollo (hot reload)
echo   prod         - Ejecutar en modo producción
echo   build        - Construir las imágenes Docker
echo   stop         - Detener los contenedores
echo   clean        - Limpiar contenedores y volúmenes
echo   logs         - Ver logs del contenedor de desarrollo
echo   shell        - Abrir shell dentro del contenedor
echo   doctor       - Ejecutar flutter doctor
echo   test         - Ejecutar tests
echo   help         - Mostrar esta ayuda
echo.
goto :end

:end
endlocal
