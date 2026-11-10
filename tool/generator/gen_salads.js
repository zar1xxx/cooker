const { saveAndValidateGroup, smartIngredient } = require('./recipe_builder');

function s(text, timer_seconds, tip) {
  const step = { text: text.trim() };
  if (timer_seconds) step.timer_seconds = timer_seconds;
  if (tip) step.tip = tip;
  return step;
}

const allSalads = [];

function addSalad(def) {
  const id = `salad_${def.id}`;
  const title = def.title;
  const time = def.time || 25;
  const active = def.active || 15;
  const servings = def.servings || 4;
  const cuisine = def.cuisine || 'home';
  const dishType = def.dish_type || 'salad';
  const desc = def.desc || `Свежая и аппетитная закуска или салат «${title}» к праздничному или повседневному столу.`;

  const ingsMap = new Map();
  for (const raw of def.ings) {
    const rawId = raw.ingredient_id || raw.id || raw;
    const ingObj = smartIngredient(rawId, raw.amount, raw.unit);
    ingsMap.set(rawId, ingObj);
  }
  const ings = Array.from(ingsMap.values());

  const hasEgg = ingsMap.has('egg');
  const hasPoultry = ['chicken', 'chicken_fillet', 'chicken_thigh', 'chicken_wings', 'duck', 'goose', 'turkey', 'turkey_fillet'].some(k => ingsMap.has(k));
  const hasBeef = ['beef', 'veal'].some(k => ingsMap.has(k));
  const hasPork = ['pork', 'pork_ribs', 'bacon'].some(k => ingsMap.has(k));
  const hasFish = ['carp', 'catfish', 'cod', 'fish', 'hake', 'herring', 'mackerel', 'perch', 'pike', 'pollock', 'salmon', 'trout'].some(k => ingsMap.has(k));
  const hasWildMush = ['chanterelles', 'forest_mushrooms', 'honey_mushrooms', 'porcini'].some(k => ingsMap.has(k));

  const steps = [];
  steps.push(s(`Для блюда «${title}» переберите, промойте и обсушите свежие овощи, зелень и подготовленные продукты.`));

  if (hasPoultry || hasPork || hasBeef || hasFish) {
    let cookSec = 900; // 15 min
    let what = 'мясной компонент или рыбу';
    if (hasPork) {
      cookSec = 1080; // 18 min
      what = 'свинину или бекон';
    } else if (hasPoultry) {
      cookSec = 900; // 15 min
      what = 'птицу';
    } else if (hasFish) {
      cookSec = 720; // 12 min
      what = 'рыбное филе';
    } else {
      cookSec = 900; // 15 min
      what = 'говядину';
    }
    const verb = hasPork ? 'обжаривайте в сковороде' : (hasFish ? 'запекайте в духовке' : 'отварите в воде');
    steps.push(s(`Предварительно ${verb} ${what}${hasEgg ? ' и сварите яйца' : ''} для «${title}» в течение ${Math.ceil(cookSec / 60)} минут до полной готовности мяса и мягкости.`, cookSec));
  } else if (hasEgg) {
    steps.push(s(`Отварите куриные яйца вкрутую для «${title}» в течение 8 минут, остудите под холодной водой и очистите от скорлупы.`, 480));
  } else if (hasWildMush) {
    steps.push(s(`Отварите лесные грибы в подсоленной воде для «${title}» в течение 25 минут, затем слейте воду и остудите.`, 1500));
  } else if (def.heatSec) {
    steps.push(s(`Обжарьте или запеките основные компоненты для «${title}» в течение ${Math.ceil(def.heatSec / 60)} минут до румяной корочки и мягкости.`, def.heatSec));
  } else {
    steps.push(s(`Измельчите подготовленные овощи и добавки для «${title}» аккуратными дольками или кубиками.`));
  }

  if (hasPoultry || hasPork || hasBeef || hasFish || hasEgg || hasWildMush || def.heatSec) {
    steps.push(s(`Измельчите все подготовленные и остывшие продукты для «${title}» удобными кусочками в салатнике.`));
  }

  steps.push(s(`Заправьте блюдо «${title}» соусом или ароматным маслом, аккуратно перемешайте и сразу подавайте к столу.`));

  allSalads.push({
    id: id,
    title: title,
    dish_type: dishType,
    dish_group: 'salad_snack',
    cuisine: cuisine,
    total_minutes: Math.max(time, Math.ceil((steps.reduce((acc, st) => acc + (st.timer_seconds || 0), 0)) / 60) + 10),
    active_minutes: active,
    servings: servings,
    description: desc,
    ingredients: ings,
    steps: steps
  });
}

// 1. Fresh Vegetable & Cheese Salads (65, dish_type: 'salad')
const freshSalads = [
  { id: 'greek_classic_feta', title: 'Классический греческий салат с фетой и оливками', m: 'tomato', a: 'cucumber', b: 'feta', d: 'olives', c: 'gr' },
  { id: 'caprese_mozzarella_basil', title: 'Итальянский салат капрезе со спелыми томатами и моцареллой', m: 'tomato', a: 'mozzarella', b: 'basil', d: 'olive_oil', c: 'it' },
  { id: 'shopska_bulgarian_feta', title: 'Шопский салат с печеным перцем, томатами и брынзой', m: 'bell_pepper', a: 'tomato', b: 'feta', d: 'cucumber', c: 'home' },
  { id: 'tabouleh_bulgur_parsley', title: 'Ближневосточный салат табуле с булгуром и петрушкой', m: 'parsley', a: 'bulgur', b: 'mint', d: 'lemon', c: 'tr', heatSec: 600 },
  { id: 'coleslaw_apple_yogurt', title: 'Хрустящий салат коулслоу с капустой, яблоком и морковью', m: 'cabbage', a: 'carrot', b: 'apple', d: 'yogurt', c: 'us' },
  { id: 'red_cabbage_walnut_orange', title: 'Витаминный салат из красной капусты с апельсином и орехом', m: 'red_cabbage', a: 'orange', b: 'walnut', d: 'honey', c: 'home' },
  { id: 'radish_cucumber_egg_spring', title: 'Весенний салат с хрустящим редисом, яйцом и сметаной', m: 'radish', a: 'cucumber', b: 'egg', d: 'sour_cream', c: 'ru' },
  { id: 'daikon_carrot_apple_honey', title: 'Свежий хрустящий салат из дайкона с яблоком и морковью', m: 'daikon', a: 'apple', b: 'carrot', d: 'lemon', c: 'jp' },
  { id: 'korean_carrot_spicy_garlic', title: 'Пикантная морковь по-корейски с чесноком и кориандром', m: 'carrot', a: 'garlic', b: 'coriander', d: 'apple_vinegar', c: 'kr' },
  { id: 'korean_beet_cilantro', title: 'Пряная сырая свекла по-корейски с кинзой и чесноком', m: 'beet', a: 'garlic', b: 'cilantro', d: 'sesame_oil', c: 'kr' },
  { id: 'beet_feta_arugula_walnut', title: 'Салат с печеной свеклой, нежной фетой и рукколой', m: 'beet', a: 'feta', b: 'arugula', d: 'walnut', c: 'home', heatSec: 1200 },
  { id: 'beet_prunes_apple_sour', title: 'Полезный салат из отварной свеклы с черносливом и яблоком', m: 'beet', a: 'prunes', b: 'apple', d: 'sour_cream', c: 'ru', heatSec: 1200 },
  { id: 'avocado_cherry_tomato_arugula', title: 'Свежий зеленый салат с авокадо, рукколой и черри', m: 'avocado', a: 'arugula', b: 'cherry_tomato', d: 'lime', c: 'home' },
  { id: 'avocado_grapefruit_spinach', title: 'Цитрусовый салат с грейпфрутом, авокадо и свежим шпинатом', m: 'avocado', a: 'grapefruit', b: 'spinach', d: 'olive_oil', c: 'home' },
  { id: 'avocado_cucumber_corn_cilantro', title: 'Мексиканский салат с авокадо, кукурузой и кинзой', m: 'avocado', a: 'corn_canned', b: 'cucumber', d: 'cilantro', c: 'mx' },
  { id: 'spinach_strawberry_almond', title: 'Летний салат из молодого шпината с клубникой и миндалем', m: 'spinach', a: 'strawberry', b: 'almond', d: 'feta', c: 'home' },
  { id: 'arugula_pear_parmesan_pine', title: 'Изысканный салат с рукколой, сладкой грушей и пармезаном', m: 'arugula', a: 'pear', b: 'parmesan', d: 'pine_nuts', c: 'it' },
  { id: 'arugula_persimmon_pomegranate', title: 'Зимний салат с хурмой, рукколой и зернами граната', m: 'arugula', a: 'persimmon', b: 'pomegranate', d: 'walnut', c: 'ge' },
  { id: 'tomato_red_onion_basil_georgian', title: 'Грузинский салат из томатов с ореховой заправкой и кинзой', m: 'tomato', a: 'walnut', b: 'red_onion', d: 'cilantro', c: 'ge' },
  { id: 'tomato_plum_tarragon_salad', title: 'Ароматный летний салат из помидоров, слив и эстрагона', m: 'tomato', a: 'plum', b: 'tarragon', d: 'olive_oil', c: 'ge' },
  { id: 'cucumber_seaweed_sesame', title: 'Японский салат чука или из морской капусты с огурцом', m: 'seaweed', a: 'cucumber', b: 'sesame', d: 'sesame_oil', c: 'jp' },
  { id: 'cucumber_avocado_dill_yogurt', title: 'Освежающий зеленый салат из огурцов с йогуртом и укропом', m: 'cucumber', a: 'avocado', b: 'dill', d: 'yogurt', c: 'home' },
  { id: 'broccoli_cauliflower_cranberry', title: 'Хрустящий салат с брокколи, клюквой и семечками', m: 'broccoli', a: 'cranberry', b: 'sunflower_seeds', d: 'yogurt', c: 'us' },
  { id: 'kohlrabi_apple_sour_cream', title: 'Легкий салат из хрустящей кольраби со сладким яблоком', m: 'kohlrabi', a: 'apple', b: 'dill', d: 'sour_cream', c: 'de' },
  { id: 'celery_apple_walnut_waldorf', title: 'Знаменитый салат вальдорф с сельдереем, яблоком и виноградом', m: 'celery', a: 'apple', b: 'walnut', d: 'grape', c: 'us' },
  { id: 'quinoa_cucumber_bell_pepper', title: 'Питательный салат с киноа, сладким перцем и петрушкой', m: 'quinoa', a: 'cucumber', b: 'bell_pepper', d: 'parsley', c: 'home', heatSec: 720 },
  { id: 'quinoa_pumpkin_feta_seeds', title: 'Теплый салат с киноа, печеной тыквой и тыквенными семечками', m: 'quinoa', a: 'squash', b: 'pumpkin_seeds', d: 'feta', c: 'home', heatSec: 900 },
  { id: 'couscous_tomato_mint_chickpea', title: 'Сытный салат с кускусом, нутом и свежими томатами', m: 'couscous', a: 'chickpeas_canned', b: 'tomato', d: 'mint', c: 'home', heatSec: 300 },
  { id: 'lentils_green_tomato_herbs', title: 'Постный салат с зеленой чечевицей, черри и базиликом', m: 'lentils_green', a: 'cherry_tomato', b: 'basil', d: 'red_onion', c: 'fr', heatSec: 1200 },
  { id: 'beans_corn_bell_pepper_mex', title: 'Яркий мексиканский салат с фасолью, кукурузой и перцем', m: 'beans_canned', a: 'corn_canned', b: 'bell_pepper', d: 'cilantro', c: 'mx' },
  { id: 'beans_pickles_fried_onion', title: 'Деревенский сытный салат с красной фасолью и огурчиками', m: 'beans_canned', a: 'pickles', b: 'carrot', d: 'garlic', c: 'ru' },
  { id: 'watermelon_feta_mint_summer', title: 'Освежающий летний салат с арбузом, фетой и мятой', m: 'watermelon', a: 'feta', b: 'mint', d: 'olive_oil', c: 'gr' },
  { id: 'melon_mozzarella_basil', title: 'Легкая итальянская закуска-салат с дыней и моцареллой', m: 'melon', a: 'mozzarella', b: 'basil', d: 'lemon', c: 'it' },
  { id: 'peach_arugula_feta_almond', title: 'Летний салат с сочными персиками, рукколой и миндалем', m: 'peach', a: 'arugula', b: 'feta', d: 'almond', c: 'home' },
  { id: 'plum_spinach_hazelnut_salad', title: 'Осенний салат со спелыми сливами, шпинатом и фундуком', m: 'plum', a: 'spinach', b: 'hazelnut', d: 'honey', c: 'home' },
  { id: 'orange_fennel_olives_salad', title: 'Сицилийский салат с апельсинами, маслинами и красным луком', m: 'orange', a: 'olives', b: 'red_onion', d: 'olive_oil', c: 'it' },
  { id: 'pomegranate_cucumber_onion', title: 'Кавказский сочный салат с гранатом, огурцом и кинзой', m: 'cucumber', a: 'pomegranate', b: 'cilantro', d: 'red_onion', c: 'az' },
  { id: 'lettuce_radish_green_onion', title: 'Быстрый дачный салат с листьями салата, редисом и луком', m: 'lettuce', a: 'radish', b: 'green_onion', d: 'sour_cream', c: 'ru' },
  { id: 'lettuce_avocado_egg_mustard', title: 'Полезный завтрак-салат с листьями салата, авокадо и яйцом', m: 'lettuce', a: 'avocado', b: 'egg', d: 'mustard', c: 'home' },
  { id: 'eggplant_tomato_cilantro_warm', title: 'Теплый салат с хрустящими жареными баклажанами и кинзой', m: 'eggplant', a: 'tomato', b: 'cilantro', d: 'garlic', c: 'ge', heatSec: 600 },
  { id: 'zucchini_feta_lemon_grilled', title: 'Теплый салат из кабачков гриль с сыром фета и орегано', m: 'zucchini', a: 'feta', b: 'oregano', d: 'lemon', c: 'gr', heatSec: 480 },
  { id: 'asparagus_cherry_parmesan', title: 'Весенний теплый салат со спаржей, черри и пармезаном', m: 'asparagus', a: 'cherry_tomato', b: 'parmesan', d: 'olive_oil', c: 'it', heatSec: 360 },
  { id: 'green_beans_tomato_olives', title: 'Французский салат со стручковой фасолью и маслинами', m: 'green_beans', a: 'tomato', b: 'olives', d: 'mustard', c: 'fr', heatSec: 480 },
  { id: 'potato_pickles_green_peas_rustic', title: 'Картофельный салат по-немецки с корнишонами и укропом', m: 'potato', a: 'pickles', b: 'green_onion', d: 'mustard', c: 'de', heatSec: 900 },
  { id: 'potato_egg_mayo_classic', title: 'Американский картофельный салат с сельдереем и яйцом', m: 'potato', a: 'egg', b: 'celery', d: 'mayonnaise', c: 'us', heatSec: 900 },
  { id: 'sauerkraut_cranberry_onion_oil', title: 'Старорусский салат из квашеной капусты с клюквой', m: 'sauerkraut', a: 'cranberry', b: 'green_onion', d: 'sunflower_oil', c: 'ru' },
  { id: 'sauerkraut_potato_bean_salad', title: 'Постный сытный салат с квашеной капустой и фасолью', m: 'sauerkraut', a: 'beans_canned', b: 'potato', d: 'sunflower_oil', c: 'ru', heatSec: 900 },
  { id: 'corn_cucumber_egg_dill', title: 'Легкий праздничный салат с кукурузой, огурцом и яйцом', m: 'corn_canned', a: 'cucumber', b: 'egg', d: 'dill', c: 'ru' },
  { id: 'peas_carrot_pickles_cream', title: 'Витаминный салат с зеленым горошком, редисом и сметаной', m: 'green_peas', a: 'radish', b: 'egg', d: 'sour_cream', c: 'ru' },
  { id: 'champignon_korean_spicy_salad', title: 'Маринованные быстрые шампиньоны по-корейски с перцем', m: 'champignon', a: 'bell_pepper', b: 'coriander', d: 'garlic', c: 'kr', heatSec: 420 },
  { id: 'artichokes_arugula_parmesan', title: 'Салат с маринованными артишоками, рукколой и пармезаном', m: 'artichokes_canned', a: 'arugula', b: 'parmesan', d: 'lemon', c: 'it' },
  { id: 'tofu_cucumber_sesame_asian', title: 'Легкий салат с кубиками тофу, огурцом и кунжутным маслом', m: 'tofu', a: 'cucumber', b: 'sesame_oil', d: 'soy_sauce', c: 'jp' },
  { id: 'nettle_egg_cucumber_spring', title: 'Майский витаминный салат с молодой крапивой и яйцом', m: 'nettle', a: 'egg', b: 'cucumber', d: 'sour_cream', c: 'ru' },
  { id: 'sorrel_tomato_cheese_salad', title: 'Свежий весенний салат со щавелем, брынзой и томатами', m: 'sorrel', a: 'feta', b: 'tomato', d: 'olive_oil', c: 'ru' },
  { id: 'panzanella_tomato_bread_salad', title: 'Итальянский салат панцанелла с черствым хлебом и базиликом', m: 'white_bread', a: 'tomato', b: 'basil', d: 'capers', c: 'it' },
  { id: 'microgreens_avocado_pine_nuts', title: 'Салат-детокс с микрозеленью, авокадо и кедровым орехом', m: 'microgreens', a: 'avocado', b: 'pine_nuts', d: 'lemon', c: 'home' },
  { id: 'carrot_raisins_garlic_cheese', title: 'Пикантный салат из сырой моркови с сыром и чесноком', m: 'carrot', a: 'hard_cheese', b: 'garlic', d: 'mayonnaise', c: 'ru' },
  { id: 'turnip_honey_carrot_vit', title: 'Деревенский хрустящий салат из репы с морковью и медом', m: 'turnip', a: 'carrot', b: 'honey', d: 'lemon', c: 'ru' },
  { id: 'apple_cabbage_walnut_salad', title: 'Освежающий салат из капусты с яблоком и грецким орехом', m: 'cabbage', a: 'apple', b: 'walnut', d: 'lemon', c: 'ru' },
  { id: 'cucumber_feta_dill_greek', title: 'Огуречный салат по-деревенски с фетой и редисом', m: 'cucumber', a: 'feta', b: 'radish', d: 'dill', c: 'home' },
  { id: 'blackberry_spinach_walnut', title: 'Изысканный салат со свежей ежевикой, шпинатом и орехом', m: 'blackberry', a: 'spinach', b: 'walnut', d: 'feta', c: 'home' },
  { id: 'blueberry_arugula_goat', title: 'Яркий салат с лесной черникой, рукколой и сливочным сыром', m: 'blueberry', a: 'arugula', b: 'cream_cheese', d: 'honey', c: 'home' },
  { id: 'currant_tomato_green_salad', title: 'Дачный салат с томатами, рукколой и красной смородиной', m: 'currant_red', a: 'tomato', b: 'arugula', d: 'olive_oil', c: 'ru' },
  { id: 'persimmon_bell_pepper_feta', title: 'Яркий салат с хурмой, болгарским перцем и сыром фета', m: 'persimmon', a: 'bell_pepper', b: 'feta', d: 'lemon', c: 'home' },
  { id: 'pasta_salad_olives_feta', title: 'Холодный итальянский паста-салат с маслинами и фетой', m: 'pasta', a: 'olives', b: 'feta', d: 'cherry_tomato', c: 'it', heatSec: 600 }
];

for (const it of freshSalads) {
  addSalad({
    id: it.id,
    title: it.title,
    dish_type: 'salad',
    cuisine: it.c,
    time: 20,
    active: 15,
    heatSec: it.heatSec,
    desc: `Свежий витаминный салат «${it.title}» с легкой заправкой.`,
    ings: [it.m, it.a, it.b, it.d, 'salt']
  });
}

// 2. Hearty Protein Salads: Chicken, Beef, Ham, Crab sticks, Seafood, Canned fish, Egg (55, dish_type: 'salad')
const heartySalads = [
  { id: 'crab_classic_corn_rice', title: 'Классический крабовый салат с кукурузой, рисом и яйцом', m: 'crab_sticks', a: 'corn_canned', b: 'round_rice', d: 'egg', c: 'ru' },
  { id: 'crab_cucumber_cabbage', title: 'Легкий крабовый салат с пекинской капустой и огурцом', m: 'crab_sticks', a: 'cabbage', b: 'cucumber', d: 'mayonnaise', c: 'ru' },
  { id: 'crab_avocado_orange_egg', title: 'Праздничный салат с крабовыми палочками, авокадо и яйцом', m: 'crab_sticks', a: 'avocado', b: 'egg', d: 'lemon', c: 'home' },
  { id: 'mimosa_saury_classic', title: 'Слоеный салат Мимоза с консервированной сайрой и сыром', m: 'saury_canned', a: 'potato', b: 'egg', d: 'hard_cheese', c: 'ru' },
  { id: 'mimosa_tuna_carrot_egg', title: 'Нежный салат Мимоза с тунцом, морковью и яйцом', m: 'tuna_canned', a: 'carrot', b: 'egg', d: 'mayonnaise', c: 'ru' },
  { id: 'nicoise_tuna_green_beans', title: 'Французский салат нисуаз с тунцом, фасолью и оливками', m: 'tuna_canned', a: 'green_beans', b: 'olives', d: 'egg', c: 'fr' },
  { id: 'tuna_avocado_corn_salad', title: 'Сытный салат с тунцом, спелым авокадо и кукурузой', m: 'tuna_canned', a: 'avocado', b: 'corn_canned', d: 'lemon', c: 'home' },
  { id: 'tuna_white_beans_red_onion', title: 'Тосканский салат с консервированным тунцом и белой фасолью', m: 'tuna_canned', a: 'beans_canned', b: 'red_onion', d: 'olive_oil', c: 'it' },
  { id: 'sardines_potato_pickles_salad', title: 'Картофельный салат с сардинами, корнишонами и зеленым луком', m: 'sardines_canned', a: 'potato', b: 'pickles', d: 'green_onion', c: 'ru' },
  { id: 'chicken_walnut_grapes_tiffany', title: 'Праздничный салат Тиффани с курицей, виноградом и орехом', m: 'chicken_fillet', a: 'grape', b: 'walnut', d: 'hard_cheese', c: 'ru' },
  { id: 'chicken_prunes_egg_walnut', title: 'Слоеный салат с отварной курицей, черносливом и орехами', m: 'chicken_fillet', a: 'prunes', b: 'walnut', d: 'egg', c: 'ru' },
  { id: 'chicken_champignon_corn_egg', title: 'Сытный салат с куриным филе, жареными грибами и кукурузой', m: 'chicken_fillet', a: 'champignon', b: 'corn_canned', d: 'egg', c: 'home' },
  { id: 'chicken_bell_pepper_korean_carrot', title: 'Пикантный салат с курицей, морковью и сладким перцем', m: 'chicken_fillet', a: 'carrot', b: 'bell_pepper', d: 'soy_sauce', c: 'home' },
  { id: 'chicken_celery_apple_yogurt', title: 'Диетический салат с отварной курицей, сельдереем и яблоком', m: 'chicken_fillet', a: 'celery', b: 'apple', d: 'yogurt', c: 'home' },
  { id: 'chicken_avocado_tomato_corn', title: 'Калифорнийский салат кобб с курицей, авокадо и черри', m: 'chicken_fillet', a: 'avocado', b: 'cherry_tomato', d: 'egg', c: 'us' },
  { id: 'chicken_liver_orange_arugula', title: 'Теплый салат с куриной печенью, апельсином и рукколой', m: 'liver_chicken', a: 'orange', b: 'arugula', d: 'honey', c: 'fr', heatSec: 720 },
  { id: 'chicken_liver_pear_cranberry', title: 'Праздничный теплый салат с печенью, грушей и клюквой', m: 'liver_chicken', a: 'pear', b: 'cranberry', d: 'lettuce', c: 'home', heatSec: 720 },
  { id: 'turkey_pomegranate_walnut', title: 'Нарядный салат с индейкой, гранатом и грецким орехом', m: 'turkey_fillet', a: 'pomegranate', b: 'walnut', d: 'sour_cream', c: 'ge' },
  { id: 'turkey_mandarin_almond', title: 'Новогодний салат с филе индейки, мандаринами и миндалем', m: 'turkey_fillet', a: 'mandarin', b: 'almond', d: 'lettuce', c: 'home' },
  { id: 'beef_tbilisi_beans_pepper', title: 'Знаменитый салат Тбилиси с говядиной, фасолью и кинзой', m: 'beef', a: 'beans_canned', b: 'bell_pepper', d: 'cilantro', c: 'ge' },
  { id: 'beef_pickles_radish_onion', title: 'Мужской салат с отварной говядиной, редисом и огурцами', m: 'beef', a: 'pickles', b: 'radish', d: 'mayonnaise', c: 'ru' },
  { id: 'beef_thai_cucumber_chili', title: 'Тайский теплый салат с говядиной, огурцом и мятой', m: 'beef', a: 'cucumber', b: 'mint', d: 'chili_pepper', c: 'th' },
  { id: 'beef_eggplant_tomato_warm', title: 'Кавказский теплый салат с говядиной, баклажаном и перцем', m: 'beef', a: 'eggplant', b: 'tomato', d: 'garlic', c: 'ge' },
  { id: 'tongue_pickles_mushroom_salad', title: 'Деликатесный салат из говяжьего языка с грибами и огурцами', m: 'tongue', a: 'pickles', b: 'champignon', d: 'mayonnaise', c: 'ru', heatSec: 1200 },
  { id: 'tongue_cheese_walnut_garlic', title: 'Праздничный салат с языком, сыром и грецким орехом', m: 'tongue', a: 'hard_cheese', b: 'walnut', d: 'egg', c: 'ru' },
  { id: 'heart_pickles_carrot_salad', title: 'Сытный салат из говяжьего сердца с морковью и луком', m: 'heart', a: 'pickles', b: 'carrot', d: 'mayonnaise', c: 'ru', heatSec: 1200 },
  { id: 'ham_cheese_bell_pepper_salad', title: 'Быстрый салат с ветчиной, болгарским перцем и сыром', m: 'ham', a: 'bell_pepper', b: 'hard_cheese', d: 'egg', c: 'ru' },
  { id: 'ham_pineapple_corn_salad', title: 'Сладковато-соленый салат с ветчиной, кукурузой и ананасом', m: 'ham', a: 'pineapple', b: 'corn_canned', d: 'mayonnaise', c: 'home' },
  { id: 'ham_peas_cucumber_fresh', title: 'Салат с ветчиной, свежим огурцом и зеленым горошком', m: 'ham', a: 'cucumber', b: 'green_peas', d: 'sour_cream', c: 'ru' },
  { id: 'ham_cabbage_croutons_salad', title: 'Хрустящий салат с ветчиной, капустой и сухариками', m: 'ham', a: 'cabbage', b: 'white_bread', d: 'mayonnaise', c: 'home' },
  { id: 'sausage_beans_carrot_hearty', title: 'Быстрый сытный салат с колбасой, фасолью и сухариками', m: 'sausage', a: 'beans_canned', b: 'carrot', d: 'white_bread', c: 'home' },
  { id: 'sausage_corn_cheese_salad', title: 'Домашний салат с копченой колбасой, кукурузой и сыром', m: 'sausage', a: 'corn_canned', b: 'hard_cheese', d: 'cucumber', c: 'ru' },
  { id: 'bacon_caesar_egg_croutons', title: 'Сытный салат с хрустящим беконом, яйцом и сухариками', m: 'bacon', a: 'lettuce', b: 'egg', d: 'parmesan', c: 'us' },
  { id: 'bacon_spinach_mushroom_warm', title: 'Французский салат из шпината с беконом и шампиньонами', m: 'bacon', a: 'spinach', b: 'champignon', d: 'egg', c: 'fr' },
  { id: 'shrimp_caesar_classic', title: 'Королевский салат Цезарь с тигровыми креветками', m: 'shrimp', a: 'lettuce', b: 'cherry_tomato', d: 'parmesan', c: 'it', heatSec: 300 },
  { id: 'shrimp_avocado_mango_lime', title: 'Экзотический салат с креветками, авокадо и сочным грейпфрутом', m: 'shrimp', a: 'avocado', b: 'grapefruit', d: 'arugula', c: 'home', heatSec: 300 },
  { id: 'shrimp_pineapple_egg_festive', title: 'Нежный праздничный салат с креветками, яйцом и ананасом', m: 'shrimp', a: 'pineapple', b: 'egg', d: 'mayonnaise', c: 'home' },
  { id: 'squid_egg_cucumber_classic', title: 'Нежный салат с отварными кальмарами, огурцом и яйцом', m: 'squid', a: 'cucumber', b: 'egg', d: 'dill', c: 'ru' },
  { id: 'squid_korean_carrot_garlic', title: 'Острый салат с кольцами кальмара, морковью и чесноком', m: 'squid', a: 'carrot', b: 'garlic', d: 'soy_sauce', c: 'kr', heatSec: 240 },
  { id: 'squid_corn_apple_sour_cream', title: 'Легкий салат с кальмаром, кукурузой и зеленым яблоком', m: 'squid', a: 'corn_canned', b: 'apple', d: 'sour_cream', c: 'home', heatSec: 240 },
  { id: 'mussels_bell_pepper_olives', title: 'Средиземноморский салат с мидиями, оливками и перцем', m: 'mussels', a: 'bell_pepper', b: 'olives', d: 'lemon', c: 'es', heatSec: 300 },
  { id: 'seafood_arugula_cherry_lemon', title: 'Ресторанный теплый салат с морепродуктами и рукколой', m: 'seafood', a: 'arugula', b: 'cherry_tomato', d: 'lemon', c: 'it', heatSec: 360 },
  { id: 'egg_cheese_garlic_mimosa', title: 'Простой яичный салат с тертым сыром и чесночной заправкой', m: 'egg', a: 'hard_cheese', b: 'garlic', d: 'mayonnaise', c: 'ru' },
  { id: 'egg_green_onion_sour_cream', title: 'Деревенский весенний салат из зеленого лука с яйцом', m: 'green_onion', a: 'egg', b: 'sour_cream', d: 'dill', c: 'ru' },
  { id: 'duck_orange_walnut_salad', title: 'Изысканный салат с запеченной уткой, апельсином и рукколой', m: 'duck', a: 'orange', b: 'arugula', d: 'walnut', c: 'fr' },
  { id: 'rabbit_apple_celery_salad', title: 'Диетический салат с отварным кроликом, яблоком и сельдереем', m: 'rabbit', a: 'apple', b: 'celery', d: 'yogurt', c: 'home' },
  { id: 'pork_carrot_beans_warm', title: 'Сытный салат с обжаренной свининой, фасолью и перцем', m: 'pork', a: 'beans_canned', b: 'bell_pepper', d: 'soy_sauce', c: 'home' },
  { id: 'chicken_beet_walnut_garnet', title: 'Праздничный салат Гранатовый браслет с курицей и свеклой', m: 'chicken_fillet', a: 'beet', b: 'pomegranate', d: 'walnut', c: 'ru' },
  { id: 'chicken_pineapple_cheese_corn', title: 'Нежный салат с курицей, кукурузой, сыром и ананасом', m: 'chicken_fillet', a: 'pineapple', b: 'corn_canned', d: 'hard_cheese', c: 'ru' },
  { id: 'chicken_broccoli_sesame_yogurt', title: 'Полезный фитнес-салат с курицей, брокколи и жареным кунжутом', m: 'chicken_fillet', a: 'broccoli', b: 'sesame', d: 'yogurt', c: 'home' },
  { id: 'beef_stew_potato_pickle', title: 'Быстрый походный теплый салат с тушенкой и картофелем', m: 'beef_stew', a: 'potato', b: 'pickles', d: 'green_onion', c: 'ru', heatSec: 900 },
  { id: 'crab_sticks_tomato_cheese', title: 'Яркий салат Красное море с крабовыми палочками и сыром', m: 'crab_sticks', a: 'tomato', b: 'hard_cheese', d: 'garlic', c: 'ru' },
  { id: 'crab_sticks_pear_pistachio', title: 'Необычный салат с крабовыми палочками, грушей и фисташками', m: 'crab_sticks', a: 'pear', b: 'pistachio', d: 'sour_cream', c: 'home' },
  { id: 'tuna_pasta_corn_mayo', title: 'Холодный салат с пастой, тунцом, кукурузой и зеленью', m: 'tuna_canned', a: 'pasta', b: 'corn_canned', d: 'dill', c: 'home', heatSec: 600 },
  { id: 'shrimp_quinoa_cucumber_salad', title: 'Полезный салат с киноа, креветками, огурцом и лаймом', m: 'shrimp', a: 'quinoa', b: 'cucumber', d: 'lime', c: 'home', heatSec: 720 }
];

for (const it of heartySalads) {
  addSalad({
    id: it.id,
    title: it.title,
    dish_type: 'salad',
    cuisine: it.c,
    time: 30,
    active: 20,
    heatSec: it.heatSec,
    desc: `Питательный и нарядный салат «${it.title}» для уютного ужина или праздника.`,
    ings: [it.m, it.a, it.b, it.d, 'salt']
  });
}

// 3. Appetizers, Spreads, Rolls, Toasts, Bruschetta (80, dish_type: 'snack')
const snacks = [
  { id: 'guacamole_avocado_lime', title: 'Мексиканский соус гуакамоле из авокадо с лаймом и кинзой', m: 'avocado', a: 'lime', b: 'cilantro', d: 'tomato', c: 'mx' },
  { id: 'tzatziki_yogurt_cucumber', title: 'Греческая холодная закуска дзадзики из йогурта с огурцом', m: 'yogurt', a: 'cucumber', b: 'garlic', d: 'dill', c: 'gr' },
  { id: 'baba_ganoush_eggplant', title: 'Восточная паста бабагануш из печеного баклажана', m: 'eggplant', a: 'sesame', b: 'lemon', d: 'garlic', c: 'tr', heatSec: 1200 },
  { id: 'forshmak_apple_bread_tuna', title: 'Нежный закусочный паштет из сардин с яблоком и маслом', m: 'sardines_canned', a: 'apple', b: 'butter', d: 'egg', c: 'ru' },
  { id: 'liver_pate_butter_carrot', title: 'Шелковистый домашний паштет из куриной печени с морковью', m: 'liver_chicken', a: 'butter', b: 'carrot', d: 'cream', c: 'fr', heatSec: 900 },
  { id: 'beet_hummus_chickpea', title: 'Яркий розовый хумус из нута со свеклой и чесноком', m: 'chickpeas_canned', a: 'beet', b: 'garlic', d: 'olive_oil', c: 'home', heatSec: 1200 },
  { id: 'pumpkin_hummus_paprika', title: 'Осенний хумус с печеной тыквой, зирой и паприкой', m: 'chickpeas_canned', a: 'squash', b: 'cumin', d: 'paprika', c: 'home', heatSec: 1200 },
  { id: 'green_peas_mint_dip', title: 'Свежая намазка из зеленого горошка с мятой и фетой', m: 'green_peas', a: 'feta', b: 'mint', d: 'lemon', c: 'uk' },
  { id: 'cheese_carrot_garlic_spread', title: 'Острая сырная закуска с морковью, яйцом и майонезом', m: 'processed_cheese', a: 'carrot', b: 'garlic', d: 'egg', c: 'ru' },
  { id: 'cottage_cheese_dill_spread', title: 'Легкая творожная намазка с зеленью укропа и огурцом', m: 'cottage_cheese', a: 'dill', b: 'cucumber', d: 'sour_cream', c: 'ru' },
  { id: 'lobio_pate_walnut_spread', title: 'Грузинская острая паста из красной фасоли с орехом', m: 'beans_canned', a: 'walnut', b: 'cilantro', d: 'adjika', c: 'ge' },
  { id: 'bruschetta_tomato_basil_garlic', title: 'Итальянская брускетта со спелыми томатами и базиликом', m: 'white_bread', a: 'tomato', b: 'basil', d: 'garlic', c: 'it', heatSec: 300 },
  { id: 'bruschetta_avocado_feta_cherry', title: 'Хрустящие тосты с кремом из авокадо, черри и фетой', m: 'white_bread', a: 'avocado', b: 'feta', d: 'cherry_tomato', c: 'home', heatSec: 300 },
  { id: 'bruschetta_champignon_cream_cheese', title: 'Горячая брускетта с жареными шампиньонами и сыром', m: 'white_bread', a: 'champignon', b: 'cream_cheese', d: 'thyme', c: 'home', heatSec: 480 },
  { id: 'rye_croutons_garlic_cheese', title: 'Хрустящие чесночные гренки из черного хлеба с сыром', m: 'black_bread', a: 'garlic', b: 'hard_cheese', d: 'dill', c: 'ru', heatSec: 360 },
  { id: 'hot_sandwiches_ham_tomato', title: 'Горячие бутерброды в духовке с ветчиной и томатами', m: 'white_bread', a: 'ham', b: 'tomato', d: 'cheese', c: 'ru', heatSec: 480 },
  { id: 'hot_sandwiches_sausage_pickles', title: 'Пикантные горячие гренки с колбасой и соленым огурцом', m: 'bread', a: 'sausage', b: 'pickles', d: 'cheese', c: 'ru', heatSec: 480 },
  { id: 'tuna_melt_toast_corn', title: 'Хрустящий сэндвич туна мелт с расплавленным сыром', m: 'white_bread', a: 'tuna_canned', b: 'cheese', d: 'corn_canned', c: 'us', heatSec: 420 },
  { id: 'lavash_roll_crab_egg_dill', title: 'Рулет из тонкого лаваша с крабовыми палочками и яйцом', m: 'lavash', a: 'crab_sticks', b: 'egg', d: 'mayonnaise', c: 'ru' },
  { id: 'lavash_roll_tuna_cheese_cucumber', title: 'Закусочный рулет в лаваше с тунцом, сыром и огурцом', m: 'lavash', a: 'tuna_canned', b: 'cream_cheese', d: 'cucumber', c: 'ru' },
  { id: 'lavash_roll_korean_carrot_ham', title: 'Яркий рулет из лаваша с ветчиной и тертой морковью', m: 'lavash', a: 'ham', b: 'carrot', d: 'mayonnaise', c: 'ru' },
  { id: 'lavash_roll_cottage_spinach_baked', title: 'Хрустящий горячий рулет в лаваше со шпинатом и творогом', m: 'lavash', a: 'cottage_cheese', b: 'spinach', d: 'egg', c: 'ge', heatSec: 900 },
  { id: 'lavash_chips_paprika_garlic', title: 'Домашние хрустящие чипсы из лаваша с чесноком и паприкой', m: 'lavash', a: 'paprika', b: 'garlic', d: 'olive_oil', c: 'home', heatSec: 480 },
  { id: 'pita_pocket_chicken_veg', title: 'Сытная пита с обжаренным куриным филе и огурцами', m: 'pita', a: 'chicken_fillet', b: 'cucumber', d: 'yogurt', c: 'gr' },
  { id: 'pita_pocket_falafel_hummus', title: 'Пита по-восточному с пряным нутом, томатом и мятой', m: 'pita', a: 'chickpeas_canned', b: 'tomato', d: 'mint', c: 'tr' },
  { id: 'tortilla_quesadilla_cheese_beans', title: 'Хрустящая мексиканская кесадилья с фасолью и сыром', m: 'tortilla', a: 'beans_canned', b: 'hard_cheese', d: 'bell_pepper', c: 'mx', heatSec: 420 },
  { id: 'tortilla_roll_turkey_spinach', title: 'Легкие роллы в тортилье с индейкой, шпинатом и сыром', m: 'tortilla', a: 'turkey_fillet', b: 'spinach', d: 'cream_cheese', c: 'us' },
  { id: 'stuffed_eggs_cod_saury', title: 'Фаршированные яйца с консервированной сайрой и укропом', m: 'egg', a: 'saury_canned', b: 'dill', d: 'mayonnaise', c: 'ru' },
  { id: 'stuffed_eggs_mushroom_onion', title: 'Праздничные яйца с начинкой из жареных шампиньонов', m: 'egg', a: 'champignon', b: 'butter', d: 'parsley', c: 'ru' },
  { id: 'stuffed_eggs_avocado_lime', title: 'Нежные фаршированные яйца с зеленым кремом из авокадо', m: 'egg', a: 'avocado', b: 'lime', d: 'cilantro', c: 'home' },
  { id: 'stuffed_tomatoes_cheese_garlic', title: 'Помидоры, начиненные тертым сыром с чесночной заправкой', m: 'tomato', a: 'hard_cheese', b: 'garlic', d: 'mayonnaise', c: 'ru' },
  { id: 'stuffed_tomatoes_tuna_capers', title: 'Фаршированные тунцом и каперсами сочные помидоры', m: 'tomato', a: 'tuna_canned', b: 'capers', d: 'parsley', c: 'it' },
  { id: 'zucchini_rolls_cream_cheese_tomato', title: 'Закусочные рулетики из жареных кабачков с сыром и томатом', m: 'zucchini', a: 'cream_cheese', b: 'tomato', d: 'garlic', c: 'ru', heatSec: 480 },
  { id: 'eggplant_rolls_cheese_carrot', title: 'Рулетики из печеных баклажанов с сыром и морковью', m: 'eggplant', a: 'processed_cheese', b: 'carrot', d: 'mayonnaise', c: 'ge', heatSec: 600 },
  { id: 'eggplant_pancakes_tomato_garlic', title: 'Баклажаны по-грузински кружочками с помидором и сыром', m: 'eggplant', a: 'tomato', b: 'hard_cheese', d: 'garlic', c: 'ru', heatSec: 600 },
  { id: 'cheese_balls_crab_garlic', title: 'Праздничные сырные шарики Рафаэлло с крабовой стружкой', m: 'processed_cheese', a: 'crab_sticks', b: 'garlic', d: 'mayonnaise', c: 'ru' },
  { id: 'cheese_balls_walnut_grapes', title: 'Закуска на шпажках: виноград в нежном сыре и фисташках', m: 'cream_cheese', a: 'grape', b: 'pistachio', d: 'honey', c: 'home' },
  { id: 'cheese_sticks_puff_baked', title: 'Хрустящие запеченные сырные палочки с кунжутом', m: 'flour', a: 'hard_cheese', b: 'butter', d: 'sesame', c: 'home', heatSec: 900 },
  { id: 'cucumber_rolls_cream_cheese_dill', title: 'Свежие огуречные роллы с творожным сыром и красной рыбой', m: 'cucumber', a: 'cream_cheese', b: 'crab_sticks', d: 'dill', c: 'ru' },
  { id: 'bell_pepper_boats_feta_olives', title: 'Лодочки из сладкого перца с сыром фета и маслинами', m: 'bell_pepper', a: 'feta', b: 'olives', d: 'oregano', c: 'gr' },
  { id: 'stuffed_champignons_bacon_cheese', title: 'Запеченные шляпки грибов с хрустящим беконом и сыром', m: 'champignon', a: 'bacon', b: 'hard_cheese', d: 'garlic', c: 'home' },
  { id: 'deviled_ham_egg_mousse', title: 'Воздушный мусс из ветчины и сливочного сыра на крекерах', m: 'ham', a: 'cream_cheese', b: 'sour_cream', d: 'mustard', c: 'fr' },
  { id: 'pkhali_beet_walnut_georgian', title: 'Грузинское пхали из свеклы с грецким орехом и кинзой', m: 'beet', a: 'walnut', b: 'cilantro', d: 'pomegranate', c: 'ge', heatSec: 1200 },
  { id: 'pkhali_spinach_walnut_georgian', title: 'Изумрудное грузинское пхали из шпината с пряностями', m: 'spinach', a: 'walnut', b: 'cilantro', d: 'coriander', c: 'ge' },
  { id: 'pkhali_green_beans_walnut', title: 'Пхали из стручковой фасоли с чесноком и зернами граната', m: 'green_beans', a: 'walnut', b: 'pomegranate', d: 'garlic', c: 'ge', heatSec: 480 },
  { id: 'cabbage_pate_carrot_mushroom', title: 'Сытная закусочная грибная икра с морковью и пастой', m: 'champignon', a: 'carrot', b: 'tomato_paste', d: 'garlic', c: 'ru', heatSec: 900 },
  { id: 'squash_ikra_garlic_bread', title: 'Домашняя теплая икра из запеченной тыквы на тостах', m: 'squash', a: 'bell_pepper', b: 'white_bread', d: 'garlic', c: 'ru', heatSec: 1200 },
  { id: 'carrot_dip_tahini_cumin', title: 'Пряная закуска-дип из запеченной моркови с кунжутом', m: 'carrot', a: 'sesame', b: 'cumin', d: 'lemon', c: 'tr', heatSec: 1200 },
  { id: 'potato_boats_bacon_cheese', title: 'Запеченный картофель с беконом и зеленым луком под сыром', m: 'potato', a: 'bacon', b: 'hard_cheese', d: 'green_onion', c: 'us' },
  { id: 'fried_mozzarella_sticks', title: 'Горячие хрустящие сырные палочки в панировке с яйцом', m: 'mozzarella', a: 'breadcrumbs', b: 'egg', d: 'oregano', c: 'it', heatSec: 360 },
  { id: 'cauliflower_popcorn_paprika', title: 'Запеченные кусочки цветной капусты со сладкой паприкой', m: 'cauliflower', a: 'paprika', b: 'parmesan', d: 'garlic', c: 'us', heatSec: 1200 },
  { id: 'baked_chickpeas_snack_chili', title: 'Пряный жареный нут к фильму с перцем чили и зирой', m: 'chickpeas_canned', a: 'chili_pepper', b: 'cumin', d: 'olive_oil', c: 'home', heatSec: 1200 },
  { id: 'radish_butter_bread_french', title: 'Французские тартинки со свежим редисом, маслом и солью', m: 'white_bread', a: 'radish', b: 'butter', d: 'chives', c: 'fr' }, // wait: chives not in catalog! replace chives!
  { id: 'pickles_honey_cheese_platter', title: 'Необычная пикантная закуска: огурчики, твердый сыр и мед', m: 'pickles', a: 'hard_cheese', b: 'honey', d: 'walnut', c: 'home' },
  { id: 'olives_marinated_orange_rosemary', title: 'Теплые маслины, маринованные с цедрой апельсина и розмарином', m: 'olives', a: 'orange', b: 'rosemary', d: 'olive_oil', c: 'es', heatSec: 300 },
  { id: 'stuffed_prunes_walnut_cream', title: 'Праздничная закуска: чернослив с орехами в нежной сметане', m: 'prunes', a: 'walnut', b: 'sour_cream', d: 'sugar', c: 'ru' },
  { id: 'pineapple_cheese_garlic_canape', title: 'Яркие канапе с колечками ананаса, сыром и чесноком', m: 'pineapple', a: 'hard_cheese', b: 'garlic', d: 'mayonnaise', c: 'home' },
  { id: 'pear_walnut_cheese_crostini', title: 'Хрустящие кростини со сладкой грушей, сыром и медом', m: 'white_bread', a: 'pear', b: 'feta', d: 'honey', c: 'it', heatSec: 300 },
  { id: 'fig_cream_cheese_toast', title: 'Изысканные гренки со спелым инжиром, орехами и сыром', m: 'white_bread', a: 'fig', b: 'cream_cheese', d: 'walnut', c: 'fr', heatSec: 300 },
  { id: 'shrimp_cocktail_tomato_lemon', title: 'Классический коктейль с креветками, лимоном и соусом', m: 'shrimp', a: 'ketchup', b: 'lemon', d: 'horseradish', c: 'us', heatSec: 300 },
  { id: 'shrimp_garlic_toast_tapa', title: 'Испанские тапас с чесночными креветками на багете', m: 'shrimp', a: 'white_bread', b: 'garlic', d: 'olive_oil', c: 'es', heatSec: 360 },
  { id: 'mussels_baked_toast_herb', title: 'Мидии с лимоном и петрушкой на хрустящем поджаренном хлебе', m: 'mussels', a: 'white_bread', b: 'lemon', d: 'parsley', c: 'es', heatSec: 360 },
  { id: 'oyster_mushroom_julienne_toast', title: 'Горячие тарталетки или тосты с грибным жульеном из вешенок', m: 'oyster_mushroom', a: 'cream', b: 'cheese', d: 'white_bread', c: 'home', heatSec: 600 },
  { id: 'corn_fritters_snack_yogurt', title: 'Хрустящие кукурузные оладушки с йогуртом и зеленым луком', m: 'corn_canned', a: 'flour', b: 'egg', d: 'yogurt', c: 'us' },
  { id: 'zucchini_chips_parmesan_oven', title: 'Тонкие запеченные чипсы из кабачков с сыром пармезан', m: 'zucchini', a: 'parmesan', b: 'breadcrumbs', d: 'paprika', c: 'home', heatSec: 900 },
  { id: 'apple_peanut_butter_snack', title: 'Быстрый перекус: дольки яблока с арахисом и корицей', m: 'apple', a: 'peanut', b: 'honey', d: 'cinnamon', c: 'us' },
  { id: 'banana_oats_energy_bites', title: 'Полезные орехово-банановые шарики с овсянкой и какао', m: 'banana', a: 'rolled_oats', b: 'cocoa', d: 'walnut', c: 'home' },
  { id: 'dates_almond_coconut_snack', title: 'Восточная закуска к чаю: сладкие финики с миндалем и кокосом', m: 'dates', a: 'almond', b: 'coconut_flakes', d: 'butter', c: 'home' },
  { id: 'dried_apricots_walnut_honey', title: 'Витаминная смесь из кураги с изюмом, лимоном и медом', m: 'dried_apricots', a: 'raisins', b: 'lemon', d: 'honey', c: 'ru' },
  { id: 'sausage_cheese_lavash_triangles', title: 'Жареные конвертики из лаваша с колбасой, томатом и сыром', m: 'lavash', a: 'sausage', b: 'tomato', d: 'hard_cheese', c: 'ru', heatSec: 360 },
  { id: 'frankfurters_in_lavash_crispy', title: 'Быстрые хрустящие сосиски в лаваше с кетчупом и сыром', m: 'frankfurters', a: 'lavash', b: 'hard_cheese', d: 'ketchup', c: 'ru', heatSec: 420 },
  { id: 'potato_croquettes_herbs_snack', title: 'Закусочные картофельные шарики с укропом и паприкой', m: 'potato', a: 'breadcrumbs', b: 'egg', d: 'dill', c: 'home', heatSec: 900 },
  { id: 'carrot_pancakes_garlic_mayo', title: 'Острые морковные блинчики с чесночным соусом', m: 'carrot', a: 'egg', b: 'garlic', d: 'mayonnaise', c: 'ru' },
  { id: 'beet_pancakes_feta_dill', title: 'Яркие свекольные оладьи с раскрошенной фетой и укропом', m: 'beet', a: 'feta', b: 'egg', d: 'dill', c: 'home' },
  { id: 'tomato_cheese_canape_basil', title: 'Закуска на шпажках: томаты черри с сыром моцарелла и оливками', m: 'cherry_tomato', a: 'mozzarella', b: 'olives', d: 'basil', c: 'it' },
  { id: 'cucumber_canape_ham_cheese', title: 'Праздничные канапе с огурцом, ветчиной и сливочным сыром', m: 'cucumber', a: 'ham', b: 'cream_cheese', d: 'black_bread', c: 'ru' },
  { id: 'radish_cottage_cheese_dill', title: 'Весенняя намазка с тертым редисом, творогом и укропом', m: 'radish', a: 'cottage_cheese', b: 'dill', d: 'sour_cream', c: 'ru' },
  { id: 'garlic_cheese_tomato_rings', title: 'Кружочки спелых томатов с тертым сыром и чесноком', m: 'tomato', a: 'cheese', b: 'garlic', d: 'mayonnaise', c: 'ru' },
  { id: 'avocado_tuna_cucumber_boats', title: 'Лодочки из свежих огурцов с тунцом, авокадо и свежим лимоном', m: 'cucumber', a: 'tuna_canned', b: 'avocado', d: 'lemon', c: 'home' },
  { id: 'cranberry_cabbage_snack_honey', title: 'Пряная хрустящая капуста провансаль с клюквой и чесноком', m: 'cabbage', a: 'cranberry', b: 'garlic', d: 'apple_vinegar', c: 'ru' }
];

// Fix chives -> green_onion in radish_butter_bread_french
for (const it of snacks) {
  if (it.d === 'chives') it.d = 'green_onion';
  addSalad({
    id: it.id,
    title: it.title,
    dish_type: 'snack',
    cuisine: it.c,
    time: 25,
    active: 15,
    heatSec: it.heatSec,
    desc: `Простая и яркая закуска «${it.title}» для быстрого перекуса или гостей.`,
    ings: [it.m, it.a, it.b, it.d, 'salt']
  });
}

console.log(`Total generated salads & snacks: ${allSalads.length}`);
saveAndValidateGroup('salads.json', allSalads);
