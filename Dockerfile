FROM ubuntu:22.04

# Instalar dependencias básicas
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    git \
    xz-utils \
    file \
    && rm -rf /var/lib/apt/lists/*

# Instalar Flutter MANUALMENTE (igual que en tu PC)
RUN git clone https://github.com/flutter/flutter.git /flutter
ENV PATH="$PATH:/flutter/bin"

# Precache para acelerar builds futuros
RUN flutter precache

WORKDIR /app

# Comando por defecto
CMD ["bash"]
