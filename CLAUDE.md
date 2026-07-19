# englishIA — Contexto

> Herda: global → `Projetos/CLAUDE.md` → este arquivo.
> Hub de conhecimento no vault: `Diogo-VAULT/Projetos/englishIA/`.

## Visão geral
App **multiplataforma de aprendizado de inglês assistido por IA** — um "professor de inglês"
com IA que oferece conversação, correção gramatical e memorização de vocabulário.
Módulos (`lib/presentation/pages/home_page.dart`):
- **Dialogues** (`/topics`) — conversação por cenário (viagem, reunião tech, restaurante…).
- **Flash Cards** (`/flashcards`) — vocabulário com repetição espaçada.
- **Phrasal Verbs** (`/phrasal-verbs`) — expressões + exercícios.
- **Free Chat** (`/chat`) — conversa livre com o AI teacher.

## Stack
- **Flutter / Dart** (SDK `^3.10.4`, canal **FVM stable**). Multiplataforma
  (android/ios/macos/linux/windows/web).
- **GetX** (`get`) — state, DI, rotas, storage (`get_storage`).
- **IA:** `google_generative_ai` — **Google Gemini** (modelo `gemini-2.5-flash`).
- **Voz:** `flutter_tts` (TTS, en-US) + `speech_to_text` (STT) + `permission_handler` (microfone).
- **Banco local:** **Isar** (NoSQL) + `path_provider`. Dev: `build_runner` + `isar_generator`.

## Arquitetura (Clean Architecture + GetX)
Monólito, tudo em `lib/`:
- `core/` — `constants/` (API key via env), `widgets/responsive_layout.dart`.
- `data/` — `datasources/` (Gemini), `models/` (Isar `.g.dart`), `repositories/` (impl).
- `domain/` — `entities/`, `repositories/` (contratos), `usecases/`.
- `presentation/` — `pages/`, `controllers/`, `bindings/` (DI por rota), `services/`
  (ConfigService, VoiceService, StorageService).
- **Backend: AI Gateway (Spring Boot)** em `gateway/` (ADR-001). Migração **parcial e em
  andamento**: hoje **só o Free Chat** passa pelo gateway (`TutorGatewayDatasource` → `POST
  /tutor/chat`). Diálogos/flashcards/phrasal verbs ainda chamam o **Gemini direto** (usam saída
  JSON estruturada que o gateway ainda não expõe — migram nas fases seguintes).
- SRS: algoritmo **SM-2** de repetição espaçada em `storage_service.dart:reviewFlashcard`.

## ⚠️ Regras do projeto (do `.agents/skills/sdd_voice_chat/SKILL.md`)
- **Sempre respeitar Clean Architecture:** Presentation → Domain → Data. Não pular camadas.
- **GetX** para state/DI/rotas. Encapsular **TTS/STT em GetxService** — nunca chamar direto no `build()`.
- **API key sempre via `ConfigService`** (`--dart-define=GEMINI_API_KEY` ou `env.json` local) —
  **nunca hardcode**.
- Usar **`fvm flutter`**. Após alterar models Isar, rodar **`build_runner`**.
- **IA usada é o Google Gemini** (não Anthropic) — considerar isso ao mexer nas datasources.

## Chamadas de IA (onde estão)
- `data/datasources/tutor_gateway_datasource.dart` — **chat livre via AI Gateway** (HTTP `POST
  /tutor/chat`). Chave **não fica mais no cliente** nesse fluxo. **Multi-turn:** o app envia o
  `history` da conversa em cada request (gateway stateless). (O antigo `gemini_datasource.dart`,
  chat via SDK, foi **removido** ao migrar para o gateway.)
- `data/datasources/gemini_context_datasource.dart` — diálogos por tópico (**saída JSON
  estruturada** `{dialogueResponse, grammarFeedback}`), flashcards e phrasal verbs. **Ainda
  direto no Gemini.**

## AI Gateway (`gateway/`, Spring Boot 4 + Java 21)
- Objetivo: tirar IA do cliente e habilitar guardrails/RAG/router/cache/fallback (ver ADRs).
- Endpoint `POST /tutor/chat` → aceita `{message, history[]}` (multi-turn, stateless), repassa ao
  Gemini server-side; retorna `reply` + `usage` (tokens/custo/latência). Observabilidade via
  Actuator/Micrometer (`LlmMetrics`).
- Erros **honestos**: `GlobalExceptionHandler` → 502 `tutor_unavailable` (nunca stacktrace).
- **Guardrails (ADR-005):** pipeline `GuardrailChain` no `TutorService` (in/out). Input: Length +
  PromptInjection regex (Java, zero token) + `LlmInputGuardrail` (injection **e** off-scope numa
  chamada `flash-lite`, fail-open). Output: `LlmModerationOutputGuardrail` (`flash-lite`). **Sem
  SaaS** — reusa o Gemini (Lakera foi descartado por falta de conta). Resposta traz `blocked`/`reason`;
  métrica `llm.guardrail.blocked`. Desligável via `GUARDRAIL_LLM_CHECKS=false`.
- Chave via env: `GEMINI_API_KEY=... ./mvnw spring-boot:run`. Preços de token no
  `application.properties` são **estimativa** (confirmar na pricing do Google).
- App aponta via `Constants.gatewayUrl` / `ConfigService.gatewayUrl` (`--dart-define=GATEWAY_URL`
  ou Settings). **Emulador Android:** usar `http://10.0.2.2:8080`.
- **RAG (Fase 3 / ADR-003):** Postgres + pgvector (`docker-compose.yml`). Pacote `rag/`:
  `GeminiEmbeddingClient` (text-embedding-004, 768d) · `KnowledgeRepository` (JdbcClient, busca
  dense `<=>`) · `RagService` (retrieve + bloco de contexto) · `KnowledgeSeeder` (gramática +
  phrasal, idempotente, boot). `TutorService` injeta o contexto no prompt e checa grounding
  (`GroundingChecker`, anti-alucinação). **Fail-soft:** DB fora → tutor segue sem grounding.
  **Busca híbrida:** dense (`<=>`) + lexical (full-text `content_tsv`) fundidas por RRF em
  `RagService` (`RAG_HYBRID`, fail-soft p/ só-dense). Endpoint `POST /tutor/retrieve` expõe os chunks.
  **Eval RAGAS** offline em `gateway/eval/` (dataset + `ragas_eval.py`). Rodar: `docker compose up -d`
  + `GEMINI_API_KEY=...`. **Stack Docker completo:** db (pgvector) + gateway + Prometheus + Grafana
  (`docker compose up -d --build`; Grafana :3000 dashboard "englishIA — LLM" p/ auditoria de token).
- **Router + cache (Fase 4 / ADR-004):** `ModelRouter` (rule-based) roteia por complexidade —
  tem contexto de gramática → modelo forte; casual → barato (`router.cheap-model`=flash-lite).
  `SemanticCache` (pgvector) responde perguntas quase idênticas do cache (`cached:true`, 0 token do
  forte), só sem histórico. Métricas `llm.route`/`llm.cache`. Liga/desliga via `ROUTER_ENABLED`/`CACHE_ENABLED`.
- **Fallback (Fase 5 / ADR-002):** abstração `LlmProvider` (`GeminiClient` primário, `ClaudeClient`
  fallback via Anthropic Messages API). `ResilientLlmService` = resilience4j (circuit breaker + retry)
  no Gemini → cai pro Claude. **Sem SaaS** por padrão (`FALLBACK_ENABLED=false`; modelo `claude-opus-4-8`,
  key via `ANTHROPIC_API_KEY`). Métrica `llm.fallback`. Se ambos falham → 502 honesto.

## UI / Responsividade
Flutter **Material 3**, tema dark (seed `#6C63FF`). Sem framework CSS (é Flutter nativo).
Responsividade própria em `core/widgets/responsive_layout.dart` (`AppBreakpoints` tablet 768/
desktop 1024, `ResponsiveBody`, `ResponsiveGrid`).

## Reaproveitamento
Reuso interno: `ResponsiveBody`/`ResponsiveGrid`, Bindings GetX por feature. **Sem design
system formalizado** — cores/gradientes (`_darkBg #0D0B1F`) duplicados inline entre páginas.
➡️ **Antes de mexer em qualquer UI, ler `.agents/skills/design_system/SKILL.md`** — ele define
o padrão único de cores/espaçamento/tipografia e as regras de responsividade (proíbe `Color(0xFF)`
inline e breakpoint mágico). Ao criar tela/componente, checar `responsive_layout.dart` e reusar.

## Como rodar
```bash
fvm flutter pub get
dart run build_runner build     # models Isar
fvm flutter run --dart-define=GEMINI_API_KEY=SUA_CHAVE
```
Alternativa: inserir a chave em runtime na tela **Settings** (salva local em GetStorage).
Sem README útil/Makefile/docker (README é template padrão do Flutter).

## Testes
**Nenhum teste** ainda (sem pasta `test/`). `flutter_test` está nas deps. ⚠️ Oportunidade de
padronizar — o SKILL.md prevê mockar `VoiceServiceInterface`. Propor testes ao implementar.

## Segurança
- **Nenhuma chave hardcoded** (só placeholder `'apiKeyAQUI'` em `constants.dart:6`).
- `.gitignore` cobre `env.json`/`.env`. Obs: GetStorage não é criptografado (chave fica em
  plaintext no dispositivo) — aceitável (é local, não commitada).

## Docs
- `ROADMAP.md` — features de usuário (planejamento real). `metrica.md` (no vault) — plano de
  maturidade de IA (gateway/guardrails/RAG/custo/fallback) usado como laboratório de entrevista.
- `ADR/` — decisões: `ADR-001` gateway · `ADR-002` fallback · `ADR-003` pgvector · `ADR-004`
  model router · `ADR-005` guardrails. `PRD/PRD-ai-tutor.md` — SLOs do tutor. (espelhados no vault
  `Projetos/englishIA/`).
- `.agents/skills/design_system/SKILL.md` — padrão de design/responsividade (ler antes de UI).
- `.agents/skills/sdd_voice_chat/SKILL.md` — design de voz, feedback gramatical via JSON,
  SRS/Isar/SM-2, guia p/ agentes. README não tem conteúdo real.

## Status do plano (metrica.md)
✅ Fase 0 (PRD + 5 ADRs) · ✅ Fase 1 (gateway + multi-turn + erros honestos) ·
✅ Fase 2 (guardrails in/out) · ✅ Fase 3 (RAG pgvector + grounding; falta híbrido/RAGAS/MCP) ·
✅ Fase 4 (model router + cache semântico) · ✅ Fase 5 (fallback Gemini→Claude + circuit breaker).
**🎉 Plano do `metrica.md` completo (Fases 0–5).** Pendências pontuais anotadas nos ADRs.
