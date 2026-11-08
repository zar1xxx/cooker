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

class LmStudioProvider implements AiProvider {
  LmStudioProvider({required this.baseUrl, this.model, this.apiKey, Dio? dio})
    : _dio = dio ?? Dio();

  final String baseUrl;
  final String? model;
  final String? apiKey;
  final Dio _dio;

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
    String resolvedModel,
  ) {
    final messages = request.messages.map((m) => m.toJson()).toList();
    final body = <String, dynamic>{
      'model': resolvedModel,
      'messages': messages,
      'temperature': request.temperature,
      'stream': false,
    };

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
    final body = _buildChatBody(request, selectedModel);

    final stopwatch = Stopwatch()..start();
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        data: body,
        options: _buildOptions(timeout: request.timeout),
      );
      stopwatch.stop();

      final data = response.data;
      if (data == null) {
        throw FormatException('Empty response from LM Studio at $url');
      }

      final choices = data['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        throw FormatException('No choices in LM Studio response: $data');
      }

      final firstChoice = choices.first as Map<String, dynamic>;
      final message = firstChoice['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String?;
      final reasoningContent = message?['reasoning_content'] as String?;
      final effectiveContent = selectEffectiveContent(
        content: content,
        reasoningContent: reasoningContent,
      );
      if (effectiveContent.trim().isEmpty) {
        throw const AiException(
          AiFailure.badResponse(
            'Пустой ответ от LM Studio (content и reasoning_content пустые)',
          ),
        );
      }
      final finishReason = firstChoice['finish_reason'] as String?;
      final responseModel =
          (data['model'] as String?) ?? request.model ?? selectedModel;

      int promptTokens = 0;
      int completionTokens = 0;
      int totalTokens = 0;
      if (data['usage'] is Map) {
        final usage = data['usage'] as Map;
        promptTokens = (usage['prompt_tokens'] as num?)?.toInt() ?? 0;
        completionTokens = (usage['completion_tokens'] as num?)?.toInt() ?? 0;
        totalTokens =
            (usage['total_tokens'] as num?)?.toInt() ??
            (promptTokens + completionTokens);
      }

      return AiCompletionResponse(
        rawContent: effectiveContent,
        model: responseModel,
        providerName: name,
        finishReason: finishReason,
        promptTokens: promptTokens,
        completionTokens: completionTokens,
        totalTokens: totalTokens,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      if (e is AiException) rethrow;
      throw AiException(mapExceptionToFailure(e, isGigaChat: false));
    }
  }
}
