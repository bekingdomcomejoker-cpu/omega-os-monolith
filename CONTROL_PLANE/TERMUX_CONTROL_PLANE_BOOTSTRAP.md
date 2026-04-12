# Termux Control Plane Bootstrap

**Version:** 1.0  
**Date:** 2026-04-12

## Purpose
This document defines the stabilized bootstrap path for the Omega Termux control plane.

## Control-plane objective
Establish one reliable local execution layer that can:
- accept direct terminal commands
- call a pinned local model server first
- fall back to Gemini when local inference fails
- log all command and result events
- support secondary ingress layers such as clipboard and notification routing

## Primary command surface
Preferred command surface:
- `oroute reason "..."`
- `oroute code "..."`
- interactive `oroute`

This is the control-plane ingress of record for direct operator interaction.

## Local backend
Preferred local backend:
- `llama-server`
- pinned known-good small model first
- localhost HTTP request path for deterministic routing

This replaces interactive `llama-cli` as the primary automation backend.

## Fallback backend
Preferred fallback backend:
- Gemini via official Python SDK configuration
- local backend attempted first
- fallback used only when local inference returns a hard failure or empty result

## Runtime components
Core files now associated with this layer include:
- `start_local_llama.sh`
- `omega_terminal_router_http.py`
- `comm_bus.jsonl`
- state files for router and server process tracking

## Logging
All command and result events should be written in structured form so the control plane can be audited, replayed, or extended without losing the chain of decisions.

## Secondary ingress layers
Secondary ingress layers may include:
- clipboard router
- notification router
- direct local API calls

These are secondary to the direct terminal control path and should not silently replace it.

## Design rule
The control plane is not a minimal demo layer. It is the stabilized measurement and execution surface from which the larger architecture can safely expand.
