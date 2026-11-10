import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import 'ai_failure.dart';
import 'ai_provider.dart';

bool isPrivateOrLocalHost(String host) {
  final cleanHost = host.trim().toLowerCase();
  if (cleanHost == 'localhost' ||
      cleanHost == '127.0.0.1' ||
      cleanHost == '::1') {
    return true;
  }
  if (cleanHost.endsWith('.local')) {
    return true;
  }

  final ip = InternetAddress.tryParse(cleanHost);
  if (ip == null) {
    return false;
  }

  if (ip.type == InternetAddressType.IPv4) {
    final raw = ip.rawAddress;
    // 10.0.0.0/8
    if (raw[0] == 10) return true;
    // 172.16.0.0/12 (172.16.0.0 – 172.31.255.255)
    if (raw[0] == 172 && raw[1] >= 16 && raw[1] <= 31) return true;
    // 192.168.0.0/16
    if (raw[0] == 192 && raw[1] == 168) return true;
    // 127.0.0.0/8
    if (raw[0] == 127) return true;
  } else if (ip.type == InternetAddressType.IPv6) {
    if (ip.isLoopback || ip.isLinkLocal) return true;
  }

  return false;
}

class LmStudioModelInfo {
  final String id;
  final int? contextLength;
  final int? parallel;
  final bool isReasoning;

  const LmStudioModelInfo({
    required this.id,
    this.contextLength,
    this.parallel,
    this.isReasoning = false,
  });
}

class LmStudioProvider implements AiProvider {
  LmStudioProvider({
    required this.baseUrl,
    this.model,
    this.apiKey,
    Dio? dio,
    this.inactivityTimeout = const Duration(seconds: 15),
    this.overallTimeout = const Duration(seconds: 90),
  }) : _dio = dio ?? Dio();

  final String baseUrl;
  final String? model;
  final String? apiKey;
  final Dio _dio;
  final Duration inactivityTimeout;
  final Duration overallTimeout;

  String? _cachedAutoModel;

  /// The automatically discovered model id if [model] was not specified.
  String? get cachedAutoModel => _cachedAutoModel;

  @override
  String get name => 'lm_studio';

  static String sanitizeBaseUrl(String url) {
    var s = url.trim();
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  void _validateUrl(String url) {
    final uri = Uri.parse(url);
    if (uri.scheme == 'http') {
      if (!isPrivateOrLocalHost(uri.host)) {
        throw ArgumentError(
          'Cleartext HTTP is only permitted for local/private network addresses: ${uri.host}',
        );
      }
    }
  }

  Options _buildOptions({Duration? timeout}) {
    final headers = <String, dynamic>{
      'Content-Type': 'application/json',
      if (apiKey != null && apiKey!.trim().isNotEmpty)
        'Authorization': 'Bearer ${apiKey!.trim()}',
    };
    final effectiveTimeout = timeout ?? const Duration(seconds: 45);
    return Options(
      headers: headers,
      connectTimeout: effectiveTimeout,
      sendTimeout: effectiveTimeout,
      receiveTimeout: effectiveTimeout,
    );
  }

  /// Resolves the model to use:
  /// 1. [requestedModel] if provided in request.
  /// 2. [model] configured in constructor.
  /// 3. [_cachedAutoModel] if previously auto-selected.
  /// 4. Queries `GET /api/v0/models` (or `GET /api/v1/models`) for loaded models.
  /// Throws [AiException] with [AiFailure.pcNoModel] if no models are loaded.
  Future<String> resolveModel({
    String? requestedModel,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (requestedModel != null && requestedModel.trim().isNotEmpty) {
      return requestedModel.trim();
    }
    if (model != null && model!.trim().isNotEmpty) {
      return model!.trim();
    }
    if (_cachedAutoModel != null && _cachedAutoModel!.trim().isNotEmpty) {
      return _cachedAutoModel!;
    }

    final loadedModels = await getLoadedModels(timeout: timeout);
    if (loadedModels.isEmpty) {
      throw const AiException(
        AiFailure.pcNoModel('На компьютере не загружена модель'),
      );
    }

    final selected = loadedModels.first;
    _cachedAutoModel = selected;
    return selected;
  }

  /// Queries loaded models from LM Studio:
  /// First tries `GET /api/v0/models` filtering by `state == "loaded"` and `type == "llm"` (or "vlm").
  /// If that endpoint fails, tries `GET /api/v1/models` checking non-empty `loaded_instances`.
  /// Excludes embedding models. Returns empty list if no models are loaded.
  Future<List<String>> getLoadedModels({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final cleanBase = sanitizeBaseUrl(baseUrl);
    _validateUrl(cleanBase);

    // 1. Try GET /api/v0/models
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$cleanBase/api/v0/models',
        options: _buildOptions(timeout: timeout),
      );
      final data = response.data?['data'];
      if (data is List) {
        final loaded = data
            .whereType<Map<dynamic, dynamic>>()
            .where((m) {
              final state = m['state'] as String?;
              final type = m['type'] as String?;
              return state == 'loaded' && (type == 'llm' || type == 'vlm');
            })
            .map((m) => m['id'] as String?)
            .whereType<String>()
            .where((id) => !id.toLowerCase().contains('embed'))
            .toList();
        if (loaded.isNotEmpty) {
          return loaded;
        }
      }
    } catch (_) {
      // Fall through to /api/v1/models
    }

    // 2. Try GET /api/v1/models
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$cleanBase/api/v1/models',
        options: _buildOptions(timeout: timeout),
      );
      final models = response.data?['models'];
      if (models is List) {
        final loaded = <String>[];
        for (final m in models.whereType<Map<dynamic, dynamic>>()) {
          final type = m['type'] as String?;
          if (type != 'llm' && type != 'vlm') continue;
          final instances = m['loaded_instances'];
          if (instances is List && instances.isNotEmpty) {
            final firstInst = instances.first;
            String? id;
            if (firstInst is Map && firstInst['id'] is String) {
              id = firstInst['id'] as String;
            } else if (m['key'] is String) {
              id = m['key'] as String;
            }
            if (id != null && !id.toLowerCase().contains('embed')) {
              loaded.add(id);
            }
          }
        }
        if (loaded.isNotEmpty) {
          return loaded;
        }
      }
    } catch (_) {
      // Fall through
    }

    return [];
  }

  Map<String, dynamic> _buildChatBody(
    AiChatRequest request,
    String resolvedModel, {
    bool stream = true,
  }) {
    final messages = request.messages.map((m) => m.toJson()).toList();
    final body = <String, dynamic>{
      'model': resolvedModel,
      'messages': messages,
      'temperature': request.temperature,
      'stream': stream,
    };

    if (stream) {
      body['stream_options'] = {'include_usage': true};
    }

    if (request.disableReasoning) {
      body['chat_template_kwargs'] = {'enable_thinking': false};
      body['reasoning_effort'] = 'none';
    }

    if (request.maxTokens != null) {
      body['max_tokens'] = request.maxTokens;
    }

    if (request.jsonSchema != null) {
      body['response_format'] = {
        'type': 'json_schema',
        'json_schema': {
          'name': request.schemaName ?? 'structured_output',
          'strict': true,
          'schema': request.jsonSchema,
        },
      };
    }

    return body;
  }

  Future<List<String>> getModels({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final cleanBase = sanitizeBaseUrl(baseUrl);
    _validateUrl(cleanBase);
    final url = '$cleanBase/v1/models';

    final response = await _dio.get<Map<String, dynamic>>(
      url,
      options: _buildOptions(timeout: timeout),
    );

    final data = response.data?['data'];
    if (data is List) {
      return data
          .map((item) {
            if (item is Map) {
              return item['id'] as String?;
            }
            return null;
          })
          .whereType<String>()
          .toList();
    }
    return [];
  }

  /// Measures pure network round-trip time to LM Studio via `GET /v1/models` in milliseconds.
  Future<int> ping({Duration timeout = const Duration(seconds: 3)}) async {
    final sw = Stopwatch()..start();
    await getModels(timeout: timeout);
    sw.stop();
    return sw.elapsedMilliseconds;
  }

  /// Queries LM Studio for loaded model details (context length, parallel, reasoning flag).
  Future<LmStudioModelInfo?> getLoadedModelInfo({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final cleanBase = sanitizeBaseUrl(baseUrl);
    _validateUrl(cleanBase);

    // 1. Try GET /api/v0/models
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$cleanBase/api/v0/models',
        options: _buildOptions(timeout: timeout),
      );
      final data = response.data?['data'];
      if (data is List) {
        for (final m in data.whereType<Map<dynamic, dynamic>>()) {
          final state = m['state'] as String?;
          if (state == 'loaded') {
            final id = (m['id'] as String?) ?? '';
            final ctx =
                (m['loaded_context_length'] as num?)?.toInt() ??
                (m['max_context_length'] as num?)?.toInt();
            final parallel =
                (m['parallel'] as num?)?.toInt() ??
                (m['parallelism'] as num?)?.toInt() ??
                ((m['instances'] as List?)?.length) ??
                1;
            final isReasoning = RegExp(
              r'(ornith|deepseek-r1|qwq|thinking|reason)',
              caseSensitive: false,
            ).hasMatch(id);
            return LmStudioModelInfo(
              id: id,
              contextLength: ctx,
              parallel: parallel,
              isReasoning: isReasoning,
            );
          }
        }
      }
    } catch (_) {
      // Fall through
    }

    // 2. Try GET /api/v1/models
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$cleanBase/api/v1/models',
        options: _buildOptions(timeout: timeout),
      );
      final models = response.data?['models'];
      if (models is List) {
        for (final m in models.whereType<Map<dynamic, dynamic>>()) {
          final instances = m['loaded_instances'];
          if (instances is List && instances.isNotEmpty) {
            final first = instances.first;
            final id =
                (first is Map ? first['id'] : null) as String? ??
                (m['key'] as String?) ??
                '';
            final ctx = first is Map
                ? (first['context_length'] as num?)?.toInt()
                : null;
            final parallel = instances.length;
            final isReasoning = RegExp(
              r'(ornith|deepseek-r1|qwq|thinking|reason)',
              caseSensitive: false,
            ).hasMatch(id);
            return LmStudioModelInfo(
              id: id,
              contextLength: ctx,
              parallel: parallel,
              isReasoning: isReasoning,
            );
          }
        }
      }
    } catch (_) {
      // Fall through
    }

    // 3. Fallback to /v1/models
    final models = await getModels(timeout: timeout);
    if (models.isNotEmpty) {
      final id = models.first;
      final isReasoning = RegExp(
        r'(ornith|deepseek-r1|qwq|thinking|reason)',
        caseSensitive: false,
      ).hasMatch(id);
      return LmStudioModelInfo(
        id: id,
        contextLength: null,
        parallel: 1,
        isReasoning: isReasoning,
      );
    }

    return null;
  }

  @override
  Future<bool> isAvailable() async {
    try {
      final resolved = await resolveModel(
        timeout: const Duration(milliseconds: 1500),
      );
      return resolved.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static bool _canParseJson(String text) {
    if (text.trim().isEmpty) return false;
    try {
      final payload = extractJsonPayload(text);
      jsonDecode(payload);
      return true;
    } catch (_) {
      return false;
    }
  }

  static String selectEffectiveContent({
    required String? content,
    required String? reasoningContent,
  }) {
    final c = content ?? '';
    final r = reasoningContent ?? '';

    final cIsJson = _canParseJson(c);
    final rIsJson = _canParseJson(r);

    if ((c.trim().isEmpty || !cIsJson) && rIsJson) {
      return r;
    }
    if (c.trim().isNotEmpty) {
      return c;
    }
    if (r.trim().isNotEmpty) {
      return r;
    }
    return '';
  }

  @override
  Future<AiCompletionResponse> chat(AiChatRequest request) async {
    final cleanBase = sanitizeBaseUrl(baseUrl);
    _validateUrl(cleanBase);

    final selectedModel = await resolveModel(
      requestedModel: request.model,
      timeout: request.timeout ?? const Duration(seconds: 5),
    );

    final url = '$cleanBase/v1/chat/completions';
    final body = _buildChatBody(request, selectedModel, stream: true);

    final cancelToken = CancelToken();
    Timer? inactivityTimer;
    Timer? overallTimer;
    bool timedOut = false;
    String timeoutMessage = '';

    void cancelTimers() {
      inactivityTimer?.cancel();
      inactivityTimer = null;
      overallTimer?.cancel();
      overallTimer = null;
    }

    final contentBuffer = StringBuffer();
    final reasoningBuffer = StringBuffer();
    String? finishReason;
    String? responseModel;
    int promptTokens = 0;
    int completionTokens = 0;
    int totalTokens = 0;
    int? reasoningTokens;
    Duration? timeToFirstToken;

    final stopwatch = Stopwatch()..start();
    final completer = Completer<void>();
    StreamSubscription<String>? sub;

    void onTimeout(String msg) {
      timedOut = true;
      timeoutMessage = msg;
      cancelTimers();
      sub?.cancel();
      if (!cancelToken.isCancelled) {
        cancelToken.cancel(msg);
      }
      if (!completer.isCompleted) {
        completer.completeError(AiException(AiFailure.timeout(msg)));
      }
    }

    void resetInactivityTimer() {
      inactivityTimer?.cancel();
      inactivityTimer = Timer(inactivityTimeout, () {
        onTimeout(
          'Превышено время ожидания токена от LM Studio (15 с без новых данных)',
        );
      });
    }

    overallTimer = Timer(request.timeout ?? overallTimeout, () {
      onTimeout('Превышено общее время ожидания ответа от LM Studio (90 с)');
    });
    resetInactivityTimer();

    unawaited(
      cancelToken.whenCancel.then((_) {
        sub?.cancel();
        cancelTimers();
      }),
    );

    try {
      final response = await _dio.post<ResponseBody>(
        url,
        data: body,
        cancelToken: cancelToken,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'text/event-stream',
            if (apiKey != null && apiKey!.trim().isNotEmpty)
              'Authorization': 'Bearer ${apiKey!.trim()}',
          },
          responseType: ResponseType.stream,
        ),
      );

      final responseBody = response.data;
      if (responseBody == null) {
        throw FormatException('Empty response stream from LM Studio at $url');
      }

      final linesStream = responseBody.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      sub = linesStream.listen(
        (line) {
          resetInactivityTimer();

          final trimmed = line.trim();
          if (trimmed.isEmpty) return;

          String jsonPayload = trimmed;
          if (trimmed.startsWith('data:')) {
            jsonPayload = trimmed.substring('data:'.length).trim();
          }
          if (jsonPayload.isEmpty || jsonPayload == '[DONE]') {
            if (jsonPayload == '[DONE]') {
              sub?.cancel();
              if (!completer.isCompleted) completer.complete();
            }
            return;
          }

          try {
            final chunk = jsonDecode(jsonPayload);
            if (chunk is Map<String, dynamic>) {
              if (chunk['model'] is String) {
                responseModel = chunk['model'] as String;
              }

              final choices = chunk['choices'];
              if (choices is List && choices.isNotEmpty) {
                final firstChoice = choices.first;
                if (firstChoice is Map) {
                  // 1. Streaming delta
                  final delta = firstChoice['delta'];
                  if (delta is Map) {
                    final c = delta['content'] as String?;
                    final r = delta['reasoning_content'] as String?;
                    if ((c != null && c.isNotEmpty) ||
                        (r != null && r.isNotEmpty)) {
                      timeToFirstToken ??= stopwatch.elapsed;
                    }
                    if (c != null) contentBuffer.write(c);
                    if (r != null) reasoningBuffer.write(r);
                  }

                  // 2. Non-streaming message (for mocks or fallback)
                  final message = firstChoice['message'];
                  if (message is Map) {
                    final c = message['content'] as String?;
                    final r = message['reasoning_content'] as String?;
                    if ((c != null && c.isNotEmpty) ||
                        (r != null && r.isNotEmpty)) {
                      timeToFirstToken ??= stopwatch.elapsed;
                    }
                    if (c != null) contentBuffer.write(c);
                    if (r != null) reasoningBuffer.write(r);
                  }

                  final fr = firstChoice['finish_reason'] as String?;
                  if (fr != null && fr.isNotEmpty) {
                    finishReason = fr;
                  }
                }
              }

              final usage = chunk['usage'];
              if (usage is Map) {
                promptTokens =
                    (usage['prompt_tokens'] as num?)?.toInt() ?? promptTokens;
                completionTokens =
                    (usage['completion_tokens'] as num?)?.toInt() ??
                    completionTokens;
                totalTokens =
                    (usage['total_tokens'] as num?)?.toInt() ?? totalTokens;
                final details = usage['completion_tokens_details'];
                if (details is Map) {
                  reasoningTokens =
                      (details['reasoning_tokens'] as num?)?.toInt() ??
                      reasoningTokens;
                }
              }
            }
          } catch (_) {
            // Ignore partial or non-JSON chunk
          }
        },
        onError: (Object error, StackTrace st) {
          cancelTimers();
          if (!completer.isCompleted) completer.completeError(error, st);
        },
        onDone: () {
          cancelTimers();
          if (!completer.isCompleted) completer.complete();
        },
        cancelOnError: true,
      );

      await completer.future;

      stopwatch.stop();
      cancelTimers();

      final effectiveContent = selectEffectiveContent(
        content: contentBuffer.toString(),
        reasoningContent: reasoningBuffer.toString(),
      );

      if (effectiveContent.trim().isEmpty) {
        throw const AiException(
          AiFailure.badResponse(
            'Пустой ответ от LM Studio (content и reasoning_content пустые)',
          ),
        );
      }

      if (totalTokens == 0 && (promptTokens > 0 || completionTokens > 0)) {
        totalTokens = promptTokens + completionTokens;
      }

      return AiCompletionResponse(
        rawContent: effectiveContent,
        model: responseModel ?? request.model ?? selectedModel,
        providerName: name,
        finishReason: finishReason,
        promptTokens: promptTokens,
        completionTokens: completionTokens,
        totalTokens: totalTokens,
        reasoningTokens: reasoningTokens,
        duration: stopwatch.elapsed,
        timeToFirstToken: timeToFirstToken,
      );
    } catch (e) {
      stopwatch.stop();
      cancelTimers();
      if (timedOut) {
        throw AiException(AiFailure.timeout(timeoutMessage));
      }
      if (cancelToken.isCancelled) {
        throw AiException(
          AiFailure.timeout(
            timeoutMessage.isNotEmpty
                ? timeoutMessage
                : 'Запрос к LM Studio был прерван по таймауту',
          ),
        );
      }
      if (e is AiException) rethrow;
      throw AiException(mapExceptionToFailure(e, isGigaChat: false));
    }
  }
}
