# softhsm (sidecar) - Plan de modificaciones (S1–S14)

Fuente de verdad para retomar este trabajo, incluyendo con Claude Code local sin el
contexto de la conversación en la que se generó. Lo marcado "cerrado" no necesita
re-investigación.

## Cerrado - sin acción pendiente, o acción ya tomada

**S1/S2. Credenciales en `k8s/hsm-secrets.yaml` y `k8s/migrations-job.yaml`**
El repo se hizo público a propósito para esta revisión, no estuvo expuesto todo el tiempo
sin saberlo. Rotar la master key AES, el PIN/SO-PIN, y la contraseña de MySQL sigue siendo
buena práctica antes de que el repo vuelva a privado (quedan en el historial de git de
cualquier forma), pero no es una emergencia activa. `k8s/hsm-secrets.yaml` sigue listado en
`.gitignore` sin estar realmente destrackeado (`git rm --cached k8s/hsm-secrets.yaml`
pendiente) - eso sí vale la pena resolverlo para que la regla empiece a funcionar.

**S3. `auth.mode: "development"` junto a `HSM_ENVIRONMENT: "production"`**
Contradicción real en `k8s/hsm-service-config.yaml` y el Deployment - sigue pendiente de
decidir/corregir, no descartado. Ver tabla de abajo.

**S4. `library.allow_export = true` en `k8s/softhsm-configmap.yaml`**
**Cerrado, verificado con evidencia real - no requiere cambio de código.**
`library.allow_export` no es una clave de configuración real de SoftHSM2 (confirmado
extrayendo las claves reconocidas del binario `libsofthsm2.so` 2.6.1: solo
`directories.tokendir`, `objectstore.backend`, `log.level`, `slots.removable`,
`slots.mechanisms`, `library.reset_on_fork` existen). La línea no hace nada. La protección
real ya está correctamente implementada en `hsm-service`:
`internal/infrastructure/hsm/client_keygen.go` setea `CKA_SENSITIVE=true` y
`CKA_EXTRACTABLE=false` en la plantilla de cada clave privada generada (RSA y ECDSA), y
`client_export.go` solo exporta clave **pública**, nunca privada. **Acción:** quitar la
línea `library.allow_export = true` de `k8s/softhsm-configmap.yaml` - es limpieza, no
corrección de una fuga real. **Ya aplicado.**

**S4b (encontrado al aplicar S4). `slot.list.oneshot = false` - tampoco es una clave real**
Mismo método de verificación: cero coincidencias en `libsofthsm2.so`. También no-op.
**Ya aplicado** - ambas líneas se quitaron del `ConfigMap` en la misma edición.

**S14. `storageClassName: standard` en `k8s/softhsm-pvc.yaml`**
**Cerrado, verificado.** DigitalOcean Kubernetes (DOKS) usa `do-block-storage` como nombre
de StorageClass - confirmado en la documentación oficial de DO (múltiples fuentes
independientes, incluyendo `docs.digitalocean.com`). No existe un StorageClass estándar
llamado `standard` en DOKS. **Acción:** cambiar `storageClassName: standard` →
`storageClassName: do-block-storage` (el propio comentario en el archivo ya lo sugería,
solo nunca se aplicó al valor real).

## Prioridad 1 - decisión de producto/config pendiente

| # | Hallazgo | Decisión necesaria |
|---|---|---|
| S3 | `auth.mode: "development"` en manifest etiquetado producción | Confirmar si el código realmente lee esta variable (la ruta "dev mode" en `hsm-service` estaba marcada como código muerto en el review original) y, si aplica, cambiar a modo real antes de cualquier tráfico externo real |

## Prioridad 2 - para delegar a Claude Code local

Leer `AGENTS.md` en la raíz de este repo primero.

| # | Hallazgo | Archivo(s) | Nota |
|---|---|---|---|
| S5 | Sin `livenessProbe`/`readinessProbe` pese a exponer `/health`, `/ready`, `/hsm-health` | `k8s/hsm-sidecar-deployment.yaml` | **✅ RESUELTO:** Agregadas probes HTTP a `/health` (liveness) y `/ready` (readiness) con timings apropiados para detectar y reiniciar pods trabados por RWMutex deadlock. Commit: 2d87db4 |
| S6 | RBAC demasiado amplio: `get/list/watch` sobre TODOS los secrets del namespace | `k8s/hsm-service-rbac.yaml` | **✅ RESUELTO:** Agregado `resourceNames: ["hsm-secrets", "mysql-secrets"]` y removido `list` verb (innecesario, solo `get`/`watch` para acceso directo via secretKeyRef). Strict least-privilege per AGENTS.md regla 7. |
| S7 | Imagen del sidecar en `:latest`, hsm-service pineado a `:1.0.9` | `k8s/hsm-sidecar-deployment.yaml` | Pinear a versión/digest específico |
| S8 | Sin `securityContext` a nivel contenedor | `k8s/hsm-sidecar-deployment.yaml` | `runAsNonRoot: true`, `allowPrivilegeEscalation: false`, capabilities drop |
| S9 | 3 scripts casi idénticos de init (`k8s/init-token-if-empty.sh`, `scripts/init-hsm.sh`, `scripts/init-token.sh`), uno con ~30 líneas comentadas | `scripts/`, `k8s/` | Consolidar a uno; `k8s/init-token-if-empty.sh` es el que realmente se usa (initContainer real) |
| S10 | `softhsm2.conf` (raíz) vs `k8s/softhsm-configmap.yaml` divergen | ambos | El ConfigMap es el que se despliega de verdad - el de la raíz es referencia obsoleta, considerar borrarlo o sincronizarlo |
| S11 | `docs/troubleshooting.md` referencia `Dockerfile.softhsm`, el archivo real es `Dockerfile.standalone.softhsm` | `docs/troubleshooting.md` | Corregir el nombre en el comando documentado |
| S12 | README/Makefile referencian `k8s/mysql-secrets.yaml` (correctamente gitignored) sin ningún `.example.yaml` de referencia | `k8s/` | Agregar `k8s/mysql-secrets.example.yaml` con placeholders, para que alguien clonando desde cero sepa qué forma debe tener |
| S13 | `docs/pvc-cleanup.md` explica borrar el PVC sin advertencia de que eso destruye todo el material HSM irreversible, sin mencionar backup | `docs/pvc-cleanup.md` | Agregar advertencia explícita + paso de backup antes del borrado |
| S12b | `docs/Troubleshot.md` es un stub de 2 líneas, duplicado confuso de `docs/troubleshooting.md` | `docs/Troubleshot.md` | Borrar |

## Nota para evitar reinvestigación
- S4 y S14 están cerrados con evidencia verificada (binario real de SoftHSM2, documentación
  oficial de DO) - no hace falta volver a cuestionarlos.
- S1/S2 no son una emergencia activa dado que la exposición fue intencional para esta
  revisión - pero rotar antes de volver a privado sigue siendo la acción correcta.