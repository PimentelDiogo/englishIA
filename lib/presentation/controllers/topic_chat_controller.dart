import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/topic_entity.dart';
import '../../domain/usecases/send_context_message_usecase.dart';

class TopicChatController extends GetxController {
  final SendContextMessageUseCase sendContextMessageUseCase;
  TopicChatController({required this.sendContextMessageUseCase});

  final messages = <MessageEntity>[].obs;
  final textController = TextEditingController();
  final isLoading = false.obs;
  // Use Rx para ter um valor inicial seguro e reativo
  final selectedTopic = Rx<TopicEntity>(TopicData.topics.first);

  void initTopic(TopicEntity topic) {
    selectedTopic.value = topic;
    messages.clear();
    messages.add(
      MessageEntity(
        text:
            "Hello! Let's practice English about \"${topic.title}\" ${topic.emoji}. Start the conversation!",
        isUser: false,
      ),
    );
  }

  Future<void> sendMessage() async {
    final text = textController.text.trim();
    if (text.isEmpty) return;

    messages.add(MessageEntity(text: text, isUser: true));
    textController.clear();
    isLoading.value = true;

    final response = await sendContextMessageUseCase(selectedTopic.value, text);
    messages.add(response);
    isLoading.value = false;
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }
}
