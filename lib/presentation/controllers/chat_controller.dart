import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/usecases/send_message_usecase.dart';

class ChatController extends GetxController {
  final SendMessageUseCase sendMessageUseCase;

  ChatController({required this.sendMessageUseCase});

  final messages = <MessageEntity>[].obs;
  final textController = TextEditingController();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Initial welcome message
    messages.add(
      MessageEntity(
        text:
            "Hello! I'm your English teacher. Let's practice English. What do you want to talk about?",
        isUser: false,
      ),
    );
  }

  Future<void> sendMessage() async {
    final text = textController.text.trim();
    if (text.isEmpty) return;

    // Add user message to UI
    messages.add(MessageEntity(text: text, isUser: true));
    textController.clear();

    // Set loading state
    isLoading.value = true;

    // Call UseCase
    final response = await sendMessageUseCase(text);

    // Add AI response
    messages.add(response);

    isLoading.value = false;
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }
}
