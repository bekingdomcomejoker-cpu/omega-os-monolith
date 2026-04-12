#!/usr/bin/env bash
set -euo pipefail

PORT="${1:-8080}"
HOST="127.0.0.1"
BASE_DIR="${HOME}/omega-local"
LOG_DIR="${BASE_DIR}/logs"
STATE_DIR="${BASE_DIR}/state"
PID_FILE="${STATE_DIR}/llama_server.pid"
LOG_FILE="${LOG_DIR}/llama_server.log"

mkdir -p "${LOG_DIR}" "${STATE_DIR}"

find_server() {
  local candidates=(
    "${HOME}/federation/llama.cpp/build/bin/llama-server"
    "${HOME}/llama.cpp/build/bin/llama-server"
    "/data/data/com.termux/files/usr/bin/llama-server"
  )

  for p in "${candidates[@]}"; do
    if [ -x "$p" ]; then
      echo "$p"
      return 0
    fi
  done

  if command -v llama-server >/dev/null 2>&1; then
    command -v llama-server
    return 0
  fi

  return 1
}

find_model() {
  find "${HOME}" \
    \( -path "${HOME}/.cache" -o -path "${HOME}/.cargo" -o -path "${HOME}/.npm" \) -prune -o \
    -type f \( \
      -iname "*qwen2.5*0.5b*gguf" -o \
      -iname "*qwen25*0.5b*gguf" -o \
      -iname "*llama*3.2*1b*gguf" -o \
      -iname "*stablelm*gguf" \
    \) -print 2>/dev/null | head -n 1
}

SERVER_BIN="$(find_server || true)"
MODEL_PATH="$(find_model || true)"

if [ -z "${SERVER_BIN}" ]; then
  echo "[ERROR] llama-server not found"
  exit 1
fi

if [ -z "${MODEL_PATH}" ]; then
  echo "[ERROR] no pinned starter model found"
  exit 1
fi

if [ -f "${PID_FILE}" ]; then
  OLD_PID="$(cat "${PID_FILE}" 2>/dev/null || true)"
  if [ -n "${OLD_PID}" ] && kill -0 "${OLD_PID}" 2>/dev/null; then
    echo "[*] stopping existing llama-server pid ${OLD_PID}"
    kill "${OLD_PID}" 2>/dev/null || true
    sleep 1
  fi
fi

pkill -f "llama-server.*--port ${PORT}" 2>/dev/null || true
sleep 1

echo "[*] server : ${SERVER_BIN}"
echo "[*] model  : ${MODEL_PATH}"
echo "[*] host   : ${HOST}"
echo "[*] port   : ${PORT}"

nohup "${SERVER_BIN}" \
  -m "${MODEL_PATH}" \
  --host "${HOST}" \
  --port "${PORT}" \
  -ngl 0 \
  -t 3 \
  -c 2048 \
  > "${LOG_FILE}" 2>&1 &

NEW_PID=$!
echo "${NEW_PID}" > "${PID_FILE}"

echo "[+] started pid ${NEW_PID}"
echo "[i] log: ${LOG_FILE}"
echo "[i] pid: ${PID_FILE}"
