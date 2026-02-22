# Script para hacer push de imágenes Docker al GitHub Container Registry (GHCR)
# Uso: .\PushToGHCR.ps1

param(
    [string]$SourceImage,
    [string]$TargetRepository,
    [string]$GitHubToken,
    [string]$GitHubUsername
)

# Colores para output
$SuccessColor = "Green"
$ErrorColor = "Red"
$InfoColor = "Cyan"
$WarningColor = "Yellow"

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor $SuccessColor
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor $ErrorColor
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor $InfoColor
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor $WarningColor
}

# Si no se proporcionan parámetros, pedir al usuario
if (-not $SourceImage) {
    Write-Info "Ingrese la URL de la imagen Docker (ej: ubuntu:latest, nginx:1.21, etc.)"
    $SourceImage = Read-Host "Imagen Docker"
    
    if (-not $SourceImage) {
        Write-Error-Custom "La imagen Docker es requerida."
        exit 1
    }
}

if (-not $GitHubUsername) {
    Write-Info "Ingrese su usuario de GitHub"
    $GitHubUsername = Read-Host "Usuario GitHub"
    
    if (-not $GitHubUsername) {
        Write-Error-Custom "El usuario de GitHub es requerido."
        exit 1
    }
}

if (-not $GitHubToken) {
    Write-Warning-Custom "Se requiere un token de GitHub para hacer push."
    Write-Info "Puedes proporcionar el token como parámetro o será solicitado interactivamente."
    $GitHubToken = Read-Host "Token GitHub (o deja vacío para usar variable de entorno)" -AsSecureString
    
    if ($GitHubToken.Length -eq 0) {
        if (Test-Path Env:\GITHUB_TOKEN) {
            $GitHubToken = $env:GITHUB_TOKEN
            Write-Success "Token obtenido de variable de entorno GITHUB_TOKEN"
        } else {
            Write-Error-Custom "Token no proporcionado y variable GITHUB_TOKEN no existe."
            exit 1
        }
    } else {
        # Convertir SecureString a texto plano
        $GitHubToken = [System.Net.NetworkCredential]::new('', $GitHubToken).Password
    }
}

if (-not $TargetRepository) {
    Write-Info "Ingrese el nombre del repositorio en GHCR (ej: mi-app, image-name)"
    $TargetRepository = Read-Host "Nombre del repositorio"
    
    if (-not $TargetRepository) {
        Write-Error-Custom "El nombre del repositorio es requerido."
        exit 1
    }
}

# Construir la URL de GHCR
$GHCRRegistry = "ghcr.io"
$FullTargetImage = "$GHCRRegistry/$GitHubUsername/$TargetRepository"

Write-Info "Iniciando proceso de push a GHCR..."
Write-Info "Imagen origen: $SourceImage"
Write-Info "Destino: $FullTargetImage"
Write-Info ""

# Paso 1: Verificar que Docker esté disponible
Write-Info "[1/5] Verificando Docker..."
try {
    $dockerVersion = docker --version
    Write-Success "Docker encontrado: $dockerVersion"
} catch {
    Write-Error-Custom "Docker no está disponible. Por favor, instálalo y asegúrate de que esté en tu PATH."
    exit 1
}

# Paso 2: Hacer login en GHCR
Write-Info "[2/5] Autenticando con GHCR..."
try {
    # Usar echo para pasar el token de forma segura
    $GitHubToken | docker login $GHCRRegistry -u $GitHubUsername --password-stdin 2>&1 | Out-Null
    Write-Success "Login exitoso en $GHCRRegistry"
} catch {
    Write-Error-Custom "Error al autenticar con GHCR: $_"
    exit 1
}

# Paso 3: Hacer pull de la imagen origen
Write-Info "[3/5] Descargando imagen: $SourceImage..."
try {
    docker pull $SourceImage --quiet
    if ($LASTEXITCODE -ne 0) {
        throw "Error al descargar la imagen"
    }
    Write-Success "Imagen descargada exitosamente"
} catch {
    Write-Error-Custom "Error al descargar la imagen: $_"
    exit 1
}

# Paso 4: Hacer tag de la imagen
Write-Info "[4/5] Etiquetando imagen como: $FullTargetImage..."
try {
    docker tag $SourceImage $FullTargetImage
    if ($LASTEXITCODE -ne 0) {
        throw "Error al etiquetar la imagen"
    }
    Write-Success "Imagen etiquetada exitosamente"
} catch {
    Write-Error-Custom "Error al etiquetar la imagen: $_"
    exit 1
}

# Paso 5: Hacer push de la imagen a GHCR
Write-Info "[5/5] Haciendo push de la imagen a GHCR..."
try {
    docker push $FullTargetImage
    if ($LASTEXITCODE -ne 0) {
        throw "Error al hacer push de la imagen"
    }
    Write-Success "¡Imagen publicada exitosamente en GHCR!"
} catch {
    Write-Error-Custom "Error al hacer push: $_"
    exit 1
}

# Limpiar localmente (opcional)
Write-Info ""
Write-Info "Limpiando imágenes locales..."
docker rmi $SourceImage, $FullTargetImage -f | Out-Null
Write-Success "Limpiezacompleta"

Write-Info ""
Write-Success "¡Proceso completado exitosamente!"
Write-Info "Puedes descargar la imagen con: docker pull $FullTargetImage"
