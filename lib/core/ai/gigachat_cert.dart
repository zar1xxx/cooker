import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;

/// Russian Trusted Root CA for GigaChat hosts.
///
/// Android does not ship this root certificate, so without it every TLS
/// handshake with Sber hosts fails and the GigaChat fallback never works.
/// Loaded once in `main()` before `runApp`; used only by the GigaChat Dio.
class GigaChatCert {
  GigaChatCert._();

  static const String assetPath = 'assets/certs/russian_trusted_root_ca.cer';

  /// PEM bytes, or null if the asset could not be loaded (tests, broken build).
  static Uint8List? bytes;

  static Future<void> load() async {
    try {
      final data = await rootBundle.load(assetPath);
      bytes = data.buffer.asUint8List();
    } catch (e) {
      debugPrint('GigaChat certificate not loaded: $e');
    }
  }
}
