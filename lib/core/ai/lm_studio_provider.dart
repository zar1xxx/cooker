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
    final effectiveTimeout = timeout ?? const Duration(seconds: 60);
    return Options(
      headers: headers,
      connectTimeout: effectiveTimeout,
      sendTimeout: effectiveTimeout,
      receiveTimeout: effectiveTimeout,
    );
  }

  Map<String, dynamic> _buildChatBody(AiChatRequest request) {
    final selectedModel = request.model ?? model ?? 'default';
    final messages = request.messages.map((m) => m.toJson()).toList();
    final body = <String, dynamic>{
      'model': selectedModel,
      'messages': messages,
      'temperature': request.temperature,
      'stream': false,
    };

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
      final models = await getModels(
        timeout: const Duration(milliseconds: 1500),
      );
      return models.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<AiCompletionResponse> chat(AiChatRequest request) async {
    final cleanBase = sanitizeBaseUrl(baseUrl);
    _validateUrl(cleanBase);
    final url = '$cleanBase/v1/chat/completions';
    final body = _buildChatBody(request);

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
      final content = message?['content'] as String? ?? '';
      final responseModel =
          (data['model'] as String?) ?? request.model ?? model ?? 'lm_studio';

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
        rawContent: content,
        model: responseModel,
        providerName: name,
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
