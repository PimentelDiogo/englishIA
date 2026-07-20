---
tags: [adr, arquitetura, englishIA, mcp, personalizacao, rag]
criado: 2026-07-19
atualizado: 2026-07-19
status: aceito (parcial — store+sync+personalização feitos; transporte MCP pendente)
decisao: "Expor o histórico/SRS do aluno via um MCP server (acesso governado por ferramentas), consumido pelo gateway para personalizar o tutor"
relaciona: [ADR-001-ai-gateway, ADR-003-vector-db, ADR-005-guardrails, PRD-ai-tutor]
---

# ADR-006 — Histórico do aluno via MCP (personalização governada)

> **Status:** proposto · **Data:** 2026-07-19 · **Decisor:** Diogo
> **Depende de:** [[ADR-001-ai-gateway]] · **Complementa:** [[ADR-003-vector-db]] (grounding) e
> [[ADR-005-guardrails]] (governança)

## Contexto

O tutor hoje é **impessoal**: não sabe o que *este* aluno já domina ou onde erra. O englishIA já
tem esse sinal — o **SRS (SM-2)** guardado no **Isar** (`FlashcardModel`: `word`, `translation`,
`interval`, `easeFactor`, `nextReviewDate`; `StorageService.getDueFlashcards()`,
`reviewFlashcard(id, quality)`). Mas:

1. Esse dado é **local no dispositivo** (Isar) — o gateway (server-side) não o alcança.
2. Dar ao gateway **acesso livre ao banco do aluno** é um anti-padrão de governança (dado que pode
   ser de menor — matriz de risco do [[PRD-ai-tutor]]): sem limite, sem auditoria, sem menor privilégio.

O `metrica.md` aponta a solução: **expor o histórico via um MCP server** (`get_student_vocabulary`
em vez de SQL livre) — e é o gancho perfeito ("você já viu MCP na prática nesta config do Claude Code").

## Decisão

Um **MCP server** dedicado expõe o histórico/SRS do aluno por **ferramentas read-only governadas**;
o **gateway é o cliente MCP** e injeta a personalização no prompt (ao lado do grounding do RAG).

```mermaid
graph TD
    APP["englishIA (Flutter)<br/>SRS no Isar (SM-2)"] -->|sync updates| STORE[("student store<br/>(Postgres — reusa o DB)")]
    subgraph GW["AI Gateway"]
        TUT["TutorService"]
    end
    MCP["MCP server (novo)<br/>tools read-only"]
    TUT -->|MCP client: get_weak_vocabulary(user_id)| MCP
    MCP -->|acesso governado| STORE
    TUT --> PROMPT["prompt = system + RAG + PERSONALIZAÇÃO"]
    style MCP fill:#1e3a2f,color:#fff
```

### Ferramentas MCP (read-only, menor privilégio)
| Tool | Retorna | Sinal SM-2 |
|---|---|---|
| `get_weak_vocabulary(user_id, limit)` | Palavras que o aluno erra | `easeFactor` baixo / falhas recentes |
| `get_due_vocabulary(user_id)` | O que está para revisar | `nextReviewDate` vencido |
| `get_recent_errors(user_id, limit)` | Erros gramaticais recentes | log de correções |

### Fluxo
Antes de gerar, o `TutorService` chama a tool MCP → recebe o vocabulário fraco/vencido → injeta um
bloco de **personalização** no prompt: *"O aluno está com dificuldade em: [make vs do, present
perfect]. Prefira exemplos usando esses itens e reforce-os."* (junto do grounding do RAG).

### Onde os dados vivem
O Isar é **local** — para o server usar, o app **sincroniza** as atualizações de SRS para um
`student_vocabulary` no **mesmo Postgres** (reusa a infra do ADR-003). O MCP server lê desse store.

> 🔌 **Qual MCP:** é um **MCP server que nós construímos** (não um conector pronto como Figma/Gmail).
> Linguagem a decidir na implementação (Node/Python são comuns p/ MCP; ou Java via lib MCP). O
> gateway atua como **MCP client**.

## Consequências

**Positivas**
- Personalização real (o tutor foca no que o aluno erra) — puxa a precisão percebida.
- **Governança:** o MCP é a fronteira única, auditável e de menor privilégio ao dado do aluno —
  sem SQL livre, à prova de injeção, reutilizável por outros agentes/clientes.
- Demonstra **MCP na prática** — diferencial forte de entrevista.

**Negativas / custos**
- **Sincronização device→server** do SRS (novo mecanismo) — hoje o Isar é offline-first.
- 1 hop/protocolo a mais vs. uma query direta; mitigável com cache curto por `user_id`.
- Precisa de **identidade de aluno** (`user_id`) — hoje o app é single-user sem auth.

## Alternativas consideradas

| Alternativa | Por que não |
|---|---|
| Gateway consulta o Postgres direto | Sem governança/auditoria; acopla o gateway ao schema do aluno; anti-padrão do `metrica.md`. |
| App envia o histórico no request | Não é reutilizável, confia no cliente, e não exercita MCP (o ponto da vaga). |
| Manter impessoal | Perde a personalização — o maior ganho de qualidade percebida do tutor. |

## Escopo sugerido (quando implementar)
1. Tabela `student_vocabulary` no Postgres + endpoint de sync no gateway (app envia SRS).
2. MCP server com as 3 tools read-only.
3. Gateway como MCP client → injeta bloco de personalização no `TutorService` (antes do LLM).
4. `user_id` mínimo (id de dispositivo) até ter auth.

> Fora de escopo agora: auth robusta/multiusuário; escrita via MCP (mantém read-only).

## Implementação (parcial — feito)
- **Store** `student_vocabulary` no Postgres (`StudentRepository`, upsert por `user_id`+`word`;
  `weak` por `ease_factor`, `due` por `next_review_date`). DDL validado contra Postgres real.
- **Fronteira governada** `StudentHistoryService` — as "tools" read-only (`getWeakVocabulary`,
  `getDueVocabulary`) + `personalizationBlock`. Fail-soft. **É aqui que o MCP client entra depois,
  sem tocar o `TutorService`.**
- **Sync** `POST /student/{userId}/vocabulary` (app envia o SRS do Isar; SM-2 como epoch millis).
  Debug: `GET /student/{userId}/weak` e `/due` (espelham as tools).
- **Personalização** injetada no prompt do `TutorService` (junto do grounding), gated por
  `PERSONALIZATION_ENABLED` + `ChatRequest.userId`.

## Pendente (o transporte MCP e o cliente Flutter)
- Trocar o `StudentRepository` in-process por um **MCP client** dentro do `StudentHistoryService`
  (o transporte MCP real; TutorService não muda).
- **MCP server** propriamente dito (Node/Python/Java) expondo as 3 tools sobre o store.
- **Sync no app Flutter**: chamar `POST /student/{id}/vocabulary` ao revisar flashcards.
- `user_id` real (hoje é um id livre; falta auth/identidade).

## Narrativa de entrevista
"Em vez de dar ao gateway acesso livre ao banco do aluno, expus o histórico de SRS por um **MCP
server** com ferramentas read-only — `get_weak_vocabulary(user_id)`. O tutor puxa o que o aluno
erra e personaliza os exemplos, e o acesso ao dado sensível fica numa fronteira única, auditável e
de menor privilégio. É MCP resolvendo governança de dados, não só 'mais uma API'."
