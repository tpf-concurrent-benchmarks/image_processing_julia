FORMAT_WORKER_REPLICAS=1
RESOLUTION_WORKER_REPLICAS=1
SIZE_WORKER_REPLICAS=1

init:
	mkdir -p ./.keys
	mkdir -p ./ips
	mkdir -p ./ips/format
	mkdir -p ./ips/resolution
	mkdir -p ./ips/size
	ssh-keygen -t rsa -b 4096 -f ./.keys/manager_rsa -N ""
.PHONY: init

build:
	docker rmi -f image_processing_julia_manager || true
	docker rmi -f image_processing_julia_worker || true
	docker build -t image_processing_julia_manager -f ./docker/Dockerfile-manager .
	docker build -t image_processing_julia_worker -f ./docker/Dockerfile-worker .
.PHONY: build

_common_folders:
	mkdir -p graphite
	mkdir -p configs/grafana_config
	mkdir -p shared
	mkdir -p shared/input
	mkdir -p shared/formatted
	mkdir -p shared/scaled
	mkdir -p shared/output

	mv shared/formatted shared/formatted.old || true
	rm -rf shared/formatted &
	mkdir -p shared/scaled

	mv shared/scaled shared/scaled.old || true
	rm -rf shared/scaled &
	mkdir -p shared/scaled

	mv shared/output shared/output.old || true
	rm -rf shared/output &
	mkdir -p shared/output


deploy: _common_folders
	until \
	FORMAT_WORKER_REPLICAS=$(FORMAT_WORKER_REPLICAS) \
	RESOLUTION_WORKER_REPLICAS=$(RESOLUTION_WORKER_REPLICAS) \
	SIZE_WORKER_REPLICAS=$(SIZE_WORKER_REPLICAS) \
	docker stack deploy \
	-c docker/docker-compose-common.yaml \
	-c docker/docker-compose-server.yaml \
	ip_julia; \
	do sleep 1; done
.PHONY: deploy

remove:
	rm -rf ./ips/*/*
	if docker stack ls | grep -q ip_julia; then \
            docker stack rm ip_julia; \
	fi
.PHONY: remove

manager_bash:
	docker exec -it $(shell docker ps -q -f name=ip_julia_manager) bash
.PHONY: manager_bash

worker_bash:
	docker exec -it $(shell docker ps -q -f name=ip_julia_worker) bash
.PHONY: worker_bash

# Cloud specific

_mount_nfs:
	mkdir -p shared
	sudo mount -o rw,intr $(NFS_SERVER_IP):/$(NFS_SERVER_PATH) ./shared
.PHONY: _mount_nfs

# Requires the following env variables:
# - NFS_SERVER_IP
# - NFS_SERVER_PATH
deploy_cloud: remove
	NFS_SERVER_IP=$(NFS_SERVER_IP) NFS_SERVER_PATH=$(NFS_SERVER_PATH) make _mount_nfs
	sudo make _common_folders
	mkdir -p graphite
	mkdir -p grafana_config
	until \
	FORMAT_WORKER_REPLICAS=$(FORMAT_WORKER_REPLICAS) \
	RESOLUTION_WORKER_REPLICAS=$(RESOLUTION_WORKER_REPLICAS) \
	SIZE_WORKER_REPLICAS=$(SIZE_WORKER_REPLICAS) \
	NFS_SERVER_IP=$(NFS_SERVER_IP) \
	NFS_SERVER_PATH=$(NFS_SERVER_PATH) \
	sudo -E docker stack deploy \
	-c docker/docker-compose-cloud.yaml ip_julia; do sleep 1; done
.PHONY: deploy_cloud