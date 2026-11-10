const { saveAndValidateGroup, smartIngredient } = require('./recipe_builder');

function s(text, timer_seconds, tip) {
  const step = { text: text.trim() };
  if (timer_seconds) step.timer_seconds = timer_seconds;
  if (tip) step.tip = tip;
  return step;
}

const allEggDairy = [];

function addED(def) {
  const id = `ed_${def.id}`;
  const title = def.title;
  const time = def.time || 25;
  const active = def.active || 15;
  const servings = def.servings || 3;
  const cuisine = def.cuisine || 'home';
  const dishType = def.dish_type || 'breakfast';
  const desc = def.desc || `Питательный и вкусный рецепт «${title}» из яиц и свежих молочных продуктов.`;

  const ingsMap = new Map();
  for (const raw of def.ings) {
    const rawId = raw.ingredient_id || raw.id || raw;
    const ingObj = smartIngredient(rawId, raw.amount, raw.unit);
    ingsMap.set(rawId, ingObj);
  }
  const ings = Array.from(ingsMap.values());

  const hasEgg = ingsMap.has('egg');
  const hasPork = ['pork', 'bacon'].some(k => ingsMap.has(k));

  let heatVerb = def.verb || 'обжаривайте на сковороде';
  if (hasEgg && !['вар', 'жар', 'запек'].some(k => heatVerb.toLowerCase().includes(k))) {
    heatVerb = 'запекайте в духовке';
  }
  const heatSec = hasPork ? 960 : (def.heatSec !== undefined ? def.heatSec : (hasEgg ? 420 : 0));

  const steps = [];
  steps.push(s(`Для блюда «${title}» достаньте свежие продукты из холодильника и подготовьте удобную миску для смешивания.`));
  if (hasEgg) {
    steps.push(s(`Аккуратно вбейте яйца и соедините компоненты для «${title}» до однородного состояния.`));
  } else {
    steps.push(s(`Соедините молочную основу и подготовленные добавки для «${title}», аккуратно перемешав ложкой.`));
  }

  if (heatSec > 0) {
    steps.push(s(`${heatVerb.charAt(0).toUpperCase() + heatVerb.slice(1)} массу${hasEgg ? ' с яйцом' : ''} для «${title}» в течение ${Math.ceil(heatSec / 60)} минут до румяной корочки и плотной текстуры.`, heatSec));
  } else {
    steps.push(s(`Выложите готовое лакомство «${title}» в глубокую пиалу или креманку и дайте вкусу немного раскрыться.`));
  }

  steps.push(s(`Подавайте свежее блюдо «${title}» к столу сразу после приготовления.`));

  allEggDairy.push({
    id: id,
    title: title,
    dish_type: dishType,
    dish_group: 'egg_dairy',
    cuisine: cuisine,
    total_minutes: Math.max(time, Math.ceil((heatSec || 0) / 60) + 10),
    active_minutes: active,
    servings: servings,
    description: desc,
    ingredients: ings,
    steps: steps
  });
}

// 1. Egg Dishes: Omelets, Shakshuka, Frittata, Poached, Scrambled, Tortillas (45)
const eggDishes = [
  { id: 'shakshuka_classic_tomato', title: 'Шакшука из яиц в пряном соусе из помидоров и паприки', e: 'egg', a: 'tomato', b: 'bell_pepper', d: 'paprika', c: 'tr', v: 'обжаривайте в сковороде', heatSec: 600 },
  { id: 'shakshuka_green_spinach_feta', title: 'Зеленая шакшука со шпинатом, щавелем и сыром фета', e: 'egg', a: 'spinach', b: 'sorrel', d: 'feta', c: 'tr', v: 'обжаривайте под крышкой', heatSec: 540 },
  { id: 'omelet_poularde_fluffy', title: 'Пышный французский омлет Пуляр со сливочным маслом', e: 'egg', a: 'butter', b: 'cream', d: 'parsley', c: 'fr', v: 'обжаривайте на медленном огне', heatSec: 420 },
  { id: 'omelet_champignon_dill', title: 'Сытный омлет с обжаренными шампиньонами и укропом', e: 'egg', a: 'champignon', b: 'dill', d: 'milk', c: 'ru', v: 'обжаривайте на сковороде', heatSec: 480 },
  { id: 'omelet_zucchini_mozzarella', title: 'Нежный омлет в духовке с тертым кабачком и моцареллой', e: 'egg', a: 'zucchini', b: 'mozzarella', d: 'milk', c: 'it', v: 'запекайте в духовке', heatSec: 900 },
  { id: 'omelet_broccoli_cheddar', title: 'Питательный омлет с соцветиями брокколи и твердым сыром', e: 'egg', a: 'broccoli', b: 'hard_cheese', d: 'milk', c: 'home', v: 'запекайте в духовке', heatSec: 900 },
  { id: 'omelet_ham_bell_pepper', title: 'Быстрый утренний омлет с ветчиной и сладким перцем', e: 'egg', a: 'ham', b: 'bell_pepper', d: 'milk', c: 'ru', v: 'обжаривайте на сковороде', heatSec: 420 },
  { id: 'omelet_spinach_cherry_tomato', title: 'Яркий омлет с листьями шпината и томатами черри', e: 'egg', a: 'spinach', b: 'cherry_tomato', d: 'cream', c: 'home', v: 'обжаривайте на тихом огне', heatSec: 480 },
  { id: 'omelet_cottage_cheese_herbs', title: 'Белковый омлет с нежным творогом и зеленым луком', e: 'egg', a: 'cottage_cheese', b: 'green_onion', d: 'milk', c: 'home', v: 'обжаривайте под крышкой', heatSec: 480 },
  { id: 'omelet_japanese_tamagoyaki', title: 'Японский сладковатый рулет-омлет тамагояки с соусом', e: 'egg', a: 'soy_sauce', b: 'sugar', d: 'sesame', c: 'jp', v: 'обжаривайте слоями на сковороде', heatSec: 480 },
  { id: 'omelet_chinese_tomato_stir', title: 'Китайский жареный омлет с сочными томатами и луком', e: 'egg', a: 'tomato', b: 'green_onion', d: 'sesame_oil', c: 'cn', v: 'обжаривайте в воке', heatSec: 360 },
  { id: 'omelet_cauliflower_sour_cream', title: 'Запеченный омлет с цветной капустой и сметаной в духовке', e: 'egg', a: 'cauliflower', b: 'sour_cream', d: 'dill', c: 'ru', v: 'запекайте в духовке', heatSec: 900 },
  { id: 'omelet_oyster_mushroom_leek', title: 'Ароматный омлет с вешенками, луком-пореем и сливками', e: 'egg', a: 'oyster_mushroom', b: 'leek', d: 'cream', c: 'fr', v: 'обжаривайте в сковороде', heatSec: 540 },
  { id: 'frittata_potato_onion_spanish', title: 'Испанская картофельная тортилья с репчатым луком', e: 'egg', a: 'potato', b: 'onion', d: 'olive_oil', c: 'es', v: 'обжаривайте под крышкой', heatSec: 720 },
  { id: 'frittata_asparagus_parmesan', title: 'Итальянская фриттата с зеленой спаржей и пармезаном', e: 'egg', a: 'asparagus', b: 'parmesan', d: 'cream', c: 'it', v: 'запекайте в духовке', heatSec: 900 },
  { id: 'frittata_eggplant_basil_feta', title: 'Средиземноморская фриттата с баклажаном и сыром фета', e: 'egg', a: 'eggplant', b: 'feta', d: 'basil', c: 'gr', v: 'запекайте в духовке', heatSec: 900 },
  { id: 'frittata_green_peas_mint', title: 'Весенняя фриттата с зеленым горошком, мятой и сыром', e: 'egg', a: 'green_peas', b: 'mint', d: 'hard_cheese', c: 'it', v: 'обжаривайте и запекайте', heatSec: 720 },
  { id: 'frittata_corn_sausage_bake', title: 'Сытная фриттата со сладкой кукурузой и колбасой', e: 'egg', a: 'corn_canned', b: 'sausage', d: 'cheese', c: 'us', v: 'запекайте в духовке', heatSec: 900 },
  { id: 'frittata_sweet_potato_rosemary', title: 'Золотистая фриттата со сладким бататом и розмарином', e: 'egg', a: 'sweet_potato', b: 'rosemary', d: 'feta', c: 'home', v: 'запекайте в духовке', heatSec: 900 },
  { id: 'scrambled_chibuli_georgian', title: 'Грузинская яичница чирбули с томатами и грецким орехом', e: 'egg', a: 'tomato', b: 'walnut', d: 'cilantro', c: 'ge', v: 'обжаривайте в сотейнике', heatSec: 480 },
  { id: 'scrambled_menemen_turkish', title: 'Турецкая яичница менемен со сладким перцем и сыром', e: 'egg', a: 'bell_pepper', b: 'tomato', d: 'feta', c: 'tr', v: 'обжаривайте в сковороде', heatSec: 480 },
  { id: 'scrambled_bacon_beans_english', title: 'Сытная яичница с беконом, фасолью и томатами', e: 'egg', a: 'bacon', b: 'beans_canned', d: 'tomato', c: 'uk', v: 'обжаривайте на сковороде', heatSec: 960 },
  { id: 'scrambled_frankfurters_peas', title: 'Утренняя яичница с сосисками и зеленым горошком', e: 'egg', a: 'frankfurters', b: 'green_peas', d: 'butter', c: 'ru', v: 'обжаривайте на сковороде', heatSec: 360 },
  { id: 'scrambled_black_bread_garlic', title: 'Деревенская яичница в ломтиках черного хлеба с укропом', e: 'egg', a: 'black_bread', b: 'garlic', d: 'dill', c: 'ru', v: 'обжаривайте на сковороде', heatSec: 360 },
  { id: 'scrambled_avocado_chili_toast', title: 'Яичница с томатами черри и авокадо на хрустящем тосте', e: 'egg', a: 'white_bread', b: 'avocado', d: 'cherry_tomato', c: 'home', v: 'обжаривайте на масле', heatSec: 360 },
  { id: 'eggs_cocotte_cream_spinach', title: 'Французские яйца кокот, запеченные в сливках со шпинатом', e: 'egg', a: 'cream', b: 'spinach', d: 'parmesan', c: 'fr', v: 'запекайте в духовке', heatSec: 720 },
  { id: 'eggs_cocotte_ham_mushroom', title: 'Яйца кокот в формочках с ветчиной, сыром и шампиньонами', e: 'egg', a: 'ham', b: 'champignon', d: 'sour_cream', c: 'fr', v: 'запекайте в духовке', heatSec: 720 },
  { id: 'eggs_poached_yogurt_cilbir', title: 'Турецкие яйца пашот чилбир на йогурте с чесноком и паприкой', e: 'egg', a: 'yogurt', b: 'paprika', d: 'butter', c: 'tr', v: 'варите в кипящей воде', heatSec: 240 },
  { id: 'eggs_poached_avocado_rye', title: 'Полезные яйца пашот на черном хлебе с кремом из авокадо', e: 'egg', a: 'avocado', b: 'black_bread', d: 'lemon', c: 'home', v: 'варите в воде', heatSec: 240 },
  { id: 'eggs_orsini_cloud_cheese', title: 'Воздушные яйца Орсини в белковых облаках с тертым сыром', e: 'egg', a: 'hard_cheese', b: 'butter', d: 'parsley', c: 'it', v: 'запекайте в духовке', heatSec: 600 },
  { id: 'egg_muffins_ham_spinach', title: 'Запеченные яичные маффины с ветчиной, шпинатом и перцем', e: 'egg', a: 'ham', b: 'spinach', d: 'bell_pepper', c: 'us', v: 'запекайте в духовке', heatSec: 1200 },
  { id: 'egg_lavash_envelope_cheese', title: 'Горячий хрустящий конвертик из лаваша с яйцом и зеленью', e: 'egg', a: 'lavash', b: 'cheese', d: 'dill', c: 'ru', v: 'обжаривайте на сковороде', heatSec: 360 },
  { id: 'egg_pita_breakfast_tomato', title: 'Быстрый завтрак в пите с жареным яйцом, сыром и томатом', e: 'egg', a: 'pita', b: 'tomato', d: 'cheese', c: 'home', v: 'обжаривайте на сковороде', heatSec: 360 },
  { id: 'egg_tortilla_breakfast_beans', title: 'Сытный буррито с омлетом, фасолью и авокадо в тортилье', e: 'egg', a: 'tortilla', b: 'beans_canned', d: 'avocado', c: 'mx', v: 'обжаривайте на сковороде', heatSec: 420 },
  { id: 'egg_kasha_kindergarten_omelet', title: 'Высокий пышный омлет на молоке, как в детском саду', e: 'egg', a: 'milk', b: 'butter', d: 'sour_cream', c: 'ru', v: 'запекайте в духовке', heatSec: 1200 },
  { id: 'egg_green_beans_garlic_pan', title: 'Запеканка из яиц со стручковой фасолью и чесноком', e: 'egg', a: 'green_beans', b: 'garlic', d: 'sour_cream', c: 'home', v: 'запекайте в духовке', heatSec: 900 },
  { id: 'egg_squash_omelet_cheese', title: 'Яркий омлет с тертой тыквой и сливочным сыром', e: 'egg', a: 'squash', b: 'cream_cheese', d: 'nutmeg', c: 'home', v: 'запекайте в духовке', heatSec: 900 },
  { id: 'egg_pasta_vermicelli_bake', title: 'Утренняя яичная запеканка с тонкой вермишелью и сыром', e: 'egg', a: 'vermicelli', b: 'hard_cheese', d: 'milk', c: 'ru', v: 'запекайте в духовке', heatSec: 900 },
  { id: 'egg_scotch_minced_bake', title: 'Яйца по-шотландски в оболочке из куриного фарша в духовке', e: 'egg', a: 'minced_chicken', b: 'breadcrumbs', d: 'mustard', c: 'uk', v: 'запекайте в духовке', heatSec: 1200 },
  { id: 'egg_baked_avocado_halves', title: 'Половинки спелого авокадо, запеченные с яйцом и зеленью', e: 'egg', a: 'avocado', b: 'dill', d: 'paprika', c: 'home', v: 'запекайте в духовке', heatSec: 900 },
  { id: 'egg_crouton_sweet_milk_toast', title: 'Сладкие гренки из белого хлеба, обжаренные в молоке и яйце', e: 'egg', a: 'white_bread', b: 'milk', d: 'sugar', c: 'ru', v: 'обжаривайте на сковороде', heatSec: 360 },
  { id: 'egg_crouton_savory_cheese_herbs', title: 'Золотистые гренки с яйцом, тертым сыром и петрушкой', e: 'egg', a: 'bread', b: 'cheese', d: 'parsley', c: 'ru', v: 'обжаривайте с двух сторон', heatSec: 360 },
  { id: 'egg_eggplant_tomato_omelet', title: 'Кавказский омлет с кубиками баклажанов и кинзой', e: 'egg', a: 'eggplant', b: 'cilantro', d: 'tomato', c: 'ge', v: 'обжаривайте на сковороде', heatSec: 600 },
  { id: 'egg_carrot_apple_sweet_omelet', title: 'Сладкий яблочный омлет с корицей и медом к чаю', e: 'egg', a: 'apple', b: 'honey', d: 'cinnamon', c: 'de', v: 'обжаривайте под крышкой', heatSec: 480 },
  { id: 'egg_baked_potato_nests', title: 'Хрустящие картофельные гнезда, запеченные с яйцом и сыром', e: 'egg', a: 'potato', b: 'hard_cheese', d: 'butter', c: 'home', v: 'запекайте в духовке', heatSec: 1200 }
];

for (const it of eggDishes) {
  addED({
    id: it.id,
    title: it.title,
    dish_type: 'breakfast',
    cuisine: it.c,
    time: 25,
    active: 15,
    verb: it.v,
    heatSec: it.heatSec,
    desc: `Аппетитный яичный завтрак «${it.title}» за считанные минуты.`,
    ings: [it.e, it.a, it.b, it.d, 'sunflower_oil', 'salt']
  });
}

// 2. Cottage Cheese (Tvorog) Specialties: Syrniki, Vareniki, Casseroles, Sweet & Savory Bowls (45)
const tvorogDishes = [
  { id: 'syrniki_classic_vanilla_flour', title: 'Румяные классические сырники со сметаной и ванилью', e: 'cottage_cheese', a: 'egg', b: 'flour', d: 'vanilla_sugar', c: 'ru', v: 'обжаривайте с двух сторон', heatSec: 480 },
  { id: 'syrniki_semolina_raisins', title: 'Нежные творожные сырники на манке с золотистым изюмом', e: 'cottage_cheese', a: 'semolina', b: 'raisins', d: 'egg', c: 'ru', v: 'обжаривайте на сковороде', heatSec: 480 },
  { id: 'syrniki_coconut_banana', title: 'Полезные сырники без сахара с бананом и кокосовой стружкой', e: 'cottage_cheese', a: 'banana', b: 'coconut_flakes', d: 'egg', c: 'home', v: 'обжаривайте на сковороде', heatSec: 480 },
  { id: 'syrniki_wholegrain_apple', title: 'Диетические сырники с яблоком на цельнозерновой муке', e: 'cottage_cheese', a: 'wholegrain_flour', b: 'apple', d: 'egg', c: 'home', v: 'запекайте в духовке', heatSec: 900 },
  { id: 'syrniki_baked_cherry_sauce', title: 'Запеченные в духовке сырники под теплым вишневым соусом', e: 'cottage_cheese', a: 'cherry', b: 'egg', d: 'starch', c: 'ru', v: 'запекайте в духовке', heatSec: 1200 },
  { id: 'syrniki_pumpkin_cinnamon', title: 'Яркие осенние сырники со сладкой тыквой и корицей', e: 'cottage_cheese', a: 'squash', b: 'cinnamon', d: 'egg', c: 'ru', v: 'обжаривайте на масле', heatSec: 480 },
  { id: 'syrniki_cocoa_chocolate_heart', title: 'Шоколадные сырники с какао и растопленной шоколадкой', e: 'cottage_cheese', a: 'cocoa', b: 'chocolate', d: 'egg', c: 'home', v: 'обжаривайте на сковороде', heatSec: 480 },
  { id: 'syrniki_savory_dill_garlic', title: 'Пикантные соленые сырники с укропом и твердым сыром', e: 'cottage_cheese', a: 'hard_cheese', b: 'dill', d: 'egg', c: 'ru', v: 'обжаривайте до румяности', heatSec: 480 },
  { id: 'syrniki_poppy_seeds_honey', title: 'Пышные сырники с кондитерским маком и жидким медом', e: 'cottage_cheese', a: 'poppy_seeds', b: 'honey', d: 'egg', c: 'ru', v: 'обжаривайте на сковороде', heatSec: 480 },
  { id: 'syrniki_oatmeal_berries', title: 'Утренние сырники с овсянкой и свежей лесной черникой', e: 'cottage_cheese', a: 'oatmeal', b: 'blueberry', d: 'egg', c: 'home', v: 'обжаривайте под крышкой', heatSec: 480 },
  { id: 'lazy_vareniki_butter_sugar', title: 'Домашние ленивые вареники с творогом и сливочным маслом', e: 'cottage_cheese', a: 'flour', b: 'egg', d: 'butter', c: 'ru', v: 'варите в кипящей воде', heatSec: 300 },
  { id: 'lazy_vareniki_strawberry_cream', title: 'Нежные ленивые вареники со свежей клубникой и сметаной', e: 'cottage_cheese', a: 'strawberry', b: 'sour_cream', d: 'egg', c: 'ru', v: 'варите 5 минут', heatSec: 300 },
  { id: 'lazy_vareniki_blueberry_yogurt', title: 'Полезные ленивые вареники из рисовой муки или манки с черникой', e: 'cottage_cheese', a: 'semolina', b: 'blueberry', d: 'egg', c: 'home', v: 'варите на тихом огне', heatSec: 300 },
  { id: 'lazy_vareniki_savory_dill_cheese', title: 'Несладкие ленивые вареники с укропом, сметаной и сыром', e: 'cottage_cheese', a: 'cheese', b: 'dill', d: 'egg', c: 'ru', v: 'варите в подсоленной воде', heatSec: 300 },
  { id: 'zapekanka_peach_semolina', title: 'Нежная творожная запеканка с дольками сочных персиков', e: 'cottage_cheese', a: 'peach', b: 'semolina', d: 'egg', c: 'ru', v: 'запекайте в духовке', heatSec: 1500 },
  { id: 'zapekanka_dried_apricots_yogurt', title: 'Творожная запеканка в духовке с курагой и йогуртом', e: 'cottage_cheese', a: 'dried_apricots', b: 'yogurt', d: 'egg', c: 'home', v: 'запекайте в духовке', heatSec: 1500 },
  { id: 'zapekanka_banana_condensed_milk', title: 'Банановая творожная запеканка со сгущенкой без муки', e: 'cottage_cheese', a: 'banana', b: 'condensed_milk', d: 'egg', c: 'home', v: 'запекайте в духовке', heatSec: 1500 },
  { id: 'zapekanka_raspberry_starch', title: 'Пышная творожная запеканка с малиной и ванилью', e: 'cottage_cheese', a: 'raspberry', b: 'starch', d: 'egg', c: 'ru', v: 'запекайте в духовке', heatSec: 1500 },
  { id: 'zapekanka_pear_almond_cinnamon', title: 'Творожная запеканка с грушей, корицей и миндалем', e: 'cottage_cheese', a: 'pear', b: 'almond', d: 'egg', c: 'home', v: 'запекайте в духовке', heatSec: 1500 },
  { id: 'zapekanka_zebra_cocoa_cream', title: 'Полосатая творожная запеканка Зебра с какао и сметаной', e: 'cottage_cheese', a: 'cocoa', b: 'sour_cream', d: 'egg', c: 'ru', v: 'запекайте в духовке', heatSec: 1800 },
  { id: 'zapekanka_apple_prunes_honey', title: 'Витаминная творожная запеканка с черносливом и яблоком', e: 'cottage_cheese', a: 'prunes', b: 'apple', d: 'egg', c: 'ru', v: 'запекайте в духовке', heatSec: 1500 },
  { id: 'zapekanka_squash_orange_zest', title: 'Двухслойная тыквенно-творожная запеканка с апельсином', e: 'cottage_cheese', a: 'squash', b: 'orange', d: 'egg', c: 'home', v: 'запекайте в духовке', heatSec: 1800 },
  { id: 'zapekanka_carrot_semolina_children', title: 'Детская творожно-морковная запеканка с манкой и изюмом', e: 'cottage_cheese', a: 'carrot', b: 'raisins', d: 'egg', c: 'ru', v: 'запекайте в духовке', heatSec: 1500 },
  { id: 'zapekanka_currant_black_cream', title: 'Ароматная запеканка из творога с черной смородиной', e: 'cottage_cheese', a: 'currant_black', b: 'cream', d: 'egg', c: 'ru', v: 'запекайте в духовке', heatSec: 1500 },
  { id: 'zapekanka_savory_zucchini_herbs', title: 'Несладкая запеканка с творогом, кабачками и укропом', e: 'cottage_cheese', a: 'zucchini', b: 'dill', d: 'egg', c: 'home', v: 'запекайте в духовке', heatSec: 1500 },
  { id: 'zapekanka_savory_spinach_feta', title: 'Греческая запеканка со шпинатом, творогом и брынзой', e: 'cottage_cheese', a: 'spinach', b: 'feta', d: 'egg', c: 'gr', v: 'запекайте в духовке', heatSec: 1500 },
  { id: 'paskha_curd_raisins_candied', title: 'Творожная праздничная масса с изюмом, цукатами и орехом', e: 'cottage_cheese', a: 'raisins', b: 'butter', d: 'almond', c: 'ru', heatSec: 0, dish_type: 'dessert' },
  { id: 'tvorog_bowl_sour_cream_jam', title: 'Деревенский рассыпчатый творог со сметаной и вареньем', e: 'cottage_cheese', a: 'sour_cream', b: 'jam', d: 'walnut', c: 'ru', heatSec: 0 },
  { id: 'tvorog_bowl_banana_honey_cinnamon', title: 'Полезный завтрак: творог со спелым бананом, медом и орехами', e: 'cottage_cheese', a: 'banana', b: 'honey', d: 'hazelnut', c: 'home', heatSec: 0 },
  { id: 'tvorog_bowl_persimmon_orange', title: 'Витаминный творог со сладкой хурмой и дольками апельсина', e: 'cottage_cheese', a: 'persimmon', b: 'orange', d: 'yogurt', c: 'home', heatSec: 0 },
  { id: 'tvorog_bowl_kiwi_blueberry_seeds', title: 'Утренний творог с киви, черникой и тыквенными семечками', e: 'cottage_cheese', a: 'kiwi', b: 'blueberry', d: 'pumpkin_seeds', c: 'home', heatSec: 0 },
  { id: 'tvorog_bowl_fig_pistachio_honey', title: 'Изысканный творожный завтрак со свежим инжиром и фисташками', e: 'cottage_cheese', a: 'fig', b: 'pistachio', d: 'honey', c: 'home', heatSec: 0 },
  { id: 'tvorog_bowl_cucumber_radish_kefir', title: 'Освежающий соленый творог с огурцом, редисом и кефиром', e: 'cottage_cheese', a: 'cucumber', b: 'radish', d: 'kefir', c: 'ru', heatSec: 0 },
  { id: 'tvorog_cream_halva_sour_cream', title: 'Сладкий взбитый творожный крем с халвой и сметаной', e: 'cottage_cheese', a: 'halva', b: 'sour_cream', d: 'vanilla', c: 'home', heatSec: 0, dish_type: 'dessert' },
  { id: 'tvorog_cream_cranberry_sugar', title: 'Взбитый нежный творог с протертой клюквой и сливками', e: 'cottage_cheese', a: 'cranberry', b: 'cream', d: 'sugar', c: 'ru', heatSec: 0 },
  { id: 'tvorog_baked_pears_walnuts', title: 'Половинки груш, запеченные с творогом, медом и орехами', e: 'cottage_cheese', a: 'pear', b: 'walnut', d: 'honey', c: 'home', v: 'запекайте в духовке', heatSec: 900 },
  { id: 'tvorog_baked_quince_apples', title: 'Сочные яблоки, запеченные с творогом, клюквой и корицей', e: 'cottage_cheese', a: 'apple', b: 'cranberry', d: 'cinnamon', c: 'ru', v: 'запекайте в духовке', heatSec: 1200 },
  { id: 'tvorog_plum_strudel_lavash', title: 'Творожный быстрый рулет со сливами и медом в лаваше', e: 'cottage_cheese', a: 'plum', b: 'lavash', d: 'egg', c: 'home', v: 'запекайте в духовке', heatSec: 1200 },
  { id: 'tvorog_cherry_galette_pita', title: 'Творожная запеканка с вишней и кукурузной крупой', e: 'cottage_cheese', a: 'cherry', b: 'cornmeal', d: 'egg', c: 'home', v: 'запекайте в духовке', heatSec: 1500 },
  { id: 'tvorog_oat_cookies_pan', title: 'Творожные лепешки с овсяными хлопьями и изюмом', e: 'cottage_cheese', a: 'rolled_oats', b: 'raisins', d: 'egg', c: 'home', v: 'обжаривайте на сухой сковороде', heatSec: 480 },
  { id: 'tvorog_dates_cocoa_balls', title: 'Творожные пирожные картошка без выпечки с финиками и какао', e: 'cottage_cheese', a: 'dates', b: 'cocoa', d: 'cookies', c: 'home', heatSec: 0, dish_type: 'dessert' },
  { id: 'tvorog_melon_mint_dessert', title: 'Летний творожный десерт с кусочками дыни и свежей мятой', e: 'cottage_cheese', a: 'melon', b: 'mint', d: 'yogurt', c: 'home', heatSec: 0, dish_type: 'dessert' },
  { id: 'tvorog_currant_red_honey', title: 'Творог с кислинкой красной смородины и цветочным медом', e: 'cottage_cheese', a: 'currant_red', b: 'honey', d: 'cream', c: 'ru', heatSec: 0 },
  { id: 'tvorog_sweet_cherry_cream', title: 'Летний творожный крем со спелой черешней и сливками', e: 'cottage_cheese', a: 'sweet_cherry', b: 'cream', d: 'sugar', c: 'home', heatSec: 0 },
  { id: 'tvorog_blackberry_sunflower_honey', title: 'Белковый завтрак с творогом, ежевикой и семечками', e: 'cottage_cheese', a: 'blackberry', b: 'sunflower_seeds', d: 'honey', c: 'home', heatSec: 0 }
];

for (const it of tvorogDishes) {
  addED({
    id: it.id,
    title: it.title,
    dish_type: it.dish_type || 'breakfast',
    cuisine: it.c,
    time: 30,
    active: 15,
    verb: it.v,
    heatSec: it.heatSec,
    desc: `Нежное и полезное творожное блюдо «${it.title}» для вкусного домашнего утра.`,
    ings: [it.e, it.a, it.b, it.d, 'salt']
  });
}

// 3. Milk, Kefir, Yogurt, Cheese, Curdled Milk & Buttermilk Dishes (45)
const dairyCheeseDishes = [
  { id: 'cheese_fondue_bread_garlic', title: 'Швейцарское сырное фондю с чесноком и хрустящим хлебом', m: 'hard_cheese', a: 'cream', b: 'garlic', d: 'white_bread', c: 'fr', v: 'растопите на тихом огне', heatSec: 480, dish_type: 'snack' },
  { id: 'cheese_baked_feta_tomato_honey', title: 'Запеченная в духовке фета с медом, кунжутом и черри', m: 'feta', a: 'cherry_tomato', b: 'honey', d: 'sesame', c: 'gr', v: 'запекайте в духовке', heatSec: 900, dish_type: 'snack' },
  { id: 'cheese_mozzarella_in_carrozza', title: 'Жареные гренки моцарелла ин карроцца в яйце и сухарях', m: 'mozzarella', a: 'white_bread', b: 'egg', d: 'breadcrumbs', c: 'it', v: 'обжаривайте в масле', heatSec: 360, dish_type: 'snack' },
  { id: 'cheese_fried_pan_breadcrumbs', title: 'Жареный сыр по-чешски смажены сыр в хрустящей панировке', m: 'hard_cheese', a: 'breadcrumbs', b: 'egg', d: 'flour', c: 'home', v: 'обжаривайте с двух сторон', heatSec: 360, dish_type: 'main' },
  { id: 'cheese_khachapuri_lazy_pan', title: 'Ленивый хачапури на сковороде с сыром, кефиром и яйцом', m: 'cheese', a: 'kefir', b: 'flour', d: 'egg', c: 'ge', v: 'обжаривайте под крышкой', heatSec: 600 },
  { id: 'cheese_parmesan_chips_thyme', title: 'Хрустящие сырные чипсы из пармезана с веточкой тимьяна', m: 'parmesan', a: 'thyme', b: 'black_pepper', d: 'garlic', c: 'it', v: 'запекайте в духовке', heatSec: 360, dish_type: 'snack' },
  { id: 'cheese_baked_georgian_cornmeal', title: 'Горячий сыр, запеченный с помидорами и мятой в кеци', m: 'feta', a: 'tomato', b: 'butter', d: 'mint', c: 'ge', v: 'запекайте в духовке', heatSec: 720, dish_type: 'snack' },
  { id: 'cheese_cream_herb_dip_radish', title: 'Праздничный дип из сливочного сыра с зеленью и редисом', m: 'cream_cheese', a: 'dill', b: 'radish', d: 'sour_cream', c: 'home', heatSec: 0, dish_type: 'snack' },
  { id: 'cheese_processed_omelet_roll', title: 'Сырные рулеты из омлета с плавленым сыром и чесноком', m: 'processed_cheese', a: 'egg', b: 'garlic', d: 'dill', c: 'ru', v: 'обжаривайте тонкие омлеты', heatSec: 360, dish_type: 'snack' },
  { id: 'yogurt_granola_oats_honey', title: 'Полезный греческий йогурт с хрустящей овсянкой и черникой', m: 'yogurt', a: 'rolled_oats', b: 'blueberry', d: 'honey', c: 'home', heatSec: 0 },
  { id: 'yogurt_chia_oats_overnight', title: 'Ленивая ночная овсянка в баночке на йогурте с малиной', m: 'yogurt', a: 'oatmeal', b: 'raspberry', d: 'banana', c: 'home', heatSec: 0 },
  { id: 'yogurt_peach_pistachio_parfait', title: 'Слоеное парфе из густого йогурта с персиком и фисташками', m: 'yogurt', a: 'peach', b: 'pistachio', d: 'cookies', c: 'home', heatSec: 0, dish_type: 'dessert' },
  { id: 'yogurt_apple_walnut_cinnamon', title: 'Свежий йогурт с кусочками яблока, орехами и корицей', m: 'yogurt', a: 'apple', b: 'walnut', d: 'cinnamon', c: 'home', heatSec: 0 },
  { id: 'yogurt_carrot_cucumber_raita', title: 'Индийский освежающий соус-закуска райта с огурцом и тмином', m: 'yogurt', a: 'cucumber', b: 'cumin', d: 'mint', c: 'in', heatSec: 0, dish_type: 'snack' },
  { id: 'kefir_oladi_fluffy_apples', title: 'Пышные оладьи на кефире с тертым яблоком и корицей', m: 'kefir', a: 'flour', b: 'apple', d: 'egg', c: 'ru', v: 'обжаривайте на сковороде', heatSec: 480 },
  { id: 'kefir_oladi_zucchini_herbs', title: 'Нежные несладкие оладьи на кефире с кабачком и укропом', m: 'kefir', a: 'zucchini', b: 'flour', d: 'egg', c: 'ru', v: 'обжаривайте с двух сторон', heatSec: 480 },
  { id: 'kefir_overnight_oats_prunes', title: 'Вечерняя или утренняя овсянка на кефире с черносливом', m: 'kefir', a: 'oatmeal', b: 'prunes', d: 'honey', c: 'ru', heatSec: 0 },
  { id: 'kefir_mannik_quick_skillet', title: 'Быстрый манник на кефире с изюмом на сковороде', m: 'kefir', a: 'semolina', b: 'raisins', d: 'egg', c: 'ru', v: 'запекайте под крышкой', heatSec: 1200 },
  { id: 'kefir_green_herbs_bowl', title: 'Летняя заправка-боул на кефире со свежей зеленью и огурцом', m: 'kefir', a: 'cucumber', b: 'dill', d: 'green_onion', c: 'ru', heatSec: 0, dish_type: 'snack' },
  { id: 'buttermilk_pancakes_classic', title: 'Американские толстые панкейки на пахте со сливочным маслом', m: 'buttermilk', a: 'flour', b: 'egg', d: 'butter', c: 'us', v: 'жарьте на сухой сковороде', heatSec: 480 },
  { id: 'buttermilk_oatmeal_berries', title: 'Утренняя овсянка на пахте со свежей клубникой и медом', m: 'buttermilk', a: 'rolled_oats', b: 'strawberry', d: 'honey', c: 'home', v: 'варите до загустения', heatSec: 480 },
  { id: 'buttermilk_scones_lemon_zest', title: 'Воздушные лепешки сконы на пахте с лимонной цедрой', m: 'buttermilk', a: 'flour', b: 'lemon', d: 'baking_powder', c: 'uk', v: 'запекайте в духовке', heatSec: 1080, dish_type: 'baking' },
  { id: 'curdled_milk_berries_honey', title: 'Домашняя густая простокваша со спелой малиной и медом', m: 'curdled_milk', a: 'raspberry', b: 'honey', d: 'almond', c: 'ru', heatSec: 0 },
  { id: 'curdled_milk_pancakes_classic', title: 'Кружевные блины на кислой простокваше со сливочным маслом', m: 'curdled_milk', a: 'flour', b: 'egg', d: 'butter', c: 'ru', v: 'жарьте тонкие блины', heatSec: 600 },
  { id: 'curdled_milk_garlic_dill_spread', title: 'Простая холодная простокваша по-деревенски с укропом', m: 'curdled_milk', a: 'dill', b: 'garlic', d: 'black_bread', c: 'ru', heatSec: 0, dish_type: 'snack' },
  { id: 'whey_bliny_thin_milk', title: 'Тончайшие блинчики с дырочками на домашней сыворотке', m: 'whey', a: 'flour', b: 'egg', d: 'sugar', c: 'ru', v: 'жарьте на сковороде', heatSec: 600 },
  { id: 'whey_oladi_fluffy_sugar', title: 'Экономичные пышные оладушки на молочной сыворотке', m: 'whey', a: 'flour', b: 'baking_soda', d: 'egg', c: 'ru', v: 'обжаривайте на сковороде', heatSec: 480 },
  { id: 'milk_pudding_vanilla_starch', title: 'Нежный французский молочный пудинг бланманже с ванилью', m: 'milk', a: 'starch', b: 'vanilla', d: 'sugar', c: 'fr', v: 'варите до загустения', heatSec: 480, dish_type: 'dessert' },
  { id: 'milk_panna_cotta_raspberry', title: 'Итальянская панна котта из сливок с малиновым соусом', m: 'cream', a: 'milk', b: 'raspberry', d: 'vanilla', c: 'it', v: 'нагрейте до кипения и остудите', heatSec: 300, dish_type: 'dessert' },
  { id: 'milk_cream_caramel_flan', title: 'Испанский молочный десерт флан с карамелью и яйцами', m: 'milk', a: 'egg', b: 'sugar', d: 'vanilla', c: 'es', v: 'запекайте на водяной бане', heatSec: 1800, dish_type: 'dessert' },
  { id: 'milk_chocolate_ganache_cream', title: 'Горячий шоколадный крем со сливками и кусочками банана', m: 'cream', a: 'chocolate', b: 'banana', d: 'butter', c: 'fr', v: 'растопите на бане', heatSec: 300, dish_type: 'dessert' },
  { id: 'sour_cream_jelly_cocoa', title: 'Шоколадно-сметанный сливочный десерт с ванилью и орехами', m: 'sour_cream', a: 'cocoa', b: 'walnut', d: 'sugar', c: 'ru', heatSec: 0, dish_type: 'dessert' },
  { id: 'sour_cream_strawberry_sugar', title: 'Свежая садовая клубника, взбитая со сметаной и сахаром', m: 'sour_cream', a: 'strawberry', b: 'sugar', d: 'mint', c: 'ru', heatSec: 0, dish_type: 'dessert' },
  { id: 'sour_cream_blackberry_honey', title: 'Густая сметана со свежей ежевикой и цветочным медом', m: 'sour_cream', a: 'blackberry', b: 'honey', d: 'almond', c: 'home', heatSec: 0 },
  { id: 'cream_whipped_peach_almond', title: 'Взбитые сливки со сладкими персиками и миндальными хлопьями', m: 'cream', a: 'peach', b: 'almond', d: 'vanilla_sugar', c: 'home', heatSec: 0, dish_type: 'dessert' },
  { id: 'condensed_milk_coconut_candy', title: 'Домашние конфеты из сгущенного молока с кокосовой стружкой', m: 'condensed_milk', a: 'coconut_flakes', b: 'almond', d: 'butter', c: 'home', heatSec: 0, dish_type: 'dessert' },
  { id: 'condensed_milk_halva_oat_bar', title: 'Быстрые сладкие батончики из сгущенки, овсянки и арахиса', m: 'condensed_milk', a: 'rolled_oats', b: 'peanut', d: 'butter', c: 'home', v: 'запекайте в духовке', heatSec: 900, dish_type: 'dessert' },
  { id: 'ice_cream_affogato_cocoa', title: 'Домашнее мороженое пломбир с горячим какао и тертым шоколадом', m: 'ice_cream', a: 'cocoa', b: 'chocolate', d: 'milk', c: 'it', v: 'сварите горячее какао', heatSec: 240, dish_type: 'dessert' },
  { id: 'ice_cream_baked_apple_cinnamon', title: 'Горячие печеные яблоки с корицей и шариком пломбира', m: 'ice_cream', a: 'apple', b: 'cinnamon', d: 'walnut', c: 'home', v: 'запекайте яблоки в духовке', heatSec: 1200, dish_type: 'dessert' },
  { id: 'ice_cream_fried_banana_caramel', title: 'Карамелизованный жареный банан со сливочным мороженым', m: 'ice_cream', a: 'banana', b: 'butter', d: 'caramel', c: 'home', v: 'обжаривайте бананы на сковороде', heatSec: 300, dish_type: 'dessert' },
  { id: 'powdered_milk_truffles_cocoa', title: 'Домашние сливочные трюфели из сухого молока и какао', m: 'powdered_milk', a: 'cocoa', b: 'butter', d: 'sugar', c: 'ru', heatSec: 0, dish_type: 'dessert' },
  { id: 'powdered_milk_burfi_indian', title: 'Индийские молочные конфеты бурфи с кардамоном и фисташками', m: 'powdered_milk', a: 'pistachio', b: 'cardamom', d: 'cream', c: 'in', v: 'варите до загустения', heatSec: 420, dish_type: 'dessert' },
  { id: 'milk_mascarpone_homemade_cream', title: 'Домашний нежный сливочный крем из жирных сливок и лимона', m: 'cream', a: 'lemon', b: 'butter', d: 'milk', c: 'it', v: 'прогрейте на тихом огне', heatSec: 480, dish_type: 'snack' },
  { id: 'milk_ginger_turmeric_golden', title: 'Пряное золотое теплое молоко с куркумой, имбирем и медом', m: 'milk', a: 'turmeric', b: 'ginger', d: 'honey', c: 'in', v: 'прогрейте без кипячения', heatSec: 300, dish_type: 'drink' },
  { id: 'cheese_cornmeal_bake_khachapuri', title: 'Сытная кукурузная лепешка мчади, запеченная с сыром', m: 'cheese', a: 'cornmeal', b: 'milk', d: 'butter', c: 'ge', v: 'запекайте в духовке', heatSec: 1200, dish_type: 'baking' }
];

for (const it of dairyCheeseDishes) {
  addED({
    id: it.id,
    title: it.title,
    dish_type: it.dish_type || 'breakfast',
    cuisine: it.c,
    time: 25,
    active: 15,
    verb: it.v,
    heatSec: it.heatSec !== undefined ? it.heatSec : 480,
    desc: `Аппетитное молочное или сырное блюдо «${it.title}» на каждый день.`,
    ings: [it.m, it.a, it.b, it.d, 'salt']
  });
}

console.log(`Total generated egg & dairy dishes: ${allEggDairy.length}`);
saveAndValidateGroup('egg_dairy.json', allEggDairy);
