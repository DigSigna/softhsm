# softhsm

SoftHSM sidecar + Kubernetes deployment manifests for the DigSigna platform's `hsm-service`.
Runs SoftHSMv2 as a token store shared with `hsm-service` via PKCS#11, on DigitalOcean
Kubernetes (DOKS).

## How the pieces fit together
- `Dockerfile` builds the sidecar image. Its default `ENTRYPOINT` is intentionally a no-op
  (`tail -f /dev/null`) — the sidecar's job is to hold the mounted token volume alive and
  stay `exec`-able, not to run initialization itself.
- Initialization happens in a Kubernetes **initContainer** (see
  `k8s/hsm-sidecar-deployment.yaml`), which reuses the same image but overrides the command
  to run `k8s/init-token-if-empty.sh` — that's the single initialization script used for
  token creation in both cluster and development modes.
- `Dockerfile.standalone.softhsm` is a separate, self-contained image (runs
  `k8s/init-token-if-empty.sh` as its own `CMD`) for local development without Kubernetes — not
  what runs in the cluster.
- `k8s/migrations-job.yaml` is what actually applies the `migrations` repo's SQL against
  the real database — not anything in that repo's own `Makefile`/`cmd/`. If you're changing
  how migrations run, this is the file to check.
- The SoftHSM token store PVC (`k8s/softhsm-pvc.yaml`) uses `ReadWriteOnce` — single
  replica by design. This is a known scaling ceiling, not a bug; horizontal signing
  throughput requires moving to a remote/dedicated HSM (already planned, see
  `hsm/sprint-1.0/controlled-migration-plan-phase-2.md` in `platform-docs`).

## Local development
```bash
make build     # builds the sidecar image
make apply     # applies k8s manifests in order (requires k8s/mysql-secrets.yaml — see below)
make show-slots  # exec into the sidecar, list HSM slots
```
You need to create `k8s/mysql-secrets.yaml` yourself — it's intentionally not committed
(correctly listed in `.gitignore`). See `k8s/mysql-secrets.example.yaml` for the expected
shape.

## Known issues
Tracked in `PLAN-S1-S14.md` in this repo (working plan) and, once resolved, in
`security/known-deviations.md` in `platform-docs` (cross-repo source of truth). Two things
worth knowing up front if you're new to this repo:
- `library.allow_export` in `k8s/softhsm-configmap.yaml` is not a real SoftHSM2 config key
  — it does nothing. The real protection against private key extraction is
  `CKA_EXTRACTABLE=false` set at key generation time in `hsm-service`'s
  `client_keygen.go`, already correctly implemented.
- `docs/pvc-cleanup.md` walks through deleting the PVC — that destroys all HSM key material
  irreversibly. Don't run it without a backup, regardless of how routine it looks.