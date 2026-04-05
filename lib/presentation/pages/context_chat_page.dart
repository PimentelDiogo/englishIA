import 'package:english_ia/core/widgets/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/topic_chat_controller.dart';
import '../../domain/entities/message_entity.dart';

class ContextChatPage extends GetView<TopicChatController> {
  const ContextChatPage({super.key});

  static const _darkBg = Color(0xFF0D0B1F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: _darkBg,
        title: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.selectedTopic.value.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                controller.selectedTopic.value.emoji,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ResponsiveBody(
        child: Column(
          children: [
            Expanded(
              child: Obx(
                () => ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.messages.length,
                  itemBuilder: (context, i) =>
                      _MessageBubble(msg: controller.messages[i]),
                ),
              ),
            ),
            Obx(
              () => controller.isLoading.value
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(
                        color: Color(0xFF6B4EFF),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF12102A),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller.textController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: Colors.white.withAlpha(100)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white.withAlpha(20),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                onSubmitted: (_) => controller.sendMessage(),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller.textController,
              builder: (context, value, child) {
                final isTyping = value.text.trim().isNotEmpty;
                return Obx(() {
                  final isListening = controller.voiceService.isListening.value;
                  return CircleAvatar(
                    backgroundColor: isListening ? Colors.redAccent : const Color(0xFF6B4EFF),
                    radius: 24,
                    child: IconButton(
                      icon: Icon(
                        isTyping 
                            ? Icons.send_rounded 
                            : (isListening ? Icons.mic_off : Icons.mic),
                        color: Colors.white,
                      ),
                      onPressed: isTyping 
                          ? controller.sendMessage 
                          : controller.toggleVoiceRecording,
                    ),
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageEntity msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          gradient: msg.isUser
              ? const LinearGradient(
                  colors: [Color(0xFF6B4EFF), Color(0xFF9B7FFF)],
                )
              : null,
          color: msg.isUser ? null : const Color(0xFF1A1835),
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: msg.isUser ? const Radius.circular(4) : null,
            bottomLeft: msg.isUser ? null : const Radius.circular(4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            if (!msg.isUser) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => Get.find<TopicChatController>().playMessage(msg.text),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.volume_up_rounded,
                      color: Colors.white.withAlpha(200),
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Listen',
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (msg.grammarFeedback != null) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    Get.bottomSheet(
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E1C38),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '💡 Grammar Tip',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              msg.grammarFeedback!,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6B4EFF),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => Get.back(),
                                child: const Text('Got it!'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withAlpha(80)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'Grammar Tip',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
