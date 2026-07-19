import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../core/constants/constants.dart';

class ConfigService extends GetxService {
  final _storage = GetStorage();
  static const _keyName = 'gemini_api_key';
  static const _gatewayUrlName = 'gateway_url';

  Future<ConfigService> init() async {
    return this;
  }

  /// URL base do AI Gateway (ADR-001). Prioriza valor salvo em Settings,
  /// senao cai para a constante (que aceita --dart-define=GATEWAY_URL).
  String get gatewayUrl {
    final stored = _storage.read<String>(_gatewayUrlName);
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }
    return Constants.gatewayUrl;
  }

  Future<void> saveGatewayUrl(String url) async {
    await _storage.write(_gatewayUrlName, url);
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
