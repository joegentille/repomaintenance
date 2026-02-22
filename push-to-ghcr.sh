#!/bin/bash

# Script para hacer push de imágenes Docker al GitHub Container Registry (GHCR)
# Uso: ./push-to-ghcr.sh [SOURCE_IMAGE] [REPOSITORY_NAME] [GITHUB_USERNAME] [GITHUB_TOKEN]

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funciones de utilidad
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Función para limpiar en caso de error
cleanup() {
    print_info "Limpiando recursos..."
    if [ ! -z "$FULL_TARGET_IMAGE" ]; then
        docker rmi "$SOURCE_IMAGE" "$FULL_TARGET_IMAGE" --force 2>/dev/null || true
    fi
}

trap cleanup EXIT

# Variables
SOURCE_IMAGE="${1:-}"
REPOSITORY_NAME="${2:-}"
GITHUB_USERNAME="${3:-}"
GITHUB_TOKEN="${4:-}"
GHCR_REGISTRY="ghcr.io"

# Solicitar entrada si no se proporcionan parámetros
if [ -z "$SOURCE_IMAGE" ]; then
    print_info "Ingrese la URL de la imagen Docker (ej: ubuntu:latest, nginx:1.21, etc.)"
    read -p "Imagen Docker: " SOURCE_IMAGE
    [ -z "$SOURCE_IMAGE" ] && print_error "La imagen Docker es requerida." && exit 1
fi

if [ -z "$GITHUB_USERNAME" ]; then
    print_info "Ingrese su usuario de GitHub"
    read -p "Usuario GitHub: " GITHUB_USERNAME
    [ -z "$GITHUB_USERNAME" ] && print_error "El usuario de GitHub es requerido." && exit 1
fi

if [ -z "$REPOSITORY_NAME" ]; then
    print_info "Ingrese el nombre del repositorio en GHCR (ej: mi-app, image-name)"
    read -p "Nombre del repositorio: " REPOSITORY_NAME
    [ -z "$REPOSITORY_NAME" ] && print_error "El nombre del repositorio es requerido." && exit 1
fi

if [ -z "$GITHUB_TOKEN" ]; then
    if [ ! -z "$GITHUB_TOKEN_ENV" ]; then
        GITHUB_TOKEN="$GITHUB_TOKEN_ENV"
        print_success "Token obtenido de variable de entorno GITHUB_TOKEN"
    else
        print_warning "Se requiere un token de GitHub para hacer push."
        print_info "Ingresa tu token de GitHub (será enmascarado)"
        read -sp "Token GitHub: " GITHUB_TOKEN
        echo
        [ -z "$GITHUB_TOKEN" ] && print_error "Token no proporcionado." && exit 1
    fi
fi

# Construir la URL de GHCR
FULL_TARGET_IMAGE="$GHCR_REGISTRY/$GITHUB_USERNAME/$REPOSITORY_NAME"

echo ""
print_info "Iniciando proceso de push a GHCR..."
print_info "Imagen origen: $SOURCE_IMAGE"
print_info "Destino: $FULL_TARGET_IMAGE"
echo ""

# Paso 1: Verificar que Docker esté disponible
print_info "[1/5] Verificando Docker..."
if ! command -v docker &> /dev/null; then
    print_error "Docker no está disponible. Por favor, instálalo."
    exit 1
fi
DOCKER_VERSION=$(docker --version)
print_success "Docker encontrado: $DOCKER_VERSION"

# Paso 2: Hacer login en GHCR
print_info "[2/5] Autenticando con GHCR..."
if echo "$GITHUB_TOKEN" | docker login "$GHCR_REGISTRY" -u "$GITHUB_USERNAME" --password-stdin &>/dev/null; then
    print_success "Login exitoso en $GHCR_REGISTRY"
else
    print_error "Error al autenticar con GHCR. Verifica tus credenciales."
    exit 1
fi

# Paso 3: Hacer pull de la imagen origen
print_info "[3/5] Descargando imagen: $SOURCE_IMAGE..."
if docker pull "$SOURCE_IMAGE" --quiet; then
    print_success "Imagen descargada exitosamente"
else
    print_error "Error al descargar la imagen. Verifica que la URL sea correcta."
    exit 1
fi

# Paso 4: Hacer tag de la imagen
print_info "[4/5] Etiquetando imagen como: $FULL_TARGET_IMAGE..."
if docker tag "$SOURCE_IMAGE" "$FULL_TARGET_IMAGE"; then
    print_success "Imagen etiquetada exitosamente"
else
    print_error "Error al etiquetar la imagen."
    exit 1
fi

# Paso 5: Hacer push de la imagen a GHCR
print_info "[5/5] Haciendo push de la imagen a GHCR..."
if docker push "$FULL_TARGET_IMAGE"; then
    print_success "¡Imagen publicada exitosamente en GHCR!"
else
    print_error "Error al hacer push de la imagen."
    exit 1
fi

echo ""
print_success "¡Proceso completado exitosamente!"
print_info "Puedes descargar la imagen con: docker pull $FULL_TARGET_IMAGE"
