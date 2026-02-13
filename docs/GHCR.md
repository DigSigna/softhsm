# GHCR

## Login
```bash
#ensure command print tocker correctly
echo $GHCR_TOKEN | docker login ghcr.io -u USERNAME --pasword-stdin
```

## build and push
```bash
docker build -t ghcr.io/<usuario>/<repo>/<nombre-de-imagen> .

docker push ghcr.io/<usuario>/<repo>/<nombre-de-imagen>
```

## Secret
Crear kubectl secret para hacer pull de imagenes privadas
```bash
kubectl create secret docker-registry ghcr-creds \
  --docker-server=ghcr.io \
  --docker-username=tuUsuario \
  --docker-password=$GITHUB_TOKEN
```

```powershell
kubectl create secret docker-registry ghcr-creds --docker-server=ghcr.io --docker-username=tuUsuario --docker-password=$GITHUB_TOKEN
```

## YAML Config
Configuración para imagenes locales (Dentro de Minikube)
```yaml
    containers:
    -  name: hsm-service
       image: hsm-service:latest
       imagePullPolicy: Never
```

Configuración para imagenes remotas (GHCR)
```yaml
    containers:
    - name: hsm-service
      image: ghcr.io/tuusuario/hsm-service:latest
      imagePullPolicy: Always
```

## YALM Deploy con imagenes privadas
```yaml
template:
    metadata:
      labels:
        app: hsm-service
    spec:
      imagePullSecrets:
      - name: ghcr-creds
```