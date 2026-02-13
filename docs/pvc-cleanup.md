# PVC cleanup

## 1. Verifica PVC y PV existentes

```bash
kubectl get pvc
kubectl get pv
```

## 2. Elimina el Deployment para liberar el PVC

```bash
kubectl delete deployment hsm-service --ignore-not-found=true

# Verifica que no queden pods
kubectl get pods -l app=hsm-service
```

## 3. Elimina el PVC

```bash
kubectl delete pvc softhsm-pvc
```

## 4. (Opcional) Borra PV en estado Released

```bash
kubectl get pv
kubectl delete pv pvc-xxxx
```

## 5. (Opcional) Limpia hostPath en Minikube

Minikube almacena volúmenes hostPath en:

```text
/var/lib/minikube/hostpath-provisioner/
```

Conéctate al nodo:

```bash
minikube ssh

sudo ls /var/lib/minikube/hostpath-provisioner

# Borrar directorios huérfanos
sudo rm -rf /var/lib/minikube/hostpath-provisioner/pvc-xxxx

exit
```

## 6. Recrea el PVC y Deployment

```bash
kubectl apply -f k8s/softhsm-pvc.yaml
kubectl apply -f k8s/hsm-sidecar-deployment.yaml

kubectl get pods -l app=hsm-service -w
```