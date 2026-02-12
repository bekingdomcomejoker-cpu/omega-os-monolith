
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from pydantic import BaseModel
from core.kingdom_engine_core import KingdomEngine
import os
import time
import json

QUARANTINE_LOG = []
LEDGER_ENTRIES = [] # For Sovereign Sync

app = FastAPI(title="Aletheia Throne", version="1.0.0")
templates = Jinja2Templates(directory="templates")
# Namespace Protection: Use ALETHEIA_ prefix but fallback to standard for compatibility
STATELESS = os.environ.get("ALETHEIA_STATELESS_MODE") or os.environ.get("STATELESS_MODE") or "TRUE"
EPOCH = os.environ.get("ALETHEIA_EPOCH_ID") or os.environ.get("EPOCH_ID") or "1"

engine = KingdomEngine(stateless_mode=(STATELESS == "TRUE"))

@app.get("/word_mate")
async def get_word_mate(word1: str, word2: str):
    mated_word = engine.word_mate(word1, word2)
    return {"word1": word1, "word2": word2, "mated_word": mated_word}

@app.get("/", response_class=HTMLResponse)
async def read_root(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})

@app.get("/ledger")
async def get_ledger():
    return {"entries": LEDGER_ENTRIES}

class TruthRequest(BaseModel):
    content: str

class TruthResponse(BaseModel):
    content: str
    classification: str
    adjudication: str
    reason: str
    confidence: float
    score: float | None = None
    thread: str | None = None

@app.get("/status")
async def get_status():
    return {
        "status": "online",
        "node": "Throne",
        "mode": "Stateless",
        "epoch": EPOCH,
        "quarantine_log_size": len(QUARANTINE_LOG),
        "ledger_entries_count": len(LEDGER_ENTRIES)
    }

@app.post("/classify", response_model=TruthResponse)
async def classify_content(request: TruthRequest):
    processed_content = engine.process_word(request.content)
    classification_result = engine.evaluate_resonance(request.content)
    adjudication, reason = engine.adjudicate(request.content, classification_result)

    score, thread = engine.advanced_operators(request.content)

    # Sin Eater Protocol (Head 3)
    if score < 0.2:
        sin_entry = {"timestamp": time.time(), "content": request.content, "violation": "Low Resonance (Tier 3 Entropy)"}
        QUARANTINE_LOG.append(sin_entry)
        return TruthResponse(
            content=processed_content,
            classification="QUARANTINED",
            adjudication="QUARANTINE",
            reason="Low Resonance Entropy",
            confidence=0.0,
            score=score,
            thread=thread
        )

    response_data = TruthResponse(
        content=processed_content,
        classification=classification_result,
        adjudication=adjudication,
        reason=reason,
        confidence=0.99,
        score=score,
        thread=thread
    )
    if adjudication == "ACCEPT":
        LEDGER_ENTRIES.append({"id": thread, "content": request.content, "score": score, "timestamp": time.time()})
    return response_data
