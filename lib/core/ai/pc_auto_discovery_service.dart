import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'ai_router.dart';
import 'ai_settings_service.dart';
import 'pc_discovery.dart';

/// Background service for automatic discovery of the local PC running LM Studio.
///
/// Implements R3-04:
/// - Checks saved address on startup and Wi-Fi connect.
/// - If not responding (or not set), runs [PcDiscovery.discover] (with 1-hour throttle).
/// - Saves newly discovered address to settings and applies it to [AiRouter].
class PcAutoDiscoveryService {
  PcAutoDiscoveryService({
    required this.discovery,
    required this.settingsService,
    required this.router,
    required this.connectivity,
  });

  final PcDiscovery discovery;
  final AiSettingsService settingsService;
  final AiRouter router;
  final Connectivity connectivity;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isScanning = false;

  bool get isScanning => _isScanning;

  /// Performs background/active check of the PC:
  /// 1. If savedHost is configured in settings and answers, keep it and ensure router has it.
  /// 2. If savedHost is missing or not answering: run [PcDiscovery.discover] (with 1h throttle unless force: true).
  /// 3. If found on subnet: save to settings and apply to router.
  Future<String?> checkAndDiscover({bool force = false}) async {
    if (_isScanning) return null;
    _isScanning = true;
    try {
      final onWifi = await discovery.isWifiConnected();
      if (!onWifi) return null;

      final settings = await settingsService.loadSettings();
      final savedHost = settings.lmStudioHost.trim();
      final port = settings.lmStudioPort != 0 ? settings.lmStudioPort : 1234;
      final candidatePorts = <int>{
        if (settings.lmStudioPort != 0) settings.lmStudioPort,
        1234,
        1235,
      }.toList();

      // 1. If savedHost is set, check if it answers (trying candidate ports)
      if (savedHost.isNotEmpty) {
        for (final p in candidatePorts) {
          final ok = await discovery.probeHost(
            savedHost,
            p,
            timeout: const Duration(milliseconds: 500),
          );
          if (ok) {
            final updated = settings.copyWith(lmStudioPort: p);
            if (p != settings.lmStudioPort) {
              await settingsService.saveSettings(updated);
            }
            if (router.lmStudioProvider == null || p != settings.lmStudioPort) {
              settingsService.applyToRouter(router, updated);
            }
            return savedHost;
          }
        }
      }

      // 2. Saved host not responding or empty: discover on subnet
      final found = await discovery.discover(
        savedHost: savedHost.isNotEmpty ? savedHost : null,
        port: port,
        force: force,
      );

      if (found != null && found.isNotEmpty) {
        final foundPort = discovery.lastDiscoveredPort ?? port;
        final updated = settings.copyWith(
          lmStudioHost: found,
          lmStudioPort: foundPort,
        );
        await settingsService.saveSettings(updated);
        settingsService.applyToRouter(router, updated);
        return found;
      }

      return null;
    } catch (_) {
      return null;
    } finally {
      _isScanning = false;
    }
  }

  /// Starts listening to connectivity changes. When Wi-Fi connects, triggers checkAndDiscover.
  void startListening() {
    _subscription?.cancel();
    // In Flutter test environment, avoid listening to the unmocked native platform channel
    // to prevent MissingPluginException, unless a fake/mock Connectivity is supplied.
    if (Platform.environment.containsKey('FLUTTER_TEST') &&
        connectivity.runtimeType.toString() == 'Connectivity') {
      return;
    }

    try {
      _subscription = connectivity.onConnectivityChanged.listen((results) {
        if (results.contains(ConnectivityResult.wifi)) {
          checkAndDiscover(force: false);
        }
      }, onError: (_) {});
    } catch (_) {}
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
