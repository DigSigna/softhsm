```yaml
current_phase: "SoftHSMv2 Standalone"
purpose: "Testing/Development del HSM mismo"
communication: "Ninguna - solo volumen local"

migration_trigger: "Cuando hsm-service (Go) esté desarrollado"
migration_actions:
  - "Eliminar deployment softhsm-standalone"
  - "Crear nuevo deployment con sidecar pattern"
  - "Mover volumen a nuevo deployment"
  - "hsm-service se comunica via filesystem (libsofthsm2.so)"

final_architecture: "Sidecar (hsm-service + softhsm) - Comunicación intra-pod"