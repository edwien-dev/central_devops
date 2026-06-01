# Central DevOps

Repositorio centralizado de CI/CD con flujos reutilizables, acciones personalizadas y runners auto-hospedados para los proyectos del ecosistema.

## Estructura

```
.github/
├── actions/
│   └── maven/                    # Acción compuesta: instala Maven 3.9.6
│       ├── action.yml
│       └── apache-maven-3.9.6-bin.tar.gz
└── workflows/
    ├── a_reusable.yml            # Workflow reusable: checkout cross-repo con GitHub App token
    ├── runeje.yml                # Build y deploy de app Angular
    ├── runeje copy.yml           # (Obsoleto) Build+push Docker con Podman
    └── testdock.yml              # (Incompleto/deshabilitado) Build+push Docker con Docker CLI
```

---

## Workflows

### 1. `a_reusable.yml` — Checkout cross-repo con GitHub App

**Trigger:** `workflow_dispatch` (manual)

**Propósito:** Clonar un repositorio externo (`edwien-dev/fe-miapp`) usando un token generado por una GitHub App, útil para flujos que necesitan acceso a múltiples repos.

```mermaid
flowchart TD
    A[Inicio: workflow_dispatch] --> B[Mostrar GH_APP_ID y GH_APP_KEY]
    B --> C[Generar token con actions/create-github-app-token]
    C --> D[Checkout edwien-dev/fe-miapp<br>en repo_codigo/]
    D --> E[ls -la del repositorio clonado]
```

### 2. `runeje.yml` — Build Angular App

**Triggers:** `workflow_dispatch` | `workflow_call` (reutilizable)

**Runner:** `arc-normaliza-runner-set`

```mermaid
flowchart TD
    A[Inicio: workflow_dispatch / workflow_call] --> B[🧹 Checkout del repo]
    B --> C[Setup Node.js 22.x]
    C --> D[npm install]
    D --> E[ng build]
    E --> F[Capturar dist_path en GITHUB_OUTPUT]
    F --> G[Mostrar ruta del build]
    G --> H[Output: steps.build.outputs.dist_path]
```

**Salida:** `steps.build.outputs.dist_path` — útil para workflows que llaman a este.

### 3. `runeje copy.yml` — (Obsoleto) Build + Push Docker con Podman

**Trigger:** `workflow_dispatch`

**Propósito:** Versión anterior que instala Node.js, Java 22, kubectl, y construye/pushea una imagen Docker a Docker Hub usando Podman.

```mermaid
flowchart TD
    A[Inicio: workflow_dispatch] --> B[🧹 Checkout del repo]
    B --> C[Setup Node.js 22.x]
    C --> D[Setup Java 22 - Temurin]
    D --> E[Ver kubectl version]
    E --> F[Login Docker Hub con Podman]
    F --> G[Build imagen con Podman]
    G --> H[Push imagen a Docker Hub]
```

> ⚠️ **Riesgo de seguridad:** contiene un token de Docker Hub hardcodeado (`dckr_pat_...`). Se recomienda migrar a secrets o eliminarlo.

### 4. `testdock.yml` — (Incompleto) Build + Push Docker con Docker CLI

**Trigger:** `workflow_dispatch`

**Propósito:** Plantilla deshabilitada. Instala Java 17 + Maven (vía acción compuesta) y tiene pasos para build/push Docker pero todos con `if: false`.

```mermaid
flowchart TD
    A[Inicio: workflow_dispatch] --> B[🧹 Checkout del repo]
    B --> C[Setup Java 17 - Temurin]
    C --> D[Instalar Maven 3.9.6<br>vía acción compuesta]
    D --> E[Validar Azure CLI<br>if: false ❌]
    E --> F[Login Docker Hub<br>if: false ❌]
    F --> G[Build imagen Docker<br>if: false ❌]
    G --> H[Push imagen Docker<br>if: false ❌]
    style E fill:#f88,stroke:#c00
    style F fill:#f88,stroke:#c00
    style G fill:#f88,stroke:#c00
    style H fill:#f88,stroke:#c00
```

**Nota:** Los pasos de validación de Azure CLI y Docker están desactivados. Este workflow está en estado de esqueleto/incompleto.

---

## Acciones Personalizadas

### `maven` (`actions/maven/action.yml`)

Acción compuesta que instala Apache Maven 3.9.6 desde un tarball incluido en el repo.

```mermaid
flowchart TD
    A[Inicio: acción compuesta] --> B[Extraer apache-maven-3.9.6-bin.tar.gz<br>en el workspace]
    B --> C[Agregar MAVEN_DIR/bin al GITHUB_PATH]
    C --> D[Verificar: mvn --version]
```

**Pasos:**
1. Extrae `apache-maven-3.9.6-bin.tar.gz` en el workspace
2. Agrega el directorio `bin/` de Maven al `PATH` via `GITHUB_PATH`
3. Verifica con `mvn --version`

**Uso:**
```yaml
- uses: edwien-dev/central_devops/.github/actions/maven@main
```

---

## Consideraciones de Seguridad

- **Tokens hardcodeados:** Los workflows `runeje.yml` y `runeje copy.yml` contienen un token de Docker Hub (`dckr_pat_...`) en texto plano. Debe migrarse a [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions).
- **Secrets mostrados:** `a_reusable.yml` imprime `GH_APP_ID` y `GH_APP_KEY` en los logs; debería eliminarse en producción.
- **Runner auto-hospedado:** Los runners `arc-normaliza-runner-set` y `self-hosted` requieren medidas de seguridad adicionales (solo workflows confiables).

## Recomendaciones

1. Migrar tokens a `${{ secrets.DOCKERHUB_TOKEN }}`
2. Eliminar `runeje copy.yml` si ya no se usa (es duplicado obsoleto)
3. Completar o eliminar `testdock.yml` si no tiene propósito actual
4. Usar `workflow_call` en `runeje.yml` para orquestar builds desde otros repos
