---
name: "Voice and SRS Implementation Context (SDD)"
description: "Context and architecture for implementing Voice (STT/TTS) and SRS in English IA"
---

# Software Design Document: Voice Dialogues & SRS Evolution

This skill document defines the architectural context and implementation strategy for evolving the `english_ia` application into a fully-fledged conversational simulator. Agents stepping into this project must read and follow this context to maintain architectural consistency.

## 1. Project Context
`english_ia` is a Flutter application using **Clean Architecture** and **GetX** for state management. It connects to the **Gemini API** to simulate English dialogues based on contexts (vacation, tech meeting, etc.).

The goal of this phase is to move from text-based chat to voice-based conversation, separate the grammar correction from the roleplay, and implement a Spaced Repetition System (SRS) for flashcards and history.

## 2. Voice Services Architecture
The application must sound and listen like a human.

### Dependencies
- **Speech-to-Text**: Use the `speech_to_text` package.
- **Text-to-Speech**: Use the `flutter_tts` package.
- **Permissions**: Use `permission_handler` for `Permission.microphone`.

### Clean Arch Boundary
Do not call `flutter_tts` directly in controllers or usecases.
1. Create a `VoiceServiceInterface` in the `domain/repositories` (or a services interface folder).
2. Implement it as `VoiceServiceImpl` extending `GetxService` in the presentation/data layer.
3. This allows mocking the voice interface during tests.

### UI Experience
- **Context Chat Page**: Must feature a prominent circular microphone button at the bottom.
- When listening, show a visual indicator (e.g., pulsing animation).
- Auto-send the transcribed message once the user stops speaking.
- **Auto-Play**: The TTS should automatically read Gemini's responses when they arrive.

## 3. Grammar Feedback Separation
Currently, Gemini roleplays and corrects the user in a single text block. This breaks immersion.

### Strategy
Modify the `systemInstruction` in `TopicEntity` and `GeminiContextDatasource` to instruct Gemini to always return a **JSON object**:
```json
{
  "dialogueResponse": "I'll get your boarding pass right away.",
  "grammarFeedback": "You said 'I go to airport'. It should be 'I went to the airport' or 'I am going to the airport' depending on the tense."
}
```
**Action Items for Dev:** 
- In `GeminiContextDatasource`, set `responseMimeType: 'application/json'`.
- Parse the resulting JSON into a DTO before sending it to the `domain`.
- The Chat UI should render `dialogueResponse` as a normal bubble. If `grammarFeedback` is not null or empty, display a "Grammar Tip 💡" button below the bubble.

## 4. Local Memory (SRS & History)
To implement long-term learning.

### Approach
- **Database**: Use `Isar` (or `Hive` if Isar is incompatible with current constraints). Isar is preferred for query performance since we need to query cards by `nextReviewDate`.
- **Entities**: Add `nextReviewDate` (DateTime), `interval` (int), and `easeFactor` (double) to `FlashcardEntity` to implement standard SM-2 (SuperMemo) algorithm.
- **Save Strategy**: After every chat session, prompt the user to "Save to History". Save the List<MessageEntity> locally.

## Instructions for Agents
When working on features related to Voice, SRS, or JSON Prompts for this app:
1. Always maintain Clean Architecture: `Presentation (GetX)` -> `Domain (UseCases & Entities)` -> `Data (Datasources & Repositories)`.
2. Do not mix UI logic (like initializing `flutter_tts` instances) directly inside `build()` methods; encapsulate it in a `GetxService` or `GetxController`.
3. Handle API Key securely via `ConfigService` (already implemented via `--dart-define` and local `env.json`).

*Context saved on: 2026-04-05*
