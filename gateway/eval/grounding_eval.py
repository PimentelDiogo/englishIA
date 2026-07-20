#!/usr/bin/env python3
"""
Eval de grounding RAGAS-style — SEM dependências (só stdlib).

Fallback do ragas_eval.py quando o pacote `ragas` não instala (ex.: Python muito novo).
Usa o gateway + o Gemini (REST) como juiz para pontuar 0..1:
  - faithfulness      : a resposta está fundamentada nos contextos? (anti-alucinação)
  - answer_relevance  : a resposta responde à pergunta?
  - context_relevance : os contextos recuperados são relevantes?

Requisitos: gateway no ar (base semeada) + GEMINI_API_KEY.
Uso:  GATEWAY_URL=http://localhost:8081 GEMINI_API_KEY=... python3 grounding_eval.py
"""
import json
import os
import pathlib
import time
import urllib.request

GATEWAY = os.environ.get("GATEWAY_URL", "http://localhost:8080")
KEY = os.environ["GEMINI_API_KEY"]
GEMINI = ("https://generativelanguage.googleapis.com/v1beta/models/"
          "gemini-2.5-flash:generateContent?key=" + KEY)
DATASET = pathlib.Path(__file__).parent / "dataset.json"

JUDGE_SYSTEM = (
    "You are a strict evaluator of an English tutor. Given QUESTION, CONTEXTS and ANSWER, "
    "score each metric from 0.0 to 1.0:\n"
    "- faithfulness: are the answer's factual claims supported by the contexts?\n"
    "- answer_relevance: does the answer address the question?\n"
    "- context_relevance: are the contexts relevant to the question?\n"
    'Return ONLY compact JSON: {"faithfulness":x,"answer_relevance":x,"context_relevance":x}'
)


def post(url, payload, tries=5):
    data = json.dumps(payload).encode()
    for attempt in range(tries):
        req = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                return json.loads(r.read())
        except urllib.error.HTTPError as e:
            # 429/502 (rate limit do free tier): backoff exponencial e tenta de novo.
            if e.code in (429, 502) and attempt < tries - 1:
                wait = 10 * (attempt + 1)
                print(f"    …{e.code} — aguardando {wait}s (free tier)")
                time.sleep(wait)
                continue
            raise


def judge(question, contexts, answer):
    prompt = (f"{JUDGE_SYSTEM}\n\nQUESTION:\n{question}\n\nCONTEXTS:\n"
              + "\n".join(f"- {c}" for c in contexts) + f"\n\nANSWER:\n{answer}")
    resp = post(GEMINI, {"contents": [{"parts": [{"text": prompt}]}]})
    text = resp["candidates"][0]["content"]["parts"][0]["text"]
    text = text.replace("```json", "").replace("```", "").strip()
    return json.loads(text)


def main():
    rows = json.loads(DATASET.read_text())
    max_q = int(os.environ.get("MAX_Q", "0"))
    if max_q > 0:
        rows = rows[:max_q]
    totals = {"faithfulness": 0.0, "answer_relevance": 0.0, "context_relevance": 0.0}
    n = 0
    print(f"Gateway: {GATEWAY}\n")
    for row in rows:
        q = row["question"]
        ctx = post(f"{GATEWAY}/tutor/retrieve", {"message": q})
        contexts = [c["content"] for c in ctx] or ["(no context retrieved)"]
        ans = post(f"{GATEWAY}/tutor/chat", {"message": q}).get("reply", "")
        scores = judge(q, contexts, ans)
        for k in totals:
            totals[k] += float(scores.get(k, 0))
        n += 1
        print(f"  {q[:45]:45s}  "
              + "  ".join(f"{k[:4]}={scores.get(k, 0):.2f}" for k in totals))
        time.sleep(4)  # respiro para o rate limit do free tier

    print("\n=== MÉDIAS (0..1) ===")
    for k in totals:
        print(f"  {k:18s}: {totals[k]/n:.3f}")


if __name__ == "__main__":
    main()
