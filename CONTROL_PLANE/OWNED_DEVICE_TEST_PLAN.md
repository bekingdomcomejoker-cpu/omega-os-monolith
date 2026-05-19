# Omega Control Plane — Owned-Device Test Plan

Purpose: verify the Termux/local control plane on an owned device without guessing, without hidden activation, and without losing the local-first route.

This plan assumes the operator controls the device and repository checkout.

## 0. Source boundary

Do not pipe model output directly into shell.

Read commands first. Paste only commands you understand into an owned terminal.

## 1. Confirm working directory

```bash
pwd
ls -la
ls -la CONTROL_PLANE
```

Expected files:

```text
CONTROL_PLANE/start_local_llama.sh
CONTROL_PLANE/omega_terminal_router_http.py
CONTROL_PLANE/README.md
```

## 2. Optional explicit paths

Prefer explicit paths when possible. This avoids slow recursive discovery.

```bash
export OMEGA_MODEL_PATH="$HOME/models/model.gguf"
export OMEGA_SERVER_BIN="$HOME/llama.cpp/build/bin/llama-server"
```

Only set these if the files exist.

```bash
ls -lh "$OMEGA_MODEL_PATH"
ls -lh "$OMEGA_SERVER_BIN"
```

## 3. Dry-run server discovery

```bash
bash CONTROL_PLANE/start_local_llama.sh dry-run 8080
```

Pass condition:

```text
server: resolved path or MISSING with explanation
model : resolved path or MISSING with explanation
no process started
no process stopped
```

If model discovery is wrong, set `OMEGA_MODEL_PATH` and repeat dry-run.

## 4. Status before start

```bash
bash CONTROL_PLANE/start_local_llama.sh status 8080 || true
```

This should not start anything. It only reports host, port, log path, PID file, and whether a recorded PID is alive.

## 5. Start local llama-server

```bash
bash CONTROL_PLANE/start_local_llama.sh start 8080
```

Expected behavior:

- Stops previous PID-file process if alive.
- Uses fallback `pkill` only if `OMEGA_ALLOW_KILL=1`.
- Starts `llama-server` with nohup.
- Writes PID under `~/omega-local/state/llama_server.pid`.
- Writes logs under `~/omega-local/logs/llama_server.log`.
- Runs `/v1/models` healthcheck.

To disable fallback `pkill`:

```bash
export OMEGA_ALLOW_KILL=0
bash CONTROL_PLANE/start_local_llama.sh start 8080
```

## 6. Router healthcheck

```bash
python3 CONTROL_PLANE/omega_terminal_router_http.py healthcheck
```

Pass condition:

```text
OK
```

If it fails, inspect:

```bash
tail -n 80 ~/omega-local/logs/llama_server.log
cat ~/omega-local/state/llama_server.pid
```

## 7. Local-only route test

This tests local inference without Gemini fallback, clipboard, or notification output.

```bash
python3 CONTROL_PLANE/omega_terminal_router_http.py --local-only --no-clipboard --no-notify reason "say ready in five words"
```

Pass condition:

- Output appears in terminal.
- `last_source` should be `local` in state if local model responded.
- No clipboard write.
- No Termux notification.

Inspect state and bus:

```bash
cat ~/omega-local/state/terminal_router_state.json
 tail -n 20 ~/omega-local/logs/comm_bus.jsonl
```

## 8. Normal route test

This uses default behavior: local-first, Gemini fallback if local fails, clipboard and notification enabled.

```bash
python3 CONTROL_PLANE/omega_terminal_router_http.py reason "say ready"
```

Pass condition:

- Output appears in terminal.
- Output is copied to clipboard if Termux API is available.
- Termux notification appears if Termux API is available.
- Bus records command and result.

## 9. Interactive route test

```bash
python3 CONTROL_PLANE/omega_terminal_router_http.py
```

Try:

```text
healthcheck
reason say ready
code write a Python function that returns true
exit
```

## 10. Stop server

```bash
bash CONTROL_PLANE/start_local_llama.sh stop 8080
bash CONTROL_PLANE/start_local_llama.sh status 8080 || true
```

## 11. Evidence bundle

After a test run, collect:

```bash
mkdir -p ~/omega-local/reports/control-plane-test
cp ~/omega-local/state/terminal_router_state.json ~/omega-local/reports/control-plane-test/ 2>/dev/null || true
cp ~/omega-local/state/llama_server.pid ~/omega-local/reports/control-plane-test/ 2>/dev/null || true
cp ~/omega-local/logs/comm_bus.jsonl ~/omega-local/reports/control-plane-test/ 2>/dev/null || true
tail -n 120 ~/omega-local/logs/llama_server.log > ~/omega-local/reports/control-plane-test/llama_server_tail.log 2>/dev/null || true
```

## 12. Do not proceed if

Stop and inspect before adding more layers if:

- `healthcheck` fails.
- `comm_bus.jsonl` is not written.
- `terminal_router_state.json` is not written.
- local-only route unexpectedly calls Gemini.
- clipboard/notification flags are ignored.
- PID file points to a dead or unrelated process.

## 13. Next layer only after pass

Only after this direct route passes should secondary ingress layers be reattached:

- clipboard watcher
- notification listener
- bridge automation
- external model fallback orchestration
- multi-node router logic

The direct route is the command surface of record.
