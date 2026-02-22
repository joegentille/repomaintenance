# GitHub Actions - Guía Detallada

Este documento explica cómo funcionan y cómo usar los workflows de GitHub Actions para automatizar el push a GHCR.

## 📚 Tabla de Contenidos

1. [Conceptos Básicos](#conceptos-básicos)
2. [Workflow Manual](#workflow-manual)
3. [Workflow Automático](#workflow-automático)
4. [Workflow Reutilizable](#workflow-reutilizable)
5. [Configuración de Permisos](#configuración-de-permisos)
6. [Monitoreo y Debugging](#monitoreo-y-debugging)

---

## 🎓 Conceptos Básicos

### ¿Qué es un Workflow?

Un workflow es un proceso automatizado que se ejecuta en respuesta a eventos en tu repositorio.

```
Evento (push, schedule, manual)
    ↓
Trigger (dispara el workflow)
    ↓
Job (unidad de trabajo)
    ↓
Steps (pasos individuales)
    ↓
Resultado (éxito/fallo)
```

### Estructura Básica

```yaml
name: Mi Workflow

on:                    # Qué dispara el workflow
  push:
    branches: [main]

jobs:                  # Trabajos a ejecutar
  my-job:
    runs-on: ubuntu-latest
    steps:             # Pasos del job
      - uses: actions/checkout@v4
      - run: echo "Hello"
```

---

## 🎬 Workflow Manual (`push-to-ghcr-manual.yml`)

### ¿Cuándo usarlo?

- ✅ Testing de una imagen
- ✅ Push occasional sin automatización
- ✅ No necesitas configuración previa

### Estructura

```yaml
on:
  workflow_dispatch:    # Permite ejecución manual
    inputs:            # Parámetros interactivos
      source_image:
        description: 'Source Docker image'
        required: true
      repository_name:
        description: 'Target repo name'
        required: true
      image_tag:
        description: 'Image tag'
        required: false
        default: 'latest'
```

### Cómo Ejecutarlo

**Opción 1: Desde la UI**

```
1. GitHub.com → Tu repo
2. Actions → "Push Docker Image to GHCR"
3. "Run workflow" (botón azul)
4. Completa los campos
5. "Run workflow" (confirmar)
```

**Opción 2: Con GitHub CLI**

```bash
gh workflow run push-to-ghcr-manual.yml \
  -f source_image=ubuntu:latest \
  -f repository_name=mi-ubuntu \
  -f image_tag=v1.0
```

### Permisos Automáticos

El workflow usa `secrets.GITHUB_TOKEN` que se genera automáticamente. No necesitas hacer nada.

### Ejemplo de Ejecución

```
Entrada:
├── source_image: nginx:latest
├── repository_name: nginx-copy
└── image_tag: 1.25

Ejecución:
1. ✅ Login a GHCR
2. ✅ Pull de nginx:latest
3. ✅ Tag como ghcr.io/tu-user/nginx-copy:1.25
4. ✅ Push a GHCR
5. ✅ Limpieza local
6. ✅ Resumen en job summary

Resultado:
✅ Imagen disponible en ghcr.io/tu-user/nginx-copy:1.25
```

---

## ⚙️ Workflow Automático (`push-to-ghcr-auto.yml`)

### ¿Cuándo usarlo?

- ✅ Sync de múltiples imágenes
- ✅ Actualizaciones programadas
- ✅ Pipeline de CI/CD

### Cómo Funciona

1. **Lee** `images-config.json`
2. **Genera** una matriz de imágenes
3. **Procesa** en paralelo
4. **Reporta** resultados

### Estructura del Config

```json
{
  "include": [
    {
      "source_image": "ubuntu:latest",
      "repository_name": "ubuntu",
      "tag": "latest"
    },
    {
      "source_image": "nginx:alpine",
      "repository_name": "nginx",
      "tag": "alpine"
    }
  ]
}
```

### Qué Dispara el Workflow

```yaml
on:
  schedule:
    - cron: '0 2 * * *'      # Diario 2 AM UTC
  push:
    paths:
      - 'images-config.json' # Cambios en config
      - '.github/workflows/push-to-ghcr-auto.yml'
  workflow_dispatch:          # Manual
```

### Ejecución en Paralelo

```
Lectura: images-config.json
    ↓
Matriz:
    Job 1 (ubuntu)      Job 2 (nginx)
        ↓                   ↓
    Pull ubuntu         Pull nginx
    Tag ubuntu          Tag nginx
    Push ubuntu         Push nginx
        ↓                   ↓
    ✅ ubuntu ready     ✅ nginx ready
```

### Ejemplo Práctico

**Archivo: images-config.json**

```json
{
  "include": [
    {
      "source_image": "golang:1.21-alpine",
      "repository_name": "golang",
      "tag": "1.21-alpine"
    },
    {
      "source_image": "node:20-slim",
      "repository_name": "node",
      "tag": "20-slim"
    },
    {
      "source_image": "rust:latest",
      "repository_name": "rust",
      "tag": "latest"
    }
  ]
}
```

**Resultado:**

```
Ejecución en paralelo:
├── golang:1.21-alpine → ghcr.io/user/golang:1.21-alpine ✅
├── node:20-slim → ghcr.io/user/node:20-slim ✅
└── rust:latest → ghcr.io/user/rust:latest ✅

Tiempo total: ~2-3 min (paralelo)
vs ~6-9 min (secuencial)
```

---

## 🔄 Workflow Reutilizable (`push-to-ghcr-reusable.yml`)

### ¿Cuándo usarlo?

- ✅ Integración en otros workflows
- ✅ Reutilización en múltiples repos
- ✅ Abstracción de lógica compleja

### Cómo Definir Entradas

```yaml
on:
  workflow_call:
    inputs:
      source_image:
        description: 'Source Docker image'
        required: true
        type: string
      repository_name:
        description: 'Target repository'
        required: true
        type: string
      image_tag:
        description: 'Image tag'
        required: false
        type: string
        default: 'latest'
```

### Cómo Llamarlo desde Otro Workflow

**Archivo: .github/workflows/my-cicd.yml**

```yaml
name: Mi Pipeline CI/CD

on:
  push:
    branches: [main]

jobs:
  sync-image:
    uses: tu-usuario/Task_PushImages/.github/workflows/push-to-ghcr-reusable.yml@main
    with:
      source_image: ${{ github.event.repository.name }}:${{ github.sha }}
      repository_name: ${{ github.event.repository.name }}
      image_tag: ${{ github.ref_name }}
```

### Llamarlo desde Múltiples Workflows

```yaml
# .github/workflows/build.yml
jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: docker build -t myapp:latest .
      - name: Push to GHCR
        uses: tu-usuario/Task_PushImages/.github/workflows/push-to-ghcr-reusable.yml@main
        with:
          source_image: myapp:latest
          repository_name: myapp
          image_tag: latest
```

---

## 🔐 Configuración de Permisos

### Paso 1: Verificar Permisos de Workflow

1. **Settings** → **Code and automation** → **Actions** → **General**
2. Desplázate a **"Workflow permissions"**
3. Selecciona:
   - ✅ **"Read and write permissions"**
   - ✅ **"Allow GitHub Actions to create and approve pull requests"** (opcional)
4. **Save**

### Paso 2: Entender GITHUB_TOKEN

`GITHUB_TOKEN` se genera automáticamente por GitHub con permisos limitados:

```
Permisos incluidos:
├── packages: read, write     ✅ Para GHCR
├── contents: read             ✅ Para checkout
└── pull-requests: read, write ✅ Para PRs
```

### Paso 3: Variables de Entorno (Opcional)

Puedes crear variables para reutilizar en workflows:

```
Settings → Secrets and variables → Actions
  ├── Secrets (encriptados en logs)
  │   └── REGISTRY_TOKEN (si necesitas registries privados)
  │
  └── Variables (visibles en logs)
      ├── REGISTRY: ghcr.io
      └── REGISTRY_PREFIX: my-org
```

### Paso 4: Usar Variables en Workflows

```yaml
env:
  REGISTRY: ${{ vars.REGISTRY || 'ghcr.io' }}
  REGISTRY_PREFIX: ${{ vars.REGISTRY_PREFIX }}

jobs:
  push:
    runs-on: ubuntu-latest
    steps:
      - name: Log in
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
```

---

## 🔍 Monitoreo y Debugging

### Ver Logs de un Workflow

**Desde la UI:**

```
1. Actions → Selecciona workflow
2. Haz clic en el run específico
3. Expande cada job para ver los steps
4. Haz clic en un step para ver logs detallados
```

**Output esperado:**

```
✅ Checkout code
✅ Set up Docker Buildx
✅ Log in to Container Registry
✅ Pull source image
  📥 Pulling image: ubuntu:latest
✅ Tag image for GHCR
  🏷️  Tagging as: ghcr.io/user/ubuntu:latest
✅ Push to GHCR
  🚀 Pushing image: ghcr.io/user/ubuntu:latest
✅ Clean up
✅ Create summary
```

### Habilitar Debug Logging

Si necesitas más detalles:

1. **Settings** → **Secrets and variables** → **Actions**
2. **New repository secret**
3. Nombre: `ACTIONS_STEP_DEBUG`
4. Valor: `true`
5. **Add secret**

### Problemas Comunes

#### ❌ Workflow no se ejecuta

**Causa:** Archivo YAML con errores de sintaxis

**Solución:**
```bash
# Valida el YAML
yaml-lint .github/workflows/push-to-ghcr-manual.yml
```

#### ❌ Permission denied en Docker push

**Causa:** Permisos de workflow insuficientes

**Solución:**
1. **Settings** → **Actions** → **General**
2. Selecciona **"Read and write permissions"**

#### ❌ Authentication failed para GHCR

**Causa:** Token inválido o expirado

**Solución:**
1. GitHub genera el token automáticamente
2. Verifica que el workflow use `secrets.GITHUB_TOKEN`
3. No uses tokens manuales si puedes evitarlo

#### ❌ Image not found

**Causa:** Imagen de origen no existe o es privada

**Solución:**
```bash
# Verifica localmente
docker pull ubuntu:latest

# Si es privada, agrega credenciales en el workflow
- name: Login to Docker Hub
  uses: docker/login-action@v3
  with:
    username: ${{ secrets.DOCKER_USERNAME }}
    password: ${{ secrets.DOCKER_PASSWORD }}
```

### Usar GitHub CLI para Debugging

```bash
# Ver últimos 10 runs
gh workflow run --repo tu-usuario/Task_PushImages \
  --list

# Ver los logs de un run específico
gh run view RUN_ID --log --repo tu-usuario/Task_PushImages

# Ver resumen de jobs
gh run view RUN_ID --repo tu-usuario/Task_PushImages
```

---

## 📊 Optimizaciones

### Cache de Docker

Para acelerar builds, usa Docker cache:

```yaml
- name: Set up Docker Buildx (with cache)
  uses: docker/setup-buildx-action@v3
  with:
    buildkitd-flags: --allow-insecure-entitlement security.insecure

- name: Build with cache
  uses: docker/build-push-action@v5
  with:
    context: .
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

### Matriz Dinámicas

Para procesar diferentes versiones:

```yaml
strategy:
  matrix:
    version: [3.9, 3.10, 3.11]
    include:
      - version: 3.11
        tag: latest

steps:
  - run: |
      docker pull python:${{ matrix.version }}-slim
      docker tag python:${{ matrix.version }}-slim \
                 ghcr.io/user/python:${{ matrix.tag || matrix.version }}
```

### Notificaciones

Notifica cuando termina un workflow:

```yaml
- name: Slack Notification
  if: always()
  uses: slackapi/slack-github-action@v1
  with:
    payload: |
      {
        "text": "Workflow ${{ job.status }}: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
      }
```

---

## 📚 Referencias

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Docker Login Action](https://github.com/docker/login-action)
- [GHCR Best Practices](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
