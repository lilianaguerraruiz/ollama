#!/usr/bin/env bash
set -euo pipefail

# Welche Modelle sollen garantiert vorhanden sein?
# Du kannst in Render per Environment Variable OLLAMA_MODELS z.B. "nomic-embed-text" setzen
# oder mehrere Modelle per Komma: "nomic-embed-text,embeddinggemma"
OLLAMA_MODELS="${OLLAMA_MODELS:-nomic-embed-text}"

# Ollama host/port (lokal im Container)
export OLLAMA_HOST="${OLLAMA_HOST:-0.0.0.0:11434}"

echo "[start] Starting Ollama server on ${OLLAMA_HOST} ..."
ollama serve &
SERVER_PID=$!

# Warten bis API antwortet
echo "[start] Waiting for Ollama API to become ready ..."
for i in {1..60}; do
  if curl -s "http://127.0.0.1:11434/api/tags" >/dev/null 2>&1; then
    echo "[start] Ollama API is ready."
    break
  fi
  sleep 1
  if [[ $i -eq 60 ]]; then
    echo "[error] Ollama API did not become ready in time."
    kill "${SERVER_PID}" || true
    exit 1
  fi
done

# Modelle-Liste parsen (Komma-separiert)
IFS=',' read -ra MODELS <<< "${OLLAMA_MODELS}"

# Für jedes Modell: nur pullen, wenn es fehlt
for MODEL in "${MODELS[@]}"; do
  MODEL="$(echo "$MODEL" | xargs)" # trim
  [[ -z "$MODEL" ]] && continue

  echo "[start] Ensuring model exists: ${MODEL}"

  # Prüfen, ob Modell vorhanden ist
  if ollama list | awk '{print $1}' | grep -qx "${MODEL}"; then
    echo "[start] Model already present: ${MODEL}"
  else
    echo "[start] Pulling model: ${MODEL}"
    ollama pull "${MODEL}"
    echo "[start] Pulled model: ${MODEL}"
  fi
done

echo "[start] Startup complete. Keeping Ollama server in foreground."
wait "${SERVER_PID}"
