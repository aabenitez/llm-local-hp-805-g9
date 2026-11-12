#!/usr/bin/env bash
# Descarga a la caché todos los modelos de la lista, uno tras otro, mostrando
# la barra de progreso. Los que ya están descargados se saltean.
# Usa llama.cpp para bajar, así quedan en la misma caché y con los mismos
# nombres que usa el servidor (modelos.sh / modelos.ini).
#
# Uso: ./descargar-modelos.sh
#      ./descargar-modelos.sh usuario/repo:CUANT [otro/repo:CUANT ...]   # solo esos

set -uo pipefail

LLAMA_DIR="${LLAMA_DIR:-$HOME/llama.cpp}"
CACHE="${HF_HUB_CACHE:-${HF_HOME:-$HOME/.cache/huggingface}/hub}"

# --- Lista de modelos: agregá o comentá líneas a gusto --------------------
MODELOS=(
  "LiquidAI/LFM2.5-8B-A1B-GGUF:Q4_K_M"
  "ggml-org/gpt-oss-20b-GGUF:MXFP4"
  "unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:Q4_K_M"
  "mradermacher/Qwen3.6-35B-A3B-GGUF:IQ4_XS"
  "unsloth/GLM-4.7-Flash-GGUF:Q4_K_XL"
  "unsloth/gemma-4-26B-A4B-it-GGUF:Q4_K_M"
  "bartowski/Qwen2.5-Coder-7B-Instruct-GGUF:Q4_K_M"
  "bartowski/nvidia_NVIDIA-Nemotron-Nano-9B-v2-GGUF:Q4_K_M"
  "mradermacher/Nemotron-9B-OpenCode-GGUF:Q4_K_M"
  # "unsloth/gemma-4-e4b-it-GGUF:Q4_K_M"
)
# --------------------------------------------------------------------------

[ "$#" -gt 0 ] && MODELOS=("$@")

BENCH="$LLAMA_DIR/build/bin/llama-bench"
if [ ! -x "$BENCH" ]; then
  echo "Error: no encuentro $BENCH (¿compilaste llama.cpp?)"
  exit 1
fi

# ¿Ya está en la caché? Busca un .gguf de esa cuantización, completo.
ya_descargado() {
  local repo="$1" quant="$2"
  local dir="$CACHE/models--${repo//\//--}"
  [ -d "$dir" ] || return 1
  # una descarga a medias deja archivos .incomplete
  if find "$dir" -name "*.incomplete" 2>/dev/null | grep -q .; then return 1; fi
  find -L "$dir/snapshots" -iname "*${quant}*.gguf" ! -iname "mmproj*" 2>/dev/null | grep -q .
}

echo "Caché: $CACHE"
echo "Espacio libre: $(df -h --output=avail "$HOME" | tail -1 | tr -d ' ')"
echo

total=${#MODELOS[@]}
i=0
bajados=(); salteados=(); fallidos=()

for m in "${MODELOS[@]}"; do
  i=$((i + 1))
  repo="${m%%:*}"
  quant="${m#*:}"
  [ "$quant" = "$m" ] && quant="Q4_K_M"

  echo "=== [$i/$total] $m ==="
  if ya_descargado "$repo" "$quant"; then
    echo "    ya está en la caché, lo salteo."
    salteados+=("$m")
    echo
    continue
  fi

  # Prueba mínima en CPU: baja el modelo (con barra de progreso) y confirma
  # que carga. No redirigir la salida: la barra solo se ve en la terminal.
  if "$BENCH" -hf "$m" -ngl 0 -p 16 -n 0 -r 1 --no-warmup; then
    bajados+=("$m")
  else
    echo "    FALLÓ la descarga o la carga de $m"
    fallidos+=("$m")
  fi
  echo
done

echo "================ Resumen ================"
echo "Descargados ahora : ${#bajados[@]}"
for m in "${bajados[@]:-}"; do [ -n "$m" ] && echo "   + $m"; done
echo "Ya estaban        : ${#salteados[@]}"
echo "Con error         : ${#fallidos[@]}"
for m in "${fallidos[@]:-}"; do [ -n "$m" ] && echo "   ! $m"; done
echo
echo "Uso de disco por modelo:"
du -sh "$CACHE"/models--* 2>/dev/null | sort -h

[ "${#fallidos[@]}" -eq 0 ]
