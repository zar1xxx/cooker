import 'dart:async';

import 'package:clock/clock.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'lm_studio_provider.dart';

class PcDiscovery {
  PcDiscovery({NetworkInfo? networkInfo, Connectivity? connectivity, Dio? dio})
    : _networkInfo = networkInfo ?? NetworkInfo(),
      _connectivity = connectivity ?? Connectivity(),
      _dio = dio ?? Dio();

  final NetworkInfo _networkInfo;
  final Connectivity _connectivity;
  final Dio _dio;

  DateTime? _lastBackgroundScan;

  DateTime? get lastBackgroundScan => _lastBackgroundScan;

  Future<bool> isWifiConnected() async {
    final status = await _connectivity.checkConnectivity();
    return status.contains(ConnectivityResult.wifi);
  }

  Future<bool> probeHost(
    String host,
    int port, {
    Duration timeout = const Duration(milliseconds: 300),
  }) async {
    if (!isPrivateOrLocalHost(host)) return false;
    final url = 'http://$host:$port/v1/models';
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        url,
        options: Options(sendTimeout: timeout, receiveTimeout: timeout),
      );
      final data = response.data?['data'];
      return data is List;
    } catch (_) {
      return false;
    }
  }

  Future<String?> discover({
    String? savedHost,
    int port = 1234,
    bool force = false,
  }) async {
    final onWifi = await isWifiConnected();
    if (!onWifi) return null;

    final now = clock.now();
    if (!force &&
        _lastBackgroundScan != null &&
        now.difference(_lastBackgroundScan!) < const Duration(hours: 1)) {
      if (savedHost != null &&
          await probeHost(
            savedHost,
            port,
            timeout: const Duration(milliseconds: 500),
          )) {
        return savedHost;
      }
      return null;
    }

    // 1. Try savedHost first
    if (savedHost != null && savedHost.trim().isNotEmpty) {
      if (await probeHost(
        savedHost.trim(),
        port,
        timeout: const Duration(milliseconds: 500),
      )) {
        return savedHost.trim();
      }
    }

    _lastBackgroundScan = now;

    // 2. Discover via subnet scan
    final wifiIp = await _networkInfo.getWifiIP();
    if (wifiIp == null || !wifiIp.contains('.')) return null;

    final parts = wifiIp.split('.');
    if (parts.length != 4) return null;
    final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';

    // Scan 1..254 in concurrent batches of 32
    final ips = List.generate(254, (i) => '$subnet.${i + 1}');
    const poolSize = 32;

    for (int i = 0; i < ips.length; i += poolSize) {
      final end = (i + poolSize < ips.length) ? i + poolSize : ips.length;
      final chunk = ips.sublist(i, end);
      final futures = chunk.map((ip) async {
        final ok = await probeHost(
          ip,
          port,
          timeout: const Duration(milliseconds: 300),
        );
        return ok ? ip : null;
      });

      final results = await Future.wait(futures);
      final found = results.whereType<String>().firstOrNull;
      if (found != null) {
        return found;
      }
    }

    return null;
  }
}
