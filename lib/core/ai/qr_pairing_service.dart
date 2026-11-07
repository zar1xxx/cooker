import 'dart:async';

import 'ai_router.dart';
import 'ai_settings_service.dart';
import 'pc_discovery.dart';
import 'qr_pairing_parser.dart';

class QrApplyResult {
  const QrApplyResult({
    required this.host,
    required this.port,
    required this.model,
    required this.isResponding,
    required this.hasGigaChatKey,
  });

  final String host;
  final int port;
  final String model;
  final bool isResponding;
  final bool hasGigaChatKey;
}

class QrPairingService {
  QrPairingService({
    required this.discovery,
    required this.settingsService,
    required this.router,
  });

  final PcDiscovery discovery;
  final AiSettingsService settingsService;
  final AiRouter router;

  Future<QrApplyResult> applyPairingData(QrPairingData data) async {
    String? respondingHost;
    for (final host in data.hosts) {
      final ok = await discovery.probeHost(
        host,
        data.port,
        timeout: const Duration(seconds: 1),
      );
      if (ok) {
        respondingHost = host;
        break;
      }
    }

    final selectedHost = respondingHost ?? data.hosts.first;
    final isResponding = respondingHost != null;

    final currentSettings = await settingsService.loadSettings();
    final updatedSettings = currentSettings.copyWith(
      lmStudioHost: selectedHost,
      lmStudioPort: data.port,
      lmStudioModel: data.model.isNotEmpty
          ? data.model
          : currentSettings.lmStudioModel,
      gigaChatAuthKey:
          (data.gigaChatKey != null && data.gigaChatKey!.isNotEmpty)
          ? data.gigaChatKey!
          : currentSettings.gigaChatAuthKey,
    );
    await settingsService.saveSettings(updatedSettings);

    settingsService.applyToRouter(router, updatedSettings);

    return QrApplyResult(
      host: selectedHost,
      port: data.port,
      model: data.model,
      isResponding: isResponding,
      hasGigaChatKey: data.gigaChatKey != null && data.gigaChatKey!.isNotEmpty,
    );
  }
}
