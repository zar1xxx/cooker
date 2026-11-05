import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ai/ai_router.dart';
import '../../core/ai/ai_settings_service.dart';
import '../../core/ai/lm_studio_provider.dart';
import '../../core/providers.dart';
import '../../core/services/daily_notification_service.dart';
import '../../l10n/app_localizations.dart';

/// Screen allowing configuration and diagnostics of AI providers (LM Studio & GigaChat).
///
/// Gated behind long-press on header badges per ТЗ 6.1.1, 7.2 and S3-08.
class AiSettingsScreen extends ConsumerStatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  ConsumerState<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends ConsumerState<AiSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _modelController;
  late final TextEditingController _gigaChatKeyController;
  late final TextEditingController _gigaChatBaseUrlController;

  bool _obscureGigaChatKey = true;
  bool _isScanning = false;
  bool _isChecking = false;
  bool _isFetchingModels = false;

  List<String> _models = [];
  String? _pcStatus;
  String? _gigaChatStatus;
  AiMode? _activeMode;
  int? _monthlyTokens;
  bool _initialized = false;
  bool _dailyNotificationEnabled = false;
  TimeOfDay _dailyNotificationTime = const TimeOfDay(hour: 10, minute: 0);

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController();
    _portController = TextEditingController(text: '1234');
    _modelController = TextEditingController();
    _gigaChatKeyController = TextEditingController();
    _gigaChatBaseUrlController = TextEditingController(
      text: 'https://gigachat.devices.sberbank.ru',
    );
    _loadNotificationConfig();
  }

  Future<void> _loadNotificationConfig() async {
    try {
      final notifService = ref.read(dailyNotificationServiceProvider);
      final config = await notifService.getConfig();
      if (mounted) {
        setState(() {
          _dailyNotificationEnabled = config.enabled;
          _dailyNotificationTime = TimeOfDay(
            hour: config.hour,
            minute: config.minute,
          );
        });
      }
    } catch (_) {}
  }

  Future<void> _updateDailyNotificationConfig({
    bool? enabled,
    TimeOfDay? time,
  }) async {
    final newEnabled = enabled ?? _dailyNotificationEnabled;
    final newTime = time ?? _dailyNotificationTime;

    setState(() {
      _dailyNotificationEnabled = newEnabled;
      _dailyNotificationTime = newTime;
    });

    final notifService = ref.read(dailyNotificationServiceProvider);
    final config = DailyNotificationConfig(
      enabled: newEnabled,
      hour: newTime.hour,
      minute: newTime.minute,
    );
    await notifService.setConfig(config);

    if (newEnabled) {
      final todayEntry = await ref.read(todayPlanEntryProvider.future);
      await notifService.scheduleDaily(
        config: config,
        todayDishTitle: todayEntry?.recipe?.title,
        recipeId: todayEntry?.recipe?.id,
      );
    } else {
      await notifService.cancelDaily();
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _modelController.dispose();
    _gigaChatKeyController.dispose();
    _gigaChatBaseUrlController.dispose();
    super.dispose();
  }

  void _initFromSettings(AiSettings settings) {
    if (_initialized) return;
    _initialized = true;
    _hostController.text = settings.lmStudioHost;
    _portController.text = settings.lmStudioPort.toString();
    _modelController.text = settings.lmStudioModel;
    _gigaChatKeyController.text = settings.gigaChatAuthKey;
    if (settings.gigaChatBaseUrl.isNotEmpty) {
      _gigaChatBaseUrlController.text = settings.gigaChatBaseUrl;
    }
  }

  Future<void> _findPc() async {
    setState(() {
      _isScanning = true;
    });

    final l10n = AppLocalizations.of(context)!;
    final discovery = ref.read(pcDiscoveryProvider);
    final port = int.tryParse(_portController.text.trim()) ?? 1234;

    try {
      final found = await discovery.discover(port: port, force: true);
      if (!mounted) return;

      setState(() {
        _isScanning = false;
      });

      if (found != null && found.isNotEmpty) {
        _hostController.text = found;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.aiSettingsPcFound(found))));
        await _fetchModels();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.aiSettingsPcNotFound)));
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.aiSettingsPcNotFound)));
      }
    }
  }

  Future<void> _fetchModels() async {
    final host = _hostController.text.trim();
    if (host.isEmpty) return;
    final port = int.tryParse(_portController.text.trim()) ?? 1234;

    setState(() {
      _isFetchingModels = true;
    });

    try {
      final provider = LmStudioProvider(baseUrl: 'http://$host:$port');
      final models = await provider.getModels();
      if (!mounted) return;

      setState(() {
        _models = models;
        if (models.isNotEmpty && _modelController.text.trim().isEmpty) {
          _modelController.text = models.first;
        }
      });
    } catch (_) {
      // Offline / unreachable
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingModels = false;
        });
      }
    }
  }

  Future<void> _checkConnection() async {
    setState(() {
      _isChecking = true;
      _pcStatus = null;
      _gigaChatStatus = null;
    });

    try {
      final l10n = AppLocalizations.of(context)!;
      final host = _hostController.text.trim();
      final port = int.tryParse(_portController.text.trim()) ?? 1234;
      final gigaKey = _gigaChatKeyController.text.trim();

      final checker = ref.read(aiConnectionCheckerProvider);

      // Check PC
      if (host.isNotEmpty) {
        final ok = await checker.checkPc(host, port);
        if (!mounted) return;
        setState(() {
          _pcStatus = ok
              ? l10n.aiSettingsStatusPcOk
              : l10n.aiSettingsStatusPcFails;
        });
      } else {
        _pcStatus = l10n.aiSettingsStatusPcFails;
      }

      // Check GigaChat
      if (gigaKey.isNotEmpty) {
        final baseUrl = _gigaChatBaseUrlController.text.trim().isNotEmpty
            ? _gigaChatBaseUrlController.text.trim()
            : 'https://gigachat.devices.sberbank.ru';
        final ok = await checker.checkGigaChat(gigaKey, baseUrl);
        if (!mounted) return;
        setState(() {
          _gigaChatStatus = ok
              ? l10n.aiSettingsStatusGigaChatOk
              : l10n.aiSettingsStatusGigaChatFails;
        });
      } else {
        _gigaChatStatus = l10n.aiSettingsStatusGigaChatNotConfigured;
      }

      // Determine active mode based on test results
      AiMode computedMode = AiMode.offline;
      if (_pcStatus == l10n.aiSettingsStatusPcOk) {
        computedMode = AiMode.localPc;
      } else if (_gigaChatStatus == l10n.aiSettingsStatusGigaChatOk) {
        computedMode = AiMode.gigaChat;
      }

      if (!mounted) return;
      setState(() {
        _activeMode = computedMode;
      });
    } catch (e, st) {
      debugPrint('Error in _checkConnection: $e\n$st');
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    final l10n = AppLocalizations.of(context)!;
    final settingsService = ref.read(aiSettingsServiceProvider);
    final router = ref.read(aiRouterProvider);

    final updated = AiSettings(
      lmStudioHost: _hostController.text.trim(),
      lmStudioPort: int.tryParse(_portController.text.trim()) ?? 1234,
      lmStudioModel: _modelController.text.trim(),
      gigaChatAuthKey: _gigaChatKeyController.text.trim(),
      gigaChatBaseUrl: _gigaChatBaseUrlController.text.trim().isNotEmpty
          ? _gigaChatBaseUrlController.text.trim()
          : 'https://gigachat.devices.sberbank.ru',
    );

    await settingsService.saveSettings(updated);
    settingsService.applyToRouter(router, updated);

    ref.invalidate(aiSettingsProvider);
    ref.invalidate(aiModeProvider);
    ref.invalidate(aiServiceProvider);
    ref.invalidate(monthlyGigaChatTokensProvider);

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.aiSettingsSaved)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final settingsAsync = ref.watch(aiSettingsProvider);
    settingsAsync.whenData((settings) {
      _initFromSettings(settings);
    });

    final tokensAsync = ref.watch(monthlyGigaChatTokensProvider);
    final tokenCount = _monthlyTokens ?? tokensAsync.value ?? 0;

    String modeText(AiMode? mode) {
      switch (mode) {
        case AiMode.localPc:
          return l10n.aiAssistantPc;
        case AiMode.gigaChat:
          return l10n.aiAssistantGigaChat;
        case AiMode.offline:
        default:
          return l10n.aiAssistantOffline;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.aiSettingsTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_outline),
            tooltip: l10n.tasteScreenTitle,
            onPressed: () => context.push('/settings/preferences'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Taste Preferences Link Card
            Card(
              elevation: 0,
              color: theme.colorScheme.secondaryContainer.withValues(
                alpha: 0.4,
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.favorite,
                  color: Colors.deepOrange,
                  size: 28,
                ),
                title: Text(
                  l10n.tasteScreenTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  l10n.tasteScreenSubtitle,
                  style: theme.textTheme.bodySmall,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/preferences'),
              ),
            ),
            const SizedBox(height: 12),

            // Backup Link Card
            Card(
              elevation: 0,
              color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.4),
              child: ListTile(
                leading: const Icon(
                  Icons.settings_backup_restore,
                  color: Colors.teal,
                  size: 28,
                ),
                title: Text(
                  l10n.backupScreenTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  l10n.backupScreenSubtitle,
                  style: theme.textTheme.bodySmall,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/backup'),
              ),
            ),
            const SizedBox(height: 12),

            // Section: Daily Notification (ТЗ 7.3)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      l10n.dailyNotificationSwitch,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      l10n.dailyNotificationSubtitle,
                      style: theme.textTheme.bodySmall,
                    ),
                    secondary: Icon(
                      Icons.notifications_active_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    value: _dailyNotificationEnabled,
                    onChanged: (val) =>
                        _updateDailyNotificationConfig(enabled: val),
                  ),
                  if (_dailyNotificationEnabled) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: Text(l10n.dailyNotificationTime),
                      trailing: Text(
                        '${_dailyNotificationTime.hour.toString().padLeft(2, '0')}:${_dailyNotificationTime.minute.toString().padLeft(2, '0')}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _dailyNotificationTime,
                        );
                        if (picked != null) {
                          await _updateDailyNotificationConfig(time: picked);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Active Mode Status Card
            Card(
              elevation: 0,
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.smart_toy_outlined,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.aiSettingsActiveMode(
                              modeText(
                                _activeMode ??
                                    ref.watch(aiModeProvider).value ??
                                    AiMode.offline,
                              ),
                            ),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.aiSettingsTokenCount(tokenCount),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section 1: LM Studio (Домашний ПК)
            Text(
              l10n.aiSettingsPcSection,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.aiSettingsPcSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _hostController,
                    decoration: InputDecoration(
                      labelText: l10n.aiSettingsPcHost,
                      hintText: '192.168.1.100',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _portController,
                    decoration: InputDecoration(
                      labelText: l10n.aiSettingsPcPort,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Button: Find PC
            SizedBox(
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _isScanning ? null : _findPc,
                icon: _isScanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(
                  _isScanning
                      ? l10n.aiSettingsFindingPc
                      : l10n.aiSettingsFindPc,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Model input / selection
            Row(
              children: [
                Expanded(
                  child: _models.isNotEmpty
                      ? DropdownButtonFormField<String>(
                          initialValue: _models.contains(_modelController.text)
                              ? _modelController.text
                              : _models.first,
                          decoration: InputDecoration(
                            labelText: l10n.aiSettingsModel,
                            border: const OutlineInputBorder(),
                          ),
                          items: _models.map((m) {
                            return DropdownMenuItem(
                              value: m,
                              child: Text(m, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _modelController.text = val;
                              });
                            }
                          },
                        )
                      : TextFormField(
                          controller: _modelController,
                          decoration: InputDecoration(
                            labelText: l10n.aiSettingsModel,
                            hintText: 'qwen2.5-7b-instruct',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: l10n.aiSettingsRefreshModels,
                  icon: _isFetchingModels
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  onPressed: _isFetchingModels ? null : _fetchModels,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section 2: GigaChat
            Text(
              l10n.aiSettingsGigaChatSection,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.aiSettingsGigaChatSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _gigaChatKeyController,
              obscureText: _obscureGigaChatKey,
              decoration: InputDecoration(
                labelText: l10n.aiSettingsGigaChatKey,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureGigaChatKey
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureGigaChatKey = !_obscureGigaChatKey;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Diagnostics & Check connection
            if (_pcStatus != null || _gigaChatStatus != null) ...[
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_pcStatus != null)
                        Row(
                          children: [
                            Icon(
                              _pcStatus == l10n.aiSettingsStatusPcOk
                                  ? Icons.check_circle
                                  : Icons.error_outline,
                              color: _pcStatus == l10n.aiSettingsStatusPcOk
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _pcStatus!,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      if (_pcStatus != null && _gigaChatStatus != null)
                        const SizedBox(height: 8),
                      if (_gigaChatStatus != null)
                        Row(
                          children: [
                            Icon(
                              _gigaChatStatus == l10n.aiSettingsStatusGigaChatOk
                                  ? Icons.check_circle
                                  : Icons.info_outline,
                              color:
                                  _gigaChatStatus ==
                                      l10n.aiSettingsStatusGigaChatOk
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _gigaChatStatus!,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              height: 56,
              child: FilledButton.tonal(
                onPressed: _isChecking ? null : _checkConnection,
                child: _isChecking
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        l10n.aiSettingsCheckConnection,
                        style: theme.textTheme.bodyLarge,
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Main Action: Save Settings
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: _saveSettings,
                child: Text(
                  l10n.aiSettingsSave,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
