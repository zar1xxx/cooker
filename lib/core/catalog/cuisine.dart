/// Canonical cuisines supported by the app.
/// Follows country ISO codes or `home` for generic home cooking.
class Cuisine {
  final String code;
  final String titleRu;

  const Cuisine(this.code, this.titleRu);

  static const home = Cuisine('home', 'Домашняя');
  static const ru = Cuisine('ru', 'Русская');
  static const it = Cuisine('it', 'Итальянская');
  static const ge = Cuisine('ge', 'Грузинская');
  static const uz = Cuisine('uz', 'Узбекская');
  static const fr = Cuisine('fr', 'Французская');
  static const cn = Cuisine('cn', 'Китайская');
  static const jp = Cuisine('jp', 'Японская');
  static const tr = Cuisine('tr', 'Турецкая');

  static const List<Cuisine> canonical = [home, ru, it, ge, uz, fr, cn, jp, tr];

  static final Map<String, String> _knownTitles = {
    'home': 'Домашняя',
    'ru': 'Русская',
    'it': 'Итальянская',
    'ge': 'Грузинская',
    'uz': 'Узбекская',
    'fr': 'Французская',
    'cn': 'Китайская',
    'jp': 'Японская',
    'tr': 'Турецкая',
    'gr': 'Греческая',
    'mx': 'Мексиканская',
    'es': 'Испанская',
    'am': 'Армянская',
    'az': 'Азербайджанская',
    'by': 'Белорусская',
    'ua': 'Украинская',
    'kz': 'Казахская',
    'th': 'Тайская',
    'in': 'Индийская',
    'kr': 'Корейская',
    'de': 'Немецкая',
    'uk': 'Британская',
    'us': 'Американская',
  };

  /// Returns localized Russian name for any cuisine code, falling back to upper-case code.
  static String titleForCode(String code) {
    final lower = code.trim().toLowerCase();
    return _knownTitles[lower] ?? code.toUpperCase();
  }

  /// Whether the given cuisine code is recognized in the catalogue.
  static bool isKnown(String code) =>
      _knownTitles.containsKey(code.trim().toLowerCase());

  /// Normalizes cuisine code. Empty/null defaults to 'home'.
  static String normalize(String? code) {
    if (code == null) return 'home';
    final trimmed = code.trim().toLowerCase();
    if (trimmed.isEmpty) return 'home';
    return trimmed;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cuisine &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'Cuisine($code, $titleRu)';
}
