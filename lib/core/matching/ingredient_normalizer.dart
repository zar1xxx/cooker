/// A catalog entry used by [IngredientNormalizer]. Kept independent from the
/// database layer so the normalization logic stays pure Dart.
class IngredientTerm {
  const IngredientTerm({
    required this.id,
    required this.name,
    this.synonyms = const [],
    this.parentId,
  });

  final String id;
  final String name;
  final List<String> synonyms;
  final String? parentId;
}

/// Normalizes Russian ingredient names: case, ё→е, simple stemming, synonyms,
/// Levenshtein distance ≤ 2 and parent/child hierarchy.
class IngredientNormalizer {
  IngredientNormalizer(Iterable<IngredientTerm> ingredients)
    : _terms = List.unmodifiable(ingredients) {
    _buildIndexes();
  }

  static const _endings = [
    'ами',
    'ями',
    'ого',
    'ему',
    'ой',
    'ей',
    'ий',
    'ый',
    'ая',
    'яя',
    'ое',
    'ее',
    'ые',
    'ие',
    'ов',
    'ев',
    'ах',
    'ях',
    'ам',
    'ям',
    'ом',
    'ем',
    'у',
    'ю',
    'а',
    'я',
    'о',
    'е',
    'ы',
    'и',
    'ь',
  ];

  static final _wordPattern = RegExp(r'[\p{L}\p{N}]+', unicode: true);
  static final _noisePattern = RegExp(r'[^\p{L}\p{N}\s]+', unicode: true);
  static final _spacePattern = RegExp(r'\s+');

  final List<IngredientTerm> _terms;
  final _byNormalizedPhrase = <String, String>{};
  final _byStemmedPhrase = <String, String>{};
  final _tokenIndex = <String, Set<String>>{};
  final _fuzzyCandidates = <_Candidate>[];
  final _parentOf = <String, String?>{};
  final _children = <String, List<String>>{};

  /// Lower case, ё→е, punctuation removed, whitespace collapsed.
  String normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('ё', 'е')
        .replaceAll(_noisePattern, ' ')
        .replaceAll(_spacePattern, ' ')
        .trim();
  }

  /// Cuts one of the simple Russian endings, keeping a stem of at least
  /// 3 letters.
  String stem(String word) {
    final normalized = normalize(word);
    for (final ending in _endings) {
      if (normalized.length - ending.length >= 3 &&
          normalized.endsWith(ending)) {
        return normalized.substring(0, normalized.length - ending.length);
      }
    }
    return normalized;
  }

  /// Resolves one product name to a catalog id. Returns null when nothing
  /// close enough is found.
  String? resolve(String input) {
    final normalized = normalize(input);
    if (normalized.isEmpty) return null;

    final exact = _byNormalizedPhrase[normalized];
    if (exact != null) return exact;

    final stemmedPhrase = _stemPhrase(normalized);
    final stemExact = _byStemmedPhrase[stemmedPhrase];
    if (stemExact != null) return stemExact;

    final queryTokens = _tokens(normalized).map(stem).toList();
    if (queryTokens.isEmpty) return null;

    // Exact token match, e.g. «филе» among the synonyms of «куриное филе».
    for (final token in queryTokens) {
      final ids = _tokenIndex[token];
      if (ids != null && ids.isNotEmpty) {
        return _pickClosest(ids, token);
      }
    }

    // Prefix match for a partially typed word («морков» → «морковь»).
    for (final token in queryTokens) {
      if (token.length < 3) continue;
      final matches = <String, String>{};
      for (final entry in _tokenIndex.entries) {
        final candidate = entry.key;
        if (candidate.length < 3) continue;
        if (candidate.startsWith(token) || token.startsWith(candidate)) {
          for (final id in entry.value) {
            matches.putIfAbsent(id, () => candidate);
          }
        }
      }
      if (matches.length == 1) return matches.keys.first;
    }

    // Fuzzy match for typos: Levenshtein ≤ 2.
    // Short words allow one typo, long words two; very short stems are not
    // compared at all, otherwise «борщ» matched «порей».
    _Candidate? best;
    var bestDistance = 3;
    for (final candidate in _fuzzyCandidates) {
      if (candidate.stemmed.length < 4) continue;
      for (final token in queryTokens) {
        if (token.length < 4) continue;
        final allowed = token.length >= 7 ? 2 : 1;
        if ((token.length - candidate.stemmed.length).abs() > allowed) {
          continue;
        }
        final distance = _levenshtein(token, candidate.stemmed);
        if (distance <= allowed && distance < bestDistance) {
          bestDistance = distance;
          best = candidate;
        }
      }
    }
    if (best != null) return best.id;

    return null;
  }

  /// Splits free text by commas and the word «и», then resolves every part.
  List<String> resolveMany(String input) {
    final result = <String>[];
    for (final part in _splitInput(input)) {
      final id = resolve(part);
      if (id != null && !result.contains(id)) result.add(id);
    }
    return result;
  }

  /// Parts of the input that could not be matched, for the
  /// «Добавить как новый продукт» prompt.
  List<String> unresolved(String input) {
    return [
      for (final part in _splitInput(input))
        if (resolve(part) == null && part.trim().isNotEmpty) part.trim(),
    ];
  }

  /// All descendants of [id], including indirect ones.
  List<String> descendantsOf(String id) {
    final result = <String>[];
    final queue = <String>[...?_children[id]];
    final seen = <String>{id};
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (!seen.add(current)) continue;
      result.add(current);
      queue.addAll(_children[current] ?? const []);
    }
    return result;
  }

  /// All ancestors of [id], nearest first.
  List<String> ancestorsOf(String id) {
    final result = <String>[];
    final seen = <String>{id};
    var current = _parentOf[id];
    while (current != null && current.isNotEmpty && seen.add(current)) {
      result.add(current);
      current = _parentOf[current];
    }
    return result;
  }

  bool isDescendantOf(String childId, String ancestorId) {
    return ancestorsOf(childId).contains(ancestorId);
  }

  /// `childId -> [parent, grandparent, ...]` for every child in the catalog.
  /// This is the shape `RecipeValidator.ingredientHierarchy` expects.
  Map<String, List<String>> hierarchy() {
    final result = <String, List<String>>{};
    for (final term in _terms) {
      final ancestors = ancestorsOf(term.id);
      if (ancestors.isNotEmpty) result[term.id] = ancestors;
    }
    return result;
  }

  List<String> _splitInput(String input) {
    return input
        .split(RegExp(r'\s+и\s+|,', unicode: true))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }

  List<String> _tokens(String value) {
    return _wordPattern
        .allMatches(value)
        .map((match) => match.group(0)!)
        .toList();
  }

  String _stemPhrase(String normalized) {
    return _tokens(normalized).map(stem).join(' ');
  }

  void _buildIndexes() {
    for (final term in _terms) {
      _parentOf[term.id] = term.parentId;
      final parent = term.parentId;
      if (parent != null && parent.isNotEmpty) {
        _children.putIfAbsent(parent, () => []).add(term.id);
      }

      final phrases = <String>[term.name, ...term.synonyms];
      for (final phrase in phrases) {
        final normalized = normalize(phrase);
        if (normalized.isEmpty) continue;
        _byNormalizedPhrase.putIfAbsent(normalized, () => term.id);

        final stemmedPhrase = _stemPhrase(normalized);
        _byStemmedPhrase.putIfAbsent(stemmedPhrase, () => term.id);

        for (final token in _tokens(normalized)) {
          final stemmed = stem(token);
          if (stemmed.length < 3) continue;
          _tokenIndex.putIfAbsent(stemmed, () => {}).add(term.id);
          _fuzzyCandidates.add(_Candidate(id: term.id, stemmed: stemmed));
        }
        _fuzzyCandidates.add(_Candidate(id: term.id, stemmed: stemmedPhrase));
      }
    }
  }

  String _pickClosest(Set<String> ids, String token) {
    // Prefer an exact name match; otherwise keep a deterministic order.
    for (final term in _terms) {
      if (!ids.contains(term.id)) continue;
      final nameStems = _tokens(normalize(term.name)).map(stem);
      if (nameStems.contains(token)) return term.id;
    }
    return ids.first;
  }

  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    var previous = List<int>.generate(b.length + 1, (index) => index);
    for (var i = 1; i <= a.length; i++) {
      final current = List<int>.filled(b.length + 1, 0);
      current[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        final deletion = previous[j] + 1;
        final insertion = current[j - 1] + 1;
        final substitution = previous[j - 1] + cost;
        current[j] = _min3(deletion, insertion, substitution);
      }
      previous = current;
    }
    return previous[b.length];
  }

  int _min3(int a, int b, int c) {
    var min = a;
    if (b < min) min = b;
    if (c < min) min = c;
    return min;
  }
}

class _Candidate {
  const _Candidate({required this.id, required this.stemmed});

  final String id;
  final String stemmed;
}
