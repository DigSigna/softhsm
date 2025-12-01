# 1. Reconstruir imagen con la solución definitiva

```powershell
minikube -p minikube docker-env --shell powershell | Invoke-Expression
docker build -t softhsm:latest -f Dockerfile.softhsm .
```

# 2. Limpiar completamente
```powershell
kubectl delete -f k8s/softhsm-standalone.yaml --ignore-not-found=true
kubectl delete pod -l app=softhsm --force --grace-period=0 2>$null

# 2. Reiniciar el deployment anterior para liberar recursos
kubectl rollout restart deployment/softhsm-standalone
```

# 3. Desplegar versión corregida
```powershell
kubectl apply -f k8s/softhsm-standalone.yaml
```

# 4. Verificar
```powershell
kubectl get pods -l app=softhsm -w

# Una vez que el pod esté Running
kubectl logs -l app=softhsm

# Probar funcionalidad HSM
kubectl exec deployment/softhsm-standalone -- softhsm2-util --show-slots

# Verificar tokens
kubectl exec deployment/softhsm-standalone -- ls -la /var/lib/softhsm/tokens/
```