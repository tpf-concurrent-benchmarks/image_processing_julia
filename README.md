# Image Processing Pipeline - Julia

## Objective

This is a Julia implementation of an image processing pipeline under [common specifications](https://github.com/tpf-concurrent-benchmarks/docs/tree/main/image_processing) defined for multiple languages.

The objective of this project is to benchmark the language on a real-world distributed system.

## Deployment

### Requirements

- [Docker >3](https://www.docker.com/) (needs docker swarm)

### Configuration

- **Number of replicas:** `FORMAT_WORKER_REPLICAS`, `RESOLUTION_WORKER_REPLICAS` and `SIZE_WORKER_REPLICAS` constants are defined in the `Makefile` file.
- **Manager config:** in `src/resources/config.json` you can define (this config is built into the container):
  - workers config: image format, resolution and size
  - logger config (graphite address)
  - working directory (route where the images are stored)

### Commands

#### Startup

- `make init`: creates required directories and generates the required keys.
- `make build`: will build the docker images.
- `template_data`: downloads test image into the input folder

#### Run

- `make deploy` will deploy the system.
- Afterwards: `make manager_bash` will open a bash session on the manager
- Afterwards: The user can run the manager script: `julia manager.jl`
- `make remove` will remove the system containers.
