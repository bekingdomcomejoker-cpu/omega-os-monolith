# Omega Control Plane

This directory contains the stabilized Termux control-plane layer for Omega OS Monolith.

## Role
The control plane provides:
- a direct terminal ingress (`oroute`)
- a pinned local model server bootstrap (`start_local_llama.sh`)
- local-first inference through `llama-server`
- Gemini fallback when local inference fails, unless local-only mode is enabled
- structured command and result logging into the communication bus
- visible clipboard/notification output, unless disabled for testing

## Files
- `start_local_llama.sh` — starts, stops, checks, or dry-runs the local `llama-server` process with a pinned small model
- `omega_terminal_router_http.py` — routes direct terminal commands to the local HTTP model endpoint first, then Gemini fallback
- `INSTALL_TERMUX_CONTROL_PLANE.md` — setup and runtime instructions
- `TERMUX_CONTROL_PLANE_BOOTSTRAP.md` — control-plane purpose and design notes
- `STARTUP_ORDER_AND_FALLBACKS.md` — verified startup sequence and recovery rule set

## Design rule
This is not a demo-only layer. It is the stabilized measurement and execution surface from which the larger architecture can expand.

The control plane should remain:
- local-first
- operator-visible
- logged
- explicitly routed
- reversible where practical
- source-preserving

## Local llama control

Legacy start still works:

```bash
bash CONTROL_PLANE/start_local_llama.sh 8080
```

Operator command form:

```bash
bash CONTROL_PLANE/start_local_llama.sh dry-run 8080
bash CONTROL_PLANE/start_local_llama.sh status 8080
bash CONTROL_PLANE/start_local_llama.sh start 8080
bash CONTROL_PLANE/start_local_llama.sh stop 8080
```

Useful overrides:

```bash
export OMEGA_MODEL_PATH="$HOME/models/model.gguf"
export OMEGA_SERVER_BIN="$HOME/llama.cpp/build/bin/llama-server"
export OMEGA_LOCAL_HOST="127.0.0.1"
export OMEGA_LLAMA_THREADS=3
export OMEGA_LLAMA_CTX=2048
export OMEGA_ALLOW_KILL=0
```

`OMEGA_MODEL_PATH` bypasses recursive model discovery. `OMEGA_SERVER_BIN` bypasses server discovery. `OMEGA_ALLOW_KILL=0` prevents the fallback `pkill` path while still allowing PID-file based stop behavior.

## Direct router workflow

Interactive:

```bash
python3 CONTROL_PLANE/omega_terminal_router_http.py
```

CLI:

```bash
python3 CONTROL_PLANE/omega_terminal_router_http.py reason "explain why the wrapper failed"
python3 CONTROL_PLANE/omega_terminal_router_http.py code "write a function to deduplicate notifications"
python3 CONTROL_PLANE/omega_terminal_router_http.py r1 "analyze this output"
```

Healthcheck:

```bash
python3 CONTROL_PLANE/omega_terminal_router_http.py healthcheck
```

Optional operator flags:

```bash
python3 CONTROL_PLANE/omega_terminal_router_http.py --local-only reason "test local backend only"
python3 CONTROL_PLANE/omega_terminal_router_http.py --no-clipboard reason "test without clipboard writes"
python3 CONTROL_PLANE/omega_terminal_router_http.py --no-notify reason "test without Termux notifications"
```

Equivalent environment flags:

```bash
export OMEGA_LOCAL_ONLY=1
export OMEGA_ENABLE_CLIPBOARD=0
export OMEGA_ENABLE_NOTIFY=0
export OMEGA_LOCAL_URL="http://127.0.0.1:8080/v1/chat/completions"
export OMEGA_LOCAL_MODEL_NAME="local"
export OMEGA_MAX_TOKENS=220
export OMEGA_TEMPERATURE=0.2
export OMEGA_GEMINI_MODEL="gemini-2.5-flash"
```

## Primary workflow
1. Dry-run local llama discovery.
2. Start or confirm the local model server.
3. Run router healthcheck.
4. Launch or invoke the direct terminal router.
5. Re-attach secondary ingress layers only after the direct route is verified.

## Direct examples
- `oroute reason "explain why the wrapper failed"`
- `oroute code "write a function to deduplicate notifications"`
- interactive `oroute`
