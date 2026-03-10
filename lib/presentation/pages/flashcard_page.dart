import 'dart:math' as math;
import 'package:english_ia/core/widgets/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/flashcard_controller.dart';
import '../../domain/entities/flashcard_entity.dart';

class FlashcardPage extends GetView<FlashcardController> {
  const FlashcardPage({super.key});

  static const _darkBg = Color(0xFF0D0B1F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: _darkBg,
        title: const Text(
          'Flash Cards',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ResponsiveBody(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF1E8AFF)),
                  SizedBox(height: 16),
                  Text(
                    'Generating flashcards...',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            );
          }

          if (controller.activeList.isEmpty) {
            return const Center(
              child: Text(
                'No cards available.',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          final card = controller.activeList[controller.currentIndex.value];
          final isLast =
              controller.currentIndex.value == controller.activeList.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: _buildProgress(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _FlipCard(card: card, controller: controller),
                ),
              ),
              _buildButtons(isLast),
              const SizedBox(height: 16),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildProgress() {
    final total = controller.activeList.length;
    final current = controller.currentIndex.value + 1;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              controller.isShowingRepeatSession.value
                  ? '🔁 Repeat Session'
                  : "Today's Words",
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            Text(
              '$current of $total',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: current / total,
          backgroundColor: Colors.white12,
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E8AFF)),
          minHeight: 4,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildButtons(bool isLast) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: '🔁 Repeat',
                  color: const Color(0xFFFF8C42),
                  onTap: controller.repeat,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ActionButton(
                  label: '✓ Got it!',
                  color: const Color(0xFF22C78E),
                  onTap: controller.gotIt,
                ),
              ),
            ],
          ),
          if (isLast &&
              controller.repeatList.isNotEmpty &&
              !controller.isShowingRepeatSession.value)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _ActionButton(
                label:
                    '📚 Review ${controller.repeatList.length} card(s) again',
                color: const Color(0xFF6B4EFF),
                onTap: controller.startRepeatSession,
              ),
            ),
          if (isLast)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextButton(
                onPressed: controller.restartSession,
                child: const Text(
                  'Restart session',
                  style: TextStyle(color: Colors.white38),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FlipCard extends StatefulWidget {
  final FlashcardEntity card;
  final FlashcardController controller;

  const _FlipCard({required this.card, required this.controller});

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: 0, end: math.pi).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _flip() {
    widget.controller.flipCard();
    if (_animController.isCompleted) {
      _animController.reverse();
    } else {
      _animController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final isFront = _animation.value < math.pi / 2;
          return Transform(
            transform: Matrix4.rotationY(_animation.value),
            alignment: Alignment.center,
            child: isFront
                ? _buildFront()
                : Transform(
                    transform: Matrix4.rotationY(math.pi),
                    alignment: Alignment.center,
                    child: _buildBack(),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildFront() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A7A), Color(0xFF1E8AFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E8AFF).withAlpha(80),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.card.word.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.card.phonetics,
                style: TextStyle(
                  color: Colors.white.withAlpha(180),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Tap to reveal',
                style: TextStyle(
                  color: Colors.white.withAlpha(120),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3A2A), Color(0xFF22C78E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C78E).withAlpha(80),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Translation',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            widget.card.translation,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Example',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            '"${widget.card.exampleSentence}"',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.card.exampleTranslation,
            style: TextStyle(
              color: Colors.white.withAlpha(160),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(80),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
