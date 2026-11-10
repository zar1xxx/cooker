const { saveAndValidateGroup, smartIngredient } = require('./recipe_builder');

function s(text, timer_seconds, tip) {
  const step = { text: text.trim() };
  if (timer_seconds) step.timer_seconds = timer_seconds;
  if (tip) step.tip = tip;
  return step;
}

const allPorridge = [];

function addPorridge(def) {
  const id = `porridge_${def.id}`;
  const title = def.title;
  const time = def.time || 30;
  const active = def.active || 15;
  const servings = def.servings || 4;
  const cuisine = def.cuisine || 'home';
  const dishType = def.dish_type || 'side';
  const desc = def.desc || `Сытное блюдо из крупы или пасты «${title}» по проверенному домашнему рецепту.`;

  const ingsMap = new Map();
  for (const raw of def.ings) {
    const rawId = raw.ingredient_id || raw.id || raw;
    const ingObj = smartIngredient(rawId, raw.amount, raw.unit);
    ingsMap.set(rawId, ingObj);
  }
  const ings = Array.from(ingsMap.values());
  const hasEgg = ingsMap.has('egg');

  let heatVerb = def.verb || 'варите на медленном огне';
  if (hasEgg && !['вар', 'жар', 'запек'].some(k => heatVerb.toLowerCase().includes(k))) {
    heatVerb = 'запекайте в духовке';
  }
  const heatSec = def.heatSec || (hasEgg ? 900 : 720);
  const heatMin = Math.ceil(heatSec / 60);
  const eggNote = hasEgg ? ' со взбитым яйцом' : '';

  const steps = def.steps || [
    s(`Для приготовления блюда «${title}» тщательно подготовьте крупу или макароны, а добавки промойте и обсушите.`),
    s(`Отмерьте нужное количество жидкости и специй для «${title}», доведите основу до слабого кипения в кастрюле или сотейнике.`),
    s(`${heatVerb.charAt(0).toUpperCase() + heatVerb.slice(1)} основу${eggNote} для «${title}» около ${heatMin} минут, помешивая до мягкости.`, heatSec),
    s(`Заправьте готовое блюдо «${title}» перед подачей и разложите теплым по тарелкам.`)
  ];

  allPorridge.push({
    id: id,
    title: title,
    dish_type: dishType,
    dish_group: 'porridge_side',
    cuisine: cuisine,
    total_minutes: time,
    active_minutes: active,
    servings: servings,
    description: desc,
    ingredients: ings,
    steps: steps
  });
}

// 1. Sweet Morning Porridges (55, dish_type: 'breakfast')
const sweetPorridges = [
  { id: 'oatmeal_apple_cinnamon', title: 'Овсяная каша на молоке с печеным яблоком и корицей', g: 'oatmeal', liq: 'milk', a: 'apple', b: 'cinnamon', c: 'ru' },
  { id: 'oatmeal_banana_walnut', title: 'Овсяная каша с бананом, медом и грецким орехом', g: 'oatmeal', liq: 'milk', a: 'banana', b: 'walnut', c: 'home' },
  { id: 'oatmeal_blueberry_honey', title: 'Утренняя овсянка со свежей черникой и майским медом', g: 'rolled_oats', liq: 'milk', a: 'blueberry', b: 'honey', c: 'home' },
  { id: 'oatmeal_raspberry_coconut', title: 'Кокосовая овсяная каша с малиной и стружкой', g: 'oatmeal', liq: 'coconut_milk', a: 'raspberry', b: 'coconut_flakes', c: 'home' },
  { id: 'oatmeal_pear_cardamom', title: 'Душистая овсяная каша с медовой грушей и кардамоном', g: 'rolled_oats', liq: 'milk', a: 'pear', b: 'cardamom', c: 'home' },
  { id: 'oatmeal_strawberry_chocolate', title: 'Шоколадная овсянка на молоке с какао и клубникой', g: 'oatmeal', liq: 'milk', a: 'cocoa', b: 'strawberry', c: 'home' },
  { id: 'oatmeal_prunes_hazelnut', title: 'Питательная овсянка на воде с черносливом и фундуком', g: 'rolled_oats', liq: 'water', a: 'prunes', b: 'hazelnut', c: 'home' },
  { id: 'oatmeal_apricots_almond', title: 'Овсяная каша с курагой и миндальными лепестками', g: 'oatmeal', liq: 'milk', a: 'dried_apricots', b: 'almond', c: 'ru' },
  { id: 'oatmeal_cherry_vanilla', title: 'Нежная овсянка с вишней, ванильным сахаром и сливками', g: 'rolled_oats', liq: 'cream', a: 'cherry', b: 'vanilla_sugar', c: 'home' },
  { id: 'oatmeal_squash_nutmeg', title: 'Солнечная овсяная каша с тертой тыквой и мускатным орехом', g: 'oatmeal', liq: 'milk', a: 'squash', b: 'nutmeg', c: 'ru' },
  { id: 'oatmeal_cranberry_orange', title: 'Овсянка с клюквой, апельсиновой цедрой и сиропом', g: 'rolled_oats', liq: 'water', a: 'cranberry', b: 'orange', c: 'home' },
  { id: 'oatmeal_baked_raisins_egg', title: 'Запеченная овсянка с изюмом и яблоками в духовке', g: 'rolled_oats', liq: 'milk', a: 'raisins', b: 'egg', c: 'uk', v: 'запекайте в духовке', heatSec: 1200 },
  { id: 'millet_pumpkin_classic', title: 'Классическая пшенная каша с тыквой на топленом молоке', g: 'millet', liq: 'milk', a: 'squash', b: 'butter', c: 'ru' },
  { id: 'millet_raisins_honey', title: 'Рассыпчатая пшенная каша с изюмом и цветочным медом', g: 'millet', liq: 'milk', a: 'raisins', b: 'honey', c: 'ru' },
  { id: 'millet_baked_pot_apple', title: 'Томленая пшенная каша в горшочке с печеными яблоками', g: 'millet', liq: 'milk', a: 'apple', b: 'cinnamon', c: 'ru', v: 'запекайте в духовке' },
  { id: 'millet_peach_almond', title: 'Пшенная молочная каша со сладкими персиками и миндалем', g: 'millet', liq: 'milk', a: 'peach', b: 'almond', c: 'home' },
  { id: 'millet_apricots_butter', title: 'Золотистая пшенная каша с курагой и сливочным маслом', g: 'millet', liq: 'water', a: 'dried_apricots', b: 'butter', c: 'ru' },
  { id: 'millet_currant_condensed', title: 'Пшенная каша на молоке со сгущенкой и черной смородиной', g: 'millet', liq: 'milk', a: 'condensed_milk', b: 'currant_black', c: 'ru' },
  { id: 'rice_milk_pumpkin_honey', title: 'Нежная рисовая каша с тыквой и медом в кастрюле', g: 'round_rice', liq: 'milk', a: 'squash', b: 'honey', c: 'ru' },
  { id: 'rice_milk_raisins_vanilla', title: 'Сливочная рисовая каша с изюмом и щепоткой ванили', g: 'round_rice', liq: 'milk', a: 'raisins', b: 'vanilla', c: 'ru' },
  { id: 'rice_mango_coconut_thai', title: 'Сладкий тайский рис в кокосовом молоке с грушей', g: 'basmati_rice', liq: 'coconut_milk', a: 'pear', b: 'sesame', c: 'th' },
  { id: 'rice_apple_caramel_butter', title: 'Рисовая молочная каша с карамелизованными яблоками', g: 'round_rice', liq: 'milk', a: 'apple', b: 'sugar', c: 'ru' },
  { id: 'rice_friendship_millet', title: 'Каша Дружба из риса и пшена на домашнем молоке', g: 'round_rice', liq: 'milk', a: 'millet', b: 'butter', c: 'ru' },
  { id: 'rice_cottage_baked_casserole', title: 'Запеченная рисовая каша с творогом и изюмом', g: 'round_rice', liq: 'milk', a: 'cottage_cheese', b: 'egg', c: 'ru', v: 'запекайте в духовке' },
  { id: 'rice_strawberry_jam_cream', title: 'Молочная рисовая каша со сливочным маслом и клубникой', g: 'round_rice', liq: 'milk', a: 'strawberry', b: 'cream', c: 'home' },
  { id: 'rice_dates_pistachio_cardamom', title: 'Восточная рисовая каша с финиками, фисташками и кардамоном', g: 'basmati_rice', liq: 'milk', a: 'dates', b: 'pistachio', c: 'uz' },
  { id: 'semolina_guriev_classic', title: 'Старинная гурьевская манная каша с орехами и пенками', g: 'semolina', liq: 'milk', a: 'walnut', b: 'jam', c: 'ru', v: 'запекайте в духовке' },
  { id: 'semolina_strawberry_jam', title: 'Воздушная манная каша без комочков с ягодным вареньем', g: 'semolina', liq: 'milk', a: 'jam', b: 'butter', c: 'ru' },
  { id: 'semolina_cocoa_chocolate', title: 'Шоколадная манная каша для сладкоежек с какао', g: 'semolina', liq: 'milk', a: 'cocoa', b: 'sugar', c: 'home' },
  { id: 'semolina_banana_coconut', title: 'Быстрая манная каша на кокосовом молоке с бананом', g: 'semolina', liq: 'coconut_milk', a: 'banana', b: 'vanilla_sugar', c: 'home' },
  { id: 'semolina_cherry_compote_sauce', title: 'Манная каша на молоке с теплым вишневым соусом', g: 'semolina', liq: 'milk', a: 'cherry', b: 'sugar', c: 'ru' },
  { id: 'semolina_poppy_seeds_honey', title: 'Густая манная каша с маком, медом и орехами', g: 'semolina', liq: 'milk', a: 'poppy_seeds', b: 'honey', c: 'ru' },
  { id: 'cornmeal_sweet_milk_butter', title: 'Кукурузная каша на молоке со сливочным маслом и медом', g: 'cornmeal', liq: 'milk', a: 'butter', b: 'honey', c: 'ru' },
  { id: 'cornmeal_pumpkin_orange', title: 'Золотая кукурузная каша с тыквой и апельсином', g: 'cornmeal', liq: 'milk', a: 'squash', b: 'orange', c: 'home' },
  { id: 'cornmeal_raisins_cottage', title: 'Кукурузная каша с изюмом и нежным творогом', g: 'cornmeal', liq: 'milk', a: 'raisins', b: 'cottage_cheese', c: 'ru' },
  { id: 'cornmeal_berries_yogurt', title: 'Теплая кукурузная каша с малиной и греческим йогуртом', g: 'cornmeal', liq: 'water', a: 'raspberry', b: 'yogurt', c: 'home' },
  { id: 'buckwheat_milk_sugar_childhood', title: 'Молочная гречневая каша с маслом по рецепту детства', g: 'buckwheat', liq: 'milk', a: 'butter', b: 'sugar', c: 'ru' },
  { id: 'buckwheat_dates_coconut', title: 'Полезная зеленая гречка на кокосовом молоке с финиками', g: 'buckwheat', liq: 'coconut_milk', a: 'dates', b: 'banana', c: 'home' },
  { id: 'buckwheat_apple_honey_stew', title: 'Сладкая рассыпчатая гречка с печеными яблоками и медом', g: 'buckwheat', liq: 'water', a: 'apple', b: 'honey', c: 'ru' },
  { id: 'buckwheat_prunes_walnut', title: 'Утренняя гречневая каша с распаренным черносливом и орехом', g: 'buckwheat', liq: 'water', a: 'prunes', b: 'walnut', c: 'ru' },
  { id: 'barley_milk_honey_butter', title: 'Ячневая каша на домашнем молоке с медом и маслом', g: 'barley', liq: 'milk', a: 'butter', b: 'honey', c: 'ru' },
  { id: 'barley_baked_squash_raisins', title: 'Томленая ячневая каша с тыквой и сладким изюмом', g: 'barley', liq: 'milk', a: 'squash', b: 'raisins', c: 'ru' },
  { id: 'pearl_barley_milk_pot', title: 'Царская перловая каша, томленная на молоке с маслом', g: 'pearl_barley', liq: 'milk', a: 'butter', b: 'sugar', c: 'ru' },
  { id: 'quinoa_coconut_blackberry', title: 'Сладкая каша из киноа с ежевикой и кокосовым молоком', g: 'quinoa', liq: 'coconut_milk', a: 'blackberry', b: 'honey', c: 'home' },
  { id: 'quinoa_apple_pecan_cinnamon', title: 'Теплый завтрак с киноа, грушей и жареным фундуком', g: 'quinoa', liq: 'milk', a: 'pear', b: 'hazelnut', c: 'home' },
  { id: 'couscous_dried_fruits_sweet', title: 'Быстрый утренний кускус на молоке с сухофруктами', g: 'couscous', liq: 'milk', a: 'dried_fruits', b: 'butter', c: 'home' },
  { id: 'couscous_persimmon_honey', title: 'Сладкий кускус на воде со спелой хурмой и медом', g: 'couscous', liq: 'water', a: 'persimmon', b: 'honey', c: 'home' },
  { id: 'bulgur_milk_apricots_pistachio', title: 'Пряная каша из булгура на молоке с курагой и фисташками', g: 'bulgur', liq: 'milk', a: 'dried_apricots', b: 'pistachio', c: 'tr' },
  { id: 'bulgur_cherry_cardamom', title: 'Молочный булгур с вишней, корицей и кардамоном', g: 'bulgur', liq: 'milk', a: 'cherry', b: 'cinnamon', c: 'tr' },
  { id: 'vermicelli_milk_sweet_butter', title: 'Молочный суп-каша с тонкой вермишелью и сливочным маслом', g: 'vermicelli', liq: 'milk', a: 'butter', b: 'sugar', c: 'ru' },
  { id: 'oatmeal_peanut_butter_banana', title: 'Питательная овсянка с измельченным арахисом и бананом', g: 'oatmeal', liq: 'milk', a: 'peanut', b: 'banana', c: 'us' },
  { id: 'oatmeal_pumpkin_seeds_cranberry', title: 'Полезная утренняя каша с тыквенными семечками и клюквой', g: 'rolled_oats', liq: 'water', a: 'pumpkin_seeds', b: 'cranberry', c: 'home' },
  { id: 'oatmeal_sunflower_halva_honey', title: 'Сытная овсянка со сладкой халвой и семечками подсолнуха', g: 'oatmeal', liq: 'milk', a: 'halva', b: 'sunflower_seeds', c: 'ru' },
  { id: 'oatmeal_gooseberry_curd', title: 'Овсяная каша с вареньем из крыжовника и кефиром', g: 'rolled_oats', liq: 'water', a: 'gooseberry', b: 'sugar', c: 'ru' },
  { id: 'semolina_blackberry_vanilla', title: 'Нежная манная каша со свежей ежевикой и ванилью', g: 'semolina', liq: 'milk', a: 'blackberry', b: 'vanilla', c: 'home' }
];

for (const it of sweetPorridges) {
  addPorridge({
    id: it.id,
    title: it.title,
    dish_type: 'breakfast',
    cuisine: it.c,
    time: 25,
    active: 10,
    verb: it.v || 'варите на медленном огне',
    heatSec: it.heatSec || 720,
    desc: `Аппетитная утренняя каша «${it.title}» для энергичного начала дня.`,
    ings: [
      { ingredient_id: it.g, amount: 160, unit: 'g' },
      it.liq,
      it.a,
      it.b,
      'salt'
    ]
  });
}

// 2. Savory Grain Sides, Risottos, Veg Pilafs, Polenta, Mash (55, dish_type: 'side')
const savorySides = [
  { id: 'buckwheat_champignon_onion', title: 'Рассыпчатая гречка с жареными шампиньонами и луком', g: 'buckwheat', a: 'champignon', b: 'onion', c: 'ru' },
  { id: 'buckwheat_carrot_garlic_herb', title: 'Гречневый гарнир с тертой морковью, чесноком и укропом', g: 'buckwheat', a: 'carrot', b: 'dill', c: 'ru' },
  { id: 'buckwheat_zucchini_tomato', title: 'Гречка по-деревенски с кабачками и сладким перцем', g: 'buckwheat', a: 'zucchini', b: 'bell_pepper', c: 'ru' },
  { id: 'buckwheat_spinach_feta', title: 'Теплая гречка со свежим шпинатом и раскрошенной фетой', g: 'buckwheat', a: 'spinach', b: 'feta', c: 'home' },
  { id: 'buckwheat_tomato_paste_egg', title: 'Гречка в томатном соусе, запеченная с яйцом', g: 'buckwheat', a: 'tomato_paste', b: 'egg', c: 'ru', v: 'запекайте в духовке' },
  { id: 'rice_veg_pilaf_uzbek', title: 'Овощной плов с нутом, морковью и пряной зирой', g: 'round_rice', a: 'chickpeas_canned', b: 'carrot', c: 'uz' },
  { id: 'rice_turmeric_corn_peas', title: 'Золотистый рис с кукурузой, зеленым горошком и куркумой', g: 'basmati_rice', a: 'corn_canned', b: 'green_peas', c: 'home' },
  { id: 'rice_risotto_mushrooms_parmesan', title: 'Итальянское ризотто с шампиньонами и сыром пармезан', g: 'round_rice', a: 'champignon', b: 'parmesan', c: 'it' },
  { id: 'rice_risotto_pumpkin_sage', title: 'Кремовое ризотто с печеной тыквой и розмарином', g: 'round_rice', a: 'squash', b: 'rosemary', c: 'it' },
  { id: 'rice_risotto_spinach_butter', title: 'Зеленое ризотто со шпинатом, чесноком и сливочным маслом', g: 'round_rice', a: 'spinach', b: 'butter', c: 'it' },
  { id: 'rice_fried_egg_green_onion', title: 'Жареный рис по-китайски с яйцом и зеленым луком', g: 'basmati_rice', a: 'egg', b: 'green_onion', c: 'cn', v: 'обжаривайте в воке' },
  { id: 'rice_basmati_garlic_cilantro', title: 'Рассыпчатый рис с лаймом, чесноком и свежей кинзой', g: 'basmati_rice', a: 'lime', b: 'cilantro', c: 'mx' },
  { id: 'rice_indian_jeera_peas', title: 'Индийский рис джира пулао с зирой и зеленым горошком', g: 'basmati_rice', a: 'cumin', b: 'green_peas', c: 'in' },
  { id: 'rice_shiitake_soy_sesame', title: 'Жареный рис по-японски с грибами шиитаке и ароматным кунжутом', g: 'round_rice', a: 'shiitake', b: 'soy_sauce', c: 'jp', v: 'обжаривайте в сковороде' },
  { id: 'rice_beans_caribbean', title: 'Рисовый гарнир с красной фасолью и кокосовым молоком', g: 'basmati_rice', a: 'beans_canned', b: 'coconut_milk', c: 'home' },
  { id: 'bulgur_tomato_bell_pepper', title: 'Турецкий плов из булгура с томатами и сладким перцем', g: 'bulgur', a: 'tomato_paste', b: 'bell_pepper', c: 'tr' },
  { id: 'bulgur_eggplant_mint', title: 'Рассыпчатый булгур с жареным баклажаном и мятой', g: 'bulgur', a: 'eggplant', b: 'mint', c: 'tr' },
  { id: 'bulgur_mushroom_carrot', title: 'Гарнир из булгура с вешенками, луком и морковью', g: 'bulgur', a: 'oyster_mushroom', b: 'carrot', c: 'home' },
  { id: 'bulgur_broccoli_lemon', title: 'Полезный булгур с соцветиями брокколи и соком лимона', g: 'bulgur', a: 'broccoli', b: 'lemon', c: 'home' },
  { id: 'bulgur_chickpeas_coriander', title: 'Сытный булгур с нутом, тмином и свежим кориандром', g: 'bulgur', a: 'chickpeas_canned', b: 'coriander', c: 'tr' },
  { id: 'couscous_roasted_zucchini', title: 'Марокканский кускус с печеными кабачками и куркумой', g: 'couscous', a: 'zucchini', b: 'turmeric', c: 'home' },
  { id: 'couscous_olives_cherry_tomato', title: 'Средиземноморский кускус с маслинами и помидорами черри', g: 'couscous', a: 'olives', b: 'cherry_tomato', c: 'it' },
  { id: 'couscous_raisins_almond', title: 'Праздничный восточный кускус с изюмом и жареным миндалем', g: 'couscous', a: 'raisins', b: 'almond', c: 'home' },
  { id: 'couscous_spinach_feta_garlic', title: 'Быстрый кускус с раскрошенной фетой и шпинатом', g: 'couscous', a: 'feta', b: 'spinach', c: 'gr' },
  { id: 'couscous_green_peas_mint', title: 'Легкий кускус с зеленым горошком, лимоном и мятой', g: 'couscous', a: 'green_peas', b: 'mint', c: 'home' },
  { id: 'quinoa_bell_pepper_corn', title: 'Гарнир из киноа со сладкой кукурузой и паприкой', g: 'quinoa', a: 'corn_canned', b: 'bell_pepper', c: 'mx' },
  { id: 'quinoa_mushrooms_thyme', title: 'Рассыпчатая киноа с жареными шампиньонами и тимьяном', g: 'quinoa', a: 'champignon', b: 'thyme', c: 'home' },
  { id: 'quinoa_asparagus_parmesan', title: 'Киноа с хрустящей зеленой спаржей и пармезаном', g: 'quinoa', a: 'asparagus', b: 'parmesan', c: 'home' },
  { id: 'quinoa_beet_walnut', title: 'Теплое киноа с печеной свеклой и грецким орехом', g: 'quinoa', a: 'beet', b: 'walnut', c: 'home' },
  { id: 'quinoa_soy_edamame_ginger', title: 'Азиатский боул с киноа, бобами и свежим имбирем', g: 'quinoa', a: 'soybeans', b: 'ginger', c: 'jp', heatSec: 2400 },
  { id: 'pearl_barley_orsotto_mushrooms', title: 'Кремовое перлотто с вешенками и твердым сыром', g: 'pearl_barley', a: 'oyster_mushroom', b: 'hard_cheese', c: 'it' },
  { id: 'pearl_barley_pumpkin_garlic', title: 'Перловая каша в горшочке с печеной тыквой и чесноком', g: 'pearl_barley', a: 'squash', b: 'garlic', c: 'ru' },
  { id: 'pearl_barley_sauerkraut_onion', title: 'Сытная перловка с тушеной квашеной капустой', g: 'pearl_barley', a: 'sauerkraut', b: 'onion', c: 'ru' },
  { id: 'pearl_barley_carrot_leek', title: 'Ароматный гарнир из перловки с пореем и морковью', g: 'pearl_barley', a: 'leek', b: 'carrot', c: 'home' },
  { id: 'barley_savory_butter_dill', title: 'Рассыпчатая ячневая каша на воде со свежим укропом', g: 'barley', a: 'butter', b: 'dill', c: 'ru' },
  { id: 'barley_tomato_garlic_skillet', title: 'Пряная ячневая каша в сковороде с томатной пастой', g: 'barley', a: 'tomato_paste', b: 'garlic', c: 'home' },
  { id: 'millet_mushroom_fried_onion', title: 'Рассыпчатое пшено с жареными шампиньонами и маслом', g: 'millet', a: 'champignon', b: 'butter', c: 'ru' },
  { id: 'millet_cabbage_carrot_pilaf', title: 'Деревенский гарнир из пшена с тушеной капустой', g: 'millet', a: 'cabbage', b: 'carrot', c: 'ru' },
  { id: 'polenta_classic_parmesan', title: 'Итальянская кремовая полента с сыром пармезан', g: 'cornmeal', a: 'parmesan', b: 'butter', c: 'it' },
  { id: 'polenta_grilled_mushrooms', title: 'Запеченная кукурузная полента с грибами и тимьяном', g: 'cornmeal', a: 'champignon', b: 'thyme', c: 'it', v: 'запекайте в духовке' },
  { id: 'mamalyga_feta_butter', title: 'Молдавская мамалыга со сливочным маслом и брынзой', g: 'cornmeal', a: 'feta', b: 'sour_cream', c: 'home' },
  { id: 'polenta_tomato_herb_ragu', title: 'Мягкая кукурузная каша с томатным соусом и базиликом', g: 'cornmeal', a: 'tomato_sauce', b: 'basil', c: 'it' },
  { id: 'potato_mash_nutmeg_cheese', title: 'Нежное картофельное пюре с мускатным орехом и сыром', g: 'potato', a: 'hard_cheese', b: 'nutmeg', c: 'fr' },
  { id: 'potato_mash_garlic_cream', title: 'Сливочное пюре с печеным чесноком и укропом', g: 'potato', a: 'cream', b: 'dill', c: 'home' },
  { id: 'potato_mash_green_peas_wasabi', title: 'Изумрудное картофельное пюре с зеленым горошком', g: 'potato', a: 'green_peas', b: 'mint', c: 'uk' },
  { id: 'potato_mash_celery_root', title: 'Нежное пюре из картофеля и корня сельдерея', g: 'potato', a: 'celery_root', b: 'sour_cream', c: 'fr' },
  { id: 'rice_carrot_bell_pepper_oven', title: 'Запеченный в духовке рис со сладким перцем и морковью', g: 'rice', a: 'bell_pepper', b: 'carrot', c: 'home', v: 'запекайте в духовке' },
  { id: 'rice_lentils_green_kitchari', title: 'Аюрведическое кичари из риса басмати и маша', g: 'basmati_rice', a: 'mung_beans', b: 'turmeric', c: 'in', heatSec: 1500 },
  { id: 'rice_cabbage_lazy_pilaf', title: 'Сытный постный плов с рисом и молодой капустой', g: 'round_rice', a: 'cabbage', b: 'tomato_paste', c: 'ru' },
  { id: 'oatmeal_savory_cheese_egg', title: 'Несладкая овсянка по-домашнему с тертым сыром и яйцом', g: 'rolled_oats', a: 'hard_cheese', b: 'egg', c: 'home', v: 'обжаривайте яйцо с овсянкой' },
  { id: 'oatmeal_savory_mushroom_thyme', title: 'Пикантная овсяная каша с шампиньонами и тимьяном', g: 'oatmeal', a: 'champignon', b: 'thyme', c: 'home' },
  { id: 'buckwheat_cabbage_carrot_pot', title: 'Рассыпчатая гречневая каша с капустой в горшочке', g: 'buckwheat', a: 'cabbage', b: 'tomato_sauce', c: 'ru' },
  { id: 'rice_eggplant_soy_side', title: 'Теплый рис с тушеным баклажаном в соевом соусе', g: 'round_rice', a: 'eggplant', b: 'soy_sauce', c: 'cn' },
  { id: 'bulgur_pumpkin_sage_side', title: 'Ароматный булгур со сладкой тыквой и розмарином', g: 'bulgur', a: 'squash', b: 'rosemary', c: 'home' },
  { id: 'couscous_beets_cilantro', title: 'Пестрый кускус с запеченной свеклой и кинзой', g: 'couscous', a: 'beet', b: 'cilantro', c: 'home' }
];

for (const it of savorySides) {
  addPorridge({
    id: it.id,
    title: it.title,
    dish_type: 'side',
    cuisine: it.c,
    time: 35,
    active: 15,
    verb: it.v || 'варите и тушите',
    heatSec: it.heatSec || 900,
    desc: `Ароматный гарнир из круп и овощей «${it.title}» к мясу, рыбе или как самостоятельное блюдо.`,
    ings: [
      { ingredient_id: it.g, amount: 250, unit: 'g' },
      it.a,
      it.b,
      'sunflower_oil',
      'water',
      'salt'
    ]
  });
}

// 3. Pasta, Spaghetti, Vermicelli & Noodles (50, dish_type: 'side')
const pastaDishes = [
  { id: 'pasta_mac_and_cheese', title: 'Американские макароны с сыром мак энд чиз', p: 'pasta', a: 'hard_cheese', b: 'milk', c: 'us' },
  { id: 'pasta_arrabbiata_chili', title: 'Острая итальянская паста арраббьята с перчиком чили', p: 'pasta', a: 'tomatoes_canned', b: 'chili_pepper', c: 'it' },
  { id: 'pasta_pesto_basil_pine', title: 'Паста с домашним базиликовым песто и кедровыми орешками', p: 'spaghetti', a: 'basil', b: 'pine_nuts', c: 'it' },
  { id: 'pasta_aglio_olio_garlic', title: 'Классические спагетти альо э олио с чесноком и петрушкой', p: 'spaghetti', a: 'garlic', b: 'olive_oil', c: 'it' },
  { id: 'pasta_alfredo_cream_parmesan', title: 'Шелковистая паста альфредо со сливками и пармезаном', p: 'spaghetti', a: 'cream', b: 'parmesan', c: 'it' },
  { id: 'pasta_four_cheese_quattro', title: 'Паста четыре сыра в бархатистом сливочном соусе', p: 'pasta', a: 'mozzarella', b: 'feta', c: 'it' },
  { id: 'pasta_champignon_sour_cream', title: 'Макароны с жареными шампиньонами в сметанном соусе', p: 'pasta', a: 'champignon', b: 'sour_cream', c: 'ru' },
  { id: 'pasta_cherry_mozzarella', title: 'Летняя паста с томатами черри, базиликом и моцареллой', p: 'pasta', a: 'cherry_tomato', b: 'mozzarella', c: 'it' },
  { id: 'pasta_puttanesca_olives_capers', title: 'Неаполитанская паста путанеска с маслинами и каперсами', p: 'spaghetti', a: 'olives', b: 'capers', c: 'it' },
  { id: 'pasta_norma_eggplant', title: 'Сицилийская паста алла норма с баклажанами и томатом', p: 'pasta', a: 'eggplant', b: 'tomato_sauce', c: 'it' },
  { id: 'pasta_spinach_cream_cheese', title: 'Нежная паста со шпинатом в сливочно-сырном соусе', p: 'pasta', a: 'spinach', b: 'cream_cheese', c: 'home' },
  { id: 'pasta_broccoli_garlic_oil', title: 'Макароны с брокколи в чесночном соусе под сыром', p: 'pasta', a: 'broccoli', b: 'hard_cheese', c: 'it' },
  { id: 'pasta_zucchini_lemon_mint', title: 'Легкая паста с молодым кабачком, цедрой лимона и мятой', p: 'spaghetti', a: 'zucchini', b: 'lemon', c: 'it' },
  { id: 'pasta_pumpkin_sage_cream', title: 'Осенняя паста в нежном тыквенно-сливочном соусе', p: 'pasta', a: 'squash', b: 'cream', c: 'home' },
  { id: 'pasta_baked_cheese_egg', title: 'Запеченная бабка из макарон с яйцом и золотистой корочкой', p: 'pasta', a: 'egg', b: 'cheese', c: 'ru', v: 'запекайте в духовке' },
  { id: 'pasta_sweet_cottage_milk', title: 'Сладкая молочная лапша или запеканка с творогом', p: 'pasta', a: 'cottage_cheese', b: 'sugar', c: 'ru' },
  { id: 'pasta_avocado_green_sauce', title: 'Зеленая паста с кремовым соусом из спелого авокадо', p: 'spaghetti', a: 'avocado', b: 'lime', c: 'home' },
  { id: 'pasta_green_peas_cream', title: 'Паста с зеленым горошком, чесноком и сливками', p: 'pasta', a: 'green_peas', b: 'cream', c: 'home' },
  { id: 'pasta_bell_pepper_walnut', title: 'Спагетти со сладким печеным перцем и грецким орехом', p: 'spaghetti', a: 'bell_pepper', b: 'walnut', c: 'ge' },
  { id: 'pasta_artichokes_olives_lemon', title: 'Паста с артишоками, маслинами и оливковым маслом', p: 'pasta', a: 'artichokes_canned', b: 'olives', c: 'it' },
  { id: 'pasta_beans_fagioli_thick', title: 'Сытная итальянская паста с белой фасолью и розмарином', p: 'pasta', a: 'beans_canned', b: 'rosemary', c: 'it' },
  { id: 'pasta_cauliflower_breadcrumbs', title: 'Паста с цветной капустой и хрустящими сухарями', p: 'pasta', a: 'cauliflower', b: 'breadcrumbs', c: 'it' },
  { id: 'pasta_asparagus_butter_egg', title: 'Спагетти со спаржей и сливочным яичным соусом', p: 'spaghetti', a: 'asparagus', b: 'egg', c: 'it', v: 'обжаривайте с яйцом в сотейнике' },
  { id: 'pasta_oyster_mushroom_thyme', title: 'Паста в сметанно-чесночном соусе с вешенками', p: 'pasta', a: 'oyster_mushroom', b: 'thyme', c: 'home' },
  { id: 'vermicelli_fried_pan_golden', title: 'Жареная на сухой сковороде вермишель с чесноком и маслом', p: 'vermicelli', a: 'butter', b: 'garlic', c: 'tr' },
  { id: 'vermicelli_tomato_carrot_side', title: 'Гарнир из тушеной вермишели с морковью и томатной пастой', p: 'vermicelli', a: 'carrot', b: 'tomato_paste', c: 'ru' },
  { id: 'vermicelli_rice_turkish_pilaf', title: 'Турецкий пилав из рассыпчатого риса с жареной вермишелью', p: 'vermicelli', a: 'basmati_rice', b: 'butter', c: 'tr' },
  { id: 'vermicelli_cottage_baked_pie', title: 'Запеканка из вермишели с творогом, яйцом и сметаной', p: 'vermicelli', a: 'cottage_cheese', b: 'egg', c: 'ru', v: 'запекайте в духовке' },
  { id: 'noodles_wok_vegetables_soy', title: 'Овощная лапша вок со сладким перцем, морковью и соусом', p: 'noodles', a: 'bell_pepper', b: 'soy_sauce', c: 'cn' },
  { id: 'noodles_sesame_peanut_sauce', title: 'Холодная или теплая лапша в пряном арахисовом соусе', p: 'noodles', a: 'peanut', b: 'sesame_oil', c: 'cn' },
  { id: 'noodles_shiitake_cabbage_yakisoba', title: 'Японская лапша якисоба с капустой и грибами шиитаке', p: 'noodles', a: 'cabbage', b: 'shiitake', c: 'jp' },
  { id: 'noodles_tofu_green_beans_wok', title: 'Питательная лапша с сыром тофу и стручковой фасолью', p: 'noodles', a: 'tofu', b: 'green_beans', c: 'cn' },
  { id: 'noodles_eggplant_ginger_soy', title: 'Азиатская лапша с обжаренными баклажанами и имбирем', p: 'noodles', a: 'eggplant', b: 'ginger', c: 'cn' },
  { id: 'noodles_garlic_butter_parmesan', title: 'Быстрая яичная лапша с чесночным маслом и пармезаном', p: 'noodles', a: 'butter', b: 'parmesan', c: 'home' },
  { id: 'noodles_cucumber_sesame_chili', title: 'Китайская лапша с огурцом, кунжутом и маслом чили', p: 'noodles', a: 'cucumber', b: 'sesame', c: 'cn' },
  { id: 'noodles_poppy_honey_polish', title: 'Рождественская лапша с маком, изюмом и медом', p: 'noodles', a: 'poppy_seeds', b: 'honey', c: 'pl' },
  { id: 'noodles_daikon_carrot_korean', title: 'Корейская жареная лапша с морковью, шпинатом и кунжутом', p: 'noodles', a: 'spinach', b: 'sesame', c: 'kr' },
  { id: 'noodles_coconut_curry_broccoli', title: 'Тайская лапша в кокосовом соусе карри с брокколи', p: 'noodles', a: 'coconut_milk', b: 'curry_powder', c: 'th' },
  { id: 'lasagna_veg_spinach_ricotta', title: 'Овощная лазанья со шпинатом, томатами и творогом', p: 'lasagna_sheets', a: 'spinach', b: 'cottage_cheese', c: 'it', v: 'запекайте в духовке' },
  { id: 'lasagna_mushroom_cream_cheese', title: 'Нежная грибная лазанья с шампиньонами под моцареллой', p: 'lasagna_sheets', a: 'champignon', b: 'mozzarella', c: 'it', v: 'запекайте в духовке' },
  { id: 'lasagna_pumpkin_walnut_sauce', title: 'Осенняя лазанья с тыквенным пюре и грецким орехом', p: 'lasagna_sheets', a: 'squash', b: 'walnut', c: 'it', v: 'запекайте в духовке' },
  { id: 'pasta_leek_cream_cheese', title: 'Изысканная паста с томленым луком-пореем и сливками', p: 'spaghetti', a: 'leek', b: 'cream', c: 'fr' },
  { id: 'pasta_beet_feta_pink', title: 'Яркая свекольная паста с нежной фетой и орехами', p: 'pasta', a: 'beet', b: 'feta', c: 'home' },
  { id: 'pasta_corn_basil_butter', title: 'Сливочная паста со сладкой кукурузой и базиликом', p: 'pasta', a: 'corn_canned', b: 'basil', c: 'us' },
  { id: 'pasta_canned_tomato_oregano', title: 'Домашняя паста в томатном соусе с душистым орегано и зубчиками чеснока', p: 'pasta', a: 'tomatoes_canned', b: 'oregano', c: 'it' },
  { id: 'pasta_lecho_quick_dinner', title: 'Быстрые макароны на скорую руку с тушеным лечо', p: 'pasta', a: 'lecho', b: 'hard_cheese', c: 'ru' },
  { id: 'pasta_sorrel_garlic_cream', title: 'Весенняя паста в сливочном соусе со свежим щавелем', p: 'pasta', a: 'sorrel', b: 'cream', c: 'home' },
  { id: 'pasta_brussels_pancetta_veg', title: 'Макароны с обжаренной брюссельской капустой и орехом', p: 'pasta', a: 'brussels_sprouts', b: 'walnut', c: 'home' },
  { id: 'pasta_processed_cheese_garlic', title: 'Быстрая студенческая паста с плавленым сыром и чесноком', p: 'pasta', a: 'processed_cheese', b: 'garlic', c: 'ru' },
  { id: 'spaghetti_sunflower_pesto', title: 'Спагетти с домашним соусом из петрушки и семечек', p: 'spaghetti', a: 'parsley', b: 'sunflower_seeds', c: 'home' }
];

for (const it of pastaDishes) {
  addPorridge({
    id: it.id,
    title: it.title,
    dish_type: 'side',
    cuisine: it.c,
    time: 30,
    active: 15,
    verb: it.v || 'варите и перемешайте с соусом',
    heatSec: 600,
    desc: `Аппетитное блюдо из макаронных изделий «${it.title}» на обед или ужин.`,
    ings: [
      { ingredient_id: it.p, amount: 300, unit: 'g' },
      it.a,
      it.b,
      'sunflower_oil',
      'salt'
    ]
  });
}

console.log(`Total generated porridge & side dishes: ${allPorridge.length}`);
saveAndValidateGroup('porridge.json', allPorridge);
