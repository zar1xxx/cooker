const { saveAndValidateGroup, smartIngredient } = require('./recipe_builder');

function s(text, timer_seconds, tip) {
  const step = { text: text.trim() };
  if (timer_seconds) step.timer_seconds = timer_seconds;
  if (tip) step.tip = tip;
  return step;
}

const allVeg = [];

function addVeg(def) {
  const id = `veg_${def.id}`;
  const title = def.title;
  const time = def.time || 40;
  const active = def.active || 20;
  const servings = def.servings || 4;
  const cuisine = def.cuisine || 'home';
  const dishType = def.dish_type || 'main';
  const desc = def.desc || `Ароматное овощное блюдо «${title}» для вкусного домашнего обеда или ужина.`;

  const ingsMap = new Map();
  for (const raw of def.ings) {
    const rawId = raw.ingredient_id || raw.id || raw;
    const ingObj = smartIngredient(rawId, raw.amount, raw.unit);
    ingsMap.set(rawId, ingObj);
  }
  const ings = Array.from(ingsMap.values());
  const hasEgg = ingsMap.has('egg');

  let heatVerb = def.verb || 'тушите под крышкой';
  if (hasEgg && !['вар', 'жар', 'запек'].some(k => heatVerb.toLowerCase().includes(k))) {
    heatVerb = 'обжаривайте на среднем огне';
  }
  const heatSec = def.heatSec || (hasEgg ? 480 : 600);
  const heatMin = Math.ceil(heatSec / 60);
  const eggNote = hasEgg ? ' со взбитым яйцом' : '';

  const steps = def.steps || [
    s(`Для блюда «${title}» переберите и промойте свежие овощи прохладной водой, затем обсушите полотенцем.`),
    s(`Подготовленные компоненты для «${title}» измельчите удобными кусочками и приправьте специями со вкусом.`),
    s(`${heatVerb.charAt(0).toUpperCase() + heatVerb.slice(1)} продукты${eggNote} для «${title}» около ${heatMin} минут до мягкости и аромата.`, heatSec),
    s(`Подавайте горячее овощное блюдо «${title}» на теплой тарелке, украсив свежей порубленной зеленью.`)
  ];

  allVeg.push({
    id: id,
    title: title,
    dish_type: dishType,
    dish_group: 'vegetable',
    cuisine: cuisine,
    total_minutes: time,
    active_minutes: active,
    servings: servings,
    description: desc,
    ingredients: ings,
    steps: steps
  });
}

const vegDefs = [
  // 1. Potato & Sweet Potato (25)
  { id: 'potato_draniki_belarus', title: 'Белорусские драники со сметаной и хрустящей корочкой', p: 'potato', a: 'sour_cream', b: 'egg', c: 'by', v: 'обжаривайте на масле' },
  { id: 'potato_zrazy_champignon', title: 'Картофельные зразы с начинкой из жареных шампиньонов', p: 'potato', a: 'champignon', b: 'breadcrumbs', c: 'ru', v: 'обжаривайте на сковороде' },
  { id: 'potato_gratin_dauphinois', title: 'Французский гратен дофинуа со сливками и мускатным орехом', p: 'potato', a: 'cream', b: 'nutmeg', c: 'fr', v: 'запекайте в духовке' },
  { id: 'potato_baked_rosemary_garlic', title: 'Запеченный картофель по-деревенски с розмарином', p: 'potato', a: 'rosemary', b: 'olive_oil', c: 'home', v: 'запекайте в духовке' },
  { id: 'potato_stew_oyster_mushrooms', title: 'Тушеный картофель с вешенками и ароматным укропом', p: 'potato', a: 'oyster_mushroom', b: 'dill', c: 'ru', v: 'тушите под крышкой' },
  { id: 'potato_curry_green_peas', title: 'Индийский алу матар с картофелем и зеленым горошком', p: 'potato', a: 'green_peas', b: 'curry_powder', c: 'in', v: 'тушите в сотейнике' },
  { id: 'potato_bake_hard_cheese', title: 'Сливочная картофельная запеканка под тертым сыром', p: 'potato', a: 'hard_cheese', b: 'milk', c: 'home', v: 'запекайте в духовке' },
  { id: 'potato_accordion_butter_garlic', title: 'Картофель гармошка с чесночным маслом и петрушкой', p: 'potato', a: 'butter', b: 'parsley', c: 'home', v: 'запекайте в духовке' },
  { id: 'potato_spanish_bravas', title: 'Испанский картофель пататас бравас в остром соусе', p: 'potato', a: 'tomato_sauce', b: 'chili_pepper', c: 'es', v: 'обжаривайте до золотистости' },
  { id: 'potato_croquettes_mozzarella', title: 'Хрустящие картофельные крокеты с сыром моцарелла', p: 'potato', a: 'mozzarella', b: 'egg', c: 'it', v: 'обжаривайте во фритюре' },
  { id: 'potato_cabbage_stew_village', title: 'Деревенская тушеная картошка со свежей капустой', p: 'potato', a: 'cabbage', b: 'bay_leaf', c: 'ru', v: 'тушите на среднем огне' },
  { id: 'potato_leek_soup_stew', title: 'Нежное рагу из молодого картофеля с луком-пореем', p: 'potato', a: 'leek', b: 'butter', c: 'fr', v: 'тушите в сотейнике' },
  { id: 'potato_sweet_potato_wedges', title: 'Запеченные дольки батата со сладкой паприкой и тимьяном', p: 'sweet_potato', a: 'paprika', b: 'thyme', c: 'us', v: 'запекайте в духовке' },
  { id: 'sweet_potato_chickpea_curry', title: 'Пряное рагу из сладкого батата с нутом и кокосом', p: 'sweet_potato', a: 'chickpeas_canned', b: 'coconut_milk', c: 'in', v: 'тушите в сотейнике' },
  { id: 'sweet_potato_feta_walnut', title: 'Печеный батат с раскрошенной фетой и грецким орехом', p: 'sweet_potato', a: 'feta', b: 'walnut', c: 'home', v: 'запекайте в духовке' },
  { id: 'sweet_potato_spinach_hash', title: 'Теплое рагу из батата со шпинатом и чесноком', p: 'sweet_potato', a: 'spinach', b: 'garlic', c: 'home', v: 'обжаривайте на сковороде' },
  { id: 'sweet_potato_cinnamon_honey', title: 'Карамелизированный батат с медом и щепоткой корицы', p: 'sweet_potato', a: 'honey', b: 'cinnamon', c: 'us', v: 'запекайте в духовке' },
  { id: 'potato_sour_cream_dill_young', title: 'Молодой отварной картофель со сметаной и свежим укропом', p: 'potato', a: 'sour_cream', b: 'green_onion', c: 'ru', v: 'варите до мягкости' },
  { id: 'potato_beans_canned_tomato', title: 'Сытная тушеная картошка с красной фасолью и томатом', p: 'potato', a: 'beans_canned', b: 'tomato_paste', c: 'home', v: 'тушите под крышкой' },
  { id: 'potato_corn_cheese_gratin', title: 'Картофельный гратен со сладкой кукурузой в духовке', p: 'potato', a: 'corn_canned', b: 'cheese', c: 'home', v: 'запекайте в духовке' },
  { id: 'potato_turmeric_cumin_indian', title: 'Индийский жареный картофель бомбей с зирой и куркумой', p: 'potato', a: 'turmeric', b: 'cumin', c: 'in', v: 'обжаривайте на сковороде' },
  { id: 'potato_turnip_butter_mash', title: 'Нежное деревенское пюре из картофеля со сладкой репой', p: 'potato', a: 'turnip', b: 'butter', c: 'ru', v: 'варите и разомните' },
  { id: 'potato_pumpkin_baked_herbs', title: 'Запеченное ассорти из картофеля и кусочков тыквы', p: 'potato', a: 'squash', b: 'oregano', c: 'home', v: 'запекайте в духовке' },
  { id: 'potato_sesame_soy_braised', title: 'Корейский тушеный картофель камджа джорим с кунжутом', p: 'potato', a: 'soy_sauce', b: 'sesame', c: 'kr', v: 'тушите в соевом соусе' },
  { id: 'potato_black_bread_garlic_bake', title: 'Картофельная запеканка с хрустящими сухариками и луком', p: 'potato', a: 'breadcrumbs', b: 'sour_cream', c: 'ru', v: 'запекайте в духовке' },

  // 2. Zucchini, Eggplant, Squash, Pattypan (30)
  { id: 'zucchini_pancakes_dill', title: 'Пышные кабачковые оладьи со свежим укропом и чесноком', p: 'zucchini', a: 'egg', b: 'flour', c: 'ru', v: 'обжаривайте на сковороде' },
  { id: 'zucchini_cake_tomato_mayo', title: 'Праздничный кабачковый торт со сметаной и томатами', p: 'zucchini', a: 'sour_cream', b: 'tomato', c: 'ru', v: 'обжаривайте коржи на сковороде' },
  { id: 'zucchini_stuffed_mushrooms_cheese', title: 'Лодочки из кабачков, запеченные с грибами под сыром', p: 'zucchini', a: 'champignon', b: 'hard_cheese', c: 'home', v: 'запекайте в духовке' },
  { id: 'zucchini_ratatouille_provence', title: 'Классический прованский рататуй с кабачками и перцем', p: 'zucchini', a: 'eggplant', b: 'tomato', c: 'fr', v: 'запекайте в духовке' },
  { id: 'zucchini_baked_parmesan_sticks', title: 'Хрустящие палочки из цукини в духовке с пармезаном', p: 'zucchini', a: 'parmesan', b: 'breadcrumbs', c: 'it', v: 'запекайте в духовке' },
  { id: 'zucchini_squash_ikra', title: 'Домашняя овощная икра из кабачков с морковью и пастой', p: 'zucchini', a: 'carrot', b: 'tomato_paste', c: 'ru', v: 'тушите на тихом огне' },
  { id: 'zucchini_rice_stuffed_tomato', title: 'Фаршированные рисом и зеленью молодые кабачки', p: 'zucchini', a: 'round_rice', b: 'parsley', c: 'home', v: 'тушите в сотейнике' },
  { id: 'zucchini_feta_mint_fritters', title: 'Греческие котлетки из цукини с сыром фета и мятой', p: 'zucchini', a: 'feta', b: 'mint', c: 'gr', v: 'обжаривайте на масле' },
  { id: 'zucchini_cream_garlic_stew', title: 'Нежные кабачки, тушенные в чесночных сливках', p: 'zucchini', a: 'cream', b: 'garlic', c: 'home', v: 'тушите в сковороде' },
  { id: 'zucchini_soy_sesame_wok', title: 'Пряные кабачки вок с кунжутным маслом и чесноком', p: 'zucchini', a: 'sesame_oil', b: 'soy_sauce', c: 'cn', v: 'обжаривайте на сильном огне' },
  { id: 'eggplant_ajapsandali_georgian', title: 'Грузинский аджапсандали с баклажанами и свежей кинзой', p: 'eggplant', a: 'bell_pepper', b: 'cilantro', c: 'ge', v: 'тушите в казане' },
  { id: 'eggplant_walnut_rolls_garlic', title: 'Рулетики из жареных баклажанов с грецким орехом', p: 'eggplant', a: 'walnut', b: 'garlic', c: 'ge', v: 'обжаривайте слайсы на сковороде' },
  { id: 'eggplant_parmigiana_mozzarella', title: 'Итальянская пармиджана из баклажанов с моцареллой', p: 'eggplant', a: 'mozzarella', b: 'tomato_sauce', c: 'it', v: 'запекайте в духовке' },
  { id: 'eggplant_chinese_sweet_spicy', title: 'Хрустящие баклажаны по-китайски в кисло-сладком соусе', p: 'eggplant', a: 'starch', b: 'chili_pepper', c: 'cn', v: 'обжаривайте до хруста' },
  { id: 'eggplant_imam_bayildi_tomato', title: 'Турецкое блюдо имам баялды из печеных баклажанов', p: 'eggplant', a: 'tomato', b: 'parsley', c: 'tr', v: 'запекайте в духовке' },
  { id: 'eggplant_caponata_olives', title: 'Сицилийская капоната из баклажанов с оливками и каперсами', p: 'eggplant', a: 'olives', b: 'capers', c: 'it', v: 'тушите в сотейнике' },
  { id: 'eggplant_miso_honey_glaze', title: 'Глазированные дольки баклажана с медом и соевым соусом', p: 'eggplant', a: 'honey', b: 'soy_sauce', c: 'jp', v: 'запекайте в духовке' },
  { id: 'eggplant_peanut_ginger_stew', title: 'Пряные баклажаны с дробленым арахисом и имбирем', p: 'eggplant', a: 'peanut', b: 'ginger', c: 'th', v: 'тушите в воке' },
  { id: 'eggplant_chickpeas_coriander', title: 'Рагу из баклажанов с турецким нутом и кориандром', p: 'eggplant', a: 'chickpeas_canned', b: 'coriander', c: 'tr', v: 'тушите под крышкой' },
  { id: 'eggplant_sour_cream_dill', title: 'Жареные баклажаны в нежной сметанной подливке', p: 'eggplant', a: 'sour_cream', b: 'dill', c: 'ru', v: 'обжаривайте и тушите' },
  { id: 'squash_baked_honey_walnut', title: 'Сладкая тыква, запеченная кусочками с медом и орехами', p: 'squash', a: 'honey', b: 'walnut', c: 'home', v: 'запекайте в духовке' },
  { id: 'squash_garlic_rosemary_savory', title: 'Запеченная тыква с чесноком, розмарином и солью', p: 'squash', a: 'rosemary', b: 'olive_oil', c: 'it', v: 'запекайте в духовке' },
  { id: 'squash_coconut_curry_lentils', title: 'Тыквенное карри с красной чечевицей и кокосом', p: 'squash', a: 'lentils_red', b: 'coconut_milk', c: 'in', v: 'тушите на среднем огне' },
  { id: 'squash_feta_pumpkin_seeds', title: 'Теплая печеная тыква с сыром фета и семечками', p: 'squash', a: 'feta', b: 'pumpkin_seeds', c: 'home', v: 'запекайте в духовке' },
  { id: 'squash_millet_baked_pot', title: 'Томленая в горшочке тыква с пшеном и сливочным маслом', p: 'squash', a: 'millet', b: 'butter', c: 'ru', v: 'запекайте в духовке' },
  { id: 'pattypan_baked_sour_cream', title: 'Запеченные молодые патиссоны под сметанным соусом', p: 'pattypan', a: 'sour_cream', b: 'cheese', c: 'ru', v: 'запекайте в духовке' },
  { id: 'pattypan_stew_carrot_pepper', title: 'Летнее овощное рагу из патиссонов со сладким перцем', p: 'pattypan', a: 'bell_pepper', b: 'carrot', c: 'home', v: 'тушите в сотейнике' },
  { id: 'pattypan_fried_garlic_flour', title: 'Хрустящие обжаренные кружочки патиссона с чесноком', p: 'pattypan', a: 'flour', b: 'garlic', c: 'ru', v: 'обжаривайте с двух сторон' },
  { id: 'squash_apple_cinnamon_stew', title: 'Душистая тушеная тыква со сладким яблоком и корицей', p: 'squash', a: 'apple', b: 'cinnamon', c: 'home', v: 'тушите в кастрюле' },
  { id: 'zucchini_corn_basil_saute', title: 'Быстрое соте из цукини, кукурузы и листьев базилика', p: 'zucchini', a: 'corn', b: 'basil', c: 'us', v: 'обжаривайте на сковороде' },

  // 3. Cabbage, Broccoli, Cauliflower, Brussels, Kohlrabi (30)
  { id: 'cabbage_steaks_garlic_paprika', title: 'Румяные стейки из молодой капусты с паприкой в духовке', p: 'cabbage', a: 'paprika', b: 'olive_oil', c: 'home', v: 'запекайте в духовке' },
  { id: 'cabbage_cutlets_semolina', title: 'Нежные капустные котлеты с манкой и зеленью', p: 'cabbage', a: 'semolina', b: 'egg', c: 'ru', v: 'обжаривайте с двух сторон' },
  { id: 'cabbage_braised_champignon', title: 'Тушеная белокочанная капуста с шампиньонами', p: 'cabbage', a: 'champignon', b: 'dill', c: 'ru', v: 'тушите под крышкой' },
  { id: 'cabbage_beans_bigus_fasting', title: 'Постный овощной бигус с капустой, фасолью и черносливом', p: 'cabbage', a: 'beans_canned', b: 'prunes', c: 'pl', v: 'тушите на тихом огне' },
  { id: 'cabbage_casserole_sour_cream', title: 'Запеканка из молодой капусты с сыром и сметаной', p: 'cabbage', a: 'cheese', b: 'sour_cream', c: 'home', v: 'запекайте в духовке' },
  { id: 'red_cabbage_apple_braise', title: 'Тушеная красная капуста по-немецки с кислыми яблоками', p: 'red_cabbage', a: 'apple', b: 'apple_vinegar', c: 'de', v: 'тушите на среднем огне' },
  { id: 'red_cabbage_orange_cloves', title: 'Праздничная красная капуста с апельсином и гвоздикой', p: 'red_cabbage', a: 'orange', b: 'cloves', c: 'uk', v: 'тушите в кастрюле' },
  { id: 'red_cabbage_walnut_honey', title: 'Красная капуста, томленная с медом и грецким орехом', p: 'red_cabbage', a: 'honey', b: 'walnut', c: 'home', v: 'тушите в сотейнике' },
  { id: 'cauliflower_gratin_cream', title: 'Цветная капуста под сливочно-сырной корочкой в духовке', p: 'cauliflower', a: 'hard_cheese', b: 'cream', c: 'fr', v: 'запекайте в духовке' },
  { id: 'cauliflower_fried_breadcrumbs', title: 'Жареная цветная капуста в золотистых сухарях со специями', p: 'cauliflower', a: 'breadcrumbs', b: 'egg', c: 'ru', v: 'обжаривайте до румяности' },
  { id: 'cauliflower_gobi_curry', title: 'Индийское блюдо алу гоби из цветной капусты с куркумой', p: 'cauliflower', a: 'turmeric', b: 'cumin', c: 'in', v: 'тушите в сковороде' },
  { id: 'cauliflower_buffalo_baked', title: 'Острые запеченные соцветия цветной капусты со специями', p: 'cauliflower', a: 'paprika', b: 'butter', c: 'us', v: 'запекайте в духовке' },
  { id: 'cauliflower_tahini_lemon', title: 'Печеная цветная капуста с кунжутом, лимоном и зирой', p: 'cauliflower', a: 'sesame', b: 'lemon', c: 'tr', v: 'запекайте в духовке' },
  { id: 'cauliflower_rice_green_peas', title: 'Овощной рис из цветной капусты с зеленым горошком', p: 'cauliflower', a: 'green_peas', b: 'soy_sauce', c: 'home', v: 'обжаривайте на сковороде' },
  { id: 'cauliflower_puree_butter_garlic', title: 'Нежное кремовое пюре из цветной капусты с чесноком', p: 'cauliflower', a: 'butter', b: 'garlic', c: 'fr', v: 'варите до мягкости' },
  { id: 'broccoli_almond_butter_saute', title: 'Хрустящая брокколи с обжаренным миндалем в масле', p: 'broccoli', a: 'almond', b: 'butter', c: 'home', v: 'обжаривайте на сковороде' },
  { id: 'broccoli_cheese_baked_crust', title: 'Запеченная брокколи под сыром моцарелла и сливками', p: 'broccoli', a: 'mozzarella', b: 'cream', c: 'it', v: 'запекайте в духовке' },
  { id: 'broccoli_garlic_soy_oyster', title: 'Брокколи в китайском стиле с чесноком и соевым соусом', p: 'broccoli', a: 'soy_sauce', b: 'sesame_oil', c: 'cn', v: 'обжаривайте в воке' },
  { id: 'broccoli_lemon_parmesan_roast', title: 'Запеченная брокколи с цедрой лимона и пармезаном', p: 'broccoli', a: 'parmesan', b: 'lemon', c: 'it', v: 'запекайте в духовке' },
  { id: 'broccoli_omelet_bake_frittata', title: 'Пышная овощная запеканка с брокколи и сметаной', p: 'broccoli', a: 'sour_cream', b: 'egg', c: 'home', v: 'запекайте в духовке' },
  { id: 'brussels_honey_mustard_roast', title: 'Брюссельская капуста в духовке с горчично-медовой глазурью', p: 'brussels_sprouts', a: 'honey', b: 'mustard', c: 'home', v: 'запекайте в духовке' },
  { id: 'brussels_walnut_balsamic', title: 'Печеная брюссельская капуста с уксусом и грецким орехом', p: 'brussels_sprouts', a: 'apple_vinegar', b: 'walnut', c: 'fr', v: 'запекайте в духовке' },
  { id: 'brussels_cream_nutmeg_braise', title: 'Нежная брюссельская капуста в сливках с мускатным орехом', p: 'brussels_sprouts', a: 'cream', b: 'nutmeg', c: 'de', v: 'тушите в сотейнике' },
  { id: 'brussels_garlic_breadcrumbs', title: 'Хрустящая брюссельская капуста с чесночными сухариками', p: 'brussels_sprouts', a: 'breadcrumbs', b: 'garlic', c: 'home', v: 'обжаривайте на сковороде' },
  { id: 'kohlrabi_cream_dill_stew', title: 'Молодая кольраби, тушенная в сметане с зеленью укропа', p: 'kohlrabi', a: 'sour_cream', b: 'dill', c: 'de', v: 'тушите до мягкости' },
  { id: 'kohlrabi_carrot_fritters', title: 'Хрустящие оладьи из тертой кольраби и сочной моркови', p: 'kohlrabi', a: 'carrot', b: 'egg', c: 'home', v: 'обжаривайте на масле' },
  { id: 'kohlrabi_cheese_gratin', title: 'Запеченная капуста кольраби с картофелем под сыром', p: 'kohlrabi', a: 'potato', b: 'cheese', c: 'home', v: 'запекайте в духовке' },
  { id: 'kohlrabi_butter_parsley_glazed', title: 'Глазированная кольраби в сливочном масле с петрушкой', p: 'kohlrabi', a: 'butter', b: 'parsley', c: 'fr', v: 'тушите в сковороде' },
  { id: 'sauerkraut_apples_cranberry', title: 'Квашеная капуста, томленная с яблоками и клюквой', p: 'sauerkraut', a: 'apple', b: 'cranberry', c: 'ru', v: 'тушите под крышкой' },
  { id: 'sauerkraut_mushrooms_buckwheat', title: 'Тушеная кислая капуста с шампиньонами и тмином', p: 'sauerkraut', a: 'champignon', b: 'cumin', c: 'pl', v: 'тушите на тихом огне' },

  // 4. Mushrooms (Cultivated: champignon, oyster_mushroom, shiitake, canned) (25)
  { id: 'mushroom_julienne_classic', title: 'Классический грибной жульен с шампиньонами под сыром', p: 'champignon', a: 'cream', b: 'hard_cheese', c: 'fr', v: 'запекайте в духовке' },
  { id: 'champignon_garlic_butter_pan', title: 'Быстрые жареные шампиньоны с чесночным маслом и укропом', p: 'champignon', a: 'butter', b: 'garlic', c: 'home', v: 'обжаривайте на сильном огне' },
  { id: 'champignon_stuffed_cheese_herbs', title: 'Шляпки шампиньонов, фаршированные сливочным сыром', p: 'champignon', a: 'cream_cheese', b: 'parsley', c: 'home', v: 'запекайте в духовке' },
  { id: 'champignon_sour_cream_buckwheat', title: 'Тушеные шампиньоны в густом сметанном соусе с луком', p: 'champignon', a: 'sour_cream', b: 'flour', c: 'ru', v: 'тушите на среднем огне' },
  { id: 'champignon_balsamic_thyme_roast', title: 'Запеченные шампиньоны с яблочным уксусом и тимьяном', p: 'champignon', a: 'apple_vinegar', b: 'thyme', c: 'it', v: 'запекайте в духовке' },
  { id: 'champignon_spinach_feta_bake', title: 'Шампиньоны со шпинатом и раскрошенной фетой в духовке', p: 'champignon', a: 'spinach', b: 'feta', c: 'gr', v: 'запекайте в духовке' },
  { id: 'champignon_fried_potato_dill', title: 'Золотистая сковородка с шампиньонами и зеленым луком', p: 'champignon', a: 'green_onion', b: 'paprika', c: 'ru', v: 'обжаривайте до румяности' },
  { id: 'oyster_mushroom_sour_cream', title: 'Вешенки, тушенные в сметане с ароматным укропом', p: 'oyster_mushroom', a: 'sour_cream', b: 'dill', c: 'ru', v: 'тушите на сковороде' },
  { id: 'oyster_mushroom_soy_ginger', title: 'Жареные вешенки в соевом соусе с имбирем и кунжутом', p: 'oyster_mushroom', a: 'soy_sauce', b: 'ginger', c: 'cn', v: 'обжаривайте в воке' },
  { id: 'oyster_mushroom_potato_roast', title: 'Жаркое из вешенок с молодым картофелем и чесноком', p: 'oyster_mushroom', a: 'potato', b: 'garlic', c: 'ru', v: 'обжаривайте под крышкой' },
  { id: 'oyster_mushroom_breadcrumbs_cutlets', title: 'Хрустящие обжаренные вешенки в золотистой панировке', p: 'oyster_mushroom', a: 'breadcrumbs', b: 'egg', c: 'home', v: 'обжаривайте на сковороде' },
  { id: 'oyster_mushroom_bell_pepper', title: 'Вешенки со сладким болгарским перцем и паприкой', p: 'oyster_mushroom', a: 'bell_pepper', b: 'paprika', c: 'home', v: 'обжаривайте на масле' },
  { id: 'shiitake_sesame_garlic_wok', title: 'Пряные грибы шиитаке вок с чесноком и кунжутным маслом', p: 'shiitake', a: 'sesame_oil', b: 'garlic', c: 'jp', v: 'обжаривайте на сильном огне' },
  { id: 'shiitake_tofu_soy_braise', title: 'Тушеные грибы шиитаке с соевым тофу и зеленым луком', p: 'shiitake', a: 'tofu', b: 'soy_sauce', c: 'cn', v: 'тушите в сковороде' },
  { id: 'shiitake_noodles_spinach', title: 'Лапша с обжаренными шиитаке, свежим шпинатом и чесноком', p: 'shiitake', a: 'noodles', b: 'spinach', c: 'jp', v: 'обжаривайте в воке' },
  { id: 'shiitake_cream_rosemary', title: 'Грибы шиитаке в сливочном соусе с розмарином', p: 'shiitake', a: 'cream', b: 'rosemary', c: 'home', v: 'тушите в сотейнике' },
  { id: 'mushrooms_rice_garlic_pan', title: 'Рассыпчатый рис с грибами, морковью и зеленым горошком', p: 'champignon', a: 'round_rice', b: 'green_peas', c: 'home', v: 'тушите в сотейнике' },
  { id: 'mushrooms_eggplant_tomato_stew', title: 'Овощное соте из шампиньонов, баклажанов и помидоров', p: 'champignon', a: 'eggplant', b: 'tomato', c: 'home', v: 'тушите в сковороде' },
  { id: 'mushrooms_beans_georgian', title: 'Жареные грибы с красной фасолью, кинзой и орехом', p: 'champignon', a: 'beans_canned', b: 'walnut', c: 'ge', v: 'тушите на среднем огне' },
  { id: 'mushrooms_canned_potato_pie', title: 'Запеканка из консервированных грибов с картофелем', p: 'mushrooms_canned', a: 'potato', b: 'cheese', c: 'ru', v: 'запекайте в духовке' },
  { id: 'mushrooms_canned_sour_cream', title: 'Маринованные грибочки, тушенные со сметаной и луком', p: 'mushrooms_canned', a: 'sour_cream', b: 'carrot', c: 'ru', v: 'тушите в сковороде' },
  { id: 'mushroom_casserole_oatmeal', title: 'Диетическая грибная запеканка с овсянкой и сыром', p: 'champignon', a: 'oatmeal', b: 'cheese', c: 'home', v: 'запекайте в духовке' },
  { id: 'mushroom_cutlets_potato', title: 'Постные котлеты из шампиньонов с картофельным пюре', p: 'champignon', a: 'potato', b: 'flour', c: 'ru', v: 'обжаривайте на масле' },
  { id: 'mushroom_teriyaki_skewers', title: 'Запеченные шампиньоны на шпажках в соусе терияки', p: 'champignon', a: 'soy_sauce', b: 'sesame', c: 'jp', v: 'запекайте в духовке' },
  { id: 'oyster_mushroom_cabbage', title: 'Вешенки, тушенные с белокочанной капустой и томатом', p: 'oyster_mushroom', a: 'cabbage', b: 'tomato_paste', c: 'ru', v: 'тушите под крышкой' },

  // 5. Legumes & Tofu (beans_canned, chickpeas_canned, lentils_red, lentils_green, green_beans, tofu) (30)
  { id: 'lobio_georgian_walnut', title: 'Грузинское лобио из красной фасоли с грецким орехом', p: 'beans_canned', a: 'walnut', b: 'cilantro', c: 'ge', v: 'тушите в кастрюле' },
  { id: 'beans_mexican_chili_corn', title: 'Мексиканское рагу с фасолью, кукурузой и паприкой', p: 'beans_canned', a: 'corn_canned', b: 'chili_pepper', c: 'mx', v: 'тушите в сотейнике' },
  { id: 'beans_tomato_garlic_stew', title: 'Тушеная фасоль по-домашнему в томатном соусе с чесноком', p: 'beans_canned', a: 'tomato_paste', b: 'garlic', c: 'ru', v: 'тушите в сотейнике' },
  { id: 'beans_spinach_olives_med', title: 'Испанская фасоль со шпинатом и маслинами в масле', p: 'beans_canned', a: 'spinach', b: 'olives', c: 'es', v: 'тушите в сковороде' },
  { id: 'beans_mushrooms_carrot_pot', title: 'Постное жаркое с фасолью, шампиньонами и морковью', p: 'beans_canned', a: 'champignon', b: 'carrot', c: 'ru', v: 'тушите в сотейнике' },
  { id: 'chickpeas_chana_masala', title: 'Индийская чана масала из нута с томатами и карри', p: 'chickpeas_canned', a: 'tomatoes_canned', b: 'curry_powder', c: 'in', v: 'тушите в сотейнике' },
  { id: 'chickpeas_spinach_coconut', title: 'Пряный нут со свежим шпинатом в кокосовом молоке', p: 'chickpeas_canned', a: 'spinach', b: 'coconut_milk', c: 'in', v: 'тушите на среднем огне' },
  { id: 'chickpeas_roasted_paprika_crunchy', title: 'Хрустящий печеный нут с паприкой, зирой и чесноком', p: 'chickpeas_canned', a: 'paprika', b: 'cumin', c: 'tr', v: 'запекайте в духовке' },
  { id: 'chickpeas_eggplant_tomato', title: 'Ближневосточное рагу из нута с баклажанами и томатом', p: 'chickpeas_canned', a: 'eggplant', b: 'tomato', c: 'tr', v: 'тушите под крышкой' },
  { id: 'chickpeas_squash_turmeric', title: 'Ароматный нут со сладкой тыквой, имбирем и куркумой', p: 'chickpeas_canned', a: 'squash', b: 'turmeric', c: 'home', v: 'тушите в сотейнике' },
  { id: 'lentils_red_dahl_coconut', title: 'Индийский дал из красной чечевицы с кокосовым молоком', p: 'lentils_red', a: 'coconut_milk', b: 'turmeric', c: 'in', v: 'варите на тихом огне', heatSec: 1200 },
  { id: 'lentils_red_tomato_carrot', title: 'Густое рагу из красной чечевицы с томатом и морковью', p: 'lentils_red', a: 'tomato_paste', b: 'carrot', c: 'tr', v: 'варите до мягкости', heatSec: 1200 },
  { id: 'lentils_red_squash_ginger', title: 'Пряная красная чечевица с тыквой и свежим имбирем', p: 'lentils_red', a: 'squash', b: 'ginger', c: 'home', v: 'варите в кастрюле', heatSec: 1200 },
  { id: 'lentils_red_cutlets_oatmeal', title: 'Постные котлеты из красной чечевицы с овсяными хлопьями', p: 'lentils_red', a: 'oatmeal', b: 'garlic', c: 'home', v: 'варите чечевицу и обжарьте', heatSec: 1200 },
  { id: 'lentils_green_mushrooms_thyme', title: 'Зеленая чечевица с жареными шампиньонами и тимьяном', p: 'lentils_green', a: 'champignon', b: 'thyme', c: 'fr', v: 'варите до мягкости', heatSec: 1500 },
  { id: 'lentils_green_celery_carrot', title: 'Французская зеленая чечевица с сельдереем и морковью', p: 'lentils_green', a: 'celery', b: 'carrot', c: 'fr', v: 'варите в бульоне', heatSec: 1500 },
  { id: 'lentils_green_spinach_lemon', title: 'Теплая чечевица со свежим шпинатом, чесноком и лимоном', p: 'lentils_green', a: 'spinach', b: 'lemon', c: 'gr', v: 'варите и потушите', heatSec: 1500 },
  { id: 'lentils_green_tomato_rice', title: 'Муджадара из зеленой чечевицы с рисом и жареным луком', p: 'lentils_green', a: 'basmati_rice', b: 'cumin', c: 'tr', v: 'варите до рассыпчатости', heatSec: 1500 },
  { id: 'green_beans_garlic_almond', title: 'Стручковая фасоль с чесноком и миндальными лепестками', p: 'green_beans', a: 'almond', b: 'butter', c: 'fr', v: 'обжаривайте в масле' },
  { id: 'green_beans_tomato_eggs', title: 'Грузинская стручковая фасоль с томатами и яйцом', p: 'green_beans', a: 'tomato', b: 'egg', c: 'ge', v: 'обжаривайте со взбитым яйцом' },
  { id: 'green_beans_sesame_soy', title: 'Хрустящая стручковая фасоль вок с кунжутом и соусом', p: 'green_beans', a: 'sesame', b: 'soy_sauce', c: 'cn', v: 'обжаривайте в воке' },
  { id: 'green_beans_carrot_walnut', title: 'Лобио из стручковой фасоли с грецким орехом и кинзой', p: 'green_beans', a: 'walnut', b: 'cilantro', c: 'ge', v: 'тушите в сковороде' },
  { id: 'tofu_crispy_soy_sesame', title: 'Хрустящий жареный тофу в соевом соусе с кунжутом', p: 'tofu', a: 'soy_sauce', b: 'sesame', c: 'jp', v: 'обжаривайте до золотистости' },
  { id: 'tofu_broccoli_ginger_wok', title: 'Вок с сыром тофу, свежей брокколи и имбирем', p: 'tofu', a: 'broccoli', b: 'ginger', c: 'cn', v: 'обжаривайте в воке' },
  { id: 'tofu_curry_coconut_pepper', title: 'Вегетарианское карри с тофу и сладким болгарским перцем', p: 'tofu', a: 'coconut_milk', b: 'bell_pepper', c: 'th', v: 'тушите в сковороде' },
  { id: 'tofu_scramble_turmeric_tomato', title: 'Постный скрембл из тофу с помидорами и куркумой', p: 'tofu', a: 'tomato', b: 'turmeric', c: 'us', v: 'обжаривайте на сковороде' },
  { id: 'mung_beans_carrot_turmeric', title: 'Рассыпчатый маш с морковью, зирой и куркумой', p: 'mung_beans', a: 'carrot', b: 'turmeric', c: 'uz', v: 'варите на тихом огне', heatSec: 1500 },
  { id: 'peas_dry_puree_onion', title: 'Традиционное густое гороховое пюре с жареным луком', p: 'peas_dry', a: 'butter', b: 'dill', c: 'ru', v: 'варите до разваривания', heatSec: 2400 },
  { id: 'azuki_sweet_rice_stew', title: 'Японские красные бобы адзуки в соево-медовой глазури', p: 'azuki', a: 'honey', b: 'soy_sauce', c: 'jp', v: 'варите и тушите', heatSec: 2400 },
  { id: 'soybeans_tomato_vegetable_stew', title: 'Питательное рагу из отварной сои со сладким перцем', p: 'soybeans', a: 'bell_pepper', b: 'tomato_paste', c: 'home', v: 'варите и тушите', heatSec: 2400 },

  // 6. Mixed Stews, Roots, Corn, Asparagus, Spinach, Artichoke (30)
  { id: 'veg_ragout_classic_autumn', title: 'Осеннее овощное рагу с кабачком, картофелем и перцем', p: 'potato', a: 'zucchini', b: 'bell_pepper', c: 'ru', v: 'тушите под крышкой' },
  { id: 'veg_lecho_homemade_stew', title: 'Домашнее горячее лечо из сладкого перца с томатами', p: 'bell_pepper', a: 'tomato', b: 'garlic', c: 'home', v: 'тушите в кастрюле' },
  { id: 'veg_saute_eggplant_carrot', title: 'Ароматное соте из баклажанов, моркови и помидоров', p: 'eggplant', a: 'carrot', b: 'tomato', c: 'home', v: 'тушите в сотейнике' },
  { id: 'carrot_glazed_honey_thyme', title: 'Карамелизованная морковь с медом, маслом и тимьяном', p: 'carrot', a: 'honey', b: 'butter', c: 'fr', v: 'тушите в сковороде' },
  { id: 'carrot_cutlets_semolina_sweet', title: 'Сладковатые морковные котлеты с манкой со сметаной', p: 'carrot', a: 'semolina', b: 'egg', c: 'ru', v: 'обжаривайте с двух сторон' },
  { id: 'beet_braised_sour_cream', title: 'Тушеная свекла в сметане с чесноком и укропом', p: 'beet', a: 'sour_cream', b: 'garlic', c: 'ru', v: 'тушите на тихом огне' },
  { id: 'beet_baked_feta_thyme', title: 'Запеченная свекла дольками с сыром фета и тимьяном', p: 'beet', a: 'feta', b: 'thyme', c: 'home', v: 'запекайте в духовке' },
  { id: 'beet_cutlets_walnut_prunes', title: 'Постные свекольные котлеты с черносливом и орехом', p: 'beet', a: 'prunes', b: 'walnut', c: 'ru', v: 'обжаривайте на сковороде' },
  { id: 'corn_grilled_butter_paprika', title: 'Запеченная кукуруза в початках со сливочным маслом', p: 'corn', a: 'butter', b: 'paprika', c: 'us', v: 'запекайте в духовке' },
  { id: 'corn_feta_lime_mexican', title: 'Мексиканская кукуруза элоте с сыром фета и соком лайма', p: 'corn', a: 'feta', b: 'lime', c: 'mx', v: 'обжаривайте на гриле' },
  { id: 'asparagus_roasted_parmesan', title: 'Запеченная зеленая спаржа с чесноком и пармезаном', p: 'asparagus', a: 'parmesan', b: 'olive_oil', c: 'it', v: 'запекайте в духовке' },
  { id: 'asparagus_lemon_butter_pan', title: 'Молодая спаржа на сковороде с лимонным маслом', p: 'asparagus', a: 'butter', b: 'lemon', c: 'fr', v: 'обжаривайте 8 минут', heatSec: 480 },
  { id: 'spinach_garlic_cream_saute', title: 'Быстрый тушеный шпинат со сливками и чесноком', p: 'spinach', a: 'cream', b: 'garlic', c: 'it', v: 'тушите в сотейнике' },
  { id: 'spinach_chickpeas_tomato_spanish', title: 'Испанский шпинат с турецким нутом и паприкой', p: 'spinach', a: 'chickpeas_canned', b: 'paprika', c: 'es', v: 'тушите в сковороде' },
  { id: 'celery_root_mash_butter', title: 'Шелковистое пюре из корня сельдерея со сливками', p: 'celery_root', a: 'cream', b: 'butter', c: 'fr', v: 'варите до мягкости' },
  { id: 'celery_root_schnitzel_crispy', title: 'Овощной шницель из корня сельдерея в сухарях', p: 'celery_root', a: 'breadcrumbs', b: 'egg', c: 'de', v: 'обжаривайте на масле' },
  { id: 'turnip_honey_butter_stew', title: 'Пареная русская репа с медом и сливочным маслом', p: 'turnip', a: 'honey', b: 'butter', c: 'ru', v: 'тушите под крышкой' },
  { id: 'turnip_baked_potato_cheese', title: 'Запеченная репа с картофелем под сырной корочкой', p: 'turnip', a: 'potato', b: 'hard_cheese', c: 'ru', v: 'запекайте в духовке' },
  { id: 'parsnip_roasted_maple_herbs', title: 'Карамелизированный корень пастернака с медом и розмарином', p: 'parsnip', a: 'honey', b: 'rosemary', c: 'uk', v: 'запекайте в духовке' },
  { id: 'daikon_soy_braised_radish', title: 'Японский тушеный дайкон в сладком соевом бульоне', p: 'daikon', a: 'soy_sauce', b: 'sugar', c: 'jp', v: 'тушите до прозрачности' },
  { id: 'artichokes_baked_garlic_lemon', title: 'Запеченные артишоки с чесноком, лимоном и петрушкой', p: 'artichokes_canned', a: 'lemon', b: 'parsley', c: 'it', v: 'запекайте в духовке' },
  { id: 'leek_gratin_cream_cheese', title: 'Запеченный лук-порей под сливочно-сырным соусом', p: 'leek', a: 'cream', b: 'cheese', c: 'fr', v: 'запекайте в духовке' },
  { id: 'tomato_stuffed_rice_herbs', title: 'Запеченные помидоры, начиненные рисом и базиликом', p: 'tomato', a: 'round_rice', b: 'basil', c: 'gr', v: 'запекайте в духовке' },
  { id: 'bell_pepper_stuffed_rice_veg', title: 'Постные фаршированные перцы с рисом и морковью', p: 'bell_pepper', a: 'round_rice', b: 'carrot', c: 'ru', v: 'тушите в сотейнике' },
  { id: 'bell_pepper_baked_feta_oil', title: 'Печеный сладкий перец, заправленный чесноком и фетой', p: 'bell_pepper', a: 'feta', b: 'olive_oil', c: 'gr', v: 'запекайте в духовке' },
  { id: 'cherry_tomato_feta_baked_pasta', title: 'Запеченные черри с сыром фета, чесноком и базиликом', p: 'cherry_tomato', a: 'feta', b: 'basil', c: 'home', v: 'запекайте в духовке' },
  { id: 'jerusalem_artichoke_roasted', title: 'Печеный топинамбур дольками с розмарином и солью', p: 'Jerusalem_artichoke', a: 'rosemary', b: 'olive_oil', c: 'home', v: 'запекайте в духовке' },
  { id: 'jerusalem_artichoke_cream_stew', title: 'Топинамбур, тушенный в нежных сливках с укропом', p: 'Jerusalem_artichoke', a: 'cream', b: 'dill', c: 'ru', v: 'тушите под крышкой' },
  { id: 'rhubarb_ginger_chutney_side', title: 'Пряное овощное чатни из ревеня с имбирем и яблоком', p: 'rhubarb', a: 'apple', b: 'ginger', c: 'uk', v: 'варите до загустения' },
  { id: 'cabbage_stuffed_veg_buckwheat', title: 'Постные голубцы в капустных листьях с гречкой и грибами', p: 'cabbage', a: 'buckwheat', b: 'champignon', c: 'ru', v: 'тушите в томате' }
];

for (const it of vegDefs) {
  addVeg({
    id: it.id,
    title: it.title,
    cuisine: it.c,
    time: 40,
    active: 20,
    verb: it.v,
    heatSec: it.heatSec,
    desc: `Вкусное и полезное блюдо «${it.title}» из свежих отборных овощей и пряностей.`,
    ings: [
      { ingredient_id: it.p, amount: 400, unit: 'g' },
      it.a,
      it.b,
      'onion',
      'sunflower_oil',
      'salt'
    ]
  });
}

console.log(`Total generated vegetable dishes: ${allVeg.length}`);
saveAndValidateGroup('vegetables.json', allVeg);
