#!/usr/bin/env python3
"""
scripts/verify_ai_tutor_live.py
Direct verification script for OpenRouter AI Tutor live integration.
Reads OPENROUTER_API_KEY from environment or .env file and tests the two
primary driving tutor questions against the active OpenRouter models.
"""

import os
import sys
import json
import urllib.request
import urllib.error

API_URL = "https://openrouter.ai/api/v1/chat/completions"

SYSTEM_PROMPT = """Sei un istruttore esperto di teoria della patente B italiana.
Rispondi in modo conciso ma molto chiaro e accurato (massimo 4-5 frasi).
Fornisci la regola ufficiale del Codice della Strada se pertinente.
Dopo la spiegazione in italiano, fornisci OBBLIGATORIAMENTE una breve traduzione/spiegazione in lingua URDU (con alfabeto urdu) per aiutare gli studenti pachistani.
Formatta la risposta esattamente così:
ITA: [La tua risposta in italiano]
URDU: [La tua spiegazione in urdu]"""

QUESTIONS = [
    "Qual è la differenza tra segnale di STOP e Dare Precedenza?",
    "Quali sono i limiti di velocità per i neopatentati in autostrada?",
]

def get_api_key():
    key = os.environ.get("OPENROUTER_API_KEY", "").strip()
    if key:
        return key
    env_file = ".env"
    if os.path.exists(env_file):
        with open(env_file, "r", encoding="utf-8") as f:
            for line in f:
                if line.startswith("OPENROUTER_API_KEY="):
                    return line.split("=", 1)[1].strip()
    return ""

def query_model(model: str, user_question: str, key: str):
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {key}",
        "HTTP-Referer": "https://patenteitaliana.app",
        "X-Title": "Patente Italiana App",
    }
    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": user_question},
        ],
    }
    req = urllib.request.Request(API_URL, data=json.dumps(payload).encode("utf-8"), headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            content = data["choices"][0]["message"]["content"]
            return {"success": True, "status": resp.status, "content": content}
    except urllib.error.HTTPError as e:
        return {"success": False, "status": e.code, "error": e.read().decode("utf-8")}
    except Exception as e:
        return {"success": False, "status": 0, "error": str(e)}

def main():
    key = get_api_key()
    if not key:
        print("ERROR: OPENROUTER_API_KEY not found in environment or .env file!", file=sys.stderr)
        sys.exit(1)

    print(f"OPENROUTER_API_KEY detected (length: {len(key)})")
    models = ["openrouter/free", "cohere/north-mini-code:free"]

    for i, q in enumerate(QUESTIONS, 1):
        print(f"\n============================================================")
        print(f"QUESTION {i}: {q}")
        print(f"============================================================")

        success = False
        for model in models:
            print(f"Attempting model: {model} ...")
            res = query_model(model, q, key)
            if res["success"]:
                print(f"HTTP {res['status']} SUCCESS from {model}:")
                print("------------------------------------------------------------")
                print(res["content"])
                print("------------------------------------------------------------")
                success = True
                break
            else:
                print(f"Model {model} failed (HTTP {res['status']}): {res.get('error', '')}")

        if not success:
            print(f"FAILED to obtain AI response for question {i} across all models!", file=sys.stderr)
            sys.exit(1)

    print("\nSUCCESS: All questions answered successfully by live OpenRouter models!")

if __name__ == "__main__":
    main()

