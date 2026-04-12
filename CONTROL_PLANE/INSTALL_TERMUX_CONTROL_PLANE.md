# Install Termux Control Plane

## Purpose
This guide installs and runs the Omega Termux control plane from a Termux environment.

## Assumptions
- Termux is installed
- `llama.cpp` binaries are present or available in a known path
- at least one pinned small GGUF model exists locally
- `GEMINI_API_KEY` or `GOOGLE_API_KEY` is available if Gemini fallback is desired

## Step 1 — ensure runtime directories exist
```bash
mkdir -p ~/omega-local/{logs,state}
mkdir -p ~/bin
```

## Step 2 — export your Gemini key if you want fallback
```bash
export GEMINI_API_KEY="your_key_here"
```
Or use:
```bash
export GOOGLE_API_KEY="your_key_here"
```

## Step 3 — place or symlink the router command
Recommended wrapper:
```bash
cat > ~/bin/oroute <<'EOF'
#!/usr/bin/env bash
exec python "$HOME/omega-os-monolith/CONTROL_PLANE/omega_terminal_router_http.py" "$@"
EOF
chmod +x ~/bin/oroute
```
Add to shell path if needed:
```bash
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## Step 4 — start the local model server
```bash
bash CONTROL_PLANE/start_local_llama.sh 8080
```
Check the log:
```bash
tail -n 40 ~/omega-local/logs/llama_server.log
```

## Step 5 — run the router
Direct command:
```bash
oroute reason "explain in one short paragraph why the bash wrapper failed under python"
```
Interactive mode:
```bash
oroute
```

## Step 6 — inspect state and logs
```bash
cat ~/omega-local/state/terminal_router_state.json
tail -n 10 ~/omega-local/logs/comm_bus.jsonl
```

## Operational rule
Verify the direct terminal route first. Only after that should clipboard or notification ingress layers be re-attached.

## Recovery
If the system becomes noisy:
1. stop secondary watchers
2. confirm `llama-server` is up
3. confirm `oroute` works
4. check the log and state files
5. re-enable secondary ingress layers one by one
