# AGENTS.md — softhsm (sidecar)

Rules for any agent working in this repository. Project-local source of truth; when this
conflicts with `platform-docs/standards/` or `platform-docs/security/known-deviations.md`,
the cross-repo standard wins and this file should be updated to match.

## Non-negotiable rules

1. **No real credentials in any committed file.** This repo has had a real AES master key,
   a real HSM PIN, and a real DigitalOcean database connection string committed before
   (`k8s/hsm-secrets.yaml`, `k8s/migrations-job.yaml`). Being listed in `.gitignore` is not
   enough if the file was already tracked before the rule was added — check
   `git ls-files` for anything that should be ignored but isn't, and use
   `git rm --cached` when you find it, not just adding the `.gitignore` entry.
2. **Don't add SoftHSM2 config keys without verifying they're real.** SoftHSM2 2.6.1 only
   recognizes: `directories.tokendir`, `objectstore.backend`, `log.level`,
   `slots.removable`, `slots.mechanisms`, `library.reset_on_fork`. An unrecognized key
   (like the former `library.allow_export`) is silently ignored — it creates false
   confidence about a setting that does nothing. If unsure whether a key is real, check
   against `strings` output of the actual `libsofthsm2.so` in use, not documentation that
   might be for a different version or a different PKCS#11 implementation.
3. **Private key non-extractability is enforced in `hsm-service`'s Go code
   (`CKA_EXTRACTABLE=false`, `CKA_SENSITIVE=true` at key generation), not in
   `softhsm2.conf`.** If someone reports a key-export concern, look there first, not at the
   SoftHSM config.
4. **This is DigitalOcean Kubernetes (DOKS).** Its StorageClass is `do-block-storage` — not
   `standard`, not any AWS/GCP-style name. Verify against DO's own docs if adding new PVCs.
5. **The sidecar's `Dockerfile` `ENTRYPOINT` is intentionally a no-op** (`tail -f /dev/null`)
   — don't "fix" it to run initialization directly. Initialization belongs in the
   initContainer (`k8s/init-token-if-empty.sh`), which is the one actually wired into
   `k8s/hsm-sidecar-deployment.yaml`. `scripts/init-hsm.sh` and `scripts/init-token.sh` are
   earlier/duplicate versions — consolidate toward the k8s one, don't add a fourth.
6. **Anything that touches `k8s/hsm-sidecar-deployment.yaml`**: check whether the change
   needs a `livenessProbe`/`readinessProbe` update too. The app already exposes `/health`,
   `/ready`, `/hsm-health` — there is currently no probe wiring at all, which means a
   wedged pod (e.g. from the known RWMutex deadlock in `hsm-service`) won't be
   auto-restarted by Kubernetes.
7. **RBAC**: the `hsm-service-secrets-reader` Role should be scoped to the specific secrets
   it needs (`resourceNames: [...]`), not broad `get/list/watch` on all secrets in the
   namespace. If you're adding a new secret this service needs, add it to
   `resourceNames`, don't remove the restriction.
8. **`docs/pvc-cleanup.md` deletes the HSM token store irreversibly.** Any edit to that doc,
   or any script that automates what it describes, needs an explicit warning and a backup
   step — this is not equivalent to resetting the (disposable, frequently recreated) test
   database.

## Cross-repo context worth knowing
- `k8s/migrations-job.yaml` here is what actually runs the `migrations` repo's SQL against
  the real cluster.
- `hsm-service`'s `client_keygen.go` and `client_export.go` are the actual enforcement point
  for key extractability — this repo's k8s manifests can't fix a code-level gap there, and
  code-level fixes there don't need a matching change here.