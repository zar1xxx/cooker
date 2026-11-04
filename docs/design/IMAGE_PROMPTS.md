# Промпты для графики приложения «Что приготовить?»

Здесь вся графика, которая нужна приложению: иконка, заставка, иконки категорий и типов блюд, заглушки для рецептов, иллюстрации пустых экранов и состояний. Для каждого элемента есть назначение, файл, размер и готовый промпт.

Промпты написаны на английском: генераторы изображений (Midjourney, DALL·E, Stable Diffusion, Kandinsky, Шедеврум) понимают его точнее. Пояснения — на русском.

---

## 0. Как пользоваться

1. **Всегда добавляй к промпту блок стиля** из раздела 1 (`STYLE`) и негативный промпт (`NEGATIVE`), если генератор его поддерживает. Без этого элементы одного набора получатся разными.
2. **Генерируй набор за один заход**, с одним seed или одним референсом стиля. Если генератор умеет «style reference» — после первой удачной иконки подавай её как референс для остальных.
3. **Текста на картинках нет.** Все подписи — в приложении из ARB-файла: генераторы искажают кириллицу, а подписи должны масштабироваться со шрифтом.
4. **Прозрачный фон.** Генераторы редко дают настоящую прозрачность. Генерируй на ровном фоне `#F9F9F6`, затем убирай фон (remove.bg, Photoshop, `rembg`). Проверь, что картинка хорошо смотрится и на светлом `#F9F9F6`, и на тёмном `#121413` фоне.
5. **Мелкие иконки лучше векторизовать.** Иконки категорий и типов блюд после генерации прогони через векторизатор (Vectorizer.ai, Inkscape → Trace Bitmap) и подключай как SVG через `flutter_svg` — они будут резкими при любом размере шрифта.
6. **Не копируй чужое.** Никаких логотипов, брендов, персонажей мультфильмов и узнаваемых упаковок продуктов.

---

## 1. Общий стиль

Палитра взята из темы приложения (`lib/app/theme.dart`) и дополнена тёплыми цветами еды.

| Роль | Цвет | Где |
| --- | --- | --- |
| Основной | `#1E5B3A` глубокий зелёный | контуры, акценты, иконка |
| Основной (тёмная тема) | `#69D898` светло-зелёный | акценты на тёмном фоне |
| Фон | `#F9F9F6` тёплый белый | фон иллюстраций при генерации |
| Тёплый акцент | `#C8643B` терракотовый | мясо, хлеб, посуда |
| Жёлтый акцент | `#E0A526` горчичный | крупы, сыр, свет |
| Мягкий | `#F2E6D0` кремовый | подложки, тарелки |
| Контур | `#2B2F2C` почти чёрный | обводка (если стиль с контуром) |

**STYLE** — добавлять в конец каждого промпта:

```
flat vector illustration, warm and friendly home-kitchen style, simple rounded shapes, thick clean outlines in dark green-black #2B2F2C, limited palette: deep green #1E5B3A, terracotta #C8643B, mustard yellow #E0A526, cream #F2E6D0, soft off-white background #F9F9F6, subtle soft shading only, no gradients, high contrast, large clear silhouettes readable at small size, centered composition, generous empty space around the subject, cozy grandmother's kitchen mood, consistent icon set style
```

**NEGATIVE** — для генераторов с негативным промптом:

```
text, letters, words, numbers, watermark, signature, logo, brand names, photorealistic, 3d render, glossy, neon, harsh gradients, tiny details, cluttered background, busy pattern, thin hairline strokes, dark moody lighting, people's faces, hands with extra fingers, blurry, low contrast, cropped subject
```

Почему так: бабушке важно с первого взгляда узнать, что нарисовано. Поэтому силуэты крупные и простые, контур толстый, контраст высокий, мелких деталей нет.

---

## 2. Иконка приложения

### 2.1. Основная иконка (Google Play и лаунчер)

- **Файлы:** `assets/branding/icon_1024.png` (исходник), `assets/branding/icon_foreground.png` (передний план для adaptive icon), `assets/branding/icon_monochrome.png` (для тематических иконок Android 13+).
- **Размер:** 1024×1024 px. Для adaptive icon важная часть рисунка должна помещаться в центральный круг диаметром ~66 % холста — края обрезаются маской лаунчера.
- **Фон adaptive icon:** сплошной цвет `#1E5B3A` (задаётся цветом, не картинкой).

```
App icon for a home cooking helper app: a simple round cooking pot with a lid slightly lifted, three soft curls of steam rising and forming a gentle question-mark shape, a small sprig of green dill on the lid handle, pot in cream #F2E6D0 with terracotta #C8643B lid, steam in white, all centered inside the middle 60% of the canvas, plain solid deep green #1E5B3A background, bold simple shapes recognizable at 48px, friendly and warm, no text
```

**Передний план (без фона, для adaptive icon):** тот же промпт, но замени конец на `transparent background, subject fits within the central 66% safe zone, nothing near the edges`.

**Монохромная версия:**

```
Single-color white silhouette of a cooking pot with a lifted lid and three curls of steam forming a soft question mark, flat solid shapes only, no outlines, no shading, on transparent background, centered within the central 66% of the canvas, readable at 24px
```

### 2.2. Иконка уведомлений

- **Файл:** `android/app/src/main/res/drawable/ic_notification.png` (или vector drawable).
- **Размер:** 96×96 px исходник → уменьшить до 24 dp. Только белый силуэт на прозрачном фоне: Android сам перекрашивает её в цвет системы.

```
Minimal white silhouette icon of a cooking pot with a small steam curl, solid flat white shape on fully transparent background, no details smaller than 1/12 of the canvas, no outlines, no color, suitable for an Android status bar notification icon at 24dp
```

---

## 3. Заставка (splash screen)

- **Файл:** `assets/branding/splash_icon.png`.
- **Размер:** 1152×1152 px. Android 12+ показывает иконку в круге: рисунок должен помещаться в центральный круг ~2/3 холста.
- **Фон заставки:** `#F9F9F6` (светлая тема), `#121413` (тёмная) — задаётся цветом в `flutter_native_splash`.

```
Splash screen emblem: the same friendly cooking pot with lifted lid and steam curls shaped like a soft question mark, cream pot with terracotta lid and a green dill sprig, centered, transparent background, subject fits within a central circle of 66% of the canvas, calm and welcoming, no text
```

---

## 4. Иконки категорий продуктов (экран «Что есть дома»)

- **Где:** плитки категорий на экране «Что есть дома» (ТЗ 7.2), список — `spec/data/ingredient_categories.json`.
- **Файлы:** `assets/icons/categories/<id>.svg` (после векторизации) или `<id>.png` 512×512.
- **Размер на экране:** ~48–64 dp. Генерировать 1024×1024, затем векторизовать.

**Шаблон** (вставь объект из таблицы на место `{SUBJECT}`):

```
Square icon for a food category: {SUBJECT}, single grouped composition of 2-3 items maximum, flat vector, thick rounded outlines, centered with 15% padding on each side, transparent background, recognizable at 48px, part of a consistent food icon set
```

| id | Подпись в приложении | `{SUBJECT}` |
| --- | --- | --- |
| `vegetables` | Овощи | a carrot, a potato and an onion lying together |
| `fruits` | Фрукты и ягоды | a red apple with a leaf and a small bunch of cherries |
| `meat` | Мясо | a raw beef steak with a white fat edge on a small wooden board |
| `poultry` | Птица | a whole raw chicken leg (drumstick), simple and clean |
| `fish` | Рыба и морепродукты | a whole silver fish with a lemon slice |
| `dairy` | Молочное и яйца | a glass bottle of milk and two brown eggs |
| `grains` | Крупы и макароны | a cloth sack of buckwheat with a scoop and a few pasta shells |
| `bakery` | Мука и хлеб | a round loaf of rye bread and a small bag of flour |
| `legumes` | Бобовые | a small bowl of beans with a few pea pods |
| `mushrooms` | Грибы | two forest mushrooms with brown caps, one small one large |
| `canned` | Консервы | a plain tin can without any label and a glass jar of pickles |
| `spices` | Специи и соусы | a salt shaker, a black pepper grinder and a bay leaf |
| `nuts` | Орехи и семечки | a walnut, a hazelnut and a few sunflower seeds |
| `sweets` | Сладкое | a jar of honey with a dipper and a sugar cube |
| `greens` | Зелень | a bunch of dill and parsley tied with string |

---

## 5. Иконки частых продуктов (плитки и «Часто выбираете»)

- **Где:** плитки отдельных продуктов. На первом релизе хватит ~40 самых частых; остальные продукты показываются иконкой своей категории.
- **Файлы:** `assets/icons/ingredients/<ingredient_id>.svg` — имя файла совпадает с `id` в `assets/seed/ingredients.json`.
- **Размер:** генерировать 1024×1024, на экране ~40–56 dp.

**Шаблон:**

```
Single food item icon: {ITEM}, one object only, flat vector, thick rounded outlines, centered with 15% padding, transparent background, recognizable at 40px, same style as the food category icon set
```

| `ingredient_id` | `{ITEM}` |
| --- | --- |
| `potato` | a brown potato |
| `onion` | a yellow onion with dry skin |
| `carrot` | an orange carrot with green top |
| `beet` | a dark red beetroot with leaves |
| `cabbage` | a round green cabbage head |
| `tomato` | a red tomato with green stem |
| `cucumber` | a green cucumber |
| `garlic` | a garlic bulb |
| `bell_pepper` | a red bell pepper |
| `zucchini` | a green zucchini |
| `chicken` | a whole raw chicken carcass, simple |
| `chicken_fillet` | a raw chicken breast fillet |
| `minced_meat` | a portion of raw minced meat on a plate |
| `pork` | a raw pork chop |
| `beef` | a raw beef steak |
| `sausage` | a cooked sausage (doctor's style, plain, no label) |
| `fish` | a whole fish |
| `egg` | two eggs, one brown one white |
| `milk` | a glass bottle of milk |
| `kefir` | a glass of thick white kefir |
| `sour_cream` | a small bowl of sour cream with a spoon |
| `cottage_cheese` | a bowl of crumbly cottage cheese (tvorog) |
| `cheese` | a wedge of yellow cheese with holes |
| `butter` | a block of butter on a small dish |
| `rice` | a small bowl of white rice grains |
| `buckwheat` | a small bowl of buckwheat groats |
| `oats` | a small bowl of rolled oats |
| `pasta` | a handful of pasta shells and spaghetti |
| `flour` | a paper bag of flour with a little spilled |
| `bread` | a sliced loaf of bread |
| `beans_dry` | a handful of dry red beans |
| `peas` | an open green pea pod |
| `mushrooms` | two forest mushrooms |
| `apple` | a red apple |
| `lemon` | a lemon with a slice |
| `honey` | a jar of honey |
| `sugar` | a bowl of sugar cubes |
| `salt` | a salt shaker |
| `sunflower_oil` | a bottle of golden sunflower oil, no label |
| `dill` | a bunch of dill |

Если в seed появятся другие `id`, промпт строится так же: один предмет, понятный силуэт.

---

## 6. Иконки типов блюд (фильтры, карточки, календарь)

- **Где:** чипы-фильтры на экране «Блюда», значок в карточке, клетка дня в календаре (ТЗ 7.2, 8.1). Значения — `DishType` из `spec/data/enums.json`.
- **Файлы:** `assets/icons/dish_types/<value>.svg`.
- **Размер на экране:** 24–40 dp, поэтому силуэт должен быть особенно простым.

**Шаблон:**

```
Simple icon of {DISH}, seen from a 3/4 angle, one dish only, flat vector, thick rounded outlines, minimal details, centered with 15% padding, transparent background, must stay recognizable at 24px, consistent dish icon set
```

| `value` | Подпись | `{DISH}` |
| --- | --- | --- |
| `soup` | Суп | a deep bowl of red borscht with a spoon and a dollop of sour cream |
| `main` | Второе | a plate with a cutlet and mashed potatoes |
| `side` | Гарнир | a small bowl of buckwheat with a pat of butter |
| `salad` | Салат | a bowl of fresh salad with cucumber and tomato slices |
| `breakfast` | Завтрак | a frying pan with two sunny-side-up eggs |
| `snack` | Закуска | a small plate with open sandwiches |
| `baking` | Выпечка | a round pie with a lattice top |
| `dessert` | Десерт | a stack of three pancakes with berries on top |
| `drink` | Напиток | a glass mug of berry kompot |
| `preserve` | Заготовки | a glass jar of pickled cucumbers with a metal lid |

---

## 7. Сложность

Лучше не генерировать, а нарисовать вектором из одной детали — поварского колпака: 1, 2 или 3 колпака заливкой, остальные контуром (ТЗ 7.2). Если всё же генерировать:

- **Файлы:** `assets/icons/difficulty/hat_filled.svg`, `hat_outline.svg`.

```
Single chef's hat icon, simple rounded toque shape, solid fill in deep green #1E5B3A, flat vector, no outline details, centered, transparent background, readable at 20px
```

```
Single chef's hat icon, simple rounded toque shape, outline only with thick deep green #1E5B3A stroke and empty inside, flat vector, centered, transparent background, readable at 20px
```

---

## 8. Заглушки для рецептов без фото

- **Где:** верх карточки рецепта и экран рецепта, если у блюда нет своей картинки. Для рецептов от ИИ фото не будет никогда, поэтому заглушка нужна на каждый тип блюда.
- **Файлы:** `assets/images/placeholders/<dish_type>.webp`.
- **Размер:** 1600×900 px (16:9), WebP ~80 % качества.
- **Важно:** на заглушке не должно быть конкретного блюда с названием. Она передаёт тип («суп»), а не обещает, как выглядит именно этот рецепт.

**Шаблон:**

```
Wide horizontal illustration 16:9 for a recipe card header: {SCENE}, viewed from slightly above, cozy home kitchen table with a linen napkin, flat vector illustration with soft shapes, warm palette deep green #1E5B3A, terracotta #C8643B, mustard #E0A526, cream #F2E6D0, calm uncluttered background, main subject in the center third, empty soft space on the left and right so the image can be cropped to square, no text, no people
```

| `dish_type` | `{SCENE}` |
| --- | --- |
| `soup` | a steaming ceramic soup bowl with a ladle and a slice of rye bread beside it |
| `main` | a family dinner plate with a hot main course, a fork and a knife |
| `side` | a serving bowl with a warm side dish and a wooden spoon |
| `salad` | a large bowl of fresh vegetable salad with herbs |
| `breakfast` | a breakfast set: a frying pan with eggs, a cup of tea, a slice of bread |
| `snack` | a wooden board with small appetizers |
| `baking` | a freshly baked pie on a cooling rack with steam |
| `dessert` | a plate of sweet pancakes with a jar of jam |
| `drink` | a glass jug of berry kompot and two glasses |
| `preserve` | a row of glass jars with pickles and jam on a shelf |

---

## 9. Иллюстрации экранов и состояний

Крупные иллюстрации для пустых экранов, ошибок и моментов радости. На экране — 160–220 dp, под ними текст из ARB.

- **Файлы:** `assets/images/states/<name>.webp` (или `.png` с прозрачностью).
- **Размер:** 1200×1200 px, прозрачный фон.

**Шаблон:**

```
Spot illustration for a mobile app screen state: {SCENE}, single clear focal point, flat vector, thick rounded outlines, warm friendly mood, transparent background, centered with 10% padding, no text, no faces
```

| Файл | Где показывается | `{SCENE}` |
| --- | --- | --- |
| `pantry_empty` | «Что есть дома», ничего не отмечено | an open empty refrigerator shelf with a small friendly note pinned with a magnet, inviting to add products |
| `no_dishes` | «Блюда», ничего не подобралось | an empty plate with a fork and a spoon beside it and a small question mark made of steam above it |
| `missing_few` | подсказка «Не хватает 1–2 продуктов» | a shopping basket with one carrot and one onion peeking out |
| `history_empty` | «История», ещё ничего не готовили | an open recipe notebook with blank pages and a pencil |
| `calendar_empty` | «Календарь», плана нет | a wall calendar page with empty squares and a wooden spoon leaning against it |
| `cooking_done` | после «Готово!» в режиме готовки | a beautiful steaming pot on a table with small sparkles and a heart-shaped curl of steam, celebratory but calm |
| `rate_dish` | экран оценки после готовки | a plate with a finished dish and five rounded stars floating above it |
| `offline` | нет интернета, показываем сохранённое | a cozy kitchen radio with a small cloud and a crossed-out signal wave, calm not alarming |
| `ai_thinking` | ИИ подбирает новые блюда (поверх загрузки) | a cookbook with pages turning by themselves and little sparkles, magical but simple |
| `pc_search` | настройки: «Найти компьютер» | a desktop computer monitor and a smartphone connected by a dotted wavy line with a small house icon between them |
| `pc_found` | компьютер найден | the same monitor and smartphone with a solid green line and a check mark |
| `pc_not_found` | компьютер не найден | the same monitor and smartphone with a dotted line broken in the middle, gentle not scary |
| `error_generic` | неожиданная ошибка | a slightly tipped over pot with a little spill and a small bandage on it, light humor |

---

## 10. Режим готовки и таймер

| Файл | Где | Промпт |
| --- | --- | --- |
| `assets/images/cooking/timer_ring.webp` | полноэкранный сигнал таймера | `Spot illustration of a classic round kitchen timer ringing, small motion lines around it, flat vector, thick rounded outlines, terracotta #C8643B timer body, transparent background, centered, no text, no numbers on the dial` |
| `assets/images/cooking/step_start.webp` | первый шаг | `Spot illustration of a clean cutting board with a knife and a few fresh vegetables ready to be chopped, flat vector, warm palette, transparent background, centered, no text` |

Цифры на таймере не рисуются: время показывает приложение крупным шрифтом.

---

## 11. Google Play (для публикации, по желанию)

| Файл | Размер | Промпт |
| --- | --- | --- |
| `assets/branding/play_feature.png` | 1024×500 | `Wide banner illustration: a cozy home kitchen table with a cooking pot, a recipe notebook, fresh vegetables and a smartphone showing an abstract list of colorful dish cards, flat vector, warm palette deep green #1E5B3A, terracotta #C8643B, mustard #E0A526, cream background, generous empty space on the left third for a title added later, no text` |

Скриншоты для Play делаются из самого приложения, не генерируются.

---

## 12. Подключение во Flutter (для агента)

1. Положи файлы по путям выше. Добавь папки в `pubspec.yaml` → `flutter: assets:`: `assets/icons/categories/`, `assets/icons/ingredients/`, `assets/icons/dish_types/`, `assets/icons/difficulty/`, `assets/images/placeholders/`, `assets/images/states/`, `assets/images/cooking/`.
2. SVG — через пакет `flutter_svg`; размер иконки задаётся от размера шрифта темы, а не числом.
3. Иконка приложения — `flutter_launcher_icons`: `image_path: assets/branding/icon_1024.png`, `adaptive_icon_background: "#1E5B3A"`, `adaptive_icon_foreground: assets/branding/icon_foreground.png`, `adaptive_icon_monochrome: assets/branding/icon_monochrome.png`.
4. Заставка — `flutter_native_splash`: `color: "#F9F9F6"`, `color_dark: "#121413"`, `android_12: image: assets/branding/splash_icon.png`.
5. Нет файла для продукта или типа → иконка категории; нет и её → Material-иконка. Отсутствие картинки не должно ломать экран (виджет-тест).
6. У каждой картинки — `Semantics(label: ...)` из ARB или `excludeSemantics: true`, если она декоративная (правило `skills/senior-ux`).
7. Проверь каждую иллюстрацию на светлой и тёмной теме. Если на тёмной теряется контур — сделай вариант `_dark` или подложку `#F2E6D0` с закруглением.

## Чек-лист готовности набора

- [ ] Все иконки одного набора в одном стиле (поставь рядом и сравни).
- [ ] Иконки категорий и типов блюд узнаются при 24–40 px.
- [ ] Нет текста, цифр, логотипов, брендов.
- [ ] Фон прозрачный, видно на светлой и тёмной теме.
- [ ] Имена файлов совпадают с `id` в seed и значениями `DishType`.
- [ ] Вес: иконки SVG < 30 КБ, иллюстрации WebP < 150 КБ.
