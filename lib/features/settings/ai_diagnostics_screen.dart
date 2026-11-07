import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/ai/ai_failure.dart';
import '../../core/ai/ai_provider.dart';
import '../../core/ai/gigachat_cert.dart';
import '../../core/ai/gigachat_provider.dart';
import '../../core/ai/lm_studio_provider.dart';
import '../../core/db/app_database.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';

enum DiagnosticStepStatus { pending, running, success, failure, skipped }

class DiagnosticStepItem {
  final String id;
  final String title;
  final DiagnosticStepStatus status;
  final String message;
  final String? details;

  const DiagnosticStepItem({
    required this.id,
    required this.title,
    this.status = DiagnosticStepStatus.pending,
    this.message = '',
    this.details,
  });

  DiagnosticStepItem copyWith({
    DiagnosticStepStatus? status,
    String? message,
    String? details,
  }) {
    return DiagnosticStepItem(
      id: id,
      title: title,
      status: status ?? this.status,
      message: message ?? this.message,
      details: details ?? this.details,
    );
  }
}

class AiDiagnosticsScreen extends ConsumerStatefulWidget {
  const AiDiagnosticsScreen({super.key});

  @override
  ConsumerState<AiDiagnosticsScreen> createState() =>
      _AiDiagnosticsScreenState();
}

class _AiDiagnosticsScreenState extends ConsumerState<AiDiagnosticsScreen> {
  bool _isRunning = false;
  List<DiagnosticStepItem> _steps = [];
  List<AiRequest> _history = [];

  @override
  void initState() {
    super.initState();
    _initSteps();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runDiagnostics();
      _loadHistory();
    });
  }

  void _initSteps() {
    _steps = const [
      DiagnosticStepItem(id: 'wifi', title: '1. Wi-Fi подключение'),
      DiagnosticStepItem(id: 'phone_ip', title: '2. Адрес телефона в сети'),
      DiagnosticStepItem(id: 'pc_found', title: '3. Поиск компьютера (ПК)'),
      DiagnosticStepItem(id: 'lm_studio', title: '4. Ответ LM Studio'),
      DiagnosticStepItem(id: 'model_loaded', title: '5. Загруженная модель'),
      DiagnosticStepItem(id: 'gigachat_key', title: '6. Ключ GigaChat'),
      DiagnosticStepItem(
        id: 'gigachat_token',
        title: '7. Авторизация GigaChat',
      ),
      DiagnosticStepItem(id: 'test_query', title: '8. Пробный запрос к ИИ'),
    ];
  }

  void _updateStep(
    String id,
    DiagnosticStepItem Function(DiagnosticStepItem) update,
  ) {
    if (!mounted) return;
    setState(() {
      _steps = _steps.map((s) => s.id == id ? update(s) : s).toList();
    });
  }

  Future<void> _loadHistory() async {
    try {
      final db = ref.read(databaseProvider);
      final list =
          await (db.select(db.aiRequests)
                ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.at)])
                ..limit(10))
              .get();
      if (mounted) {
        setState(() {
          _history = list;
        });
      }
    } catch (_) {}
  }

  Future<void> _runDiagnostics() async {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
      _initSteps();
    });

    final connectivity = ref.read(connectivityProvider);
    final networkInfo = ref.read(networkInfoProvider);
    final discovery = ref.read(pcDiscoveryProvider);
    final settingsService = ref.read(aiSettingsServiceProvider);
    final settings = await settingsService.loadSettings();

    bool wifiOk = false;
    String? phoneIp;
    String? pcHost;
    int pcPort = settings.lmStudioPort != 0 ? settings.lmStudioPort : 1234;
    bool lmStudioOk = false;
    String? activeModel;
    bool gigaKeyOk = false;
    bool gigaTokenOk = false;

    // --- 1. Wi-Fi ---
    _updateStep(
      'wifi',
      (s) => s.copyWith(
        status: DiagnosticStepStatus.running,
        message: 'Проверка сети...',
      ),
    );
    try {
      final conn = await connectivity.checkConnectivity();
      wifiOk = conn.contains(ConnectivityResult.wifi);
      _updateStep(
        'wifi',
        (s) => s.copyWith(
          status: wifiOk
              ? DiagnosticStepStatus.success
              : DiagnosticStepStatus.failure,
          message: wifiOk
              ? 'Телефон подключён к Wi-Fi'
              : 'Телефон не подключён к Wi-Fi',
        ),
      );
    } catch (e) {
      _updateStep(
        'wifi',
        (s) => s.copyWith(
          status: DiagnosticStepStatus.failure,
          message: 'Ошибка проверки сети: $e',
        ),
      );
    }

    // --- 2. Phone IP ---
    _updateStep(
      'phone_ip',
      (s) => s.copyWith(
        status: DiagnosticStepStatus.running,
        message: 'Определение IP адреса...',
      ),
    );
    try {
      phoneIp = await networkInfo.getWifiIP();
      final hasIp = phoneIp != null && phoneIp.isNotEmpty;
      _updateStep(
        'phone_ip',
        (s) => s.copyWith(
          status: hasIp
              ? DiagnosticStepStatus.success
              : DiagnosticStepStatus.failure,
          message: hasIp
              ? 'Адрес телефона: $phoneIp'
              : 'Не удалось определить IP телефона',
        ),
      );
    } catch (e) {
      _updateStep(
        'phone_ip',
        (s) => s.copyWith(
          status: DiagnosticStepStatus.failure,
          message: 'Ошибка получения IP: $e',
        ),
      );
    }

    // --- 3. PC Reachability ---
    _updateStep(
      'pc_found',
      (s) => s.copyWith(
        status: DiagnosticStepStatus.running,
        message: 'Поиск компьютера в сети...',
      ),
    );
    try {
      final configuredHost = settings.lmStudioHost.trim();
      final candidatePorts = <int>{pcPort, 1234, 1235}.toList();
      bool found = false;
      if (configuredHost.isNotEmpty) {
        for (final p in candidatePorts) {
          found = await discovery.probeHost(
            configuredHost,
            p,
            timeout: const Duration(milliseconds: 600),
          );
          if (found) {
            pcHost = configuredHost;
            pcPort = p;
            break;
          }
        }
      }

      if (!found && wifiOk) {
        final discovered = await discovery.discover(
          savedHost: configuredHost.isNotEmpty ? configuredHost : null,
          port: pcPort,
          force: true,
        );
        if (discovered != null && discovered.isNotEmpty) {
          pcHost = discovered;
          pcPort = discovery.lastDiscoveredPort ?? pcPort;
          found = true;
        }
      }

      _updateStep(
        'pc_found',
        (s) => s.copyWith(
          status: found
              ? DiagnosticStepStatus.success
              : DiagnosticStepStatus.failure,
          message: found
              ? 'Компьютер найден: $pcHost:$pcPort'
              : 'Компьютер не найден в локальной сети',
        ),
      );
    } catch (e) {
      _updateStep(
        'pc_found',
        (s) => s.copyWith(
          status: DiagnosticStepStatus.failure,
          message: 'Ошибка поиска ПК: $e',
        ),
      );
    }

    // --- 4. LM Studio Responding ---
    _updateStep(
      'lm_studio',
      (s) => s.copyWith(
        status: DiagnosticStepStatus.running,
        message: 'Проверка ответа LM Studio...',
      ),
    );
    List<String> loadedModels = [];
    if (pcHost != null) {
      try {
        final lm = LmStudioProvider(
          baseUrl: 'http://$pcHost:$pcPort',
          apiKey: settings.lmStudioApiKey.isNotEmpty
              ? settings.lmStudioApiKey
              : null,
        );
        loadedModels = await lm.getModels(timeout: const Duration(seconds: 3));
        lmStudioOk = true;
        _updateStep(
          'lm_studio',
          (s) => s.copyWith(
            status: DiagnosticStepStatus.success,
            message: 'LM Studio отвечает на порту $pcPort',
          ),
        );
      } catch (e) {
        lmStudioOk = false;
        _updateStep(
          'lm_studio',
          (s) => s.copyWith(
            status: DiagnosticStepStatus.failure,
            message: 'LM Studio не отвечает: ${e.toString().split('\n').first}',
          ),
        );
      }
    } else {
      _updateStep(
        'lm_studio',
        (s) => s.copyWith(
          status: DiagnosticStepStatus.skipped,
          message: 'Пропущено: компьютер не найден',
        ),
      );
    }

    // --- 5. Model Loaded ---
    _updateStep(
      'model_loaded',
      (s) => s.copyWith(
        status: DiagnosticStepStatus.running,
        message: 'Проверка загруженных моделей...',
      ),
    );
    if (lmStudioOk) {
      if (loadedModels.isNotEmpty) {
        final nonEmbed = loadedModels.where(
          (m) => !m.toLowerCase().contains('embed'),
        );
        activeModel =
            settings.lmStudioModel.isNotEmpty &&
                loadedModels.contains(settings.lmStudioModel)
            ? settings.lmStudioModel
            : (nonEmbed.isNotEmpty ? nonEmbed.first : loadedModels.first);
        _updateStep(
          'model_loaded',
          (s) => s.copyWith(
            status: DiagnosticStepStatus.success,
            message: 'Модель загружена: $activeModel',
          ),
        );
      } else {
        _updateStep(
          'model_loaded',
          (s) => s.copyWith(
            status: DiagnosticStepStatus.failure,
            message: 'В LM Studio не загружена ни одна модель',
          ),
        );
      }
    } else {
      _updateStep(
        'model_loaded',
        (s) => s.copyWith(
          status: DiagnosticStepStatus.skipped,
          message: 'Пропущено: нет связи с LM Studio',
        ),
      );
    }

    // --- 6. GigaChat Key Configured ---
    _updateStep(
      'gigachat_key',
      (s) => s.copyWith(
        status: DiagnosticStepStatus.running,
        message: 'Проверка настроек GigaChat...',
      ),
    );
    gigaKeyOk = settings.gigaChatAuthKey.trim().isNotEmpty;
    _updateStep(
      'gigachat_key',
      (s) => s.copyWith(
        status: gigaKeyOk
            ? DiagnosticStepStatus.success
            : DiagnosticStepStatus.failure,
        message: gigaKeyOk
            ? 'Ключ GigaChat задан'
            : 'Ключ GigaChat не задан в настройках',
      ),
    );

    // --- 7. GigaChat Token Obtained ---
    _updateStep(
      'gigachat_token',
      (s) => s.copyWith(
        status: DiagnosticStepStatus.running,
        message: 'Запрос токена GigaChat...',
      ),
    );
    if (gigaKeyOk) {
      try {
        final giga = GigaChatProvider(
          authKey: settings.gigaChatAuthKey.trim(),
          baseUrl: settings.gigaChatBaseUrl.isNotEmpty
              ? settings.gigaChatBaseUrl
              : 'https://gigachat.devices.sberbank.ru',
          oauthUrl: settings.gigaChatOauthUrl.isNotEmpty
              ? settings.gigaChatOauthUrl
              : 'https://ngw.devices.sberbank.ru:9443/api/v2/oauth',
          dio: GigaChatProvider.createDioWithCert(
            certBytes: GigaChatCert.bytes,
          ),
        );
        await giga.getToken(forceRefresh: true);
        gigaTokenOk = true;
        _updateStep(
          'gigachat_token',
          (s) => s.copyWith(
            status: DiagnosticStepStatus.success,
            message: 'Токен GigaChat успешно получен',
          ),
        );
      } catch (e) {
        gigaTokenOk = false;
        final failure = e is AiException ? e.failure : mapExceptionToFailure(e);
        _updateStep(
          'gigachat_token',
          (s) => s.copyWith(
            status: DiagnosticStepStatus.failure,
            message: 'Ошибка авторизации: ${failure.message}',
          ),
        );
      }
    } else {
      _updateStep(
        'gigachat_token',
        (s) => s.copyWith(
          status: DiagnosticStepStatus.skipped,
          message: 'Пропущено: ключ GigaChat не задан',
        ),
      );
    }

    // --- 8. Test Query to Active Providers ---
    _updateStep(
      'test_query',
      (s) => s.copyWith(
        status: DiagnosticStepStatus.running,
        message: 'Выполнение пробного запроса...',
      ),
    );

    final testResults = <String>[];
    bool anySuccess = false;
    bool anyFailure = false;

    // Test LM Studio if available
    if (lmStudioOk && pcHost != null && activeModel != null) {
      try {
        final sw = Stopwatch()..start();
        final lm = LmStudioProvider(
          baseUrl: 'http://$pcHost:$pcPort',
          model: activeModel,
          apiKey: settings.lmStudioApiKey.isNotEmpty
              ? settings.lmStudioApiKey
              : null,
        );
        await lm.chat(
          const AiChatRequest(
            messages: [AiChatMessage.user('Ответь одним словом: готов')],
            temperature: 0.1,
            timeout: Duration(seconds: 5),
          ),
        );
        sw.stop();
        testResults.add('LM Studio: ОК (${sw.elapsedMilliseconds} мс)');
        anySuccess = true;
      } catch (e) {
        testResults.add(
          'LM Studio: ошибка (${e.toString().split('\n').first})',
        );
        anyFailure = true;
      }
    }

    // Test GigaChat if available
    if (gigaKeyOk && gigaTokenOk) {
      try {
        final sw = Stopwatch()..start();
        final giga = GigaChatProvider(
          authKey: settings.gigaChatAuthKey.trim(),
          model: settings.gigaChatModel.isNotEmpty
              ? settings.gigaChatModel
              : 'GigaChat-2',
          baseUrl: settings.gigaChatBaseUrl.isNotEmpty
              ? settings.gigaChatBaseUrl
              : 'https://gigachat.devices.sberbank.ru',
          oauthUrl: settings.gigaChatOauthUrl.isNotEmpty
              ? settings.gigaChatOauthUrl
              : 'https://ngw.devices.sberbank.ru:9443/api/v2/oauth',
          dio: GigaChatProvider.createDioWithCert(
            certBytes: GigaChatCert.bytes,
          ),
        );
        await giga.chat(
          const AiChatRequest(
            messages: [AiChatMessage.user('Ответь одним словом: готов')],
            temperature: 0.1,
            timeout: Duration(seconds: 5),
          ),
        );
        sw.stop();
        testResults.add('GigaChat: ОК (${sw.elapsedMilliseconds} мс)');
        anySuccess = true;
      } catch (e) {
        testResults.add('GigaChat: ошибка (${e.toString().split('\n').first})');
        anyFailure = true;
      }
    }

    if (testResults.isEmpty) {
      _updateStep(
        'test_query',
        (s) => s.copyWith(
          status: DiagnosticStepStatus.skipped,
          message: 'Пропущено: нет доступных провайдеров',
        ),
      );
    } else if (anyFailure && !anySuccess) {
      _updateStep(
        'test_query',
        (s) => s.copyWith(
          status: DiagnosticStepStatus.failure,
          message: testResults.join('\n'),
        ),
      );
    } else {
      _updateStep(
        'test_query',
        (s) => s.copyWith(
          status: DiagnosticStepStatus.success,
          message: testResults.join('\n'),
        ),
      );
    }

    // Refresh history
    await _loadHistory();

    if (mounted) {
      setState(() {
        _isRunning = false;
      });
    }
  }

  String _sanitize(String text) {
    return text
        .replaceAll(
          RegExp(r'Basic\s+[A-Za-z0-9+/=]+', caseSensitive: false),
          'Basic [СКРЫТО]',
        )
        .replaceAll(
          RegExp(r'Bearer\s+[A-Za-z0-9._\-]+', caseSensitive: false),
          'Bearer [СКРЫТО]',
        )
        .replaceAll(RegExp(r'[a-zA-Z0-9_\-]{32,}'), '[СКРЫТО]');
  }

  String _formatReason(AiRequest req) {
    if (req.status == 'ok') {
      if (req.tokensOut != null && req.tokensOut! > 0) {
        return 'Токены: ${req.tokensIn ?? 0} вход / ${req.tokensOut} выход';
      }
      return 'Успешно';
    }
    try {
      final decoded = jsonDecode(req.responseJson);
      if (decoded is Map) {
        final msg = decoded['message'] ?? decoded['reason'] ?? decoded['error'];
        if (msg != null && msg.toString().isNotEmpty) {
          return _sanitize(msg.toString());
        }
      }
    } catch (_) {}
    final raw = req.responseJson.trim();
    if (raw.isNotEmpty) {
      return _sanitize(raw.length > 120 ? '${raw.substring(0, 120)}...' : raw);
    }
    return req.status == 'error'
        ? 'Ошибка выполнения запроса'
        : 'Отклонено валидатором';
  }

  Widget _buildStepIcon(DiagnosticStepStatus status, ThemeData theme) {
    switch (status) {
      case DiagnosticStepStatus.success:
        return const Icon(
          Icons.check_circle_rounded,
          color: Colors.green,
          size: 28,
        );
      case DiagnosticStepStatus.failure:
        return Icon(
          Icons.cancel_rounded,
          color: theme.colorScheme.error,
          size: 28,
        );
      case DiagnosticStepStatus.running:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        );
      case DiagnosticStepStatus.skipped:
        return Icon(
          Icons.remove_circle_outline_rounded,
          color: theme.colorScheme.outline,
          size: 28,
        );
      case DiagnosticStepStatus.pending:
        return Icon(
          Icons.circle_outlined,
          color: theme.colorScheme.outlineVariant,
          size: 28,
        );
    }
  }

  Widget _buildStatusChip(String status, ThemeData theme) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'ok':
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.green.shade800;
        label = 'Успех';
        break;
      case 'rejected':
        bg = Colors.orange.withValues(alpha: 0.15);
        fg = Colors.orange.shade900;
        label = 'Отклонено';
        break;
      case 'error':
      default:
        bg = theme.colorScheme.errorContainer;
        fg = theme.colorScheme.onErrorContainer;
        label = 'Ошибка';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final timeFormat = DateFormat('HH:mm:ss dd.MM.yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.aiDiagnosticsTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header description
          Text(
            l10n.aiDiagnosticsSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // Diagnostic Steps List
          ..._steps.map((step) {
            return Card(
              key: Key('diagnostic_step_${step.id}'),
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.4,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStepIcon(step.status, theme),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (step.message.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              step.message,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color:
                                    step.status == DiagnosticStepStatus.failure
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (step.id == 'pc_found' &&
                              step.status == DiagnosticStepStatus.failure) ...[
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              key: const Key('btn_diagnostics_connect_qr'),
                              onPressed: () async {
                                await context.push('/settings/ai/qr-scanner');
                                await _runDiagnostics();
                              },
                              icon: const Icon(Icons.qr_code_scanner, size: 20),
                              label: Text(l10n.aiSettingsConnectQr),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Re-run Button
          SizedBox(
            height: 52,
            child: FilledButton.tonalIcon(
              key: const Key('btn_run_diagnostics'),
              onPressed: _isRunning ? null : _runDiagnostics,
              icon: _isRunning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(
                _isRunning ? l10n.aiDiagnosticsRunning : l10n.aiDiagnosticsRun,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Section: Last 10 Requests
          Text(
            l10n.aiDiagnosticsHistoryTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),

          if (_history.isEmpty)
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                child: Center(
                  child: Text(
                    l10n.aiDiagnosticsHistoryEmpty,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ),
            )
          else
            ..._history.map((req) {
              final dateTime = DateTime.fromMillisecondsSinceEpoch(req.at)
                  .toLocal();
              final formattedTime = timeFormat.format(dateTime);
              final modelDisplay = req.model.isNotEmpty
                  ? req.model
                  : 'модель не указана';

              return Card(
                key: Key('history_request_${req.id}'),
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              formattedTime,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ),
                          _buildStatusChip(req.status, theme),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.smart_toy_outlined,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${req.kind} • $modelDisplay',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatReason(req),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: req.status == 'error'
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
