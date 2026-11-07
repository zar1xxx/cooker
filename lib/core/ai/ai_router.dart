import 'dart:async';

import 'package:clock/clock.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'ai_failure.dart';
import 'ai_provider.dart';
import 'gigachat_provider.dart';
import 'lm_studio_provider.dart';

enum AiMode {
  localPc, // Домашний ПК (LM Studio)
  gigaChat, // GigaChat API
  offline, // Только локальный каталог (без ИИ)
}

class AiRouter {
  AiRouter({
    this.lmStudioProvider,
    this.gigaChatProvider,
    Connectivity? connectivity,
    Future<void>? ready,
  }) : _connectivity = connectivity ?? Connectivity(),
       _readyFuture = ready;

  LmStudioProvider? lmStudioProvider;
  GigaChatProvider? gigaChatProvider;
  final Connectivity _connectivity;

  Future<void>? _readyFuture;

  /// Future that completes when initial settings have been applied to the router.
  Future<void> get ready => _readyFuture ?? Future.value();

  void setReadyFuture(Future<void> future) {
    _readyFuture = future;
  }

  DateTime? _lastPcSuccess;
  DateTime? _lastPcFailure;

  DateTime? get lastPcSuccess => _lastPcSuccess;
  DateTime? get lastPcFailure => _lastPcFailure;

  void markPcSuccess([DateTime? when]) {
    _lastPcSuccess = when ?? clock.now();
    _lastPcFailure = null;
  }

  void markPcFailure([DateTime? when]) {
    _lastPcFailure = when ?? clock.now();
  }

  Future<bool> isWifiConnected() async {
    final status = await _connectivity.checkConnectivity();
    return status.contains(ConnectivityResult.wifi);
  }

  /// Determines the active provider and why resolution succeeded or failed.
  Future<({AiProvider? provider, AiFailure? failure})> determineProvider({
    Duration healthCheckTimeout = const Duration(milliseconds: 1500),
  }) async {
    await ready;
    final now = clock.now();
    final onWifi = await isWifiConnected();
    final hasLm = lmStudioProvider != null;
    final hasGiga =
        gigaChatProvider != null && gigaChatProvider!.authKey.trim().isNotEmpty;

    // 0. Neither provider configured
    if (!hasLm && !hasGiga) {
      return (provider: null, failure: const AiFailure.notConfigured());
    }

    // 1. LM Studio configured
    if (hasLm) {
      if (!onWifi) {
        if (hasGiga) {
          return (provider: gigaChatProvider, failure: null);
        }
        return (provider: null, failure: const AiFailure.noWifi());
      }

      final pcFailedRecently =
          _lastPcFailure != null &&
          now.difference(_lastPcFailure!) < const Duration(seconds: 60);

      if (pcFailedRecently) {
        if (hasGiga) {
          return (provider: gigaChatProvider, failure: null);
        }
        return (provider: null, failure: const AiFailure.pcNotFound());
      }

      final pcVerifiedRecently =
          _lastPcSuccess != null &&
          now.difference(_lastPcSuccess!) < const Duration(seconds: 60);

      if (pcVerifiedRecently) {
        return (provider: lmStudioProvider, failure: null);
      }

      // 1.5s health-check
      try {
        final models = await lmStudioProvider!.getModels(
          timeout: healthCheckTimeout,
        );
        if (models.isNotEmpty) {
          markPcSuccess(now);
          return (provider: lmStudioProvider, failure: null);
        } else {
          markPcFailure(now);
          if (hasGiga) {
            return (provider: gigaChatProvider, failure: null);
          }
          return (provider: null, failure: const AiFailure.pcNoModel());
        }
      } catch (e) {
        markPcFailure(now);
        if (hasGiga) {
          return (provider: gigaChatProvider, failure: null);
        }
        final failure = mapExceptionToFailure(e, isGigaChat: false);
        return (provider: null, failure: failure);
      }
    }

    // 2. GigaChat fallback
    if (hasGiga) {
      return (provider: gigaChatProvider, failure: null);
    }

    return (provider: null, failure: const AiFailure.notConfigured());
  }

  /// Chooses active provider based on rules of TZ 6.1.1:
  /// - Wi-Fi + PC checked < 60s -> LM Studio
  /// - Wi-Fi + check missing or > 60s -> 1.5s health-check -> LM Studio or GigaChat
  /// - No Wi-Fi -> GigaChat
  /// - PC failed recently (< 60s) -> GigaChat
  /// - If neither configured -> null (offline local catalog)
  Future<AiProvider?> getActiveProvider({
    Duration healthCheckTimeout = const Duration(milliseconds: 1500),
  }) async {
    final result = await determineProvider(
      healthCheckTimeout: healthCheckTimeout,
    );
    return result.provider;
  }

  /// Returns current operational mode for UI indicator
  Future<AiMode> getMode() async {
    await ready;
    final provider = await getActiveProvider();
    if (provider is LmStudioProvider) return AiMode.localPc;
    if (provider is GigaChatProvider) return AiMode.gigaChat;
    return AiMode.offline;
  }

  /// Executes chat request with automatic fallback from LM Studio to GigaChat on network/timeout failure
  Future<AiCompletionResponse> executeChatWithFallback(
    AiChatRequest request, {
    String? Function(String rawPayload)? validateContent,
  }) async {
    final resolution = await determineProvider();
    final primary = resolution.provider;
    if (primary == null) {
      throw AiException(resolution.failure ?? const AiFailure.notConfigured());
    }

    if (primary is LmStudioProvider) {
      try {
        final response = await _attemptWithRetry(
          primary,
          request,
          validateContent,
        );
        markPcSuccess();
        return response;
      } catch (e) {
        // TZ 6.1.1 p.4: invalid JSON twice on LM Studio -> GigaChat.
        // The PC itself is reachable, so do not mark as failed for format errors.
        final isFormatError =
            e is FormatException ||
            (e is AiException && e.failure is AiFailureBadResponse);
        if (!isFormatError) {
          markPcFailure();
        }

        // Fallback to GigaChat
        if (gigaChatProvider != null &&
            gigaChatProvider!.authKey.trim().isNotEmpty) {
          try {
            return await _attemptWithRetry(
              gigaChatProvider!,
              request,
              validateContent,
            );
          } catch (gigaErr) {
            if (gigaErr is AiException) rethrow;
            throw AiException(mapExceptionToFailure(gigaErr, isGigaChat: true));
          }
        }

        if (e is AiException) rethrow;
        throw AiException(mapExceptionToFailure(e, isGigaChat: false));
      }
    } else {
      try {
        return await _attemptWithRetry(primary, request, validateContent);
      } catch (err) {
        if (err is AiException) rethrow;
        throw AiException(
          mapExceptionToFailure(err, isGigaChat: primary is GigaChatProvider),
        );
      }
    }
  }

  Future<AiCompletionResponse> _attemptWithRetry(
    AiProvider provider,
    AiChatRequest request,
    String? Function(String rawPayload)? validateContent,
  ) async {
    final firstResponse = await provider.chat(request);

    if (validateContent == null) {
      return firstResponse;
    }

    final validationError = validateContent(firstResponse.rawContent);
    if (validationError == null) {
      return firstResponse;
    }

    // 1 retry on same provider with error message
    final retryMessages = [
      ...request.messages,
      AiChatMessage.assistant(firstResponse.rawContent),
      AiChatMessage.user(
        'Ответ не соответствует формату: $validationError. Исправь ошибку и ответь строго валидным JSON.',
      ),
    ];

    final retryRequest = AiChatRequest(
      messages: retryMessages,
      model: request.model,
      temperature: request.temperature,
      timeout: request.timeout,
      jsonSchema: request.jsonSchema,
      schemaName: request.schemaName,
    );

    final secondResponse = await provider.chat(retryRequest);
    final secondError = validateContent(secondResponse.rawContent);
    if (secondError != null) {
      throw FormatException('AI response validation failed: $secondError');
    }

    return secondResponse;
  }
}
