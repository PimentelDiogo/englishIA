#!/usr/bin/env python3
"""
RAGAS eval harness do AI Tutor (Fase 3 / ADR-003).

Roda OFFLINE contra o gateway em execução:
  1. Para cada pergunta do dataset, chama /tutor/retrieve (contextos) e /tutor/chat (resposta).
  2. Monta um dataset RAGAS (question, answer, contexts, ground_truth).
  3. Calcula faithfulness, answer_relevancy, context_precision, context_recall.

Pré-requisitos:
  - Gateway no ar (docker compose up) com DB semeado + GEMINI_API_KEY.
  - GEMINI_API_KEY no ambiente (o RAGAS usa o Gemini como juiz/embeddings).
  - pip install -r requirements.txt

⚠️ A API do RAGAS muda entre versões — este script segue a linha 0.2.x (ver requirements).
   Se algo divergir, confira a doc da sua versão do ragas.
"""
import json
import os
import sys
import pathlib
import requests

GATEWAY = os.environ.get("GATEWAY_URL", "http://localhost:8080")
DATASET = pathlib.Path(__file__).parent / "dataset.json"


def collect_samples():
    """Bate no gateway e coleta (question, answer, contexts, ground_truth)."""
    rows = json.loads(DATASET.read_text())
    samples = []
    for row in rows:
        q = row["question"]
        ctx = requests.post(f"{GATEWAY}/tutor/retrieve", json={"message": q}, timeout=60).json()
        contexts = [c["content"] for c in ctx] or ["(no context retrieved)"]
        ans = requests.post(f"{GATEWAY}/tutor/chat", json={"message": q}, timeout=60).json()
        samples.append({
            "user_input": q,
            "response": ans.get("reply", ""),
            "retrieved_contexts": contexts,
            "reference": row["ground_truth"],
        })
        print(f"  ✓ {q}")
    return samples


def main():
    if not os.environ.get("GEMINI_API_KEY"):
        sys.exit("Defina GEMINI_API_KEY (o RAGAS usa o Gemini como juiz).")

    print(f"Coletando amostras do gateway em {GATEWAY} ...")
    samples = collect_samples()

    # Imports pesados só depois da coleta (falha cedo se o gateway estiver fora).
    from datasets import Dataset
    from ragas import evaluate
    from ragas.metrics import faithfulness, answer_relevancy, context_precision, context_recall
    from langchain_google_genai import ChatGoogleGenerativeAI, GoogleGenerativeAIEmbeddings

    key = os.environ["GEMINI_API_KEY"]
    judge = ChatGoogleGenerativeAI(model="gemini-2.5-flash", google_api_key=key)
    embeddings = GoogleGenerativeAIEmbeddings(model="models/gemini-embedding-001", google_api_key=key)

    ds = Dataset.from_list(samples)
    result = evaluate(
        ds,
        metrics=[faithfulness, answer_relevancy, context_precision, context_recall],
        llm=judge,
        embeddings=embeddings,
    )
    print("\n=== RAGAS ===")
    print(result)


if __name__ == "__main__":
    main()
