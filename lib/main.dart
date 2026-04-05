import 'package:english_ia/presentation/bindings/chat_binding.dart';
import 'package:english_ia/presentation/bindings/flashcard_binding.dart';
import 'package:english_ia/presentation/bindings/phrasal_verb_binding.dart';
import 'package:english_ia/presentation/bindings/topic_chat_binding.dart';
import 'package:english_ia/presentation/pages/chat_page.dart';
import 'package:english_ia/presentation/pages/context_chat_page.dart';
import 'package:english_ia/presentation/pages/flashcard_page.dart';
import 'package:english_ia/presentation/pages/home_page.dart';
import 'package:english_ia/presentation/pages/phrasal_verb_page.dart';
import 'package:english_ia/presentation/pages/settings_page.dart';
import 'package:english_ia/presentation/pages/topic_selection_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:get_storage/get_storage.dart';
import 'package:english_ia/presentation/services/config_service.dart';
import 'package:english_ia/presentation/services/voice_service.dart';
import 'package:english_ia/presentation/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await Get.putAsync(() => StorageService().init());
  await Get.putAsync(() => ConfigService().init());
  await Get.putAsync(() => VoiceService().init());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'English IA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF)),
        useMaterial3: true,
      ),
      initialRoute: '/home',
      getPages: [
        GetPage(name: '/home', page: () => const HomePage()),
        GetPage(
          name: '/chat',
          page: () => const ChatPage(),
          binding: ChatBinding(),
        ),
        GetPage(
          name: '/topics',
          page: () => const TopicSelectionPage(),
          binding: TopicChatBinding(),
        ),
        GetPage(
          name: '/context-chat',
          page: () => const ContextChatPage(),
          binding: TopicChatBinding(),
        ),
        GetPage(
          name: '/flashcards',
          page: () => const FlashcardPage(),
          binding: FlashcardBinding(),
        ),
        GetPage(
          name: '/phrasal-verbs',
          page: () => const PhrasalVerbPage(),
          binding: PhrasalVerbBinding(),
        ),
        GetPage(name: '/settings', page: () => const SettingsPage()),
      ],
    );
  }
}
