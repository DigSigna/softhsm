# GHCR

## Login

```bash
# Ensure the command prints the token correctly
# Replace USERNAME with your GitHub username
# GHCR_TOKEN can be a PAT with read:packages/write:packages

echo $GHCR_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
```

## Build and push

```bash
docker build -t ghcr.io/<usuario>/<repo>/<nombre-de-imagen> .

docker push ghcr.io/<usuario>/<repo>/<nombre-de-imagen>
```

## Create pull secret

Crear kubectl secret para hacer pull de imágenes privadas:

```bash
kubectl create secret docker-registry ghcr-creds \
	--docker-server=ghcr.io \
	--docker-username=tuUsuario \
	--docker-password=$GITHUB_TOKEN
```

```powershell
kubectl create secret docker-registry ghcr-creds \
	--docker-server=ghcr.io \
	--docker-username=tuUsuario \
	--docker-password=$GITHUB_TOKEN
```

## YAML examples

### Imagen local (Minikube)

```yaml
containers:
	- name: hsm-service
		image: hsm-service:latest
		imagePullPolicy: Never
```

### Imagen remota (GHCR)

```yaml
containers:
	- name: hsm-service
		image: ghcr.io/tuusuario/hsm-service:latest
		imagePullPolicy: Always
```

## YAML deploy con imágenes privadas

```yaml
template:
	metadata:
		labels:
			app: hsm-service
	spec:
		imagePullSecrets:
			- name: ghcr-creds
```