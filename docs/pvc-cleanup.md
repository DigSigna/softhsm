# PVC cleanup

⚠️ **WARNING: This operation is IRREVERSIBLE** ⚠️

Deleting the PVC will **permanently destroy** all HSM tokens, keys, and the entire SoftHSM token store. This data cannot be recovered.

- This is NOT equivalent to database cleanup (which can be re-initialized).
- Ensure you have backed up any critical keys or have rotated them to a different HSM before proceeding.
- Do not proceed unless you explicitly understand the consequences.

## 0. (REQUIRED) Back up the token store before deletion

Before deleting anything, back up the persistent volume if you need to preserve the HSM token data:

```bash
# Get the PVC details
kubectl get pvc softhsm-pvc -o yaml > softhsm-pvc-backup.yaml

# If using DigitalOcean block storage, take a snapshot via the DO console or CLI
# doctl compute volume-snapshot create <volume-id> --snapshot-name softhsm-backup-$(date +%Y%m%d)

# Alternatively, pod-exec into the sidecar and tar the token directory
kubectl exec -it deployment/hsm-service -c softhsm-sidecar -- tar czf /tmp/tokens-backup.tar.gz -C /var/lib/softhsm tokens/

# Copy the backup out
kubectl cp hsm-service:/tmp/tokens-backup.tar.gz ./softhsm-tokens-backup-$(date +%Y%m%d).tar.gz -c softhsm-sidecar
```

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