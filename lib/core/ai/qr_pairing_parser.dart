import 'dart:convert';

/// Returns true if [ip] is an IPv4 address within RFC 1918 private ranges:
/// - 10.0.0.0/8
/// - 172.16.0.0/12
/// - 192.168.0.0/16
///
/// Explicitly excludes loopback (127.x), link-local (169.254.x), and TUN/benchmark (198.18.x / 198.19.x).
bool isPrivateIpv4(String ip) {
  final parts = ip.split('.');
  if (parts.length != 4) return false;
  final octets = parts.map(int.tryParse).toList();
  if (octets.any((o) => o == null || o < 0 || o > 255)) return false;

  final o0 = octets[0]!;
  final o1 = octets[1]!;

  // 127.x.x.x
  if (o0 == 127) return false;
  // 169.254.x.x
  if (o0 == 169 && o1 == 254) return false;
  // 198.18.x.x / 198.19.x.x (FlClashX / Clash TUN)
  if (o0 == 198 && (o1 == 18 || o1 == 19)) return false;

  // 10.0.0.0/8
  if (o0 == 10) return true;
  // 172.16.0.0/12
  if (o0 == 172 && o1 >= 16 && o1 <= 31) return true;
  // 192.168.0.0/16
  if (o0 == 192 && o1 == 168) return true;

  return false;
}

class QrPairingData {
  const QrPairingData({
    required this.hosts,
    required this.port,
    required this.model,
    this.gigaChatKey,
  });

  final List<String> hosts;
  final int port;
  final String model;
  final String? gigaChatKey;
}

sealed class QrParseResult {
  const QrParseResult();
}

class QrParseSuccess extends QrParseResult {
  const QrParseSuccess(this.data);
  final QrPairingData data;
}

class QrParseFailure extends QrParseResult {
  const QrParseFailure(this.error);
  final String error;
}

/// Parses and validates the raw QR code content scanned from PC.
QrParseResult parsePairingQr(String rawContent) {
  try {
    final dynamic decoded = jsonDecode(rawContent);
    if (decoded is! Map<String, dynamic>) {
      return const QrParseFailure('Это не QR-код приложения');
    }
    if (decoded['app'] != 'chto-prigotovit' || decoded['v'] != 1) {
      return const QrParseFailure('Это не QR-код приложения');
    }
    final rawHosts = decoded['hosts'];
    if (rawHosts is! List || rawHosts.isEmpty) {
      return const QrParseFailure('В QR-коде не указаны адреса компьютера');
    }

    final validPrivateHosts = <String>[];
    for (final h in rawHosts) {
      if (h is String && isPrivateIpv4(h.trim())) {
        validPrivateHosts.add(h.trim());
      }
    }

    if (validPrivateHosts.isEmpty) {
      return const QrParseFailure(
        'QR-код содержит некорректные или публичные IP-адреса',
      );
    }

    final port = decoded['port'] is int ? decoded['port'] as int : 1235;
    final model = decoded['model']?.toString() ?? '';

    String? gigaChatKey;
    if (decoded['gigachat_key'] != null) {
      final rawKey = decoded['gigachat_key'].toString().trim();
      if (rawKey.isNotEmpty) {
        gigaChatKey = rawKey;
      }
    }

    return QrParseSuccess(
      QrPairingData(
        hosts: validPrivateHosts,
        port: port,
        model: model,
        gigaChatKey: gigaChatKey,
      ),
    );
  } catch (_) {
    return const QrParseFailure('Это не QR-код приложения');
  }
}
