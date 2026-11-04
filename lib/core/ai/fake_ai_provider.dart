import 'dart:collection';
import 'dart:io';

import 'ai_provider.dart';

class FakeAiProvider implements AiProvider {
  FakeAiProvider({
    Map<String, String>? initialFixtures,
    String? defaultFixtureName,
    bool isInitiallyAvailable = true,
  }) : _inMemoryFixtures = Map.of(initialFixtures ?? {}),
       _defaultFixture = defaultFixtureName,
       _isAvailable = isInitiallyAvailable;

  final Map<String, String> _inMemoryFixtures;
  final Queue<AiCompletionResponse> _responseQueue = Queue();
  final List<AiChatRequest> _recordedRequests = [];

  String? _defaultFixture;
  bool _isAvailable;
  Exception? _exception;

  @override
  String get name => 'fake';

  List<AiChatRequest> get recordedRequests =>
      List.unmodifiable(_recordedRequests);

  AiChatRequest? get lastRequest =>
      _recordedRequests.isEmpty ? null : _recordedRequests.last;

  void clearRecorded() => _recordedRequests.clear();

  void setAvailable(bool available) {
    _isAvailable = available;
  }

  void setException(Exception? exception) {
    _exception = exception;
  }

  void setDefaultFixture(String fixtureName) {
    _defaultFixture = fixtureName;
  }

  void addFixture(String name, String content) {
    _inMemoryFixtures[name] = content;
  }

  void queueResponse(
    String content, {
    String model = 'fake-model',
    int promptTokens = 50,
    int completionTokens = 100,
    Duration duration = const Duration(milliseconds: 10),
  }) {
    _responseQueue.add(
      AiCompletionResponse(
        rawContent: content,
        model: model,
        providerName: name,
        promptTokens: promptTokens,
        completionTokens: completionTokens,
        totalTokens: promptTokens + completionTokens,
        duration: duration,
      ),
    );
  }

  void queueFixture(
    String fixtureName, {
    String model = 'fake-model',
    int promptTokens = 50,
    int completionTokens = 100,
    Duration duration = const Duration(milliseconds: 10),
  }) {
    final content = loadFixtureContent(fixtureName);
    queueResponse(
      content,
      model: model,
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      duration: duration,
    );
  }

  String loadFixtureContent(String fixtureName) {
    // 1. In-memory override
    if (_inMemoryFixtures.containsKey(fixtureName)) {
      return _inMemoryFixtures[fixtureName]!;
    }

    // 2. Try filesystem test/fixtures/ai/
    final testFile = File('test/fixtures/ai/$fixtureName');
    if (testFile.existsSync()) {
      final content = testFile.readAsStringSync();
      _inMemoryFixtures[fixtureName] = content;
      return content;
    }

    // 3. Try filesystem spec/fixtures/ai/
    final specFile = File('spec/fixtures/ai/$fixtureName');
    if (specFile.existsSync()) {
      final content = specFile.readAsStringSync();
      _inMemoryFixtures[fixtureName] = content;
      return content;
    }

    throw ArgumentError(
      'Fixture "$fixtureName" not found in memory, test/fixtures/ai/ or spec/fixtures/ai/',
    );
  }

  @override
  Future<bool> isAvailable() async => _isAvailable;

  @override
  Future<AiCompletionResponse> chat(AiChatRequest request) async {
    _recordedRequests.add(request);

    if (_exception != null) {
      final err = _exception!;
      throw err;
    }

    if (_responseQueue.isNotEmpty) {
      return _responseQueue.removeFirst();
    }

    if (_defaultFixture != null) {
      final content = loadFixtureContent(_defaultFixture!);
      return AiCompletionResponse(
        rawContent: content,
        model: request.model ?? 'fake-model',
        providerName: name,
        promptTokens: 40,
        completionTokens: 80,
        totalTokens: 120,
        duration: const Duration(milliseconds: 15),
      );
    }

    // Fallback: try suggest_dishes_ok.json
    final content = loadFixtureContent('suggest_dishes_ok.json');
    return AiCompletionResponse(
      rawContent: content,
      model: request.model ?? 'fake-model',
      providerName: name,
      promptTokens: 40,
      completionTokens: 80,
      totalTokens: 120,
      duration: const Duration(milliseconds: 15),
    );
  }
}
