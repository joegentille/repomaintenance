# Push Images a GitHub Container Registry (GHCR)

Este proyecto contiene scripts para hacer push de imágenes Docker al GitHub Container Registry (GHCR) de forma automatizada y segura.

## 📋 Requisitos

- Docker instalado y en funcionamiento
- Cuenta de GitHub
- Token de GitHub con permisos de `write:packages` y `read:packages`
- PowerShell 5.0+ (para el script `.ps1`)
- Bash (para el script `.sh`)

## 🔐 Obtener un Token de GitHub

1. Ve a https://github.com/settings/tokens
2. Haz clic en "Generate new token" (Classic)
3. Selecciona los siguientes permisos:
   - `write:packages` - Para hacer push de paquetes/imágenes
   - `read:packages` - Para leer paquetes
   - `repo` - Acceso completo al repositorio (opcional pero recomendado)
4. Copia el token generado (se muestra una sola vez)
5. **Guarda el token en un lugar seguro**

## 📝 Configuración

### Opción 1: Variable de Entorno (Recomendada)

#### Windows (PowerShell):
```powershell
$env:GITHUB_TOKEN = "tu_token_aqui"
# O permanentemente:
[Environment]::SetEnvironmentVariable("GITHUB_TOKEN", "tu_token_aqui", "User")
```

#### Linux/Mac (Bash):
```bash
export GITHUB_TOKEN="tu_token_aqui"
# O permanentemente, añade a ~/.bashrc o ~/.bash_profile:
echo 'export GITHUB_TOKEN="tu_token_aqui"' >> ~/.bashrc
source ~/.bashrc
```

### Opción 2: Archivo .env (NO recomendada para tokens reales)

Crea un archivo `.env` en la raíz del proyecto:
```
GITHUB_TOKEN=tu_token_aqui
GITHUB_USERNAME=tu_usuario_github
```

**⚠️ ADVERTENCIA**: Nunca haga commit del archivo `.env` con tokens reales. Usa solo para desarrollo local.

## 🚀 Uso

### Script PowerShell (Windows)

#### Opción 1: Ejecución interactiva (más segura)
```powershell
.\PushToGHCR.ps1
```
El script te pedirá:
- URL de la imagen Docker
- Usuario de GitHub
- Token de GitHub (o lo leerá de la variable de entorno)
- Nombre del repositorio en GHCR

#### Opción 2: Con parámetros
```powershell
.\PushToGHCR.ps1 -SourceImage "ubuntu:latest" `
                 -GitHubUsername "tu_usuario" `
                 -TargetRepository "mi-ubuntu" `
                 -GitHubToken "ghp_xxxxx"
```

#### Opción 3: Con variable de entorno (más segura)
```powershell
$env:GITHUB_TOKEN = "your_token_here"
.\PushToGHCR.ps1 -SourceImage "ubuntu:latest" `
                 -GitHubUsername "tu_usuario" `
                 -TargetRepository "mi-ubuntu"
```

### Script Bash (Linux/Mac/WSL)

#### Opción 1: Ejecución interactiva (más segura)
```bash
chmod +x push-to-ghcr.sh
./push-to-ghcr.sh
```

#### Opción 2: Con parámetros
```bash
./push-to-ghcr.sh "ubuntu:latest" "nombre-repo" "tu_usuario" "tu_token"
```

#### Opción 3: Con variable de entorno
```bash
export GITHUB_TOKEN="your_token_here"
./push-to-ghcr.sh "ubuntu:latest" "nombre-repo" "tu_usuario"
```

## 📋 Ejemplos Prácticos

### Ejemplo 1: Copiar una imagen de Docker Hub a GHCR

```powershell
.\PushToGHCR.ps1 -SourceImage "nginx:latest" `
                 -GitHubUsername "joegentille" `
                 -TargetRepository "nginx-repo"
```

Resultado: `ghcr.io/joegentille/nginx-repo:latest`

### Ejemplo 2: Copiar una imagen de Azure Container Registry

```powershell
.\PushToGHCR.ps1 -SourceImage "myregistry.azurecr.io/MyApp:v1.0" `
                 -GitHubUsername "joegentille" `
                 -TargetRepository "myapp"
```

Resultado: `ghcr.io/joegentille/myapp:v1.0`

### Ejemplo 3: Copiar desde otro registry privado

```bash
./push-to-ghcr.sh "my-private-registry.io/myimage:v2.0" "myimage" "tu_usuario"
```

## 🔄 Flujo del Script

1. **Validación**: Verifica que Docker esté disponible
2. **Autenticación**: Autentica con GHCR usando el token
3. **Descarga**: Descarga (pull) la imagen del origen
4. **Etiquetado**: Aplica el tag con el formato de GHCR
5. **Push**: Sube la imagen a GHCR
6. **Limpieza**: Elimina las imágenes locales (opcional)

## 📦 Usar las imágenes después de hacer push

Después de que el script finalice exitosamente, puedes descargar la imagen con:

```bash
docker pull ghcr.io/tu_usuario/nombre-repo:latest
```

## 🔒 Buenas Prácticas de Seguridad

1. **Nunca haga commit de tokens**: No incluyas tokens en archivos versionados
2. **Usa variables de entorno**: Siempre prefiere variables de entorno sobre parámetros
3. **Tokens con scopes limitados**: Solo asigna los permisos necesarios al token
4. **Rotación de tokens**: Regenera tokens regularmente
5. **Uso de secretos en CI/CD**: En GitHub Actions, usa `secrets` en lugar de tokens visibles

## 🛠️ Solución de Problemas

### Error: "Docker not found"
- Instala Docker desde https://www.docker.com/products/docker-desktop
- Asegúrate de que Docker Desktop esté en ejecución (Windows/Mac)

### Error: "Authentication failed"
- Verifica que el token sea válido y no esté expirado
- Confirma que el usuario de GitHub sea correcto
- Checkea los permisos del token (`write:packages`)

### Error: "Image not found"
- Verifica que la URL de la imagen Docker sea correcta
- La imagen debe ser pública o debes tener credenciales para acceder

### Error: "Permission denied"
- En Linux/WSL, quizás necesites permisos de Docker: `sudo usermod -aG docker $USER`
- Reinicia la sesión de terminal

## � Integración con GitHub Actions

Este proyecto incluye tres workflows automáticos para facilitar el push a GHCR:

### 1. **push-to-ghcr-manual.yml** - Ejecución Manual Interactiva

Dispara la acción manualmente desde la UI de GitHub Actions.

**Cómo usar:**

1. Ve a tu repositorio → **Actions**
2. Selecciona **"Push Docker Image to GHCR"**
3. Haz clic en **"Run workflow"**
4. Ingresa los parámetros:
   - **Source Image**: `ubuntu:latest`
   - **Repository Name**: `mi-ubuntu`
   - **Image Tag**: `latest` (opcional)
5. Espera a que se complete el workflow

**Ventajas:**
- ✅ No requiere configuración previa
- ✅ Ingreso interactivo de parámetros
- ✅ Genera resumen automático
- ✅ Usa `secrets.GITHUB_TOKEN` de forma segura

### 2. **push-to-ghcr-auto.yml** - Ejecución Automática (Scheduled)

Procesa múltiples imágenes definidas en `images-config.json`.

**Cómo usar:**

1. Edita `images-config.json`:

```json
{
  "include": [
    {
      "source_image": "ubuntu:latest",
      "repository_name": "ubuntu",
      "tag": "latest"
    },
    {
      "source_image": "nginx:latest",
      "repository_name": "nginx",
      "tag": "1.25"
    }
  ]
}
```

2. Haz commit y push:

```bash
git add images-config.json .github/workflows/
git commit -m "Add images to GHCR pipeline"
git push
```

3. El workflow se ejecutará:
   - 📅 Automáticamente cada día a las 2:00 AM UTC
   - 🔄 Cada vez que cambies `images-config.json`
   - 🔘 Manualmente desde GitHub Actions

**Ventajas:**
- ✅ Procesa múltiples imágenes en paralelo
- ✅ Automatización programada (schedules)
- ✅ Fácil de mantener (archivo JSON)
- ✅ Genera reportes por cada imagen

### 3. **push-to-ghcr-reusable.yml** - Workflow Reutilizable

Llama desde otros workflows o repositorios.

**Cómo usar en otro workflow:**

```yaml
name: My Custom Workflow

on: [push]

jobs:
  push-images:
    uses: tu-usuario/Task_PushImages/.github/workflows/push-to-ghcr-reusable.yml@main
    with:
      source_image: ubuntu:latest
      repository_name: mi-ubuntu
      image_tag: v1.0.0
```

**Ventajas:**
- ✅ Reutilizable en otros repos
- ✅ Encapsulado y limpio
- ✅ Fácil de integrar en pipelines complejos

---

## 🔐 Configuración Necesaria para GitHub Actions

### Permisos Requeridos

Los workflows usan `secrets.GITHUB_TOKEN` que se genera automáticamente. **No necesitas hacer nada especial**, pero puedes verificar:

1. Ve a **Settings** → **Actions** → **General**
2. Desplázate a **"Workflow permissions"**
3. Selecciona: **"Read and write permissions"**
4. ✅ Marca: **"Allow GitHub Actions to create and approve pull requests"**

### Variables de Entorno (Opcional)

Puedes crear variables de entorno en tu repositorio:

1. **Settings** → **Secrets and variables** → **Actions** → **New repository secret**
2. Agrega:
   - `REGISTRY_PREFIX`: (opcional, default: `ghcr.io`)
   - `CUSTOM_USERNAME`: (opcional, para override del usuario)

---

## 📋 Tabla Comparativa de Workflows

| Workflow | Trigger | Entrada | Paralelo | Mejor para |
|----------|---------|---------|----------|-----------|
| **Manual** | Manual UI | Parámetros interactivos | ❌ | Testing, one-off pushes |
| **Auto** | Schedule/Push | Archivo JSON | ✅ | Múltiples imágenes, automatización |
| **Reusable** | workflow_call | Parámetros | ❌ | Integración con otros repos |

---

## 🎯 Ejemplos de Uso en GitHub Actions

### Ejemplo 1: Push Manual

```bash
# Ir a Actions → Push Docker Image to GHCR → Run workflow
# Ingresa:
# - Source Image: nginx:alpine
# - Repository Name: nginx-custom
# - Tag: 1.24-alpine
```

### Ejemplo 2: Push Automático (varias imágenes)

Actualiza `images-config.json`:

```json
{
  "include": [
    {
      "source_image": "golang:1.21",
      "repository_name": "golang-build",
      "tag": "1.21"
    },
    {
      "source_image": "node:20-alpine",
      "repository_name": "node-app",
      "tag": "20-alpine"
    },
    {
      "source_image": "postgres:15",
      "repository_name": "postgres-db",
      "tag": "15"
    }
  ]
}
```

Haz commit y push:

```bash
git add images-config.json
git commit -m "Add Go, Node, and PostgreSQL images to sync"
git push
```

Los 3 pushes se ejecutarán en paralelo automáticamente.

### Ejemplo 3: Integración en CI/CD

En otro workflow, llama al reusable:

```yaml
name: Build and Push

on:
  release:
    types: [published]

jobs:
  push-to-registry:
    uses: tu-usuario/Task_PushImages/.github/workflows/push-to-ghcr-reusable.yml@main
    with:
      source_image: ${{ github.event.release.name }}
      repository_name: my-app
      image_tag: ${{ github.ref_name }}
```

---

## 🐛 Solución de Problemas (GitHub Actions)

### ❌ Error: "Permission denied"

**Solución:**
1. **Settings** → **Actions** → **General**
2. En "Workflow permissions", selecciona **"Read and write permissions"**
3. Guarda y reintentar

### ❌ Error: "Image not found"

**Solución:**
- Verifica que la URL en `images-config.json` sea pública
- O proporciona credenciales para registries privados

### ❌ El workflow no se ejecuta

**Solución:**
1. Verifica que `.github/workflows/` esté en la rama principal
2. Haz commit con: `git add .github/`
3. Redeploy: `git push`
4. Ve a **Actions** y verifica si aparece el workflow

### 📊 Ver logs del workflow

1. **Actions** → Selecciona el workflow
2. Haz clic en el run que quieras inspeccionar
3. Expande **"Push to GHCR"** para ver detalles

---

## �📄 Licencia

Este proyecto es de código libre, úsalo como desees.

## 📧 Soporte

Para reportar problemas o sugerencias, abre un issue en el repositorio.
