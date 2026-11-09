import '../db/enums.dart';

/// The 11 canonical dish groups ("kingdoms") of the recipe catalog.
/// Each recipe belongs to exactly ONE dish group.
enum DishGroup {
  baking('baking', 'Выпечка'),
  meat('meat', 'Мясные блюда'),
  fishSeafood('fish_seafood', 'Рыбные и морепродукты'),
  vegetable('vegetable', 'Овощные блюда'),
  soup('soup', 'Супы'),
  porridgeSide('porridge_side', 'Каши и гарниры'),
  saladSnack('salad_snack', 'Салаты и закуски'),
  eggDairy('egg_dairy', 'Яйца и молочное'),
  dessert('dessert', 'Десерты'),
  beverage('beverage', 'Напитки'),
  preserves('preserves', 'Заготовки');

  final String id;
  final String titleRu;

  const DishGroup(this.id, this.titleRu);

  static DishGroup fromId(String id) {
    for (final group in DishGroup.values) {
      if (group.id == id) return group;
    }
    // Fallback for case-insensitive or dash-separated
    final normalized = id.toLowerCase().replaceAll('-', '_');
    for (final group in DishGroup.values) {
      if (group.id == normalized) return group;
    }
    throw ArgumentError('Unknown DishGroup id: "$id"');
  }

  static DishGroup? tryFromId(String? id) {
    if (id == null || id.isEmpty) return null;
    try {
      return fromId(id);
    } catch (_) {
      return null;
    }
  }

  /// Map legacy [DishType] to the closest default [DishGroup].
  static DishGroup fromDishType(DishType type) {
    switch (type) {
      case DishType.soup:
        return DishGroup.soup;
      case DishType.main:
        return DishGroup.meat;
      case DishType.side:
        return DishGroup.porridgeSide;
      case DishType.salad:
        return DishGroup.saladSnack;
      case DishType.breakfast:
        return DishGroup.eggDairy;
      case DishType.snack:
        return DishGroup.saladSnack;
      case DishType.baking:
        return DishGroup.baking;
      case DishType.dessert:
        return DishGroup.dessert;
      case DishType.drink:
        return DishGroup.beverage;
      case DishType.preserve:
        return DishGroup.preserves;
    }
  }
}
