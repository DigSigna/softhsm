# Troubleshooting

## Reconstruir imagen y redeploy (standalone)

```powershell
minikube -p minikube docker-env --shell powershell | Invoke-Expression
docker build -t softhsm:latest -f Dockerfile.softhsm .
```

## Limpieza completa

```powershell
kubectl delete -f k8s/softhsm-standalone.yaml --ignore-not-found=true
kubectl delete pod -l app=softhsm --force --grace-period=0 2>$null

# Reiniciar deployment anterior
kubectl rollout restart deployment/softhsm-standalone
```

## Desplegar versión corregida

```powershell
kubectl apply -f k8s/softhsm-standalone.yaml
```

## Verificar

```powershell
kubectl get pods -l app=softhsm -w

# Una vez que el pod esté Running
kubectl logs -l app=softhsm

# Probar funcionalidad HSM
kubectl exec deployment/softhsm-standalone -- softhsm2-util --show-slots

# Verificar tokens
kubectl exec deployment/softhsm-standalone -- ls -la /var/lib/softhsm/tokens/
```