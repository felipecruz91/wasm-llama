# wasm-llama

:warning: WIP - Not working yet.

## Build
```
docker buildx build --platform wasi/wasm32 -t llama-interactive --provenance=false .
```

## Run
```
docker run --rm --runtime io.containerd.wasmedge.v1 --platform wasi/wasm32 llama-interactive default
```
