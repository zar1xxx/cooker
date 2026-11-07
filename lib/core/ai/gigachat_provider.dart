import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:uuid/uuid.dart';

import 'ai_failure.dart';
import 'ai_provider.dart';

class GigaChatProvider implements AiProvider {
  GigaChatProvider({
    required this.authKey,
    this.baseUrl = 'https://gigachat.devices.sberbank.ru',
    this.oauthUrl = 'https://ngw.devices.sberbank.ru:9443/api/v2/oauth',
    this.model = 'GigaChat-2',
    Dio? dio,
    Uuid? uuid,
  }) : _dio = dio ?? Dio(),
       _uuid = uuid ?? const Uuid() {
    _validateHttps(baseUrl);
    _validateHttps(oauthUrl);
  }

  final String authKey;
  final String baseUrl;
  final String oauthUrl;
  final String model;
  final Dio _dio;
  final Uuid _uuid;

  String? _cachedToken;
  int? _tokenExpiresAtMs;
  Future<void> _requestLock = Future.value();

  @override
  String get name => 'gigachat';

  /// Exposed for testing and inspection
  Dio get dio => _dio;
  String? get cachedToken => _cachedToken;
  int? get tokenExpiresAtMs => _tokenExpiresAtMs;

  static void _validateHttps(String url) {
    final uri = Uri.parse(url);
    if (uri.scheme != 'https') {
      throw ArgumentError('GigaChat URLs must use HTTPS: $url');
    }
  }

  static Dio createDioWithCert({
    Uint8List? certBytes,
    HttpClientAdapter? adapter,
  }) {
    final dio = Dio();
    if (adapter != null) {
      dio.httpClientAdapter = adapter;
    } else if (certBytes != null) {
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final context = SecurityContext(withTrustedRoots: true);
          context.setTrustedCertificatesBytes(certBytes);
          return HttpClient(context: context);
        },
      );
    }
    return dio;
  }

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _requestLock = _requestLock.then((_) async {
      try {
        final result = await action();
        completer.complete(result);
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  Future<String> getToken({bool forceRefresh = false}) async {
    final nowMs = clock.now().millisecondsSinceEpoch;
    if (!forceRefresh &&
        _cachedToken != null &&
        _tokenExpiresAtMs != null &&
        nowMs < (_tokenExpiresAtMs! - 60000)) {
      return _cachedToken!;
    }

    final cleanKey = authKey.trim();
    if (cleanKey.isEmpty) {
      throw const AiException(AiFailure.gigaChatBadKey('Ключ GigaChat пуст'));
    }

    final rqUid = _uuid.v4();
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        oauthUrl,
        data: 'scope=GIGACHAT_API_PERS',
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
            'RqUID': rqUid,
            'Authorization': 'Basic $cleanKey',
          },
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
        ),
      );

      final data = response.data;
      if (data == null || data['access_token'] == null) {
        throw FormatException('Failed to get GigaChat OAuth token: $data');
      }

      final token = data['access_token'] as String;
      final expiresAt = (data['expires_at'] as num).toInt();

      _cachedToken = token;
      _tokenExpiresAtMs = expiresAt;
      return token;
    } catch (e) {
      if (e is AiException) rethrow;
      throw AiException(mapExceptionToFailure(e, isGigaChat: true));
    }
  }

  List<Map<String, dynamic>> _prepareMessages(AiChatRequest request) {
    final result = <Map<String, dynamic>>[];
    var schemaAppended = false;

    for (int i = 0; i < request.messages.length; i++) {
      final msg = request.messages[i];
      if (request.jsonSchema != null &&
          (msg.role == 'system' || (i == 0 && !schemaAppended))) {
        final schemaPrompt =
            '\n\nТребование к формату: ответь строго валидным JSON-объектом по следующей JSON Schema без дополнительного текста до или после:\n${jsonEncode(request.jsonSchema)}';
        result.add({
          'role': msg.role,
          'content': '${msg.content}$schemaPrompt',
        });
        schemaAppended = true;
      } else {
        result.add(msg.toJson());
      }
    }

    if (request.jsonSchema != null && !schemaAppended) {
      result.insert(0, {
        'role': 'system',
        'content':
            'Ответь строго валидным JSON-объектом по следующей JSON Schema без дополнительного текста:\n${jsonEncode(request.jsonSchema)}',
      });
    }

    return result;
  }

  @override
  Future<bool> isAvailable() async {
    if (authKey.trim().isEmpty) return false;
    try {
      await getToken();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<AiCompletionResponse> chat(AiChatRequest request) {
    return _enqueue(() => _executeChat(request));
  }

  Future<AiCompletionResponse> _executeChat(
    AiChatRequest request, {
    bool hasRetriedAuth = false,
  }) async {
    final token = await getToken(forceRefresh: hasRetriedAuth);
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = '$cleanBase/api/v1/chat/completions';

    final selectedModel = request.model ?? model;
    final messages = _prepareMessages(request);
    final body = <String, dynamic>{
      'model': selectedModel,
      'messages': messages,
      'temperature': request.temperature,
    };

    final effectiveTimeout = request.timeout ?? const Duration(seconds: 45);
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          sendTimeout: effectiveTimeout,
          receiveTimeout: effectiveTimeout,
        ),
      );
      stopwatch.stop();

      final data = response.data;
      if (data == null) {
        throw FormatException('Empty response from GigaChat at $url');
      }

      final choices = data['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        throw FormatException('No choices in GigaChat response: $data');
      }

      final firstChoice = choices.first as Map<String, dynamic>;
      final message = firstChoice['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String? ?? '';
      final responseModel = (data['model'] as String?) ?? selectedModel;

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
    } on DioException catch (e) {
      stopwatch.stop();
      if (!hasRetriedAuth && e.response?.statusCode == 401) {
        _cachedToken = null;
        _tokenExpiresAtMs = null;
        return _executeChat(request, hasRetriedAuth: true);
      }
      throw AiException(mapExceptionToFailure(e, isGigaChat: true));
    } catch (e) {
      stopwatch.stop();
      if (e is AiException) rethrow;
      throw AiException(mapExceptionToFailure(e, isGigaChat: true));
    }
  }
}
