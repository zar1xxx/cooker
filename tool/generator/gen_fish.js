const { saveAndValidateGroup, smartIngredient } = require('./recipe_builder');

function s(text, timer_seconds, tip) {
  const step = { text: text.trim() };
  if (timer_seconds) step.timer_seconds = timer_seconds;
  if (tip) step.tip = tip;
  return step;
}

const allFish = [];

function addFish(def) {
  const id = `fish_${def.id}`;
  const title = def.title;
  const time = def.time || 40;
  const active = def.active || 20;
  const servings = def.servings || 4;
  const cuisine = def.cuisine || 'home';
  const desc = def.desc || `Вкусное рыбное блюдо «${title}» с тонким ароматом специй и нежной текстурой.`;

  const ingsMap = new Map();
  for (const raw of def.ings) {
    const rawId = raw.ingredient_id || raw.id || raw;
    const ingObj = smartIngredient(rawId, raw.amount, raw.unit);
    ingsMap.set(rawId, ingObj);
  }
  const ings = Array.from(ingsMap.values());
  const hasEgg = ingsMap.has('egg');

  let heatVerb = def.verb || 'запекайте в духовке';
  if (hasEgg && !['вар', 'жар', 'запек'].some(k => heatVerb.toLowerCase().includes(k))) {
    heatVerb = 'запекайте в духовке';
  }
  const heatSec = def.heatSec || (hasEgg ? 900 : 720);
  const heatMin = Math.ceil(heatSec / 60);
  const eggNote = hasEgg ? ' и соедините с взбитым яйцом' : '';

  const steps = def.steps || [
    s(`Для блюда «${title}» подготовьте филе или морепродукты: промойте прохладной водой и обсушите бумажным полотенцем.`),
    s(`Овощи, зелень и ароматные добавки для «${title}» измельчите на разделочной доске и выложите в форму.`),
    s(`${heatVerb.charAt(0).toUpperCase() + heatVerb.slice(1)} рыбу или морепродукты${eggNote} для «${title}» в течение ${heatMin} минут до готовности и румяности.`, heatSec),
    s(`Перед подачей дайте блюду «${title}» немного постоять и украсьте свежей зеленью к столу.`)
  ];

  // Fix "до готовности" to always have readiness sign!
  steps[2].text = `${heatVerb.charAt(0).toUpperCase() + heatVerb.slice(1)} основной продукт${eggNote} для «${title}» в течение ${heatMin} минут до румяной корочки и мягкости.`;

  allFish.push({
    id: id,
    title: title,
    dish_type: 'main',
    dish_group: 'fish_seafood',
    cuisine: cuisine,
    total_minutes: time,
    active_minutes: active,
    servings: servings,
    description: desc,
    ingredients: ings,
    steps: steps
  });
}

// 170 Distinct Fish & Seafood Recipes
const fishDefs = [
  // Pollock (Минтай) - 12
  { id: 'pollock_sour_cream_carrot', title: 'Минтай, тушенный с морковью в нежном сметанном соусе', f: 'pollock', a: 'sour_cream', b: 'carrot', c: 'ru', v: 'тушите на слабом огне' },
  { id: 'pollock_tomato_marinade', title: 'Филе минтая под густым пряным томатным маринадом', f: 'pollock', a: 'tomato_paste', b: 'sugar', c: 'ru', v: 'тушите в сотейнике' },
  { id: 'pollock_foil_lemon_herbs', title: 'Нежный минтай, запеченный в фольге с лимоном и укропом', f: 'pollock', a: 'lemon', b: 'dill', c: 'home', v: 'запекайте в духовке' },
  { id: 'pollock_broccoli_cream_bake', title: 'Запеканка из филе минтая с брокколи под сливками', f: 'pollock', a: 'broccoli', b: 'cream', c: 'home', v: 'запекайте в духовке' },
  { id: 'pollock_spinach_mozzarella', title: 'Минтай под подушкой из свежего шпината и моцареллы', f: 'pollock', a: 'spinach', b: 'mozzarella', c: 'it', v: 'запекайте в духовке' },
  { id: 'pollock_garlic_breadcrumbs', title: 'Хрустящие палочки из минтая в чесночной панировке', f: 'pollock', a: 'breadcrumbs', b: 'garlic', c: 'home', v: 'обжаривайте на сковороде' },
  { id: 'pollock_zucchini_herbs', title: 'Рагу из минтая с молодыми кабачками и базиликом', f: 'pollock', a: 'zucchini', b: 'basil', c: 'home', v: 'тушите под крышкой' },
  { id: 'pollock_coconut_curry', title: 'Карри из филе минтая с кокосовым молоком и куркумой', f: 'pollock', a: 'coconut_milk', b: 'curry_powder', c: 'in', v: 'тушите в глубокой сковороде' },
  { id: 'pollock_cauliflower_gratin', title: 'Рыбный гратен из минтая с цветной капустой', f: 'pollock', a: 'cauliflower', b: 'hard_cheese', c: 'fr', v: 'запекайте в духовке' },
  { id: 'pollock_sauerkraut_stew', title: 'Минтай по-деревенски с тушеной квашеной капустой', f: 'pollock', a: 'sauerkraut', b: 'bay_leaf', c: 'ru', v: 'тушите на среднем огне' },
  { id: 'pollock_green_beans_tomato', title: 'Филе минтая со стручковой фасолью и сладким перцем', f: 'pollock', a: 'green_beans', b: 'bell_pepper', c: 'home', v: 'обжаривайте в сковороде' },
  { id: 'pollock_oat_cutlets', title: 'Нежные котлеты из минтая с овсяными хлопьями', f: 'pollock', a: 'oatmeal', b: 'egg', c: 'ru', v: 'обжаривайте на масле' },

  // Cod (Треска) - 15
  { id: 'cod_mediterranean_olives', title: 'Треска по-средиземноморски с оливками и каперсами', f: 'cod', a: 'olives', b: 'capers', c: 'es', v: 'запекайте в духовке' },
  { id: 'cod_cherry_tomato_thyme', title: 'Филе трески, запеченное с томатами черри и тимьяном', f: 'cod', a: 'cherry_tomato', b: 'thyme', c: 'fr', v: 'запекайте в духовке' },
  { id: 'cod_cream_mustard_sauce', title: 'Треска в сливочно-горчичном соусе по-французски', f: 'cod', a: 'cream', b: 'mustard', c: 'fr', v: 'тушите на тихом огне' },
  { id: 'cod_leek_butter_braise', title: 'Филе трески, томленное с луком-пореем в масле', f: 'cod', a: 'leek', b: 'butter', c: 'home', v: 'тушите в сотейнике' },
  { id: 'cod_eggplant_garlic_bake', title: 'Треска с печеными баклажанами и ароматным чесноком', f: 'cod', a: 'eggplant', b: 'garlic', c: 'gr', v: 'запекайте в духовке' },
  { id: 'cod_bacon_wrapped_rosemary', title: 'Филе трески в хрустящем беконе с веточкой розмарина', f: 'cod', a: 'bacon', b: 'rosemary', c: 'uk', v: 'запекайте в духовке', heatSec: 1000 },
  { id: 'cod_corn_chowder_bake', title: 'Сытная запеканка из трески со сладкой кукурузой', f: 'cod', a: 'corn_canned', b: 'sour_cream', c: 'us', v: 'запекайте в духовке' },
  { id: 'cod_mashed_potato_brandade', title: 'Брандада из трески с картофелем и оливковым маслом', f: 'cod', a: 'olive_oil', b: 'potato', c: 'fr', v: 'запекайте в духовке' },
  { id: 'cod_asparagus_lemon_butter', title: 'Стейк трески со спаржей в лимонно-сливочном соусе', f: 'cod', a: 'asparagus', b: 'lemon', c: 'home', v: 'обжаривайте на сковороде' },
  { id: 'cod_chickpea_spinach_stew', title: 'Испанская треска, тушенная с нутом и шпинатом', f: 'cod', a: 'chickpeas_canned', b: 'spinach', c: 'es', v: 'тушите в сотейнике' },
  { id: 'cod_green_peas_mint_puree', title: 'Жареная треска с нежным пюре из зеленого горошка', f: 'cod', a: 'green_peas', b: 'mint', c: 'uk', v: 'обжаривайте на сковороде' },
  { id: 'cod_feta_tomato_greek', title: 'Треска по-гречески с сыром фета и орегано', f: 'cod', a: 'feta', b: 'oregano', c: 'gr', v: 'запекайте в духовке' },
  { id: 'cod_parmesan_crust_bake', title: 'Хрустящее филе трески под сырной шубкой из пармезана', f: 'cod', a: 'parmesan', b: 'breadcrumbs', c: 'it', v: 'запекайте в духовке' },
  { id: 'cod_ginger_soy_steamed', title: 'Азиатская треска на пару с имбирем и кунжутом', f: 'cod', a: 'ginger', b: 'soy_sauce', c: 'cn', v: 'варите на пару' },
  { id: 'cod_sweet_potato_paprika', title: 'Запеченная треска с дольками батата и паприкой', f: 'cod', a: 'sweet_potato', b: 'paprika', c: 'home', v: 'запекайте в духовке' },

  // Hake (Хек) - 12
  { id: 'hake_tomato_bell_pepper', title: 'Хек по-домашнему с болгарским перцем в томате', f: 'hake', a: 'bell_pepper', b: 'tomato', c: 'ru', v: 'тушите в сковороде' },
  { id: 'hake_garlic_paprika_fried', title: 'Жареный хек с золотистой корочкой и паприкой', f: 'hake', a: 'paprika', b: 'flour', c: 'home', v: 'обжаривайте с двух сторон' },
  { id: 'hake_champignon_cream_bake', title: 'Тушки хека со свежими шампиньонами в сливках', f: 'hake', a: 'champignon', b: 'cream', c: 'home', v: 'запекайте в духовке' },
  { id: 'hake_carrot_onion_marinade', title: 'Хек под сладкой овощной шубой из моркови с пастой', f: 'hake', a: 'carrot', b: 'tomato_paste', c: 'ru', v: 'тушите под крышкой' },
  { id: 'hake_kefir_herb_baked', title: 'Диетический хек в кефирно-укропном соусе в духовке', f: 'hake', a: 'kefir', b: 'dill', c: 'home', v: 'запекайте в духовке' },
  { id: 'hake_pickles_olives_tartar', title: 'Филе хека в сметанном соусе с солеными огурцами', f: 'hake', a: 'pickles', b: 'sour_cream', c: 'home', v: 'тушите на среднем огне' },
  { id: 'hake_squash_dill_stew', title: 'Нежный хек, томленный с кубиками сладкой тыквы', f: 'hake', a: 'squash', b: 'butter', c: 'home', v: 'тушите в сотейнике' },
  { id: 'hake_potato_layer_pie', title: 'Сытная картофельная запеканка с кусочками хека', f: 'hake', a: 'potato', b: 'egg', c: 'ru', v: 'запекайте в духовке' },
  { id: 'hake_green_beans_soy', title: 'Хек со стручковой фасолью в легком соевом соусе', f: 'hake', a: 'green_beans', b: 'soy_sauce', c: 'cn', v: 'обжаривайте в воке' },
  { id: 'hake_rice_baked_pot', title: 'Хек с рассыпчатым рисом и овощами в горшочке', f: 'hake', a: 'round_rice', b: 'carrot', c: 'ru', v: 'запекайте в духовке' },
  { id: 'hake_red_onion_vinegar', title: 'Маринованный жареный хек с красным луком', f: 'hake', a: 'red_onion', b: 'apple_vinegar', c: 'es', v: 'обжаривайте на масле' },
  { id: 'hake_cottage_cheese_souffle', title: 'Рыбное суфле из хека с творогом для легкого ужина', f: 'hake', a: 'cottage_cheese', b: 'egg', c: 'home', v: 'запекайте в духовке' },

  // Salmon & Trout (Лосось и Форель) - 35
  { id: 'salmon_teriyaki_sesame', title: 'Стейк лосося в глянцевом соусе терияки с кунжутом', f: 'salmon', a: 'soy_sauce', b: 'sesame', c: 'jp', v: 'обжаривайте на сковороде' },
  { id: 'salmon_honey_mustard_glaze', title: 'Запеченный лосось под медово-горчичной глазурью', f: 'salmon', a: 'honey', b: 'mustard', c: 'home', v: 'запекайте в духовке' },
  { id: 'salmon_spinach_cream_pasta', title: 'Сливочный лосось со свежим шпинатом и лимоном', f: 'salmon', a: 'spinach', b: 'cream', c: 'it', v: 'тушите в сковороде' },
  { id: 'salmon_orange_rosemary', title: 'Праздничный лосось в духовке с апельсином и розмарином', f: 'salmon', a: 'orange', b: 'rosemary', c: 'fr', v: 'запекайте в духовке' },
  { id: 'salmon_avocado_quinoa_bowl', title: 'Теплый боул с запеченным лососем, крупой киноа и спелым авокадо', f: 'salmon', a: 'quinoa', b: 'avocado', c: 'home', v: 'запекайте в духовке' },
  { id: 'salmon_asparagus_parmesan', title: 'Лосось на подушке из зеленой спаржи под пармезаном', f: 'salmon', a: 'asparagus', b: 'parmesan', c: 'it', v: 'запекайте в духовке' },
  { id: 'salmon_pistachio_crust', title: 'Филе красной рыбы в хрустящей фисташковой корочке', f: 'salmon', a: 'pistachio', b: 'olive_oil', c: 'home', v: 'запекайте в духовке' },
  { id: 'salmon_cream_cheese_dill', title: 'Запеченный лосось с творожным сыром и свежим укропом', f: 'salmon', a: 'cream_cheese', b: 'dill', c: 'home', v: 'запекайте в духовке' },
  { id: 'salmon_broccoli_cauliflower', title: 'Лосось с соцветиями брокколи в нежном соусе', f: 'salmon', a: 'broccoli', b: 'sour_cream', c: 'home', v: 'запекайте в духовке' },
  { id: 'salmon_couscous_tomato', title: 'Жареный стейк лосося с кускусом и черри', f: 'salmon', a: 'couscous', b: 'cherry_tomato', c: 'home', v: 'обжаривайте на сковороде' },
  { id: 'salmon_pasta_caviar_cream', title: 'Паста фетучини с нежным лососем в сливочном соусе', f: 'salmon', a: 'spaghetti', b: 'cream', c: 'it', v: 'тушите в сотейнике' },
  { id: 'salmon_pomegranate_walnut', title: 'Лосось по-кавказски с гранатом и грецким орехом', f: 'salmon', a: 'pomegranate', b: 'walnut', c: 'ge', v: 'запекайте в духовке' },
  { id: 'salmon_coconut_lime_curry', title: 'Тайский лосось в кокосовом молоке с соком лайма', f: 'salmon', a: 'coconut_milk', b: 'lime', c: 'th', v: 'тушите в сковороде' },
  { id: 'salmon_zucchini_noodles', title: 'Стейк из семги с румяными молодыми кабачками', f: 'salmon', a: 'zucchini', b: 'garlic', c: 'home', v: 'обжаривайте на сковороде' },
  { id: 'salmon_basmati_peas', title: 'Лосось, запеченный с рисом басмати и зеленым горошком', f: 'salmon', a: 'basmati_rice', b: 'green_peas', c: 'home', v: 'запекайте в духовке' },
  { id: 'salmon_cranberry_thyme', title: 'Красная рыба под пряным клюквенным соусом с тимьяном', f: 'salmon', a: 'cranberry', b: 'thyme', c: 'home', v: 'запекайте в духовке' },
  { id: 'salmon_sweet_potato_mash', title: 'Жареное филе лосося с нежным пюре из батата', f: 'salmon', a: 'sweet_potato', b: 'butter', c: 'us', v: 'обжаривайте на сковороде' },
  { id: 'trout_lemon_garlic_foil', title: 'Радужная форель, запеченная целиком с лимоном', f: 'trout', a: 'lemon', b: 'garlic', c: 'home', v: 'запекайте в духовке' },
  { id: 'trout_almond_butter_amandine', title: 'Форель по-французски амандин с миндалем и маслом', f: 'trout', a: 'almond', b: 'butter', c: 'fr', v: 'обжаривайте в масле' },
  { id: 'trout_champignon_wine_cream', title: 'Стейки форели в сливочном соусе с шампиньонами', f: 'trout', a: 'champignon', b: 'cream', c: 'home', v: 'тушите в сковороде' },
  { id: 'trout_tarragon_sour_cream', title: 'Форель, томленная в сметане с ароматным эстрагоном', f: 'trout', a: 'tarragon', b: 'sour_cream', c: 'ge', v: 'тушите на тихом огне' },
  { id: 'trout_bulgur_cilantro', title: 'Форель с рассыпчатым булгуром и свежей кинзой', f: 'trout', a: 'bulgur', b: 'cilantro', c: 'tr', v: 'запекайте в духовке' },
  { id: 'trout_artichoke_olives', title: 'Филе форели с консервированными артишоками и маслинами', f: 'trout', a: 'artichokes_canned', b: 'olives', c: 'it', v: 'запекайте в духовке' },
  { id: 'trout_leek_parsley', title: 'Запеченная в пергаменте форель с пореем и петрушкой', f: 'trout', a: 'leek', b: 'parsley', c: 'home', v: 'запекайте в духовке' },
  { id: 'trout_bell_pepper_rice', title: 'Стейки форели с болгарским перцем и рисом', f: 'trout', a: 'bell_pepper', b: 'round_rice', c: 'home', v: 'запекайте в духовке' },
  { id: 'trout_ginger_honey_soy', title: 'Глазированная форель с медом и тертым имбирем', f: 'trout', a: 'ginger', b: 'honey', c: 'jp', v: 'запекайте в духовке' },
  { id: 'trout_spinach_feta_bake', title: 'Запеченное филе форели со шпинатом и сыром фета', f: 'trout', a: 'spinach', b: 'feta', c: 'gr', v: 'запекайте в духовке' },
  { id: 'trout_grapefruit_mint', title: 'Праздничная форель с дольками грейпфрута и мятой', f: 'trout', a: 'grapefruit', b: 'mint', c: 'home', v: 'запекайте в духовке' },
  { id: 'trout_eggplant_tomato', title: 'Форель, тушенная по-кавказски с баклажаном и томатом', f: 'trout', a: 'eggplant', b: 'tomato', c: 'ge', v: 'тушите в сотейнике' },
  { id: 'trout_carrot_celery_steamed', title: 'Диетическая паровая форель с морковью и сельдереем', f: 'trout', a: 'carrot', b: 'celery', c: 'home', v: 'варите на пару' },
  { id: 'trout_sesame_noodles', title: 'Лапша с кусочками обжаренной форели и кунжутом', f: 'trout', a: 'noodles', b: 'sesame', c: 'cn', v: 'обжаривайте в воке' },
  { id: 'salmon_shiitake_bokchoy', title: 'Лосось с грибами шиитаке и соевым соусом', f: 'salmon', a: 'shiitake', b: 'soy_sauce', c: 'jp', v: 'обжаривайте на сковороде' },
  { id: 'salmon_capers_lemon_butter', title: 'Нежное филе лосося под соусом с каперсами', f: 'salmon', a: 'capers', b: 'lemon', c: 'it', v: 'обжаривайте на сковороде' },
  { id: 'salmon_pumpkin_seeds_crust', title: 'Лосось под хрустящей посыпкой из тыквенных семечек', f: 'salmon', a: 'pumpkin_seeds', b: 'garlic', c: 'home', v: 'запекайте в духовке' },
  { id: 'salmon_red_cabbage_apple', title: 'Теплое блюдо из лосося с тушеной красной капустой', f: 'salmon', a: 'red_cabbage', b: 'apple', c: 'de', v: 'запекайте в духовке' },

  // Mackerel & Herring (Скумбрия и Сельдь - обязательно >= 8 мин термообработки!) - 25
  { id: 'mackerel_baked_lemon_onion', title: 'Скумбрия, запеченная в фольге с луком и лимоном', f: 'mackerel', a: 'lemon', b: 'dill', c: 'ru', v: 'запекайте в духовке' },
  { id: 'mackerel_mustard_soy_bake', title: 'Сочная скумбрия в горчично-соевом соусе в духовке', f: 'mackerel', a: 'mustard', b: 'soy_sauce', c: 'home', v: 'запекайте в духовке' },
  { id: 'mackerel_potato_garlic_tray', title: 'Скумбрия, запеченная на противне с картошкой', f: 'mackerel', a: 'potato', b: 'garlic', c: 'ru', v: 'запекайте в духовке' },
  { id: 'mackerel_tomato_bell_pepper', title: 'Скумбрия по-болгарски со сладким перцем и томатами', f: 'mackerel', a: 'bell_pepper', b: 'tomato', c: 'home', v: 'запекайте в духовке' },
  { id: 'mackerel_orange_thyme_roast', title: 'Запеченная скумбрия с апельсином и веточкой тимьяна', f: 'mackerel', a: 'orange', b: 'thyme', c: 'home', v: 'запекайте в духовке' },
  { id: 'mackerel_sour_cream_herbs', title: 'Тушеная скумбрия в сметане с зеленью укропа', f: 'mackerel', a: 'sour_cream', b: 'parsley', c: 'ru', v: 'тушите в духовке' },
  { id: 'mackerel_adjika_garlic_grill', title: 'Пряная скумбрия на решетке с кавказской аджикой', f: 'mackerel', a: 'adjika', b: 'cilantro', c: 'ge', v: 'запекайте на гриле' },
  { id: 'mackerel_buckwheat_mushrooms', title: 'Скумбрия с начинкой из гречки и шампиньонов в духовке', f: 'mackerel', a: 'buckwheat', b: 'champignon', c: 'ru', v: 'запекайте в духовке' },
  { id: 'mackerel_apple_prunes_bake', title: 'Ароматная скумбрия, запеченная с яблоками и черносливом', f: 'mackerel', a: 'apple', b: 'prunes', c: 'home', v: 'запекайте в духовке' },
  { id: 'mackerel_carrot_tomato_paste', title: 'Домашняя скумбрия в густом томатном соусе с морковью', f: 'mackerel', a: 'carrot', b: 'tomato_paste', c: 'ru', v: 'тушите на тихом огне' },
  { id: 'mackerel_olive_capers_sicilian', title: 'Скумбрия по-сицилийски с маслинами и каперсами', f: 'mackerel', a: 'olives', b: 'capers', c: 'it', v: 'запекайте в духовке' },
  { id: 'mackerel_ginger_turmeric_pan', title: 'Пряные кусочки скумбрии с куркумой и имбирем', f: 'mackerel', a: 'turmeric', b: 'ginger', c: 'in', v: 'обжаривайте на сковороде' },
  { id: 'mackerel_honey_vinegar_glaze', title: 'Румяная скумбрия в сладковато-пряной глазури', f: 'mackerel', a: 'honey', b: 'apple_vinegar', c: 'home', v: 'запекайте в духовке' },
  { id: 'mackerel_zucchini_eggplant', title: 'Скумбрия на овощной подушке из кабачков и баклажанов', f: 'mackerel', a: 'zucchini', b: 'eggplant', c: 'home', v: 'запекайте в духовке' },
  { id: 'herring_fried_scandinavian', title: 'Жареная свежая сельдь по-скандинавски в сухарях', f: 'herring', a: 'breadcrumbs', b: 'butter', c: 'home', v: 'обжаривайте на сковороде' },
  { id: 'herring_baked_mustard_potato', title: 'Свежая сельдь, запеченная с горчицей и картофелем', f: 'herring', a: 'mustard', b: 'potato', c: 'home', v: 'запекайте в духовке' },
  { id: 'herring_baked_sour_cream_dill', title: 'Свежая сельдь, томленная в сметане с укропом', f: 'herring', a: 'sour_cream', b: 'dill', c: 'ru', v: 'запекайте в духовке' },
  { id: 'herring_fried_red_onion_apple', title: 'Жареное филе свежей сельди с яблоками и луком', f: 'herring', a: 'apple', b: 'red_onion', c: 'de', v: 'обжаривайте на сковороде' },
  { id: 'herring_tomato_stew', title: 'Свежая сельдь, тушенная в томатном соусе с чесноком', f: 'herring', a: 'tomatoes_canned', b: 'garlic', c: 'ru', v: 'тушите на среднем огне' },
  { id: 'herring_baked_tomato_olives', title: 'Филе сельди в духовке с помидорами и маслинами', f: 'herring', a: 'tomato', b: 'olives', c: 'it', v: 'запекайте в духовке' },
  { id: 'herring_oat_fried', title: 'Хрустящая сельдь в панировке из ржаной муки', f: 'herring', a: 'rye_flour', b: 'dill', c: 'ru', v: 'обжаривайте на сковороде' },
  { id: 'herring_cabbage_braised', title: 'Свежая сельдь, тушенная с капустой и морковью', f: 'herring', a: 'cabbage', b: 'carrot', c: 'ru', v: 'тушите под крышкой' },
  { id: 'herring_lemon_herb_foil', title: 'Запеченная в фольге свежая сельдь с лимоном и петрушкой', f: 'herring', a: 'lemon', b: 'parsley', c: 'home', v: 'запекайте в духовке' },
  { id: 'herring_beet_sour_cream_bake', title: 'Горячая запеканка со свежей сельдью и свеклой', f: 'herring', a: 'beet', b: 'sour_cream', c: 'home', v: 'запекайте в духовке' },
  { id: 'mackerel_green_onion_sesame', title: 'Скумбрия в сковороде с зеленым луком и кунжутом', f: 'mackerel', a: 'green_onion', b: 'sesame_oil', c: 'kr', v: 'обжаривайте на сковороде' },

  // Pike, Perch, Carp, Catfish, Generic Fish (Щука, Судак/Окунь, Карп, Сом, Рыба) - 38
  { id: 'pike_cutlets_pork_lard', title: 'Классические щучьи котлеты со свиным салом и луком', f: 'pike', a: 'lard', b: 'white_bread', c: 'ru', v: 'обжаривайте на сковороде' },
  { id: 'pike_baked_sour_cream', title: 'Щука, запеченная кусочками в густой сметане', f: 'pike', a: 'sour_cream', b: 'butter', c: 'ru', v: 'запекайте в духовке' },
  { id: 'pike_stuffed_vegetables', title: 'Фаршированная щука по-праздничному с морковью', f: 'pike', a: 'carrot', b: 'egg', c: 'ru', v: 'запекайте в духовке' },
  { id: 'pike_tomato_celery_stew', title: 'Щука, тушенная с корнем сельдерея в томатном соусе', f: 'pike', a: 'celery_root', b: 'tomato_paste', c: 'home', v: 'тушите в сотейнике' },
  { id: 'pike_garlic_butter_fried', title: 'Хрустящие стейки из щуки с чесночным маслом', f: 'pike', a: 'garlic', b: 'butter', c: 'ru', v: 'обжаривайте до румяности' },
  { id: 'pike_pickles_mushroom_pot', title: 'Жаркое из щуки с солеными огурцами и грибами', f: 'pike', a: 'pickles', b: 'champignon', c: 'ru', v: 'запекайте в горшочке' },
  { id: 'perch_white_cream_lemon', title: 'Нежное филе судака или окуня в сливочно-лимонном соусе', f: 'perch', a: 'cream', b: 'lemon', c: 'ru', v: 'тушите на сковороде' },
  { id: 'perch_polish_egg_sauce', title: 'Судак по-польски с рубленым вареным яйцом в масле', f: 'perch', a: 'egg', b: 'butter', c: 'pl', v: 'варите на слабом огне' },
  { id: 'perch_baked_mushrooms_cheese', title: 'Филе окуня, запеченное с грибами под сыром', f: 'perch', a: 'champignon', b: 'hard_cheese', c: 'ru', v: 'запекайте в духовке' },
  { id: 'perch_zucchini_bell_pepper', title: 'Окунь в фольге с молодым кабачком и болгарским перцем', f: 'perch', a: 'zucchini', b: 'bell_pepper', c: 'home', v: 'запекайте в духовке' },
  { id: 'perch_tomato_basil_pan', title: 'Жареный речной окунь со спелыми томатами и базиликом', f: 'perch', a: 'tomato', b: 'basil', c: 'it', v: 'обжаривайте на сковороде' },
  { id: 'perch_spinach_gratin', title: 'Гратен из окуня и шпината под нежным сыром', f: 'perch', a: 'spinach', b: 'mozzarella', c: 'fr', v: 'запекайте в духовке' },
  { id: 'carp_baked_sour_cream_herbs', title: 'Зеркальный карп в духовке со сметаной и петрушкой', f: 'carp', a: 'sour_cream', b: 'parsley', c: 'ru', v: 'запекайте в духовке' },
  { id: 'carp_stuffed_buckwheat_mushrooms', title: 'Карп с начинкой из гречневой каши и грибов', f: 'carp', a: 'buckwheat', b: 'champignon', c: 'ru', v: 'запекайте в духовке' },
  { id: 'carp_sweet_sour_asian', title: 'Хрустящий карп по-китайски в кисло-сладком соусе', f: 'carp', a: 'soy_sauce', b: 'apple_vinegar', c: 'cn', v: 'обжаривайте в воке' },
  { id: 'carp_potato_onion_tray', title: 'Домашний карп, запеченный на картофельной подушке со сметаной', f: 'carp', a: 'potato', b: 'sour_cream', c: 'ru', v: 'запекайте в духовке' },
  { id: 'carp_garlic_rosemary_foil', title: 'Запеченный в фольге карп с чесноком, лимоном и розмарином', f: 'carp', a: 'garlic', b: 'rosemary', c: 'home', v: 'запекайте в духовке' },
  { id: 'carp_lecho_braised', title: 'Кусочки карпа, тушенные в сладком овощном лечо', f: 'carp', a: 'lecho', b: 'dill', c: 'ru', v: 'тушите в сотейнике' },
  { id: 'catfish_fried_cornmeal', title: 'Хрустящие кусочки сома в кукурузной панировке', f: 'catfish', a: 'cornmeal', b: 'paprika', c: 'us', v: 'обжаривайте в масле' },
  { id: 'catfish_tomato_garlic_stew', title: 'Сом по-астрахански, тушенный в густом томате', f: 'catfish', a: 'tomato_paste', b: 'garlic', c: 'ru', v: 'тушите в сотейнике' },
  { id: 'catfish_cream_baked', title: 'Нежное филе сома, запеченное под сливками и сыром', f: 'catfish', a: 'cream', b: 'cheese', c: 'home', v: 'запекайте в духовке' },
  { id: 'catfish_soy_ginger_wok', title: 'Карамелизованный сом с имбирем и соевым соусом', f: 'catfish', a: 'ginger', b: 'soy_sauce', c: 'cn', v: 'обжаривайте в воке' },
  { id: 'catfish_lemon_herb_foil', title: 'Стейки сома на овощах, запеченные в фольге с лимоном', f: 'catfish', a: 'lemon', b: 'zucchini', c: 'home', v: 'запекайте в духовке' },
  { id: 'fish_pie_rice_egg', title: 'Рыбный пирог с рассыпчатым рисом и вареным яйцом', f: 'fish', a: 'round_rice', b: 'egg', c: 'ru', v: 'запекайте в духовке' },
  { id: 'fish_casserole_broccoli', title: 'Рыбная запеканка с брокколи в сырном соусе', f: 'fish', a: 'broccoli', b: 'hard_cheese', c: 'home', v: 'запекайте в духовке' },
  { id: 'fish_meatballs_tomato', title: 'Рыбные тефтели в нежном томатно-сметанном соусе', f: 'fish', a: 'tomato_sauce', b: 'round_rice', c: 'ru', v: 'тушите в сотейнике' },
  { id: 'fish_cutlets_semolina', title: 'Пышные рыбные котлеты с манкой и жареным луком', f: 'fish', a: 'semolina', b: 'egg', c: 'ru', v: 'обжаривайте на сковороде' },
  { id: 'fish_stew_green_peas', title: 'Рыбное рагу со сладким зеленым горошком в сливках', f: 'fish', a: 'green_peas', b: 'cream', c: 'home', v: 'тушите в сотейнике' },
  { id: 'fish_baked_pesto_tomato', title: 'Белая рыба под базиликом, чесноком и помидорами', f: 'fish', a: 'basil', b: 'tomato', c: 'it', v: 'запекайте в духовке' },
  { id: 'fish_nuggets_oats', title: 'Хрустящие домашние рыбные наггетсы в сухарях', f: 'fish', a: 'breadcrumbs', b: 'egg', c: 'home', v: 'обжаривайте до золотистости' },
  { id: 'fish_kefir_batter_fried', title: 'Рыба в нежном воздушном кляре на кефире', f: 'fish', a: 'kefir', b: 'flour', c: 'ru', v: 'обжаривайте в масле' },
  { id: 'fish_beans_canned_stew', title: 'Рыба, тушенная с белой фасолью и болгарским перцем', f: 'fish', a: 'beans_canned', b: 'bell_pepper', c: 'es', v: 'тушите в сотейнике' },
  { id: 'fish_coconut_curry_mango', title: 'Нежное рыбное карри в пряном кокосовом молоке', f: 'fish', a: 'coconut_milk', b: 'curry_powder', c: 'th', v: 'тушите в сковороде' },
  { id: 'fish_sauerkraut_baked', title: 'Филе белой рыбы, запеченное на подушке из квашеной капусты', f: 'fish', a: 'sauerkraut', b: 'sour_cream', c: 'de', v: 'запекайте в духовке' },
  { id: 'fish_walnut_herbs_georgian', title: 'Жареная рыба по-грузински в ореховой подливке с кинзой', f: 'fish', a: 'walnut', b: 'cilantro', c: 'ge', v: 'обжаривайте на сковороде' },
  { id: 'fish_turmeric_ginger_pan', title: 'Пряная жареная рыба с куркумой, лимоном и чесноком', f: 'fish', a: 'turmeric', b: 'lemon', c: 'in', v: 'обжаривайте на сковороде' },
  { id: 'fish_milk_poached_butter', title: 'Филе рыбы, припущенное в молоке со сливочным маслом', f: 'fish', a: 'milk', b: 'butter', c: 'home', v: 'варите на тихом огне' },
  { id: 'celery_carrot_steam', title: 'Легкая паровая рыба с молодым сельдереем и укропом', f: 'fish', a: 'celery', b: 'dill', c: 'home', v: 'варите на пару' },

  // Seafood: Shrimp, Squid, Mussels, Crab sticks, Seafood mix - 35
  { id: 'shrimp_garlic_butter_lemon', title: 'Королевские креветки в чесночно-сливочном масле с лимоном', f: 'shrimp', a: 'garlic', b: 'butter', c: 'home', v: 'обжаривайте на сильном огне' },
  { id: 'shrimp_curry_coconut_rice', title: 'Креветки карри в кокосовом молоке с рисом басмати', f: 'shrimp', a: 'coconut_milk', b: 'curry_powder', c: 'th', v: 'тушите в сковороде' },
  { id: 'shrimp_spaghetti_tomato', title: 'Спагетти с креветками, томатами черри и чесноком', f: 'shrimp', a: 'spaghetti', b: 'cherry_tomato', c: 'it', v: 'обжаривайте в сотейнике' },
  { id: 'shrimp_chili_honey_soy', title: 'Острые креветки в медово-соевой глазури с чили', f: 'shrimp', a: 'honey', b: 'chili_pepper', c: 'cn', v: 'обжаривайте на сковороде' },
  { id: 'shrimp_risotto_parmesan', title: 'Итальянское ризотто с креветками, тимьяном и пармезаном', f: 'shrimp', a: 'round_rice', b: 'parmesan', c: 'it', v: 'тушите на среднем огне' },
  { id: 'shrimp_noodles_wok_ginger', title: 'Лапша вок с креветками, имбирем и кунжутом', f: 'shrimp', a: 'noodles', b: 'ginger', c: 'cn', v: 'обжаривайте в воке' },
  { id: 'shrimp_spinach_cream_cheese', title: 'Нежные креветки в соусе со шпинатом и сливочным сыром', f: 'shrimp', a: 'spinach', b: 'cream_cheese', c: 'home', v: 'тушите на тихом огне' },
  { id: 'shrimp_avocado_mango_tacos', title: 'Горячие такос с креветками, авокадо и сладким перцем', f: 'shrimp', a: 'tortilla', b: 'avocado', c: 'mx', v: 'обжаривайте на сковороде' },
  { id: 'shrimp_quinoa_lemon_herb', title: 'Теплый гарнир с киноа, креветками и свежим укропом', f: 'shrimp', a: 'quinoa', b: 'lemon', c: 'home', v: 'обжаривайте на сковороде' },
  { id: 'shrimp_eggplant_soy_wok', title: 'Жареные креветки с кубиками баклажанов в соевом соусе', f: 'shrimp', a: 'eggplant', b: 'soy_sauce', c: 'jp', v: 'обжаривайте в воке' },
  { id: 'squid_rings_sour_cream', title: 'Кальмары, тушенные в густом сметанном соусе с луком', f: 'squid', a: 'sour_cream', b: 'dill', c: 'ru', v: 'тушите 8 минут на среднем огне' },
  { id: 'squid_stuffed_rice_mushroom', title: 'Фаршированные кальмары с рисом и жареными шампиньонами', f: 'squid', a: 'round_rice', b: 'champignon', c: 'home', v: 'запекайте в духовке' },
  { id: 'squid_garlic_olive_herbs', title: 'Кольца кальмара по-гречески с чесноком и орегано', f: 'squid', a: 'olive_oil', b: 'oregano', c: 'gr', v: 'обжаривайте на сковороде' },
  { id: 'squid_crispy_batter_lemon', title: 'Хрустящие кольца кальмаров в легкой панировке с лимоном', f: 'squid', a: 'flour', b: 'lemon', c: 'es', v: 'обжаривайте в масле' },
  { id: 'squid_bell_pepper_teriyaki', title: 'Кальмар со сладким перцем в соусе терияки с кунжутом', f: 'squid', a: 'bell_pepper', b: 'sesame', c: 'jp', v: 'обжаривайте в воке' },
  { id: 'squid_tomato_olives_stew', title: 'Тушеные кальмары в томатном соусе с маслинами', f: 'squid', a: 'tomatoes_canned', b: 'olives', c: 'it', v: 'тушите в сотейнике' },
  { id: 'squid_zucchini_pasta', title: 'Паста с кольцами кальмара, кабачком и чесноком', f: 'squid', a: 'pasta', b: 'zucchini', c: 'it', v: 'обжаривайте в сковороде' },
  { id: 'squid_stuffed_cottage_herb', title: 'Кальмары, фаршированные творогом с укропом и чесноком', f: 'squid', a: 'cottage_cheese', b: 'egg', c: 'home', v: 'запекайте в духовке' },
  { id: 'mussels_creamy_garlic_wine', title: 'Мидии в сливочно-чесночном соусе с петрушкой', f: 'mussels', a: 'cream', b: 'garlic', c: 'fr', v: 'тушите в сотейнике' },
  { id: 'mussels_marinara_tomato', title: 'Мидии в пикантном томатном соусе маринара с базиликом', f: 'mussels', a: 'tomato_sauce', b: 'basil', c: 'it', v: 'тушите под крышкой' },
  { id: 'mussels_pilaf_black_sea', title: 'Черноморский плов с мидиями, морковью и пряностями', f: 'mussels', a: 'round_rice', b: 'carrot', c: 'ru', v: 'тушите в казане' },
  { id: 'mussels_baked_cheese_garlic', title: 'Мидии, запеченные под ароматной чесночно-сырной шапочкой', f: 'mussels', a: 'hard_cheese', b: 'butter', c: 'jp', v: 'запекайте в духовке' },
  { id: 'mussels_pasta_chili_oil', title: 'Спагетти с мидиями, острым перчиком чили и оливковым маслом', f: 'mussels', a: 'spaghetti', b: 'chili_pepper', c: 'it', v: 'обжаривайте в сотейнике' },
  { id: 'mussels_thai_coconut_ginger', title: 'Тайские мидии в кокосовом молоке со свежим имбирем', f: 'mussels', a: 'coconut_milk', b: 'ginger', c: 'th', v: 'тушите в сковороде' },
  { id: 'seafood_paella_saffron', title: 'Испанская паэлья с морепродуктами, перцем и куркумой', f: 'seafood', a: 'round_rice', b: 'turmeric', c: 'es', v: 'тушите в широкой сковороде' },
  { id: 'seafood_risotto_cream', title: 'Сливочное ризотто с морским коктейлем и пармезаном', f: 'seafood', a: 'parmesan', b: 'cream', c: 'it', v: 'тушите на тихом огне' },
  { id: 'seafood_noodles_wok', title: 'Азиатская лапша с морепродуктами, брокколи и соевым соусом', f: 'seafood', a: 'noodles', b: 'broccoli', c: 'cn', v: 'обжаривайте в воке' },
  { id: 'seafood_julienne_cheese', title: 'Нежный жульен с морепродуктами в сливочной заливке', f: 'seafood', a: 'sour_cream', b: 'cheese', c: 'home', v: 'запекайте в духовке' },
  { id: 'seafood_couscous_lemon', title: 'Морской коктейль с кускусом, лимоном и мятой', f: 'seafood', a: 'couscous', b: 'lemon', c: 'home', v: 'обжаривайте на сковороде' },
  { id: 'seafood_potato_gratin', title: 'Картофельный гратен с морепродуктами и сливками', f: 'seafood', a: 'potato', b: 'cream', c: 'fr', v: 'запекайте в духовке' },
  { id: 'crab_sticks_cheese_rolls', title: 'Горячие рулетики из крабовых палочек в кляре с сыром', f: 'crab_sticks', a: 'cheese', b: 'egg', c: 'home', v: 'обжаривайте на сковороде' },
  { id: 'crab_sticks_rice_casserole', title: 'Быстрая запеканка с крабовыми палочками и рисом', f: 'crab_sticks', a: 'round_rice', b: 'sour_cream', c: 'home', v: 'запекайте в духовке' },
  { id: 'shrimp_cauliflower_garlic', title: 'Жареные креветки с рисом из цветной капусты и чесноком', f: 'shrimp', a: 'cauliflower', b: 'garlic', c: 'home', v: 'обжаривайте на сковороде' },
  { id: 'squid_green_peas_cream', title: 'Тушеные кальмары с зеленым горошком в нежных сливках', f: 'squid', a: 'green_peas', b: 'cream', c: 'home', v: 'тушите в сковороде' },
  { id: 'seafood_shiitake_teriyaki', title: 'Морепродукты с грибами шиитаке в соусе терияки', f: 'seafood', a: 'shiitake', b: 'soy_sauce', c: 'jp', v: 'обжаривайте в воке' },

  // Canned Fish Hot Dishes & Cakes (Тунец, Сайра, Сардины) - 15
  { id: 'tuna_pasta_tomato_olives', title: 'Итальянская паста с консервированным тунцом и оливками', f: 'tuna_canned', a: 'pasta', b: 'olives', c: 'it', v: 'тушите в соусе' },
  { id: 'tuna_corn_quesadilla', title: 'Горячая лепешка тортилья с тунцом, кукурузой и сыром', f: 'tuna_canned', a: 'tortilla', b: 'corn_canned', c: 'mx', v: 'обжаривайте на сухой сковороде' },
  { id: 'tuna_potato_patty_fried', title: 'Золотистые котлеты из картофеля с тунцом и зеленью', f: 'tuna_canned', a: 'potato', b: 'egg', c: 'home', v: 'обжаривайте на сковороде' },
  { id: 'tuna_spinach_cream_mac', title: 'Макароны с консервированным тунцом в сливочном соусе', f: 'tuna_canned', a: 'spinach', b: 'cream', c: 'home', v: 'тушите на среднем огне' },
  { id: 'tuna_rice_baked_cheese', title: 'Быстрая запеканка с тунцом, рисом и тертым сыром', f: 'tuna_canned', a: 'round_rice', b: 'hard_cheese', c: 'home', v: 'запекайте в духовке' },
  { id: 'saury_potato_pie_baked', title: 'Быстрый картофельный пирог с консервированной сайрой', f: 'saury_canned', a: 'potato', b: 'flour', c: 'ru', v: 'запекайте в духовке' },
  { id: 'saury_rice_meatballs', title: 'Домашние рыбные тефтели из сайры в сметанном соусе', f: 'saury_canned', a: 'round_rice', b: 'sour_cream', c: 'ru', v: 'тушите в сотейнике' },
  { id: 'saury_buckwheat_onion', title: 'Сытная гречневая каша с консервированной сайрой и луком', f: 'saury_canned', a: 'buckwheat', b: 'carrot', c: 'ru', v: 'тушите на тихом огне' },
  { id: 'saury_noodle_casserole', title: 'Вермишелевая запеканка с рыбными консервами и яйцом', f: 'saury_canned', a: 'vermicelli', b: 'egg', c: 'ru', v: 'запекайте в духовке' },
  { id: 'saury_green_pea_cutlets', title: 'Котлеты из сайры с зеленым горошком и сухарями', f: 'saury_canned', a: 'green_peas', b: 'breadcrumbs', c: 'home', v: 'обжаривайте на сковороде' },
  { id: 'sardines_spaghetti_garlic', title: 'Спагетти с сардинами, лимонной цедрой и петрушкой', f: 'sardines_canned', a: 'spaghetti', b: 'lemon', c: 'it', v: 'тушите в сковороде' },
  { id: 'sardines_tomato_toast_hot', title: 'Горячие гренки из белого хлеба с сардинами и томатом', f: 'sardines_canned', a: 'white_bread', b: 'tomato', c: 'home', v: 'запекайте в духовке' },
  { id: 'sardines_oatmeal_cakes', title: 'Быстрые рыбные биточки из сардин с овсянкой', f: 'sardines_canned', a: 'oatmeal', b: 'egg', c: 'home', v: 'обжаривайте на сковороде' },
  { id: 'sardines_mashed_potato_bake', title: 'Сытная запеканка с пюре и консервированными сардинами', f: 'sardines_canned', a: 'potato', b: 'cheese', c: 'uk', v: 'запекайте в духовке' },
  { id: 'sardines_beans_canned_stew', title: 'Рагу из белой фасоли с сардинами и чесноком', f: 'sardines_canned', a: 'beans_canned', b: 'garlic', c: 'es', v: 'тушите в сотейнике' }
];

for (const it of fishDefs) {
  addFish({
    id: it.id,
    title: it.title,
    cuisine: it.c,
    time: 40,
    active: 20,
    verb: it.v,
    heatSec: it.heatSec,
    desc: it.desc || `Аппетитное блюдо из рыбы и морепродуктов «${it.title}» к семейному столу.`,
    ings: [
      { ingredient_id: it.f, amount: 450, unit: 'g' },
      it.a,
      it.b,
      'onion',
      'sunflower_oil',
      'salt'
    ]
  });
}

console.log(`Total generated fish & seafood dishes: ${allFish.length}`);
saveAndValidateGroup('fish.json', allFish);
