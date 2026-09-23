# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

**SoftHSM sidecar service** — a Kubernetes microservice that runs a SoftHSM2 (PKCS#11 token store)
as a sidecar container. Provides HSM-based key generation and signing for `hsm-service`.
Deployed on DigitalOcean Kubernetes (DOKS); includes k8s manifests, initialization scripts,
and Docker images.

## Architecture (30-second version)

```
Pod: hsm-service
├── Container: hsm-service (main app, in separate repo)
│   └── Makes PKCS#11 calls to softhsm2
│
├── Container: softhsm-sidecar (this repo)
│   └── Runs libsofthsm2.so with /dev/null socket backend
│
└── Init container: init-token-if-empty (k8s/init-token-if-empty.sh)
    └── Creates HSM token on PVC first boot only

Storage:
├── PVC: softhsm-pvc (do-block-storage, not standard)
│   └── Contains libsofthsm2 token directory + SQLite DB
│
└── Secrets (k8s/):
    ├── hsm-secrets (HSM pin, SO pin, master key)
    └── mysql-secrets (DB credentials for migrations)
```

## Critical non-negotiable rules

**Read `AGENTS.md` fully before any change.** Highlights:

1. **No real credentials ever committed** — even if `.gitignore`'d, check `git ls-files`
   and `git rm --cached` any that slipped through.
2. **SoftHSM2 2.6.1 config keys only** — unrecognized keys silently fail. Verify
   against `strings libsofthsm2.so`, not docs.
3. **Private key non-extractability is code, not config** — enforced in `hsm-service`
   (`CKA_EXTRACTABLE=false`, `CKA_SENSITIVE=true`), not in `softhsm2.conf`.
4. **DOKS uses `do-block-storage` StorageClass**, not `standard`.
5. **Sidecar Dockerfile `ENTRYPOINT` is intentionally `tail -f /dev/null`** — init
   logic belongs in the initContainer, not the app.
6. **Deployment pod changes may need probe updates** — check if `/health`, `/ready`,
   `/hsm-health` endpoints need new `livenessProbe`/`readinessProbe`.
7. **RBAC must use `resourceNames: [...]`** scoping to specific secrets, not broad wildcard.
8. **`docs/pvc-cleanup.md` is irreversible** — warn and back up before automating.

## Common commands

From `Makefile` (run in repo root):

**Minikube / local dev:**
- `make create` — Create minikube cluster (4GB mem, 2 CPUs, 20GB disk)
- `make apply` — Deploy all k8s manifests
- `make rollout` — Restart hsm-service deployment
- `make portforward` — Forward localhost:8080 to pod
- `make show-slots` — List SoftHSM slots in running sidecar
- `make hsm-list` — List all PKCS#11 objects
- `make bash` — Shell into softhsm-sidecar container
- `make watch-pods` — Watch deployment pod status

**Logs & inspection:**
- `make logs` — Tail hsm-service logs (100 lines)
- `make logs-sidecar` — Tail softhsm-sidecar logs
- `make show-token-info` — Show objects in a slot

**Build & registry:**
- `make build-ghcr` — Build Docker image locally
- `make push-ghcr` — Push to GHCR (`ghcr.io/digsigna/softhsm/softhsm:latest`)

## Key files & their roles

- `k8s/hsm-sidecar-deployment.yaml` — Pod spec, image, init container, volumes, RBAC ref
- `k8s/init-token-if-empty.sh` — ONE-TIME token initialization (wrapped in initContainer)
- `k8s/softhsm-configmap.yaml` — SoftHSM2 runtime config
- `k8s/hsm-secrets.yaml` — HSM PIN, SO-PIN, AES master key (git-ignored, example: `mysql-secrets.example.yaml`)
- `k8s/hsm-service-rbac.yaml` — ServiceAccount, Role, RoleBinding (scoped to specific secrets)
- `Dockerfile` — SoftHSM2 container image
- `scripts/{init-hsm,init-token}.sh` — **Obsolete duplicates** (consolidation pending, see PLAN)

## Working plan

Before re-investigating a half-done task, check `docs/PLAN-S1-S14.md`:
- **Closed (no action needed):** S1, S2 (creds), S4, S4b (fake config keys), S14 (storage class)
- **Priority 1 (decision pending):** S3 (dev vs. production mode)
- **Priority 2 (for Claude Code):** S5–S13 (probes, RBAC scoping, image pinning, security context, script consolidation, config sync, docs)

Check the PLAN before doing work that touches Deployment, RBAC, init scripts, or docs.

## Cross-repo context

- `hsm-service` (separate repo) — makes PKCS#11 calls; owns key generation + export protection
- `platform-docs/` — Ask before assuming cross-repo standards if not checked out

## Secrets management

- `k8s/mysql-secrets.yaml` — Git-ignored; use `mysql-secrets.example.yaml` as template
- `k8s/hsm-secrets.yaml` — Git-ignored; generated/rotated by ops, never committed
- `.env` — Git-ignored; local dev only