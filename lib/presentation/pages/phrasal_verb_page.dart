import 'package:english_ia/core/widgets/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/phrasal_verb_controller.dart';
import '../../domain/entities/phrasal_verb_entity.dart';

class PhrasalVerbPage extends GetView<PhrasalVerbController> {
  const PhrasalVerbPage({super.key});

  static const _darkBg = Color(0xFF0D0B1F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: _darkBg,
        title: const Text(
          'Phrasal Verbs',
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
                  CircularProgressIndicator(color: Color(0xFF22C78E)),
                  SizedBox(height: 16),
                  Text(
                    'Loading phrasal verbs...',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.phrasalVerbs.length,
            itemBuilder: (context, index) {
              return Obx(() {
                final isExpanded = controller.selectedIndex.value == index;
                return _PhrasalVerbCard(
                  verb: controller.phrasalVerbs[index],
                  isExpanded: isExpanded,
                  exerciseResult: isExpanded
                      ? controller.exerciseResult.value
                      : null,
                  onTap: () => controller.selectVerb(index),
                  onCheckAnswer: controller.checkAnswer,
                );
              });
            },
          );
        }),
      ),
    );
  }
}

class _PhrasalVerbCard extends StatelessWidget {
  final PhrasalVerbEntity verb;
  final bool isExpanded;
  final bool? exerciseResult;
  final VoidCallback onTap;
  final Function(String) onCheckAnswer;

  const _PhrasalVerbCard({
    required this.verb,
    required this.isExpanded,
    required this.exerciseResult,
    required this.onTap,
    required this.onCheckAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isExpanded ? const Color(0xFF1A1640) : const Color(0xFF12102A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isExpanded ? const Color(0xFF6B4EFF) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: const Color(0xFF6B4EFF).withAlpha(50),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.transparent,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B4EFF).withAlpha(50),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      verb.verb,
                      style: const TextStyle(
                        color: Color(0xFF9B7FFF),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      verb.meaning,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: Colors.white38,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(color: Colors.white12, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Examples',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...verb.examples.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(
                              color: Color(0xFF9B7FFF),
                              fontSize: 16,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              e,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildExercise(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExercise() {
    final TextEditingController answerController = TextEditingController();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📝  Practice',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            verb.exerciseSentence,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: answerController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Your answer...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withAlpha(15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => onCheckAnswer(answerController.text),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C78E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          if (exerciseResult != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Icon(
                    exerciseResult!
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: exerciseResult!
                        ? const Color(0xFF22C78E)
                        : const Color(0xFFFF6B6B),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    exerciseResult!
                        ? 'Correct! Great job! 🎉'
                        : 'Answer: "${verb.exerciseAnswer}"',
                    style: TextStyle(
                      color: exerciseResult!
                          ? const Color(0xFF22C78E)
                          : const Color(0xFFFF6B6B),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
