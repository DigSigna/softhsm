HSM_SLOT ?= 1872106899
HSM_PIN  ?= 1234
HSM_MODULE := /usr/lib/x86_64-linux-gnu/softhsm/libsofthsm2.so
HSM_DEPLOY := hsm-service
HSM_CONTAINER := softhsm-sidecar

create:
	@echo "Creating minikube cluster..."
	minikube start --memory=4g --cpus=2 --disk-size=20g --driver=docker --addons=ingress,metrics-server
# 	minikube start --memory=4g --cpus=2  --disk-size=20g --driver=docker --kubernetes-version=v1.28.0 --addons=ingress,metrics-server

#build to GHCR
build-ghcr:
	@echo "Building to GHCR..."
	docker build -t ghcr.io/digsigna/softhsm/softhsm:latest -f Dockerfile .
	@echo "Built to GHCR..."
#push to GHCR
push-ghcr:
	@echo 'Pushing to GHCR...'
	docker push ghcr.io/digsigna/softhsm/softhsm:latest
	@echo 'Pushed to GHCR...'

#roll out deployment
rollout:
	@echo 'Rolling out deployment...'
	kubectl rollout restart deployment/hsm-service
	@echo 'Rolled out deployment...'

#deployment bash
bash:
	@echo 'Accessing softhsm-sidecar bash...'
	kubectl exec -it deployment/hsm-service -c softhsm-sidecar -- bash

#show slots softhsm
show-slots:
	@echo 'Showing slots...'
	kubectl exec -it deployment/hsm-service -c softhsm-sidecar -- softhsm2-util --show-slots

show-token-info:
	@POD=$$(kubectl get pods -o jsonpath='{.items[0].metadata.name}'); \
	echo "Showing token info in pod $$POD, slot $(slot)" && \
	kubectl exec -it $$POD -- softhsm2-util --show-objects --slot $(slot)

#portfoerwarding service
portforward:
	@echo 'portfoerwarding service 8080... '
	kubectl port-forward deployment/hsm-service 8080:8080

#list tokens in slot
hsm-list:
	kubectl exec deployment/$(HSM_DEPLOY) -c $(HSM_CONTAINER) -- \
		pkcs11-tool --module $(HSM_MODULE) \
		--login --pin $(HSM_PIN) \
		--list-objects --slot $(HSM_SLOT)

#waching deploy pods
watch-pods:
	@echo 'Watching deployment pods...'
	kubectl get pods -l app=hsm-service -w
	