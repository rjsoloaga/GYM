# Dockerfile para Flutter Gym App
FROM ubuntu:22.04

# Variables de entorno
ENV DEBIAN_FRONTEND=noninteractive
ENV FLUTTER_VERSION=3.24.0
ENV FLUTTER_HOME=/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    libgtk-3-0 \
    libblkid1 \
    liblzma5 \
    libpcre2-16-0 \
    libpcre3 \
    libuuid1 \
    ca-certificates \
    software-properties-common \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Instalar Flutter con configuración mejorada para evitar errores de red
RUN git config --global http.version HTTP/1.1 && \
    git config --global http.postBuffer 524288000 && \
    git clone --branch stable --depth 1 https://github.com/flutter/flutter.git ${FLUTTER_HOME} || \
    (git clone --branch stable https://github.com/flutter/flutter.git ${FLUTTER_HOME} && \
     git -C ${FLUTTER_HOME} fetch --unshallow) && \
    flutter config --no-analytics && \
    flutter precache --web

# Verificar instalación
RUN flutter doctor -v

# Configurar directorio de trabajo
WORKDIR /app

# Copiar archivos de dependencias primero (para cache de Docker)
COPY pubspec.yaml pubspec.lock* ./

# Instalar dependencias de Flutter
RUN flutter pub get

# Copiar el resto del código
COPY . .

# Exponer puerto para web
EXPOSE 8080 39421

# Comando por defecto (puede ser sobrescrito por docker-compose)
CMD ["flutter", "run", "-d", "web-server", "--web-port", "8080", "--web-hostname", "0.0.0.0"]