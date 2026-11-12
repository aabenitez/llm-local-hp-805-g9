#!/usr/bin/env bash
# Levanta gpt-oss-20b (documentos / RAG) en llama-server, usando la iGPU Radeon 780M por Vulkan.
# Uso: ./gptoss.sh [low|medium|high] [contexto]
#   ./gptoss.sh               -> razonamiento medium, contexto 16384
#   ./gptoss.sh low           -> razonamiento low (respuestas más rápidas)
#   ./gptoss.sh high 32768    -> razonamiento high, contexto 32768

set -euo pipefail

LLAMA_DIR="${LLAMA_DIR:-$HOME/llama.cpp}"
DEVICE="${DEVICE:-Vulkan1}"   # Radeon 780M (Vulkan0 es la T400)
PORT="${PORT:-8080}"
EFFORT="${1:-medium}"
CTX="${2:-16384}"

case "$EFFORT" in
  low|medium|high) ;;
  *) echo "Error: el razonamiento debe ser low, medium o high (recibido: '$EFFORT')"; exit 1 ;;
esac

# Si ya hay un llama-server escuchando en el puerto, lo detiene
if pgrep -f "llama-server.*--port $PORT" >/dev/null; then
  echo ">> Deteniendo llama-server existente en el puerto $PORT..."
  pkill -f "llama-server.*--port $PORT"
  sleep 2
fi

echo ">> Iniciando gpt-oss-20b (MXFP4) | razonamiento: $EFFORT | contexto: $CTX | http://127.0.0.1:$PORT"

exec "$LLAMA_DIR/build/bin/llama-server" \
  -hf ggml-org/gpt-oss-20b-GGUF \
  --device "$DEVICE" -ngl 99 -fa on \
  -c "$CTX" -np 1 --jinja \
  --chat-template-kwargs "{\"reasoning_effort\":\"$EFFORT\"}" \
  --host 127.0.0.1 --port "$PORT"
