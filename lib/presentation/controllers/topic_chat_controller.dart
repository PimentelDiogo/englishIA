import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/topic_entity.dart';
import '../../domain/usecases/send_context_message_usecase.dart';
import '../services/voice_service.dart';

class TopicChatController extends GetxController {
  final SendContextMessageUseCase sendContextMessageUseCase;
  TopicChatController({required this.sendContextMessageUseCase});

  final messages = <MessageEntity>[].obs;
  final textController = TextEditingController();
  final isLoading = false.obs;
  
  // Use Rx para ter um valor inicial seguro e reativo
  final selectedTopic = Rx<TopicEntity>(TopicData.topics.first);
  
  late final VoiceService voiceService;

  @override
  void onInit() {
    super.onInit();
    voiceService = Get.find<VoiceService>();
    ever(voiceService.recognizedText, (String text) {
      if (text.isNotEmpty) {
        textController.text = text;
      }
    });
  }

  void initTopic(TopicEntity topic) {
    selectedTopic.value = topic;
    messages.clear();
    final welcomeMsg = "Hello! Let's practice English about \"${topic.title}\" ${topic.emoji}. Start the conversation!";
    messages.add(
      MessageEntity(
        text: welcomeMsg,
        isUser: false,
      ),
    );
    voiceService.speak(welcomeMsg); // Auto-play welcome message
  }

  Future<void> sendMessage() async {
    // Se estiver ouvindo, pare.
    if (voiceService.isListening.value) {
      await voiceService.stopListening();
    }
    
    final text = textController.text.trim();
    if (text.isEmpty) return;

    messages.add(MessageEntity(text: text, isUser: true));
    textController.clear();
    isLoading.value = true;

    final response = await sendContextMessageUseCase(selectedTopic.value, text);
    messages.add(response);
    isLoading.value = false;
    
    // Auto-play the AI response
    voiceService.speak(response.text);
  }

  void playMessage(String text) {
    voiceService.speak(text);
  }

  Future<void> toggleVoiceRecording() async {
    if (voiceService.isListening.value) {
      await voiceService.stopListening();
      // Auto-send when stopping mic if there's text
      if (textController.text.trim().isNotEmpty) {
        sendMessage();
      }
    } else {
      textController.clear();
      await voiceService.toggleListening();
    }
  }

  @override
  void onClose() {
    voiceService.stopSpeaking();
    if (voiceService.isListening.value) voiceService.stopListening();
    textController.dispose();
    super.onClose();
  }
}
