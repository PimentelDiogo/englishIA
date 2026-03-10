import 'package:english_ia/core/widgets/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/topic_entity.dart';
import '../controllers/topic_chat_controller.dart';

class TopicSelectionPage extends StatelessWidget {
  const TopicSelectionPage({super.key});

  static const _darkBg = Color(0xFF0D0B1F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: _darkBg,
        title: const Text(
          'Choose a Topic',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ResponsiveBody(
        child: ResponsiveGrid(
          mobileColumns: 2,
          tabletColumns: 3,
          desktopColumns: 4,
          childAspectRatio: 0.9,
          itemCount: TopicData.topics.length,
          itemBuilder: (context, index) {
            final topic = TopicData.topics[index];
            return _TopicCard(topic: topic);
          },
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final TopicEntity topic;
  const _TopicCard({required this.topic});

  static const _gradients = [
    [Color(0xFF1E3A5F), Color(0xFF2980B9)],
    [Color(0xFF1A472A), Color(0xFF27AE60)],
    [Color(0xFF4A235A), Color(0xFF8E44AD)],
    [Color(0xFF7B241C), Color(0xFFE74C3C)],
    [Color(0xFF7D6608), Color(0xFFF39C12)],
    [Color(0xFF1A5276), Color(0xFF2196F3)],
    [Color(0xFF1C3A2A), Color(0xFF00BCA4)],
  ];

  @override
  Widget build(BuildContext context) {
    final idx = TopicData.topics.indexOf(topic) % _gradients.length;
    return GestureDetector(
      onTap: () {
        final controller = Get.find<TopicChatController>();
        controller.initTopic(topic);
        Get.toNamed('/context-chat');
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: _gradients[idx].map((c) => c).toList(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _gradients[idx][1].withAlpha(80),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(topic.emoji, style: const TextStyle(fontSize: 40)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  topic.description,
                  style: TextStyle(
                    color: Colors.white.withAlpha(180),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
