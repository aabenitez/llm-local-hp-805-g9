#!/usr/bin/env bash
# Levanta llama-server en modo router: todos los modelos de la caché quedan
# disponibles en el selector del chat y se cargan de a uno.
# Los ajustes de cada modelo están en modelos.ini, que se busca en la misma
# carpeta donde está este script.
# Uso: ./modelos.sh        (también funciona con: sh modelos.sh)

set -eu

# Carpeta donde está este script (funciona aunque tenga espacios en el nombre
# y aunque se lo ejecute desde otra carpeta)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

LLAMA_DIR="${LLAMA_DIR:-$HOME/llama.cpp}"
PRESET="${PRESET:-$SCRIPT_DIR/modelos.ini}"
PORT="${PORT:-8080}"

SERVER="$LLAMA_DIR/build/bin/llama-server"

if [ ! -x "$SERVER" ]; then
  echo "Error: no encuentro llama-server en $SERVER"
  echo "       Si llama.cpp está en otra carpeta, indicala así:"
  echo "       LLAMA_DIR=/ruta/a/llama.cpp ./modelos.sh"
  exit 1
fi

if [ ! -f "$PRESET" ]; then
  echo "Error: no encuentro el archivo de presets en $PRESET"
  exit 1
fi

# Si ya hay un llama-server escuchando en el puerto, lo detiene
if pgrep -f "llama-server.*--port $PORT" >/dev/null; then
  echo ">> Deteniendo llama-server existente en el puerto $PORT..."
  pkill -f "llama-server.*--port $PORT"
  sleep 2
fi

echo ">> Modo router | presets: $PRESET | http://127.0.0.1:$PORT"

# Importante: device, contexto, etc. NO van acá. Lo que se pasa por línea de
# comandos pisa a los presets, así que todo eso vive en modelos.ini.
exec "$SERVER" \
  --models-preset "$PRESET" \
  --models-max 1 \
  --host 127.0.0.1 --port "$PORT"
