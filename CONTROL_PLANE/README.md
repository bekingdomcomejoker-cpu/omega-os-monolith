# Omega Control Plane

This directory contains the stabilized Termux control-plane layer for Omega OS Monolith.

## Role
The control plane provides:
- a direct terminal ingress (`oroute`)
- a pinned local model server bootstrap (`start_local_llama.sh`)
- local-first inference through `llama-server`
- Gemini fallback when local inference fails
- structured command and result logging into the communication bus

## Files
- `start_local_llama.sh` — starts the local `llama-server` process with a pinned small model
- `omega_terminal_router_http.py` — routes direct terminal commands to the local HTTP model endpoint first, then Gemini fallback
- `INSTALL_TERMUX_CONTROL_PLANE.md` — setup and runtime instructions
- `TERMUX_CONTROL_PLANE_BOOTSTRAP.md` — control-plane purpose and design notes
- `STARTUP_ORDER_AND_FALLBACKS.md` — verified startup sequence and recovery rule set

## Design rule
This is not a demo-only layer. It is the stabilized measurement and execution surface from which the larger architecture can expand.

## Primary workflow
1. Start the local model server.
2. Launch or invoke the direct terminal router.
3. Re-attach secondary ingress layers only after the direct route is verified.

## Direct examples
- `oroute reason "explain why the wrapper failed"`
- `oroute code "write a function to deduplicate notifications"`
- interactive `oroute`
