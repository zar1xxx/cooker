import 'dart:convert';

class AiChatMessage {
  const AiChatMessage({required this.role, required this.content});

  const AiChatMessage.system(this.content) : role = 'system';
  const AiChatMessage.user(this.content) : role = 'user';
  const AiChatMessage.assistant(this.content) : role = 'assistant';

  final String role;
  final String content;

  Map<String, dynamic> toJson() => {'role': role, 'content': content};

  factory AiChatMessage.fromJson(Map<String, dynamic> json) {
    return AiChatMessage(
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
    );
  }

  @override
  String toString() => 'AiChatMessage($role: $content)';
}

class AiChatRequest {
  const AiChatRequest({
    required this.messages,
    this.model,
    this.temperature = 0.7,
    this.maxTokens,
    this.timeout,
    this.jsonSchema,
    this.schemaName,
    this.disableReasoning = false,
  });

  final List<AiChatMessage> messages;
  final String? model;
  final double temperature;
  final int? maxTokens;
  final Duration? timeout;
  final Map<String, dynamic>? jsonSchema;
  final String? schemaName;
  final bool disableReasoning;
}

class AiCompletionResponse {
  const AiCompletionResponse({
    required this.rawContent,
    required this.model,
    required this.providerName,
    this.finishReason,
    this.promptTokens = 0,
    this.completionTokens = 0,
    this.totalTokens = 0,
    this.reasoningTokens,
    this.duration = Duration.zero,
    this.timeToFirstToken,
  });

  final String rawContent;
  final String model;
  final String providerName;
  final String? finishReason;
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final int? reasoningTokens;
  final Duration duration;
  final Duration? timeToFirstToken;

  /// Extracts clean JSON from `rawContent`, removing Markdown fences and surrounding comments.
  String get jsonPayload => extractJsonPayload(rawContent);

  /// Decodes `jsonPayload` as `Map<String, dynamic>`.
  Map<String, dynamic> decodeJson() {
    final payload = jsonPayload;
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Expected JSON object, got ${decoded.runtimeType}');
    }
    return decoded;
  }
}

/// Extracts a JSON object `{...}` or array `[...]` from raw model output,
/// stripping Markdown code fences and peripheral chat text.
String extractJsonPayload(String text) {
  var s = text.trim();

  // Try extracting from markdown ```json ... ``` code fence first
  final codeBlockRegex = RegExp(
    r'```(?:json)?\s*([\s\S]*?)\s*```',
    caseSensitive: false,
  );
  final match = codeBlockRegex.firstMatch(s);
  if (match != null) {
    final extracted = match.group(1)?.trim();
    if (extracted != null && extracted.isNotEmpty) {
      s = extracted;
    }
  }

  // Look for outermost JSON object {...} or array [...]
  final firstBrace = s.indexOf('{');
  final firstBracket = s.indexOf('[');
  int startIdx = -1;
  int endIdx = -1;

  if (firstBrace != -1 && (firstBracket == -1 || firstBrace < firstBracket)) {
    startIdx = firstBrace;
    endIdx = s.lastIndexOf('}');
  } else if (firstBracket != -1) {
    startIdx = firstBracket;
    endIdx = s.lastIndexOf(']');
  }

  if (startIdx != -1 && endIdx != -1 && endIdx >= startIdx) {
    return s.substring(startIdx, endIdx + 1).trim();
  }

  return s;
}

abstract class AiProvider {
  String get name;
  Future<AiCompletionResponse> chat(AiChatRequest request);
  Future<bool> isAvailable();
}
