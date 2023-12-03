# Image Processing Pipeline - Julia

This is a Julia implementation of an image processing pipeline under [common specifications](https://github.com/tpf-concurrent-benchmarks/docs/tree/main/image_processing) defined for multiple languages.

The objective of this project is to benchmark the language on a real-world distributed system.

## Deployment

The project is deployed using docker swarm, `make init` initializes it, creates required directories and generates the required keys.

`make build` will build the docker images.

`make deploy` will deploy the system.

`make manager_bash` will open a bash session on the manager, where the user can run the manager script: `julia manager.jl`

## Implementation details

- The system uses Julia's built-in distributed computing capabilities to distribute the tasks to the workers.
- The systems uses RemoteChannels as work-queues between stages.
