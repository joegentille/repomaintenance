# Quick Start - GitHub Actions

Guía rápida para comenzar a usar GitHub Actions con GHCR.

## ⚡ 5 Minutos - Setup Inicial

### 1. Verificar Permisos (1 min)

En tu repo GitHub:

```
Settings → Actions → General
  ↓
Workflow permissions: Read and write permissions ✅
  ↓
Save
```

### 2. Hacer Push del Código (1 min)

Desde tu terminal:

```bash
cd d:\@ProyectosGeneral\DevOpsEngineer\GitHub\Task_PushImages

# Verificar archivos
ls -la .github/workflows/

# Hacer commit
git add .github/workflows/ images-config.json
git commit -m "Add GitHub Actions workflows for GHCR push"
git push
```

### 3. Verificar en GitHub (1 min)

```
GitHub → Actions
  ↓
Debes ver 3 workflows:
  ✅ Push Docker Image to GHCR (manual)
  ✅ Push Docker Image from URL to GHCR (auto)
  ✅ Push Multiple Images from Config (reusable)
```

### 4. Ejecutar tu Primer Push (2 min)

**Opción A: Manual (Recomendado para primeras pruebas)**

```
GitHub → Actions
  ↓
"Push Docker Image to GHCR"
  ↓
"Run workflow" (azul)
  ↓
source_image: ubuntu:latest
repository_name: ubuntu-test
image_tag: v1.0
  ↓
"Run workflow" (verde)
```

**Opción B: Automático (Procesa múltiples en paralelo)**

1. Edita `images-config.json`:

```json
{
  "include": [
    {
      "source_image": "ubuntu:latest",
      "repository_name": "ubuntu-test",
      "tag": "latest"
    },
    {
      "source_image": "nginx:latest",
      "repository_name": "nginx-test",
      "tag": "latest"
    }
  ]
}
```

2. Push:

```bash
git add images-config.json
git commit -m "Sync images to GHCR"
git push
```

El workflow se ejecutará automáticamente.

---

## 📊 Comparación Rápida

| Método | Ventaja | Tiempo |
|--------|---------|--------|
| **Script Local (PS1)** | Total control, sin red | ~1-2 min |
| **Script Local (Bash)** | Portable, máxima flexibilidad | ~1-2 min |
| **GitHub Actions Manual** | Sin instalaciones, basado en UI | ~1-2 min |
| **GitHub Actions Auto** | Múltiples imágenes, scheduled | ~2-3 min |

---

## 🎯 Próximos Pasos

### Personalizar `images-config.json`

Reemplaza con tus imágenes reales:

```json
{
  "include": [
    {
      "source_image": "python:3.11-slim",
      "repository_name": "python-app",
      "tag": "3.11"
    },
    {
      "source_image": "node:20-alpine",
      "repository_name": "node-app",
      "tag": "20"
    },
    {
      "source_image": "postgresql:15",
      "repository_name": "postgres",
      "tag": "15"
    }
  ]
}
```

### Usar con Builds Personalizados

Si tienes un Dockerfile, crea un workflow custom:

```yaml
# .github/workflows/build-and-push.yml
name: Build and Push Custom Image

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v4
      
      - name: Build image
        run: |
          docker build -t ghcr.io/${{ github.repository_owner }}/myapp:latest .
      
      - name: Login to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Push image
        run: |
          docker push ghcr.io/${{ github.repository_owner }}/myapp:latest
```

---

## ❌ Troubleshooting Rápido

| Problema | Solución |
|----------|----------|
| **Workflow no ejecuta** | Haz push a la rama principal (main/master) |
| **Permission denied** | Settings → Actions → "Read and write" |
| **Image not found** | Verifica que la imagen sea pública |
| **Push lento** | Es normal (~1-2 min por imagen) |

---

## 🔗 Recursos

- [Ver Logs](https://docs.github.com/en/actions/monitoring-and-troubleshooting-workflows/about-workflow-runs)
- [Guía Completa](./GITHUB_ACTIONS_GUIDE.md)
- [README Principal](./README.md)

---

**¿Listo?** Haz push del código y ejecuta tu primer workflow. ¡Debería funcionar en 2-3 minutos!
