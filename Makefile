init:
	mkdir -p ./.keys
	mkdir -p ./ips
	mkdir -p ./ips/format
	mkdir -p ./ips/resolution
	mkdir -p ./ips/size
	ssh-keygen -t rsa -b 4096 -f ./.keys/manager_rsa -N ""
.PHONY: init

build:
	docker rmi -f julia_manager || true
	docker rmi -f julia_worker || true
	docker build -t julia_manager -f ./docker/Dockerfile-manager .
	docker build -t julia_worker -f ./docker/Dockerfile-worker .
.PHONY: build

_common_folders:
	mkdir -p graphite
	mkdir -p grafana_config
	mkdir -p shared
	mkdir -p shared/input
	rm -rf shared/formatted || true
	mkdir -p shared/formatted
	rm -rf shared/scaled || true
	mkdir -p shared/scaled
	rm -rf shared/output || true
	mkdir -p shared/output


deploy: remove _common_folders
	docker stack deploy -c docker/docker-compose.yaml ip_julia
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