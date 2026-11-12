#!/usr/bin/env bash
# Levanta Qwen3-Coder-30B-A3B (código) en llama-server, usando la iGPU Radeon 780M por Vulkan.
# Uso: ./qwen.sh [contexto]
#   ./qwen.sh          -> contexto 16384
#   ./qwen.sh 8192     -> contexto 8192 (más rápido)

set -euo pipefail

LLAMA_DIR="${LLAMA_DIR:-$HOME/llama.cpp}"
DEVICE="${DEVICE:-Vulkan1}"   # Radeon 780M (Vulkan0 es la T400)
PORT="${PORT:-8080}"
CTX="${1:-16384}"

# Si ya hay un llama-server escuchando en el puerto, lo detiene
if pgrep -f "llama-server.*--port $PORT" >/dev/null; then
  echo ">> Deteniendo llama-server existente en el puerto $PORT..."
  pkill -f "llama-server.*--port $PORT"
  sleep 2
fi

echo ">> Iniciando Qwen3-Coder-30B-A3B (Q4_K_M) | contexto: $CTX | http://127.0.0.1:$PORT"

exec "$LLAMA_DIR/build/bin/llama-server" \
  -hf unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:Q4_K_M \
  --device "$DEVICE" -ngl 99 -fa on \
  -c "$CTX" -np 1 --jinja \
  --host 127.0.0.1 --port "$PORT"
