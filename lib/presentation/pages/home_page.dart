import 'package:english_ia/core/widgets/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _darkBg = Color(0xFF0D0B1F);
  static const _cardColors = [
    [Color(0xFF6B4EFF), Color(0xFF9B7FFF)],
    [Color(0xFF1E8AFF), Color(0xFF56C1FF)],
    [Color(0xFF22C78E), Color(0xFF58E0B5)],
    [Color(0xFFFF6B6B), Color(0xFFFFAA6B)],
  ];

  static const _features = [
    {
      'title': 'Dialogues',
      'subtitle': 'Conversation scenarios',
      'icon': Icons.chat_bubble_rounded,
      'route': '/topics',
    },
    {
      'title': 'Flash Cards',
      'subtitle': 'Vocabulary & review',
      'icon': Icons.style_rounded,
      'route': '/flashcards',
    },
    {
      'title': 'Phrasal Verbs',
      'subtitle': 'Idioms & usage',
      'icon': Icons.extension_rounded,
      'route': '/phrasal-verbs',
    },
    {
      'title': 'Free Chat',
      'subtitle': 'Talk with AI teacher',
      'icon': Icons.record_voice_over_rounded,
      'route': '/chat',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      body: ResponsiveBody(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildSectionTitle('Practice Modules'),
                const SizedBox(height: 16),
                _buildFeatureGrid(),
                const SizedBox(height: 32),
                _buildQuickPracticeButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF6B4EFF), Color(0xFF9B7FFF)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B4EFF).withAlpha(100),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, Learner! 👋',
              style: TextStyle(
                color: Colors.white.withAlpha(200),
                fontSize: 15,
              ),
            ),
            const Text(
              'English IA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white.withAlpha(180),
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildFeatureGrid() {
    return ResponsiveGrid(
      mobileColumns: 2,
      tabletColumns: 2,
      desktopColumns: 4,
      childAspectRatio: 1.1,
      itemCount: _features.length,
      itemBuilder: (context, index) {
        final f = _features[index];
        return _FeatureCard(
          title: f['title'] as String,
          subtitle: f['subtitle'] as String,
          icon: f['icon'] as IconData,
          route: f['route'] as String,
          gradientColors: _cardColors[index],
        );
      },
    );
  }

  Widget _buildQuickPracticeButton() {
    return GestureDetector(
      onTap: () => Get.toNamed('/chat'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(30), width: 1),
          color: Colors.white.withAlpha(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6B4EFF).withAlpha(50),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mic_rounded,
                color: Color(0xFF9B7FFF),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Practice',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Tap to chat with your AI English teacher',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white38,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final List<Color> gradientColors;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.gradientColors,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.05,
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        Get.toNamed(widget.route);
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: widget.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.gradientColors[0].withAlpha(100),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 28),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
