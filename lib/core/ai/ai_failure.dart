import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

/// Sealed hierarchy of all AI failure reasons per R3-01 and ТЗ 6.1.1.
sealed class AiFailure {
  const AiFailure();

  /// Short machine/diagnostic code, e.g. 'not_configured', 'no_wifi'.
  String get code;

  /// Human-readable explanation in Russian without keys, tokens, or technical secrets.
  String get message;

  const factory AiFailure.notConfigured([String? details]) =
      AiFailureNotConfigured;
  const factory AiFailure.noWifi([String? details]) = AiFailureNoWifi;
  const factory AiFailure.pcNotFound([String? details]) = AiFailurePcNotFound;
  const factory AiFailure.pcNoModel([String? details]) = AiFailurePcNoModel;
  const factory AiFailure.gigaChatBadKey([String? details]) =
      AiFailureGigaChatBadKey;
  const factory AiFailure.gigaChatCert([String? details]) =
      AiFailureGigaChatCert;
  const factory AiFailure.noInternet([String? details]) = AiFailureNoInternet;
  const factory AiFailure.timeout([String? details]) = AiFailureTimeout;
  const factory AiFailure.badResponse([String? details]) = AiFailureBadResponse;
  const factory AiFailure.rejected(String reason) = AiFailureRejected;
}

class AiFailureNotConfigured extends AiFailure {
  final String? details;
  const AiFailureNotConfigured([this.details]);

  @override
  String get code => 'not_configured';

  @override
  String get message => details ?? 'Помощник не настроен';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiFailureNotConfigured && details == other.details;

  @override
  int get hashCode => code.hashCode ^ details.hashCode;

  @override
  String toString() => 'AiFailure.notConfigured($message)';
}

class AiFailureNoWifi extends AiFailure {
  final String? details;
  const AiFailureNoWifi([this.details]);

  @override
  String get code => 'no_wifi';

  @override
  String get message => details ?? 'Телефон не подключён к Wi-Fi';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiFailureNoWifi && details == other.details;

  @override
  int get hashCode => code.hashCode ^ details.hashCode;

  @override
  String toString() => 'AiFailure.noWifi($message)';
}

class AiFailurePcNotFound extends AiFailure {
  final String? details;
  const AiFailurePcNotFound([this.details]);

  @override
  String get code => 'pc_not_found';

  @override
  String get message => details ?? 'Компьютер не найден в сети';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiFailurePcNotFound && details == other.details;

  @override
  int get hashCode => code.hashCode ^ details.hashCode;

  @override
  String toString() => 'AiFailure.pcNotFound($message)';
}

class AiFailurePcNoModel extends AiFailure {
  final String? details;
  const AiFailurePcNoModel([this.details]);

  @override
  String get code => 'pc_no_model';

  @override
  String get message => details ?? 'На компьютере не загружена модель';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiFailurePcNoModel && details == other.details;

  @override
  int get hashCode => code.hashCode ^ details.hashCode;

  @override
  String toString() => 'AiFailure.pcNoModel($message)';
}

class AiFailureGigaChatBadKey extends AiFailure {
  final String? details;
  const AiFailureGigaChatBadKey([this.details]);

  @override
  String get code => 'gigachat_bad_key';

  @override
  String get message => details ?? 'Ключ GigaChat не подходит';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiFailureGigaChatBadKey && details == other.details;

  @override
  int get hashCode => code.hashCode ^ details.hashCode;

  @override
  String toString() => 'AiFailure.gigaChatBadKey($message)';
}

class AiFailureGigaChatCert extends AiFailure {
  final String? details;
  const AiFailureGigaChatCert([this.details]);

  @override
  String get code => 'gigachat_cert';

  @override
  String get message => details ?? 'Проблема с сертификатом Минцифры';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiFailureGigaChatCert && details == other.details;

  @override
  int get hashCode => code.hashCode ^ details.hashCode;

  @override
  String toString() => 'AiFailure.gigaChatCert($message)';
}

class AiFailureNoInternet extends AiFailure {
  final String? details;
  const AiFailureNoInternet([this.details]);

  @override
  String get code => 'no_internet';

  @override
  String get message => details ?? 'Нет подключения к интернету';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiFailureNoInternet && details == other.details;

  @override
  int get hashCode => code.hashCode ^ details.hashCode;

  @override
  String toString() => 'AiFailure.noInternet($message)';
}

class AiFailureTimeout extends AiFailure {
  final String? details;
  const AiFailureTimeout([this.details]);

  @override
  String get code => 'timeout';

  @override
  String get message => details ?? 'Превышено время ожидания ответа';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiFailureTimeout && details == other.details;

  @override
  int get hashCode => code.hashCode ^ details.hashCode;

  @override
  String toString() => 'AiFailure.timeout($message)';
}

class AiFailureBadResponse extends AiFailure {
  final String? details;
  const AiFailureBadResponse([this.details]);

  @override
  String get code => 'bad_response';

  @override
  String get message => details ?? 'Некорректный ответ помощника';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiFailureBadResponse && details == other.details;

  @override
  int get hashCode => code.hashCode ^ details.hashCode;

  @override
  String toString() => 'AiFailure.badResponse($message)';
}

class AiFailureRejected extends AiFailure {
  final String reason;
  const AiFailureRejected(this.reason);

  @override
  String get code => 'rejected';

  @override
  String get message => 'Рецепт отклонён: $reason';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiFailureRejected && reason == other.reason;

  @override
  int get hashCode => code.hashCode ^ reason.hashCode;

  @override
  String toString() => 'AiFailure.rejected($reason)';
}

/// Typed result of an AI operation that either returns [data] on success
/// or carries an [AiFailure] on error without throwing or swallowing.
sealed class AiResult<T> {
  const AiResult();

  const factory AiResult.success(T data) = AiSuccess<T>;
  const factory AiResult.failure(AiFailure failure) = AiError<T>;

  bool get isSuccess => this is AiSuccess<T>;
  bool get isFailure => this is AiError<T>;

  T? get dataOrNull => switch (this) {
    AiSuccess<T>(data: final d) => d,
    AiError<T>() => null,
  };

  AiFailure? get failureOrNull => switch (this) {
    AiSuccess<T>() => null,
    AiError<T>(failure: final f) => f,
  };

  T get data => switch (this) {
    AiSuccess<T>(data: final d) => d,
    AiError<T>(failure: final f) => throw StateError(
      'Cannot get data from failure result: $f',
    ),
  };

  AiFailure get failure => switch (this) {
    AiSuccess<T>() => throw StateError(
      'Cannot get failure from success result',
    ),
    AiError<T>(failure: final f) => f,
  };

  R when<R>({
    required R Function(T data) success,
    required R Function(AiFailure failure) failure,
  }) {
    return switch (this) {
      AiSuccess<T>(data: final d) => success(d),
      AiError<T>(failure: final f) => failure(f),
    };
  }
}

class AiSuccess<T> extends AiResult<T> {
  @override
  final T data;
  const AiSuccess(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiSuccess<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'AiSuccess($data)';
}

class AiError<T> extends AiResult<T> {
  @override
  final AiFailure failure;
  const AiError(this.failure);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiError<T> &&
          runtimeType == other.runtimeType &&
          failure == other.failure;

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'AiError($failure)';
}

/// Exception wrapping [AiFailure] for propagation inside router/providers.
class AiException implements Exception {
  final AiFailure failure;
  const AiException(this.failure);

  @override
  String toString() => 'AiException(${failure.code}: ${failure.message})';
}

/// Maps arbitrary network and protocol exceptions to a concrete [AiFailure].
AiFailure mapExceptionToFailure(
  Object error, {
  bool isGigaChat = false,
  String? host,
}) {
  if (error is AiException) {
    return error.failure;
  }
  if (error is AiFailure) {
    return error;
  }

  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status == 401 || status == 403) {
      return const AiFailure.gigaChatBadKey();
    }
    if (status == 400) {
      final msg = error.response?.data?.toString().toLowerCase() ?? '';
      if (msg.contains('model') || msg.contains('not found')) {
        return const AiFailure.pcNoModel();
      }
    }

    final inner = error.error;
    if (inner is HandshakeException ||
        inner is TlsException ||
        error.message?.contains('HandshakeException') == true ||
        error.message?.contains('CERTIFICATE_VERIFY_FAILED') == true) {
      return const AiFailure.gigaChatCert();
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      if (!isGigaChat) {
        return const AiFailure.timeout(
          'Компьютер долго отвечает (превышено время ожидания)',
        );
      }
      return const AiFailure.timeout();
    }

    if (error.type == DioExceptionType.connectionError ||
        inner is SocketException) {
      if (isGigaChat) {
        return const AiFailure.noInternet();
      } else {
        return const AiFailure.pcNotFound();
      }
    }

    if (error.type == DioExceptionType.badResponse) {
      return const AiFailure.badResponse();
    }
  }

  if (error is HandshakeException || error is TlsException) {
    return const AiFailure.gigaChatCert();
  }

  if (error is TimeoutException) {
    if (!isGigaChat) {
      return const AiFailure.timeout(
        'Компьютер долго отвечает (превышено время ожидания)',
      );
    }
    return const AiFailure.timeout();
  }

  if (error is SocketException) {
    if (isGigaChat) {
      return const AiFailure.noInternet();
    } else {
      return const AiFailure.pcNotFound();
    }
  }

  if (error is FormatException) {
    return const AiFailure.badResponse();
  }

  return const AiFailure.badResponse();
}
