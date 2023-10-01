# syntax=docker/dockerfile:1

FROM --platform=linux/amd64 rust:1.69 AS buildbase
WORKDIR /src
RUN <<EOT bash
    set -ex
    apt-get update
    apt-get install -y \
        git \
        clang
    rustup target add wasm32-wasi
EOT
# This line installs WasmEdge including the wasi_nn-ggml plugin
RUN curl -sSf https://raw.githubusercontent.com/WasmEdge/WasmEdge/master/utils/install.sh | bash -s -- --plugin wasi_nn-ggml 

FROM buildbase AS build
RUN --mount=type=bind,source=src,target=src \
    --mount=type=bind,source=Cargo.toml,target=Cargo.toml \
    --mount=type=cache,target=/app/target/ \
    --mount=type=cache,target=/usr/local/cargo/registry/ \
    <<EOF
set -ex
cargo build --target wasm32-wasi --release
EOF

FROM --platform=linux/amd64 alpine:3.17 AS model
WORKDIR /src
RUN <<EOF
apk add --no-cache curl
curl -LO https://huggingface.co/TheBloke/Llama-2-7b-Chat-GGUF/resolve/main/llama-2-7b-chat.Q5_K_M.gguf
EOF

FROM scratch
COPY --link --from=build /src/target/wasm32-wasi/release/wasmedge-ggml-llama-interactive.wasm /app.wasm
COPY --link --from=model /src/llama-2-7b-chat.Q5_K_M.gguf /llama-2-7b-chat.Q5_K_M.gguf
ENTRYPOINT [ "/app.wasm" ]
