// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class IngredientsFts extends Table
    with
        TableInfo<IngredientsFts, IngredientsFt>,
        VirtualTableInfo<IngredientsFts, IngredientsFt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  IngredientsFts(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ingredientIdMeta = const VerificationMeta(
    'ingredientId',
  );
  late final GeneratedColumn<String> ingredientId = GeneratedColumn<String>(
    'ingredient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  static const VerificationMeta _synonymsMeta = const VerificationMeta(
    'synonyms',
  );
  late final GeneratedColumn<String> synonyms = GeneratedColumn<String>(
    'synonyms',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [ingredientId, name, synonyms];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingredients_fts';
  @override
  VerificationContext validateIntegrity(
    Insertable<IngredientsFt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ingredient_id')) {
      context.handle(
        _ingredientIdMeta,
        ingredientId.isAcceptableOrUnknown(
          data['ingredient_id']!,
          _ingredientIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ingredientIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('synonyms')) {
      context.handle(
        _synonymsMeta,
        synonyms.isAcceptableOrUnknown(data['synonyms']!, _synonymsMeta),
      );
    } else if (isInserting) {
      context.missing(_synonymsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  IngredientsFt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IngredientsFt(
      ingredientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ingredient_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      synonyms: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}synonyms'],
      )!,
    );
  }

  @override
  IngredientsFts createAlias(String alias) {
    return IngredientsFts(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
  @override
  String get moduleAndArgs => 'fts5(ingredient_id UNINDEXED, name, synonyms)';
}

class IngredientsFt extends DataClass implements Insertable<IngredientsFt> {
  final String ingredientId;
  final String name;
  final String synonyms;
  const IngredientsFt({
    required this.ingredientId,
    required this.name,
    required this.synonyms,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ingredient_id'] = Variable<String>(ingredientId);
    map['name'] = Variable<String>(name);
    map['synonyms'] = Variable<String>(synonyms);
    return map;
  }

  IngredientsFtsCompanion toCompanion(bool nullToAbsent) {
    return IngredientsFtsCompanion(
      ingredientId: Value(ingredientId),
      name: Value(name),
      synonyms: Value(synonyms),
    );
  }

  factory IngredientsFt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IngredientsFt(
      ingredientId: serializer.fromJson<String>(json['ingredient_id']),
      name: serializer.fromJson<String>(json['name']),
      synonyms: serializer.fromJson<String>(json['synonyms']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ingredient_id': serializer.toJson<String>(ingredientId),
      'name': serializer.toJson<String>(name),
      'synonyms': serializer.toJson<String>(synonyms),
    };
  }

  IngredientsFt copyWith({
    String? ingredientId,
    String? name,
    String? synonyms,
  }) => IngredientsFt(
    ingredientId: ingredientId ?? this.ingredientId,
    name: name ?? this.name,
    synonyms: synonyms ?? this.synonyms,
  );
  IngredientsFt copyWithCompanion(IngredientsFtsCompanion data) {
    return IngredientsFt(
      ingredientId: data.ingredientId.present
          ? data.ingredientId.value
          : this.ingredientId,
      name: data.name.present ? data.name.value : this.name,
      synonyms: data.synonyms.present ? data.synonyms.value : this.synonyms,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IngredientsFt(')
          ..write('ingredientId: $ingredientId, ')
          ..write('name: $name, ')
          ..write('synonyms: $synonyms')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(ingredientId, name, synonyms);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IngredientsFt &&
          other.ingredientId == this.ingredientId &&
          other.name == this.name &&
          other.synonyms == this.synonyms);
}

class IngredientsFtsCompanion extends UpdateCompanion<IngredientsFt> {
  final Value<String> ingredientId;
  final Value<String> name;
  final Value<String> synonyms;
  final Value<int> rowid;
  const IngredientsFtsCompanion({
    this.ingredientId = const Value.absent(),
    this.name = const Value.absent(),
    this.synonyms = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IngredientsFtsCompanion.insert({
    required String ingredientId,
    required String name,
    required String synonyms,
    this.rowid = const Value.absent(),
  }) : ingredientId = Value(ingredientId),
       name = Value(name),
       synonyms = Value(synonyms);
  static Insertable<IngredientsFt> custom({
    Expression<String>? ingredientId,
    Expression<String>? name,
    Expression<String>? synonyms,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ingredientId != null) 'ingredient_id': ingredientId,
      if (name != null) 'name': name,
      if (synonyms != null) 'synonyms': synonyms,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IngredientsFtsCompanion copyWith({
    Value<String>? ingredientId,
    Value<String>? name,
    Value<String>? synonyms,
    Value<int>? rowid,
  }) {
    return IngredientsFtsCompanion(
      ingredientId: ingredientId ?? this.ingredientId,
      name: name ?? this.name,
      synonyms: synonyms ?? this.synonyms,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ingredientId.present) {
      map['ingredient_id'] = Variable<String>(ingredientId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (synonyms.present) {
      map['synonyms'] = Variable<String>(synonyms.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngredientsFtsCompanion(')
          ..write('ingredientId: $ingredientId, ')
          ..write('name: $name, ')
          ..write('synonyms: $synonyms, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IngredientsTable extends Ingredients
    with TableInfo<$IngredientsTable, Ingredient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngredientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: () => clock.now().toUtc().millisecondsSinceEpoch,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: () => clock.now().toUtc().millisecondsSinceEpoch,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> synonyms =
      GeneratedColumn<String>(
        'synonyms',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<String>>($IngredientsTable.$convertersynonyms);
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isStapleMeta = const VerificationMeta(
    'isStaple',
  );
  @override
  late final GeneratedColumn<bool> isStaple = GeneratedColumn<bool>(
    'is_staple',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_staple" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    name,
    synonyms,
    category,
    isStaple,
    icon,
    parentId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingredients';
  @override
  VerificationContext validateIntegrity(
    Insertable<Ingredient> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('is_staple')) {
      context.handle(
        _isStapleMeta,
        isStaple.isAcceptableOrUnknown(data['is_staple']!, _isStapleMeta),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Ingredient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Ingredient(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      synonyms: $IngredientsTable.$convertersynonyms.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}synonyms'],
        )!,
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      isStaple: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_staple'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
    );
  }

  @override
  $IngredientsTable createAlias(String alias) {
    return $IngredientsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $convertersynonyms =
      const StringListConverter();
}

class Ingredient extends DataClass implements Insertable<Ingredient> {
  final String id;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  final String name;
  final List<String> synonyms;
  final String category;
  final bool isStaple;
  final String? icon;
  final String? parentId;
  const Ingredient({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.name,
    required this.synonyms,
    required this.category,
    required this.isStaple,
    this.icon,
    this.parentId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['name'] = Variable<String>(name);
    {
      map['synonyms'] = Variable<String>(
        $IngredientsTable.$convertersynonyms.toSql(synonyms),
      );
    }
    map['category'] = Variable<String>(category);
    map['is_staple'] = Variable<bool>(isStaple);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    return map;
  }

  IngredientsCompanion toCompanion(bool nullToAbsent) {
    return IngredientsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      name: Value(name),
      synonyms: Value(synonyms),
      category: Value(category),
      isStaple: Value(isStaple),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
    );
  }

  factory Ingredient.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Ingredient(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      name: serializer.fromJson<String>(json['name']),
      synonyms: serializer.fromJson<List<String>>(json['synonyms']),
      category: serializer.fromJson<String>(json['category']),
      isStaple: serializer.fromJson<bool>(json['isStaple']),
      icon: serializer.fromJson<String?>(json['icon']),
      parentId: serializer.fromJson<String?>(json['parentId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'name': serializer.toJson<String>(name),
      'synonyms': serializer.toJson<List<String>>(synonyms),
      'category': serializer.toJson<String>(category),
      'isStaple': serializer.toJson<bool>(isStaple),
      'icon': serializer.toJson<String?>(icon),
      'parentId': serializer.toJson<String?>(parentId),
    };
  }

  Ingredient copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? name,
    List<String>? synonyms,
    String? category,
    bool? isStaple,
    Value<String?> icon = const Value.absent(),
    Value<String?> parentId = const Value.absent(),
  }) => Ingredient(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    name: name ?? this.name,
    synonyms: synonyms ?? this.synonyms,
    category: category ?? this.category,
    isStaple: isStaple ?? this.isStaple,
    icon: icon.present ? icon.value : this.icon,
    parentId: parentId.present ? parentId.value : this.parentId,
  );
  Ingredient copyWithCompanion(IngredientsCompanion data) {
    return Ingredient(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      name: data.name.present ? data.name.value : this.name,
      synonyms: data.synonyms.present ? data.synonyms.value : this.synonyms,
      category: data.category.present ? data.category.value : this.category,
      isStaple: data.isStaple.present ? data.isStaple.value : this.isStaple,
      icon: data.icon.present ? data.icon.value : this.icon,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ingredient(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('synonyms: $synonyms, ')
          ..write('category: $category, ')
          ..write('isStaple: $isStaple, ')
          ..write('icon: $icon, ')
          ..write('parentId: $parentId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    name,
    synonyms,
    category,
    isStaple,
    icon,
    parentId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ingredient &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.name == this.name &&
          other.synonyms == this.synonyms &&
          other.category == this.category &&
          other.isStaple == this.isStaple &&
          other.icon == this.icon &&
          other.parentId == this.parentId);
}

class IngredientsCompanion extends UpdateCompanion<Ingredient> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> name;
  final Value<List<String>> synonyms;
  final Value<String> category;
  final Value<bool> isStaple;
  final Value<String?> icon;
  final Value<String?> parentId;
  final Value<int> rowid;
  const IngredientsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.synonyms = const Value.absent(),
    this.category = const Value.absent(),
    this.isStaple = const Value.absent(),
    this.icon = const Value.absent(),
    this.parentId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IngredientsCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String name,
    this.synonyms = const Value.absent(),
    required String category,
    this.isStaple = const Value.absent(),
    this.icon = const Value.absent(),
    this.parentId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       category = Value(category);
  static Insertable<Ingredient> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? name,
    Expression<String>? synonyms,
    Expression<String>? category,
    Expression<bool>? isStaple,
    Expression<String>? icon,
    Expression<String>? parentId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (name != null) 'name': name,
      if (synonyms != null) 'synonyms': synonyms,
      if (category != null) 'category': category,
      if (isStaple != null) 'is_staple': isStaple,
      if (icon != null) 'icon': icon,
      if (parentId != null) 'parent_id': parentId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IngredientsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? name,
    Value<List<String>>? synonyms,
    Value<String>? category,
    Value<bool>? isStaple,
    Value<String?>? icon,
    Value<String?>? parentId,
    Value<int>? rowid,
  }) {
    return IngredientsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      name: name ?? this.name,
      synonyms: synonyms ?? this.synonyms,
      category: category ?? this.category,
      isStaple: isStaple ?? this.isStaple,
      icon: icon ?? this.icon,
      parentId: parentId ?? this.parentId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (synonyms.present) {
      map['synonyms'] = Variable<String>(
        $IngredientsTable.$convertersynonyms.toSql(synonyms.value),
      );
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (isStaple.present) {
      map['is_staple'] = Variable<bool>(isStaple.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngredientsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('synonyms: $synonyms, ')
          ..write('category: $category, ')
          ..write('isStaple: $isStaple, ')
          ..write('icon: $icon, ')
          ..write('parentId: $parentId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PantryItemsTable extends PantryItems
    with TableInfo<$PantryItemsTable, PantryItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PantryItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: () => clock.now().toUtc().millisecondsSinceEpoch,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: () => clock.now().toUtc().millisecondsSinceEpoch,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ingredientIdMeta = const VerificationMeta(
    'ingredientId',
  );
  @override
  late final GeneratedColumn<String> ingredientId = GeneratedColumn<String>(
    'ingredient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isAvailableMeta = const VerificationMeta(
    'isAvailable',
  );
  @override
  late final GeneratedColumn<bool> isAvailable = GeneratedColumn<bool>(
    'is_available',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_available" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    ingredientId,
    isAvailable,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pantry_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<PantryItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('ingredient_id')) {
      context.handle(
        _ingredientIdMeta,
        ingredientId.isAcceptableOrUnknown(
          data['ingredient_id']!,
          _ingredientIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ingredientIdMeta);
    }
    if (data.containsKey('is_available')) {
      context.handle(
        _isAvailableMeta,
        isAvailable.isAcceptableOrUnknown(
          data['is_available']!,
          _isAvailableMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PantryItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PantryItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      ingredientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ingredient_id'],
      )!,
      isAvailable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_available'],
      )!,
    );
  }

  @override
  $PantryItemsTable createAlias(String alias) {
    return $PantryItemsTable(attachedDatabase, alias);
  }
}

class PantryItem extends DataClass implements Insertable<PantryItem> {
  final String id;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  final String ingredientId;
  final bool isAvailable;
  const PantryItem({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.ingredientId,
    required this.isAvailable,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['ingredient_id'] = Variable<String>(ingredientId);
    map['is_available'] = Variable<bool>(isAvailable);
    return map;
  }

  PantryItemsCompanion toCompanion(bool nullToAbsent) {
    return PantryItemsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      ingredientId: Value(ingredientId),
      isAvailable: Value(isAvailable),
    );
  }

  factory PantryItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PantryItem(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      ingredientId: serializer.fromJson<String>(json['ingredientId']),
      isAvailable: serializer.fromJson<bool>(json['isAvailable']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'ingredientId': serializer.toJson<String>(ingredientId),
      'isAvailable': serializer.toJson<bool>(isAvailable),
    };
  }

  PantryItem copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? ingredientId,
    bool? isAvailable,
  }) => PantryItem(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    ingredientId: ingredientId ?? this.ingredientId,
    isAvailable: isAvailable ?? this.isAvailable,
  );
  PantryItem copyWithCompanion(PantryItemsCompanion data) {
    return PantryItem(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      ingredientId: data.ingredientId.present
          ? data.ingredientId.value
          : this.ingredientId,
      isAvailable: data.isAvailable.present
          ? data.isAvailable.value
          : this.isAvailable,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PantryItem(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('isAvailable: $isAvailable')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    ingredientId,
    isAvailable,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PantryItem &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.ingredientId == this.ingredientId &&
          other.isAvailable == this.isAvailable);
}

class PantryItemsCompanion extends UpdateCompanion<PantryItem> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> ingredientId;
  final Value<bool> isAvailable;
  final Value<int> rowid;
  const PantryItemsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.ingredientId = const Value.absent(),
    this.isAvailable = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PantryItemsCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String ingredientId,
    this.isAvailable = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : ingredientId = Value(ingredientId);
  static Insertable<PantryItem> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? ingredientId,
    Expression<bool>? isAvailable,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (ingredientId != null) 'ingredient_id': ingredientId,
      if (isAvailable != null) 'is_available': isAvailable,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PantryItemsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? ingredientId,
    Value<bool>? isAvailable,
    Value<int>? rowid,
  }) {
    return PantryItemsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      ingredientId: ingredientId ?? this.ingredientId,
      isAvailable: isAvailable ?? this.isAvailable,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (ingredientId.present) {
      map['ingredient_id'] = Variable<String>(ingredientId.value);
    }
    if (isAvailable.present) {
      map['is_available'] = Variable<bool>(isAvailable.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PantryItemsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('isAvailable: $isAvailable, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecipesTable extends Recipes with TableInfo<$RecipesTable, Recipe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: () => clock.now().toUtc().millisecondsSinceEpoch,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: () => clock.now().toUtc().millisecondsSinceEpoch,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedTitleMeta = const VerificationMeta(
    'normalizedTitle',
  );
  @override
  late final GeneratedColumn<String> normalizedTitle = GeneratedColumn<String>(
    'normalized_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DishType, String> dishType =
      GeneratedColumn<String>(
        'dish_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DishType>($RecipesTable.$converterdishType);
  @override
  late final GeneratedColumnWithTypeConverter<DishGroup, String> dishGroup =
      GeneratedColumn<String>(
        'dish_group',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('vegetable'),
      ).withConverter<DishGroup>($RecipesTable.$converterdishGroup);
  @override
  late final GeneratedColumnWithTypeConverter<Difficulty, String> difficulty =
      GeneratedColumn<String>(
        'difficulty',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Difficulty>($RecipesTable.$converterdifficulty);
  static const VerificationMeta _cuisineMeta = const VerificationMeta(
    'cuisine',
  );
  @override
  late final GeneratedColumn<String> cuisine = GeneratedColumn<String>(
    'cuisine',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalMinutesMeta = const VerificationMeta(
    'totalMinutes',
  );
  @override
  late final GeneratedColumn<int> totalMinutes = GeneratedColumn<int>(
    'total_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMinutesMeta = const VerificationMeta(
    'activeMinutes',
  );
  @override
  late final GeneratedColumn<int> activeMinutes = GeneratedColumn<int>(
    'active_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cookMinutesMeta = const VerificationMeta(
    'cookMinutes',
  );
  @override
  late final GeneratedColumn<int> cookMinutes = GeneratedColumn<int>(
    'cook_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kcalPerServingMeta = const VerificationMeta(
    'kcalPerServing',
  );
  @override
  late final GeneratedColumn<int> kcalPerServing = GeneratedColumn<int>(
    'kcal_per_serving',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _servingsMeta = const VerificationMeta(
    'servings',
  );
  @override
  late final GeneratedColumn<int> servings = GeneratedColumn<int>(
    'servings',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RecipeSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<RecipeSource>($RecipesTable.$convertersource);
  static const VerificationMeta _fingerprintMeta = const VerificationMeta(
    'fingerprint',
  );
  @override
  late final GeneratedColumn<String> fingerprint = GeneratedColumn<String>(
    'fingerprint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aiModelMeta = const VerificationMeta(
    'aiModel',
  );
  @override
  late final GeneratedColumn<String> aiModel = GeneratedColumn<String>(
    'ai_model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    title,
    normalizedTitle,
    dishType,
    dishGroup,
    difficulty,
    cuisine,
    totalMinutes,
    activeMinutes,
    cookMinutes,
    kcalPerServing,
    servings,
    description,
    source,
    fingerprint,
    aiModel,
    isFavorite,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Recipe> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('normalized_title')) {
      context.handle(
        _normalizedTitleMeta,
        normalizedTitle.isAcceptableOrUnknown(
          data['normalized_title']!,
          _normalizedTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedTitleMeta);
    }
    if (data.containsKey('cuisine')) {
      context.handle(
        _cuisineMeta,
        cuisine.isAcceptableOrUnknown(data['cuisine']!, _cuisineMeta),
      );
    } else if (isInserting) {
      context.missing(_cuisineMeta);
    }
    if (data.containsKey('total_minutes')) {
      context.handle(
        _totalMinutesMeta,
        totalMinutes.isAcceptableOrUnknown(
          data['total_minutes']!,
          _totalMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalMinutesMeta);
    }
    if (data.containsKey('active_minutes')) {
      context.handle(
        _activeMinutesMeta,
        activeMinutes.isAcceptableOrUnknown(
          data['active_minutes']!,
          _activeMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activeMinutesMeta);
    }
    if (data.containsKey('cook_minutes')) {
      context.handle(
        _cookMinutesMeta,
        cookMinutes.isAcceptableOrUnknown(
          data['cook_minutes']!,
          _cookMinutesMeta,
        ),
      );
    }
    if (data.containsKey('kcal_per_serving')) {
      context.handle(
        _kcalPerServingMeta,
        kcalPerServing.isAcceptableOrUnknown(
          data['kcal_per_serving']!,
          _kcalPerServingMeta,
        ),
      );
    }
    if (data.containsKey('servings')) {
      context.handle(
        _servingsMeta,
        servings.isAcceptableOrUnknown(data['servings']!, _servingsMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('fingerprint')) {
      context.handle(
        _fingerprintMeta,
        fingerprint.isAcceptableOrUnknown(
          data['fingerprint']!,
          _fingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fingerprintMeta);
    }
    if (data.containsKey('ai_model')) {
      context.handle(
        _aiModelMeta,
        aiModel.isAcceptableOrUnknown(data['ai_model']!, _aiModelMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Recipe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Recipe(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      normalizedTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_title'],
      )!,
      dishType: $RecipesTable.$converterdishType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}dish_type'],
        )!,
      ),
      dishGroup: $RecipesTable.$converterdishGroup.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}dish_group'],
        )!,
      ),
      difficulty: $RecipesTable.$converterdifficulty.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}difficulty'],
        )!,
      ),
      cuisine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cuisine'],
      )!,
      totalMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_minutes'],
      )!,
      activeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}active_minutes'],
      )!,
      cookMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cook_minutes'],
      ),
      kcalPerServing: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kcal_per_serving'],
      ),
      servings: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}servings'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      source: $RecipesTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      fingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fingerprint'],
      )!,
      aiModel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ai_model'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
    );
  }

  @override
  $RecipesTable createAlias(String alias) {
    return $RecipesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DishType, String, String> $converterdishType =
      const EnumNameConverter<DishType>(DishType.values);
  static JsonTypeConverter2<DishGroup, String, String> $converterdishGroup =
      const EnumNameConverter<DishGroup>(DishGroup.values);
  static JsonTypeConverter2<Difficulty, String, String> $converterdifficulty =
      const EnumNameConverter<Difficulty>(Difficulty.values);
  static JsonTypeConverter2<RecipeSource, String, String> $convertersource =
      const EnumNameConverter<RecipeSource>(RecipeSource.values);
}

class Recipe extends DataClass implements Insertable<Recipe> {
  final String id;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  final String title;
  final String normalizedTitle;
  final DishType dishType;
  final DishGroup dishGroup;
  final Difficulty difficulty;
  final String cuisine;
  final int totalMinutes;
  final int activeMinutes;
  final int? cookMinutes;
  final int? kcalPerServing;
  final int servings;
  final String description;
  final RecipeSource source;
  final String fingerprint;
  final String? aiModel;
  final bool isFavorite;
  const Recipe({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.title,
    required this.normalizedTitle,
    required this.dishType,
    required this.dishGroup,
    required this.difficulty,
    required this.cuisine,
    required this.totalMinutes,
    required this.activeMinutes,
    this.cookMinutes,
    this.kcalPerServing,
    required this.servings,
    required this.description,
    required this.source,
    required this.fingerprint,
    this.aiModel,
    required this.isFavorite,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['title'] = Variable<String>(title);
    map['normalized_title'] = Variable<String>(normalizedTitle);
    {
      map['dish_type'] = Variable<String>(
        $RecipesTable.$converterdishType.toSql(dishType),
      );
    }
    {
      map['dish_group'] = Variable<String>(
        $RecipesTable.$converterdishGroup.toSql(dishGroup),
      );
    }
    {
      map['difficulty'] = Variable<String>(
        $RecipesTable.$converterdifficulty.toSql(difficulty),
      );
    }
    map['cuisine'] = Variable<String>(cuisine);
    map['total_minutes'] = Variable<int>(totalMinutes);
    map['active_minutes'] = Variable<int>(activeMinutes);
    if (!nullToAbsent || cookMinutes != null) {
      map['cook_minutes'] = Variable<int>(cookMinutes);
    }
    if (!nullToAbsent || kcalPerServing != null) {
      map['kcal_per_serving'] = Variable<int>(kcalPerServing);
    }
    map['servings'] = Variable<int>(servings);
    map['description'] = Variable<String>(description);
    {
      map['source'] = Variable<String>(
        $RecipesTable.$convertersource.toSql(source),
      );
    }
    map['fingerprint'] = Variable<String>(fingerprint);
    if (!nullToAbsent || aiModel != null) {
      map['ai_model'] = Variable<String>(aiModel);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    return map;
  }

  RecipesCompanion toCompanion(bool nullToAbsent) {
    return RecipesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      title: Value(title),
      normalizedTitle: Value(normalizedTitle),
      dishType: Value(dishType),
      dishGroup: Value(dishGroup),
      difficulty: Value(difficulty),
      cuisine: Value(cuisine),
      totalMinutes: Value(totalMinutes),
      activeMinutes: Value(activeMinutes),
      cookMinutes: cookMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(cookMinutes),
      kcalPerServing: kcalPerServing == null && nullToAbsent
          ? const Value.absent()
          : Value(kcalPerServing),
      servings: Value(servings),
      description: Value(description),
      source: Value(source),
      fingerprint: Value(fingerprint),
      aiModel: aiModel == null && nullToAbsent
          ? const Value.absent()
          : Value(aiModel),
      isFavorite: Value(isFavorite),
    );
  }

  factory Recipe.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Recipe(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      title: serializer.fromJson<String>(json['title']),
      normalizedTitle: serializer.fromJson<String>(json['normalizedTitle']),
      dishType: $RecipesTable.$converterdishType.fromJson(
        serializer.fromJson<String>(json['dishType']),
      ),
      dishGroup: $RecipesTable.$converterdishGroup.fromJson(
        serializer.fromJson<String>(json['dishGroup']),
      ),
      difficulty: $RecipesTable.$converterdifficulty.fromJson(
        serializer.fromJson<String>(json['difficulty']),
      ),
      cuisine: serializer.fromJson<String>(json['cuisine']),
      totalMinutes: serializer.fromJson<int>(json['totalMinutes']),
      activeMinutes: serializer.fromJson<int>(json['activeMinutes']),
      cookMinutes: serializer.fromJson<int?>(json['cookMinutes']),
      kcalPerServing: serializer.fromJson<int?>(json['kcalPerServing']),
      servings: serializer.fromJson<int>(json['servings']),
      description: serializer.fromJson<String>(json['description']),
      source: $RecipesTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      fingerprint: serializer.fromJson<String>(json['fingerprint']),
      aiModel: serializer.fromJson<String?>(json['aiModel']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'title': serializer.toJson<String>(title),
      'normalizedTitle': serializer.toJson<String>(normalizedTitle),
      'dishType': serializer.toJson<String>(
        $RecipesTable.$converterdishType.toJson(dishType),
      ),
      'dishGroup': serializer.toJson<String>(
        $RecipesTable.$converterdishGroup.toJson(dishGroup),
      ),
      'difficulty': serializer.toJson<String>(
        $RecipesTable.$converterdifficulty.toJson(difficulty),
      ),
      'cuisine': serializer.toJson<String>(cuisine),
      'totalMinutes': serializer.toJson<int>(totalMinutes),
      'activeMinutes': serializer.toJson<int>(activeMinutes),
      'cookMinutes': serializer.toJson<int?>(cookMinutes),
      'kcalPerServing': serializer.toJson<int?>(kcalPerServing),
      'servings': serializer.toJson<int>(servings),
      'description': serializer.toJson<String>(description),
      'source': serializer.toJson<String>(
        $RecipesTable.$convertersource.toJson(source),
      ),
      'fingerprint': serializer.toJson<String>(fingerprint),
      'aiModel': serializer.toJson<String?>(aiModel),
      'isFavorite': serializer.toJson<bool>(isFavorite),
    };
  }

  Recipe copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? title,
    String? normalizedTitle,
    DishType? dishType,
    DishGroup? dishGroup,
    Difficulty? difficulty,
    String? cuisine,
    int? totalMinutes,
    int? activeMinutes,
    Value<int?> cookMinutes = const Value.absent(),
    Value<int?> kcalPerServing = const Value.absent(),
    int? servings,
    String? description,
    RecipeSource? source,
    String? fingerprint,
    Value<String?> aiModel = const Value.absent(),
    bool? isFavorite,
  }) => Recipe(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    title: title ?? this.title,
    normalizedTitle: normalizedTitle ?? this.normalizedTitle,
    dishType: dishType ?? this.dishType,
    dishGroup: dishGroup ?? this.dishGroup,
    difficulty: difficulty ?? this.difficulty,
    cuisine: cuisine ?? this.cuisine,
    totalMinutes: totalMinutes ?? this.totalMinutes,
    activeMinutes: activeMinutes ?? this.activeMinutes,
    cookMinutes: cookMinutes.present ? cookMinutes.value : this.cookMinutes,
    kcalPerServing: kcalPerServing.present
        ? kcalPerServing.value
        : this.kcalPerServing,
    servings: servings ?? this.servings,
    description: description ?? this.description,
    source: source ?? this.source,
    fingerprint: fingerprint ?? this.fingerprint,
    aiModel: aiModel.present ? aiModel.value : this.aiModel,
    isFavorite: isFavorite ?? this.isFavorite,
  );
  Recipe copyWithCompanion(RecipesCompanion data) {
    return Recipe(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      title: data.title.present ? data.title.value : this.title,
      normalizedTitle: data.normalizedTitle.present
          ? data.normalizedTitle.value
          : this.normalizedTitle,
      dishType: data.dishType.present ? data.dishType.value : this.dishType,
      dishGroup: data.dishGroup.present ? data.dishGroup.value : this.dishGroup,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      cuisine: data.cuisine.present ? data.cuisine.value : this.cuisine,
      totalMinutes: data.totalMinutes.present
          ? data.totalMinutes.value
          : this.totalMinutes,
      activeMinutes: data.activeMinutes.present
          ? data.activeMinutes.value
          : this.activeMinutes,
      cookMinutes: data.cookMinutes.present
          ? data.cookMinutes.value
          : this.cookMinutes,
      kcalPerServing: data.kcalPerServing.present
          ? data.kcalPerServing.value
          : this.kcalPerServing,
      servings: data.servings.present ? data.servings.value : this.servings,
      description: data.description.present
          ? data.description.value
          : this.description,
      source: data.source.present ? data.source.value : this.source,
      fingerprint: data.fingerprint.present
          ? data.fingerprint.value
          : this.fingerprint,
      aiModel: data.aiModel.present ? data.aiModel.value : this.aiModel,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Recipe(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('title: $title, ')
          ..write('normalizedTitle: $normalizedTitle, ')
          ..write('dishType: $dishType, ')
          ..write('dishGroup: $dishGroup, ')
          ..write('difficulty: $difficulty, ')
          ..write('cuisine: $cuisine, ')
          ..write('totalMinutes: $totalMinutes, ')
          ..write('activeMinutes: $activeMinutes, ')
          ..write('cookMinutes: $cookMinutes, ')
          ..write('kcalPerServing: $kcalPerServing, ')
          ..write('servings: $servings, ')
          ..write('description: $description, ')
          ..write('source: $source, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('aiModel: $aiModel, ')
          ..write('isFavorite: $isFavorite')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    title,
    normalizedTitle,
    dishType,
    dishGroup,
    difficulty,
    cuisine,
    totalMinutes,
    activeMinutes,
    cookMinutes,
    kcalPerServing,
    servings,
    description,
    source,
    fingerprint,
    aiModel,
    isFavorite,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Recipe &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.title == this.title &&
          other.normalizedTitle == this.normalizedTitle &&
          other.dishType == this.dishType &&
          other.dishGroup == this.dishGroup &&
          other.difficulty == this.difficulty &&
          other.cuisine == this.cuisine &&
          other.totalMinutes == this.totalMinutes &&
          other.activeMinutes == this.activeMinutes &&
          other.cookMinutes == this.cookMinutes &&
          other.kcalPerServing == this.kcalPerServing &&
          other.servings == this.servings &&
          other.description == this.description &&
          other.source == this.source &&
          other.fingerprint == this.fingerprint &&
          other.aiModel == this.aiModel &&
          other.isFavorite == this.isFavorite);
}

class RecipesCompanion extends UpdateCompanion<Recipe> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> title;
  final Value<String> normalizedTitle;
  final Value<DishType> dishType;
  final Value<DishGroup> dishGroup;
  final Value<Difficulty> difficulty;
  final Value<String> cuisine;
  final Value<int> totalMinutes;
  final Value<int> activeMinutes;
  final Value<int?> cookMinutes;
  final Value<int?> kcalPerServing;
  final Value<int> servings;
  final Value<String> description;
  final Value<RecipeSource> source;
  final Value<String> fingerprint;
  final Value<String?> aiModel;
  final Value<bool> isFavorite;
  final Value<int> rowid;
  const RecipesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.title = const Value.absent(),
    this.normalizedTitle = const Value.absent(),
    this.dishType = const Value.absent(),
    this.dishGroup = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.cuisine = const Value.absent(),
    this.totalMinutes = const Value.absent(),
    this.activeMinutes = const Value.absent(),
    this.cookMinutes = const Value.absent(),
    this.kcalPerServing = const Value.absent(),
    this.servings = const Value.absent(),
    this.description = const Value.absent(),
    this.source = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.aiModel = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipesCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String title,
    required String normalizedTitle,
    required DishType dishType,
    this.dishGroup = const Value.absent(),
    required Difficulty difficulty,
    required String cuisine,
    required int totalMinutes,
    required int activeMinutes,
    this.cookMinutes = const Value.absent(),
    this.kcalPerServing = const Value.absent(),
    this.servings = const Value.absent(),
    required String description,
    required RecipeSource source,
    required String fingerprint,
    this.aiModel = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : title = Value(title),
       normalizedTitle = Value(normalizedTitle),
       dishType = Value(dishType),
       difficulty = Value(difficulty),
       cuisine = Value(cuisine),
       totalMinutes = Value(totalMinutes),
       activeMinutes = Value(activeMinutes),
       description = Value(description),
       source = Value(source),
       fingerprint = Value(fingerprint);
  static Insertable<Recipe> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? title,
    Expression<String>? normalizedTitle,
    Expression<String>? dishType,
    Expression<String>? dishGroup,
    Expression<String>? difficulty,
    Expression<String>? cuisine,
    Expression<int>? totalMinutes,
    Expression<int>? activeMinutes,
    Expression<int>? cookMinutes,
    Expression<int>? kcalPerServing,
    Expression<int>? servings,
    Expression<String>? description,
    Expression<String>? source,
    Expression<String>? fingerprint,
    Expression<String>? aiModel,
    Expression<bool>? isFavorite,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (title != null) 'title': title,
      if (normalizedTitle != null) 'normalized_title': normalizedTitle,
      if (dishType != null) 'dish_type': dishType,
      if (dishGroup != null) 'dish_group': dishGroup,
      if (difficulty != null) 'difficulty': difficulty,
      if (cuisine != null) 'cuisine': cuisine,
      if (totalMinutes != null) 'total_minutes': totalMinutes,
      if (activeMinutes != null) 'active_minutes': activeMinutes,
      if (cookMinutes != null) 'cook_minutes': cookMinutes,
      if (kcalPerServing != null) 'kcal_per_serving': kcalPerServing,
      if (servings != null) 'servings': servings,
      if (description != null) 'description': description,
      if (source != null) 'source': source,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (aiModel != null) 'ai_model': aiModel,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipesCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? title,
    Value<String>? normalizedTitle,
    Value<DishType>? dishType,
    Value<DishGroup>? dishGroup,
    Value<Difficulty>? difficulty,
    Value<String>? cuisine,
    Value<int>? totalMinutes,
    Value<int>? activeMinutes,
    Value<int?>? cookMinutes,
    Value<int?>? kcalPerServing,
    Value<int>? servings,
    Value<String>? description,
    Value<RecipeSource>? source,
    Value<String>? fingerprint,
    Value<String?>? aiModel,
    Value<bool>? isFavorite,
    Value<int>? rowid,
  }) {
    return RecipesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      title: title ?? this.title,
      normalizedTitle: normalizedTitle ?? this.normalizedTitle,
      dishType: dishType ?? this.dishType,
      dishGroup: dishGroup ?? this.dishGroup,
      difficulty: difficulty ?? this.difficulty,
      cuisine: cuisine ?? this.cuisine,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      cookMinutes: cookMinutes ?? this.cookMinutes,
      kcalPerServing: kcalPerServing ?? this.kcalPerServing,
      servings: servings ?? this.servings,
      description: description ?? this.description,
      source: source ?? this.source,
      fingerprint: fingerprint ?? this.fingerprint,
      aiModel: aiModel ?? this.aiModel,
      isFavorite: isFavorite ?? this.isFavorite,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (normalizedTitle.present) {
      map['normalized_title'] = Variable<String>(normalizedTitle.value);
    }
    if (dishType.present) {
      map['dish_type'] = Variable<String>(
        $RecipesTable.$converterdishType.toSql(dishType.value),
      );
    }
    if (dishGroup.present) {
      map['dish_group'] = Variable<String>(
        $RecipesTable.$converterdishGroup.toSql(dishGroup.value),
      );
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(
        $RecipesTable.$converterdifficulty.toSql(difficulty.value),
      );
    }
    if (cuisine.present) {
      map['cuisine'] = Variable<String>(cuisine.value);
    }
    if (totalMinutes.present) {
      map['total_minutes'] = Variable<int>(totalMinutes.value);
    }
    if (activeMinutes.present) {
      map['active_minutes'] = Variable<int>(activeMinutes.value);
    }
    if (cookMinutes.present) {
      map['cook_minutes'] = Variable<int>(cookMinutes.value);
    }
    if (kcalPerServing.present) {
      map['kcal_per_serving'] = Variable<int>(kcalPerServing.value);
    }
    if (servings.present) {
      map['servings'] = Variable<int>(servings.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $RecipesTable.$convertersource.toSql(source.value),
      );
    }
    if (fingerprint.present) {
      map['fingerprint'] = Variable<String>(fingerprint.value);
    }
    if (aiModel.present) {
      map['ai_model'] = Variable<String>(aiModel.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('title: $title, ')
          ..write('normalizedTitle: $normalizedTitle, ')
          ..write('dishType: $dishType, ')
          ..write('dishGroup: $dishGroup, ')
          ..write('difficulty: $difficulty, ')
          ..write('cuisine: $cuisine, ')
          ..write('totalMinutes: $totalMinutes, ')
          ..write('activeMinutes: $activeMinutes, ')
          ..write('cookMinutes: $cookMinutes, ')
          ..write('kcalPerServing: $kcalPerServing, ')
          ..write('servings: $servings, ')
          ..write('description: $description, ')
          ..write('source: $source, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('aiModel: $aiModel, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecipeIngredientsTable extends RecipeIngredients
    with TableInfo<$RecipeIngredientsTable, RecipeIngredient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeIngredientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: () => clock.now().toUtc().millisecondsSinceEpoch,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: () => clock.now().toUtc().millisecondsSinceEpoch,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
    'recipe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ingredientIdMeta = const VerificationMeta(
    'ingredientId',
  );
  @override
  late final GeneratedColumn<String> ingredientId = GeneratedColumn<String>(
    'ingredient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isOptionalMeta = const VerificationMeta(
    'isOptional',
  );
  @override
  late final GeneratedColumn<bool> isOptional = GeneratedColumn<bool>(
    'is_optional',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_optional" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    recipeId,
    ingredientId,
    amount,
    unit,
    isOptional,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_ingredients';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeIngredient> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('ingredient_id')) {
      context.handle(
        _ingredientIdMeta,
        ingredientId.isAcceptableOrUnknown(
          data['ingredient_id']!,
          _ingredientIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ingredientIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('is_optional')) {
      context.handle(
        _isOptionalMeta,
        isOptional.isAcceptableOrUnknown(data['is_optional']!, _isOptionalMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecipeIngredient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeIngredient(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_id'],
      )!,
      ingredientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ingredient_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      isOptional: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_optional'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $RecipeIngredientsTable createAlias(String alias) {
    return $RecipeIngredientsTable(attachedDatabase, alias);
  }
}

class RecipeIngredient extends DataClass
    implements Insertable<RecipeIngredient> {
  final String id;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  final String recipeId;
  final String ingredientId;
  final double? amount;
  final String? unit;
  final bool isOptional;
  final String? note;
  const RecipeIngredient({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.recipeId,
    required this.ingredientId,
    this.amount,
    this.unit,
    required this.isOptional,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['recipe_id'] = Variable<String>(recipeId);
    map['ingredient_id'] = Variable<String>(ingredientId);
    if (!nullToAbsent || amount != null) {
      map['amount'] = Variable<double>(amount);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['is_optional'] = Variable<bool>(isOptional);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  RecipeIngredientsCompanion toCompanion(bool nullToAbsent) {
    return RecipeIngredientsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      recipeId: Value(recipeId),
      ingredientId: Value(ingredientId),
      amount: amount == null && nullToAbsent
          ? const Value.absent()
          : Value(amount),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      isOptional: Value(isOptional),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory RecipeIngredient.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeIngredient(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      recipeId: serializer.fromJson<String>(json['recipeId']),
      ingredientId: serializer.fromJson<String>(json['ingredientId']),
      amount: serializer.fromJson<double?>(json['amount']),
      unit: serializer.fromJson<String?>(json['unit']),
      isOptional: serializer.fromJson<bool>(json['isOptional']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'recipeId': serializer.toJson<String>(recipeId),
      'ingredientId': serializer.toJson<String>(ingredientId),
      'amount': serializer.toJson<double?>(amount),
      'unit': serializer.toJson<String?>(unit),
      'isOptional': serializer.toJson<bool>(isOptional),
      'note': serializer.toJson<String?>(note),
    };
  }

  RecipeIngredient copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? recipeId,
    String? ingredientId,
    Value<double?> amount = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    bool? isOptional,
    Value<String?> note = const Value.absent(),
  }) => RecipeIngredient(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    recipeId: recipeId ?? this.recipeId,
    ingredientId: ingredientId ?? this.ingredientId,
    amount: amount.present ? amount.value : this.amount,
    unit: unit.present ? unit.value : this.unit,
    isOptional: isOptional ?? this.isOptional,
    note: note.present ? note.value : this.note,
  );
  RecipeIngredient copyWithCompanion(RecipeIngredientsCompanion data) {
    return RecipeIngredient(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      ingredientId: data.ingredientId.present
          ? data.ingredientId.value
          : this.ingredientId,
      amount: data.amount.present ? data.amount.value : this.amount,
      unit: data.unit.present ? data.unit.value : this.unit,
      isOptional: data.isOptional.present
          ? data.isOptional.value
          : this.isOptional,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeIngredient(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('recipeId: $recipeId, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('amount: $amount, ')
          ..write('unit: $unit, ')
          ..write('isOptional: $isOptional, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    recipeId,
    ingredientId,
    amount,
    unit,
    isOptional,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeIngredient &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.recipeId == this.recipeId &&
          other.ingredientId == this.ingredientId &&
          other.amount == this.amount &&
          other.unit == this.unit &&
          other.isOptional == this.isOptional &&
          other.note == this.note);
}

class RecipeIngredientsCompanion extends UpdateCompanion<RecipeIngredient> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> recipeId;
  final Value<String> ingredientId;
  final Value<double?> amount;
  final Value<String?> unit;
  final Value<bool> isOptional;
  final Value<String?> note;
  final Value<int> rowid;
  const RecipeIngredientsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.ingredientId = const Value.absent(),
    this.amount = const Value.absent(),
    this.unit = const Value.absent(),
    this.isOptional = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipeIngredientsCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String recipeId,
    required String ingredientId,
    this.amount = const Value.absent(),
    this.unit = const Value.absent(),
    this.isOptional = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : recipeId = Value(recipeId),
       ingredientId = Value(ingredientId);
  static Insertable<RecipeIngredient> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? recipeId,
    Expression<String>? ingredientId,
    Expression<double>? amount,
    Expression<String>? unit,
    Expression<bool>? isOptional,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (recipeId != null) 'recipe_id': recipeId,
      if (ingredientId != null) 'ingredient_id': ingredientId,
      if (amount != null) 'amount': amount,
      if (unit != null) 'unit': unit,
      if (isOptional != null) 'is_optional': isOptional,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipeIngredientsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? recipeId,
    Value<String>? ingredientId,
    Value<double?>? amount,
    Value<String?>? unit,
    Value<bool>? isOptional,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return RecipeIngredientsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      recipeId: recipeId ?? this.recipeId,
      ingredientId: ingredientId ?? this.ingredientId,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      isOptional: isOptional ?? this.isOptional,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (ingredientId.present) {
      map['ingredient_id'] = Variable<String>(ingredientId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (isOptional.present) {
      map['is_optional'] = Variable<bool>(isOptional.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeIngredientsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('recipeId: $recipeId, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('amount: $amount, ')
          ..write('unit: $unit, ')
          ..write('isOptional: $isOptional, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecipeStepsTable extends RecipeSteps
    with TableInfo<$RecipeStepsTable, RecipeStep> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeStepsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: () => clock.now().toUtc().millisecondsSinceEpoch,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: () => clock.now().toUtc().millisecondsSinceEpoch,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
    'recipe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textContentMeta = const VerificationMeta(
    'textContent',
  );
  @override
  late final GeneratedColumn<String> textContent = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timerSecondsMeta = const VerificationMeta(
    'timerSeconds',
  );
  @override
  late final GeneratedColumn<int> timerSeconds = GeneratedColumn<int>(
    'timer_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tipMeta = const VerificationMeta('tip');
  @override
  late final GeneratedColumn<String> tip = GeneratedColumn<String>(
    'tip',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    recipeId,
    position,
    textContent,
    timerSeconds,
    tip,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_steps';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeStep> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _textContentMeta,
        textContent.isAcceptableOrUnknown(data['text']!, _textContentMeta),
      );
    } else if (isInserting) {
      context.missing(_textContentMeta);
    }
    if (data.containsKey('timer_seconds')) {
      context.handle(
        _timerSecondsMeta,
        timerSeconds.isAcceptableOrUnknown(
          data['timer_seconds']!,
          _timerSecondsMeta,
        ),
      );
    }
    if (data.containsKey('tip')) {
      context.handle(
        _tipMeta,
        tip.isAcceptableOrUnknown(data['tip']!, _tipMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecipeStep map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeStep(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      textContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      timerSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timer_seconds'],
      ),
      tip: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tip'],
      ),
    );
  }

  @override
  $RecipeStepsTable createAlias(String alias) {
    return $RecipeStepsTable(attachedDatabase, alias);
  }
}

class RecipeStep extends DataClass implements Insertable<RecipeStep> {
  final String id;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  final String recipeId;
  final int position;
  final String textContent;
  final int? timerSeconds;
  final String? tip;
  const RecipeStep({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.recipeId,
    required this.position,
    required this.textContent,
    this.timerSeconds,
    this.tip,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['recipe_id'] = Variable<String>(recipeId);
    map['position'] = Variable<int>(position);
    map['text'] = Variable<String>(textContent);
    if (!nullToAbsent || timerSeconds != null) {
      map['timer_seconds'] = Variable<int>(timerSeconds);
    }
    if (!nullToAbsent || tip != null) {
      map['tip'] = Variable<String>(tip);
    }
    return map;
  }

  RecipeStepsCompanion toCompanion(bool nullToAbsent) {
    return RecipeStepsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      recipeId: Value(recipeId),
      position: Value(position),
      textContent: Value(textContent),
      timerSeconds: timerSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(timerSeconds),
      tip: tip == null && nullToAbsent ? const Value.absent() : Value(tip),
    );
  }

  factory RecipeStep.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeStep(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      recipeId: serializer.fromJson<String>(json['recipeId']),
      position: serializer.fromJson<int>(json['position']),
      textContent: serializer.fromJson<String>(json['textContent']),
      timerSeconds: serializer.fromJson<int?>(json['timerSeconds']),
      tip: serializer.fromJson<String?>(json['tip']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'recipeId': serializer.toJson<String>(recipeId),
      'position': serializer.toJson<int>(position),
      'textContent': serializer.toJson<String>(textContent),
      'timerSeconds': serializer.toJson<int?>(timerSeconds),
      'tip': serializer.toJson<String?>(tip),
    };
  }

  RecipeStep copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? recipeId,
    int? position,
    String? textContent,
    Value<int?> timerSeconds = const Value.absent(),
    Value<String?> tip = const Value.absent(),
  }) => RecipeStep(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    recipeId: recipeId ?? this.recipeId,
    position: position ?? this.position,
    textContent: textContent ?? this.textContent,
    timerSeconds: timerSeconds.present ? timerSeconds.value : this.timerSeconds,
    tip: tip.present ? tip.value : this.tip,
  );
  RecipeStep copyWithCompanion(RecipeStepsCompanion data) {
    return RecipeStep(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      position: data.position.present ? data.position.value : this.position,
      textContent: data.textContent.present
          ? data.textContent.value
          : this.textContent,
      timerSeconds: data.timerSeconds.present
          ? data.timerSeconds.value
          : this.timerSeconds,
      tip: data.tip.present ? data.tip.value : this.tip,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeStep(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('recipeId: $recipeId, ')
          ..write('position: $position, ')
          ..write('textContent: $textContent, ')
          ..write('timerSeconds: $timerSeconds, ')
          ..write('tip: $tip')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    recipeId,
    position,
    textContent,
    timerSeconds,
    tip,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeStep &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.recipeId == this.recipeId &&
          other.position == this.position &&
          other.textContent == this.textContent &&
          other.timerSeconds == this.timerSeconds &&
          other.tip == this.tip);
}

class RecipeStepsCompanion extends UpdateCompanion<RecipeStep> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> recipeId;
  final Value<int> position;
  final Value<String> textContent;
  final Value<int?> timerSeconds;
  final Value<String?> tip;
  final Value<int> rowid;
  const RecipeStepsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.position = const Value.absent(),
    this.textContent = const Value.absent(),
    this.timerSeconds = const Value.absent(),
    this.tip = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipeStepsCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String recipeId,
    required int position,
    required String textContent,
    this.timerSeconds = const Value.absent(),
    this.tip = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : recipeId = Value(recipeId),
       position = Value(position),
       textContent = Value(textContent);
  static Insertable<RecipeStep> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? recipeId,
    Expression<int>? position,
    Expression<String>? textContent,
    Expression<int>? timerSeconds,
    Expression<String>? tip,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (recipeId != null) 'recipe_id': recipeId,
      if (position != null) 'position': position,
      if (textContent != null) 'text': textContent,
      if (timerSeconds != null) 'timer_seconds': timerSeconds,
      if (tip != null) 'tip': tip,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipeStepsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? recipeId,
    Value<int>? position,
    Value<String>? textContent,
    Value<int?>? timerSeconds,
    Value<String?>? tip,
    Value<int>? rowid,
  }) {
    return RecipeStepsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      recipeId: recipeId ?? this.recipeId,
      position: position ?? this.position,
      textContent: textContent ?? this.textContent,
      timerSeconds: timerSeconds ?? this.timerSeconds,
      tip: tip ?? this.tip,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (textContent.present) {
      map['text'] = Variable<String>(textContent.value);
    }
    if (timerSeconds.present) {
      map['timer_seconds'] = Variable<int>(timerSeconds.value);
    }
    if (tip.present) {
      map['tip'] = Variable<String>(tip.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeStepsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('recipeId: $recipeId, ')
          ..write('position: $position, ')
          ..write('textContent: $textContent, ')
          ..write('timerSeconds: $timerSeconds, ')
          ..write('tip: $tip, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecipeTagsTable extends RecipeTags
    with TableInfo<$RecipeTagsTable, RecipeTagEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
    'recipe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recipes (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<TagKind, String> tagKind =
      GeneratedColumn<String>(
        'tag_kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TagKind>($RecipeTagsTable.$convertertagKind);
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [recipeId, tagKind, tag];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeTagEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('tag')) {
      context.handle(
        _tagMeta,
        tag.isAcceptableOrUnknown(data['tag']!, _tagMeta),
      );
    } else if (isInserting) {
      context.missing(_tagMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recipeId, tagKind, tag};
  @override
  RecipeTagEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeTagEntry(
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_id'],
      )!,
      tagKind: $RecipeTagsTable.$convertertagKind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}tag_kind'],
        )!,
      ),
      tag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag'],
      )!,
    );
  }

  @override
  $RecipeTagsTable createAlias(String alias) {
    return $RecipeTagsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TagKind, String, String> $convertertagKind =
      const EnumNameConverter<TagKind>(TagKind.values);
}

class RecipeTagEntry extends DataClass implements Insertable<RecipeTagEntry> {
  final String recipeId;
  final TagKind tagKind;
  final String tag;
  const RecipeTagEntry({
    required this.recipeId,
    required this.tagKind,
    required this.tag,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['recipe_id'] = Variable<String>(recipeId);
    {
      map['tag_kind'] = Variable<String>(
        $RecipeTagsTable.$convertertagKind.toSql(tagKind),
      );
    }
    map['tag'] = Variable<String>(tag);
    return map;
  }

  RecipeTagsCompanion toCompanion(bool nullToAbsent) {
    return RecipeTagsCompanion(
      recipeId: Value(recipeId),
      tagKind: Value(tagKind),
      tag: Value(tag),
    );
  }

  factory RecipeTagEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeTagEntry(
      recipeId: serializer.fromJson<String>(json['recipeId']),
      tagKind: $RecipeTagsTable.$convertertagKind.fromJson(
        serializer.fromJson<String>(json['tagKind']),
      ),
      tag: serializer.fromJson<String>(json['tag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recipeId': serializer.toJson<String>(recipeId),
      'tagKind': serializer.toJson<String>(
        $RecipeTagsTable.$convertertagKind.toJson(tagKind),
      ),
      'tag': serializer.toJson<String>(tag),
    };
  }

  RecipeTagEntry copyWith({String? recipeId, TagKind? tagKind, String? tag}) =>
      RecipeTagEntry(
        recipeId: recipeId ?? this.recipeId,
        tagKind: tagKind ?? this.tagKind,
        tag: tag ?? this.tag,
      );
  RecipeTagEntry copyWithCompanion(RecipeTagsCompanion data) {
    return RecipeTagEntry(
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      tagKind: data.tagKind.present ? data.tagKind.value : this.tagKind,
      tag: data.tag.present ? data.tag.value : this.tag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeTagEntry(')
          ..write('recipeId: $recipeId, ')
          ..write('tagKind: $tagKind, ')
          ..write('tag: $tag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(recipeId, tagKind, tag);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeTagEntry &&
          other.recipeId == this.recipeId &&
          other.tagKind == this.tagKind &&
          other.tag == this.tag);
}

class RecipeTagsCompanion extends UpdateCompanion<RecipeTagEntry> {
  final Value<String> recipeId;
  final Value<TagKind> tagKind;
  final Value<String> tag;
  final Value<int> rowid;
  const RecipeTagsCompanion({
    this.recipeId = const Value.absent(),
    this.tagKind = const Value.absent(),
    this.tag = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipeTagsCompanion.insert({
    required String recipeId,
    required TagKind tagKind,
    required String tag,
    this.rowid = const Value.absent(),
  }) : recipeId = Value(recipeId),
       tagKind = Value(tagKind),
       tag = Value(tag);
  static Insertable<RecipeTagEntry> custom({
    Expression<String>? recipeId,
    Expression<String>? tagKind,
    Expression<String>? tag,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (recipeId != null) 'recipe_id': recipeId,
      if (tagKind != null) 'tag_kind': tagKind,
      if (tag != null) 'tag': tag,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipeTagsCompanion copyWith({
    Value<String>? recipeId,
    Value<TagKind>? tagKind,
    Value<String>? tag,
    Value<int>? rowid,
  }) {
    return RecipeTagsCompanion(
      recipeId: recipeId ?? this.recipeId,
      tagKind: tagKind ?? this.tagKind,
      tag: tag ?? this.tag,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (tagKind.present) {
      map['tag_kind'] = Variable<String>(
        $RecipeTagsTable.$convertertagKind.toSql(tagKind.value),
      );
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeTagsCompanion(')
          ..write('recipeId: $recipeId, ')
          ..write('tagKind: $tagKind, ')
          ..write('tag: $tag, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CookedEntriesTable extends CookedEntries
    with TableInfo<$CookedEntriesTable, CookedEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CookedEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: () => clock.now().toUtc().millisecondsSinceEpoch,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: () => clock.now().toUtc().millisecondsSinceEpoch,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
    'recipe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cookedOnMeta = const VerificationMeta(
    'cookedOn',
  );
  @override
  late final GeneratedColumn<String> cookedOn = GeneratedColumn<String>(
    'cooked_on',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wouldRepeatMeta = const VerificationMeta(
    'wouldRepeat',
  );
  @override
  late final GeneratedColumn<bool> wouldRepeat = GeneratedColumn<bool>(
    'would_repeat',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("would_repeat" IN (0, 1))',
    ),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    recipeId,
    cookedOn,
    rating,
    wouldRepeat,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cooked_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<CookedEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('cooked_on')) {
      context.handle(
        _cookedOnMeta,
        cookedOn.isAcceptableOrUnknown(data['cooked_on']!, _cookedOnMeta),
      );
    } else if (isInserting) {
      context.missing(_cookedOnMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('would_repeat')) {
      context.handle(
        _wouldRepeatMeta,
        wouldRepeat.isAcceptableOrUnknown(
          data['would_repeat']!,
          _wouldRepeatMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CookedEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CookedEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_id'],
      )!,
      cookedOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cooked_on'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      ),
      wouldRepeat: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}would_repeat'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $CookedEntriesTable createAlias(String alias) {
    return $CookedEntriesTable(attachedDatabase, alias);
  }
}

class CookedEntry extends DataClass implements Insertable<CookedEntry> {
  final String id;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  final String recipeId;
  final String cookedOn;
  final int? rating;
  final bool? wouldRepeat;
  final String? note;
  const CookedEntry({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.recipeId,
    required this.cookedOn,
    this.rating,
    this.wouldRepeat,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['recipe_id'] = Variable<String>(recipeId);
    map['cooked_on'] = Variable<String>(cookedOn);
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<int>(rating);
    }
    if (!nullToAbsent || wouldRepeat != null) {
      map['would_repeat'] = Variable<bool>(wouldRepeat);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  CookedEntriesCompanion toCompanion(bool nullToAbsent) {
    return CookedEntriesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      recipeId: Value(recipeId),
      cookedOn: Value(cookedOn),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      wouldRepeat: wouldRepeat == null && nullToAbsent
          ? const Value.absent()
          : Value(wouldRepeat),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory CookedEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CookedEntry(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      recipeId: serializer.fromJson<String>(json['recipeId']),
      cookedOn: serializer.fromJson<String>(json['cookedOn']),
      rating: serializer.fromJson<int?>(json['rating']),
      wouldRepeat: serializer.fromJson<bool?>(json['wouldRepeat']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'recipeId': serializer.toJson<String>(recipeId),
      'cookedOn': serializer.toJson<String>(cookedOn),
      'rating': serializer.toJson<int?>(rating),
      'wouldRepeat': serializer.toJson<bool?>(wouldRepeat),
      'note': serializer.toJson<String?>(note),
    };
  }

  CookedEntry copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? recipeId,
    String? cookedOn,
    Value<int?> rating = const Value.absent(),
    Value<bool?> wouldRepeat = const Value.absent(),
    Value<String?> note = const Value.absent(),
  }) => CookedEntry(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    recipeId: recipeId ?? this.recipeId,
    cookedOn: cookedOn ?? this.cookedOn,
    rating: rating.present ? rating.value : this.rating,
    wouldRepeat: wouldRepeat.present ? wouldRepeat.value : this.wouldRepeat,
    note: note.present ? note.value : this.note,
  );
  CookedEntry copyWithCompanion(CookedEntriesCompanion data) {
    return CookedEntry(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      cookedOn: data.cookedOn.present ? data.cookedOn.value : this.cookedOn,
      rating: data.rating.present ? data.rating.value : this.rating,
      wouldRepeat: data.wouldRepeat.present
          ? data.wouldRepeat.value
          : this.wouldRepeat,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CookedEntry(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('recipeId: $recipeId, ')
          ..write('cookedOn: $cookedOn, ')
          ..write('rating: $rating, ')
          ..write('wouldRepeat: $wouldRepeat, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    recipeId,
    cookedOn,
    rating,
    wouldRepeat,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CookedEntry &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.recipeId == this.recipeId &&
          other.cookedOn == this.cookedOn &&
          other.rating == this.rating &&
          other.wouldRepeat == this.wouldRepeat &&
          other.note == this.note);
}

class CookedEntriesCompanion extends UpdateCompanion<CookedEntry> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> recipeId;
  final Value<String> cookedOn;
  final Value<int?> rating;
  final Value<bool?> wouldRepeat;
  final Value<String?> note;
  final Value<int> rowid;
  const CookedEntriesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.cookedOn = const Value.absent(),
    this.rating = const Value.absent(),
    this.wouldRepeat = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CookedEntriesCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String recipeId,
    required String cookedOn,
    this.rating = const Value.absent(),
    this.wouldRepeat = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : recipeId = Value(recipeId),
       cookedOn = Value(cookedOn);
  static Insertable<CookedEntry> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? recipeId,
    Expression<String>? cookedOn,
    Expression<int>? rating,
    Expression<bool>? wouldRepeat,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (recipeId != null) 'recipe_id': recipeId,
      if (cookedOn != null) 'cooked_on': cookedOn,
      if (rating != null) 'rating': rating,
      if (wouldRepeat != null) 'would_repeat': wouldRepeat,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CookedEntriesCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? recipeId,
    Value<String>? cookedOn,
    Value<int?>? rating,
    Value<bool?>? wouldRepeat,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return CookedEntriesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      recipeId: recipeId ?? this.recipeId,
      cookedOn: cookedOn ?? this.cookedOn,
      rating: rating ?? this.rating,
      wouldRepeat: wouldRepeat ?? this.wouldRepeat,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (cookedOn.present) {
      map['cooked_on'] = Variable<String>(cookedOn.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (wouldRepeat.present) {
      map['would_repeat'] = Variable<bool>(wouldRepeat.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CookedEntriesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('recipeId: $recipeId, ')
          ..write('cookedOn: $cookedOn, ')
          ..write('rating: $rating, ')
          ..write('wouldRepeat: $wouldRepeat, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MealPlanEntriesTable extends MealPlanEntries
    with TableInfo<$MealPlanEntriesTable, MealPlanEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealPlanEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: () => clock.now().toUtc().millisecondsSinceEpoch,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: () => clock.now().toUtc().millisecondsSinceEpoch,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
    'recipe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mealSlotMeta = const VerificationMeta(
    'mealSlot',
  );
  @override
  late final GeneratedColumn<String> mealSlot = GeneratedColumn<String>(
    'meal_slot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('main'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<MealPlanStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(MealPlanStatus.planned.name),
      ).withConverter<MealPlanStatus>($MealPlanEntriesTable.$converterstatus);
  static const VerificationMeta _lockedMeta = const VerificationMeta('locked');
  @override
  late final GeneratedColumn<bool> locked = GeneratedColumn<bool>(
    'locked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("locked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    date,
    recipeId,
    mealSlot,
    status,
    locked,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_plan_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealPlanEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('meal_slot')) {
      context.handle(
        _mealSlotMeta,
        mealSlot.isAcceptableOrUnknown(data['meal_slot']!, _mealSlotMeta),
      );
    }
    if (data.containsKey('locked')) {
      context.handle(
        _lockedMeta,
        locked.isAcceptableOrUnknown(data['locked']!, _lockedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealPlanEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealPlanEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_id'],
      )!,
      mealSlot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meal_slot'],
      )!,
      status: $MealPlanEntriesTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      locked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}locked'],
      )!,
    );
  }

  @override
  $MealPlanEntriesTable createAlias(String alias) {
    return $MealPlanEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MealPlanStatus, String, String> $converterstatus =
      const EnumNameConverter<MealPlanStatus>(MealPlanStatus.values);
}

class MealPlanEntry extends DataClass implements Insertable<MealPlanEntry> {
  final String id;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  final String date;
  final String recipeId;
  final String mealSlot;
  final MealPlanStatus status;
  final bool locked;
  const MealPlanEntry({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.date,
    required this.recipeId,
    required this.mealSlot,
    required this.status,
    required this.locked,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['date'] = Variable<String>(date);
    map['recipe_id'] = Variable<String>(recipeId);
    map['meal_slot'] = Variable<String>(mealSlot);
    {
      map['status'] = Variable<String>(
        $MealPlanEntriesTable.$converterstatus.toSql(status),
      );
    }
    map['locked'] = Variable<bool>(locked);
    return map;
  }

  MealPlanEntriesCompanion toCompanion(bool nullToAbsent) {
    return MealPlanEntriesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      date: Value(date),
      recipeId: Value(recipeId),
      mealSlot: Value(mealSlot),
      status: Value(status),
      locked: Value(locked),
    );
  }

  factory MealPlanEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealPlanEntry(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      date: serializer.fromJson<String>(json['date']),
      recipeId: serializer.fromJson<String>(json['recipeId']),
      mealSlot: serializer.fromJson<String>(json['mealSlot']),
      status: $MealPlanEntriesTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      locked: serializer.fromJson<bool>(json['locked']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'date': serializer.toJson<String>(date),
      'recipeId': serializer.toJson<String>(recipeId),
      'mealSlot': serializer.toJson<String>(mealSlot),
      'status': serializer.toJson<String>(
        $MealPlanEntriesTable.$converterstatus.toJson(status),
      ),
      'locked': serializer.toJson<bool>(locked),
    };
  }

  MealPlanEntry copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? date,
    String? recipeId,
    String? mealSlot,
    MealPlanStatus? status,
    bool? locked,
  }) => MealPlanEntry(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    date: date ?? this.date,
    recipeId: recipeId ?? this.recipeId,
    mealSlot: mealSlot ?? this.mealSlot,
    status: status ?? this.status,
    locked: locked ?? this.locked,
  );
  MealPlanEntry copyWithCompanion(MealPlanEntriesCompanion data) {
    return MealPlanEntry(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      date: data.date.present ? data.date.value : this.date,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      mealSlot: data.mealSlot.present ? data.mealSlot.value : this.mealSlot,
      status: data.status.present ? data.status.value : this.status,
      locked: data.locked.present ? data.locked.value : this.locked,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealPlanEntry(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('date: $date, ')
          ..write('recipeId: $recipeId, ')
          ..write('mealSlot: $mealSlot, ')
          ..write('status: $status, ')
          ..write('locked: $locked')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    date,
    recipeId,
    mealSlot,
    status,
    locked,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealPlanEntry &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.date == this.date &&
          other.recipeId == this.recipeId &&
          other.mealSlot == this.mealSlot &&
          other.status == this.status &&
          other.locked == this.locked);
}

class MealPlanEntriesCompanion extends UpdateCompanion<MealPlanEntry> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> date;
  final Value<String> recipeId;
  final Value<String> mealSlot;
  final Value<MealPlanStatus> status;
  final Value<bool> locked;
  final Value<int> rowid;
  const MealPlanEntriesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.date = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.mealSlot = const Value.absent(),
    this.status = const Value.absent(),
    this.locked = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealPlanEntriesCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String date,
    required String recipeId,
    this.mealSlot = const Value.absent(),
    this.status = const Value.absent(),
    this.locked = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       recipeId = Value(recipeId);
  static Insertable<MealPlanEntry> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? date,
    Expression<String>? recipeId,
    Expression<String>? mealSlot,
    Expression<String>? status,
    Expression<bool>? locked,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (date != null) 'date': date,
      if (recipeId != null) 'recipe_id': recipeId,
      if (mealSlot != null) 'meal_slot': mealSlot,
      if (status != null) 'status': status,
      if (locked != null) 'locked': locked,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealPlanEntriesCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? date,
    Value<String>? recipeId,
    Value<String>? mealSlot,
    Value<MealPlanStatus>? status,
    Value<bool>? locked,
    Value<int>? rowid,
  }) {
    return MealPlanEntriesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      date: date ?? this.date,
      recipeId: recipeId ?? this.recipeId,
      mealSlot: mealSlot ?? this.mealSlot,
      status: status ?? this.status,
      locked: locked ?? this.locked,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (mealSlot.present) {
      map['meal_slot'] = Variable<String>(mealSlot.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $MealPlanEntriesTable.$converterstatus.toSql(status.value),
      );
    }
    if (locked.present) {
      map['locked'] = Variable<bool>(locked.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealPlanEntriesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('date: $date, ')
          ..write('recipeId: $recipeId, ')
          ..write('mealSlot: $mealSlot, ')
          ..write('status: $status, ')
          ..write('locked: $locked, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FeedbackEventsTable extends FeedbackEvents
    with TableInfo<$FeedbackEventsTable, FeedbackEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FeedbackEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: () => clock.now().toUtc().millisecondsSinceEpoch,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: () => clock.now().toUtc().millisecondsSinceEpoch,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
    'recipe_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<FeedbackKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<FeedbackKind>($FeedbackEventsTable.$converterkind);
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<int> at = GeneratedColumn<int>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc().millisecondsSinceEpoch,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    recipeId,
    kind,
    reason,
    at,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'feedback_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<FeedbackEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FeedbackEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FeedbackEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_id'],
      ),
      kind: $FeedbackEventsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $FeedbackEventsTable createAlias(String alias) {
    return $FeedbackEventsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<FeedbackKind, String, String> $converterkind =
      const EnumNameConverter<FeedbackKind>(FeedbackKind.values);
}

class FeedbackEvent extends DataClass implements Insertable<FeedbackEvent> {
  final String id;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  final String? recipeId;
  final FeedbackKind kind;
  final String? reason;
  final int at;
  const FeedbackEvent({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.recipeId,
    required this.kind,
    this.reason,
    required this.at,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || recipeId != null) {
      map['recipe_id'] = Variable<String>(recipeId);
    }
    {
      map['kind'] = Variable<String>(
        $FeedbackEventsTable.$converterkind.toSql(kind),
      );
    }
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    map['at'] = Variable<int>(at);
    return map;
  }

  FeedbackEventsCompanion toCompanion(bool nullToAbsent) {
    return FeedbackEventsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      recipeId: recipeId == null && nullToAbsent
          ? const Value.absent()
          : Value(recipeId),
      kind: Value(kind),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      at: Value(at),
    );
  }

  factory FeedbackEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FeedbackEvent(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      recipeId: serializer.fromJson<String?>(json['recipeId']),
      kind: $FeedbackEventsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      reason: serializer.fromJson<String?>(json['reason']),
      at: serializer.fromJson<int>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'recipeId': serializer.toJson<String?>(recipeId),
      'kind': serializer.toJson<String>(
        $FeedbackEventsTable.$converterkind.toJson(kind),
      ),
      'reason': serializer.toJson<String?>(reason),
      'at': serializer.toJson<int>(at),
    };
  }

  FeedbackEvent copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    Value<String?> recipeId = const Value.absent(),
    FeedbackKind? kind,
    Value<String?> reason = const Value.absent(),
    int? at,
  }) => FeedbackEvent(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    recipeId: recipeId.present ? recipeId.value : this.recipeId,
    kind: kind ?? this.kind,
    reason: reason.present ? reason.value : this.reason,
    at: at ?? this.at,
  );
  FeedbackEvent copyWithCompanion(FeedbackEventsCompanion data) {
    return FeedbackEvent(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      kind: data.kind.present ? data.kind.value : this.kind,
      reason: data.reason.present ? data.reason.value : this.reason,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FeedbackEvent(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('recipeId: $recipeId, ')
          ..write('kind: $kind, ')
          ..write('reason: $reason, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    recipeId,
    kind,
    reason,
    at,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FeedbackEvent &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.recipeId == this.recipeId &&
          other.kind == this.kind &&
          other.reason == this.reason &&
          other.at == this.at);
}

class FeedbackEventsCompanion extends UpdateCompanion<FeedbackEvent> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String?> recipeId;
  final Value<FeedbackKind> kind;
  final Value<String?> reason;
  final Value<int> at;
  final Value<int> rowid;
  const FeedbackEventsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.kind = const Value.absent(),
    this.reason = const Value.absent(),
    this.at = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FeedbackEventsCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.recipeId = const Value.absent(),
    required FeedbackKind kind,
    this.reason = const Value.absent(),
    this.at = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : kind = Value(kind);
  static Insertable<FeedbackEvent> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? recipeId,
    Expression<String>? kind,
    Expression<String>? reason,
    Expression<int>? at,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (recipeId != null) 'recipe_id': recipeId,
      if (kind != null) 'kind': kind,
      if (reason != null) 'reason': reason,
      if (at != null) 'at': at,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FeedbackEventsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String?>? recipeId,
    Value<FeedbackKind>? kind,
    Value<String?>? reason,
    Value<int>? at,
    Value<int>? rowid,
  }) {
    return FeedbackEventsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      recipeId: recipeId ?? this.recipeId,
      kind: kind ?? this.kind,
      reason: reason ?? this.reason,
      at: at ?? this.at,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $FeedbackEventsTable.$converterkind.toSql(kind.value),
      );
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (at.present) {
      map['at'] = Variable<int>(at.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FeedbackEventsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('recipeId: $recipeId, ')
          ..write('kind: $kind, ')
          ..write('reason: $reason, ')
          ..write('at: $at, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FeedEventsTable extends FeedEvents
    with TableInfo<$FeedEventsTable, FeedEventEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FeedEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: () => clock.now().toUtc().millisecondsSinceEpoch,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: () => clock.now().toUtc().millisecondsSinceEpoch,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
    'recipe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recipes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _eventMeta = const VerificationMeta('event');
  @override
  late final GeneratedColumn<String> event = GeneratedColumn<String>(
    'event',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contextJsonMeta = const VerificationMeta(
    'contextJson',
  );
  @override
  late final GeneratedColumn<String> contextJson = GeneratedColumn<String>(
    'context_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<int> at = GeneratedColumn<int>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: () => clock.now().toUtc().millisecondsSinceEpoch,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    recipeId,
    event,
    rating,
    contextJson,
    at,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'feed_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<FeedEventEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('event')) {
      context.handle(
        _eventMeta,
        event.isAcceptableOrUnknown(data['event']!, _eventMeta),
      );
    } else if (isInserting) {
      context.missing(_eventMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('context_json')) {
      context.handle(
        _contextJsonMeta,
        contextJson.isAcceptableOrUnknown(
          data['context_json']!,
          _contextJsonMeta,
        ),
      );
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FeedEventEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FeedEventEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_id'],
      )!,
      event: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      ),
      contextJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context_json'],
      ),
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $FeedEventsTable createAlias(String alias) {
    return $FeedEventsTable(attachedDatabase, alias);
  }
}

class FeedEventEntry extends DataClass implements Insertable<FeedEventEntry> {
  final String id;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  final String recipeId;

  /// Event type: 'shown', 'opened', 'cooked', 'skipped', 'rated'
  final String event;

  /// Rating 1..5 when event is 'rated', or null for other interactions.
  final int? rating;

  /// JSON payload recording the recommendation context (occasion, mood, etc.)
  final String? contextJson;

  /// Timestamp in milliseconds since epoch
  final int at;
  const FeedEventEntry({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.recipeId,
    required this.event,
    this.rating,
    this.contextJson,
    required this.at,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['recipe_id'] = Variable<String>(recipeId);
    map['event'] = Variable<String>(event);
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<int>(rating);
    }
    if (!nullToAbsent || contextJson != null) {
      map['context_json'] = Variable<String>(contextJson);
    }
    map['at'] = Variable<int>(at);
    return map;
  }

  FeedEventsCompanion toCompanion(bool nullToAbsent) {
    return FeedEventsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      recipeId: Value(recipeId),
      event: Value(event),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      contextJson: contextJson == null && nullToAbsent
          ? const Value.absent()
          : Value(contextJson),
      at: Value(at),
    );
  }

  factory FeedEventEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FeedEventEntry(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      recipeId: serializer.fromJson<String>(json['recipeId']),
      event: serializer.fromJson<String>(json['event']),
      rating: serializer.fromJson<int?>(json['rating']),
      contextJson: serializer.fromJson<String?>(json['contextJson']),
      at: serializer.fromJson<int>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'recipeId': serializer.toJson<String>(recipeId),
      'event': serializer.toJson<String>(event),
      'rating': serializer.toJson<int?>(rating),
      'contextJson': serializer.toJson<String?>(contextJson),
      'at': serializer.toJson<int>(at),
    };
  }

  FeedEventEntry copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? recipeId,
    String? event,
    Value<int?> rating = const Value.absent(),
    Value<String?> contextJson = const Value.absent(),
    int? at,
  }) => FeedEventEntry(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    recipeId: recipeId ?? this.recipeId,
    event: event ?? this.event,
    rating: rating.present ? rating.value : this.rating,
    contextJson: contextJson.present ? contextJson.value : this.contextJson,
    at: at ?? this.at,
  );
  FeedEventEntry copyWithCompanion(FeedEventsCompanion data) {
    return FeedEventEntry(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      event: data.event.present ? data.event.value : this.event,
      rating: data.rating.present ? data.rating.value : this.rating,
      contextJson: data.contextJson.present
          ? data.contextJson.value
          : this.contextJson,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FeedEventEntry(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('recipeId: $recipeId, ')
          ..write('event: $event, ')
          ..write('rating: $rating, ')
          ..write('contextJson: $contextJson, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    recipeId,
    event,
    rating,
    contextJson,
    at,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FeedEventEntry &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.recipeId == this.recipeId &&
          other.event == this.event &&
          other.rating == this.rating &&
          other.contextJson == this.contextJson &&
          other.at == this.at);
}

class FeedEventsCompanion extends UpdateCompanion<FeedEventEntry> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> recipeId;
  final Value<String> event;
  final Value<int?> rating;
  final Value<String?> contextJson;
  final Value<int> at;
  final Value<int> rowid;
  const FeedEventsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.event = const Value.absent(),
    this.rating = const Value.absent(),
    this.contextJson = const Value.absent(),
    this.at = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FeedEventsCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String recipeId,
    required String event,
    this.rating = const Value.absent(),
    this.contextJson = const Value.absent(),
    this.at = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : recipeId = Value(recipeId),
       event = Value(event);
  static Insertable<FeedEventEntry> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? recipeId,
    Expression<String>? event,
    Expression<int>? rating,
    Expression<String>? contextJson,
    Expression<int>? at,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (recipeId != null) 'recipe_id': recipeId,
      if (event != null) 'event': event,
      if (rating != null) 'rating': rating,
      if (contextJson != null) 'context_json': contextJson,
      if (at != null) 'at': at,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FeedEventsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? recipeId,
    Value<String>? event,
    Value<int?>? rating,
    Value<String?>? contextJson,
    Value<int>? at,
    Value<int>? rowid,
  }) {
    return FeedEventsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      recipeId: recipeId ?? this.recipeId,
      event: event ?? this.event,
      rating: rating ?? this.rating,
      contextJson: contextJson ?? this.contextJson,
      at: at ?? this.at,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (event.present) {
      map['event'] = Variable<String>(event.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (contextJson.present) {
      map['context_json'] = Variable<String>(contextJson.value);
    }
    if (at.present) {
      map['at'] = Variable<int>(at.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FeedEventsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('recipeId: $recipeId, ')
          ..write('event: $event, ')
          ..write('rating: $rating, ')
          ..write('contextJson: $contextJson, ')
          ..write('at: $at, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PreferenceProfileTable extends PreferenceProfile
    with TableInfo<$PreferenceProfileTable, PreferenceProfileData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreferenceProfileTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: () => clock.now().toUtc().millisecondsSinceEpoch,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: () => clock.now().toUtc().millisecondsSinceEpoch,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, dynamic>, String>
  dishTypeWeights =
      GeneratedColumn<String>(
        'dish_type_weights',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      ).withConverter<Map<String, dynamic>>(
        $PreferenceProfileTable.$converterdishTypeWeights,
      );
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, dynamic>, String>
  ingredientWeights =
      GeneratedColumn<String>(
        'ingredient_weights',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      ).withConverter<Map<String, dynamic>>(
        $PreferenceProfileTable.$converteringredientWeights,
      );
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, dynamic>, String>
  cuisineWeights =
      GeneratedColumn<String>(
        'cuisine_weights',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      ).withConverter<Map<String, dynamic>>(
        $PreferenceProfileTable.$convertercuisineWeights,
      );
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, dynamic>, String>
  difficultyWeights =
      GeneratedColumn<String>(
        'difficulty_weights',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      ).withConverter<Map<String, dynamic>>(
        $PreferenceProfileTable.$converterdifficultyWeights,
      );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  excludedIngredients =
      GeneratedColumn<String>(
        'excluded_ingredients',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<String>>(
        $PreferenceProfileTable.$converterexcludedIngredients,
      );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> allergies =
      GeneratedColumn<String>(
        'allergies',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<String>>(
        $PreferenceProfileTable.$converterallergies,
      );
  static const VerificationMeta _maxTotalMinutesMeta = const VerificationMeta(
    'maxTotalMinutes',
  );
  @override
  late final GeneratedColumn<int> maxTotalMinutes = GeneratedColumn<int>(
    'max_total_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _servingsDefaultMeta = const VerificationMeta(
    'servingsDefault',
  );
  @override
  late final GeneratedColumn<int> servingsDefault = GeneratedColumn<int>(
    'servings_default',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    dishTypeWeights,
    ingredientWeights,
    cuisineWeights,
    difficultyWeights,
    excludedIngredients,
    allergies,
    maxTotalMinutes,
    servingsDefault,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preference_profile';
  @override
  VerificationContext validateIntegrity(
    Insertable<PreferenceProfileData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('max_total_minutes')) {
      context.handle(
        _maxTotalMinutesMeta,
        maxTotalMinutes.isAcceptableOrUnknown(
          data['max_total_minutes']!,
          _maxTotalMinutesMeta,
        ),
      );
    }
    if (data.containsKey('servings_default')) {
      context.handle(
        _servingsDefaultMeta,
        servingsDefault.isAcceptableOrUnknown(
          data['servings_default']!,
          _servingsDefaultMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PreferenceProfileData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PreferenceProfileData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      dishTypeWeights: $PreferenceProfileTable.$converterdishTypeWeights
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}dish_type_weights'],
            )!,
          ),
      ingredientWeights: $PreferenceProfileTable.$converteringredientWeights
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}ingredient_weights'],
            )!,
          ),
      cuisineWeights: $PreferenceProfileTable.$convertercuisineWeights.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}cuisine_weights'],
        )!,
      ),
      difficultyWeights: $PreferenceProfileTable.$converterdifficultyWeights
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}difficulty_weights'],
            )!,
          ),
      excludedIngredients: $PreferenceProfileTable.$converterexcludedIngredients
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}excluded_ingredients'],
            )!,
          ),
      allergies: $PreferenceProfileTable.$converterallergies.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}allergies'],
        )!,
      ),
      maxTotalMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_total_minutes'],
      ),
      servingsDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}servings_default'],
      )!,
    );
  }

  @override
  $PreferenceProfileTable createAlias(String alias) {
    return $PreferenceProfileTable(attachedDatabase, alias);
  }

  static TypeConverter<Map<String, dynamic>, String> $converterdishTypeWeights =
      const StringMapConverter();
  static TypeConverter<Map<String, dynamic>, String>
  $converteringredientWeights = const StringMapConverter();
  static TypeConverter<Map<String, dynamic>, String> $convertercuisineWeights =
      const StringMapConverter();
  static TypeConverter<Map<String, dynamic>, String>
  $converterdifficultyWeights = const StringMapConverter();
  static TypeConverter<List<String>, String> $converterexcludedIngredients =
      const StringListConverter();
  static TypeConverter<List<String>, String> $converterallergies =
      const StringListConverter();
}

class PreferenceProfileData extends DataClass
    implements Insertable<PreferenceProfileData> {
  final String id;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  final Map<String, dynamic> dishTypeWeights;
  final Map<String, dynamic> ingredientWeights;
  final Map<String, dynamic> cuisineWeights;
  final Map<String, dynamic> difficultyWeights;
  final List<String> excludedIngredients;
  final List<String> allergies;
  final int? maxTotalMinutes;
  final int servingsDefault;
  const PreferenceProfileData({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.dishTypeWeights,
    required this.ingredientWeights,
    required this.cuisineWeights,
    required this.difficultyWeights,
    required this.excludedIngredients,
    required this.allergies,
    this.maxTotalMinutes,
    required this.servingsDefault,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    {
      map['dish_type_weights'] = Variable<String>(
        $PreferenceProfileTable.$converterdishTypeWeights.toSql(
          dishTypeWeights,
        ),
      );
    }
    {
      map['ingredient_weights'] = Variable<String>(
        $PreferenceProfileTable.$converteringredientWeights.toSql(
          ingredientWeights,
        ),
      );
    }
    {
      map['cuisine_weights'] = Variable<String>(
        $PreferenceProfileTable.$convertercuisineWeights.toSql(cuisineWeights),
      );
    }
    {
      map['difficulty_weights'] = Variable<String>(
        $PreferenceProfileTable.$converterdifficultyWeights.toSql(
          difficultyWeights,
        ),
      );
    }
    {
      map['excluded_ingredients'] = Variable<String>(
        $PreferenceProfileTable.$converterexcludedIngredients.toSql(
          excludedIngredients,
        ),
      );
    }
    {
      map['allergies'] = Variable<String>(
        $PreferenceProfileTable.$converterallergies.toSql(allergies),
      );
    }
    if (!nullToAbsent || maxTotalMinutes != null) {
      map['max_total_minutes'] = Variable<int>(maxTotalMinutes);
    }
    map['servings_default'] = Variable<int>(servingsDefault);
    return map;
  }

  PreferenceProfileCompanion toCompanion(bool nullToAbsent) {
    return PreferenceProfileCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      dishTypeWeights: Value(dishTypeWeights),
      ingredientWeights: Value(ingredientWeights),
      cuisineWeights: Value(cuisineWeights),
      difficultyWeights: Value(difficultyWeights),
      excludedIngredients: Value(excludedIngredients),
      allergies: Value(allergies),
      maxTotalMinutes: maxTotalMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(maxTotalMinutes),
      servingsDefault: Value(servingsDefault),
    );
  }

  factory PreferenceProfileData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PreferenceProfileData(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      dishTypeWeights: serializer.fromJson<Map<String, dynamic>>(
        json['dishTypeWeights'],
      ),
      ingredientWeights: serializer.fromJson<Map<String, dynamic>>(
        json['ingredientWeights'],
      ),
      cuisineWeights: serializer.fromJson<Map<String, dynamic>>(
        json['cuisineWeights'],
      ),
      difficultyWeights: serializer.fromJson<Map<String, dynamic>>(
        json['difficultyWeights'],
      ),
      excludedIngredients: serializer.fromJson<List<String>>(
        json['excludedIngredients'],
      ),
      allergies: serializer.fromJson<List<String>>(json['allergies']),
      maxTotalMinutes: serializer.fromJson<int?>(json['maxTotalMinutes']),
      servingsDefault: serializer.fromJson<int>(json['servingsDefault']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'dishTypeWeights': serializer.toJson<Map<String, dynamic>>(
        dishTypeWeights,
      ),
      'ingredientWeights': serializer.toJson<Map<String, dynamic>>(
        ingredientWeights,
      ),
      'cuisineWeights': serializer.toJson<Map<String, dynamic>>(cuisineWeights),
      'difficultyWeights': serializer.toJson<Map<String, dynamic>>(
        difficultyWeights,
      ),
      'excludedIngredients': serializer.toJson<List<String>>(
        excludedIngredients,
      ),
      'allergies': serializer.toJson<List<String>>(allergies),
      'maxTotalMinutes': serializer.toJson<int?>(maxTotalMinutes),
      'servingsDefault': serializer.toJson<int>(servingsDefault),
    };
  }

  PreferenceProfileData copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    Map<String, dynamic>? dishTypeWeights,
    Map<String, dynamic>? ingredientWeights,
    Map<String, dynamic>? cuisineWeights,
    Map<String, dynamic>? difficultyWeights,
    List<String>? excludedIngredients,
    List<String>? allergies,
    Value<int?> maxTotalMinutes = const Value.absent(),
    int? servingsDefault,
  }) => PreferenceProfileData(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    dishTypeWeights: dishTypeWeights ?? this.dishTypeWeights,
    ingredientWeights: ingredientWeights ?? this.ingredientWeights,
    cuisineWeights: cuisineWeights ?? this.cuisineWeights,
    difficultyWeights: difficultyWeights ?? this.difficultyWeights,
    excludedIngredients: excludedIngredients ?? this.excludedIngredients,
    allergies: allergies ?? this.allergies,
    maxTotalMinutes: maxTotalMinutes.present
        ? maxTotalMinutes.value
        : this.maxTotalMinutes,
    servingsDefault: servingsDefault ?? this.servingsDefault,
  );
  PreferenceProfileData copyWithCompanion(PreferenceProfileCompanion data) {
    return PreferenceProfileData(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      dishTypeWeights: data.dishTypeWeights.present
          ? data.dishTypeWeights.value
          : this.dishTypeWeights,
      ingredientWeights: data.ingredientWeights.present
          ? data.ingredientWeights.value
          : this.ingredientWeights,
      cuisineWeights: data.cuisineWeights.present
          ? data.cuisineWeights.value
          : this.cuisineWeights,
      difficultyWeights: data.difficultyWeights.present
          ? data.difficultyWeights.value
          : this.difficultyWeights,
      excludedIngredients: data.excludedIngredients.present
          ? data.excludedIngredients.value
          : this.excludedIngredients,
      allergies: data.allergies.present ? data.allergies.value : this.allergies,
      maxTotalMinutes: data.maxTotalMinutes.present
          ? data.maxTotalMinutes.value
          : this.maxTotalMinutes,
      servingsDefault: data.servingsDefault.present
          ? data.servingsDefault.value
          : this.servingsDefault,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PreferenceProfileData(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dishTypeWeights: $dishTypeWeights, ')
          ..write('ingredientWeights: $ingredientWeights, ')
          ..write('cuisineWeights: $cuisineWeights, ')
          ..write('difficultyWeights: $difficultyWeights, ')
          ..write('excludedIngredients: $excludedIngredients, ')
          ..write('allergies: $allergies, ')
          ..write('maxTotalMinutes: $maxTotalMinutes, ')
          ..write('servingsDefault: $servingsDefault')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    dishTypeWeights,
    ingredientWeights,
    cuisineWeights,
    difficultyWeights,
    excludedIngredients,
    allergies,
    maxTotalMinutes,
    servingsDefault,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PreferenceProfileData &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.dishTypeWeights == this.dishTypeWeights &&
          other.ingredientWeights == this.ingredientWeights &&
          other.cuisineWeights == this.cuisineWeights &&
          other.difficultyWeights == this.difficultyWeights &&
          other.excludedIngredients == this.excludedIngredients &&
          other.allergies == this.allergies &&
          other.maxTotalMinutes == this.maxTotalMinutes &&
          other.servingsDefault == this.servingsDefault);
}

class PreferenceProfileCompanion
    extends UpdateCompanion<PreferenceProfileData> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<Map<String, dynamic>> dishTypeWeights;
  final Value<Map<String, dynamic>> ingredientWeights;
  final Value<Map<String, dynamic>> cuisineWeights;
  final Value<Map<String, dynamic>> difficultyWeights;
  final Value<List<String>> excludedIngredients;
  final Value<List<String>> allergies;
  final Value<int?> maxTotalMinutes;
  final Value<int> servingsDefault;
  final Value<int> rowid;
  const PreferenceProfileCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.dishTypeWeights = const Value.absent(),
    this.ingredientWeights = const Value.absent(),
    this.cuisineWeights = const Value.absent(),
    this.difficultyWeights = const Value.absent(),
    this.excludedIngredients = const Value.absent(),
    this.allergies = const Value.absent(),
    this.maxTotalMinutes = const Value.absent(),
    this.servingsDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PreferenceProfileCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.dishTypeWeights = const Value.absent(),
    this.ingredientWeights = const Value.absent(),
    this.cuisineWeights = const Value.absent(),
    this.difficultyWeights = const Value.absent(),
    this.excludedIngredients = const Value.absent(),
    this.allergies = const Value.absent(),
    this.maxTotalMinutes = const Value.absent(),
    this.servingsDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<PreferenceProfileData> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? dishTypeWeights,
    Expression<String>? ingredientWeights,
    Expression<String>? cuisineWeights,
    Expression<String>? difficultyWeights,
    Expression<String>? excludedIngredients,
    Expression<String>? allergies,
    Expression<int>? maxTotalMinutes,
    Expression<int>? servingsDefault,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (dishTypeWeights != null) 'dish_type_weights': dishTypeWeights,
      if (ingredientWeights != null) 'ingredient_weights': ingredientWeights,
      if (cuisineWeights != null) 'cuisine_weights': cuisineWeights,
      if (difficultyWeights != null) 'difficulty_weights': difficultyWeights,
      if (excludedIngredients != null)
        'excluded_ingredients': excludedIngredients,
      if (allergies != null) 'allergies': allergies,
      if (maxTotalMinutes != null) 'max_total_minutes': maxTotalMinutes,
      if (servingsDefault != null) 'servings_default': servingsDefault,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PreferenceProfileCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<Map<String, dynamic>>? dishTypeWeights,
    Value<Map<String, dynamic>>? ingredientWeights,
    Value<Map<String, dynamic>>? cuisineWeights,
    Value<Map<String, dynamic>>? difficultyWeights,
    Value<List<String>>? excludedIngredients,
    Value<List<String>>? allergies,
    Value<int?>? maxTotalMinutes,
    Value<int>? servingsDefault,
    Value<int>? rowid,
  }) {
    return PreferenceProfileCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      dishTypeWeights: dishTypeWeights ?? this.dishTypeWeights,
      ingredientWeights: ingredientWeights ?? this.ingredientWeights,
      cuisineWeights: cuisineWeights ?? this.cuisineWeights,
      difficultyWeights: difficultyWeights ?? this.difficultyWeights,
      excludedIngredients: excludedIngredients ?? this.excludedIngredients,
      allergies: allergies ?? this.allergies,
      maxTotalMinutes: maxTotalMinutes ?? this.maxTotalMinutes,
      servingsDefault: servingsDefault ?? this.servingsDefault,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (dishTypeWeights.present) {
      map['dish_type_weights'] = Variable<String>(
        $PreferenceProfileTable.$converterdishTypeWeights.toSql(
          dishTypeWeights.value,
        ),
      );
    }
    if (ingredientWeights.present) {
      map['ingredient_weights'] = Variable<String>(
        $PreferenceProfileTable.$converteringredientWeights.toSql(
          ingredientWeights.value,
        ),
      );
    }
    if (cuisineWeights.present) {
      map['cuisine_weights'] = Variable<String>(
        $PreferenceProfileTable.$convertercuisineWeights.toSql(
          cuisineWeights.value,
        ),
      );
    }
    if (difficultyWeights.present) {
      map['difficulty_weights'] = Variable<String>(
        $PreferenceProfileTable.$converterdifficultyWeights.toSql(
          difficultyWeights.value,
        ),
      );
    }
    if (excludedIngredients.present) {
      map['excluded_ingredients'] = Variable<String>(
        $PreferenceProfileTable.$converterexcludedIngredients.toSql(
          excludedIngredients.value,
        ),
      );
    }
    if (allergies.present) {
      map['allergies'] = Variable<String>(
        $PreferenceProfileTable.$converterallergies.toSql(allergies.value),
      );
    }
    if (maxTotalMinutes.present) {
      map['max_total_minutes'] = Variable<int>(maxTotalMinutes.value);
    }
    if (servingsDefault.present) {
      map['servings_default'] = Variable<int>(servingsDefault.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PreferenceProfileCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dishTypeWeights: $dishTypeWeights, ')
          ..write('ingredientWeights: $ingredientWeights, ')
          ..write('cuisineWeights: $cuisineWeights, ')
          ..write('difficultyWeights: $difficultyWeights, ')
          ..write('excludedIngredients: $excludedIngredients, ')
          ..write('allergies: $allergies, ')
          ..write('maxTotalMinutes: $maxTotalMinutes, ')
          ..write('servingsDefault: $servingsDefault, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AiRequestsTable extends AiRequests
    with TableInfo<$AiRequestsTable, AiRequest> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiRequestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: () => clock.now().toUtc().millisecondsSinceEpoch,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: () => clock.now().toUtc().millisecondsSinceEpoch,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _promptHashMeta = const VerificationMeta(
    'promptHash',
  );
  @override
  late final GeneratedColumn<String> promptHash = GeneratedColumn<String>(
    'prompt_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _responseJsonMeta = const VerificationMeta(
    'responseJson',
  );
  @override
  late final GeneratedColumn<String> responseJson = GeneratedColumn<String>(
    'response_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tokensInMeta = const VerificationMeta(
    'tokensIn',
  );
  @override
  late final GeneratedColumn<int> tokensIn = GeneratedColumn<int>(
    'tokens_in',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tokensOutMeta = const VerificationMeta(
    'tokensOut',
  );
  @override
  late final GeneratedColumn<int> tokensOut = GeneratedColumn<int>(
    'tokens_out',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<int> at = GeneratedColumn<int>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc().millisecondsSinceEpoch,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    kind,
    promptHash,
    responseJson,
    model,
    tokensIn,
    tokensOut,
    status,
    at,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_requests';
  @override
  VerificationContext validateIntegrity(
    Insertable<AiRequest> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('prompt_hash')) {
      context.handle(
        _promptHashMeta,
        promptHash.isAcceptableOrUnknown(data['prompt_hash']!, _promptHashMeta),
      );
    } else if (isInserting) {
      context.missing(_promptHashMeta);
    }
    if (data.containsKey('response_json')) {
      context.handle(
        _responseJsonMeta,
        responseJson.isAcceptableOrUnknown(
          data['response_json']!,
          _responseJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_responseJsonMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('tokens_in')) {
      context.handle(
        _tokensInMeta,
        tokensIn.isAcceptableOrUnknown(data['tokens_in']!, _tokensInMeta),
      );
    }
    if (data.containsKey('tokens_out')) {
      context.handle(
        _tokensOutMeta,
        tokensOut.isAcceptableOrUnknown(data['tokens_out']!, _tokensOutMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AiRequest map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiRequest(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      promptHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt_hash'],
      )!,
      responseJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}response_json'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      tokensIn: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tokens_in'],
      ),
      tokensOut: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tokens_out'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $AiRequestsTable createAlias(String alias) {
    return $AiRequestsTable(attachedDatabase, alias);
  }
}

class AiRequest extends DataClass implements Insertable<AiRequest> {
  final String id;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  final String kind;
  final String promptHash;
  final String responseJson;
  final String model;
  final int? tokensIn;
  final int? tokensOut;
  final String status;
  final int at;
  const AiRequest({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.kind,
    required this.promptHash,
    required this.responseJson,
    required this.model,
    this.tokensIn,
    this.tokensOut,
    required this.status,
    required this.at,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['kind'] = Variable<String>(kind);
    map['prompt_hash'] = Variable<String>(promptHash);
    map['response_json'] = Variable<String>(responseJson);
    map['model'] = Variable<String>(model);
    if (!nullToAbsent || tokensIn != null) {
      map['tokens_in'] = Variable<int>(tokensIn);
    }
    if (!nullToAbsent || tokensOut != null) {
      map['tokens_out'] = Variable<int>(tokensOut);
    }
    map['status'] = Variable<String>(status);
    map['at'] = Variable<int>(at);
    return map;
  }

  AiRequestsCompanion toCompanion(bool nullToAbsent) {
    return AiRequestsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      kind: Value(kind),
      promptHash: Value(promptHash),
      responseJson: Value(responseJson),
      model: Value(model),
      tokensIn: tokensIn == null && nullToAbsent
          ? const Value.absent()
          : Value(tokensIn),
      tokensOut: tokensOut == null && nullToAbsent
          ? const Value.absent()
          : Value(tokensOut),
      status: Value(status),
      at: Value(at),
    );
  }

  factory AiRequest.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiRequest(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      kind: serializer.fromJson<String>(json['kind']),
      promptHash: serializer.fromJson<String>(json['promptHash']),
      responseJson: serializer.fromJson<String>(json['responseJson']),
      model: serializer.fromJson<String>(json['model']),
      tokensIn: serializer.fromJson<int?>(json['tokensIn']),
      tokensOut: serializer.fromJson<int?>(json['tokensOut']),
      status: serializer.fromJson<String>(json['status']),
      at: serializer.fromJson<int>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'kind': serializer.toJson<String>(kind),
      'promptHash': serializer.toJson<String>(promptHash),
      'responseJson': serializer.toJson<String>(responseJson),
      'model': serializer.toJson<String>(model),
      'tokensIn': serializer.toJson<int?>(tokensIn),
      'tokensOut': serializer.toJson<int?>(tokensOut),
      'status': serializer.toJson<String>(status),
      'at': serializer.toJson<int>(at),
    };
  }

  AiRequest copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? kind,
    String? promptHash,
    String? responseJson,
    String? model,
    Value<int?> tokensIn = const Value.absent(),
    Value<int?> tokensOut = const Value.absent(),
    String? status,
    int? at,
  }) => AiRequest(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    kind: kind ?? this.kind,
    promptHash: promptHash ?? this.promptHash,
    responseJson: responseJson ?? this.responseJson,
    model: model ?? this.model,
    tokensIn: tokensIn.present ? tokensIn.value : this.tokensIn,
    tokensOut: tokensOut.present ? tokensOut.value : this.tokensOut,
    status: status ?? this.status,
    at: at ?? this.at,
  );
  AiRequest copyWithCompanion(AiRequestsCompanion data) {
    return AiRequest(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      kind: data.kind.present ? data.kind.value : this.kind,
      promptHash: data.promptHash.present
          ? data.promptHash.value
          : this.promptHash,
      responseJson: data.responseJson.present
          ? data.responseJson.value
          : this.responseJson,
      model: data.model.present ? data.model.value : this.model,
      tokensIn: data.tokensIn.present ? data.tokensIn.value : this.tokensIn,
      tokensOut: data.tokensOut.present ? data.tokensOut.value : this.tokensOut,
      status: data.status.present ? data.status.value : this.status,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiRequest(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('kind: $kind, ')
          ..write('promptHash: $promptHash, ')
          ..write('responseJson: $responseJson, ')
          ..write('model: $model, ')
          ..write('tokensIn: $tokensIn, ')
          ..write('tokensOut: $tokensOut, ')
          ..write('status: $status, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    kind,
    promptHash,
    responseJson,
    model,
    tokensIn,
    tokensOut,
    status,
    at,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiRequest &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.kind == this.kind &&
          other.promptHash == this.promptHash &&
          other.responseJson == this.responseJson &&
          other.model == this.model &&
          other.tokensIn == this.tokensIn &&
          other.tokensOut == this.tokensOut &&
          other.status == this.status &&
          other.at == this.at);
}

class AiRequestsCompanion extends UpdateCompanion<AiRequest> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> kind;
  final Value<String> promptHash;
  final Value<String> responseJson;
  final Value<String> model;
  final Value<int?> tokensIn;
  final Value<int?> tokensOut;
  final Value<String> status;
  final Value<int> at;
  final Value<int> rowid;
  const AiRequestsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.kind = const Value.absent(),
    this.promptHash = const Value.absent(),
    this.responseJson = const Value.absent(),
    this.model = const Value.absent(),
    this.tokensIn = const Value.absent(),
    this.tokensOut = const Value.absent(),
    this.status = const Value.absent(),
    this.at = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AiRequestsCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String kind,
    required String promptHash,
    required String responseJson,
    required String model,
    this.tokensIn = const Value.absent(),
    this.tokensOut = const Value.absent(),
    required String status,
    this.at = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : kind = Value(kind),
       promptHash = Value(promptHash),
       responseJson = Value(responseJson),
       model = Value(model),
       status = Value(status);
  static Insertable<AiRequest> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? kind,
    Expression<String>? promptHash,
    Expression<String>? responseJson,
    Expression<String>? model,
    Expression<int>? tokensIn,
    Expression<int>? tokensOut,
    Expression<String>? status,
    Expression<int>? at,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (kind != null) 'kind': kind,
      if (promptHash != null) 'prompt_hash': promptHash,
      if (responseJson != null) 'response_json': responseJson,
      if (model != null) 'model': model,
      if (tokensIn != null) 'tokens_in': tokensIn,
      if (tokensOut != null) 'tokens_out': tokensOut,
      if (status != null) 'status': status,
      if (at != null) 'at': at,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AiRequestsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? kind,
    Value<String>? promptHash,
    Value<String>? responseJson,
    Value<String>? model,
    Value<int?>? tokensIn,
    Value<int?>? tokensOut,
    Value<String>? status,
    Value<int>? at,
    Value<int>? rowid,
  }) {
    return AiRequestsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      kind: kind ?? this.kind,
      promptHash: promptHash ?? this.promptHash,
      responseJson: responseJson ?? this.responseJson,
      model: model ?? this.model,
      tokensIn: tokensIn ?? this.tokensIn,
      tokensOut: tokensOut ?? this.tokensOut,
      status: status ?? this.status,
      at: at ?? this.at,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (promptHash.present) {
      map['prompt_hash'] = Variable<String>(promptHash.value);
    }
    if (responseJson.present) {
      map['response_json'] = Variable<String>(responseJson.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (tokensIn.present) {
      map['tokens_in'] = Variable<int>(tokensIn.value);
    }
    if (tokensOut.present) {
      map['tokens_out'] = Variable<int>(tokensOut.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (at.present) {
      map['at'] = Variable<int>(at.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiRequestsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('kind: $kind, ')
          ..write('promptHash: $promptHash, ')
          ..write('responseJson: $responseJson, ')
          ..write('model: $model, ')
          ..write('tokensIn: $tokensIn, ')
          ..write('tokensOut: $tokensOut, ')
          ..write('status: $status, ')
          ..write('at: $at, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final IngredientsFts ingredientsFts = IngredientsFts(this);
  late final $IngredientsTable ingredients = $IngredientsTable(this);
  late final $PantryItemsTable pantryItems = $PantryItemsTable(this);
  late final $RecipesTable recipes = $RecipesTable(this);
  late final $RecipeIngredientsTable recipeIngredients =
      $RecipeIngredientsTable(this);
  late final $RecipeStepsTable recipeSteps = $RecipeStepsTable(this);
  late final $RecipeTagsTable recipeTags = $RecipeTagsTable(this);
  late final $CookedEntriesTable cookedEntries = $CookedEntriesTable(this);
  late final $MealPlanEntriesTable mealPlanEntries = $MealPlanEntriesTable(
    this,
  );
  late final $FeedbackEventsTable feedbackEvents = $FeedbackEventsTable(this);
  late final $FeedEventsTable feedEvents = $FeedEventsTable(this);
  late final $PreferenceProfileTable preferenceProfile =
      $PreferenceProfileTable(this);
  late final $AiRequestsTable aiRequests = $AiRequestsTable(this);
  late final Index idxPantryItemsIngredientId = Index(
    'idx_pantry_items_ingredient_id',
    'CREATE UNIQUE INDEX idx_pantry_items_ingredient_id ON pantry_items (ingredient_id)',
  );
  late final Index idxRecipeIngredientsRecipeId = Index(
    'idx_recipe_ingredients_recipe_id',
    'CREATE INDEX idx_recipe_ingredients_recipe_id ON recipe_ingredients (recipe_id)',
  );
  late final Index idxRecipeIngredientsIngredientId = Index(
    'idx_recipe_ingredients_ingredient_id',
    'CREATE INDEX idx_recipe_ingredients_ingredient_id ON recipe_ingredients (ingredient_id)',
  );
  late final Index idxRecipeStepsRecipeId = Index(
    'idx_recipe_steps_recipe_id',
    'CREATE INDEX idx_recipe_steps_recipe_id ON recipe_steps (recipe_id)',
  );
  late final Index idxCookedEntriesCookedOn = Index(
    'idx_cooked_entries_cooked_on',
    'CREATE INDEX idx_cooked_entries_cooked_on ON cooked_entries (cooked_on)',
  );
  late final Index idxMealPlanEntriesDateSlot = Index(
    'idx_meal_plan_entries_date_slot',
    'CREATE UNIQUE INDEX idx_meal_plan_entries_date_slot ON meal_plan_entries (date, meal_slot)',
  );
  Selectable<IngredientsFt> searchIngredientsFts(String query) {
    return customSelect(
      'SELECT ingredient_id, name, synonyms FROM ingredients_fts WHERE ingredients_fts MATCH ?1',
      variables: [Variable<String>(query)],
      readsFrom: {this.ingredientsFts},
    ).asyncMap(this.ingredientsFts.mapFromRow);
  }

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    ingredientsFts,
    ingredients,
    pantryItems,
    recipes,
    recipeIngredients,
    recipeSteps,
    recipeTags,
    cookedEntries,
    mealPlanEntries,
    feedbackEvents,
    feedEvents,
    preferenceProfile,
    aiRequests,
    idxPantryItemsIngredientId,
    idxRecipeIngredientsRecipeId,
    idxRecipeIngredientsIngredientId,
    idxRecipeStepsRecipeId,
    idxCookedEntriesCookedOn,
    idxMealPlanEntriesDateSlot,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'recipes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('recipe_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'recipes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('feed_events', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $IngredientsFtsCreateCompanionBuilder =
    IngredientsFtsCompanion Function({
      required String ingredientId,
      required String name,
      required String synonyms,
      Value<int> rowid,
    });
typedef $IngredientsFtsUpdateCompanionBuilder =
    IngredientsFtsCompanion Function({
      Value<String> ingredientId,
      Value<String> name,
      Value<String> synonyms,
      Value<int> rowid,
    });

class $IngredientsFtsFilterComposer
    extends Composer<_$AppDatabase, IngredientsFts> {
  $IngredientsFtsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get synonyms => $composableBuilder(
    column: $table.synonyms,
    builder: (column) => ColumnFilters(column),
  );
}

class $IngredientsFtsOrderingComposer
    extends Composer<_$AppDatabase, IngredientsFts> {
  $IngredientsFtsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get synonyms => $composableBuilder(
    column: $table.synonyms,
    builder: (column) => ColumnOrderings(column),
  );
}

class $IngredientsFtsAnnotationComposer
    extends Composer<_$AppDatabase, IngredientsFts> {
  $IngredientsFtsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get synonyms =>
      $composableBuilder(column: $table.synonyms, builder: (column) => column);
}

class $IngredientsFtsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          IngredientsFts,
          IngredientsFt,
          $IngredientsFtsFilterComposer,
          $IngredientsFtsOrderingComposer,
          $IngredientsFtsAnnotationComposer,
          $IngredientsFtsCreateCompanionBuilder,
          $IngredientsFtsUpdateCompanionBuilder,
          (
            IngredientsFt,
            BaseReferences<_$AppDatabase, IngredientsFts, IngredientsFt>,
          ),
          IngredientsFt,
          PrefetchHooks Function()
        > {
  $IngredientsFtsTableManager(_$AppDatabase db, IngredientsFts table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $IngredientsFtsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $IngredientsFtsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $IngredientsFtsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> ingredientId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> synonyms = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IngredientsFtsCompanion(
                ingredientId: ingredientId,
                name: name,
                synonyms: synonyms,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ingredientId,
                required String name,
                required String synonyms,
                Value<int> rowid = const Value.absent(),
              }) => IngredientsFtsCompanion.insert(
                ingredientId: ingredientId,
                name: name,
                synonyms: synonyms,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<IngredientsFts, IngredientsFt>(table),
                  BaseReferences<_$AppDatabase, IngredientsFts, IngredientsFt>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $IngredientsFtsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      IngredientsFts,
      IngredientsFt,
      $IngredientsFtsFilterComposer,
      $IngredientsFtsOrderingComposer,
      $IngredientsFtsAnnotationComposer,
      $IngredientsFtsCreateCompanionBuilder,
      $IngredientsFtsUpdateCompanionBuilder,
      (
        IngredientsFt,
        BaseReferences<_$AppDatabase, IngredientsFts, IngredientsFt>,
      ),
      IngredientsFt,
      PrefetchHooks Function()
    >;
typedef $$IngredientsTableCreateCompanionBuilder =
    IngredientsCompanion Function({
      Value<String> id,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      required String name,
      Value<List<String>> synonyms,
      required String category,
      Value<bool> isStaple,
      Value<String?> icon,
      Value<String?> parentId,
      Value<int> rowid,
    });
typedef $$IngredientsTableUpdateCompanionBuilder =
    IngredientsCompanion Function({
      Value<String> id,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> name,
      Value<List<String>> synonyms,
      Value<String> category,
      Value<bool> isStaple,
      Value<String?> icon,
      Value<String?> parentId,
      Value<int> rowid,
    });

class $$IngredientsTableFilterComposer
    extends Composer<_$AppDatabase, $IngredientsTable> {
  $$IngredientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get synonyms => $composableBuilder(
    column: $table.synonyms,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isStaple => $composableBuilder(
    column: $table.isStaple,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IngredientsTableOrderingComposer
    extends Composer<_$AppDatabase, $IngredientsTable> {
  $$IngredientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get synonyms => $composableBuilder(
    column: $table.synonyms,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isStaple => $composableBuilder(
    column: $table.isStaple,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IngredientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IngredientsTable> {
  $$IngredientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get synonyms =>
      $composableBuilder(column: $table.synonyms, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<bool> get isStaple =>
      $composableBuilder(column: $table.isStaple, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);
}

class $$IngredientsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IngredientsTable,
          Ingredient,
          $$IngredientsTableFilterComposer,
          $$IngredientsTableOrderingComposer,
          $$IngredientsTableAnnotationComposer,
          $$IngredientsTableCreateCompanionBuilder,
          $$IngredientsTableUpdateCompanionBuilder,
          (
            Ingredient,
            BaseReferences<_$AppDatabase, $IngredientsTable, Ingredient>,
          ),
          Ingredient,
          PrefetchHooks Function()
        > {
  $$IngredientsTableTableManager(_$AppDatabase db, $IngredientsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngredientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IngredientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IngredientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<List<String>> synonyms = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<bool> isStaple = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IngredientsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                synonyms: synonyms,
                category: category,
                isStaple: isStaple,
                icon: icon,
                parentId: parentId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                required String name,
                Value<List<String>> synonyms = const Value.absent(),
                required String category,
                Value<bool> isStaple = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IngredientsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                synonyms: synonyms,
                category: category,
                isStaple: isStaple,
                icon: icon,
                parentId: parentId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IngredientsTable, Ingredient>(table),
                  BaseReferences<_$AppDatabase, $IngredientsTable, Ingredient>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IngredientsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IngredientsTable,
      Ingredient,
      $$IngredientsTableFilterComposer,
      $$IngredientsTableOrderingComposer,
      $$IngredientsTableAnnotationComposer,
      $$IngredientsTableCreateCompanionBuilder,
      $$IngredientsTableUpdateCompanionBuilder,
      (
        Ingredient,
        BaseReferences<_$AppDatabase, $IngredientsTable, Ingredient>,
      ),
      Ingredient,
      PrefetchHooks Function()
    >;
typedef $$PantryItemsTableCreateCompanionBuilder =
    PantryItemsCompanion Function({
      Value<String> id,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      required String ingredientId,
      Value<bool> isAvailable,
      Value<int> rowid,
    });
typedef $$PantryItemsTableUpdateCompanionBuilder =
    PantryItemsCompanion Function({
      Value<String> id,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> ingredientId,
      Value<bool> isAvailable,
      Value<int> rowid,
    });

class $$PantryItemsTableFilterComposer
    extends Composer<_$AppDatabase, $PantryItemsTable> {
  $$PantryItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PantryItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $PantryItemsTable> {
  $$PantryItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PantryItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PantryItemsTable> {
  $$PantryItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => column,
  );
}

class $$PantryItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PantryItemsTable,
          PantryItem,
          $$PantryItemsTableFilterComposer,
          $$PantryItemsTableOrderingComposer,
          $$PantryItemsTableAnnotationComposer,
          $$PantryItemsTableCreateCompanionBuilder,
          $$PantryItemsTableUpdateCompanionBuilder,
          (
            PantryItem,
            BaseReferences<_$AppDatabase, $PantryItemsTable, PantryItem>,
          ),
          PantryItem,
          PrefetchHooks Function()
        > {
  $$PantryItemsTableTableManager(_$AppDatabase db, $PantryItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PantryItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PantryItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PantryItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> ingredientId = const Value.absent(),
                Value<bool> isAvailable = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PantryItemsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                ingredientId: ingredientId,
                isAvailable: isAvailable,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                required String ingredientId,
                Value<bool> isAvailable = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PantryItemsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                ingredientId: ingredientId,
                isAvailable: isAvailable,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PantryItemsTable, PantryItem>(table),
                  BaseReferences<_$AppDatabase, $PantryItemsTable, PantryItem>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PantryItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PantryItemsTable,
      PantryItem,
      $$PantryItemsTableFilterComposer,
      $$PantryItemsTableOrderingComposer,
      $$PantryItemsTableAnnotationComposer,
      $$PantryItemsTableCreateCompanionBuilder,
      $$PantryItemsTableUpdateCompanionBuilder,
      (
        PantryItem,
        BaseReferences<_$AppDatabase, $PantryItemsTable, PantryItem>,
      ),
      PantryItem,
      PrefetchHooks Function()
    >;
typedef $$RecipesTableCreateCompanionBuilder = RecipesCompanion Function({
  Value<String> id,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  required String title,
  required String normalizedTitle,
  required DishType dishType,
  Value<DishGroup> dishGroup,
  required Difficulty difficulty,
  required String cuisine,
  required int totalMinutes,
  required int activeMinutes,
  Value<int?> cookMinutes,
  Value<int?> kcalPerServing,
  Value<int> servings,
  required String description,
  required RecipeSource source,
  required String fingerprint,
  Value<String?> aiModel,
  Value<bool> isFavorite,
  Value<int> rowid,
});
typedef $$RecipesTableUpdateCompanionBuilder = RecipesCompanion Function({
  Value<String> id,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<String> title,
  Value<String> normalizedTitle,
  Value<DishType> dishType,
  Value<DishGroup> dishGroup,
  Value<Difficulty> difficulty,
  Value<String> cuisine,
  Value<int> totalMinutes,
  Value<int> activeMinutes,
  Value<int?> cookMinutes,
  Value<int?> kcalPerServing,
  Value<int> servings,
  Value<String> description,
  Value<RecipeSource> source,
  Value<String> fingerprint,
  Value<String?> aiModel,
  Value<bool> isFavorite,
  Value<int> rowid,
});

final class $$RecipesTableReferences
    extends BaseReferences<_$AppDatabase, $RecipesTable, Recipe> {
  $$RecipesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RecipeTagsTable, List<RecipeTagEntry>>
  _recipeTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.recipeTags,
    aliasName: 'recipes__id__recipe_tags__recipe_id',
  );

  $$RecipeTagsTableProcessedTableManager get recipeTagsRefs {
    final manager = $$RecipeTagsTableTableManager(
      $_db,
      $_db.recipeTags,
    ).filter((f) => f.recipeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_recipeTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FeedEventsTable, List<FeedEventEntry>>
  _feedEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.feedEvents,
    aliasName: 'recipes__id__feed_events__recipe_id',
  );

  $$FeedEventsTableProcessedTableManager get feedEventsRefs {
    final manager = $$FeedEventsTableTableManager(
      $_db,
      $_db.feedEvents,
    ).filter((f) => f.recipeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_feedEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RecipesTableFilterComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedTitle => $composableBuilder(
    column: $table.normalizedTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DishType, DishType, String> get dishType =>
      $composableBuilder(
        column: $table.dishType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DishGroup, DishGroup, String> get dishGroup =>
      $composableBuilder(
        column: $table.dishGroup,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Difficulty, Difficulty, String>
  get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get cuisine => $composableBuilder(
    column: $table.cuisine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalMinutes => $composableBuilder(
    column: $table.totalMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get activeMinutes => $composableBuilder(
    column: $table.activeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cookMinutes => $composableBuilder(
    column: $table.cookMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get kcalPerServing => $composableBuilder(
    column: $table.kcalPerServing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get servings => $composableBuilder(
    column: $table.servings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RecipeSource, RecipeSource, String>
  get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aiModel => $composableBuilder(
    column: $table.aiModel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> recipeTagsRefs(
    Expression<bool> Function($$RecipeTagsTableFilterComposer f) f,
  ) {
    final $$RecipeTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recipeTags,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipeTagsTableFilterComposer(
            $db: $db,
            $table: $db.recipeTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> feedEventsRefs(
    Expression<bool> Function($$FeedEventsTableFilterComposer f) f,
  ) {
    final $$FeedEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.feedEvents,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FeedEventsTableFilterComposer(
            $db: $db,
            $table: $db.feedEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecipesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedTitle => $composableBuilder(
    column: $table.normalizedTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dishType => $composableBuilder(
    column: $table.dishType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dishGroup => $composableBuilder(
    column: $table.dishGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cuisine => $composableBuilder(
    column: $table.cuisine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalMinutes => $composableBuilder(
    column: $table.totalMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activeMinutes => $composableBuilder(
    column: $table.activeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cookMinutes => $composableBuilder(
    column: $table.cookMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kcalPerServing => $composableBuilder(
    column: $table.kcalPerServing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get servings => $composableBuilder(
    column: $table.servings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aiModel => $composableBuilder(
    column: $table.aiModel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecipesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get normalizedTitle => $composableBuilder(
    column: $table.normalizedTitle,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DishType, String> get dishType =>
      $composableBuilder(column: $table.dishType, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DishGroup, String> get dishGroup =>
      $composableBuilder(column: $table.dishGroup, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Difficulty, String> get difficulty =>
      $composableBuilder(
        column: $table.difficulty,
        builder: (column) => column,
      );

  GeneratedColumn<String> get cuisine =>
      $composableBuilder(column: $table.cuisine, builder: (column) => column);

  GeneratedColumn<int> get totalMinutes => $composableBuilder(
    column: $table.totalMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get activeMinutes => $composableBuilder(
    column: $table.activeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cookMinutes => $composableBuilder(
    column: $table.cookMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get kcalPerServing => $composableBuilder(
    column: $table.kcalPerServing,
    builder: (column) => column,
  );

  GeneratedColumn<int> get servings =>
      $composableBuilder(column: $table.servings, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<RecipeSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get aiModel =>
      $composableBuilder(column: $table.aiModel, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  Expression<T> recipeTagsRefs<T extends Object>(
    Expression<T> Function($$RecipeTagsTableAnnotationComposer a) f,
  ) {
    final $$RecipeTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recipeTags,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipeTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.recipeTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> feedEventsRefs<T extends Object>(
    Expression<T> Function($$FeedEventsTableAnnotationComposer a) f,
  ) {
    final $$FeedEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.feedEvents,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FeedEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.feedEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecipesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipesTable,
          Recipe,
          $$RecipesTableFilterComposer,
          $$RecipesTableOrderingComposer,
          $$RecipesTableAnnotationComposer,
          $$RecipesTableCreateCompanionBuilder,
          $$RecipesTableUpdateCompanionBuilder,
          (Recipe, $$RecipesTableReferences),
          Recipe,
          PrefetchHooks Function({bool recipeTagsRefs, bool feedEventsRefs})
        > {
  $$RecipesTableTableManager(_$AppDatabase db, $RecipesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> normalizedTitle = const Value.absent(),
                Value<DishType> dishType = const Value.absent(),
                Value<DishGroup> dishGroup = const Value.absent(),
                Value<Difficulty> difficulty = const Value.absent(),
                Value<String> cuisine = const Value.absent(),
                Value<int> totalMinutes = const Value.absent(),
                Value<int> activeMinutes = const Value.absent(),
                Value<int?> cookMinutes = const Value.absent(),
                Value<int?> kcalPerServing = const Value.absent(),
                Value<int> servings = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<RecipeSource> source = const Value.absent(),
                Value<String> fingerprint = const Value.absent(),
                Value<String?> aiModel = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                title: title,
                normalizedTitle: normalizedTitle,
                dishType: dishType,
                dishGroup: dishGroup,
                difficulty: difficulty,
                cuisine: cuisine,
                totalMinutes: totalMinutes,
                activeMinutes: activeMinutes,
                cookMinutes: cookMinutes,
                kcalPerServing: kcalPerServing,
                servings: servings,
                description: description,
                source: source,
                fingerprint: fingerprint,
                aiModel: aiModel,
                isFavorite: isFavorite,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                required String title,
                required String normalizedTitle,
                required DishType dishType,
                Value<DishGroup> dishGroup = const Value.absent(),
                required Difficulty difficulty,
                required String cuisine,
                required int totalMinutes,
                required int activeMinutes,
                Value<int?> cookMinutes = const Value.absent(),
                Value<int?> kcalPerServing = const Value.absent(),
                Value<int> servings = const Value.absent(),
                required String description,
                required RecipeSource source,
                required String fingerprint,
                Value<String?> aiModel = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                title: title,
                normalizedTitle: normalizedTitle,
                dishType: dishType,
                dishGroup: dishGroup,
                difficulty: difficulty,
                cuisine: cuisine,
                totalMinutes: totalMinutes,
                activeMinutes: activeMinutes,
                cookMinutes: cookMinutes,
                kcalPerServing: kcalPerServing,
                servings: servings,
                description: description,
                source: source,
                fingerprint: fingerprint,
                aiModel: aiModel,
                isFavorite: isFavorite,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecipesTable, Recipe>(table),
                  $$RecipesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({recipeTagsRefs = false, feedEventsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (recipeTagsRefs) db.recipeTags,
                    if (feedEventsRefs) db.feedEvents,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (recipeTagsRefs)
                        await $_getPrefetchedDataByColumns<
                          Recipe,
                          $RecipesTable,
                          RecipeTagEntry,
                          $RecipeTagsTable
                        >(
                          currentTable: table,
                          referencedTable: $$RecipesTableReferences
                              ._recipeTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RecipesTableReferences(
                                db,
                                table,
                                p0,
                              ).recipeTagsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'recipe_id',
                          typedResults: items,
                        ),
                      if (feedEventsRefs)
                        await $_getPrefetchedDataByColumns<
                          Recipe,
                          $RecipesTable,
                          FeedEventEntry,
                          $FeedEventsTable
                        >(
                          currentTable: table,
                          referencedTable: $$RecipesTableReferences
                              ._feedEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RecipesTableReferences(
                                db,
                                table,
                                p0,
                              ).feedEventsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'recipe_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RecipesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipesTable,
      Recipe,
      $$RecipesTableFilterComposer,
      $$RecipesTableOrderingComposer,
      $$RecipesTableAnnotationComposer,
      $$RecipesTableCreateCompanionBuilder,
      $$RecipesTableUpdateCompanionBuilder,
      (Recipe, $$RecipesTableReferences),
      Recipe,
      PrefetchHooks Function({bool recipeTagsRefs, bool feedEventsRefs})
    >;
typedef $$RecipeIngredientsTableCreateCompanionBuilder =
    RecipeIngredientsCompanion Function({
      Value<String> id,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      required String recipeId,
      required String ingredientId,
      Value<double?> amount,
      Value<String?> unit,
      Value<bool> isOptional,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$RecipeIngredientsTableUpdateCompanionBuilder =
    RecipeIngredientsCompanion Function({
      Value<String> id,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> recipeId,
      Value<String> ingredientId,
      Value<double?> amount,
      Value<String?> unit,
      Value<bool> isOptional,
      Value<String?> note,
      Value<int> rowid,
    });

class $$RecipeIngredientsTableFilterComposer
    extends Composer<_$AppDatabase, $RecipeIngredientsTable> {
  $$RecipeIngredientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOptional => $composableBuilder(
    column: $table.isOptional,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecipeIngredientsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipeIngredientsTable> {
  $$RecipeIngredientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOptional => $composableBuilder(
    column: $table.isOptional,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecipeIngredientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipeIngredientsTable> {
  $$RecipeIngredientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get recipeId =>
      $composableBuilder(column: $table.recipeId, builder: (column) => column);

  GeneratedColumn<String> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<bool> get isOptional => $composableBuilder(
    column: $table.isOptional,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$RecipeIngredientsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipeIngredientsTable,
          RecipeIngredient,
          $$RecipeIngredientsTableFilterComposer,
          $$RecipeIngredientsTableOrderingComposer,
          $$RecipeIngredientsTableAnnotationComposer,
          $$RecipeIngredientsTableCreateCompanionBuilder,
          $$RecipeIngredientsTableUpdateCompanionBuilder,
          (
            RecipeIngredient,
            BaseReferences<
              _$AppDatabase,
              $RecipeIngredientsTable,
              RecipeIngredient
            >,
          ),
          RecipeIngredient,
          PrefetchHooks Function()
        > {
  $$RecipeIngredientsTableTableManager(
    _$AppDatabase db,
    $RecipeIngredientsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeIngredientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipeIngredientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipeIngredientsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> recipeId = const Value.absent(),
                Value<String> ingredientId = const Value.absent(),
                Value<double?> amount = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<bool> isOptional = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipeIngredientsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                recipeId: recipeId,
                ingredientId: ingredientId,
                amount: amount,
                unit: unit,
                isOptional: isOptional,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                required String recipeId,
                required String ingredientId,
                Value<double?> amount = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<bool> isOptional = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipeIngredientsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                recipeId: recipeId,
                ingredientId: ingredientId,
                amount: amount,
                unit: unit,
                isOptional: isOptional,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecipeIngredientsTable, RecipeIngredient>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $RecipeIngredientsTable,
                    RecipeIngredient
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecipeIngredientsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipeIngredientsTable,
      RecipeIngredient,
      $$RecipeIngredientsTableFilterComposer,
      $$RecipeIngredientsTableOrderingComposer,
      $$RecipeIngredientsTableAnnotationComposer,
      $$RecipeIngredientsTableCreateCompanionBuilder,
      $$RecipeIngredientsTableUpdateCompanionBuilder,
      (
        RecipeIngredient,
        BaseReferences<
          _$AppDatabase,
          $RecipeIngredientsTable,
          RecipeIngredient
        >,
      ),
      RecipeIngredient,
      PrefetchHooks Function()
    >;
typedef $$RecipeStepsTableCreateCompanionBuilder =
    RecipeStepsCompanion Function({
      Value<String> id,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      required String recipeId,
      required int position,
      required String textContent,
      Value<int?> timerSeconds,
      Value<String?> tip,
      Value<int> rowid,
    });
typedef $$RecipeStepsTableUpdateCompanionBuilder =
    RecipeStepsCompanion Function({
      Value<String> id,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> recipeId,
      Value<int> position,
      Value<String> textContent,
      Value<int?> timerSeconds,
      Value<String?> tip,
      Value<int> rowid,
    });

class $$RecipeStepsTableFilterComposer
    extends Composer<_$AppDatabase, $RecipeStepsTable> {
  $$RecipeStepsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textContent => $composableBuilder(
    column: $table.textContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timerSeconds => $composableBuilder(
    column: $table.timerSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tip => $composableBuilder(
    column: $table.tip,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecipeStepsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipeStepsTable> {
  $$RecipeStepsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textContent => $composableBuilder(
    column: $table.textContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timerSeconds => $composableBuilder(
    column: $table.timerSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tip => $composableBuilder(
    column: $table.tip,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecipeStepsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipeStepsTable> {
  $$RecipeStepsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get recipeId =>
      $composableBuilder(column: $table.recipeId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get textContent => $composableBuilder(
    column: $table.textContent,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timerSeconds => $composableBuilder(
    column: $table.timerSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tip =>
      $composableBuilder(column: $table.tip, builder: (column) => column);
}

class $$RecipeStepsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipeStepsTable,
          RecipeStep,
          $$RecipeStepsTableFilterComposer,
          $$RecipeStepsTableOrderingComposer,
          $$RecipeStepsTableAnnotationComposer,
          $$RecipeStepsTableCreateCompanionBuilder,
          $$RecipeStepsTableUpdateCompanionBuilder,
          (
            RecipeStep,
            BaseReferences<_$AppDatabase, $RecipeStepsTable, RecipeStep>,
          ),
          RecipeStep,
          PrefetchHooks Function()
        > {
  $$RecipeStepsTableTableManager(_$AppDatabase db, $RecipeStepsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeStepsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipeStepsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipeStepsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> recipeId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> textContent = const Value.absent(),
                Value<int?> timerSeconds = const Value.absent(),
                Value<String?> tip = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipeStepsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                recipeId: recipeId,
                position: position,
                textContent: textContent,
                timerSeconds: timerSeconds,
                tip: tip,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                required String recipeId,
                required int position,
                required String textContent,
                Value<int?> timerSeconds = const Value.absent(),
                Value<String?> tip = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipeStepsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                recipeId: recipeId,
                position: position,
                textContent: textContent,
                timerSeconds: timerSeconds,
                tip: tip,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecipeStepsTable, RecipeStep>(table),
                  BaseReferences<_$AppDatabase, $RecipeStepsTable, RecipeStep>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecipeStepsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipeStepsTable,
      RecipeStep,
      $$RecipeStepsTableFilterComposer,
      $$RecipeStepsTableOrderingComposer,
      $$RecipeStepsTableAnnotationComposer,
      $$RecipeStepsTableCreateCompanionBuilder,
      $$RecipeStepsTableUpdateCompanionBuilder,
      (
        RecipeStep,
        BaseReferences<_$AppDatabase, $RecipeStepsTable, RecipeStep>,
      ),
      RecipeStep,
      PrefetchHooks Function()
    >;
typedef $$RecipeTagsTableCreateCompanionBuilder = RecipeTagsCompanion Function({
  required String recipeId,
  required TagKind tagKind,
  required String tag,
  Value<int> rowid,
});
typedef $$RecipeTagsTableUpdateCompanionBuilder = RecipeTagsCompanion Function({
  Value<String> recipeId,
  Value<TagKind> tagKind,
  Value<String> tag,
  Value<int> rowid,
});

final class $$RecipeTagsTableReferences
    extends BaseReferences<_$AppDatabase, $RecipeTagsTable, RecipeTagEntry> {
  $$RecipeTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RecipesTable _recipeIdTable(_$AppDatabase db) =>
      db.recipes.createAlias('recipe_tags__recipe_id__recipes__id');

  $$RecipesTableProcessedTableManager get recipeId {
    final $_column = $_itemColumn<String>('recipe_id')!;

    final manager = $$RecipesTableTableManager(
      $_db,
      $_db.recipes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RecipeTagsTableFilterComposer
    extends Composer<_$AppDatabase, $RecipeTagsTable> {
  $$RecipeTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<TagKind, TagKind, String> get tagKind =>
      $composableBuilder(
        column: $table.tagKind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnFilters(column),
  );

  $$RecipesTableFilterComposer get recipeId {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableFilterComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipeTagsTable> {
  $$RecipeTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tagKind => $composableBuilder(
    column: $table.tagKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnOrderings(column),
  );

  $$RecipesTableOrderingComposer get recipeId {
    final $$RecipesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableOrderingComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipeTagsTable> {
  $$RecipeTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<TagKind, String> get tagKind =>
      $composableBuilder(column: $table.tagKind, builder: (column) => column);

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);

  $$RecipesTableAnnotationComposer get recipeId {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableAnnotationComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipeTagsTable,
          RecipeTagEntry,
          $$RecipeTagsTableFilterComposer,
          $$RecipeTagsTableOrderingComposer,
          $$RecipeTagsTableAnnotationComposer,
          $$RecipeTagsTableCreateCompanionBuilder,
          $$RecipeTagsTableUpdateCompanionBuilder,
          (RecipeTagEntry, $$RecipeTagsTableReferences),
          RecipeTagEntry,
          PrefetchHooks Function({bool recipeId})
        > {
  $$RecipeTagsTableTableManager(_$AppDatabase db, $RecipeTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipeTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipeTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> recipeId = const Value.absent(),
                Value<TagKind> tagKind = const Value.absent(),
                Value<String> tag = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipeTagsCompanion(
                recipeId: recipeId,
                tagKind: tagKind,
                tag: tag,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String recipeId,
                required TagKind tagKind,
                required String tag,
                Value<int> rowid = const Value.absent(),
              }) => RecipeTagsCompanion.insert(
                recipeId: recipeId,
                tagKind: tagKind,
                tag: tag,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecipeTagsTable, RecipeTagEntry>(table),
                  $$RecipeTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recipeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (recipeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.recipeId,
                        referencedTable: $$RecipeTagsTableReferences
                            ._recipeIdTable(db),
                        referencedColumn: $$RecipeTagsTableReferences
                            ._recipeIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RecipeTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipeTagsTable,
      RecipeTagEntry,
      $$RecipeTagsTableFilterComposer,
      $$RecipeTagsTableOrderingComposer,
      $$RecipeTagsTableAnnotationComposer,
      $$RecipeTagsTableCreateCompanionBuilder,
      $$RecipeTagsTableUpdateCompanionBuilder,
      (RecipeTagEntry, $$RecipeTagsTableReferences),
      RecipeTagEntry,
      PrefetchHooks Function({bool recipeId})
    >;
typedef $$CookedEntriesTableCreateCompanionBuilder =
    CookedEntriesCompanion Function({
      Value<String> id,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      required String recipeId,
      required String cookedOn,
      Value<int?> rating,
      Value<bool?> wouldRepeat,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$CookedEntriesTableUpdateCompanionBuilder =
    CookedEntriesCompanion Function({
      Value<String> id,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> recipeId,
      Value<String> cookedOn,
      Value<int?> rating,
      Value<bool?> wouldRepeat,
      Value<String?> note,
      Value<int> rowid,
    });

class $$CookedEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $CookedEntriesTable> {
  $$CookedEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cookedOn => $composableBuilder(
    column: $table.cookedOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wouldRepeat => $composableBuilder(
    column: $table.wouldRepeat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CookedEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CookedEntriesTable> {
  $$CookedEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cookedOn => $composableBuilder(
    column: $table.cookedOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wouldRepeat => $composableBuilder(
    column: $table.wouldRepeat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CookedEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CookedEntriesTable> {
  $$CookedEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get recipeId =>
      $composableBuilder(column: $table.recipeId, builder: (column) => column);

  GeneratedColumn<String> get cookedOn =>
      $composableBuilder(column: $table.cookedOn, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<bool> get wouldRepeat => $composableBuilder(
    column: $table.wouldRepeat,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$CookedEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CookedEntriesTable,
          CookedEntry,
          $$CookedEntriesTableFilterComposer,
          $$CookedEntriesTableOrderingComposer,
          $$CookedEntriesTableAnnotationComposer,
          $$CookedEntriesTableCreateCompanionBuilder,
          $$CookedEntriesTableUpdateCompanionBuilder,
          (
            CookedEntry,
            BaseReferences<_$AppDatabase, $CookedEntriesTable, CookedEntry>,
          ),
          CookedEntry,
          PrefetchHooks Function()
        > {
  $$CookedEntriesTableTableManager(_$AppDatabase db, $CookedEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CookedEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CookedEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CookedEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> recipeId = const Value.absent(),
                Value<String> cookedOn = const Value.absent(),
                Value<int?> rating = const Value.absent(),
                Value<bool?> wouldRepeat = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CookedEntriesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                recipeId: recipeId,
                cookedOn: cookedOn,
                rating: rating,
                wouldRepeat: wouldRepeat,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                required String recipeId,
                required String cookedOn,
                Value<int?> rating = const Value.absent(),
                Value<bool?> wouldRepeat = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CookedEntriesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                recipeId: recipeId,
                cookedOn: cookedOn,
                rating: rating,
                wouldRepeat: wouldRepeat,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CookedEntriesTable, CookedEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CookedEntriesTable,
                    CookedEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CookedEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CookedEntriesTable,
      CookedEntry,
      $$CookedEntriesTableFilterComposer,
      $$CookedEntriesTableOrderingComposer,
      $$CookedEntriesTableAnnotationComposer,
      $$CookedEntriesTableCreateCompanionBuilder,
      $$CookedEntriesTableUpdateCompanionBuilder,
      (
        CookedEntry,
        BaseReferences<_$AppDatabase, $CookedEntriesTable, CookedEntry>,
      ),
      CookedEntry,
      PrefetchHooks Function()
    >;
typedef $$MealPlanEntriesTableCreateCompanionBuilder =
    MealPlanEntriesCompanion Function({
      Value<String> id,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      required String date,
      required String recipeId,
      Value<String> mealSlot,
      Value<MealPlanStatus> status,
      Value<bool> locked,
      Value<int> rowid,
    });
typedef $$MealPlanEntriesTableUpdateCompanionBuilder =
    MealPlanEntriesCompanion Function({
      Value<String> id,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> date,
      Value<String> recipeId,
      Value<String> mealSlot,
      Value<MealPlanStatus> status,
      Value<bool> locked,
      Value<int> rowid,
    });

class $$MealPlanEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $MealPlanEntriesTable> {
  $$MealPlanEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mealSlot => $composableBuilder(
    column: $table.mealSlot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MealPlanStatus, MealPlanStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get locked => $composableBuilder(
    column: $table.locked,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MealPlanEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MealPlanEntriesTable> {
  $$MealPlanEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mealSlot => $composableBuilder(
    column: $table.mealSlot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get locked => $composableBuilder(
    column: $table.locked,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MealPlanEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealPlanEntriesTable> {
  $$MealPlanEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get recipeId =>
      $composableBuilder(column: $table.recipeId, builder: (column) => column);

  GeneratedColumn<String> get mealSlot =>
      $composableBuilder(column: $table.mealSlot, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MealPlanStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get locked =>
      $composableBuilder(column: $table.locked, builder: (column) => column);
}

class $$MealPlanEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealPlanEntriesTable,
          MealPlanEntry,
          $$MealPlanEntriesTableFilterComposer,
          $$MealPlanEntriesTableOrderingComposer,
          $$MealPlanEntriesTableAnnotationComposer,
          $$MealPlanEntriesTableCreateCompanionBuilder,
          $$MealPlanEntriesTableUpdateCompanionBuilder,
          (
            MealPlanEntry,
            BaseReferences<_$AppDatabase, $MealPlanEntriesTable, MealPlanEntry>,
          ),
          MealPlanEntry,
          PrefetchHooks Function()
        > {
  $$MealPlanEntriesTableTableManager(
    _$AppDatabase db,
    $MealPlanEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealPlanEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealPlanEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealPlanEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> recipeId = const Value.absent(),
                Value<String> mealSlot = const Value.absent(),
                Value<MealPlanStatus> status = const Value.absent(),
                Value<bool> locked = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealPlanEntriesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                date: date,
                recipeId: recipeId,
                mealSlot: mealSlot,
                status: status,
                locked: locked,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                required String date,
                required String recipeId,
                Value<String> mealSlot = const Value.absent(),
                Value<MealPlanStatus> status = const Value.absent(),
                Value<bool> locked = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealPlanEntriesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                date: date,
                recipeId: recipeId,
                mealSlot: mealSlot,
                status: status,
                locked: locked,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MealPlanEntriesTable, MealPlanEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $MealPlanEntriesTable,
                    MealPlanEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MealPlanEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealPlanEntriesTable,
      MealPlanEntry,
      $$MealPlanEntriesTableFilterComposer,
      $$MealPlanEntriesTableOrderingComposer,
      $$MealPlanEntriesTableAnnotationComposer,
      $$MealPlanEntriesTableCreateCompanionBuilder,
      $$MealPlanEntriesTableUpdateCompanionBuilder,
      (
        MealPlanEntry,
        BaseReferences<_$AppDatabase, $MealPlanEntriesTable, MealPlanEntry>,
      ),
      MealPlanEntry,
      PrefetchHooks Function()
    >;
typedef $$FeedbackEventsTableCreateCompanionBuilder =
    FeedbackEventsCompanion Function({
      Value<String> id,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String?> recipeId,
      required FeedbackKind kind,
      Value<String?> reason,
      Value<int> at,
      Value<int> rowid,
    });
typedef $$FeedbackEventsTableUpdateCompanionBuilder =
    FeedbackEventsCompanion Function({
      Value<String> id,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String?> recipeId,
      Value<FeedbackKind> kind,
      Value<String?> reason,
      Value<int> at,
      Value<int> rowid,
    });

class $$FeedbackEventsTableFilterComposer
    extends Composer<_$AppDatabase, $FeedbackEventsTable> {
  $$FeedbackEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FeedbackKind, FeedbackKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FeedbackEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $FeedbackEventsTable> {
  $$FeedbackEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FeedbackEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FeedbackEventsTable> {
  $$FeedbackEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get recipeId =>
      $composableBuilder(column: $table.recipeId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<FeedbackKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<int> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);
}

class $$FeedbackEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FeedbackEventsTable,
          FeedbackEvent,
          $$FeedbackEventsTableFilterComposer,
          $$FeedbackEventsTableOrderingComposer,
          $$FeedbackEventsTableAnnotationComposer,
          $$FeedbackEventsTableCreateCompanionBuilder,
          $$FeedbackEventsTableUpdateCompanionBuilder,
          (
            FeedbackEvent,
            BaseReferences<_$AppDatabase, $FeedbackEventsTable, FeedbackEvent>,
          ),
          FeedbackEvent,
          PrefetchHooks Function()
        > {
  $$FeedbackEventsTableTableManager(
    _$AppDatabase db,
    $FeedbackEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FeedbackEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FeedbackEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FeedbackEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String?> recipeId = const Value.absent(),
                Value<FeedbackKind> kind = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<int> at = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FeedbackEventsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                recipeId: recipeId,
                kind: kind,
                reason: reason,
                at: at,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String?> recipeId = const Value.absent(),
                required FeedbackKind kind,
                Value<String?> reason = const Value.absent(),
                Value<int> at = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FeedbackEventsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                recipeId: recipeId,
                kind: kind,
                reason: reason,
                at: at,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FeedbackEventsTable, FeedbackEvent>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $FeedbackEventsTable,
                    FeedbackEvent
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FeedbackEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FeedbackEventsTable,
      FeedbackEvent,
      $$FeedbackEventsTableFilterComposer,
      $$FeedbackEventsTableOrderingComposer,
      $$FeedbackEventsTableAnnotationComposer,
      $$FeedbackEventsTableCreateCompanionBuilder,
      $$FeedbackEventsTableUpdateCompanionBuilder,
      (
        FeedbackEvent,
        BaseReferences<_$AppDatabase, $FeedbackEventsTable, FeedbackEvent>,
      ),
      FeedbackEvent,
      PrefetchHooks Function()
    >;
typedef $$FeedEventsTableCreateCompanionBuilder = FeedEventsCompanion Function({
  Value<String> id,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  required String recipeId,
  required String event,
  Value<int?> rating,
  Value<String?> contextJson,
  Value<int> at,
  Value<int> rowid,
});
typedef $$FeedEventsTableUpdateCompanionBuilder = FeedEventsCompanion Function({
  Value<String> id,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<String> recipeId,
  Value<String> event,
  Value<int?> rating,
  Value<String?> contextJson,
  Value<int> at,
  Value<int> rowid,
});

final class $$FeedEventsTableReferences
    extends BaseReferences<_$AppDatabase, $FeedEventsTable, FeedEventEntry> {
  $$FeedEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RecipesTable _recipeIdTable(_$AppDatabase db) =>
      db.recipes.createAlias('feed_events__recipe_id__recipes__id');

  $$RecipesTableProcessedTableManager get recipeId {
    final $_column = $_itemColumn<String>('recipe_id')!;

    final manager = $$RecipesTableTableManager(
      $_db,
      $_db.recipes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FeedEventsTableFilterComposer
    extends Composer<_$AppDatabase, $FeedEventsTable> {
  $$FeedEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get event => $composableBuilder(
    column: $table.event,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contextJson => $composableBuilder(
    column: $table.contextJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  $$RecipesTableFilterComposer get recipeId {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableFilterComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FeedEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $FeedEventsTable> {
  $$FeedEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get event => $composableBuilder(
    column: $table.event,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contextJson => $composableBuilder(
    column: $table.contextJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  $$RecipesTableOrderingComposer get recipeId {
    final $$RecipesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableOrderingComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FeedEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FeedEventsTable> {
  $$FeedEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get event =>
      $composableBuilder(column: $table.event, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get contextJson => $composableBuilder(
    column: $table.contextJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  $$RecipesTableAnnotationComposer get recipeId {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableAnnotationComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FeedEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FeedEventsTable,
          FeedEventEntry,
          $$FeedEventsTableFilterComposer,
          $$FeedEventsTableOrderingComposer,
          $$FeedEventsTableAnnotationComposer,
          $$FeedEventsTableCreateCompanionBuilder,
          $$FeedEventsTableUpdateCompanionBuilder,
          (FeedEventEntry, $$FeedEventsTableReferences),
          FeedEventEntry,
          PrefetchHooks Function({bool recipeId})
        > {
  $$FeedEventsTableTableManager(_$AppDatabase db, $FeedEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FeedEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FeedEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FeedEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> recipeId = const Value.absent(),
                Value<String> event = const Value.absent(),
                Value<int?> rating = const Value.absent(),
                Value<String?> contextJson = const Value.absent(),
                Value<int> at = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FeedEventsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                recipeId: recipeId,
                event: event,
                rating: rating,
                contextJson: contextJson,
                at: at,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                required String recipeId,
                required String event,
                Value<int?> rating = const Value.absent(),
                Value<String?> contextJson = const Value.absent(),
                Value<int> at = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FeedEventsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                recipeId: recipeId,
                event: event,
                rating: rating,
                contextJson: contextJson,
                at: at,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FeedEventsTable, FeedEventEntry>(table),
                  $$FeedEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recipeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (recipeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.recipeId,
                        referencedTable: $$FeedEventsTableReferences
                            ._recipeIdTable(db),
                        referencedColumn: $$FeedEventsTableReferences
                            ._recipeIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FeedEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FeedEventsTable,
      FeedEventEntry,
      $$FeedEventsTableFilterComposer,
      $$FeedEventsTableOrderingComposer,
      $$FeedEventsTableAnnotationComposer,
      $$FeedEventsTableCreateCompanionBuilder,
      $$FeedEventsTableUpdateCompanionBuilder,
      (FeedEventEntry, $$FeedEventsTableReferences),
      FeedEventEntry,
      PrefetchHooks Function({bool recipeId})
    >;
typedef $$PreferenceProfileTableCreateCompanionBuilder =
    PreferenceProfileCompanion Function({
      Value<String> id,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<Map<String, dynamic>> dishTypeWeights,
      Value<Map<String, dynamic>> ingredientWeights,
      Value<Map<String, dynamic>> cuisineWeights,
      Value<Map<String, dynamic>> difficultyWeights,
      Value<List<String>> excludedIngredients,
      Value<List<String>> allergies,
      Value<int?> maxTotalMinutes,
      Value<int> servingsDefault,
      Value<int> rowid,
    });
typedef $$PreferenceProfileTableUpdateCompanionBuilder =
    PreferenceProfileCompanion Function({
      Value<String> id,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<Map<String, dynamic>> dishTypeWeights,
      Value<Map<String, dynamic>> ingredientWeights,
      Value<Map<String, dynamic>> cuisineWeights,
      Value<Map<String, dynamic>> difficultyWeights,
      Value<List<String>> excludedIngredients,
      Value<List<String>> allergies,
      Value<int?> maxTotalMinutes,
      Value<int> servingsDefault,
      Value<int> rowid,
    });

class $$PreferenceProfileTableFilterComposer
    extends Composer<_$AppDatabase, $PreferenceProfileTable> {
  $$PreferenceProfileTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    Map<String, dynamic>,
    Map<String, dynamic>,
    String
  >
  get dishTypeWeights => $composableBuilder(
    column: $table.dishTypeWeights,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<
    Map<String, dynamic>,
    Map<String, dynamic>,
    String
  >
  get ingredientWeights => $composableBuilder(
    column: $table.ingredientWeights,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<
    Map<String, dynamic>,
    Map<String, dynamic>,
    String
  >
  get cuisineWeights => $composableBuilder(
    column: $table.cuisineWeights,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<
    Map<String, dynamic>,
    Map<String, dynamic>,
    String
  >
  get difficultyWeights => $composableBuilder(
    column: $table.difficultyWeights,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get excludedIngredients => $composableBuilder(
    column: $table.excludedIngredients,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get allergies => $composableBuilder(
    column: $table.allergies,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get maxTotalMinutes => $composableBuilder(
    column: $table.maxTotalMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get servingsDefault => $composableBuilder(
    column: $table.servingsDefault,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PreferenceProfileTableOrderingComposer
    extends Composer<_$AppDatabase, $PreferenceProfileTable> {
  $$PreferenceProfileTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dishTypeWeights => $composableBuilder(
    column: $table.dishTypeWeights,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ingredientWeights => $composableBuilder(
    column: $table.ingredientWeights,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cuisineWeights => $composableBuilder(
    column: $table.cuisineWeights,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficultyWeights => $composableBuilder(
    column: $table.difficultyWeights,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get excludedIngredients => $composableBuilder(
    column: $table.excludedIngredients,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get allergies => $composableBuilder(
    column: $table.allergies,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxTotalMinutes => $composableBuilder(
    column: $table.maxTotalMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get servingsDefault => $composableBuilder(
    column: $table.servingsDefault,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PreferenceProfileTableAnnotationComposer
    extends Composer<_$AppDatabase, $PreferenceProfileTable> {
  $$PreferenceProfileTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Map<String, dynamic>, String>
  get dishTypeWeights => $composableBuilder(
    column: $table.dishTypeWeights,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Map<String, dynamic>, String>
  get ingredientWeights => $composableBuilder(
    column: $table.ingredientWeights,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Map<String, dynamic>, String>
  get cuisineWeights => $composableBuilder(
    column: $table.cuisineWeights,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Map<String, dynamic>, String>
  get difficultyWeights => $composableBuilder(
    column: $table.difficultyWeights,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<String>, String>
  get excludedIngredients => $composableBuilder(
    column: $table.excludedIngredients,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<String>, String> get allergies =>
      $composableBuilder(column: $table.allergies, builder: (column) => column);

  GeneratedColumn<int> get maxTotalMinutes => $composableBuilder(
    column: $table.maxTotalMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get servingsDefault => $composableBuilder(
    column: $table.servingsDefault,
    builder: (column) => column,
  );
}

class $$PreferenceProfileTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PreferenceProfileTable,
          PreferenceProfileData,
          $$PreferenceProfileTableFilterComposer,
          $$PreferenceProfileTableOrderingComposer,
          $$PreferenceProfileTableAnnotationComposer,
          $$PreferenceProfileTableCreateCompanionBuilder,
          $$PreferenceProfileTableUpdateCompanionBuilder,
          (
            PreferenceProfileData,
            BaseReferences<
              _$AppDatabase,
              $PreferenceProfileTable,
              PreferenceProfileData
            >,
          ),
          PreferenceProfileData,
          PrefetchHooks Function()
        > {
  $$PreferenceProfileTableTableManager(
    _$AppDatabase db,
    $PreferenceProfileTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PreferenceProfileTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PreferenceProfileTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PreferenceProfileTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<Map<String, dynamic>> dishTypeWeights =
                    const Value.absent(),
                Value<Map<String, dynamic>> ingredientWeights =
                    const Value.absent(),
                Value<Map<String, dynamic>> cuisineWeights =
                    const Value.absent(),
                Value<Map<String, dynamic>> difficultyWeights =
                    const Value.absent(),
                Value<List<String>> excludedIngredients = const Value.absent(),
                Value<List<String>> allergies = const Value.absent(),
                Value<int?> maxTotalMinutes = const Value.absent(),
                Value<int> servingsDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PreferenceProfileCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                dishTypeWeights: dishTypeWeights,
                ingredientWeights: ingredientWeights,
                cuisineWeights: cuisineWeights,
                difficultyWeights: difficultyWeights,
                excludedIngredients: excludedIngredients,
                allergies: allergies,
                maxTotalMinutes: maxTotalMinutes,
                servingsDefault: servingsDefault,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<Map<String, dynamic>> dishTypeWeights =
                    const Value.absent(),
                Value<Map<String, dynamic>> ingredientWeights =
                    const Value.absent(),
                Value<Map<String, dynamic>> cuisineWeights =
                    const Value.absent(),
                Value<Map<String, dynamic>> difficultyWeights =
                    const Value.absent(),
                Value<List<String>> excludedIngredients = const Value.absent(),
                Value<List<String>> allergies = const Value.absent(),
                Value<int?> maxTotalMinutes = const Value.absent(),
                Value<int> servingsDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PreferenceProfileCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                dishTypeWeights: dishTypeWeights,
                ingredientWeights: ingredientWeights,
                cuisineWeights: cuisineWeights,
                difficultyWeights: difficultyWeights,
                excludedIngredients: excludedIngredients,
                allergies: allergies,
                maxTotalMinutes: maxTotalMinutes,
                servingsDefault: servingsDefault,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PreferenceProfileTable, PreferenceProfileData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $PreferenceProfileTable,
                    PreferenceProfileData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PreferenceProfileTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PreferenceProfileTable,
      PreferenceProfileData,
      $$PreferenceProfileTableFilterComposer,
      $$PreferenceProfileTableOrderingComposer,
      $$PreferenceProfileTableAnnotationComposer,
      $$PreferenceProfileTableCreateCompanionBuilder,
      $$PreferenceProfileTableUpdateCompanionBuilder,
      (
        PreferenceProfileData,
        BaseReferences<
          _$AppDatabase,
          $PreferenceProfileTable,
          PreferenceProfileData
        >,
      ),
      PreferenceProfileData,
      PrefetchHooks Function()
    >;
typedef $$AiRequestsTableCreateCompanionBuilder = AiRequestsCompanion Function({
  Value<String> id,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  required String kind,
  required String promptHash,
  required String responseJson,
  required String model,
  Value<int?> tokensIn,
  Value<int?> tokensOut,
  required String status,
  Value<int> at,
  Value<int> rowid,
});
typedef $$AiRequestsTableUpdateCompanionBuilder = AiRequestsCompanion Function({
  Value<String> id,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<String> kind,
  Value<String> promptHash,
  Value<String> responseJson,
  Value<String> model,
  Value<int?> tokensIn,
  Value<int?> tokensOut,
  Value<String> status,
  Value<int> at,
  Value<int> rowid,
});

class $$AiRequestsTableFilterComposer
    extends Composer<_$AppDatabase, $AiRequestsTable> {
  $$AiRequestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get promptHash => $composableBuilder(
    column: $table.promptHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get responseJson => $composableBuilder(
    column: $table.responseJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tokensIn => $composableBuilder(
    column: $table.tokensIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tokensOut => $composableBuilder(
    column: $table.tokensOut,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AiRequestsTableOrderingComposer
    extends Composer<_$AppDatabase, $AiRequestsTable> {
  $$AiRequestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get promptHash => $composableBuilder(
    column: $table.promptHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get responseJson => $composableBuilder(
    column: $table.responseJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tokensIn => $composableBuilder(
    column: $table.tokensIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tokensOut => $composableBuilder(
    column: $table.tokensOut,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AiRequestsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiRequestsTable> {
  $$AiRequestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get promptHash => $composableBuilder(
    column: $table.promptHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get responseJson => $composableBuilder(
    column: $table.responseJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<int> get tokensIn =>
      $composableBuilder(column: $table.tokensIn, builder: (column) => column);

  GeneratedColumn<int> get tokensOut =>
      $composableBuilder(column: $table.tokensOut, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);
}

class $$AiRequestsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AiRequestsTable,
          AiRequest,
          $$AiRequestsTableFilterComposer,
          $$AiRequestsTableOrderingComposer,
          $$AiRequestsTableAnnotationComposer,
          $$AiRequestsTableCreateCompanionBuilder,
          $$AiRequestsTableUpdateCompanionBuilder,
          (
            AiRequest,
            BaseReferences<_$AppDatabase, $AiRequestsTable, AiRequest>,
          ),
          AiRequest,
          PrefetchHooks Function()
        > {
  $$AiRequestsTableTableManager(_$AppDatabase db, $AiRequestsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiRequestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiRequestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiRequestsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> promptHash = const Value.absent(),
                Value<String> responseJson = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<int?> tokensIn = const Value.absent(),
                Value<int?> tokensOut = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> at = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AiRequestsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                kind: kind,
                promptHash: promptHash,
                responseJson: responseJson,
                model: model,
                tokensIn: tokensIn,
                tokensOut: tokensOut,
                status: status,
                at: at,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                required String kind,
                required String promptHash,
                required String responseJson,
                required String model,
                Value<int?> tokensIn = const Value.absent(),
                Value<int?> tokensOut = const Value.absent(),
                required String status,
                Value<int> at = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AiRequestsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                kind: kind,
                promptHash: promptHash,
                responseJson: responseJson,
                model: model,
                tokensIn: tokensIn,
                tokensOut: tokensOut,
                status: status,
                at: at,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AiRequestsTable, AiRequest>(table),
                  BaseReferences<_$AppDatabase, $AiRequestsTable, AiRequest>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AiRequestsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AiRequestsTable,
      AiRequest,
      $$AiRequestsTableFilterComposer,
      $$AiRequestsTableOrderingComposer,
      $$AiRequestsTableAnnotationComposer,
      $$AiRequestsTableCreateCompanionBuilder,
      $$AiRequestsTableUpdateCompanionBuilder,
      (AiRequest, BaseReferences<_$AppDatabase, $AiRequestsTable, AiRequest>),
      AiRequest,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $IngredientsFtsTableManager get ingredientsFts =>
      $IngredientsFtsTableManager(_db, _db.ingredientsFts);
  $$IngredientsTableTableManager get ingredients =>
      $$IngredientsTableTableManager(_db, _db.ingredients);
  $$PantryItemsTableTableManager get pantryItems =>
      $$PantryItemsTableTableManager(_db, _db.pantryItems);
  $$RecipesTableTableManager get recipes =>
      $$RecipesTableTableManager(_db, _db.recipes);
  $$RecipeIngredientsTableTableManager get recipeIngredients =>
      $$RecipeIngredientsTableTableManager(_db, _db.recipeIngredients);
  $$RecipeStepsTableTableManager get recipeSteps =>
      $$RecipeStepsTableTableManager(_db, _db.recipeSteps);
  $$RecipeTagsTableTableManager get recipeTags =>
      $$RecipeTagsTableTableManager(_db, _db.recipeTags);
  $$CookedEntriesTableTableManager get cookedEntries =>
      $$CookedEntriesTableTableManager(_db, _db.cookedEntries);
  $$MealPlanEntriesTableTableManager get mealPlanEntries =>
      $$MealPlanEntriesTableTableManager(_db, _db.mealPlanEntries);
  $$FeedbackEventsTableTableManager get feedbackEvents =>
      $$FeedbackEventsTableTableManager(_db, _db.feedbackEvents);
  $$FeedEventsTableTableManager get feedEvents =>
      $$FeedEventsTableTableManager(_db, _db.feedEvents);
  $$PreferenceProfileTableTableManager get preferenceProfile =>
      $$PreferenceProfileTableTableManager(_db, _db.preferenceProfile);
  $$AiRequestsTableTableManager get aiRequests =>
      $$AiRequestsTableTableManager(_db, _db.aiRequests);
}
