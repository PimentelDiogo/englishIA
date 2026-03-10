# Funcionalidades e Roadmap - English IA

Este documento contém o planejamento das próximas funcionalidades a serem desenvolvidas no projeto English IA, um aplicativo feito em Flutter (Clean Architecture + GetX) integrado à API do Gemini.

## 🗂️ 1. Histórico de Conversas
**Objetivo:** Permitir que o usuário recupere e estude conversas e aulas passadas.
- [ ] Implementar armazenamento das mensagens localmente.
- [ ] Decidir a tecnologia de banco local (SQLite, Hive ou SharedPreferences).
- [ ] Criar repositório e UseCases para salvar, listar e carregar o histórico.
- [ ] Construir a tela de histórico no GetX e criar navegação para ela.

## 🗣️ 2. Text-to-Speech (TTS)
**Objetivo:** Fazer a IA "falar" as mensagens de resposta em inglês com a pronúncia correta, e adicionar o recurso de ouvir o texto.
- [ ] Adicionar um pacote TTS, como `flutter_tts`.
- [ ] Adicionar a funcionalidade respeitando a Clean Architecture (Domain e Data).
- [ ] Colocar um botão de "Ouvir" nas mensagens da IA no chat.
- [ ] Ajustar o idioma do TTS para o inglês.

## 🎙️ 3. Speech-to-Text (Reconhecimento de Voz)
**Objetivo:** Permitir que o usuário converse por voz com a IA ao invés de apenas digitar.
- [ ] Integrar pacote `speech_to_text`.
- [ ] Solicitar permissão de uso do microfone no Android/iOS.
- [ ] Adicionar um botão de gravação na área de input do chat.
- [ ] Tratar os retornos do reconhecimento e enviar como texto para a API do Gemini.

## 📝 4. Análise de Gramática Independente
**Objetivo:** Um botão específico ou nova tela para o usuário enviar frases em inglês e receber a correção de maneira isolada.
- [ ] Criar nova rota GetX, Controller e Page para essa funcionalidade.
- [ ] Criar um UseCase focado e um novo método no repositório.
- [ ] Ajustar as instruções do Gemini (*System Instruction*) especificamente para agir como um corretor gramatical rigoroso ao invés de um parceiro de bate-papo.
- [ ] Desenvolver a UI para destacar as correções e explicações em blocos fáceis de ler.
