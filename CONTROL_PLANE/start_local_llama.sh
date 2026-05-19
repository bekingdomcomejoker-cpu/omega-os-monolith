#!/usr/bin/env bash
set -euo pipefail

COMMAND="start"
PORT="8080"

if [ "${1:-}" = "start" ] || [ "${1:-}" = "stop" ] || [ "${1:-}" = "status" ] || [ "${1:-}" = "dry-run" ]; then
  COMMAND="$1"
  PORT="${2:-8080}"
else
  PORT="${1:-8080}"
fi

HOST="${OMEGA_LOCAL_HOST:-127.0.0.1}"
BASE_DIR="${OMEGA_LOCAL_BASE:-${HOME}/omega-local}"
LOG_DIR="${BASE_DIR}/logs"
STATE_DIR="${BASE_DIR}/state"
PID_FILE="${STATE_DIR}/llama_server.pid"
LOG_FILE="${LOG_DIR}/llama_server.log"
ALLOW_KILL="${OMEGA_ALLOW_KILL:-1}"

mkdir -p "${LOG_DIR}" "${STATE_DIR}"

find_server() {
  if [ -n "${OMEGA_SERVER_BIN:-}" ]; then
    if [ -x "${OMEGA_SERVER_BIN}" ]; then
      echo "${OMEGA_SERVER_BIN}"
      return 0
    fi
    echo "[ERROR] OMEGA_SERVER_BIN is set but not executable: ${OMEGA_SERVER_BIN}" >&2
    return 1
  fi

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
  if [ -n "${OMEGA_MODEL_PATH:-}" ]; then
    if [ -f "${OMEGA_MODEL_PATH}" ]; then
      echo "${OMEGA_MODEL_PATH}"
      return 0
    fi
    echo "[ERROR] OMEGA_MODEL_PATH is set but file was not found: ${OMEGA_MODEL_PATH}" >&2
    return 1
  fi

  find "${HOME}" \
    \( -path "${HOME}/.cache" -o -path "${HOME}/.cargo" -o -path "${HOME}/.npm" \) -prune -o \
    -type f \( \
      -iname "*qwen2.5*0.5b*gguf" -o \
      -iname "*qwen25*0.5b*gguf" -o \
      -iname "*llama*3.2*1b*gguf" -o \
      -iname "*stablelm*gguf" \
    \) -print 2>/dev/null | head -n 1
}

pid_alive() {
  local pid="$1"
  [ -n "${pid}" ] && kill -0 "${pid}" 2>/dev/null
}

current_pid() {
  if [ -f "${PID_FILE}" ]; then
    cat "${PID_FILE}" 2>/dev/null || true
  fi
}

print_status() {
  local pid="$(current_pid)"
  echo "[*] host      : ${HOST}"
  echo "[*] port      : ${PORT}"
  echo "[*] log       : ${LOG_FILE}"
  echo "[*] pid file  : ${PID_FILE}"
  if pid_alive "${pid}"; then
    echo "[+] llama-server pid ${pid} appears alive"
    return 0
  fi
  echo "[-] no live llama-server pid recorded"
  return 1
}

stop_server() {
  local pid="$(current_pid)"
  if pid_alive "${pid}"; then
    echo "[*] stopping existing llama-server pid ${pid}"
    kill "${pid}" 2>/dev/null || true
    sleep 1
  fi

  if [ "${ALLOW_KILL}" = "1" ]; then
    pkill -f "llama-server.*--port ${PORT}" 2>/dev/null || true
  else
    echo "[i] OMEGA_ALLOW_KILL=${ALLOW_KILL}; skipping pkill fallback"
  fi
}

healthcheck() {
  python3 - <<PY
import json
import sys
import urllib.request
url = "http://${HOST}:${PORT}/v1/models"
try:
    with urllib.request.urlopen(url, timeout=8) as resp:
        raw = resp.read().decode("utf-8", errors="replace")
    print("[+] healthcheck ok:", url)
    try:
        data = json.loads(raw)
        print(json.dumps(data, indent=2)[:800])
    except Exception:
        print(raw[:800])
    sys.exit(0)
except Exception as exc:
    print("[WARN] healthcheck failed:", exc)
    sys.exit(1)
PY
}

SERVER_BIN="$(find_server || true)"
MODEL_PATH="$(find_model || true)"

case "${COMMAND}" in
  status)
    print_status
    exit $?
    ;;
  stop)
    stop_server
    print_status || true
    exit 0
    ;;
  dry-run)
    echo "[*] DRY RUN — no process will be started or stopped"
    echo "[*] server : ${SERVER_BIN:-MISSING}"
    echo "[*] model  : ${MODEL_PATH:-MISSING}"
    echo "[*] host   : ${HOST}"
    echo "[*] port   : ${PORT}"
    echo "[*] base   : ${BASE_DIR}"
    echo "[*] allow kill fallback: ${ALLOW_KILL}"
    exit 0
    ;;
  start)
    ;;
  *)
    echo "Usage: $0 [start|stop|status|dry-run] [port]"
    echo "Legacy form still works: $0 [port]"
    exit 1
    ;;
esac

if [ -z "${SERVER_BIN}" ]; then
  echo "[ERROR] llama-server not found"
  exit 1
fi

if [ -z "${MODEL_PATH}" ]; then
  echo "[ERROR] no pinned starter model found"
  echo "[i] set OMEGA_MODEL_PATH=/path/to/model.gguf to bypass recursive discovery"
  exit 1
fi

stop_server
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
  -t "${OMEGA_LLAMA_THREADS:-3}" \
  -c "${OMEGA_LLAMA_CTX:-2048}" \
  > "${LOG_FILE}" 2>&1 &

NEW_PID=$!
echo "${NEW_PID}" > "${PID_FILE}"

echo "[+] started pid ${NEW_PID}"
echo "[i] log: ${LOG_FILE}"
echo "[i] pid: ${PID_FILE}"

sleep 2
healthcheck || true
