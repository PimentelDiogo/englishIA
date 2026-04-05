import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService extends GetxService {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();

  final isListening = false.obs;
  final isSpeaking = false.obs;
  final recognizedText = ''.obs;

  bool _isSttInitialized = false;

  Future<VoiceService> init() async {
    // Configurar TTS
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    // Callbacks do TTS
    _tts.setStartHandler(() {
      isSpeaking.value = true;
    });

    _tts.setCompletionHandler(() {
      isSpeaking.value = false;
    });

    _tts.setErrorHandler((msg) {
      print('TTS Error: $msg');
      isSpeaking.value = false;
    });

    return this;
  }

  /// Pede permissão de microfone
  Future<bool> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      Get.snackbar(
        'Permission Denied',
        'Microphone is required for voice chat.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    return true;
  }

  /// Inicia ou para a escuta (Speech to Text)
  Future<void> toggleListening() async {
    if (isListening.value) {
      await stopListening();
      return;
    }

    final hasPermission = await _requestMicrophonePermission();
    if (!hasPermission) return;

    if (!_isSttInitialized) {
      _isSttInitialized = await _stt.initialize(
        onError: (err) => print('STT Error: $err'),
        onStatus: (status) {
          if (status == 'listening') isListening.value = true;
          if (status == 'done' || status == 'notListening') {
            isListening.value = false;
          }
        },
      );
    }

    if (_isSttInitialized) {
      recognizedText.value = '';
      await _stt.listen(
        onResult: (result) {
          recognizedText.value = result.recognizedWords;
          // Se parar de falar, podemos fazer auto-submit verificando 'result.finalResult'
          // no controller ou direto aqui.
        },
        localeId: 'en_US', // Forçar inglês
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      );
      isListening.value = true;
    }
  }

  Future<void> stopListening() async {
    await _stt.stop();
    isListening.value = false;
  }

  /// Falar um texto (Text to Speech)
  Future<void> speak(String text) async {
    await stopSpeaking();
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  @override
  void onClose() {
    _tts.stop();
    _stt.cancel();
    super.onClose();
  }
}
