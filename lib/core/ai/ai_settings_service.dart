import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'ai_router.dart';
import 'gigachat_provider.dart';
import 'lm_studio_provider.dart';

/// Configuration values for AI providers.
class AiSettings {
  const AiSettings({
    this.lmStudioHost = '',
    this.lmStudioPort = 1234,
    this.lmStudioModel = '',
    this.lmStudioApiKey = '',
    this.gigaChatAuthKey = '',
    this.gigaChatModel = 'GigaChat-2',
    this.gigaChatBaseUrl = 'https://gigachat.devices.sberbank.ru',
    this.gigaChatOauthUrl = 'https://ngw.devices.sberbank.ru:9443/api/v2/oauth',
  });

  final String lmStudioHost;
  final int lmStudioPort;
  final String lmStudioModel;
  final String lmStudioApiKey;
  final String gigaChatAuthKey;
  final String gigaChatModel;
  final String gigaChatBaseUrl;
  final String gigaChatOauthUrl;

  AiSettings copyWith({
    String? lmStudioHost,
    int? lmStudioPort,
    String? lmStudioModel,
    String? lmStudioApiKey,
    String? gigaChatAuthKey,
    String? gigaChatModel,
    String? gigaChatBaseUrl,
    String? gigaChatOauthUrl,
  }) {
    return AiSettings(
      lmStudioHost: lmStudioHost ?? this.lmStudioHost,
      lmStudioPort: lmStudioPort ?? this.lmStudioPort,
      lmStudioModel: lmStudioModel ?? this.lmStudioModel,
      lmStudioApiKey: lmStudioApiKey ?? this.lmStudioApiKey,
      gigaChatAuthKey: gigaChatAuthKey ?? this.gigaChatAuthKey,
      gigaChatModel: gigaChatModel ?? this.gigaChatModel,
      gigaChatBaseUrl: gigaChatBaseUrl ?? this.gigaChatBaseUrl,
      gigaChatOauthUrl: gigaChatOauthUrl ?? this.gigaChatOauthUrl,
    );
  }
}

/// Service managing persistent storage of AI settings.
///
/// Uses [FlutterSecureStorage] for secure persistence of credentials (ТЗ hard rule 7).
class AiSettingsService {
  AiSettingsService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kLmStudioHost = 'ai_lm_studio_host';
  static const _kLmStudioPort = 'ai_lm_studio_port';
  static const _kLmStudioModel = 'ai_lm_studio_model';
  static const _kLmStudioApiKey = 'ai_lm_studio_api_key';
  static const _kGigaChatAuthKey = 'ai_gigachat_auth_key';
  static const _kGigaChatModel = 'ai_gigachat_model';
  static const _kGigaChatBaseUrl = 'ai_gigachat_base_url';
  static const _kGigaChatOauthUrl = 'ai_gigachat_oauth_url';

  Future<AiSettings> loadSettings() async {
    try {
      final host = await _storage.read(key: _kLmStudioHost) ?? '';
      final portStr = await _storage.read(key: _kLmStudioPort);
      final port = int.tryParse(portStr ?? '') ?? 1234;
      final model = await _storage.read(key: _kLmStudioModel) ?? '';
      final apiKey = await _storage.read(key: _kLmStudioApiKey) ?? '';
      final authKey = await _storage.read(key: _kGigaChatAuthKey) ?? '';
      final gigaModel =
          await _storage.read(key: _kGigaChatModel) ?? 'GigaChat-2';
      final baseUrl =
          await _storage.read(key: _kGigaChatBaseUrl) ??
          'https://gigachat.devices.sberbank.ru';
      final oauthUrl =
          await _storage.read(key: _kGigaChatOauthUrl) ??
          'https://ngw.devices.sberbank.ru:9443/api/v2/oauth';

      return AiSettings(
        lmStudioHost: host,
        lmStudioPort: port,
        lmStudioModel: model,
        lmStudioApiKey: apiKey,
        gigaChatAuthKey: authKey,
        gigaChatModel: gigaModel,
        gigaChatBaseUrl: baseUrl,
        gigaChatOauthUrl: oauthUrl,
      );
    } catch (_) {
      return const AiSettings();
    }
  }

  Future<void> saveSettings(AiSettings settings) async {
    await _storage.write(key: _kLmStudioHost, value: settings.lmStudioHost);
    await _storage.write(
      key: _kLmStudioPort,
      value: settings.lmStudioPort.toString(),
    );
    await _storage.write(key: _kLmStudioModel, value: settings.lmStudioModel);
    await _storage.write(key: _kLmStudioApiKey, value: settings.lmStudioApiKey);
    await _storage.write(
      key: _kGigaChatAuthKey,
      value: settings.gigaChatAuthKey,
    );
    await _storage.write(key: _kGigaChatModel, value: settings.gigaChatModel);
    await _storage.write(
      key: _kGigaChatBaseUrl,
      value: settings.gigaChatBaseUrl,
    );
    await _storage.write(
      key: _kGigaChatOauthUrl,
      value: settings.gigaChatOauthUrl,
    );
  }

  Future<void> clearSettings() async {
    await _storage.delete(key: _kLmStudioHost);
    await _storage.delete(key: _kLmStudioPort);
    await _storage.delete(key: _kLmStudioModel);
    await _storage.delete(key: _kLmStudioApiKey);
    await _storage.delete(key: _kGigaChatAuthKey);
    await _storage.delete(key: _kGigaChatModel);
    await _storage.delete(key: _kGigaChatBaseUrl);
    await _storage.delete(key: _kGigaChatOauthUrl);
  }

  void applyToRouter(
    AiRouter router,
    AiSettings settings, {
    Uint8List? certBytes,
  }) {
    if (settings.lmStudioHost.trim().isNotEmpty) {
      router.lmStudioProvider = LmStudioProvider(
        baseUrl:
            'http://${settings.lmStudioHost.trim()}:${settings.lmStudioPort}',
        model: settings.lmStudioModel.trim().isNotEmpty
            ? settings.lmStudioModel.trim()
            : null,
        apiKey: settings.lmStudioApiKey.trim().isNotEmpty
            ? settings.lmStudioApiKey.trim()
            : null,
      );
    } else {
      router.lmStudioProvider = null;
    }

    if (settings.gigaChatAuthKey.trim().isNotEmpty) {
      final dio = GigaChatProvider.createDioWithCert(certBytes: certBytes);
      router.gigaChatProvider = GigaChatProvider(
        authKey: settings.gigaChatAuthKey.trim(),
        model: settings.gigaChatModel.trim().isNotEmpty
            ? settings.gigaChatModel.trim()
            : 'GigaChat-2',
        baseUrl: settings.gigaChatBaseUrl.trim().isNotEmpty
            ? settings.gigaChatBaseUrl.trim()
            : 'https://gigachat.devices.sberbank.ru',
        oauthUrl: settings.gigaChatOauthUrl.trim().isNotEmpty
            ? settings.gigaChatOauthUrl.trim()
            : 'https://ngw.devices.sberbank.ru:9443/api/v2/oauth',
        dio: dio,
      );
    } else {
      router.gigaChatProvider = null;
    }
  }
}
