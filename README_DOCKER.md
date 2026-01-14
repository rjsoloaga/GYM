# 🐳 Guía de Docker para GYM App

Este proyecto incluye configuración de Docker para ejecutar la aplicación Flutter en contenedores.

## 📋 Requisitos Previos

- Docker instalado ([Descargar Docker](https://www.docker.com/get-started))
- Docker Compose instalado (viene con Docker Desktop)

## 🚀 Uso Rápido

### Desarrollo (Modo Hot Reload)

Para ejecutar la aplicación en modo desarrollo con hot reload:

```bash
docker-compose up flutter-dev
```

La aplicación estará disponible en: **http://localhost:39421**

### Producción (Build Optimizado)

Para crear un build de producción y servirlo:

```bash
docker-compose --profile production up flutter-prod
```

La aplicación estará disponible en: **http://localhost:8080**

## 📝 Comandos Útiles

### Construir la imagen

```bash
docker-compose build
```

### Ejecutar en segundo plano

```bash
docker-compose up -d flutter-dev
```

### Ver logs

```bash
docker-compose logs -f flutter-dev
```

### Detener contenedores

```bash
docker-compose down
```

### Limpiar todo (incluyendo volúmenes)

```bash
docker-compose down -v
```

### Ejecutar comandos dentro del contenedor

```bash
# Entrar al contenedor
docker-compose exec flutter-dev bash

# Ejecutar comandos Flutter
docker-compose exec flutter-dev flutter doctor
docker-compose exec flutter-dev flutter pub get
docker-compose exec flutter-dev flutter build web
```

## 🔧 Configuración

### Puertos

- **39421**: Puerto para desarrollo (hot reload)
- **8080**: Puerto para producción

Puedes cambiar estos puertos en `docker-compose.yml` si es necesario.

### Volúmenes

El código fuente está montado como volumen, por lo que los cambios se reflejan automáticamente en el contenedor.

## 🐛 Solución de Problemas

### Error: "Port already in use"

Si el puerto está en uso, cambia el puerto en `docker-compose.yml`:

```yaml
ports:
  - "3000:39421"  # Cambia 39421 por otro puerto
```

### Error: "Flutter not found"

Asegúrate de que la imagen se construyó correctamente:

```bash
docker-compose build --no-cache
```

### Limpiar cache de Flutter

```bash
docker-compose exec flutter-dev flutter clean
docker-compose exec flutter-dev flutter pub get
```

### Reconstruir desde cero

```bash
docker-compose down -v
docker-compose build --no-cache
docker-compose up
```

## 📦 Estructura

```
.
├── Dockerfile              # Imagen base con Flutter
├── docker-compose.yml      # Configuración de servicios
├── .dockerignore          # Archivos excluidos del build
└── README_DOCKER.md       # Esta guía
```

## 🔄 Flujo de Trabajo Recomendado

1. **Desarrollo diario:**
   ```bash
   docker-compose up flutter-dev
   ```

2. **Probar build de producción:**
   ```bash
   docker-compose --profile production up flutter-prod
   ```

3. **Antes de commit:**
   ```bash
   docker-compose exec flutter-dev flutter analyze
   docker-compose exec flutter-dev flutter test
   ```

## 💡 Tips

- El contenedor mantiene el cache de `pub get` en un volumen separado para acelerar builds
- Los cambios en el código se reflejan automáticamente gracias a los volúmenes
- Puedes usar VS Code con la extensión "Remote - Containers" para desarrollar dentro del contenedor
