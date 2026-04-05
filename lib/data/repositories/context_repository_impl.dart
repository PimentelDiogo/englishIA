import 'dart:convert';

import '../../domain/entities/flashcard_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/phrasal_verb_entity.dart';
import '../../domain/entities/topic_entity.dart';
import '../datasources/gemini_context_datasource.dart';

abstract class ContextChatRepository {
  Future<MessageEntity> sendContextMessage(TopicEntity topic, String message);
}

abstract class FlashcardRepository {
  Future<List<FlashcardEntity>> getFlashcards(int count);
}

abstract class PhrasalVerbRepository {
  Future<List<PhrasalVerbEntity>> getPhrasalVerbs(int count);
}

class ContextChatRepositoryImpl implements ContextChatRepository {
  final GeminiContextDatasource dataSource;
  ContextChatRepositoryImpl({required this.dataSource});

  @override
  Future<MessageEntity> sendContextMessage(
    TopicEntity topic,
    String message,
  ) async {
    try {
      final jsonStr = await dataSource.sendMessage(topic, message);
      final Map<String, dynamic> data = json.decode(jsonStr);
      
      final dialogueResponse = data['dialogueResponse'] as String? ?? 'No response';
      final grammarFeedback = data['grammarFeedback'] as String?;
      
      return MessageEntity(
        text: dialogueResponse, 
        isUser: false,
        grammarFeedback: (grammarFeedback != null && grammarFeedback.isNotEmpty) 
            ? grammarFeedback 
            : null,
      );
    } catch (e) {
      return MessageEntity(text: 'Error parsing response: ${e.toString()}', isUser: false);
    }
  }
}

class FlashcardRepositoryImpl implements FlashcardRepository {
  final GeminiFlashcardDatasource dataSource;
  FlashcardRepositoryImpl({required this.dataSource});

  @override
  Future<List<FlashcardEntity>> getFlashcards(int count) async {
    try {
      final jsonStr = await dataSource.getFlashcardsJson(count);
      final cleaned = jsonStr
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final List<dynamic> list = json.decode(cleaned);
      return list.map((e) => FlashcardEntity.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }
}

class PhrasalVerbRepositoryImpl implements PhrasalVerbRepository {
  final GeminiPhrasalVerbDatasource dataSource;
  PhrasalVerbRepositoryImpl({required this.dataSource});

  @override
  Future<List<PhrasalVerbEntity>> getPhrasalVerbs(int count) async {
    try {
      final jsonStr = await dataSource.getPhrasalVerbsJson(count);
      final cleaned = jsonStr
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final List<dynamic> list = json.decode(cleaned);
      return list.map((e) => PhrasalVerbEntity.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }
}
