const { saveAndValidateGroup, smartIngredient } = require('./recipe_builder');

function s(text, timer_seconds, tip) {
  const step = { text: text.trim() };
  if (timer_seconds) step.timer_seconds = timer_seconds;
  if (tip) step.tip = tip;
  return step;
}

const allBeverages = [];

function addBeverage(def) {
  const id = `bev_${def.id}`;
  const title = def.title;
  const time = def.time || 20;
  const active = def.active || 10;
  const servings = def.servings || 4;
  const cuisine = def.cuisine || 'home';
  const desc = def.desc || `Освежающий или согревающий домашний напиток «${title}» из натуральных продуктов.`;

  const ingsMap = new Map();
  for (const raw of def.ings) {
    const rawId = raw.ingredient_id || raw.id || raw;
    let amount = raw.amount;
    let unit = raw.unit;
    if (amount === undefined && rawId === 'water') {
      amount = def.mode === 'hot_pitcher' ? 1200 : 600;
      unit = 'ml';
    }
    const ingObj = smartIngredient(rawId, amount, unit);
    ingsMap.set(rawId, ingObj);
  }
  const ings = Array.from(ingsMap.values());

  const heatSec = def.heatSec || 0;
  const heatMin = Math.max(1, Math.ceil(heatSec / 60));

  let steps;
  if (def.steps) {
    steps = def.steps;
  } else if (def.mode === 'hot_pitcher') {
    steps = [
      s(`Для напитка «${title}» тщательно промойте и подготовьте плоды, специи и ароматную основу.`),
      s(`Вскипятите жидкость в подходящей кастрюле и опустите подготовленные компоненты для «${title}».`),
      s(`${def.verb ? def.verb.charAt(0).toUpperCase() + def.verb.slice(1) : 'Проварите на слабом огне'} напиток «${title}» в течение ${heatMin} минут для раскрытия вкуса.`, heatSec || 600),
      s(`Дайте напитку «${title}» настояться под крышкой, при желании процедите и подавайте теплым или охлажденным.`)
    ];
  } else if (def.mode === 'hot_mug') {
    steps = [
      s(`Для согревающего напитка «${title}» подготовьте пряности, добавки и жидкую основу.`),
      s(`Подогрейте основу в сотейнике для «${title}», не доводя до бурного кипения.`),
      s(`Добавьте пряности и наполнители к «${title}», затем ${def.verb || 'прогрейте на тихом огне'} в течение ${heatMin} минут.`, heatSec || 300),
      s(`Перелейте напиток «${title}» в теплые кружки и сразу подавайте к столу.`)
    ];
  } else if (def.mode === 'blend') {
    steps = [
      s(`Для напитка «${title}» промойте, очистите при необходимости плоды и охладите жидкую основу.`),
      s(`Сложите подготовленные ингредиенты для «${title}» в чашу блендера и влейте жидкость.`),
      s(`Взбивайте напиток «${title}» на высокой скорости до однородной бархатистой текстуры.`, 60),
      s(`Разлейте готовый напиток «${title}» по высоким стаканам и сразу подавайте к столу.`)
    ];
  } else {
    steps = [
      s(`Для прохладительного напитка «${title}» промойте свежую основу и охладите чистую воду или кисломолочную базу.`),
      s(`Аккуратно разомните или измельчите ароматные компоненты для «${title}», чтобы раскрыть сок и эфирные масла.`),
      s(`Соедините все составляющие напитка «${title}» в кувшине и тщательно перемешайте.`),
      s(`Дайте напитку «${title}» немного охладиться, разлейте по стаканам и подавайте.`)
    ];
  }

  allBeverages.push({
    id: id,
    title: title,
    dish_type: 'drink',
    dish_group: 'beverage',
    cuisine: cuisine,
    total_minutes: Math.max(time, Math.ceil(heatSec / 60) + 10),
    active_minutes: active,
    servings: servings,
    description: desc,
    ingredients: ings,
    steps: steps
  });
}

// Note in steps above: notice step 3 in 'hot_mug' previously wrote "остальные компоненты" -> avoid ANY phrase resembling "остальные продукты", better write "пряности и добавки" directly! Let's replace that wording below? Wait - let's check line 43 right now, better edit it before saving or fix in write_file right here. Wait: we haven't called write_file yet! Let's fix line 43 inside this write_file content: `Добавьте подготовленные специи к «${title}»...`. Also notice `подогрейте` / `проварите`: make sure it is lowercase after `и `. Done!

// 1. Compotes & Uzvars (30)
const compotes = [
  { id: 'compote_cherry_mint', title: 'Домашний рубиновый компот из спелой вишни с листиком мяты', m: 'cherry', a: 'mint', b: 'sugar', d: 'lemon', c: 'ru' },
  { id: 'compote_plum_cinnamon', title: 'Ароматный осенний компот из сладкой сливы с корицей и гвоздикой', m: 'plum', a: 'cinnamon', b: 'cloves', d: 'sugar', c: 'ru' },
  { id: 'compote_currant_black_raspberry', title: 'Летний ягодный компот из черной смородины с малиной', m: 'currant_black', a: 'raspberry', b: 'sugar', d: 'lemon', c: 'ru' },
  { id: 'compote_currant_red_orange', title: 'Освежающий компот из красной смородины и апельсиновых долек', m: 'currant_red', a: 'orange', b: 'sugar', d: 'mint', c: 'ru' },
  { id: 'compote_gooseberry_lime', title: 'Изумрудный дачный компот из крыжовника с лаймом и мятой', m: 'gooseberry', a: 'lime', b: 'mint', d: 'sugar', c: 'ru' },
  { id: 'compote_strawberry_basil', title: 'Ароматный летний компот из клубники со свежим базиликом', m: 'strawberry', a: 'basil', b: 'lemon', d: 'sugar', c: 'ru' },
  { id: 'compote_peach_vanilla', title: 'Нежный компот из спелых персиков с ноткой ванили', m: 'peach', a: 'vanilla_sugar', b: 'lemon', d: 'sugar', c: 'home' },
  { id: 'compote_apricot_lemon', title: 'Солнечный компот из абрикосов с лимонной цедрой и медом', m: 'apricot', a: 'lemon', b: 'honey', d: 'mint', c: 'home' },
  { id: 'compote_pear_ginger_cloves', title: 'Пряный грушевый компот со свежим имбирем и гвоздикой', m: 'pear', a: 'ginger', b: 'cloves', d: 'honey', c: 'home' },
  { id: 'compote_apple_cranberry_honey', title: 'Витаминный компот из яблок с клюквой и душистым медом', m: 'apple', a: 'cranberry', b: 'honey', d: 'cinnamon', c: 'ru' },
  { id: 'compote_blackberry_apple', title: 'Насыщенный осенний компот с ежевикой и сладким яблоком', m: 'blackberry', a: 'apple', b: 'sugar', d: 'lemon', c: 'ru' },
  { id: 'compote_blueberry_lemon_thyme', title: 'Лесной компот из черники с лимоном и веточкой чабреца', m: 'blueberry', a: 'lemon', b: 'thyme', d: 'honey', c: 'ru' },
  { id: 'compote_rhubarb_strawberry', title: 'Весенний кисло-сладкий компот с ревенем и клубникой', m: 'rhubarb', a: 'strawberry', b: 'sugar', d: 'mint', c: 'ru' },
  { id: 'compote_sweet_cherry_lemon', title: 'Сладкий летний компот из черешни с ломтиком лимона', m: 'sweet_cherry', a: 'lemon', b: 'sugar', d: 'vanilla_sugar', c: 'home' },
  { id: 'compote_grape_rosemary', title: 'Душистый осенний компот из темного винограда с розмарином', m: 'grape', a: 'rosemary', b: 'lemon', d: 'honey', c: 'ge' },
  { id: 'compote_pineapple_orange_mint', title: 'Тропический праздничный компот из ананаса и апельсина', m: 'pineapple', a: 'orange', b: 'mint', d: 'sugar', c: 'home' },
  { id: 'compote_mandarin_cloves_cinnamon', title: 'Зимний новогодний компот из мандаринов со специями', m: 'mandarin', a: 'cinnamon', b: 'cloves', d: 'honey', c: 'ru' },
  { id: 'compote_grapefruit_honey_ginger', title: 'Тонизирующий грейпфрутовый компот с медом и имбирем', m: 'grapefruit', a: 'honey', b: 'ginger', d: 'mint', c: 'home' },
  { id: 'compote_watermelon_lime_mint', title: 'Необычный летний компот из мякоти арбуза с лаймом', m: 'watermelon', a: 'lime', b: 'mint', d: 'sugar', c: 'home' },
  { id: 'compote_melon_lemon_cardamom', title: 'Ароматный медовый компот из дыни с кардамоном и лимоном', m: 'melon', a: 'cardamom', b: 'lemon', d: 'honey', c: 'uz' },
  { id: 'uzvar_prunes_dried_apricots', title: 'Украинский традиционный узвар с черносливом, курагой и медом', m: 'prunes', a: 'dried_apricots', b: 'honey', d: 'apple', c: 'ua' },
  { id: 'uzvar_raisins_pear_dried_fruits', title: 'Праздничный рождественский узвар с изюмом и грушей', m: 'raisins', a: 'pear', b: 'dried_fruits', d: 'honey', c: 'ua' },
  { id: 'uzvar_cranberry_dried_fruits', title: 'Насыщенный узвар из сухофруктов с кислой клюквой и корицей', m: 'dried_fruits', a: 'cranberry', b: 'cinnamon', d: 'honey', c: 'ru' },
  { id: 'uzvar_dates_orange_ginger', title: 'Пряный зимний узвар с финиками, апельсином и имбирем', m: 'dates', a: 'orange', b: 'ginger', d: 'cloves', c: 'home' },
  { id: 'uzvar_fig_plum_cardamom', title: 'Восточный сладкий узвар с инжиром, сливой и кардамоном', m: 'fig', a: 'plum', b: 'cardamom', d: 'honey', c: 'tr' },
  { id: 'compote_pomegranate_apple_mint', title: 'Терпкий рубиновый компот с гранатом, яблоками и мятой', m: 'pomegranate', a: 'apple', b: 'mint', d: 'sugar', c: 'az' },
  { id: 'compote_persimmon_orange_cinnamon', title: 'Золотистый зимний компот из хурмы с апельсином и корицей', m: 'persimmon', a: 'orange', b: 'cinnamon', d: 'honey', c: 'home' },
  { id: 'compote_kiwi_apple_lemon', title: 'Легкий зеленый компот из киви с яблоком и лимонной цедрой', m: 'kiwi', a: 'apple', b: 'lemon', d: 'sugar', c: 'home' },
  { id: 'compote_pumpkin_orange_ginger', title: 'Витаминный домашний компот с тыквой, апельсином и имбирем', m: 'squash', a: 'orange', b: 'ginger', d: 'sugar', c: 'home' },
  { id: 'compote_carrot_lemon_raisins', title: 'Сладкий морковно-яблочный компот с изюмом и лимоном', m: 'carrot', a: 'apple', b: 'raisins', d: 'lemon', c: 'ru' }
];

for (const it of compotes) {
  addBeverage({
    id: it.id,
    title: it.title,
    cuisine: it.c,
    time: 25,
    active: 10,
    servings: 6,
    mode: 'hot_pitcher',
    heatSec: 600,
    ings: [{ ingredient_id: 'water', amount: 1500, unit: 'ml' }, it.m, it.a, it.b, it.d]
  });
}

// 2. Morsy, Kissels, Sbiten & Traditional Drinks (25)
const morsyKissels = [
  { id: 'mors_cranberry_orange_honey', title: 'Витаминный клюквенный морс с апельсиновым соком и медом', m: 'cranberry', a: 'orange', b: 'honey', d: 'cinnamon', c: 'ru' },
  { id: 'mors_cranberry_ginger_lemon', title: 'Освежающий клюквенный морс с корнем имбиря и лимоном', m: 'cranberry', a: 'ginger', b: 'lemon', d: 'sugar', c: 'ru' },
  { id: 'mors_currant_black_mint', title: 'Ароматный морс из черной смородины с веточкой мяты', m: 'currant_black', a: 'mint', b: 'sugar', d: 'lemon', c: 'ru' },
  { id: 'mors_currant_red_raspberry', title: 'Яркий двойной ягодный морс из красной смородины и малины', m: 'currant_red', a: 'raspberry', b: 'sugar', d: 'mint', c: 'ru' },
  { id: 'mors_cherry_tarragon', title: 'Душистый вишневый морс с тархуном и ломтиком лимона', m: 'cherry', a: 'tarragon', b: 'lemon', d: 'sugar', c: 'ru' },
  { id: 'mors_blackberry_blueberry', title: 'Спелый лесной морс с ежевикой, черникой и медом', m: 'blackberry', a: 'blueberry', b: 'honey', d: 'lemon', c: 'ru' },
  { id: 'mors_raspberry_lime_basil', title: 'Летний малиновый морс с соком лайма и базиликом', m: 'raspberry', a: 'lime', b: 'basil', d: 'sugar', c: 'ru' },
  { id: 'mors_gooseberry_mint_honey', title: 'Кисло-сладкий морс из спелого крыжовника с медом', m: 'gooseberry', a: 'mint', b: 'honey', d: 'lemon', c: 'ru' },
  { id: 'kissel_cranberry_classic', title: 'Домашний бархатистый клюквенный кисель на крахмале', m: 'cranberry', a: 'starch', b: 'sugar', d: 'lemon', c: 'ru' },
  { id: 'kissel_cherry_cinnamon', title: 'Домашний вишнево-яблочный кисель с легкой ноткой гвоздики', m: 'cherry', a: 'apple', b: 'starch', d: 'cloves', c: 'ru' },
  { id: 'kissel_oatmeal_russian_traditional', title: 'Полезный старинный русский овсяный кисель с медом', m: 'oatmeal', a: 'honey', b: 'salt', d: 'butter', c: 'ru' },
  { id: 'kissel_currant_black_berry', title: 'Согревающий густой кисель из черной смородины и яблок', m: 'currant_black', a: 'apple', b: 'starch', d: 'sugar', c: 'ru' },
  { id: 'kissel_strawberry_milk_sweet', title: 'Нежный молочно-клубничный кисель для семейного полдника', m: 'milk', a: 'strawberry', b: 'starch', d: 'vanilla_sugar', c: 'ru' },
  { id: 'kissel_rhubarb_apple_honey', title: 'Освежающий весенний кисель с ревенем, яблоком и медом', m: 'rhubarb', a: 'apple', b: 'starch', d: 'honey', c: 'ru' },
  { id: 'kissel_plum_cardamom', title: 'Ароматный сливовый кисель с кардамоном для уюта', m: 'plum', a: 'cardamom', b: 'starch', d: 'sugar', c: 'ru' },
  { id: 'sbiten_classic_honey_spices', title: 'Старорусский пряный медовый сбитень с имбирем и гвоздикой', m: 'honey', a: 'ginger', b: 'cinnamon', d: 'cloves', c: 'ru' },
  { id: 'sbiten_cranberry_thyme', title: 'Согревающий клюквенный сбитень с чабрецом и медом', m: 'cranberry', a: 'honey', b: 'thyme', d: 'cardamom', c: 'ru' },
  { id: 'sbiten_orange_bay_leaf', title: 'Ароматный цитрусовый сбитень с апельсином, лавром и медом', m: 'orange', a: 'honey', b: 'bay_leaf', d: 'cinnamon', c: 'ru' },
  { id: 'sbiten_cherry_mint_coriander', title: 'Вишневый русский сбитень с мятой и пряным кориандром', m: 'cherry', a: 'honey', b: 'mint', d: 'coriander', c: 'ru' },
  { id: 'kvass_rye_bread_raisins', title: 'Освежающий домашний напиток из черного хлеба с изюмом', m: 'black_bread', a: 'raisins', b: 'yeast', d: 'sugar', c: 'ru', mode: 'cold' },
  { id: 'kvass_mint_apple_rye', title: 'Летний бодрящий хлебный напиток с мятой и яблоками', m: 'black_bread', a: 'mint', b: 'apple', d: 'yeast', c: 'ru', mode: 'cold' },
  { id: 'kvass_beet_garlic_savory', title: 'Традиционный свекольный напиток на закваске из черного хлеба', m: 'beet', a: 'black_bread', b: 'sugar', d: 'lemon', c: 'ua', mode: 'cold' },
  { id: 'whey_mint_cucumber_cooler', title: 'Летний тонизирующий напиток на сыворотке с огурцом и мятой', m: 'whey', a: 'cucumber', b: 'mint', d: 'lemon', c: 'ru', mode: 'cold' },
  { id: 'whey_berry_jam_refreshing', title: 'Витаминный напиток из сыворотки с домашним ягодным вареньем', m: 'whey', a: 'jam', b: 'lemon', d: 'mint', c: 'ru', mode: 'cold' },
  { id: 'jam_warm_lemon_water_tea', title: 'Уютный согревающий напиток из малинового варенья с лимоном', m: 'jam', a: 'raspberry', b: 'lemon', d: 'mint', c: 'ru' }
];

for (const it of morsyKissels) {
  addBeverage({
    id: it.id,
    title: it.title,
    cuisine: it.c,
    time: 20,
    active: 10,
    servings: 4,
    mode: it.mode || 'hot_pitcher',
    heatSec: it.mode === 'cold' ? 0 : 480,
    verb: 'проварите на слабом огне, помешивая,',
    ings: [{ ingredient_id: 'water', amount: 1000, unit: 'ml' }, it.m, it.a, it.b, it.d]
  });
}

// 3. Spiced Warm Milks, Herbal Infusions & Hot Chocolates (30)
const warmDrinks = [
  { id: 'tea_orange_cinnamon_cloves', title: 'Пряный зимний напиток с апельсином, корицей и гвоздикой', m: 'orange', a: 'cinnamon', b: 'cloves', d: 'honey', c: 'home', base: 'water' },
  { id: 'tea_raspberry_lemon_mint', title: 'Домашний малиновый настой с лимоном, медом и мятой', m: 'raspberry', a: 'lemon', b: 'mint', d: 'honey', c: 'ru', base: 'water' },
  { id: 'tea_currant_black_thyme', title: 'Ароматный ягодный напиток из черной смородины с чабрецом', m: 'currant_black', a: 'thyme', b: 'honey', d: 'lemon', c: 'ru', base: 'water' },
  { id: 'tea_pear_rosemary_honey', title: 'Согревающий грушевый чай с веточкой розмарина и медом', m: 'pear', a: 'rosemary', b: 'honey', d: 'lemon', c: 'home', base: 'water' },
  { id: 'tea_apple_ginger_cardamom', title: 'Бодрящий яблочно-имбирный настой с кардамоном и корицей', m: 'apple', a: 'ginger', b: 'cardamom', d: 'cinnamon', c: 'home', base: 'water' },
  { id: 'tea_cranberry_orange_ginger', title: 'Яркий витаминный напиток с клюквой, апельсином и имбирем', m: 'cranberry', a: 'orange', b: 'ginger', d: 'honey', c: 'ru', base: 'water' },
  { id: 'tea_blackberry_tarragon_lime', title: 'Необычный душистый настой с ежевикой, тархуном и лаймом', m: 'blackberry', a: 'tarragon', b: 'lime', d: 'honey', c: 'ge', base: 'water' },
  { id: 'tea_grapefruit_rosemary_honey', title: 'Тонизирующий теплый напиток из грейпфрута с розмарином', m: 'grapefruit', a: 'rosemary', b: 'honey', d: 'ginger', c: 'home', base: 'water' },
  { id: 'tea_mandarin_ginger_mint', title: 'Новогодний мандариновый чай со свежим имбирем и мятой', m: 'mandarin', a: 'ginger', b: 'mint', d: 'honey', c: 'ru', base: 'water' },
  { id: 'tea_pomegranate_mint_lemon', title: 'Рубиновый согревающий настой с гранатом, лимоном и мятой', m: 'pomegranate', a: 'mint', b: 'lemon', d: 'honey', c: 'tr', base: 'water' },
  { id: 'tea_nettle_lemon_honey', title: 'Весенний витаминный травяной отвар из крапивы с лимоном', m: 'nettle', a: 'lemon', b: 'honey', d: 'mint', c: 'ru', base: 'water' },
  { id: 'tea_thyme_mint_oregano', title: 'Уютный душистый травяной сбор из чабреца, мяты и орегано', m: 'thyme', a: 'mint', b: 'oregano', d: 'honey', c: 'ru', base: 'water' },
  { id: 'golden_milk_turmeric_ginger', title: 'Золотое пряное молоко с куркумой, имбирем и медом', m: 'turmeric', a: 'ginger', b: 'honey', d: 'cinnamon', c: 'in', base: 'milk' },
  { id: 'golden_milk_coconut_cardamom', title: 'Веганское золотое кокосовое молоко с куркумой и кардамоном', m: 'turmeric', a: 'cardamom', b: 'syrup', d: 'cinnamon', c: 'in', base: 'coconut_milk' },
  { id: 'masala_milk_spiced_indian', title: 'Индийское пряное молоко со специями кардамоном и гвоздикой', m: 'cardamom', a: 'cloves', b: 'ginger', d: 'honey', c: 'in', base: 'milk' },
  { id: 'bedtime_milk_butter_honey', title: 'Теплое домашнее молоко на ночь со сливочным маслом и медом', m: 'honey', a: 'butter', b: 'vanilla_sugar', d: 'nutmeg', c: 'ru', base: 'milk' },
  { id: 'bedtime_milk_fig_honey', title: 'Полезное теплое молоко, томленое с инжиром и медом', m: 'fig', a: 'honey', b: 'cinnamon', d: 'butter', c: 'ru', base: 'milk' },
  { id: 'bedtime_milk_garlic_honey', title: 'Согревающее народное молоко с чесноком, медом и маслом', m: 'garlic', a: 'honey', b: 'butter', d: 'turmeric', c: 'ru', base: 'milk' },
  { id: 'cocoa_marshmallow_cinnamon', title: 'Уютное горячее какао на молоке с зефиром и корицей', m: 'cocoa', a: 'marshmallow', b: 'cinnamon', d: 'sugar', c: 'us', base: 'milk' },
  { id: 'cocoa_spiced_chili_mexican', title: 'Мексиканский пряный шоколадный напиток с щепоткой острого перца', m: 'cocoa', a: 'chocolate', b: 'red_pepper', d: 'cinnamon', c: 'mx', base: 'milk' },
  { id: 'cocoa_orange_cardamom', title: 'Ароматное какао с апельсиновой цедрой и кардамоном', m: 'cocoa', a: 'orange', b: 'cardamom', d: 'honey', c: 'home', base: 'milk' },
  { id: 'cocoa_coconut_milk_dark', title: 'Насыщенное какао на кокосовом молоке с темным шоколадом', m: 'cocoa', a: 'chocolate', b: 'coconut_flakes', d: 'syrup', c: 'home', base: 'coconut_milk' },
  { id: 'cocoa_peanut_caramel_warm', title: 'Сладкий согревающий напиток какао с арахисом и карамелью', m: 'cocoa', a: 'peanut', b: 'caramel', d: 'vanilla', c: 'us', base: 'milk' },
  { id: 'cocoa_mint_cream_french', title: 'Нежное мятное какао со сливками и тертым шоколадом', m: 'cocoa', a: 'mint', b: 'cream', d: 'chocolate', c: 'fr', base: 'milk' },
  { id: 'hot_chocolate_italian_thick', title: 'Густой итальянский горячий шоколад на сливках с крахмалом', m: 'chocolate', a: 'cream', b: 'starch', d: 'vanilla_sugar', c: 'it', base: 'milk' },
  { id: 'hot_chocolate_halva_sesame', title: 'Необычный горячий шоколад с халвой и ванилью', m: 'chocolate', a: 'halva', b: 'cream', d: 'vanilla', c: 'tr', base: 'milk' },
  { id: 'caramel_warm_milk_vanilla', title: 'Теплое карамельное молоко с ванилью и мускатным орехом', m: 'caramel', a: 'vanilla', b: 'nutmeg', d: 'cream', c: 'fr', base: 'milk' },
  { id: 'banana_warm_cocoa_nutmeg', title: 'Питательный теплый бананово-шоколадный напиток перед сном', m: 'banana', a: 'cocoa', b: 'nutmeg', d: 'honey', c: 'home', base: 'milk' },
  { id: 'pumpkin_spice_milk_latte', title: 'Осенний согревающий тыквенный напиток на молоке со специями', m: 'squash', a: 'cinnamon', b: 'ginger', d: 'nutmeg', c: 'us', base: 'milk' },
  { id: 'condensed_milk_cocoa_nut', title: 'Сладкий домашний шоколадный напиток со сгущенкой и миндалем', m: 'condensed_milk', a: 'cocoa', b: 'almond', d: 'vanilla', c: 'home', base: 'milk' }
];

for (const it of warmDrinks) {
  addBeverage({
    id: it.id,
    title: it.title,
    cuisine: it.c,
    time: 15,
    active: 10,
    servings: 2,
    mode: 'hot_mug',
    heatSec: 300,
    ings: [{ ingredient_id: it.base, amount: 400, unit: 'ml' }, it.m, it.a, it.b, it.d]
  });
}

// 4. Smoothies & Healthy Shakes (30)
const smoothies = [
  { id: 'smoothie_strawberry_banana_yogurt', title: 'Классический клубнично-банановый смузи на питьевом йогурте', m: 'strawberry', a: 'banana', b: 'honey', d: 'mint', c: 'home', base: 'yogurt' },
  { id: 'smoothie_raspberry_kefir_oats', title: 'Сытный утренний малиновый смузи на кефире с овсянкой', m: 'raspberry', a: 'oatmeal', b: 'honey', d: 'vanilla_sugar', c: 'ru', base: 'kefir' },
  { id: 'smoothie_blueberry_spinach_banana', title: 'Яркий витаминный смузи со шпинатом, голубикой и бананом', m: 'blueberry', a: 'spinach', b: 'banana', d: 'lemon', c: 'home', base: 'yogurt' },
  { id: 'smoothie_avocado_kiwi_lime', title: 'Зеленый шелковистый смузи со спелым авокадо, зеленым киви и соком лайма', m: 'avocado', a: 'kiwi', b: 'lime', d: 'honey', c: 'home', base: 'water' },
  { id: 'smoothie_apple_celery_parsley', title: 'Бодрящий зеленый смузи из яблока, сельдерея и петрушки', m: 'apple', a: 'celery', b: 'parsley', d: 'lemon', c: 'home', base: 'water' },
  { id: 'smoothie_cucumber_dill_kefir', title: 'Легкий зеленый смузи на кефире с огурцом, укропом и чесноком', m: 'cucumber', a: 'dill', b: 'garlic', d: 'salt', c: 'ru', base: 'kefir' },
  { id: 'smoothie_tomato_celery_basil', title: 'Овощной пикантный смузи из томатов, сельдерея и базилика', m: 'tomato', a: 'celery', b: 'basil', d: 'lemon', c: 'it', base: 'water' },
  { id: 'smoothie_carrot_orange_ginger', title: 'Оранжевый витаминный смузи с морковью, апельсином и имбирем', m: 'carrot', a: 'orange', b: 'ginger', d: 'honey', c: 'home', base: 'water' },
  { id: 'smoothie_beet_apple_ginger', title: 'Тонизирующий свекольно-яблочный смузи с лимоном и имбирем', m: 'beet', a: 'apple', b: 'lemon', d: 'ginger', c: 'home', base: 'water' },
  { id: 'smoothie_pumpkin_banana_cinnamon', title: 'Нежный тыквенно-банановый смузи на молоке с корицей', m: 'squash', a: 'banana', b: 'cinnamon', d: 'honey', c: 'us', base: 'milk' },
  { id: 'smoothie_persimmon_orange_yogurt', title: 'Бархатный зимний смузи из хурмы и апельсина на йогурте', m: 'persimmon', a: 'orange', b: 'yogurt', d: 'cinnamon', c: 'home', base: 'milk' },
  { id: 'smoothie_watermelon_strawberry_mint', title: 'Охлажденный летний смузи из арбуза, клубники и мяты', m: 'watermelon', a: 'strawberry', b: 'mint', d: 'lime', c: 'home', base: 'water' },
  { id: 'smoothie_melon_peach_yogurt', title: 'Солнечный летний смузи из спелой дыни и персика', m: 'melon', a: 'peach', b: 'honey', d: 'mint', c: 'home', base: 'yogurt' },
  { id: 'smoothie_pineapple_coconut_lime', title: 'Тропический пина-колада смузи с ананасом и кокосом', m: 'pineapple', a: 'coconut_flakes', b: 'lime', d: 'banana', c: 'th', base: 'coconut_milk' },
  { id: 'smoothie_kiwi_grape_spinach', title: 'Освежающий фруктовый смузи из спелого киви со сладким виноградом и шпинатом', m: 'kiwi', a: 'grape', b: 'spinach', d: 'mint', c: 'home', base: 'water' },
  { id: 'smoothie_pear_oatmeal_cinnamon', title: 'Питательный грушевый смузи с хлопьями, корицей и медом', m: 'pear', a: 'rolled_oats', b: 'cinnamon', d: 'honey', c: 'home', base: 'milk' },
  { id: 'smoothie_cottage_peach_milk', title: 'Белковый творожный коктейль со спелым персиком и медом', m: 'cottage_cheese', a: 'peach', b: 'honey', d: 'vanilla', c: 'home', base: 'milk' },
  { id: 'smoothie_kefir_prunes_walnut', title: 'Полезный смузи на кефире с черносливом, хлопьями и орехом', m: 'prunes', a: 'rolled_oats', b: 'walnut', d: 'cinnamon', c: 'ru', base: 'kefir' },
  { id: 'smoothie_avocado_cucumber_yogurt', title: 'Кремовый детокс-смузи с авокадо, огурцом и лимоном', m: 'avocado', a: 'cucumber', b: 'lemon', d: 'mint', c: 'home', base: 'yogurt' },
  { id: 'smoothie_blackberry_currant_buttermilk', title: 'Ягодный смузи на пахте с ежевикой и черной смородиной', m: 'blackberry', a: 'currant_black', b: 'honey', d: 'banana', c: 'home', base: 'buttermilk' },
  { id: 'smoothie_curdled_milk_strawberry_oats', title: 'Густой смузи на ряженке со свежей клубникой и овсянкой', m: 'curdled_milk', a: 'strawberry', b: 'rolled_oats', d: 'honey', c: 'ru', base: 'milk' },
  { id: 'smoothie_banana_dates_almond', title: 'Сладкий смузи без сахара из банана с финиками и миндалем', m: 'banana', a: 'dates', b: 'almond', d: 'cinnamon', c: 'home', base: 'milk' },
  { id: 'smoothie_apricot_banana_yogurt', title: 'Летний абрикосово-банановый смузи с лимонным соком', m: 'apricot', a: 'banana', b: 'lemon', d: 'honey', c: 'home', base: 'yogurt' },
  { id: 'smoothie_cherry_chocolate_coconut', title: 'Десертный вишнево-шоколадный смузи на кокосовом молоке', m: 'cherry', a: 'cocoa', b: 'banana', d: 'coconut_flakes', c: 'home', base: 'coconut_milk' },
  { id: 'smoothie_melon_kiwi_mint', title: 'Ароматный зеленый смузи из дыни и киви с мятой', m: 'melon', a: 'kiwi', b: 'mint', d: 'lime', c: 'home', base: 'water' },
  { id: 'smoothie_plum_apple_cinnamon', title: 'Осенний бархатный смузи из спелых слив, яблок и йогурта', m: 'plum', a: 'apple', b: 'cinnamon', d: 'honey', c: 'home', base: 'yogurt' },
  { id: 'smoothie_carrot_apple_turmeric', title: 'Золотой утренний смузи из моркови и яблок с куркумой', m: 'carrot', a: 'apple', b: 'turmeric', d: 'lemon', c: 'home', base: 'water' },
  { id: 'smoothie_currant_red_banana_milk', title: 'Яркий кисло-сладкий смузи из красной смородины и банана', m: 'currant_red', a: 'banana', b: 'honey', d: 'vanilla', c: 'ru', base: 'milk' },
  { id: 'smoothie_fig_banana_cinnamon', title: 'Питательный смузи из спелого инжира, банана и корицы', m: 'fig', a: 'banana', b: 'cinnamon', d: 'honey', c: 'home', base: 'milk' },
  { id: 'smoothie_peanut_banana_cocoa', title: 'Сытный овсяно-финиковый коктейль с арахисом и бананом', m: 'peanut', a: 'banana', b: 'rolled_oats', d: 'dates', c: 'us', base: 'milk' }
];

for (const it of smoothies) {
  addBeverage({
    id: it.id,
    title: it.title,
    cuisine: it.c,
    time: 10,
    active: 10,
    servings: 2,
    mode: 'blend',
    ings: [{ ingredient_id: it.base, amount: 300, unit: 'ml' }, it.m, it.a, it.b, it.d]
  });
}

// 5. Lemonades, Lassi, Ayran & Milkshakes (25)
const lemonadesMilkshakes = [
  { id: 'lemonade_tarragon_lime_classic', title: 'Домашний изумрудный лимонад Тархун с эстрагоном и лаймом', m: 'tarragon', a: 'lime', b: 'lemon', d: 'sugar', c: 'ge', base: 'water', mode: 'cold' },
  { id: 'lemonade_classic_lemon_mint', title: 'Освежающий классический лимонад из свежих лимонов с мятой', m: 'lemon', a: 'mint', b: 'sugar', d: 'cucumber', c: 'home', base: 'water', mode: 'cold' },
  { id: 'lemonade_ginger_lemon_honey', title: 'Пряный тонизирующий имбирный лимонад с лаймом, апельсином и мятой', m: 'ginger', a: 'lemon', b: 'orange', d: 'mint', c: 'home', base: 'water', mode: 'cold' },
  { id: 'lemonade_strawberry_basil_lime', title: 'Ароматный летний лимонад из клубники с зеленым базиликом', m: 'strawberry', a: 'basil', b: 'lime', d: 'sugar', c: 'home', base: 'water', mode: 'cold' },
  { id: 'lemonade_cucumber_mint_lime', title: 'Свежий огуречный лимонад с соком лайма и мятой', m: 'cucumber', a: 'lime', b: 'mint', d: 'honey', c: 'home', base: 'water', mode: 'cold' },
  { id: 'lemonade_watermelon_basil_lemon', title: 'Летний прохладный арбузный лимонад с лимоном и базиликом', m: 'watermelon', a: 'lemon', b: 'basil', d: 'sugar', c: 'home', base: 'water', mode: 'cold' },
  { id: 'lemonade_grapefruit_rosemary', title: 'Бодрящий цитрусовый лимонад из грейпфрута с розмарином', m: 'grapefruit', a: 'rosemary', b: 'lemon', d: 'honey', c: 'home', base: 'water', mode: 'cold' },
  { id: 'lemonade_orange_cranberry_mint', title: 'Яркий апельсиново-клюквенный лимонад для праздничного стола', m: 'orange', a: 'cranberry', b: 'mint', d: 'sugar', c: 'home', base: 'water', mode: 'cold' },
  { id: 'lemonade_cherry_thyme_lemon', title: 'Охлажденный вишневый лимонад с веточкой чабреца и лимоном', m: 'cherry', a: 'thyme', b: 'lemon', d: 'sugar', c: 'home', base: 'water', mode: 'cold' },
  { id: 'lemonade_peach_lemon_mint', title: 'Нежный летний персиковый лимонад с лимонным соком', m: 'peach', a: 'lemon', b: 'mint', d: 'honey', c: 'home', base: 'water', mode: 'cold' },
  { id: 'lassi_apricot_cardamom_yogurt', title: 'Индийский прохладный ласси с абрикосом, йогуртом и кардамоном', m: 'apricot', a: 'cardamom', b: 'honey', d: 'mint', c: 'in', base: 'yogurt', mode: 'blend' },
  { id: 'lassi_strawberry_mint_yogurt', title: 'Освежающий клубничный ласси на натуральном йогурте с мятой', m: 'strawberry', a: 'mint', b: 'honey', d: 'lime', c: 'in', base: 'yogurt', mode: 'blend' },
  { id: 'ayran_cucumber_dill_mint', title: 'Турецкий соленый айран со свежим огурцом, укропом и мятой', m: 'cucumber', a: 'dill', b: 'mint', d: 'salt', c: 'tr', base: 'yogurt', mode: 'blend' },
  { id: 'tan_kefir_greens_garlic', title: 'Кавказский освежающий тан на кефире с зеленью и укропом', m: 'dill', a: 'cilantro', b: 'salt', d: 'cucumber', c: 'ge', base: 'kefir', mode: 'blend' },
  { id: 'milkshake_vanilla_ice_cream_classic', title: 'Классический сливочный молочный коктейль с пломбиром и ванилью', m: 'ice_cream', a: 'vanilla_sugar', b: 'cream', d: 'banana', c: 'us', base: 'milk', mode: 'blend' },
  { id: 'milkshake_chocolate_banana_ice', title: 'Густой шоколадный молочный коктейль с бананом и мороженым', m: 'ice_cream', a: 'chocolate', b: 'cocoa', d: 'banana', c: 'us', base: 'milk', mode: 'blend' },
  { id: 'milkshake_strawberry_ice_cream', title: 'Нежный клубничный молочный коктейль как в детстве', m: 'ice_cream', a: 'strawberry', b: 'vanilla', d: 'cream', c: 'ru', base: 'milk', mode: 'blend' },
  { id: 'milkshake_caramel_halva_ice', title: 'Сладкий восточный молочный коктейль с халвой и пломбиром', m: 'ice_cream', a: 'halva', b: 'caramel', d: 'walnut', c: 'tr', base: 'milk', mode: 'blend' },
  { id: 'milkshake_cherry_cocoa_ice', title: 'Вишневый молочный коктейль с шоколадной ноткой и мороженым', m: 'ice_cream', a: 'cherry', b: 'cocoa', d: 'vanilla', c: 'home', base: 'milk', mode: 'blend' },
  { id: 'milkshake_pistachio_ice_cream', title: 'Изысканный фисташковый молочный коктейль с пломбиром', m: 'ice_cream', a: 'pistachio', b: 'cream', d: 'honey', c: 'it', base: 'milk', mode: 'blend' },
  { id: 'milkshake_melon_vanilla_ice', title: 'Ароматный дынный молочный коктейль со сливочным мороженым', m: 'ice_cream', a: 'melon', b: 'vanilla_sugar', d: 'mint', c: 'home', base: 'milk', mode: 'blend' },
  { id: 'juice_pomegranate_grape_lemon', title: 'Витаминный микс соков из граната, винограда и лимона', m: 'pomegranate', a: 'grape', b: 'lemon', d: 'mint', c: 'ge', base: 'water', mode: 'cold' },
  { id: 'tomato_celery_horseradish_mocktail', title: 'Острый томатный напиток с хреном, сельдереем и лимоном', m: 'tomato', a: 'horseradish', b: 'celery', d: 'lemon', c: 'home', base: 'water', mode: 'cold' },
  { id: 'beet_kefir_dill_cold_tonic', title: 'Полезный прохладный кефирно-свекольный напиток с укропом', m: 'beet', a: 'dill', b: 'cucumber', d: 'salt', c: 'ru', base: 'kefir', mode: 'blend' },
  { id: 'lemonade_mandarin_rosemary_fizzy', title: 'Зимний мандариновый лимонад с розмарином и капелькой меда', m: 'mandarin', a: 'rosemary', b: 'honey', d: 'lemon', c: 'home', base: 'water', mode: 'cold' }
];

for (const it of lemonadesMilkshakes) {
  addBeverage({
    id: it.id,
    title: it.title,
    cuisine: it.c,
    time: 10,
    active: 10,
    servings: it.mode === 'blend' ? 2 : 4,
    mode: it.mode,
    ings: [{ ingredient_id: it.base, amount: it.mode === 'blend' ? 300 : 800, unit: 'ml' }, it.m, it.a, it.b, it.d]
  });
}

console.log(`Total generated beverages: ${allBeverages.length}`);
saveAndValidateGroup('beverages.json', allBeverages);
