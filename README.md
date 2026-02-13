## Verificación y Configuración del Entorno
# Verificar que Minikube está listo
```powershell
minikube status
kubectl get nodes
kubectl get pods -A

# Configurar Docker build en Minikube

minikube -p minikube docker-env --shell powershell | Invoke-Expression

# Construir imagen segura (sin EXPOSE)
docker build -t softhsm:latest -f Dockerfile.softhsm .

# Desplegar standalone seguro
kubectl apply -f k8s/softhsm-standalone.yaml

# Verificar internamente
kubectl exec deployment/softhsm-standalone -- softhsm2-util --show-slots
```

## Verificación Final de Operaciones
```powershell
# 1. Probar generación de claves (operación criptográfica real)
kubectl exec deployment/softhsm-standalone -- pkcs11-tool --module /usr/lib/softhsm/libsofthsm2.so --login --pin 1234 --keypairgen --key-type rsa:2048 --label "test-signing-key"

#log
Using slot 0 with a present token (0x5bdaceb0)
Key pair generated:
Private Key Object; RSA
  label:      test-signing-key
  Usage:      decrypt, sign, unwrap
  Access:     sensitive, always sensitive, never extractable, local
Public Key Object; RSA 2048 bits
  label:      test-signing-key
  Usage:      encrypt, verify, wrap
  Access:     local

# 2. Listar objetos en el token
kubectl exec deployment/softhsm-standalone -- pkcs11-tool --module /usr/lib/softhsm/libsofthsm2.so --login --pin 1234 --list-objects

#log
Using slot 0 with a present token (0x5bdaceb0)
Private Key Object; RSA 
  label:      test-signing-key
  Usage:      decrypt, sign, unwrap
  Access:     sensitive, always sensitive, never extractable, local
Public Key Object; RSA 2048 bits
  label:      test-signing-key
  Usage:      encrypt, verify, wrap
  Access:     local

# 3. Verificar información detallada del token
# Usar el SLOT ID específico (0x5bdaceb0) en lugar del índice
kubectl exec deployment/softhsm-standalone -- pkcs11-tool --module /usr/lib/softhsm/libsofthsm2.so --slot 0x5bdaceb0 --login --pin 1234 --list-objects
#O usar el token label que es más legible
kubectl exec deployment/softhsm-standalone -- pkcs11-tool --module /usr/lib/softhsm/libsofthsm2.so --token-label "digsigna-token" --login --pin 1234 --list-objects

#Para listar tokens, NO usar --login (solo información)
kubectl exec deployment/softhsm-standalone -- pkcs11-tool --module /usr/lib/softhsm/libsofthsm2.so --list-token-slots


# Generar clave RSA de 2048 bits para prueba
kubectl exec deployment/softhsm-standalone -- pkcs11-tool --module /usr/lib/softhsm/libsofthsm2.so --token-label "digsigna-token" --login --pin 1234 --keypairgen --key-type rsa:2048 --label "test-key-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Listar objetos inmediatamente después
kubectl exec deployment/softhsm-standalone -- pkcs11-tool --module /usr/lib/softhsm/libsofthsm2.so --token-label "digsigna-token" --login --pin 1234 --list-objects
```

# Despliegue sidecar
```bash
# 1. Cambiar de entorno para generar imagen con docker dentro de minikube
& minikube -p minikube docker-env --shell powershell | Invoke-Expression
# 2. Generar imagen hsm-service
docker build -t hsm-service:latest -f .\Dockerfile .

# 3. Aplicar configuración
kubectl apply -f .\k8s\auth-public-key-configmap.yaml
kubectl apply -f softhsm-configmap.yaml
kubectl apply -f hsm-secrets.yaml
kubectl apply -f hsm-service-config.yaml
kubectl apply -f softhsm-pvc.yaml
kubectl apply -f mysql-secrets.yaml
kubectl apply -f migrations-job.yaml
kubectl apply -f hsm-sidecar-deployment.yaml

# 3.1 removing
kubectl delete -f xxxxxxxx.yaml
# 3.2 removing job
kubectl delete job migrations-job
kubectl logs job/migrations-job


# 4. Verificar
kubectl get pods -l app=hsm-service -w

##Recreación de deployment
kubectl delete deployment hsm-service --ignore-not-found=true
kubectl apply -f hsm-sidecar-deployment.yaml

# Aplicar deployment temporal
kubectl apply -f hsm-sidecar-temp.yaml

# Reiniciar el deployment
kubectl rollout restart deployment/hsm-service

#verificaciones
kubectl exec deployment/hsm-service -c hsm-service -- curl -s http://localhost:8080/health

# Probar conexión PKCS#11 desde hsm-sidecar al SoftHSM
kubectl exec deployment/hsm-service -c softhsm-sidecar -- pkcs11-tool --module /usr/lib/softhsm/libsofthsm2.so --login --pin 1234 --list-objects

#verificar librería
kubectl exec deployment/hsm-service -c hsm-service -- 
ls -la /usr/lib/softhsm/libsofthsm2.so 

#verificar puedan acceder al mismo token
# Desde hsm-service
kubectl exec deployment/hsm-service -c hsm-service -- ls -la /var/lib/softhsm/tokens/

# Desde softhsm-sidecar  
kubectl exec deployment/hsm-service -c softhsm-sidecar -- ls -la /var/lib/softhsm/tokens/

# Redeploy en Kubernetes
kubectl rollout restart deployment/hsm-service

# Verificar que el pod se reinició
kubectl get pods -l app=hsm-service

# Probar el endpoint nuevamente
kubectl exec deployment/hsm-service -c hsm-service -- \
  curl -s http://localhost:8080/hsm-health

#logs
kubectl logs deployment/hsm-service -c hsm-service 
kubectl describe pod -l app=hsm-service
```

## Administración de imagenes
```bash
#ssh minikube
minikube ssh

#list images
docker images

#delete image
docker rmi [id]


#hs-service operation (generate token key)
kubectl exec deployment/hsm-service -c hsm-service -- \
  curl -X POST http://localhost:8080/api/v1/keys \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dev-tenant-token123" \
  -d '{
    "name": "test-key-mvp",
    "key_size": 2048,
    "algorithm": "RSA",
    "usage": "SIGNING",
    "tenant_id": "123e4567-e89b-12d3-a456-426614174000"
  }'

  kubectl exec deployment/hsm-service -c hsm-service -- curl -X POST http://localhost:8080/api/v1/keys -H "Content-Type: application/json" -H "Authorization: Bearer dev-tenant-token123" -d '{"name": "test-key-mvp", "key_size": 2048, "algorithm": "RSA", "usage": "SIGNING", "tenant_id": "123e4567-e89b-12d3-a456-426614174000"}'

# Ver logs detallados del error
kubectl logs deployment/hsm-service -c hsm-service --tail=100 | grep -A 10 -B 10 "CreateKey"

# O en tiempo real
kubectl logs deployment/hsm-service -c hsm-service -f

# Listado de tokens y slots en sidecard
kubectl exec -it deployment/hsm-service -c softhsm-sidecar --   ls -la /var/lib/softhsm/tokens
kubectl exec -it deployment/hsm-service -c softhsm-sidecar -- softhsm2-util --show-slots

#accesoa  bash
kubectl exec -it deployment/hsm-service -c softhsm-sidecar -- bash


#show slot content
pkcs11-tool --modul /usr/local/lib/softhsm/libsofthsm2.so -l -O --slot XXXXX
⭐ 1 SoftHSM sidecar por aplicación (uno solo)
⭐ Un token por tenant
⭐ Dentro de cada token, una clave privada por usuario, si ellos firman.

# Verificar estado del pod
kubectl get pods -l app=hsm-service -w
