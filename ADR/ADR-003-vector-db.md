---
tags: [adr, arquitetura, englishIA, rag, vector-db]
criado: 2026-07-19
atualizado: 2026-07-19
status: aceito (implementado na Fase 3)
decisao: "pgvector (Postgres) como vector DB do RAG — em vez de Qdrant"
relaciona: [ADR-001-ai-gateway, PRD-ai-tutor]
---

# ADR-003 — Vector DB do RAG: pgvector vs Qdrant

> **Status:** proposto · **Data:** 2026-07-19 · **Decisor:** Diogo
> **Depende de:** [[ADR-001-ai-gateway]] · **Habilita:** RAG (Fase 3 do [[PRD-ai-tutor]])

## Contexto

O RAG do tutor precisa de uma base vetorial para: regras gramaticais, banco de phrasal
verbs/idioms e histórico/erros do próprio aluno (personalização + SRS). Não existe nada disso
hoje (o `pubspec.yaml` não tem embeddings/vector DB). Precisamos escolher **onde** guardar e
buscar os embeddings.

A busca alvo é **híbrida** (dense + BM25), com rerank só no top-k (ver PRD/`metrica.md`).

## Decisão

Usar **pgvector** (extensão do **PostgreSQL**) como vector DB, **não** Qdrant — para o
escopo de laboratório e além.

```mermaid
graph LR
    subgraph GW["AI Gateway (Spring Boot)"]
        RAG["RAG service<br/>Spring Data JPA"]
    end
    RAG -->|dense (cosine)| PG[("Postgres + pgvector")]
    RAG -->|BM25 / full-text| PG
    PG -->|híbrido: 1 banco só| RAG
```

### Por que pgvector
1. **Uma infra só:** Postgres já resolve dados relacionais **e** vetores — sem serviço extra pra subir/manter (chave num lab).
2. **Busca híbrida no mesmo banco:** full-text search nativo do Postgres (BM25-like) + `<=>` de similaridade vetorial numa query — combina dense+sparse sem juntar dois sistemas.
3. **Spring-friendly:** Spring Data JPA + driver JDBC padrão; menos código de integração.
4. **Custo/simplicidade:** roda em 1 container; suficiente para a escala de estudo e MVP.

## Consequências

**Positivas**
- Menos peças móveis; um `docker-compose` com Postgres resolve app + RAG.
- Transação única entre metadados do aluno e vetores (consistência fácil).
- Migração de dados/backup trivial (é Postgres).

**Negativas / custos**
- Em **escala muito alta** (milhões de vetores, filtragem pesada), Qdrant/bases dedicadas performam melhor (HNSW ajustável, quantização). Não é o caso do lab.
- Rerank e HNSW tuning são mais manuais que num vector DB dedicado.
- Se um dia a escala exigir, migrar para Qdrant é um novo ADR (contrato do `RAG service` isola isso).

## Alternativas consideradas

| Alternativa | Prós | Por que não agora |
|---|---|---|
| **Qdrant** | HNSW rápido, filtros ricos, feito p/ vetor | Mais um serviço; ganho só aparece em escala que o lab não tem. |
| Pinecone / Weaviate (SaaS) | Zero ops | Custo recorrente, vendor lock-in, foge do "roda local". |
| FAISS em memória | Simples | Sem persistência/transação; ruim para histórico do aluno. |

## Escopo desta fase (Fase 3)
- Postgres + extensão `pgvector` no compose.
- Ingestão: chunking → embeddings baratos → índice.
- Busca híbrida (dense + full-text) com top-k rígido; rerank só no top-k.
- Medir com RAGAS (Context Relevance, Faithfulness, Answer Relevance) contra o eval dataset.

## Implementação (Fase 3)
- Infra: `gateway/docker-compose.yml` (`pgvector/pgvector:pg16`).
- Acesso: **Spring JDBC** (`JdbcClient`) — embedding como literal `[...]` com `CAST(... AS vector)`,
  busca dense por `<=>` (cosseno). Sem Hibernate (evita complexidade do tipo `vector`).
- Embeddings: `text-embedding-004` (Gemini, 768 dims) — sem SaaS/conta nova.
- Base semeada no boot (`KnowledgeSeeder`, idempotente): regras de gramática + phrasal verbs.
- Grounding: contexto recuperado injetado no prompt + `GroundingChecker` (anti-alucinação).
- **Fail-soft:** DB fora → RAG retorna vazio, tutor segue sem grounding (não derruba).
- **Pendente:** busca híbrida (BM25) + rerank; RAGAS offline; histórico do aluno via MCP.

## Narrativa de entrevista
"Escolhi pgvector em vez de Qdrant conscientemente: no meu estágio, uma infra só (Postgres
guardando vetor e relacional) vale mais que o ganho de performance de um vector DB dedicado que
só aparece em escala. Isolei atrás de um RAG service, então trocar por Qdrant depois é um ADR,
não um retrabalho."
