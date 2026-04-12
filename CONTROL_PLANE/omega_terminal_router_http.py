#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import subprocess
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Optional

BASE = Path.home() / "omega-local"
LOGS = BASE / "logs"
STATE = BASE / "state"

BUS_FILE = LOGS / "comm_bus.jsonl"
STATE_FILE = STATE / "terminal_router_state.json"

LOCAL_URL = os.environ.get("OMEGA_LOCAL_URL", "http://127.0.0.1:8080/v1/chat/completions")
LOCAL_MODEL_NAME = os.environ.get("OMEGA_LOCAL_MODEL_NAME", "local")
MAX_TOKENS = int(os.environ.get("OMEGA_MAX_TOKENS", "220"))
TEMPERATURE = float(os.environ.get("OMEGA_TEMPERATURE", "0.2"))


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def append_jsonl(path: Path, record: Dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(record, ensure_ascii=False) + "\n")


def save_json(path: Path, data: Dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)


def set_clipboard(text: str) -> None:
    try:
        subprocess.run(
            ["termux-clipboard-set"],
            input=text,
            text=True,
            timeout=5,
            capture_output=True,
            check=False,
        )
    except Exception:
        pass


def notify_local(title: str, content: str) -> None:
    try:
        subprocess.run(
            ["termux-notification", "--title", f"ΩTERM {title}", "--content", content[:180]],
            timeout=5,
            capture_output=True,
            text=True,
            check=False,
        )
    except Exception:
        pass


def get_api_key() -> Optional[str]:
    return os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")


def build_prompt(route: str, user_prompt: str) -> str:
    route = route.lower().strip()
    user_prompt = user_prompt.strip()

    if route == "code":
        return (
            "Answer with usable code first. Keep comments minimal. "
            "Do not narrate internal reasoning. "
            f"Task: {user_prompt}"
        )
    if route == "r1":
        return user_prompt
    return (
        "Answer directly and briefly. "
        "Do not describe internal reasoning. "
        "Use one short paragraph unless asked for more. "
        f"User request: {user_prompt}"
    )


def call_local(route: str, user_prompt: str) -> str:
    prompt = build_prompt(route, user_prompt)
    payload = {
        "model": LOCAL_MODEL_NAME,
        "messages": [
            {"role": "system", "content": "You are the Omega local router backend. Reply directly and clearly."},
            {"role": "user", "content": prompt},
        ],
        "temperature": TEMPERATURE,
        "max_tokens": MAX_TOKENS,
        "stream": False,
    }

    req = urllib.request.Request(
        LOCAL_URL,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    try:
        with urllib.request.urlopen(req, timeout=90) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
        data = json.loads(raw)
        return data["choices"][0]["message"]["content"].strip()
    except Exception as e:
        return f"[ERROR] local backend failed: {e}"


def call_gemini(route: str, user_prompt: str) -> str:
    api_key = get_api_key()
    if not api_key:
        return "[ERROR] no GEMINI_API_KEY or GOOGLE_API_KEY set"

    try:
        from google import genai

        client = genai.Client(api_key=api_key)
        prompt = build_prompt(route, user_prompt)
        resp = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt,
        )
        text = (resp.text or "").strip()
        return text or "[ERROR] Gemini returned empty output"
    except Exception as e:
        return f"[ERROR] Gemini fallback failed: {e}"


def route_once(route: str, prompt: str) -> str:
    append_jsonl(
        BUS_FILE,
        {
            "timestamp": utc_now(),
            "kind": "command",
            "route": f"node_{route}",
            "priority": "high",
            "trigger": route,
            "prompt": prompt,
            "status": "started",
        },
    )

    output = call_local(route, prompt)
    source = "local"

    if output.startswith("[ERROR]"):
        gem = call_gemini(route, prompt)
        if not gem.startswith("[ERROR]"):
            output = gem
            source = "gemini"
        else:
            output = gem
            source = "error"

    set_clipboard(output)

    append_jsonl(
        BUS_FILE,
        {
            "timestamp": utc_now(),
            "kind": "result",
            "route": f"node_{route}",
            "priority": "medium",
            "trigger": route,
            "source": source,
            "output_preview": output[:240],
        },
    )

    save_json(
        STATE_FILE,
        {
            "timestamp": utc_now(),
            "last_trigger": route,
            "last_prompt": prompt,
            "last_source": source,
            "last_output_preview": output[:240],
        },
    )

    notify_local("Answer Ready", f"@{route} via {source} — result copied to clipboard")
    return output


def shell_loop() -> int:
    print("=" * 72)
    print("OMEGA TERMINAL ROUTER HTTP")
    print("=" * 72)
    print("Type like:")
    print("  reason explain why the bash wrapper failed under python")
    print("  code write a python function that deduplicates notifications by key")
    print("  r1 analyze this output")
    print("Type 'exit' to leave.")
    print("=" * 72)

    while True:
        try:
            raw = input("oroute> ").strip()
        except (EOFError, KeyboardInterrupt):
            print()
            return 0

        if not raw:
            continue
        if raw.lower() in {"exit", "quit"}:
            return 0

        parts = raw.split(" ", 1)
        if len(parts) < 2:
            print("Format: <route> <prompt>")
            continue

        route = parts[0].strip().lower()
        prompt = parts[1].strip()
        print()
        print(route_once(route, prompt))
        print()


def main() -> int:
    if len(sys.argv) == 1:
        return shell_loop()

    if len(sys.argv) < 3:
        print("Usage: oroute <route> <prompt>")
        return 1

    route = sys.argv[1].strip().lower()
    prompt = " ".join(sys.argv[2:]).strip()
    print(route_once(route, prompt))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
