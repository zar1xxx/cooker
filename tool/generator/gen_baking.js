const { saveAndValidateGroup, smartIngredient } = require('./recipe_builder');

function s(text, timer_seconds, tip) {
  const step = { text: text.trim() };
  if (timer_seconds) step.timer_seconds = timer_seconds;
  if (tip) step.tip = tip;
  return step;
}

const allBaking = [];

function addBaking(def) {
  const id = `bake_${def.id}`;
  const title = def.title;
  const time = def.time || 50;
  const active = def.active || 20;
  const servings = def.servings || 6;
  const cuisine = def.cuisine || 'home';
  const desc = def.desc || `Ароматная домашняя выпечка «${title}» к чаю или семейному столу.`;

  const ingsMap = new Map();
  for (const raw of def.ings) {
    const rawId = raw.ingredient_id || raw.id || raw;
    const ingObj = smartIngredient(rawId, raw.amount, raw.unit);
    ingsMap.set(rawId, ingObj);
  }
  const ings = Array.from(ingsMap.values());

  const hasEgg = ingsMap.has('egg');
  const hasMeat = ['pork', 'chicken_fillet', 'minced_meat', 'minced_beef', 'minced_chicken', 'beef', 'lamb', 'salmon', 'cod', 'trout', 'pollock', 'tuna_canned'].some(k => ingsMap.has(k));

  let heatVerb = def.verb || 'запекайте в разогретой духовке';
  if (hasEgg && !['вар', 'жар', 'запек'].some(k => heatVerb.toLowerCase().includes(k))) {
    heatVerb = 'запекайте в духовке';
  }
  const heatSec = def.heatSec || (hasMeat ? 1800 : 1500); // 25-30 min
  const heatMin = Math.ceil(heatSec / 60);

  const steps = def.steps || [
    s(`Для домашней выпечки «${title}» отмерьте сухие и жидкие компоненты, просейте муку и подготовьте начинку.`),
    s(`Замесите мягкое эластичное тесто или взбейте основу${hasEgg ? ' с яйцом' : ''} для «${title}» до однородного состояния.`),
    s(`Сформируйте изделие или выложите заготовку для «${title}» в подготовленную форму или на противень.`),
    s(`${heatVerb.charAt(0).toUpperCase() + heatVerb.slice(1)} блюдо «${title}» в течение ${heatMin} минут до румяной золотистой корочки.`, heatSec),
    s(`Дайте готовой выпечке «${title}» слегка остыть на решетке или под полотенцем и подавайте к столу.`)
  ];

  allBaking.push({
    id: id,
    title: title,
    dish_type: 'baking',
    dish_group: 'baking',
    cuisine: cuisine,
    total_minutes: Math.max(time, heatMin + 20),
    active_minutes: active,
    servings: servings,
    description: desc,
    ingredients: ings,
    steps: steps
  });
}

// 1. Sweet Pies, Galettes, Tarts, Crumbles (40)
const sweetPies = [
  { id: 'plum_pie_butter_cinnamon', title: 'Нежный сливовый пирог с корицей из песочного теста', f: 'flour', m: 'plum', a: 'butter', b: 'sugar', d: 'egg', e: 'cinnamon', c: 'us' },
  { id: 'cherry_pie_sour_cream', title: 'Открытый вишневый пирог со сметанной заливкой и ванилью', f: 'flour', m: 'cherry', a: 'sour_cream', b: 'vanilla_sugar', d: 'egg', e: 'starch', c: 'ru' },
  { id: 'pear_almond_frangipane_tart', title: 'Французский грушевый тарт с миндальным кремом франжипан', f: 'flour', m: 'pear', a: 'almond', b: 'butter', d: 'egg', e: 'sugar', c: 'fr' },
  { id: 'blueberry_galette_cornmeal', title: 'Хрустящая галета с черникой и добавлением кукурузной крупы', f: 'flour', m: 'blueberry', a: 'cornmeal', b: 'butter', d: 'sugar', e: 'lemon', c: 'home' },
  { id: 'raspberry_curd_tart_cream', title: 'Летний малиновый пирог с нежным сливочным кремом', f: 'flour', m: 'raspberry', a: 'cream', b: 'egg', d: 'sugar', e: 'vanilla', c: 'fr' },
  { id: 'strawberry_rhubarb_pie', title: 'Кисло-сладкий английский пирог с клубникой и ревенем', f: 'flour', m: 'strawberry', a: 'rhubarb', b: 'butter', d: 'sugar', e: 'starch', c: 'uk' },
  { id: 'apple_strudel_walnut_raisins', title: 'Венский яблочный штрудель с изюмом, корицей и орехами', f: 'flour', m: 'apple', a: 'walnut', b: 'raisins', d: 'butter', e: 'cinnamon', c: 'de' },
  { id: 'tsvetayevsky_apple_pie_cream', title: 'Легендарный цветаевский яблочный пирог в сметанной заливке', f: 'flour', m: 'apple', a: 'sour_cream', b: 'butter', d: 'egg', e: 'sugar', c: 'ru' },
  { id: 'currant_black_crumble_oats', title: 'Хрустящий крамбл с черной смородиной и овсяными хлопьями', f: 'oatmeal', m: 'currant_black', a: 'butter', b: 'sugar', d: 'flour', e: 'vanilla_sugar', c: 'uk' },
  { id: 'currant_red_meringue_pie', title: 'Нежный пирог с красной смородиной под воздушным безе', f: 'flour', m: 'currant_red', a: 'egg', b: 'sugar', d: 'butter', e: 'baking_powder', c: 'ru' },
  { id: 'gooseberry_honey_pie', title: 'Летний домашний пирог с крыжовником, медом и сметаной', f: 'flour', m: 'gooseberry', a: 'honey', b: 'sour_cream', d: 'egg', e: 'butter', c: 'ru' },
  { id: 'peach_coconut_tart', title: 'Нежный летний пирог с персиками и кокосовой стружкой', f: 'flour', m: 'peach', a: 'coconut_flakes', b: 'butter', d: 'egg', e: 'sugar', c: 'home' },
  { id: 'apricot_kefir_quick_pie', title: 'Быстрый заливной пирог на кефире со свежими абрикосами', f: 'flour', m: 'apricot', a: 'kefir', b: 'sugar', d: 'egg', e: 'baking_soda', c: 'ru' },
  { id: 'blackberry_yogurt_cake', title: 'Мягкий йогуртовый пирог со спелой ежевикой и лимоном', f: 'flour', m: 'blackberry', a: 'yogurt', b: 'lemon', d: 'egg', e: 'sugar', c: 'home' },
  { id: 'grape_schiacciata_rosemary', title: 'Итальянский осенний пирог с виноградом и розмарином', f: 'flour', m: 'grape', a: 'rosemary', b: 'olive_oil', d: 'yeast', e: 'sugar', c: 'it' },
  { id: 'lemon_tart_curd_classic', title: 'Французский лимонный тарт на хрустящем песочном тесте', f: 'flour', m: 'lemon', a: 'butter', b: 'egg', d: 'sugar', e: 'cream', c: 'fr' },
  { id: 'orange_polenta_cake', title: 'Средиземноморский апельсиновый кекс из кукурузной крупы', f: 'cornmeal', m: 'orange', a: 'almond', b: 'egg', d: 'sugar', e: 'olive_oil', c: 'it' },
  { id: 'pineapple_upside_down_cake', title: 'Перевернутый карамельный пирог с кольцами ананаса', f: 'flour', m: 'pineapple', a: 'butter', b: 'sugar', d: 'egg', e: 'baking_powder', c: 'us' },
  { id: 'persimmon_ginger_spice_cake', title: 'Пряный зимний пирог с хурмой, имбирем и корицей', f: 'flour', m: 'persimmon', a: 'ginger', b: 'cinnamon', d: 'egg', e: 'sugar', c: 'home' },
  { id: 'fig_honey_hazelnut_tart', title: 'Изысканный осенний тарт со свежим инжиром и фундуком', f: 'flour', m: 'fig', a: 'hazelnut', b: 'honey', d: 'butter', e: 'cream_cheese', c: 'fr' },
  { id: 'cottage_terty_pie_jam', title: 'Тертый песочный пирог из детства с ягодным вареньем', f: 'flour', m: 'jam', a: 'butter', b: 'egg', d: 'sugar', e: 'baking_powder', c: 'ru' },
  { id: 'cottage_royal_vatrushka_cocoa', title: 'Королевская шоколадная ватрушка с нежной творожной начинкой', f: 'flour', m: 'cottage_cheese', a: 'cocoa', b: 'butter', d: 'egg', e: 'sugar', c: 'ru' },
  { id: 'poppy_seed_roll_raisins', title: 'Рулет с сочной маковой начинкой, изюмом и медом', f: 'flour', m: 'poppy_seeds', a: 'raisins', b: 'honey', d: 'yeast', e: 'milk', c: 'ru' },
  { id: 'condensed_milk_napoleon_cake', title: 'Быстрый медовый торт с вареной сгущенкой и сметаной', f: 'flour', m: 'condensed_milk', a: 'honey', b: 'sour_cream', d: 'butter', e: 'egg', c: 'ru' },
  { id: 'carrot_walnut_cream_cheese_cake', title: 'Пряный морковный пирог с грецким орехом и сливочным сыром', f: 'flour', m: 'carrot', a: 'walnut', b: 'cream_cheese', d: 'egg', e: 'cinnamon', c: 'us' },
  { id: 'chocolate_lava_fondant_cake', title: 'Шоколадный фондан с жидкой серединкой и сливочным маслом', f: 'flour', m: 'chocolate', a: 'butter', b: 'egg', d: 'sugar', e: 'vanilla', c: 'fr', heatSec: 600 },
  { id: 'zebra_marble_kefir_pie', title: 'Мраморный домашний пирог Зебра с какао на кефире', f: 'flour', m: 'cocoa', a: 'kefir', b: 'egg', d: 'sugar', e: 'butter', c: 'ru' },
  { id: 'prague_chocolate_apricot_cake', title: 'Домашний шоколадный торт Прага с абрикосовым джемом', f: 'flour', m: 'cocoa', a: 'jam', b: 'condensed_milk', d: 'egg', e: 'butter', c: 'ru' },
  { id: 'beet_chocolate_brownie_pie', title: 'Необычный влажный шоколадный пирог со свеклой и какао', f: 'flour', m: 'beet', a: 'chocolate', b: 'cocoa', d: 'egg', e: 'sugar', c: 'home' },
  { id: 'zucchini_lemon_glaze_loaf', title: 'Сладкий влажный лимонный кекс с тертым молодым кабачком', f: 'flour', m: 'zucchini', a: 'lemon', b: 'sugar', d: 'egg', e: 'sunflower_oil', c: 'home' },
  { id: 'cranberry_orange_pound_cake', title: 'Праздничный кекс Столичный с клюквой и апельсиновой цедрой', f: 'flour', m: 'cranberry', a: 'orange', b: 'butter', d: 'egg', e: 'sugar', c: 'ru' },
  { id: 'dates_caramel_sticky_pudding', title: 'Английский финиковый пирог с густым карамельным соусом', f: 'flour', m: 'dates', a: 'caramel', b: 'butter', d: 'egg', e: 'baking_soda', c: 'uk' },
  { id: 'halva_shortcrust_tea_pie', title: 'Восточный рассыпчатый пирог к чаю с подсолнечной халвой', f: 'flour', m: 'halva', a: 'sour_cream', b: 'butter', d: 'egg', e: 'baking_powder', c: 'home' },
  { id: 'dried_apricots_cottage_pie', title: 'Творожный пирог на песочной крошке с курагой и миндалем', f: 'flour', m: 'dried_apricots', a: 'cottage_cheese', b: 'almond', d: 'egg', e: 'butter', c: 'home' },
  { id: 'mandarin_almond_flourless_pie', title: 'Ароматный мандариновый пирог с миндальной крошкой', f: 'almond', m: 'mandarin', a: 'egg', b: 'sugar', d: 'butter', e: 'baking_powder', c: 'es' },
  { id: 'sweet_cherry_clafoutis_french', title: 'Французский клафути со спелой черешней в молочной заливке', f: 'flour', m: 'sweet_cherry', a: 'milk', b: 'egg', d: 'sugar', e: 'vanilla', c: 'fr' },
  { id: 'pumpkin_cream_cheese_swirl', title: 'Осенний тыквенный пирог с прослойкой из сливочного сыра', f: 'flour', m: 'squash', a: 'cream_cheese', b: 'nutmeg', d: 'egg', e: 'sugar', c: 'us' },
  { id: 'melon_yogurt_sponge_cake', title: 'Нежный летний бисквит с кусочками дыни и йогуртом', f: 'flour', m: 'melon', a: 'yogurt', b: 'egg', d: 'sugar', e: 'baking_powder', c: 'home' },
  { id: 'semolina_mannik_berry_jam', title: 'Рассыпчатый манник на простокваше с домашним повидлом', f: 'semolina', m: 'curdled_milk', a: 'jam', b: 'egg', d: 'sugar', e: 'butter', c: 'ru' },
  { id: 'grapefruit_olive_oil_cake', title: 'Средиземноморский пирог на оливковом масле с грейпфрутом', f: 'flour', m: 'grapefruit', a: 'olive_oil', b: 'egg', d: 'sugar', e: 'yogurt', c: 'it' }
];

for (const it of sweetPies) {
  addBaking({
    id: it.id,
    title: it.title,
    cuisine: it.c,
    time: 55,
    active: 20,
    desc: `Ароматный домашний пирог «${it.title}» с нежной начинкой к семейному чаепитию.`,
    ings: [
      { ingredient_id: it.f, amount: 250, unit: 'g' },
      { ingredient_id: it.m, amount: 250, unit: 'g' },
      it.a,
      it.b,
      it.d,
      it.e
    ]
  });
}

// 2. Savory Pies, Quiches, Khachapuri, Focaccia, Pizzas (40)
const savoryPies = [
  { id: 'khachapuri_ajaruli_egg_cheese', title: 'Грузинский хачапури по-аджарски лодочка с сыром и яйцом', f: 'flour', m: 'feta', a: 'mozzarella', b: 'egg', d: 'butter', e: 'yeast', c: 'ge' },
  { id: 'khachapuri_imeretian_kefir', title: 'Закрытый имеретинский хачапури на кефирном тесте с сыром', f: 'flour', m: 'cheese', a: 'kefir', b: 'butter', d: 'baking_soda', e: 'egg', c: 'ge' },
  { id: 'kubdari_georgian_beef_spice', title: 'Грузинский мясной пирог кубдари с говядиной и кориандром', f: 'flour', m: 'beef', a: 'onion', b: 'coriander', d: 'garlic', e: 'yeast', c: 'ge' },
  { id: 'ossetian_pie_potato_cheese', title: 'Тонкий осетинский пирог картофджин с картофелем и сыром', f: 'flour', m: 'potato', a: 'feta', b: 'milk', d: 'butter', e: 'yeast', c: 'ru' },
  { id: 'ossetian_pie_beet_leaves_cheese', title: 'Традиционный пирог с зеленью, щавелем и рассольным сыром', f: 'flour', m: 'sorrel', a: 'spinach', b: 'feta', d: 'green_onion', e: 'kefir', c: 'ru' },
  { id: 'kurnik_chicken_mushroom_creamy', title: 'Царский курник с куриным филе, шампиньонами и сметаной', f: 'flour', m: 'chicken_fillet', a: 'champignon', b: 'sour_cream', d: 'butter', e: 'egg', c: 'ru' },
  { id: 'kulebyaka_salmon_rice_egg', title: 'Праздничная кулебяка с лососем, рисом и зеленым луком', f: 'flour', m: 'salmon', a: 'round_rice', b: 'egg', d: 'green_onion', e: 'yeast', c: 'ru' },
  { id: 'quiche_lorraine_bacon_cream', title: 'Французский киш лорен с хрустящим беконом и сливками', f: 'flour', m: 'bacon', a: 'cream', b: 'hard_cheese', d: 'egg', e: 'butter', c: 'fr' },
  { id: 'quiche_salmon_broccoli_cream', title: 'Открытый заливной пирог с лососем и брокколи в сливках', f: 'flour', m: 'salmon', a: 'broccoli', b: 'cream', d: 'egg', e: 'mozzarella', c: 'fr' },
  { id: 'quiche_champignon_leek_thyme', title: 'Киш с жареными шампиньонами, пореем и тимьяном', f: 'flour', m: 'champignon', a: 'leek', b: 'thyme', d: 'egg', e: 'cream', c: 'fr' },
  { id: 'quiche_spinach_feta_pine', title: 'Средиземноморский открытый пирог со шпинатом, фетой и орешком', f: 'flour', m: 'spinach', a: 'feta', b: 'pine_nuts', d: 'egg', e: 'sour_cream', c: 'gr' },
  { id: 'spanakopita_lavash_greek', title: 'Хрустящая греческая спанакопита из лаваша со шпинатом', f: 'lavash', m: 'spinach', a: 'feta', b: 'dill', d: 'egg', e: 'butter', c: 'gr' },
  { id: 'zalivnoy_cabbage_egg_kefir', title: 'Быстрый заливной пирог на кефире с капустой и зеленым луком', f: 'flour', m: 'cabbage', a: 'green_onion', b: 'kefir', d: 'egg', e: 'mayonnaise', c: 'ru' },
  { id: 'zalivnoy_tuna_potato_rice', title: 'Быстрый пирог на сметане с консервированным тунцом и рисом', f: 'flour', m: 'tuna_canned', a: 'round_rice', b: 'sour_cream', d: 'egg', e: 'dill', c: 'ru' },
  { id: 'zalivnoy_saury_green_onion', title: 'Заливной рыбный пирог с консервированной сайрой и укропом', f: 'flour', m: 'saury_canned', a: 'green_onion', b: 'dill', d: 'kefir', e: 'egg', c: 'ru' },
  { id: 'zalivnoy_green_onion_egg_classic', title: 'Любимый быстрый пирог с зеленым луком и вареным яйцом', f: 'flour', m: 'green_onion', a: 'egg', b: 'kefir', d: 'butter', e: 'baking_soda', c: 'ru' },
  { id: 'echpochmak_tatar_beef_potato', title: 'Татарские треугольники эчпочмак с говядиной и картофелем', f: 'flour', m: 'beef', a: 'potato', b: 'onion', d: 'butter', e: 'kefir', c: 'ru' },
  { id: 'samsa_crispy_minced_cumin', title: 'Хрустящая слоеная самса с рубленым мясом и зирой', f: 'flour', m: 'minced_beef', a: 'onion', b: 'cumin', d: 'butter', e: 'egg', c: 'uz' },
  { id: 'belyashi_fried_pork_onion', title: 'Сочные жареные беляши с мясным фаршем на дрожжевом тесте', f: 'flour', m: 'minced_meat', a: 'onion', b: 'yeast', d: 'milk', e: 'sunflower_oil', c: 'ru', verb: 'обжаривайте в глубокой сковороде', heatSec: 900 },
  { id: 'pirozhki_potato_fried_dill', title: 'Пышные жареные пирожки с картофельным пюре и жареным луком', f: 'flour', m: 'potato', a: 'dill', b: 'yeast', d: 'onion', e: 'sunflower_oil', c: 'ru', verb: 'обжаривайте с двух сторон', heatSec: 480 },
  { id: 'pirozhki_cabbage_oven_baked', title: 'Румяные печеные пирожки с тушеной капустой и морковью', f: 'flour', m: 'cabbage', a: 'carrot', b: 'yeast', d: 'egg', e: 'milk', c: 'ru' },
  { id: 'pirozhki_liver_buckwheat', title: 'Домашние пирожки из духовки с ливерной начинкой из печени', f: 'flour', m: 'liver_chicken', a: 'buckwheat', b: 'yeast', d: 'egg', e: 'onion', c: 'ru' },
  { id: 'rasstegai_cod_onion_broth', title: 'Традиционные открытые расстегаи с филе трески и укропом', f: 'flour', m: 'cod', a: 'dill', b: 'yeast', d: 'butter', e: 'egg', c: 'ru' },
  { id: 'focaccia_cherry_rosemary_olives', title: 'Итальянская фокачча с томатами черри, маслинами и розмарином', f: 'flour', m: 'cherry_tomato', a: 'olives', b: 'rosemary', d: 'olive_oil', e: 'yeast', c: 'it' },
  { id: 'focaccia_potato_garlic_thyme', title: 'Ароматная картофельная фокачча с чесноком и тимьяном', f: 'flour', m: 'potato', a: 'garlic', b: 'thyme', d: 'olive_oil', e: 'yeast', c: 'it' },
  { id: 'pizza_margherita_mozzarella_basil', title: 'Домашняя пицца Маргарита с томатным соусом и моцареллой', f: 'flour', m: 'mozzarella', a: 'tomato_sauce', b: 'basil', d: 'olive_oil', e: 'yeast', c: 'it' },
  { id: 'pizza_four_cheeses_quattro', title: 'Сливочная пицца Четыре сыра с пармезаном, фетой и орегано', f: 'flour', m: 'parmesan', a: 'mozzarella', b: 'feta', d: 'cream', e: 'oregano', c: 'it' },
  { id: 'pizza_mushroom_ham_olives', title: 'Домашняя пицца с ветчиной, шампиньонами и маслинами', f: 'flour', m: 'ham', a: 'champignon', b: 'olives', d: 'hard_cheese', e: 'tomato_sauce', c: 'it' },
  { id: 'pizza_chicken_pineapple_corn', title: 'Гавайская пицца с куриным филе, ананасом и кукурузой', f: 'flour', m: 'chicken_fillet', a: 'pineapple', b: 'corn_canned', d: 'mozzarella', e: 'tomato_sauce', c: 'us' },
  { id: 'pizza_zucchini_eggplant_feta', title: 'Овощная пицца с кабачком, баклажаном и раскрошенной фетой', f: 'flour', m: 'zucchini', a: 'eggplant', b: 'feta', d: 'bell_pepper', e: 'olive_oil', c: 'it' },
  { id: 'tarte_flambee_onion_bacon', title: 'Эльзасский луковый тарт фламбе со сметаной и беконом', f: 'flour', m: 'bacon', a: 'onion', b: 'sour_cream', d: 'nutmeg', e: 'olive_oil', c: 'fr' },
  { id: 'chicken_broccoli_pie_cream', title: 'Нежный закрытый пирог с куриной грудкой, брокколи и сыром', f: 'flour', m: 'chicken_fillet', a: 'broccoli', b: 'hard_cheese', d: 'egg', e: 'cream', c: 'home' },
  { id: 'turkey_zucchini_herb_galette', title: 'Сытная галета из цельнозерновой муки с индейкой и кабачком', f: 'wholegrain_flour', m: 'turkey_fillet', a: 'zucchini', b: 'cream_cheese', d: 'dill', e: 'butter', c: 'home' },
  { id: 'pork_ribs_sauerkraut_pie_rye', title: 'Старорусский закрытый курник-пирог на ржаной муке с капустой', f: 'rye_flour', m: 'pork', a: 'sauerkraut', b: 'onion', d: 'butter', e: 'kefir', c: 'ru' },
  { id: 'bell_pepper_corn_cornbread', title: 'Техасский кукурузный хлеб со сладким перцем и кукурузой', f: 'cornmeal', m: 'corn_canned', a: 'bell_pepper', b: 'hard_cheese', d: 'buttermilk', e: 'egg', c: 'us' },
  { id: 'pumpkin_savory_feta_galette', title: 'Осенняя несладкая галета с печеной тыквой, фетой и розмарином', f: 'flour', m: 'squash', a: 'feta', b: 'rosemary', d: 'butter', e: 'olive_oil', c: 'home' },
  { id: 'tomato_mustard_french_tart', title: 'Прованский горчично-томатный тарт с моцареллой и тимьяном', f: 'flour', m: 'tomato', a: 'mustard', b: 'mozzarella', d: 'thyme', e: 'butter', c: 'fr' },
  { id: 'cauliflower_cheese_crust_pizza', title: 'Полезная низкоуглеводная пицца на основе из цветной капусты', f: 'cauliflower', m: 'egg', a: 'hard_cheese', b: 'tomato', d: 'mozzarella', e: 'oregano', c: 'home' },
  { id: 'sausage_rolls_puff_mustard', title: 'Домашние сосиски в слоеном или дрожжевом тесте с горчицей', f: 'flour', m: 'frankfurters', a: 'mustard', b: 'egg', d: 'sesame', e: 'yeast', c: 'ru' },
  { id: 'carrot_oyster_mushroom_pie', title: 'Постный сытный пирог с вешенками, морковью и жареным луком', f: 'flour', m: 'oyster_mushroom', a: 'carrot', b: 'onion', d: 'sunflower_oil', e: 'yeast', c: 'ru' }
];

for (const it of savoryPies) {
  addBaking({
    id: it.id,
    title: it.title,
    cuisine: it.c,
    time: 60,
    active: 25,
    verb: it.verb,
    heatSec: it.heatSec || 1800,
    desc: `Ароматный несладкий пирог или выпечка «${it.title}» к обеду или ужину.`,
    ings: [
      { ingredient_id: it.f, amount: 250, unit: 'g' },
      { ingredient_id: it.m, amount: 250, unit: 'g' },
      it.a,
      it.b,
      it.d,
      it.e,
      'salt'
    ]
  });
}

// 3. Cookies, Gingerbread, Muffins, Cupcakes, Brownies, Scones (45)
const cookiesMuffins = [
  { id: 'cookies_oatmeal_raisins_honey', title: 'Домашнее овсяное печенье с изюмом, корицей и медом', f: 'oatmeal', m: 'raisins', a: 'honey', b: 'butter', d: 'egg', e: 'cinnamon', c: 'ru' },
  { id: 'cookies_chocolate_chip_classic', title: 'Американское хрустящее печенье с кусочками темного шоколада', f: 'flour', m: 'chocolate', a: 'butter', b: 'sugar', d: 'egg', e: 'vanilla_sugar', c: 'us' },
  { id: 'cookies_peanut_butter_crispy', title: 'Рассыпчатое арахисовое печенье с орешками и медом', f: 'flour', m: 'peanut', a: 'butter', b: 'honey', d: 'egg', e: 'baking_soda', c: 'us' },
  { id: 'cookies_gingerbread_spiced', title: 'Ароматные рождественские имбирные пряники с корицей и гвоздикой', f: 'flour', m: 'ginger', a: 'honey', b: 'cinnamon', d: 'cloves', e: 'butter', c: 'de' },
  { id: 'cookies_pryaniki_kefir_mint', title: 'Мягкие русские домашние пряники на кефире с ноткой мяты', f: 'flour', m: 'kefir', a: 'sugar', b: 'mint', d: 'egg', e: 'baking_soda', c: 'ru' },
  { id: 'cookies_kurabye_jam_butter', title: 'Песочное печенье Курабье с капелькой яблочного повидла', f: 'flour', m: 'butter', a: 'jam', b: 'sugar', d: 'egg', e: 'vanilla', c: 'ru' },
  { id: 'cookies_coconut_macaroons_condensed', title: 'Нежное кокосовое печенье без муки на сгущенном молоке', f: 'coconut_flakes', m: 'condensed_milk', a: 'egg', b: 'vanilla_sugar', d: 'butter', e: 'sugar', c: 'home' },
  { id: 'cookies_almond_biscotti_orange', title: 'Итальянское хрустящее печенье бискотти с миндалем и апельсином', f: 'flour', m: 'almond', a: 'orange', b: 'egg', d: 'sugar', e: 'baking_powder', c: 'it' },
  { id: 'cookies_cottage_cheese_triangles', title: 'Творожные ушки по бабушкиному рецепту в сахарной корочке', f: 'flour', m: 'cottage_cheese', a: 'butter', b: 'sugar', d: 'baking_powder', e: 'vanilla_sugar', c: 'ru' },
  { id: 'cookies_buckwheat_banana_healthy', title: 'Полезное гречневое печенье с бананом и финиками без сахара', f: 'buckwheat', m: 'banana', a: 'dates', b: 'walnut', d: 'sunflower_oil', e: 'cinnamon', c: 'home' },
  { id: 'cookies_lemon_crinkle_powdered', title: 'Мягкое лимонное мраморное печенье с сахарной пудрой', f: 'flour', m: 'lemon', a: 'butter', b: 'egg', d: 'sugar', e: 'baking_powder', c: 'home' },
  { id: 'cookies_chocolate_crinkle_cocoa', title: 'Шоколадное печенье с трещинками на какао и сливочном масле', f: 'flour', m: 'cocoa', a: 'butter', b: 'egg', d: 'sugar', e: 'vanilla', c: 'us' },
  { id: 'cookies_cornmeal_rosemary_lemon', title: 'Песочное кукурузное печенье с цедрой лимона и розмарином', f: 'cornmeal', m: 'flour', a: 'lemon', b: 'rosemary', d: 'butter', e: 'sugar', c: 'it' },
  { id: 'cookies_hazelnut_shortbread_balls', title: 'Рассыпчатые ореховые шарики из песочного теста с фундуком', f: 'flour', m: 'hazelnut', a: 'butter', b: 'sugar', d: 'vanilla', e: 'starch', c: 'de' },
  { id: 'cookies_sour_cream_korzhiki', title: 'Школьные молочные или сметанные коржики с детства', f: 'flour', m: 'sour_cream', a: 'butter', b: 'egg', d: 'sugar', e: 'baking_powder', c: 'ru' },
  { id: 'cookies_pistachio_cranberry_bark', title: 'Праздничное тонкое печенье с фисташками и сушеной клюквой', f: 'flour', m: 'pistachio', a: 'cranberry', b: 'butter', d: 'sugar', e: 'egg', c: 'home' },
  { id: 'cookies_sesame_tahini_crunchy', title: 'Восточное рассыпчатое кунжутное печенье на меду', f: 'flour', m: 'sesame', a: 'honey', b: 'butter', d: 'egg', e: 'baking_powder', c: 'tr' },
  { id: 'cookies_sunflower_halva_oat', title: 'Домашнее печенье из овсяных хлопьев с семечками подсолнуха', f: 'rolled_oats', m: 'sunflower_seeds', a: 'honey', b: 'butter', d: 'flour', e: 'baking_soda', c: 'ru' },
  { id: 'brownie_classic_walnut_dark', title: 'Влажный шоколадный брауни с грецким орехом и корочкой', f: 'flour', m: 'chocolate', a: 'butter', b: 'walnut', d: 'egg', e: 'sugar', c: 'us' },
  { id: 'brownie_cherry_chocolate_fudge', title: 'Шоколадный пирог-брауни с сочной вишней и какао', f: 'flour', m: 'chocolate', a: 'cherry', b: 'cocoa', d: 'egg', e: 'butter', c: 'us' },
  { id: 'brownie_cottage_cheesecake_swirl', title: 'Мраморный брауни с нежной творожно-ванильной прослойкой', f: 'flour', m: 'chocolate', a: 'cottage_cheese', b: 'butter', d: 'egg', e: 'sugar', c: 'home' },
  { id: 'blondie_caramel_cashew_butter', title: 'Карамельный блонди с белым орехом кешью и душистой ванилью', f: 'flour', m: 'cashew', a: 'caramel', b: 'butter', d: 'egg', e: 'sugar', c: 'us' },
  { id: 'muffins_blueberry_yogurt_crumb', title: 'Пышные маффины с черникой и нежным йогуртом', f: 'flour', m: 'blueberry', a: 'yogurt', b: 'sugar', d: 'egg', e: 'baking_powder', c: 'us' },
  { id: 'muffins_chocolate_banana_soft', title: 'Шоколадно-банановые кексы на скорую руку с какао', f: 'flour', m: 'banana', a: 'cocoa', b: 'sunflower_oil', d: 'egg', e: 'sugar', c: 'home' },
  { id: 'muffins_lemon_poppy_seed', title: 'Английские лимонные кексы с маком и сладкой цедрой', f: 'flour', m: 'poppy_seeds', a: 'lemon', b: 'butter', d: 'egg', e: 'sugar', c: 'uk' },
  { id: 'muffins_cottage_cheese_raisins', title: 'Воздушные творожные кексики с изюмом, как в кулинарии', f: 'flour', m: 'cottage_cheese', a: 'raisins', b: 'butter', d: 'egg', e: 'sugar', c: 'ru' },
  { id: 'muffins_orange_cranberry_nutmeg', title: 'Рождественские кексы с апельсином, клюквой и мускатным орехом', f: 'flour', m: 'orange', a: 'cranberry', b: 'nutmeg', d: 'egg', e: 'butter', c: 'home' },
  { id: 'muffins_apple_oatmeal_streusel', title: 'Овсяно-яблочные маффины со штрейзельной крошкой', f: 'rolled_oats', m: 'apple', a: 'flour', b: 'cinnamon', d: 'egg', e: 'kefir', c: 'home' },
  { id: 'muffins_pumpkin_chocolate_chip', title: 'Осенние тыквенные маффины с каплями горького шоколада', f: 'flour', m: 'squash', a: 'chocolate', b: 'cinnamon', d: 'egg', e: 'sunflower_oil', c: 'us' },
  { id: 'muffins_savory_cheese_ham_dill', title: 'Закусочные несладкие маффины с ветчиной, сыром и укропом', f: 'flour', m: 'ham', a: 'hard_cheese', b: 'dill', d: 'egg', e: 'milk', c: 'home' },
  { id: 'muffins_savory_zucchini_feta', title: 'Соленые маффины с кабачком, сыром фета и петрушкой', f: 'flour', m: 'zucchini', a: 'feta', b: 'parsley', d: 'egg', e: 'kefir', c: 'gr' },
  { id: 'muffins_savory_corn_bell_pepper', title: 'Пикантные кукурузные маффины со сладким перцем и сыром', f: 'cornmeal', m: 'corn_canned', a: 'bell_pepper', b: 'cheese', d: 'egg', e: 'milk', c: 'us' },
  { id: 'cupcakes_vanilla_condensed_frost', title: 'Нежные ванильные капкейки с кремом из вареной сгущенки', f: 'flour', m: 'vanilla_sugar', a: 'condensed_milk', b: 'butter', d: 'egg', e: 'milk', c: 'home' },
  { id: 'cupcakes_red_velvet_cocoa_kefir', title: 'Бархатные шоколадные капкейки на кефире со сливочным сыром', f: 'flour', m: 'cocoa', a: 'kefir', b: 'cream_cheese', d: 'egg', e: 'sugar', c: 'us' },
  { id: 'scones_cream_currant_black', title: 'Английские сливочные сконы к чаю с черной смородиной', f: 'flour', m: 'currant_black', a: 'cream', b: 'butter', d: 'sugar', e: 'baking_powder', c: 'uk' },
  { id: 'scones_savory_cheddar_green_onion', title: 'Сырные сконы с зеленым луком и сливочным маслом на завтрак', f: 'flour', m: 'hard_cheese', a: 'green_onion', b: 'butter', d: 'buttermilk', e: 'baking_powder', c: 'uk' },
  { id: 'madeleine_lemon_honey_shells', title: 'Французское бисквитное печенье Мадлен с медом и лимоном', f: 'flour', m: 'honey', a: 'lemon', b: 'butter', d: 'egg', e: 'sugar', c: 'fr', heatSec: 720 },
  { id: 'eclairs_custard_vanilla_cream', title: 'Домашние заварные профитроли со сливочным ванильным кремом', f: 'flour', m: 'butter', a: 'milk', b: 'egg', d: 'vanilla', e: 'sugar', c: 'fr' },
  { id: 'meringue_kisses_almond_sugar', title: 'Хрустящие безе с рубленым миндалем к ароматному чаю', f: 'egg', m: 'sugar', a: 'almond', b: 'vanilla', d: 'lemon', e: 'starch', c: 'fr', heatSec: 2700 },
  { id: 'sochniki_cottage_cheese_soft', title: 'Мягкие песочные сочники с творожной начинкой из школьной столовой', f: 'flour', m: 'cottage_cheese', a: 'sour_cream', b: 'butter', d: 'egg', e: 'sugar', c: 'ru' },
  { id: 'orehki_condensed_milk_cookies', title: 'Любимые хрустящие орешки из детства со сгущенкой и орехом', f: 'flour', m: 'condensed_milk', a: 'walnut', b: 'butter', d: 'egg', e: 'sugar', c: 'ru' },
  { id: 'cookies_rye_honey_ginger', title: 'Полезное ржаное печенье на меду со специями и орешками', f: 'rye_flour', m: 'honey', a: 'butter', b: 'ginger', d: 'hazelnut', e: 'baking_soda', c: 'ru' },
  { id: 'cookies_wholegrain_cranberry_oats', title: 'Фитнес-печенье из цельнозерновой муки с овсянкой и клюквой', f: 'wholegrain_flour', m: 'rolled_oats', a: 'cranberry', b: 'honey', d: 'sunflower_oil', e: 'egg', c: 'home' },
  { id: 'cookies_pumpkin_spice_soft', title: 'Мягкое тыквенное печенье с мускатным орехом и корицей', f: 'flour', m: 'squash', a: 'nutmeg', b: 'cinnamon', d: 'butter', e: 'egg', c: 'us' },
  { id: 'cookies_pear_chocolate_chunks', title: 'Нежное бисквитное печенье с кубиками груши и шоколадом', f: 'flour', m: 'pear', a: 'chocolate', b: 'butter', d: 'egg', e: 'sugar', c: 'home' }
];

for (const it of cookiesMuffins) {
  addBaking({
    id: it.id,
    title: it.title,
    cuisine: it.c,
    time: 40,
    active: 20,
    heatSec: it.heatSec || 1200,
    desc: `Ароматное домашнее печенье или кексы «${it.title}» к чаю или кофе.`,
    ings: [
      { ingredient_id: it.f, amount: 220, unit: 'g' },
      it.m,
      it.a,
      it.b,
      it.d,
      it.e
    ]
  });
}

// 4. Breads, Buns, Rolls, Flatbreads, Bagels (35)
const breadsBuns = [
  { id: 'cinnabon_cinnamon_cream_rolls', title: 'Воздушные булочки синнабон с корицей и сливочным сыром', f: 'flour', m: 'cinnamon', a: 'cream_cheese', b: 'butter', d: 'milk', e: 'yeast', c: 'us' },
  { id: 'poppy_sugar_buns_sverdlovsky', title: 'Пышные сдобные плюшки-сердечки с сахаром и маком', f: 'flour', m: 'poppy_seeds', a: 'butter', b: 'milk', d: 'egg', e: 'yeast', c: 'ru' },
  { id: 'vatrushka_cottage_raisins_bun', title: 'Сдобная русская ватрушка с нежным творогом и изюмом', f: 'flour', m: 'cottage_cheese', a: 'raisins', b: 'milk', d: 'egg', e: 'yeast', c: 'ru' },
  { id: 'bread_rye_borodinsky_coriander', title: 'Домашний ароматный ржаной хлеб с кориандром и тмином', f: 'rye_flour', m: 'flour', a: 'coriander', b: 'cumin', d: 'honey', e: 'yeast', c: 'ru' },
  { id: 'bread_garlic_butter_pampushki', title: 'Мягкие украинские чесночные пампушки с укропом к борщу', f: 'flour', m: 'garlic', a: 'dill', b: 'sunflower_oil', d: 'yeast', e: 'sugar', c: 'ua' },
  { id: 'bread_onion_walnut_artisan', title: 'Хрустящий деревенский хлеб с жареным луком и грецким орехом', f: 'flour', m: 'onion', a: 'walnut', b: 'olive_oil', d: 'yeast', e: 'rye_flour', c: 'fr' },
  { id: 'bread_sunflower_pumpkin_seeds', title: 'Цельнозерновой домашний хлеб с тыквенными и подсолнечными семечками', f: 'wholegrain_flour', m: 'sunflower_seeds', a: 'pumpkin_seeds', b: 'honey', d: 'yeast', e: 'olive_oil', c: 'de' },
  { id: 'bread_brioche_butter_eggs', title: 'Сдобная французская бриошь на яйцах с маслом и цедрой апельсина', f: 'flour', m: 'butter', a: 'egg', b: 'milk', d: 'orange', e: 'yeast', c: 'fr' },
  { id: 'bread_challah_sesame_braided', title: 'Праздничная плетеная хала с кунжутом и медом', f: 'flour', m: 'sesame', a: 'honey', b: 'egg', d: 'sunflower_oil', e: 'yeast', c: 'home' },
  { id: 'bread_irish_soda_kefir_quick', title: 'Быстрый ирландский содовый хлеб на кефире без дрожжей', f: 'flour', m: 'wholegrain_flour', a: 'kefir', b: 'baking_soda', d: 'butter', e: 'oatmeal', c: 'uk' },
  { id: 'bread_naan_garlic_butter_pan', title: 'Мягкие индийские лепешки наан с чесноком и кинзой на сковороде', f: 'flour', m: 'yogurt', a: 'garlic', b: 'butter', d: 'cilantro', e: 'yeast', c: 'in', verb: 'обжаривайте на сухой сковороде', heatSec: 600 },
  { id: 'bread_pita_pocket_homemade', title: 'Домашние полые питы в духовке для шаурмы и сэндвичей', f: 'flour', m: 'yeast', a: 'olive_oil', b: 'sugar', d: 'water', e: 'wholegrain_flour', c: 'gr', heatSec: 600 },
  { id: 'bread_tortilla_homemade_corn', title: 'Домашние мягкие лепешки тортилья на кукурузной и пшеничной муке', f: 'flour', m: 'cornmeal', a: 'butter', b: 'water', d: 'baking_powder', e: 'salt', c: 'mx', verb: 'обжаривайте на сухой сковороде', heatSec: 480 },
  { id: 'bread_shoti_georgian_crispy', title: 'Хрустящий грузинский хлеб шоти с золотистой корочкой', f: 'flour', m: 'yeast', a: 'water', b: 'olive_oil', d: 'sugar', e: 'sesame', c: 'ge' },
  { id: 'bread_bagels_sesame_boiled', title: 'Упругие бейглы с маком и кунжутом, сваренные в медовой воде', f: 'flour', m: 'honey', a: 'sesame', b: 'poppy_seeds', d: 'yeast', e: 'olive_oil', c: 'us' },
  { id: 'bread_pretzels_crispy_salt', title: 'Немецкие хрустящие брецели с крупной солью и тмином', f: 'flour', m: 'butter', a: 'baking_soda', b: 'cumin', d: 'milk', e: 'yeast', c: 'de' },
  { id: 'buns_apple_caramel_sticky', title: 'Карамельные булочки-улитки с печеным яблоком и орехами', f: 'flour', m: 'apple', a: 'caramel', b: 'walnut', d: 'butter', e: 'yeast', c: 'home' },
  { id: 'buns_cherry_puff_envelopes', title: 'Слоеные хрустящие конвертики с вишней и ванильным сахаром', f: 'flour', m: 'cherry', a: 'butter', b: 'vanilla_sugar', d: 'starch', e: 'egg', c: 'home' },
  { id: 'buns_apricot_jam_croissants', title: 'Домашние круассаны или рогалики с густым повидлом', f: 'flour', m: 'jam', a: 'butter', b: 'sour_cream', d: 'yeast', e: 'egg', c: 'ru' },
  { id: 'buns_milk_butter_french', title: 'Нежные утренние молочные булочки с капелькой ванили', f: 'flour', m: 'milk', a: 'butter', b: 'egg', d: 'vanilla_sugar', e: 'yeast', c: 'fr' },
  { id: 'khvorost_crispy_kefir', title: 'Хрустящий воздушный хворост на кефире с пудрой', f: 'flour', m: 'kefir', a: 'egg', b: 'sugar', d: 'baking_soda', e: 'sunflower_oil', c: 'ru', verb: 'обжаривайте в раскаленном масле', heatSec: 480 },
  { id: 'ponchiki_cottage_cheese_fried', title: 'Нежные жареные творожные пончики с корицей и пудрой', f: 'flour', m: 'cottage_cheese', a: 'egg', b: 'cinnamon', d: 'baking_soda', e: 'sunflower_oil', c: 'ru', verb: 'обжаривайте со всех сторон', heatSec: 600 },
  { id: 'chak_chak_honey_tatar', title: 'Традиционный татарский чак-чак в тягучем медовом сиропе', f: 'flour', m: 'egg', a: 'honey', b: 'sugar', d: 'walnut', e: 'sunflower_oil', c: 'ru', verb: 'обжаривайте кусочки теста', heatSec: 600 },
  { id: 'bread_chebureki_cheese_herbs', title: 'Хрустящие янтыки с сыром, томатами и кинзой на сухой сковороде', f: 'flour', m: 'feta', a: 'tomato', b: 'cilantro', d: 'butter', e: 'salt', c: 'ru', verb: 'обжаривайте без масла на сковороде', heatSec: 600 },
  { id: 'bread_kazy_flatbread_potato', title: 'Тонкие картофельные лепешки кыстыбый со сливочным маслом', f: 'flour', m: 'potato', a: 'butter', b: 'milk', d: 'onion', e: 'dill', c: 'ru', verb: 'обжаривайте на сухой сковороде', heatSec: 480 },
  { id: 'bread_zucchini_dill_scone', title: 'Быстрый закусочный хлеб с тертым кабачком, укропом и сыром', f: 'flour', m: 'zucchini', a: 'hard_cheese', b: 'dill', d: 'egg', e: 'baking_powder', c: 'home' },
  { id: 'bread_olive_herb_skillet', title: 'Ароматная лепешка в сковороде с оливками, орегано и ароматным чесноком', f: 'flour', m: 'olives', a: 'oregano', b: 'garlic', d: 'olive_oil', e: 'yeast', c: 'gr' },
  { id: 'bread_pumpkin_puree_loaf', title: 'Солнечный мягкий тыквенный хлеб к супам с семечками', f: 'flour', m: 'squash', a: 'pumpkin_seeds', b: 'butter', d: 'honey', e: 'yeast', c: 'home' },
  { id: 'bread_carrot_rye_healthy', title: 'Морковно-ржаной цельнозерновой батон со льном и семечками', f: 'rye_flour', m: 'carrot', a: 'sunflower_seeds', b: 'honey', d: 'yeast', e: 'sunflower_oil', c: 'ru' },
  { id: 'buns_cardamom_swedish_fika', title: 'Шведские скрученные булочки с кардамоном и маслом', f: 'flour', m: 'cardamom', a: 'butter', b: 'milk', d: 'sugar', e: 'yeast', c: 'home' },
  { id: 'buns_lemon_curd_sweet', title: 'Сладкие булочки-бриоши с нежным лимонным кремом и яйцом', f: 'flour', m: 'lemon', a: 'butter', b: 'egg', d: 'milk', e: 'yeast', c: 'fr' },
  { id: 'buns_peach_ricotta_tartlets', title: 'Песочные корзиночки-тарталетки с творогом и персиком', f: 'flour', m: 'peach', a: 'cottage_cheese', b: 'butter', d: 'egg', e: 'sugar', c: 'home' },
  { id: 'buns_chocolate_banana_croissant', title: 'Домашние слоеные рогалики с шоколадом и кусочком банана', f: 'flour', m: 'chocolate', a: 'banana', b: 'butter', d: 'egg', e: 'yeast', c: 'fr' },
  { id: 'bread_garlic_cheese_pull_apart', title: 'Отрывной чесночный хлеб обезьяний с моцареллой и петрушкой', f: 'flour', m: 'mozzarella', a: 'garlic', b: 'parsley', d: 'butter', e: 'yeast', c: 'us' },
  { id: 'bread_potato_rosemary_loaf', title: 'Пышный итальянский картофельный хлеб с розмарином и маслом', f: 'flour', m: 'potato', a: 'rosemary', b: 'olive_oil', d: 'yeast', e: 'sugar', c: 'it' }
];

for (const it of breadsBuns) {
  addBaking({
    id: it.id,
    title: it.title,
    cuisine: it.c,
    time: 70,
    active: 25,
    verb: it.verb,
    heatSec: it.heatSec || 1500,
    desc: `Ароматный домашний хлеб или сдобные булочки «${it.title}».`,
    ings: [
      { ingredient_id: it.f, amount: 400, unit: 'g' },
      it.m,
      it.a,
      it.b,
      it.d,
      it.e
    ]
  });
}

// 5. Pancakes, Bliny, Crepes, Oladi & Waffles (20)
const pancakesWaffles = [
  { id: 'bliny_yeast_milk_classic', title: 'Кружевные русские дрожжевые блины на молоке со сметаной', f: 'flour', m: 'milk', a: 'yeast', b: 'egg', d: 'butter', e: 'sour_cream', c: 'ru' },
  { id: 'bliny_kefir_boiling_water', title: 'Тонкие заварные блины на кефире в дырочку со сметаной', f: 'flour', m: 'kefir', a: 'baking_soda', b: 'egg', d: 'sour_cream', e: 'sunflower_oil', c: 'ru' },
  { id: 'bliny_buckwheat_french_galette', title: 'Бретонские гречневые блины с сыром, ветчиной и яйцом', f: 'buckwheat', m: 'flour', a: 'hard_cheese', b: 'ham', d: 'egg', e: 'milk', c: 'fr' },
  { id: 'blinchiki_cottage_raisins_stuffed', title: 'Домашние блинчики, начиненные сладким творогом с изюмом', f: 'flour', m: 'cottage_cheese', a: 'raisins', b: 'milk', d: 'egg', e: 'butter', c: 'ru' },
  { id: 'blinchiki_apple_cinnamon_rolled', title: 'Тонкие блинчики с карамельными яблоками и корицей', f: 'flour', m: 'apple', a: 'cinnamon', b: 'butter', d: 'milk', e: 'egg', c: 'ru' },
  { id: 'blinchiki_liver_pate_fried_onion', title: 'Сытные блинчики, фаршированные печеночным паштетом и луком', f: 'flour', m: 'liver_chicken', a: 'onion', b: 'milk', d: 'egg', e: 'butter', c: 'ru', heatSec: 900 },
  { id: 'blinchiki_champignon_cream_cheese', title: 'Закусочные блинчики с жареными шампиньонами и сливочным сыром', f: 'flour', m: 'champignon', a: 'cream_cheese', b: 'milk', d: 'egg', e: 'dill', c: 'ru' },
  { id: 'crepes_suzette_orange_butter', title: 'Французские блинчики креп сюзетт в апельсиновой карамели', f: 'flour', m: 'orange', a: 'butter', b: 'sugar', d: 'milk', e: 'egg', c: 'fr' },
  { id: 'crepes_spinach_feta_green', title: 'Яркие зеленые блинчики со шпинатом, фетой и укропом', f: 'flour', m: 'spinach', a: 'feta', b: 'dill', d: 'milk', e: 'egg', c: 'home' },
  { id: 'crepes_cocoa_chocolate_banana', title: 'Шоколадные тонкие блинчики с бананом и сгущенным молоком', f: 'flour', m: 'cocoa', a: 'banana', b: 'condensed_milk', d: 'milk', e: 'egg', c: 'home' },
  { id: 'oladi_banana_oatmeal_healthy', title: 'Полезные овсяно-банановые панкейки без пшеничной муки и сахара', f: 'rolled_oats', m: 'banana', a: 'egg', b: 'milk', d: 'cinnamon', e: 'butter', c: 'home' },
  { id: 'oladi_pumpkin_sour_cream_spicy', title: 'Ароматные тыквенные оладьи на кефире со специями', f: 'flour', m: 'squash', a: 'kefir', b: 'nutmeg', d: 'egg', e: 'baking_soda', c: 'ru' },
  { id: 'oladi_cabbage_dill_savory', title: 'Румяные несладкие оладьи с молодой капустой и зеленью', f: 'flour', m: 'cabbage', a: 'dill', b: 'kefir', d: 'egg', e: 'baking_soda', c: 'ru' },
  { id: 'oladi_beet_sweet_vanilla', title: 'Необычные розовые оладьи со свеклой, медом и ванилью', f: 'flour', m: 'beet', a: 'honey', b: 'vanilla_sugar', d: 'kefir', e: 'egg', c: 'home' },
  { id: 'oladi_corn_sweet_honey', title: 'Солнечные панкейки из кукурузной крупы с ягодами и медом', f: 'cornmeal', m: 'flour', a: 'blueberry', b: 'honey', d: 'milk', e: 'egg', c: 'us' },
  { id: 'waffles_belgian_crispy_vanilla', title: 'Хрустящие венские или бельгийские вафли на сливочном масле', f: 'flour', m: 'butter', a: 'milk', b: 'egg', d: 'sugar', e: 'vanilla_sugar', c: 'home' },
  { id: 'waffles_cottage_cheese_raspberry', title: 'Мягкие творожные вафли к завтраку со свежей малиной', f: 'flour', m: 'cottage_cheese', a: 'raspberry', b: 'egg', d: 'butter', e: 'baking_powder', c: 'home' },
  { id: 'waffles_savory_potato_cheese', title: 'Хрустящие картофельные вафли с сыром, чесноком и укропом', f: 'potato', m: 'hard_cheese', a: 'flour', b: 'garlic', d: 'egg', e: 'dill', c: 'home' },
  { id: 'waffles_chocolate_peanut_cream', title: 'Шоколадные вафли с арахисом и карамельным сиропом', f: 'flour', m: 'cocoa', a: 'peanut', b: 'caramel', d: 'milk', e: 'egg', c: 'us' },
  { id: 'dutch_baby_oven_berry_pancake', title: 'Пышный голландский блин в духовке с клубникой и пудрой', f: 'flour', m: 'strawberry', a: 'milk', b: 'butter', d: 'egg', e: 'vanilla', c: 'us', verb: 'запекайте в разогретой сковороде в духовке', heatSec: 1200 }
];

for (const it of pancakesWaffles) {
  addBaking({
    id: it.id,
    title: it.title,
    cuisine: it.c,
    time: 35,
    active: 20,
    verb: it.verb || 'обжаривайте на сковороде или в вафельнице',
    heatSec: it.heatSec || 600,
    desc: `Аппетитные домашние блины, оладьи или вафли «${it.title}».`,
    ings: [
      { ingredient_id: it.f, amount: 220, unit: 'g' },
      it.m,
      it.a,
      it.b,
      it.d,
      it.e
    ]
  });
}

console.log(`Total generated baking dishes: ${allBaking.length}`);
saveAndValidateGroup('baking.json', allBaking);
