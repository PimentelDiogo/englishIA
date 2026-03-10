import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../core/constants/constants.dart';

class ConfigService extends GetxService {
  final _storage = GetStorage();
  static const _keyName = 'gemini_api_key';

  Future<ConfigService> init() async {
    return this;
  }

  String get apiKey {
    final storedKey = _storage.read<String>(_keyName);
    if (storedKey != null && storedKey.isNotEmpty) {
      return storedKey;
    }
    // Fallback to constants (which can be populated via --dart-define)
    return Constants.geminiApiKey;
  }

  Future<void> saveApiKey(String key) async {
    await _storage.write(_keyName, key);
  }

  bool get hasCustomKey => _storage.hasData(_keyName);

  Future<void> clearCustomKey() async {
    await _storage.remove(_keyName);
  }
}
