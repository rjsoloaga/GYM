# 🐳 Instrucciones para Construir el Contenedor Docker

## ⚠️ Requisito Previo

**Docker Desktop debe estar corriendo** antes de ejecutar cualquier comando.

### Cómo iniciar Docker Desktop en Windows:

1. Busca "Docker Desktop" en el menú de inicio
2. Haz clic para abrirlo
3. Espera a que el ícono de Docker aparezca en la bandeja del sistema (abajo a la derecha)
4. Verifica que esté corriendo: el ícono debe estar verde/activo

## 🔨 Construir la Imagen

Una vez que Docker Desktop esté corriendo, ejecuta:

```bash
docker-compose build
```

Este proceso puede tardar varios minutos la primera vez, ya que:
- Descarga la imagen base de Ubuntu
- Instala Flutter
- Descarga todas las dependencias de Flutter
- Instala las dependencias del proyecto

## ✅ Verificar que Docker está Corriendo

Antes de construir, verifica con:

```bash
docker ps
```

Si ves un error sobre "dockerDesktopLinuxEngine", significa que Docker Desktop no está corriendo.

## 🚀 Después de Construir

Una vez construida la imagen, puedes ejecutar:

```bash
# Modo desarrollo
docker-compose up flutter-dev

# O usando el script
.\docker-run.bat dev
```

## 🐛 Solución de Problemas

### Error: "The system cannot find the file specified"
- **Solución**: Inicia Docker Desktop

### Error: "Port already in use"
- **Solución**: Cambia el puerto en `docker-compose.yml` o cierra la aplicación que está usando el puerto

### Error durante el build
- **Solución**: Intenta con `docker-compose build --no-cache` para reconstruir desde cero
