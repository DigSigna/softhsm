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