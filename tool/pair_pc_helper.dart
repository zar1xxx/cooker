import 'package:qr/qr.dart';

class PcNetworkInfo {
  const PcNetworkInfo({required this.name, required this.addresses});
  final String name;
  final List<String> addresses;
}

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

/// Returns true if the network interface name indicates a virtual, container, or tunnel adapter.
bool isVirtualOrExcludedAdapter(String name) {
  final lower = name.toLowerCase();
  const excluded = [
    'vethernet',
    'virtualbox',
    'vmware',
    'hyper-v',
    'wsl',
    'flclash',
    'clash',
    'tun',
    'tailscale',
  ];
  return excluded.any((ex) => lower.contains(ex));
}

/// Filters and orders network interfaces for PC pairing.
/// Places physical Wi-Fi and Ethernet interfaces first.
List<String> filterCandidateHosts(List<PcNetworkInfo> interfaces) {
  final validEntries = <({String name, String ip, int priority})>[];

  for (final iface in interfaces) {
    if (isVirtualOrExcludedAdapter(iface.name)) continue;

    int priority = 3;
    final lower = iface.name.toLowerCase();
    if (lower.contains('wi-fi') ||
        lower.contains('wifi') ||
        lower.contains('беспроводн') ||
        lower.contains('wlan')) {
      priority = 1;
    } else if (lower.contains('ethernet') || lower.contains('eth')) {
      priority = 2;
    }

    for (final addr in iface.addresses) {
      if (isPrivateIpv4(addr)) {
        validEntries.add((name: iface.name, ip: addr, priority: priority));
      }
    }
  }

  validEntries.sort((a, b) => a.priority.compareTo(b.priority));
  final seen = <String>{};
  final result = <String>[];
  for (final entry in validEntries) {
    if (seen.add(entry.ip)) {
      result.add(entry.ip);
    }
  }
  return result;
}

/// Builds the JSON payload for the pairing QR code according to R4-10 spec.
Map<String, dynamic> buildPairingJson({
  required List<String> hosts,
  required int port,
  required String model,
  String? gigaChatKey,
}) {
  final cleanKey = gigaChatKey
      ?.trim()
      .replaceAll(RegExp(r'^Basic\s+', caseSensitive: false), '')
      .replaceAll(RegExp(r'[\r\n\t "]+'), '')
      .trim();

  return {
    'app': 'chto-prigotovit',
    'v': 1,
    'hosts': hosts,
    'port': port,
    'model': model,
    if (cleanKey != null && cleanKey.isNotEmpty) 'gigachat_key': cleanKey,
  };
}

/// Generates an SVG string representation of the QR code using package:qr.
String generateQrSvg(String data, {int moduleSize = 8, int margin = 20}) {
  final payload = QrPayload.fromString(data);
  final qrCode = QrCode(
    payload: payload,
    errorCorrectLevel: QrErrorCorrectLevel.medium,
  );
  final qrImage = QrImage(qrCode);
  final count = qrImage.moduleCount;
  final size = count * moduleSize + margin * 2;

  final sb = StringBuffer();
  sb.writeln(
    '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" '
    'width="$size" height="$size" viewBox="0 0 $size $size">',
  );
  sb.writeln('<rect width="100%" height="100%" fill="#ffffff" rx="16"/>');

  for (int y = 0; y < count; y++) {
    for (int x = 0; x < count; x++) {
      if (qrImage.isDark(y, x)) {
        final px = margin + x * moduleSize;
        final py = margin + y * moduleSize;
        sb.writeln(
          '<rect x="$px" y="$py" width="$moduleSize" height="$moduleSize" fill="#1b1c18"/>',
        );
      }
    }
  }
  sb.writeln('</svg>');
  return sb.toString();
}

/// Builds the complete HTML page with the QR code and instructions.
String buildPairingHtml({
  required String svg,
  required List<String> hosts,
  required int port,
  required String model,
  required bool hasGigaChatKey,
}) {
  return '''<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <title>Подключение помощника — Что приготовить?</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: #f4f7f4;
      color: #1b1c18;
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 32px 16px;
      margin: 0;
    }
    .card {
      background: #ffffff;
      border-radius: 24px;
      box-shadow: 0 4px 24px rgba(0, 0, 0, 0.08);
      padding: 32px;
      max-width: 520px;
      width: 100%;
      text-align: center;
      box-sizing: border-box;
    }
    h1 {
      font-size: 24px;
      margin: 0 0 8px 0;
      color: #226440;
    }
    p.subtitle {
      color: #49454f;
      margin: 0 0 24px 0;
      font-size: 15px;
    }
    .qr-container {
      background: #ffffff;
      padding: 16px;
      border: 2px solid #e0e4de;
      border-radius: 16px;
      display: inline-block;
      margin-bottom: 24px;
    }
    .qr-container svg {
      display: block;
      max-width: 100%;
      height: auto;
      min-width: 300px;
    }
    .info-box {
      background: #eef5ee;
      border-radius: 12px;
      padding: 16px;
      text-align: left;
      font-size: 14px;
      line-height: 1.5;
      margin-bottom: 20px;
    }
    .info-box strong {
      color: #1b1c18;
    }
    .tips {
      text-align: left;
      font-size: 13px;
      color: #555;
      line-height: 1.5;
      border-top: 1px solid #e0e0e0;
      padding-top: 16px;
    }
    .tips li {
      margin-bottom: 8px;
    }
    .badge-key {
      background: #ffd8d8;
      color: #900;
      padding: 4px 8px;
      border-radius: 6px;
      font-size: 12px;
      font-weight: bold;
      display: inline-block;
      margin-bottom: 12px;
    }
  </style>
  ${hasGigaChatKey ? '''
  <script>
    setTimeout(function() {
      document.body.innerHTML = '<div class="card"><h1>Время действия QR-кода истекло</h1><p>Для безопасности ключ GigaChat был удалён. Закройте эту вкладку.</p></div>';
    }, 120000);
  </script>
  ''' : ''}
</head>
<body>
  <div class="card">
    <h1>Подключение компьютера к телефону</h1>
    <p class="subtitle">Откройте приложение «Что приготовить?» на телефоне и отсканируйте этот QR-код</p>

    ${hasGigaChatKey ? '<div class="badge-key">Содержит ключ GigaChat • Закройте страницу после сканирования (автоудаление через 2 мин)</div>' : ''}

    <div class="qr-container">
      $svg
    </div>

    <div class="info-box">
      <div><strong>Адрес ПК:</strong> ${hosts.join(', ')}:$port</div>
      <div><strong>Модель:</strong> $model</div>
    </div>

    <div class="tips">
      <strong>Важно:</strong>
      <ul>
        <li>Телефон и компьютер должны быть подключены к <b>одной Wi-Fi сети</b>.</li>
        <li>Брандмауэр Windows должен разрешать порт <b>$port</b> для частной сети.</li>
        <li>Если на ПК включён прокси/VPN в режиме TUN (например, FlClashX), добавьте диапазон <code>192.168.0.0/16</code> в список исключений TUN.</li>
      </ul>
    </div>
  </div>
</body>
</html>
''';
}
