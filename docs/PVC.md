## Verifica qué PVC y PV existen
```bash
kubectl get pvc
kubectl get pv
```

## Elimina el Deployment para soltar el PVC

Esto es necesario porque mientras el Pod esté corriendo, el PVC no se puede borrar.

```bash
kubectl delete deployment hsm-service --ignore-not-found=true

# Verifica que NO haya pods corriendo
kubectl get pods -l app=hsm-service

``` 
## Elimina el PVC
```bash
kubectl delete pvc softhsm-pvc
```

## (Opcional pero recomendado) 4. Borra el PV que quedó "Released"
```bash
kubectl get pv

#borrar manualmente

kubectl delete pv pvc-xxxx
```

## (Opcional) Limpia el directorio físico del volumen de minikube
Minikube almacena volúmenes hostPath en:
```text
/var/lib/minikube/hostpath-provisioner/
```

### Conéctate al nodo:
```bash
minikube ssh

sudo ls /var/lib/minikube/hostpath-provisioner

#si hay carpetas huérfanas tipo:
#pvc-xxxx
#pvc-yyyy

#borrar
sudo rm -rf /var/lib/minikube/hostpath-provisioner/pvc-xxxx

exit
```

## Recrea el PVC

Aplica tu archivo:

```bash
kubectl apply -f k8s/softhsm-pvc.yaml

#verifica
kubectl get pvc
```

## Reconstruye el Deployment

```bash
kubectl apply -f k8s/hsm-sidecar-deployment.yaml

#verificar
kubectl get pods -l app=hsm-service -w
```