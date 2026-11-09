import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/ai/qr_pairing_parser.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key, this.openSettings});

  final Future<bool> Function()? openSettings;

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  late final MobileScannerController _controller;
  bool _isProcessing = false;
  bool _torchEnabled = false;
  bool _hasCameraError = false;

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
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.aiQrScannerSaveError),
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
    if (!_hasCameraError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasCameraError) {
          setState(() {
            _hasCameraError = true;
          });
        }
      });
    }

    final l10n = AppLocalizations.of(context)!;
    final isPermissionDenied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    final message = isPermissionDenied
        ? l10n.aiQrScannerPermissionError
        : l10n.aiQrScannerCameraUnavailable;

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
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              key: const Key('btn_open_app_settings'),
              onPressed: () => (widget.openSettings ?? openAppSettings)(),
              icon: const Icon(Icons.settings),
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
          if (!_hasCameraError) ...[
            // Viewfinder Overlay
            Center(
              child: Container(
                key: const Key('qr_viewfinder_overlay'),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.aiQrScannerHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
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
