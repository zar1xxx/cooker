import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/adaptive/adaptive_app_bar_title.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';

/// Screen allowing elderly users and their relatives to safely export
/// and import application data without leaking API keys (ТЗ 7.2, 8.2, S4-05).
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  final _importController = TextEditingController();
  bool _isExporting = false;
  bool _isImporting = false;
  String? _lastExportSummary;
  String? _importError;

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  Future<void> _exportBackup() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isExporting = true;
    });

    try {
      final backupService = ref.read(backupServiceProvider);
      final jsonString = await backupService.exportBackupJson();

      try {
        await Clipboard.setData(ClipboardData(text: jsonString))
            .timeout(const Duration(milliseconds: 500), onTimeout: () {});
      } catch (_) {
        // Fallback for test environments without platform clipboard
      }

      final bytes = utf8.encode(jsonString).length;
      final kb = (bytes / 1024.0).toStringAsFixed(1);

      final dynamic decoded = jsonDecode(jsonString);
      final data = decoded['data'] as Map<String, dynamic>? ?? {};
      final cookedList = data['cooked_entries'] as List? ?? [];
      final recipesList = data['recipes'] as List? ?? [];

      if (!mounted) return;

      setState(() {
        _lastExportSummary = l10n.backupExportSummary(
          cookedList.length,
          recipesList.length,
        );
        _isExporting = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.backupExportSuccess(kb))));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isExporting = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      setState(() {
        _importController.text = data.text!.trim();
        _importError = null;
      });
    }
  }

  Future<void> _importBackup() async {
    final l10n = AppLocalizations.of(context)!;
    final text = _importController.text.trim();

    if (text.isEmpty) {
      setState(() {
        _importError = l10n.backupEmptyInputError;
      });
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.backupImportConfirmTitle),
        content: Text(l10n.backupImportConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.backupImportCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.backupImportConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isImporting = true;
      _importError = null;
    });

    try {
      final backupService = ref.read(backupServiceProvider);
      final summary = await backupService.importBackupJson(text);

      ref.invalidate(historyEntriesProvider);
      ref.invalidate(preferenceProfileProvider);
      ref.invalidate(compressedProfileProvider);
      ref.invalidate(pantryProvider);
      ref.invalidate(suggestionsProvider);

      if (!mounted) return;

      setState(() {
        _isImporting = false;
        _importController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.backupImportSuccess(summary.cookedEntries)),
        ),
      );
    } catch (e, st) {
      debugPrint('EXPORT ERROR: $e\n$st');
      if (!mounted) return;
      setState(() {
        _isImporting = false;
        _importError = l10n.backupImportError(e.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: AdaptiveAppBarTitle(l10n.backupScreenTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Security and Privacy Notice Card
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.security,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.backupAboutCard,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section 1: Export
          Text(
            l10n.backupExportSection,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: _isExporting ? null : _exportBackup,
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.copy),
              label: Text(
                l10n.backupExportButton,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
          if (_lastExportSummary != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _lastExportSummary!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Section 2: Import
          Text(
            l10n.backupImportSection,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.backupImportSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),

          // Paste Button
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: _pasteFromClipboard,
                icon: const Icon(Icons.paste),
                label: Text(l10n.backupPasteButton),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Import Text Field
          TextField(
            controller: _importController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: l10n.backupImportHint,
              border: const OutlineInputBorder(),
              errorText: _importError,
            ),
          ),
          const SizedBox(height: 16),

          // Import Button
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: _isImporting ? null : _importBackup,
              icon: _isImporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.settings_backup_restore),
              label: Text(
                l10n.backupImportButton,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
