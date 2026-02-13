## SoftHSM service (sidecar)

Microservicio para administrar claves HSM usando SoftHSM como sidecar en Kubernetes.

## Requisitos

- Minikube + kubectl
- Docker
- Make (opcional)

## Quickstart (Minikube)

```powershell
minikube status
kubectl get nodes
```

### Deploy sidecar

```powershell
minikube -p minikube docker-env --shell powershell | Invoke-Expression

kubectl apply -f .\k8s\auth-public-key-configmap.yaml
kubectl apply -f .\k8s\softhsm-configmap.yaml
kubectl apply -f .\k8s\hsm-secrets.yaml
kubectl apply -f .\k8s\hsm-service-config.yaml
kubectl apply -f .\k8s\softhsm-pvc.yaml
kubectl apply -f .\k8s\mysql-secrets.yaml
kubectl apply -f .\k8s\migrations-job.yaml
kubectl apply -f .\k8s\hsm-service-rbac.yaml
kubectl apply -f .\k8s\hsm-sidecar-deployment.yaml
```

### Verificar

```powershell
kubectl get pods -l app=hsm-service -w
kubectl exec deployment/hsm-service -c hsm-service -- curl -s http://localhost:8080/health
kubectl exec deployment/hsm-service -c softhsm-sidecar -- softhsm2-util --show-slots
```

## Comandos útiles (Makefile)

- `make create`: crear cluster minikube
- `make rollout`: reiniciar deployment
- `make portforward`: port-forward a 8080
- `make show-slots`: mostrar slots SoftHSM
- `make hsm-list`: listar objetos PKCS#11
- `make watch-pods`: monitorear pods

## Docs

- `docs/GHCR.md`: autenticación y pull de imágenes GHCR
- `docs/pvc-cleanup.md`: limpieza de PVC/PV
- `docs/troubleshooting.md`: pasos de troubleshooting
#O usar el token label que es más legible
