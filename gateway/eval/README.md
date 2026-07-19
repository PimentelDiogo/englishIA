# RAGAS eval — AI Tutor (Fase 3 / ADR-003)

Mede a qualidade do RAG (grounding/faithfulness) contra o eval dataset — o SLO do
[[PRD-ai-tutor]]. Roda **offline**, contra o gateway em execução.

## Como rodar

```bash
# 1. Suba o stack com a base semeada (na pasta gateway/)
GEMINI_API_KEY=sua_chave docker compose up -d --build

# 2. Ambiente Python do harness
cd eval
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# 3. Rode o eval (o RAGAS usa o Gemini como juiz)
GEMINI_API_KEY=sua_chave python ragas_eval.py
```

## O que ele mede

| Métrica | O que verifica |
|---|---|
| **faithfulness** | A resposta está fundamentada nos contextos? (anti-alucinação) |
| **answer_relevancy** | A resposta responde à pergunta? |
| **context_precision** | Os contextos recuperados são relevantes? |
| **context_recall** | Os contextos cobrem a resposta de referência? |

Os contextos vêm do endpoint `POST /tutor/retrieve` (busca híbrida: dense + lexical + RRF).

## Notas
- ⚠️ A API do RAGAS muda entre versões — pinado na linha `0.2.x`. Ajuste se necessário.
- Amplie `dataset.json` com mais frases-teste para um sinal mais robusto.
