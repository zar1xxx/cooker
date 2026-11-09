/// The three tag namespaces defined by recipe taxonomy.
enum TagKind {
  dietary('dietary'),
  occasion('occasion'),
  mood('mood');

  final String id;
  const TagKind(this.id);

  static TagKind fromId(String id) {
    for (final kind in TagKind.values) {
      if (kind.id == id) return kind;
    }
    throw ArgumentError('Unknown TagKind: "$id"');
  }

  static TagKind? tryFromId(String? id) {
    if (id == null) return null;
    try {
      return fromId(id);
    } catch (_) {
      return null;
    }
  }
}

/// Dietary and nutritional attributes.
enum DietaryTag {
  vegetarian('vegetarian', 'Вегетарианское'),
  vegan('vegan', 'Веганское'),
  lenten('lenten', 'Постное'),
  lowCalorie('low_calorie', 'Малокалорийное'),
  glutenFree('gluten_free', 'Без глютена'),
  lactoseFree('lactose_free', 'Без лактозы'),
  highProtein('high_protein', 'Высокобелковое');

  final String id;
  final String titleRu;
  const DietaryTag(this.id, this.titleRu);

  static DietaryTag fromId(String id) {
    final normalized = id.toLowerCase().replaceAll('-', '_');
    for (final tag in DietaryTag.values) {
      if (tag.id == normalized) return tag;
    }
    throw ArgumentError('Unknown DietaryTag: "$id"');
  }

  static DietaryTag? tryFromId(String? id) {
    if (id == null) return null;
    try {
      return fromId(id);
    } catch (_) {
      return null;
    }
  }
}

/// Occasion and situational contexts.
enum OccasionTag {
  everyday('everyday', 'Повседневное'),
  festive('festive', 'Праздничное'),
  quick('quick', 'Быстрое (до 30 мин)'),
  forGuests('for_guests', 'Для гостей'),
  picnic('picnic', 'На природу'),
  kids('kids', 'Детям');

  final String id;
  final String titleRu;
  const OccasionTag(this.id, this.titleRu);

  static OccasionTag fromId(String id) {
    final normalized = id.toLowerCase().replaceAll('-', '_');
    for (final tag in OccasionTag.values) {
      if (tag.id == normalized) return tag;
    }
    throw ArgumentError('Unknown OccasionTag: "$id"');
  }

  static OccasionTag? tryFromId(String? id) {
    if (id == null) return null;
    try {
      return fromId(id);
    } catch (_) {
      return null;
    }
  }
}

/// Emotional or appetite mood contexts.
enum MoodTag {
  cozy('cozy', 'Уютное'),
  light('light', 'Лёгкое'),
  hearty('hearty', 'Сытное'),
  somethingNew('something_new', 'Хочется нового'),
  onTheRun('on_the_run', 'По-быстрому'),
  treatYourself('treat_yourself', 'Порадовать себя');

  final String id;
  final String titleRu;
  const MoodTag(this.id, this.titleRu);

  static MoodTag fromId(String id) {
    final normalized = id.toLowerCase().replaceAll('-', '_');
    for (final tag in MoodTag.values) {
      if (tag.id == normalized) return tag;
    }
    throw ArgumentError('Unknown MoodTag: "$id"');
  }

  static MoodTag? tryFromId(String? id) {
    if (id == null) return null;
    try {
      return fromId(id);
    } catch (_) {
      return null;
    }
  }
}

/// Representation of a single recipe tag tuple (kind, tag).
class RecipeTag {
  final TagKind kind;
  final String tag;

  const RecipeTag({required this.kind, required this.tag});

  factory RecipeTag.dietary(DietaryTag dietary) =>
      RecipeTag(kind: TagKind.dietary, tag: dietary.id);

  factory RecipeTag.occasion(OccasionTag occasion) =>
      RecipeTag(kind: TagKind.occasion, tag: occasion.id);

  factory RecipeTag.mood(MoodTag mood) =>
      RecipeTag(kind: TagKind.mood, tag: mood.id);

  String get localizedTitle {
    switch (kind) {
      case TagKind.dietary:
        return DietaryTag.tryFromId(tag)?.titleRu ?? tag;
      case TagKind.occasion:
        return OccasionTag.tryFromId(tag)?.titleRu ?? tag;
      case TagKind.mood:
        return MoodTag.tryFromId(tag)?.titleRu ?? tag;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeTag &&
          runtimeType == other.runtimeType &&
          kind == other.kind &&
          tag == other.tag;

  @override
  int get hashCode => Object.hash(kind, tag);

  @override
  String toString() => '${kind.id}:$tag';
}
