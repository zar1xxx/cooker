import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/ai/qr_pairing_parser.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  late final MobileScannerController _controller;
  bool _isProcessing = false;
  bool _torchEnabled = false;

  @override
  void initState() {
    super.initState();
    // Do NOT call controller.start() manually - MobileScanner handles its own lifecycle.
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    final rawValue = barcode?.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    final l10n = AppLocalizations.of(context)!;
    final parseResult = parsePairingQr(rawValue);

    if (parseResult is! QrParseSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              parseResult is QrParseFailure
                  ? parseResult.error
                  : l10n.aiQrScannerNotAppQr,
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
      return;
    }

    try {
      final service = ref.read(qrPairingServiceProvider);
      final result = await service.applyPairingData(parseResult.data);
      if (!mounted) return;

      ref.invalidate(aiModeProvider);

      if (result.isResponding) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.aiQrScannerConnected(result.host)),
            backgroundColor: Colors.green.shade800,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.aiQrScannerSavedNotResponding),
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      context.pop(result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения настроек: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Widget _buildErrorView(BuildContext context, MobileScannerException error) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.videocam_off_outlined,
              size: 64,
              color: Colors.white70,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.aiQrScannerPermissionError,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: Text(l10n.aiQrScannerOpenSettings),
              style: ElevatedButton.styleFrom(minimumSize: const Size(180, 48)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scannerBuilder = ref.watch(qrScannerWidgetBuilderProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l10n.aiQrScannerTitle),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _torchEnabled ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            tooltip: 'Фонарик',
            onPressed: () async {
              await _controller.toggleTorch();
              setState(() {
                _torchEnabled = !_torchEnabled;
              });
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          scannerBuilder(context, _controller, _handleBarcode, _buildErrorView),
          // Viewfinder Overlay
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          // Bottom hint banner
          Positioned(
            left: 20,
            right: 20,
            bottom: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.aiQrScannerHint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
