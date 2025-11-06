#!/bin/bash

# Script de ayuda para ejecutar Docker con GYM App

set -e

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🐳 GYM App - Docker Helper${NC}\n"

# Función para mostrar ayuda
show_help() {
    echo "Uso: ./docker-run.sh [comando]"
    echo ""
    echo "Comandos disponibles:"
    echo "  dev          - Ejecutar en modo desarrollo (hot reload)"
    echo "  prod         - Ejecutar en modo producción"
    echo "  build        - Construir las imágenes Docker"
    echo "  stop         - Detener los contenedores"
    echo "  clean        - Limpiar contenedores y volúmenes"
    echo "  logs         - Ver logs del contenedor de desarrollo"
    echo "  shell        - Abrir shell dentro del contenedor"
    echo "  doctor       - Ejecutar flutter doctor"
    echo "  test         - Ejecutar tests"
    echo "  help         - Mostrar esta ayuda"
    echo ""
}

# Verificar si Docker está instalado
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}❌ Docker no está instalado. Por favor instálalo primero.${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}❌ Docker Compose no está instalado. Por favor instálalo primero.${NC}"
    exit 1
fi

# Procesar comandos
case "${1:-help}" in
    dev)
        echo -e "${GREEN}🚀 Iniciando modo desarrollo...${NC}"
        echo -e "${BLUE}📱 La app estará disponible en: http://localhost:39421${NC}\n"
        docker-compose up flutter-dev
        ;;
    prod)
        echo -e "${GREEN}🏭 Iniciando modo producción...${NC}"
        echo -e "${BLUE}📱 La app estará disponible en: http://localhost:8080${NC}\n"
        docker-compose --profile production up flutter-prod
        ;;
    build)
        echo -e "${GREEN}🔨 Construyendo imágenes Docker...${NC}\n"
        docker-compose build
        ;;
    stop)
        echo -e "${YELLOW}⏹️  Deteniendo contenedores...${NC}\n"
        docker-compose down
        ;;
    clean)
        echo -e "${YELLOW}🧹 Limpiando contenedores y volúmenes...${NC}\n"
        docker-compose down -v
        echo -e "${GREEN}✅ Limpieza completada${NC}"
        ;;
    logs)
        echo -e "${BLUE}📋 Mostrando logs...${NC}\n"
        docker-compose logs -f flutter-dev
        ;;
    shell)
        echo -e "${GREEN}🐚 Abriendo shell en el contenedor...${NC}\n"
        docker-compose exec flutter-dev bash
        ;;
    doctor)
        echo -e "${BLUE}🏥 Ejecutando Flutter Doctor...${NC}\n"
        docker-compose exec flutter-dev flutter doctor -v
        ;;
    test)
        echo -e "${BLUE}🧪 Ejecutando tests...${NC}\n"
        docker-compose exec flutter-dev flutter test
        ;;
    help|*)
        show_help
        ;;
esac
