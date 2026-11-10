const { saveAndValidateGroup, smartIngredient } = require('./recipe_builder');

function s(text, timer_seconds, tip) {
  const step = { text: text.trim() };
  if (timer_seconds) step.timer_seconds = timer_seconds;
  if (tip) step.tip = tip;
  return step;
}

const allPreserves = [];

function addPreserve(def) {
  const id = `pres_${def.id}`;
  const title = def.title;
  const time = def.time || 90;
  const active = def.active || 30;
  const servings = def.servings || 10; // large jar — per_serving limits stay safe
  const cuisine = def.cuisine || 'ru';
  const desc = def.desc || `Домашняя заготовка «${title}» на зиму — натуральный вкус без лишних добавок.`;

  const ingsMap = new Map();
  for (const raw of def.ings) {
    const rawId = raw.ingredient_id || raw.id || raw;
    const ingObj = smartIngredient(rawId, raw.amount, raw.unit);
    ingsMap.set(rawId, ingObj);
  }
  const ings = Array.from(ingsMap.values());

  const heatSec = def.heatSec || 1800;
  const heatMin = Math.ceil(heatSec / 60);
  const verb = def.verb || 'варите на слабом огне, помешивая,';

  const steps = def.steps || [
    s(`Для заготовки «${title}» тщательно вымойте и подготовьте основные компоненты, измельчите или оставьте целыми по рецепту.`),
    s(`Уложите подготовленные ингредиенты для «${title}» в кастрюлю или банку, добавьте специи и жидкость по рецепту.`),
    s(`${verb.charAt(0).toUpperCase() + verb.slice(1)} заготовку «${title}» в течение ${heatMin} минут до нужной консистенции и готовности.`, heatSec),
    s(`Разложите горячую «${title}» по стерилизованным банкам, закатайте крышками, переверните и укутайте до остывания.`)
  ];

  allPreserves.push({
    id: id,
    title: title,
    dish_type: 'preserve',
    dish_group: 'preserves',
    cuisine: cuisine,
    total_minutes: Math.max(time, heatMin + 20),
    active_minutes: active,
    servings: servings,
    description: desc,
    ingredients: ings,
    steps: steps
  });
}

// 1. Jams, Confiturs & Fruit Pastes (40)
const jams = [
  { id: 'jam_strawberry_lemon_classic', title: 'Классическое ароматное клубничное варенье с лимоном', m: 'strawberry', a: 'lemon', b: 'sugar', d: 'water', heatSec: 2400 },
  { id: 'jam_raspberry_whole_berry', title: 'Нежное малиновое варенье пятиминутка с целыми ягодами', m: 'raspberry', a: 'sugar', b: 'lemon', d: 'water', heatSec: 900 },
  { id: 'jam_cherry_pitted_dark', title: 'Насыщенное домашнее варенье из темной вишни без косточек', m: 'cherry', a: 'sugar', b: 'water', d: 'lemon', heatSec: 2400 },
  { id: 'jam_sweet_cherry_vanilla', title: 'Нежное черешневое варенье с ванилью и апельсиновой кислинкой', m: 'sweet_cherry', a: 'sugar', b: 'vanilla_sugar', d: 'orange', heatSec: 2400 },
  { id: 'jam_currant_black_classic', title: 'Классическое ароматное варенье из черной смородины', m: 'currant_black', a: 'sugar', b: 'water', d: 'lemon', heatSec: 1800 },
  { id: 'jam_currant_red_gel', title: 'Яркое желе-варенье из красной смородины без варки ягод', m: 'currant_red', a: 'sugar', b: 'water', d: 'lemon', heatSec: 1200 },
  { id: 'jam_gooseberry_emerald', title: 'Изумрудное варенье из крыжовника с вишневым листом', m: 'gooseberry', a: 'sugar', b: 'water', d: 'lemon', heatSec: 2400 },
  { id: 'jam_blueberry_cardamom', title: 'Черничное варенье с кардамоном и лимонной цедрой', m: 'blueberry', a: 'cardamom', b: 'sugar', d: 'lemon', heatSec: 1800 },
  { id: 'jam_cranberry_orange_confit', title: 'Клюквенный конфитюр с апельсиновой цедрой и корицей', m: 'cranberry', a: 'orange', b: 'cinnamon', d: 'sugar', heatSec: 1800 },
  { id: 'jam_blackberry_plum_spiced', title: 'Терпкое варенье из ежевики и сливы с душистыми специями', m: 'blackberry', a: 'plum', b: 'cinnamon', d: 'sugar', heatSec: 2400 },
  { id: 'jam_apple_cinnamon_cloves', title: 'Ароматное яблочное повидло с корицей и гвоздикой', m: 'apple', a: 'cinnamon', b: 'cloves', d: 'sugar', verb: 'варите уваривая до густоты', heatSec: 3600 },
  { id: 'jam_pear_vanilla_cardamom', title: 'Нежное грушевое варенье дольками с ванилью и кардамоном', m: 'pear', a: 'vanilla_sugar', b: 'cardamom', d: 'sugar', heatSec: 2400 },
  { id: 'jam_apricot_kernel_classic', title: 'Классическое янтарное абрикосовое варенье дольками', m: 'apricot', a: 'sugar', b: 'water', d: 'lemon', heatSec: 2400 },
  { id: 'jam_peach_ginger_lemon', title: 'Летнее персиковое варенье с имбирем и лимонной цедрой', m: 'peach', a: 'ginger', b: 'lemon', d: 'sugar', heatSec: 2400 },
  { id: 'jam_plum_spiced_hungarian', title: 'Густое сливовое повидло с гвоздикой и анисом по-венгерски', m: 'plum', a: 'cloves', b: 'cardamom', d: 'sugar', verb: 'варите уваривая', heatSec: 3600 },
  { id: 'jam_cherry_apple_confit', title: 'Пикантный вишнево-яблочный конфитюр с анисовыми нотками', m: 'cherry', a: 'apple', b: 'cardamom', d: 'sugar', heatSec: 2400 },
  { id: 'jam_watermelon_rind_classic', title: 'Редкое прозрачное варенье из арбузных корок с лимоном', m: 'watermelon', a: 'sugar', b: 'lemon', d: 'water', heatSec: 3600 },
  { id: 'jam_fig_lemon_vanilla', title: 'Изысканное инжирное варенье с лимоном и натуральной ванилью', m: 'fig', a: 'lemon', b: 'vanilla_sugar', d: 'sugar', heatSec: 2400 },
  { id: 'jam_dates_cardamom_lemon', title: 'Восточный финиковый джем с кардамоном и цедрой лимона', m: 'dates', a: 'cardamom', b: 'lemon', d: 'sugar', heatSec: 1800 },
  { id: 'jam_grape_dark_lemon', title: 'Густое виноградное варенье из темного сорта с лимоном', m: 'grape', a: 'sugar', b: 'lemon', d: 'water', heatSec: 2400 },
  { id: 'jam_quince_spice_amber', title: 'Янтарное айвовое варенье с корицей и анисовыми нотками', m: 'pear', a: 'cinnamon', b: 'sugar', d: 'lemon', heatSec: 3600 },
  { id: 'jam_rhubarb_strawberry_confit', title: 'Кисло-сладкий конфитюр с ревенем и клубникой на пектине', m: 'rhubarb', a: 'strawberry', b: 'sugar', d: 'lemon', heatSec: 1800 },
  { id: 'jam_cranberry_walnut_honey', title: 'Пряное клюквенное варенье с грецким орехом и медом', m: 'cranberry', a: 'walnut', b: 'honey', d: 'sugar', heatSec: 1800 },
  { id: 'jam_pumpkin_orange_cinnamon', title: 'Солнечный тыквенный джем с апельсином и корицей', m: 'squash', a: 'orange', b: 'cinnamon', d: 'sugar', heatSec: 2400 },
  { id: 'jam_carrot_lemon_ginger', title: 'Яркий морковный мармелад с лимоном и свежим имбирем', m: 'carrot', a: 'lemon', b: 'ginger', d: 'sugar', heatSec: 2400 },
  { id: 'jam_beet_citrus_spice', title: 'Редкое свекольное варенье с апельсином и гвоздикой', m: 'beet', a: 'orange', b: 'cloves', d: 'sugar', heatSec: 3600 },
  { id: 'jam_onion_caramel_balsamic', title: 'Карамелизованный луковый конфитюр с уксусом и розмарином', m: 'onion', a: 'apple_vinegar', b: 'rosemary', d: 'sugar', heatSec: 2400, cuisine: 'fr' },
  { id: 'jam_cranberry_apple_pectin', title: 'Клюквенно-яблочное желе на натуральном пектине без сахара', m: 'cranberry', a: 'apple', b: 'lemon', d: 'honey', heatSec: 1800 },
  { id: 'jam_peach_raspberry_confit', title: 'Нежный летний конфитюр из персиков и малины с лимоном', m: 'peach', a: 'raspberry', b: 'lemon', d: 'sugar', heatSec: 1800 },
  { id: 'jam_plum_walnut_chocolate', title: 'Шоколадно-сливовое варенье с грецким орехом к блинам', m: 'plum', a: 'walnut', b: 'chocolate', d: 'sugar', heatSec: 2400 },
  { id: 'jam_pear_chocolate_spiced', title: 'Пряный грушево-шоколадный джем с корицей и гвоздикой', m: 'pear', a: 'chocolate', b: 'cinnamon', d: 'sugar', heatSec: 2400 },
  { id: 'jam_apricot_almond_vanilla', title: 'Деликатесное абрикосовое варенье с миндалем и ванилью', m: 'apricot', a: 'almond', b: 'vanilla_sugar', d: 'sugar', heatSec: 2400 },
  { id: 'jam_blueberry_lemon_thyme', title: 'Черничный конфитюр с лимоном и веточкой свежего чабреца', m: 'blueberry', a: 'lemon', b: 'thyme', d: 'sugar', heatSec: 1800 },
  { id: 'jam_strawberry_basil_confit', title: 'Итальянский клубничный конфитюр с бадьяном и апельсином', m: 'strawberry', a: 'orange', b: 'cloves', d: 'sugar', heatSec: 1800, cuisine: 'it' },
  { id: 'jam_apple_quince_honey', title: 'Яблочно-медовое повидло с изюмом и корицей на зиму', m: 'apple', a: 'raisins', b: 'honey', d: 'cinnamon', verb: 'варите до густоты', heatSec: 3600 },
  { id: 'jam_cherry_cocoa_liqueur', title: 'Оригинальное вишневое варенье с какао и кофейным ароматом', m: 'cherry', a: 'cocoa', b: 'sugar', d: 'cinnamon', heatSec: 2400 },
  { id: 'jam_currant_red_raspberry_mint', title: 'Пикантное ягодное желе с красной смородиной и мятой', m: 'currant_red', a: 'mint', b: 'blueberry', d: 'sugar', heatSec: 1800 },
  { id: 'jam_peach_vanilla_saffron', title: 'Утонченное персиковое варенье с ванилью и кардамоном', m: 'peach', a: 'vanilla_sugar', b: 'cardamom', d: 'sugar', heatSec: 2400 },
  { id: 'jam_greengage_plum_spice', title: 'Прозрачное сливовое желе с кориандром и лимонной цедрой', m: 'plum', a: 'coriander', b: 'lemon', d: 'sugar', heatSec: 2400 },
  { id: 'jam_blackberry_apple_rum', title: 'Зимнее ежевично-яблочное варенье с гвоздикой и кардамоном', m: 'blackberry', a: 'apple', b: 'cloves', d: 'cardamom', heatSec: 2400 }
];

for (const it of jams) {
  addPreserve({
    id: it.id,
    title: it.title,
    cuisine: it.cuisine || 'ru',
    time: 100,
    active: 30,
    servings: 10,
    verb: it.verb,
    heatSec: it.heatSec,
    ings: [{ ingredient_id: it.m, amount: 1000, unit: 'g' }, { ingredient_id: it.a, amount: 50, unit: 'g' }, it.b, it.d, { ingredient_id: 'water', amount: 100, unit: 'ml' }]
  });
}

// 2. Pickled & Marinated Vegetables (45)
const pickles = [
  { id: 'pickles_cucumbers_dill_garlic', title: 'Хрустящие маринованные огурцы с укропом и чесноком', m: 'cucumber', a: 'dill', b: 'garlic', d: 'apple_vinegar', e: 'bay_leaf' },
  { id: 'pickles_cucumbers_sour_barrel', title: 'Настоящие бочковые соленые огурцы с дубовым листом', m: 'cucumber', a: 'dill', b: 'garlic', d: 'horseradish_root', e: 'salt' },
  { id: 'pickles_tomatoes_sweet_pepper', title: 'Маринованные помидоры со сладким перцем и пряностями', m: 'tomato', a: 'bell_pepper', b: 'garlic', d: 'vinegar', e: 'bay_leaf' },
  { id: 'pickles_tomatoes_sour_cold', title: 'Квашеные помидоры холодным способом с чесноком и укропом', m: 'tomato', a: 'garlic', b: 'dill', d: 'horseradish_root', e: 'salt' },
  { id: 'pickles_cherry_tomatoes_spicy', title: 'Острые маринованные томаты черри с базиликом и перцем', m: 'cherry_tomato', a: 'basil', b: 'chili_pepper', d: 'garlic', e: 'vinegar', cuisine: 'it' },
  { id: 'pickles_zucchini_spicy_rings', title: 'Острые маринованные кружочки кабачка с чесноком', m: 'zucchini', a: 'garlic', b: 'chili_pepper', d: 'dill', e: 'vinegar' },
  { id: 'pickles_zucchini_korean', title: 'Пикантная закуска из кабачков по-корейски с кориандром', m: 'zucchini', a: 'carrot', b: 'garlic', d: 'coriander', e: 'vinegar', cuisine: 'kr' },
  { id: 'pickles_eggplant_stuffed_garlic', title: 'Маринованные баклажаны, фаршированные чесноком и зеленью', m: 'eggplant', a: 'garlic', b: 'cilantro', d: 'vinegar', e: 'bay_leaf' },
  { id: 'pickles_eggplant_grilled_olive', title: 'Вяленые баклажаны на оливковом масле с чесноком и розмарином', m: 'eggplant', a: 'garlic', b: 'rosemary', d: 'olive_oil', e: 'vinegar', cuisine: 'it' },
  { id: 'pickles_bell_pepper_olive_oil', title: 'Запеченный сладкий перец в оливковом масле с чесноком', m: 'bell_pepper', a: 'garlic', b: 'olive_oil', d: 'basil', e: 'vinegar', cuisine: 'it' },
  { id: 'pickles_bell_pepper_stuffed_cabbage', title: 'Маринованные фаршированные перцы с капустой и морковью', m: 'bell_pepper', a: 'cabbage', b: 'carrot', d: 'garlic', e: 'vinegar' },
  { id: 'pickles_cauliflower_turmeric', title: 'Яркая маринованная цветная капуста с куркумой и чесноком', m: 'cauliflower', a: 'garlic', b: 'turmeric', d: 'dill', e: 'vinegar' },
  { id: 'pickles_beet_spiced_classic', title: 'Маринованная свекла с гвоздикой и лавровым листом', m: 'beet', a: 'cloves', b: 'bay_leaf', d: 'vinegar', e: 'garlic' },
  { id: 'pickles_beet_horseradish_relish', title: 'Свекольно-хреновый соус с чесноком — острый хреновик', m: 'beet', a: 'horseradish_root', b: 'garlic', d: 'vinegar', e: 'salt' },
  { id: 'pickles_cabbage_sour_classic', title: 'Классическая домашняя квашеная капуста с морковью', m: 'cabbage', a: 'carrot', b: 'bay_leaf', d: 'black_pepper', e: 'salt' },
  { id: 'pickles_cabbage_sour_cranberry', title: 'Квашеная капуста с клюквой и морковью — к рыбе и мясу', m: 'cabbage', a: 'cranberry', b: 'carrot', d: 'bay_leaf', e: 'salt' },
  { id: 'pickles_cabbage_sour_apple', title: 'Квашеная капуста с антоновскими яблоками и тмином', m: 'cabbage', a: 'apple', b: 'carrot', d: 'cumin', e: 'salt' },
  { id: 'pickles_cabbage_kimchi_style', title: 'Острая капуста по-корейски кимчи с чесноком и перцем', m: 'cabbage', a: 'garlic', b: 'chili_pepper', d: 'ginger', e: 'salt', cuisine: 'kr' },
  { id: 'pickles_daikon_korean_spicy', title: 'Пикантный маринованный дайкон по-корейски с кориандром', m: 'daikon', a: 'carrot', b: 'garlic', d: 'coriander', e: 'vinegar', cuisine: 'kr' },
  { id: 'pickles_mushrooms_champignon_garlic', title: 'Пикантные маринованные шампиньоны с чесноком и укропом', m: 'champignon', a: 'garlic', b: 'dill', d: 'vinegar', e: 'bay_leaf' },
  { id: 'pickles_mushrooms_oyster_spicy', title: 'Острые маринованные вешенки с луком и морковью', m: 'oyster_mushroom', a: 'onion', b: 'carrot', d: 'garlic', e: 'vinegar' },
  { id: 'pickles_mushrooms_forest_dill', title: 'Традиционные соленые лесные грибы с укропом и чесноком', m: 'forest_mushrooms', a: 'dill', b: 'garlic', d: 'horseradish_root', e: 'salt' },
  { id: 'pickles_garlic_whole_brine', title: 'Маринованные головки чеснока в пряном уксусном рассоле', m: 'garlic', a: 'bay_leaf', b: 'black_pepper', d: 'dill', e: 'vinegar' },
  { id: 'pickles_onion_sweet_vinegar', title: 'Сладко-кислый маринованный лук к шашлыку и мясу', m: 'onion', a: 'vinegar', b: 'sugar', d: 'bay_leaf', e: 'black_pepper' },
  { id: 'pickles_watermelon_whole_brine', title: 'Малосольный маринованный арбуз в пряном рассоле', m: 'watermelon', a: 'garlic', b: 'dill', d: 'horseradish_root', e: 'salt' },
  { id: 'pickles_apple_whole_sour', title: 'Моченые яблоки с клюквой и листочком смородины', m: 'apple', a: 'cranberry', b: 'currant_black', d: 'bay_leaf', e: 'salt' },
  { id: 'pickles_carrot_spicy_fingers', title: 'Маринованная морковь с чесноком и зирой по-узбекски', m: 'carrot', a: 'garlic', b: 'cumin', d: 'vinegar', e: 'coriander', cuisine: 'uz' },
  { id: 'pickles_celery_lemon_olive', title: 'Итальянская маринованная черешковая сельдерей с оливками', m: 'celery', a: 'olives', b: 'lemon', d: 'olive_oil', e: 'vinegar', cuisine: 'it' },
  { id: 'pickles_asparagus_lemon_dill', title: 'Маринованная спаржа с лимоном, укропом и чесноком', m: 'asparagus', a: 'lemon', b: 'dill', d: 'garlic', e: 'vinegar', cuisine: 'de' },
  { id: 'pickles_green_beans_garlic', title: 'Маринованная стручковая фасоль с чесноком и укропом', m: 'green_beans', a: 'garlic', b: 'dill', d: 'vinegar', e: 'bay_leaf' },
  { id: 'pickles_pumpkin_spicy_rings', title: 'Острые маринованные кусочки тыквы с имбирем и чесноком', m: 'squash', a: 'ginger', b: 'garlic', d: 'vinegar', e: 'cloves' },
  { id: 'pickles_ginger_sweet_rice', title: 'Розовый маринованный имбирь как в суши-ресторане', m: 'ginger', a: 'vinegar', b: 'sugar', d: 'salt', e: 'water', cuisine: 'jp' },
  { id: 'pickles_leek_mustard_dill', title: 'Маринованный порей с зернистой горчицей и укропом', m: 'leek', a: 'mustard_seeds', b: 'dill', d: 'vinegar', e: 'bay_leaf', cuisine: 'fr' },
  { id: 'pickles_cherry_tomatoes_sweet', title: 'Сладкие консервированные помидорки черри в сладком рассоле', m: 'cherry_tomato', a: 'garlic', b: 'dill', d: 'vinegar', e: 'bay_leaf' },
  { id: 'pickles_beet_cranberry_horseradish', title: 'Пряный закусочный соус из свеклы с клюквой и хреном', m: 'beet', a: 'cranberry', b: 'horseradish_root', d: 'lemon', e: 'salt' },
  { id: 'pickles_cabbage_provencal_spice', title: 'Капуста Провансаль с морковью, клюквой и пряным маслом', m: 'cabbage', a: 'carrot', b: 'cranberry', d: 'garlic', e: 'sunflower_oil' },
  { id: 'pickles_zucchini_sweet_sour_balkan', title: 'Маринованные кабачки по-балкански с болгарским перцем', m: 'zucchini', a: 'bell_pepper', b: 'garlic', d: 'dill', e: 'vinegar', cuisine: 'pl' },
  { id: 'pickles_eggplant_pepper_relish', title: 'Пикантная заготовка из баклажанов с перцем и луком', m: 'eggplant', a: 'bell_pepper', b: 'onion', d: 'garlic', e: 'vinegar' },
  { id: 'pickles_tomatoes_horseradish_brine', title: 'Маринованные помидоры с хреном и листовой горчицей', m: 'tomato', a: 'horseradish_root', b: 'garlic', d: 'dill', e: 'vinegar' },
  { id: 'pickles_cauliflower_beet_color', title: 'Розовая маринованная цветная капуста со свеклой', m: 'cauliflower', a: 'beet', b: 'garlic', d: 'vinegar', e: 'bay_leaf' },
  { id: 'pickles_mushrooms_chanterelle_cream', title: 'Маринованные лисички с луком и пряным рассолом', m: 'chanterelles', a: 'onion', b: 'bay_leaf', d: 'vinegar', e: 'dill' },
  { id: 'pickles_watermelon_spicy_brine', title: 'Острый малосольный арбуз с чесноком и перцем', m: 'watermelon', a: 'garlic', b: 'chili_pepper', d: 'dill', e: 'salt' },
  { id: 'pickles_cabbage_spicy_korean_carrot', title: 'Острая капуста с морковью по-корейски с кориандром', m: 'cabbage', a: 'carrot', b: 'coriander', d: 'garlic', e: 'vinegar', cuisine: 'kr' },
  { id: 'pickles_corn_mexican_pickled', title: 'Маринованная кукуруза с чили и лаймом по-мексикански', m: 'corn', a: 'chili_pepper', b: 'lime', d: 'garlic', e: 'vinegar', cuisine: 'mx' },
  { id: 'pickles_cherry_tomato_basil_brine', title: 'Малосольные томаты черри с базиликом и лимонным рассолом', m: 'cherry_tomato', a: 'basil', b: 'garlic', d: 'lemon', e: 'salt' }
];

for (const it of pickles) {
  addPreserve({
    id: it.id,
    title: it.title,
    cuisine: it.cuisine || 'ru',
    time: 60,
    active: 25,
    servings: 8,
    heatSec: it.heatSec || 1200,
    ings: [{ ingredient_id: it.m, amount: 1000, unit: 'g' }, it.a, it.b, it.d, it.e, { ingredient_id: 'salt', amount: null, unit: 'to_taste' }]
  });
}

// 3. Sauces, Adjika, Tkemali, Horseradish & Caviar (35)
const sauces = [
  { id: 'adjika_tomato_pepper_classic', title: 'Классическая домашняя аджика из томатов и острого перца', m: 'tomato', a: 'chili_pepper', b: 'garlic', d: 'coriander', e: 'salt' },
  { id: 'adjika_green_herb_georgian', title: 'Грузинская зеленая аджика из острого перца с кинзой', m: 'chili_pepper', a: 'garlic', b: 'cilantro', d: 'coriander', e: 'salt', cuisine: 'ge' },
  { id: 'adjika_apple_sweet_spicy', title: 'Яблочная аджика с помидорами, перцем и пряными специями', m: 'tomato', a: 'apple', b: 'chili_pepper', d: 'garlic', e: 'vinegar' },
  { id: 'adjika_eggplant_spicy', title: 'Баклажанная аджика с чесноком и острым перцем чили', m: 'eggplant', a: 'chili_pepper', b: 'garlic', d: 'coriander', e: 'vinegar' },
  { id: 'tkemali_plum_sour_georgian', title: 'Грузинский классический соус ткемали из кислой сливы', m: 'plum', a: 'garlic', b: 'cilantro', d: 'coriander', e: 'chili_pepper', cuisine: 'ge' },
  { id: 'tkemali_red_spiced', title: 'Красный грузинский ткемали из красной сливы и помидор', m: 'plum', a: 'tomato', b: 'garlic', d: 'coriander', e: 'vinegar', cuisine: 'ge' },
  { id: 'tkemali_apple_green_mint', title: 'Яблочный кисло-пряный соус в духе ткемали с мятой', m: 'apple', a: 'garlic', b: 'mint', d: 'cilantro', e: 'coriander' },
  { id: 'ketchup_homemade_spicy', title: 'Острый домашний томатный кетчуп с луком и чесноком', m: 'tomato', a: 'onion', b: 'garlic', d: 'vinegar', e: 'cloves' },
  { id: 'ketchup_plum_sour', title: 'Пикантный сливовый кетчуп с томатами и острым перцем', m: 'plum', a: 'tomato', b: 'garlic', d: 'vinegar', e: 'chili_pepper' },
  { id: 'ketchup_apple_cranberry', title: 'Кисло-сладкий яблочно-клюквенный соус с пряностями', m: 'apple', a: 'cranberry', b: 'garlic', d: 'vinegar', e: 'cloves' },
  { id: 'hrenovaya_zakuska_horseradish', title: 'Острая хреновина из помидоров, хрена и чеснока', m: 'tomato', a: 'horseradish_root', b: 'garlic', d: 'salt', e: 'black_pepper' },
  { id: 'horseradish_beet_simple', title: 'Традиционный тертый хрен со свеклой и уксусом', m: 'horseradish_root', a: 'beet', b: 'vinegar', d: 'sugar', e: 'salt' },
  { id: 'lecho_classic_pepper_tomato', title: 'Классическое лечо из болгарского перца с томатами', m: 'bell_pepper', a: 'tomato', b: 'onion', d: 'vinegar', e: 'garlic' },
  { id: 'lecho_spicy_hungarian', title: 'Пикантное венгерское лечо с острым перцем и луком', m: 'bell_pepper', a: 'tomato', b: 'onion', d: 'chili_pepper', e: 'vinegar', cuisine: 'pl' },
  { id: 'caviar_zucchini_classic', title: 'Классическая домашняя кабачковая икра как в магазине', m: 'zucchini', a: 'carrot', b: 'onion', d: 'tomato_paste', e: 'garlic' },
  { id: 'caviar_zucchini_spicy_pepper', title: 'Острая кабачковая икра с болгарским перцем и томатами', m: 'zucchini', a: 'bell_pepper', b: 'tomato', d: 'garlic', e: 'chili_pepper' },
  { id: 'caviar_eggplant_classic', title: 'Классическая баклажанная икра с луком и томатами', m: 'eggplant', a: 'onion', b: 'tomato', d: 'garlic', e: 'sunflower_oil' },
  { id: 'caviar_eggplant_pepper_georgian', title: 'Грузинская пряная баклажанная закуска с перцем', m: 'eggplant', a: 'bell_pepper', b: 'garlic', d: 'coriander', e: 'vinegar', cuisine: 'ge' },
  { id: 'caviar_pumpkin_onion', title: 'Нежная тыквенная икра с луком и томатной пастой', m: 'squash', a: 'onion', b: 'tomato_paste', d: 'garlic', e: 'sunflower_oil' },
  { id: 'caviar_beet_onion_lemon', title: 'Свекольная икра с луком, лимоном и грецким орехом', m: 'beet', a: 'onion', b: 'walnut', d: 'lemon', e: 'garlic' },
  { id: 'sauce_pesto_garlic_basil', title: 'Домашнее зеленое песто с базиликом, кедровым орехом и оливкой', m: 'basil', a: 'pine_nuts', b: 'garlic', d: 'olive_oil', e: 'parmesan', cuisine: 'it' },
  { id: 'sauce_tomato_basil_italian', title: 'Классический итальянский томатный соус с базиликом', m: 'tomato', a: 'basil', b: 'garlic', d: 'olive_oil', e: 'onion', cuisine: 'it' },
  { id: 'sauce_apple_horseradish_cream', title: 'Нежный яблочно-хреновый соус к рыбе и холодному мясу', m: 'apple', a: 'horseradish_root', b: 'lemon', d: 'sour_cream', e: 'sugar' },
  { id: 'sauce_cherry_plum_sweet_sour', title: 'Кисло-сладкий вишнево-сливовый соус к мясу и птице', m: 'cherry', a: 'plum', b: 'garlic', d: 'coriander', e: 'vinegar' },
  { id: 'sauce_cranberry_orange_holiday', title: 'Праздничный клюквенный соус с апельсином и корицей', m: 'cranberry', a: 'orange', b: 'cinnamon', d: 'apple', e: 'water' },
  { id: 'sauce_adjika_walnuts_georgian', title: 'Грузинская ореховая аджика с кинзой и голубым пажитником', m: 'walnut', a: 'garlic', b: 'chili_pepper', d: 'cilantro', e: 'coriander', cuisine: 'ge' },
  { id: 'sauce_muhammara_pepper_walnut', title: 'Сирийский соус мухаммара из жареного перца с орехами', m: 'bell_pepper', a: 'walnut', b: 'garlic', d: 'olive_oil', e: 'chili_pepper', cuisine: 'tr' },
  { id: 'sauce_tomatillo_salsa_verde', title: 'Мексиканская зеленая сальса с острым перцем и кинзой', m: 'tomato', a: 'chili_pepper', b: 'cilantro', d: 'garlic', e: 'lemon', cuisine: 'mx' },
  { id: 'sauce_harissa_chili_spice', title: 'Североафриканская острая паста харисса со специями', m: 'chili_pepper', a: 'garlic', b: 'cumin', d: 'olive_oil', e: 'coriander', cuisine: 'tr' },
  { id: 'sauce_dried_apricot_spice', title: 'Пряный кисло-сладкий соус из кураги с имбирем к мясу', m: 'dried_apricots', a: 'ginger', b: 'vinegar', d: 'garlic', e: 'cloves' },
  { id: 'sauce_prune_spiced_sweet', title: 'Терпкий черносливовый соус с пряностями к дичи и говядине', m: 'prunes', a: 'garlic', b: 'coriander', d: 'vinegar', e: 'cloves' },
  { id: 'sauce_sea_buckthorn_orange', title: 'Яркий облепиховый соус с апельсином и медом к рыбе', m: 'cranberry', a: 'orange', b: 'honey', d: 'ginger', e: 'lemon' },
  { id: 'sauce_mushroom_champignon_cream', title: 'Густой грибной соус из шампиньонов с чесноком и укропом', m: 'champignon', a: 'onion', b: 'garlic', d: 'dill', e: 'vinegar' },
  { id: 'sauce_wild_mushroom_sour_cream', title: 'Насыщенный соус из лесных грибов со сметаной к картофелю', m: 'forest_mushrooms', a: 'onion', b: 'garlic', d: 'dill', e: 'vinegar' },
  { id: 'sauce_beet_orange_vinaigrette', title: 'Пикантная свекольная заправка с апельсином и хреном', m: 'beet', a: 'orange', b: 'horseradish_root', d: 'vinegar', e: 'garlic' }
];

for (const it of sauces) {
  addPreserve({
    id: it.id,
    title: it.title,
    cuisine: it.cuisine || 'ru',
    time: 60,
    active: 25,
    servings: 8,
    heatSec: it.heatSec || 1800,
    ings: [{ ingredient_id: it.m, amount: 500, unit: 'g' }, it.a, it.b, it.d, it.e, { ingredient_id: 'salt', amount: null, unit: 'to_taste' }]
  });
}

console.log(`Total generated preserves: ${allPreserves.length}`);
saveAndValidateGroup('preserves.json', allPreserves);
