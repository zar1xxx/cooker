# Иконки разделов и значок «От помощника»

Все SVG нарисованы с нуля для проекта (лицензионных ограничений нет), viewBox 64×64, обводка 3, скруглённые концы.

| Файл | Раздел |
|---|---|
| sections/bakery.svg | выпечка |
| sections/meat.svg | мясные |
| sections/fish.svg | рыбные |
| sections/vegetables.svg | овощные |
| sections/soups.svg | супы |
| sections/porridges.svg | каши и гарниры |
| sections/salads.svg | салаты и закуски |
| sections/dairy_eggs.svg | яйца и молочное |
| sections/desserts.svg | десерты |
| sections/drinks.svg | напитки |
| sections/preserves.svg | заготовки |
| badges/from_assistant.svg | плашка «От помощника» |

Подключение: в pubspec.yaml добавлены `assets/images/sections/` и `assets/images/badges/`. Для показа SVG нужен пакет `flutter_svg` (в проект пока не добавлен — решение владельца, см. D-059 в docs/DECISIONS.md, если принято).
