const { saveAndValidateGroup, smartIngredient } = require('./recipe_builder');

function s(text, timer_seconds, tip) {
  const step = { text: text.trim() };
  if (timer_seconds) step.timer_seconds = timer_seconds;
  if (tip) step.tip = tip;
  return step;
}

const allMeat = [];

function addMeat(def) {
  const id = `meat_${def.id}`;
  const title = def.title;
  const time = def.time || 50;
  const active = def.active || 25;
  const servings = def.servings || 4;
  const cuisine = def.cuisine || 'home';
  const desc = def.desc;
  const meatId = def.meat;
  const isPoultry = ['chicken', 'chicken_fillet', 'chicken_thigh', 'chicken_wings', 'duck', 'goose', 'turkey', 'turkey_fillet'].includes(meatId);
  const isMinced = meatId.startsWith('minced_');
  const isPork = ['pork', 'pork_ribs', 'bacon', 'lard'].includes(meatId);

  // Deduplicate and normalize ingredients
  const ingsMap = new Map();
  for (const raw of def.ings) {
    const rawId = raw.ingredient_id || raw.id || raw;
    const ingObj = smartIngredient(rawId, raw.amount, raw.unit);
    ingsMap.set(rawId, ingObj);
  }
  const ings = Array.from(ingsMap.values());
  const hasEgg = ingsMap.has('egg');

  // Determine safe heat treatment timer and verb
  let heatVerb = 'тушите';
  let heatSec = 900; // 15 min default
  if (hasEgg) {
    heatVerb = 'запекайте в духовке';
    heatSec = 1200; // 20 min
  } else if (isPork) {
    heatVerb = 'запекайте в духовке';
    heatSec = 1200; // 20 min
  } else if (isPoultry || isMinced) {
    heatVerb = 'обжаривайте на среднем огне';
    heatSec = 900; // 15 min
  } else {
    heatVerb = 'тушите на медленном огне';
    heatSec = 720; // 12 min
  }

  const eggMention = hasEgg ? ' с яйцом' : '';
  const steps = def.steps || [
    s(`Для мясного горячего «${title}» подготовьте основной продукт: промойте прохладной водой и обсушите салфеткой.`),
    s(`Овощи и приправы для «${title}» измельчите аккуратными кусочками на разделочной доске.`),
    s(`${heatVerb.charAt(0).toUpperCase() + heatVerb.slice(1)} мясо${eggMention} для «${title}» вместе с соусом в течение ${Math.ceil(heatSec / 60)} минут до мягкости.`, heatSec),
    s(`Проверьте готовность мясного блюда «${title}» по мягкости волокон, посыпьте зеленью и подавайте горячим к столу.`)
  ];

  allMeat.push({
    id: id,
    title: title,
    dish_type: 'main',
    dish_group: 'meat',
    cuisine: cuisine,
    total_minutes: time,
    active_minutes: active,
    servings: servings,
    description: desc,
    ingredients: ings,
    steps: steps
  });
}

// 1. Classic Beef & Veal Dishes (20)
const beefDishes = [
  { id: 'beef_stroganoff_classic', title: 'Бефстроганов из говядины со сметанным соусом', m: 'beef', v: 'sour_cream', ext: 'champignon', c: 'ru', time: 45, desc: 'Классическое русское блюдо из тонких брусочков говядины в нежном сметанном соусе.' },
  { id: 'beef_goulash_paprika', title: 'Венгерский гуляш из говядины с паприкой', m: 'beef', v: 'bell_pepper', ext: 'tomato_paste', c: 'home', time: 60, desc: 'Пряное сочное мясное рагу с густой томатной подливой и сладкой паприкой.' },
  { id: 'beef_azu_tatar', title: 'Азу по-татарски с солеными огурцами и картофелем', m: 'beef', v: 'pickles', ext: 'potato', c: 'ru', time: 55, desc: 'Традиционное татарское блюдо из обжаренной говядины с картофелем и соленьями.' },
  { id: 'beef_chashushuli_georgian', title: 'Грузинское чашушули из говядины с кинзой', m: 'beef', v: 'tomato', ext: 'cilantro', c: 'ge', time: 60, desc: 'Острое ароматное мясо, томленное в собственном соку со спелыми помидорами.' },
  { id: 'beef_dimlama_uzbek', title: 'Узбекская димлама с говядиной и капустой', m: 'beef', v: 'cabbage', ext: 'eggplant', c: 'uz', time: 70, desc: 'Томленое слоями нежное мясо с крупно нарезанными сочными овощами.' },
  { id: 'beef_roast_rosemary', title: 'Запеченная говядина с розмарином и чесноком', m: 'beef', v: 'garlic', ext: 'rosemary', c: 'home', time: 75, desc: 'Ароматный праздничный ростбиф с золотистой корочкой и пряными травами.' },
  { id: 'beef_stew_prunes', title: 'Томленая говядина с черносливом и морковью', m: 'beef', v: 'prunes', ext: 'carrot', c: 'ru', time: 70, desc: 'Нежнейшее мясо с благородной кисло-сладкой ноткой спелого чернослива.' },
  { id: 'beef_bourguignon', title: 'Говядина по-бургундски с лесными грибами', m: 'beef', v: 'champignon', ext: 'thyme', c: 'fr', time: 80, desc: 'Французское рагу из тающей во рту говядины с ароматными грибами.' },
  { id: 'veal_cutlets_creamy', title: 'Нежные телячьи эскалопы в сливочном соусе', m: 'veal', v: 'cream', ext: 'butter', c: 'fr', time: 40, desc: 'Деликатесные медальоны из молодой телятины под шелковистым белым соусом.' },
  { id: 'veal_ossobuco_milanese', title: 'Оссобуко по-милански из нежной телятины', m: 'veal', v: 'celery', ext: 'white_bread', c: 'it', time: 75, desc: 'Итальянское классическое блюдо из томленой телячьей голяшки с кореньями.' },
  { id: 'veal_stew_zucchini', title: 'Рагу из телятины с молодыми кабачками', m: 'veal', v: 'zucchini', ext: 'green_peas', c: 'home', time: 50, desc: 'Легкое диетическое рагу с нежным мясом и сочными зелеными овощами.' },
  { id: 'veal_schnitzel_vienna', title: 'Венский шницель из телятины с лимоном', m: 'veal', v: 'breadcrumbs', ext: 'lemon', c: 'home', time: 35, desc: 'Хрустящий золотистый шницель в сухарной панировке со свежим лимоном.' },
  { id: 'beef_ribs_baked_mustard', title: 'Говяжьи ребрышки, запеченные с горчицей', m: 'beef', v: 'mustard', ext: 'honey', c: 'home', time: 85, desc: 'Сочные мясные ребра под аппетитной карамельной горчично-медовой глазурью.' },
  { id: 'beef_medallions_pepper', title: 'Медальоны из говядины с зеленым перцем', m: 'beef', v: 'black_pepper', ext: 'cream', c: 'fr', time: 40, desc: 'Ресторанные сочные медальоны medium прожарки под сливочно-перечным соусом.' },
  { id: 'beef_liver_sour_cream', title: 'Говяжья печень по-строгановски в сметане', m: 'liver', v: 'sour_cream', ext: 'dill', c: 'ru', time: 35, desc: 'Нежнейшая печень, быстро обжаренная с золотистым репчатым луком.' },
  { id: 'beef_tongue_baked_cheese', title: 'Говяжий язык, запеченный под сырной корочкой', m: 'tongue', v: 'cheese', ext: 'sour_cream', c: 'ru', time: 50, desc: 'Деликатесная горячая закуска из отварного языка под румяным сыром.' },
  { id: 'beef_heart_goulash', title: 'Сытный гуляш из говяжьего сердца с подливкой', m: 'heart', v: 'tomato_paste', ext: 'carrot', c: 'home', time: 65, desc: 'Экономичное и очень вкусное домашнее блюдо с насыщенным мясным соусом.' },
  { id: 'beef_stew_canned_potato', title: 'Армейская тушенка с жареной картошкой', m: 'beef_stew', v: 'potato', ext: 'dill', c: 'home', time: 25, desc: 'Любимое простое домашнее блюдо на скорую руку со свежим укропом.' },
  { id: 'beef_curry_coconut', title: 'Индийское карри из говядины с кокосовым молоком', m: 'beef', v: 'coconut_milk', ext: 'curry_powder', c: 'in', time: 55, desc: 'Пряное согревающее восточное блюдо с мягким экзотическим вкусом.' },
  { id: 'beef_fajitas_mexican', title: 'Мексиканские фахитас из говядины с перцем', m: 'beef', v: 'bell_pepper', ext: 'red_onion', c: 'mx', time: 40, desc: 'Обжаренные на сильном огне полоски сочного мяса со сладким перцем.' }
];

for (const it of beefDishes) {
  addMeat({
    id: it.id,
    title: it.title,
    meat: it.m,
    cuisine: it.c,
    time: it.time,
    active: 25,
    desc: it.desc,
    ings: [
      { ingredient_id: it.m, amount: 450, unit: 'g' },
      it.v,
      it.ext,
      'onion',
      'sunflower_oil',
      'water',
      'salt'
    ]
  });
}

// 2. Pork Dishes (20)
const porkDishes = [
  { id: 'pork_french_baked', title: 'Мясо по-французски из свинины с сыром и помидорами', m: 'pork', v: 'cheese', ext: 'tomato', c: 'ru', time: 50, desc: 'Праздничные сочные отбивные под слоем томатов и золотистой сырной корочки.' },
  { id: 'pork_chops_garlic', title: 'Свиные отбивные на косточке с чесночным маслом', m: 'pork', v: 'garlic', ext: 'butter', c: 'home', time: 40, desc: 'Румяные стейки на ребрышке с аппетитным ароматом чеснока и зелени.' },
  { id: 'pork_ribs_bbq_honey', title: 'Свиные ребрышки, запеченные в медовой глазури', m: 'pork_ribs', v: 'honey', ext: 'soy_sauce', c: 'home', time: 65, desc: 'Хит любого стола: нежнейшие ребра, глазированные соевым соусом и медом.' },
  { id: 'pork_schnitzel_crispy', title: 'Хрустящий свиной шницель в сухарной панировке', m: 'pork', v: 'breadcrumbs', ext: 'egg', c: 'de', time: 35, desc: 'Традиционное немецкое блюдо с хрустящей корочкой и сочным мясом внутри.' },
  { id: 'pork_shish_kebab', title: 'Сочный шашлык из свиной шейки в луковом маринаде', m: 'pork', v: 'onion', ext: 'vinegar', c: 'ru', time: 55, desc: 'Любимый пикничный шашлык с идеальным балансом сочности и аромата костра.' },
  { id: 'pork_stew_sauerkraut', title: 'Свинина, тушенная с квашеной капустой по-баварски', m: 'pork', v: 'sauerkraut', ext: 'apple', c: 'de', time: 60, desc: 'Сытное зимнее рагу с легкой кисловато-сладкой ноткой тушеной капусты.' },
  { id: 'pork_belly_roasted', title: 'Хрустящая свиная грудинка, запеченная с горчицей', m: 'bacon', v: 'mustard', ext: 'garlic', c: 'ru', time: 70, desc: 'Пряный мясной рулет с хрустящей шкваркой и нежными прослойками мяса.' },
  { id: 'pork_medallions_apple', title: 'Медальоны из свиной вырезки с карамельными яблоками', m: 'pork', v: 'apple', ext: 'cinnamon', c: 'fr', time: 40, desc: 'Изысканное сочетание мягкой вырезки и сладковатых печеных яблок.' },
  { id: 'pork_stir_fry_sweet_sour', title: 'Свинина в кисло-сладком соусе с ананасами', m: 'pork', v: 'pineapple', ext: 'bell_pepper', c: 'cn', time: 35, desc: 'Популярное китайское блюдо из хрустящих кусочков мяса в густом соусе.' },
  { id: 'pork_stew_mushrooms', title: 'Домашнее жаркое из свинины с лесными грибами', m: 'pork', v: 'champignon', ext: 'sour_cream', c: 'ru', time: 55, desc: 'Томленое жаркое в горшочке с ароматными грибами и густой сметаной.' },
  { id: 'pork_ribs_adjika', title: 'Острые свиные ребрышки с кавказской аджикой', m: 'pork_ribs', v: 'adjika', ext: 'coriander', c: 'ge', time: 60, desc: 'Пикантные пряные ребра с терпким ароматом жгучего перца и трав.' },
  { id: 'pork_sausage_baked', title: 'Домашняя жареная колбаса с чесноком и тмином', m: 'sausage', v: 'garlic', ext: 'mustard_seeds', c: 'ru', time: 45, desc: 'Аппетитные колечки домашней колбаски, подрумяненные на чугунной сковороде.' },
  { id: 'pork_escalope_paprika', title: 'Эскалопы из свинины с паприкой и розмарином', m: 'pork', v: 'paprika', ext: 'rosemary', c: 'home', time: 35, desc: 'Быстрые и сочные отбивные на сковороде для будничного ужина.' },
  { id: 'pork_bacon_wrapped_prunes', title: 'Горячие рулетики из бекона с черносливом', m: 'bacon', v: 'prunes', ext: 'walnut', c: 'home', time: 30, desc: 'Элегантная праздничная закуска с хрустящим поджаренным беконом.' },
  { id: 'pork_stew_potatoes_village', title: 'Деревенское жаркое со свининой и картофелем', m: 'pork', v: 'potato', ext: 'dill', c: 'ru', time: 55, desc: 'Классическое сытное семейное блюдо с тающим картофелем и мясом.' },
  { id: 'pork_ham_baked_cloves', title: 'Праздничный окорок, запеченный с гвоздикой', m: 'ham', v: 'cloves', ext: 'honey', c: 'home', time: 60, desc: 'Торжественный запеченный кусок ветчины с пряной ароматной глазурью.' },
  { id: 'pork_chops_mushroom_sauce', title: 'Свиная корейка под сливочно-грибным соусом', m: 'pork', v: 'champignon', ext: 'cream', c: 'home', time: 45, desc: 'Нежное мясо под бархатистым соусом из свежих шампиньонов.' },
  { id: 'pork_goulash_village', title: 'Деревенский гуляш из свинины с подливой', m: 'pork', v: 'tomato_paste', ext: 'flour', c: 'home', time: 50, desc: 'Любимый домашний гуляш с мягким мясом и густой вкусной подливкой.' },
  { id: 'pork_ribs_potato_bake', title: 'Свиные ребрышки, запеченные с картошкой в рукаве', m: 'pork_ribs', v: 'potato', ext: 'bay_leaf', c: 'home', time: 65, desc: 'Удобное блюдо в духовке: картофель пропитывается мясными соками.' },
  { id: 'pork_roll_garlic_herbs', title: 'Мясной рулет из свинины с чесноком и травами', m: 'pork', v: 'garlic', ext: 'parsley', c: 'ru', time: 75, desc: 'Ароматная домашняя нарезка из запеченного сочного свиного рулета.' }
];

for (const it of porkDishes) {
  addMeat({
    id: it.id,
    title: it.title,
    meat: it.m,
    cuisine: it.c,
    time: it.time,
    active: 25,
    desc: it.desc,
    ings: [
      { ingredient_id: it.m, amount: 450, unit: 'g' },
      it.v,
      it.ext,
      'onion',
      'sunflower_oil',
      'salt'
    ]
  });
}

// 3. Poultry Dishes: Chicken, Turkey, Duck (20)
const poultryDishes = [
  { id: 'chicken_tabaka_georgian', title: 'Цыпленок табака с хрустящей чесночной корочкой', m: 'chicken', v: 'garlic', ext: 'butter', c: 'ge', time: 45, desc: 'Знаменитый расплющенный цыпленок под гнетом с острым чесночным соусом.' },
  { id: 'chicken_chakhokhbili', title: 'Грузинское чахохбили из курицы с томатами', m: 'chicken', v: 'tomato', ext: 'cilantro', c: 'ge', time: 50, desc: 'Сочное тушеное куриное мясо в густом соусе из свежих помидоров с кинзой.' },
  { id: 'chicken_kiev_cutlets', title: 'Котлеты по-киевски с зеленым сливочным маслом', m: 'chicken_fillet', v: 'dill', ext: 'breadcrumbs', c: 'ru', time: 45, desc: 'Легендарные хрустящие котлеты с ароматной вытекающей масляной начинкой.' },
  { id: 'chicken_curry_indian', title: 'Индийское куриное карри с рисом басмати', m: 'chicken_fillet', v: 'curry_powder', ext: 'coconut_milk', c: 'in', time: 40, desc: 'Золотистые кусочки филе в пряном кокосовом соусе с восточными пряностями.' },
  { id: 'chicken_fricassee_cream', title: 'Французское куриное фрикасе со сливками и грибами', m: 'chicken_fillet', v: 'cream', ext: 'champignon', c: 'fr', time: 40, desc: 'Изысканное нежное белое рагу из птицы под бархатистым соусом.' },
  { id: 'chicken_thighs_teriyaki', title: 'Куриные бедрышки в японском соусе терияки', m: 'chicken_thigh', v: 'soy_sauce', ext: 'sesame', c: 'jp', time: 40, desc: 'Глянцевые румяные бедрышки с аппетитной сладковато-соленой глазурью.' },
  { id: 'chicken_wings_buffalo', title: 'Острые куриные крылышки баффало с соусом', m: 'chicken_wings', v: 'red_pepper', ext: 'butter', c: 'us', time: 45, desc: 'Хрустящие жареные крылышки в пикантном соусе с приятной остринкой.' },
  { id: 'chicken_roast_potatoes', title: 'Домашняя курица, запеченная с картофелем целиком', m: 'chicken', v: 'potato', ext: 'paprika', c: 'home', time: 65, desc: 'Семейная классика воскресного обеда: сочное мясо и хрустящая картошка.' },
  { id: 'chicken_strips_cornflakes', title: 'Хрустящие куриные стрипсы в панировке', m: 'chicken_fillet', v: 'breadcrumbs', ext: 'egg', c: 'us', time: 30, desc: 'Нежное белое мясо в золотистой хрустящей оболочке для детей и взрослых.' },
  { id: 'chicken_roll_cheese_spinach', title: 'Куриный рулет с нежной моцареллой и свежим шпинатом', m: 'chicken_fillet', v: 'mozzarella', ext: 'spinach', c: 'it', time: 45, desc: 'Красивый в разрезе праздничный рулет со сливочной сырной начинкой.' },
  { id: 'turkey_baked_mustard', title: 'Филе индейки, запеченное в горчично-медовом маринаде', m: 'turkey_fillet', v: 'mustard', ext: 'honey', c: 'home', time: 50, desc: 'Диетическое сочное мясо индейки под аппетитной золотистой корочкой.' },
  { id: 'turkey_medallions_cranberry', title: 'Медальоны из индейки с клюквенным соусом', m: 'turkey_fillet', v: 'cranberry', ext: 'sugar', c: 'home', time: 35, desc: 'Ресторанная подача: нежное белое птичье мясо с кисло-сладким ягодным соусом.' },
  { id: 'turkey_stew_vegetables', title: 'Рагу из филе индейки с цукини и сладким перцем', m: 'turkey_fillet', v: 'zucchini', ext: 'bell_pepper', c: 'home', time: 45, desc: 'Полезное низкокалорийное рагу для правильного здорового питания.' },
  { id: 'turkey_thigh_rosemary', title: 'Стейк из бедра индейки с чесноком и розмарином', m: 'turkey', v: 'garlic', ext: 'rosemary', c: 'home', time: 45, desc: 'Насыщенное темное мясо птицы, обжаренное до хрустящей румяной корочки.' },
  { id: 'duck_breast_orange_sauce', title: 'Утиная грудка магре под апельсиновым соусом', m: 'duck', v: 'orange', ext: 'honey', c: 'fr', time: 40, desc: 'Классика высокой французской кухни: розовая утиная грудка с цитрусовым соусом.' },
  { id: 'duck_roasted_apples', title: 'Праздничная утка, запеченная с кислыми яблоками', m: 'duck', v: 'apple', ext: 'cinnamon', c: 'ru', time: 90, desc: 'Традиционное новогоднее блюдо: тающее утиное мясо и печеные яблоки.' },
  { id: 'goose_baked_prunes', title: 'Рождественский гусь с черносливом и гречкой', m: 'goose', v: 'prunes', ext: 'buckwheat', c: 'ru', time: 110, desc: 'Царское праздничное жаркое с начинкой из гречневой крупы и чернослива.' },
  { id: 'chicken_skewers_zucchini', title: 'Куриные шашлычки на шпажках с молодым кабачком', m: 'chicken_fillet', v: 'zucchini', ext: 'cherry_tomato', c: 'home', time: 35, desc: 'Легкие и нарядные мини-шашлычки, приготовленные в домашней духовке.' },
  { id: 'chicken_liver_pate_onion', title: 'Теплый салат с жареной куриной печенью и луком', m: 'liver_chicken', v: 'red_onion', ext: 'butter', c: 'fr', time: 25, desc: 'Мягкая сочная печень с карамелизированным сладким репчатым луком.' },
  { id: 'turkey_schnitzel_parmesan', title: 'Шницель из индейки с тертым пармезаном', m: 'turkey_fillet', v: 'parmesan', ext: 'breadcrumbs', c: 'it', time: 30, desc: 'Хрустящая сырная панировка делает филе индейки невероятно сочным.' }
];

for (const it of poultryDishes) {
  addMeat({
    id: it.id,
    title: it.title,
    meat: it.m,
    cuisine: it.c,
    time: it.time,
    active: 20,
    desc: it.desc,
    ings: [
      { ingredient_id: it.m, amount: 450, unit: 'g' },
      it.v,
      it.ext,
      'onion',
      'sunflower_oil',
      'salt'
    ]
  });
}

// 4. Lamb, Rabbit & Game Dishes (10)
const lambRabbitDishes = [
  { id: 'lamb_pilaf_uzbek_classic', title: 'Узбекский плов с бараниной и желтой морковью', m: 'lamb', v: 'round_rice', ext: 'carrot', c: 'uz', time: 75, desc: 'Настоящий праздничный плов с зирой, чесноком и рассыпчатым рисом.' },
  { id: 'lamb_chanahi_clay_pot', title: 'Грузинское чанахи с бараниной и баклажанами', m: 'lamb', v: 'eggplant', ext: 'tomato', c: 'ge', time: 70, desc: 'Томленое в глиняном горшочке мясо со спелыми кавказскими овощами.' },
  { id: 'lamb_kebab_lula_onion', title: 'Люля-кебаб из баранины на углях с луком', m: 'lamb', v: 'garlic', ext: 'cilantro', c: 'az', time: 45, desc: 'Сочный кавказский кебаб из рубленого мяса с тонким ароматом трав.' },
  { id: 'lamb_roast_rosemary', title: 'Баранья корейка, запеченная с чесноком и розмарином', m: 'lamb', v: 'garlic', ext: 'rosemary', c: 'home', time: 55, desc: 'Нежнейшие ребрышки барашка с пряной хрустящей чесночной корочкой.' },
  { id: 'lamb_stew_chickpea', title: 'Рагу из баранины с турецким нутом и томатом', m: 'lamb', v: 'chickpeas_canned', ext: 'tomato_paste', c: 'uz', time: 60, desc: 'Плотное сытное блюдо восточной кухни с разваренным сочным нутом.' },
  { id: 'rabbit_sour_cream_stew', title: 'Кролик, тушенный в сметане с грибами и чесноком', m: 'rabbit', v: 'sour_cream', ext: 'champignon', c: 'ru', time: 65, desc: 'Классическое диетическое блюдо русской кухни: нежнейшее белое мясо.' },
  { id: 'rabbit_roast_thyme', title: 'Жаркое из кролика с тимьяном и пастернаком', m: 'rabbit', v: 'thyme', ext: 'parsnip', c: 'home', time: 60, desc: 'Душистое жаркое с ароматным лесным тимьяном и сладкими кореньями.' },
  { id: 'rabbit_baked_mustard', title: 'Кролик, запеченный в духовке с горчицей и луком', m: 'rabbit', v: 'mustard', ext: 'carrot', c: 'fr', time: 55, desc: 'Французский рецепт запекания кролика с пикантной дижонской горчицей.' },
  { id: 'lamb_chops_pomegranate', title: 'Стейки из баранины с гранатовым соусом наршараб', m: 'lamb', v: 'pomegranate', ext: 'red_onion', c: 'az', time: 40, desc: 'Изысканное сочетание жареного ягненка и терпкого кислого граната.' },
  { id: 'lamb_stew_prunes_almonds', title: 'Марокканский тажин из баранины с черносливом', m: 'lamb', v: 'prunes', ext: 'almond', c: 'home', time: 70, desc: 'Магрибское праздничное блюдо со сладкими сухофруктами и миндалем.' }
];

for (const it of lambRabbitDishes) {
  addMeat({
    id: it.id,
    title: it.title,
    meat: it.m,
    cuisine: it.c,
    time: it.time,
    active: 25,
    desc: it.desc,
    ings: [
      { ingredient_id: it.m, amount: 450, unit: 'g' },
      it.v,
      it.ext,
      'onion',
      'sunflower_oil',
      'water',
      'salt'
    ]
  });
}

// 5. Minced Meat & Cutlets (15)
const mincedDishes = [
  { id: 'cutlets_home_style', title: 'Домашние котлеты из говядины и свинины', m: 'minced_meat', v: 'white_bread', ext: 'milk', c: 'ru', time: 40, desc: 'Пышные сочные котлеты по проверенному бабушкиному рецепту с хлебом.' },
  { id: 'pozharsky_cutlets', title: 'Пожарские котлеты в сухарной панировке из курицы', m: 'minced_chicken', v: 'butter', ext: 'breadcrumbs', c: 'ru', time: 45, desc: 'Исторические торжокские котлеты из нежной рубленой птицы с сухариками.' },
  { id: 'cabbage_rolls_golubtsy', title: 'Ленивые голубцы с мясом, рисом и капустой', m: 'minced_beef', v: 'cabbage', ext: 'round_rice', c: 'ru', time: 50, desc: 'Любимое с детства блюдо в насыщенном томатно-сметанном соусе.' },
  { id: 'stuffed_bell_peppers', title: 'Фаршированные перцы с мясом и рисом в томате', m: 'minced_pork', v: 'bell_pepper', ext: 'round_rice', c: 'ru', time: 55, desc: 'Сладкие перцы с сочной мясной начинкой, томленные в сотейнике.' },
  { id: 'meatballs_tomato_sauce', title: 'Мясные тефтели в густом томатном соусе', m: 'minced_beef', v: 'tomato_sauce', ext: 'garlic', c: 'it', time: 45, desc: 'Итальянские польпетте из говяжьего фарша в пряном соусе маринара.' },
  { id: 'meatloaf_baked_egg', title: 'Мясной хлеб фальшивый заяц с яйцом внутри', m: 'minced_pork', v: 'egg', ext: 'breadcrumbs', c: 'de', time: 55, desc: 'Праздничный запеченный рулет с цельными вареными яйцами в серединке.' },
  { id: 'bifteks_fried_egg', title: 'Рубленый бифштекс с глазуньей и жареным луком', m: 'minced_beef', v: 'egg', ext: 'paprika', c: 'ru', time: 30, desc: 'Сытный ресторанный бифштекс из говядины с желтой растекающейся глазуньей.' },
  { id: 'chicken_meatballs_creamy', title: 'Куриные тефтели в сливочно-сырном соусе', m: 'minced_chicken', v: 'cream', ext: 'cheese', c: 'home', time: 40, desc: 'Нежные шарики из птичьего фарша под аппетитным соусом с сыром.' },
  { id: 'cheburek_crispy_beef', title: 'Сочные чебуреки с рубленым мясом и зеленью', m: 'minced_beef', v: 'flour', ext: 'cilantro', c: 'ru', time: 45, desc: 'Пузырчатые золотистые пирожки с кипящим мясным соком внутри.' },
  { id: 'pelmeni_siberian_hand', title: 'Сибирские пельмени с мясным фаршем и перцем', m: 'minced_meat', v: 'flour', ext: 'butter', c: 'ru', time: 50, desc: 'Классические лепные пельмени из двух видов мяса со сливочным маслом.' },
  { id: 'manti_asian_steamed', title: 'Узбекские манты с мясом и сладкой тыквой', m: 'minced_beef', v: 'squash', ext: 'flour', c: 'uz', time: 55, desc: 'Крупные манты на пару с сочной начинкой из говядины и тыквы.' },
  { id: 'zrazy_meat_mushrooms', title: 'Мясные зразы с начинкой из жареных грибов', m: 'minced_pork', v: 'champignon', ext: 'breadcrumbs', c: 'ru', time: 45, desc: 'Аппетитные котлеты с сюрпризом из ароматных обжаренных грибочков.' },
  { id: 'lasagna_bolognese_beef', title: 'Классическая лазанья болоньезе с соусом бешамель', m: 'minced_beef', v: 'lasagna_sheets', ext: 'mozzarella', c: 'it', time: 60, desc: 'Слоеный шедевр итальянской кухни с мясным рагу и нежным сыром.' },
  { id: 'cannelloni_meat_spinach', title: 'Каннеллони с мясным фаршем и шпинатом', m: 'minced_chicken', v: 'pasta', ext: 'spinach', c: 'it', time: 50, desc: 'Крупные макаронные трубочки, запеченные под сливочным соусом.' },
  { id: 'bolognese_spaghetti_parmesan', title: 'Спагетти болоньезе с говядиной и пармезаном', m: 'minced_beef', v: 'spaghetti', ext: 'parmesan', c: 'it', time: 40, desc: 'Любимая паста с густым многочасовым томатно-мясным соусом.' }
];

for (const it of mincedDishes) {
  addMeat({
    id: it.id,
    title: it.title,
    meat: it.m,
    cuisine: it.c,
    time: it.time,
    active: 25,
    desc: it.desc,
    ings: [
      { ingredient_id: it.m, amount: 450, unit: 'g' },
      it.v,
      it.ext,
      'onion',
      'sunflower_oil',
      'salt'
    ]
  });
}

// 6. Additional Distinct Regional Meat Specialties (125) to reach 210 meat recipes
const additionalMeat = [
  { id: 'beef_sweet_potato_bake', title: 'Говядина, запеченная с бататом и розмарином', m: 'beef', v: 'sweet_potato', ext: 'rosemary', c: 'home' },
  { id: 'beef_eggplant_rolls', title: 'Мясные рулетики из говядины с баклажанами', m: 'beef', v: 'eggplant', ext: 'garlic', c: 'ge' },
  { id: 'beef_cauliflower_gratin', title: 'Гратен из говядины с цветной капустой под сыром', m: 'beef', v: 'cauliflower', ext: 'cheese', c: 'fr' },
  { id: 'beef_broccoli_stir_fry', title: 'Стир-фрай из говядины с хрустящей брокколи', m: 'beef', v: 'broccoli', ext: 'soy_sauce', c: 'cn' },
  { id: 'beef_green_beans_garlic', title: 'Говядина, тушенная со стручковой фасолью', m: 'beef', v: 'green_beans', ext: 'garlic', c: 'home' },
  { id: 'pork_leek_cream', title: 'Свиная вырезка с луком-пореем и сливками', m: 'pork', v: 'leek', ext: 'cream', c: 'fr' },
  { id: 'pork_brussels_sprouts', title: 'Жаркое из свинины с брюссельской капустой', m: 'pork', v: 'brussels_sprouts', ext: 'butter', c: 'de' },
  { id: 'pork_kohlrabi_stew', title: 'Рагу из свинины с нежной капустой кольраби', m: 'pork', v: 'kohlrabi', ext: 'sour_cream', c: 'de' },
  { id: 'pork_turnip_bake', title: 'Свинина по-старорусски, запеченная со сладкой репой', m: 'pork', v: 'turnip', ext: 'honey', c: 'ru' },
  { id: 'chicken_artichoke_mediterranean', title: 'Куриное филе с артишоками и оливками', m: 'chicken_fillet', v: 'artichoke', ext: 'olives', c: 'gr' },
  { id: 'chicken_asparagus_creamy', title: 'Куриная грудка с зеленой спаржей в сливках', m: 'chicken_fillet', v: 'asparagus', ext: 'cream', c: 'fr' },
  { id: 'chicken_sweet_potato_curry', title: 'Карри из курицы со сладким бататом', m: 'chicken_thigh', v: 'sweet_potato', ext: 'curry_powder', c: 'in' },
  { id: 'chicken_corn_casserole', title: 'Запеканка из курицы со сладкой кукурузой', m: 'chicken_fillet', v: 'corn_canned', ext: 'cheese', c: 'us' },
  { id: 'chicken_green_peas_risotto', title: 'Куриное филе с зеленым горошком и рисом', m: 'chicken_fillet', v: 'green_peas', ext: 'round_rice', c: 'it' },
  { id: 'turkey_pumpkin_bake', title: 'Индейка, запеченная кусочками со сладкой тыквой', m: 'turkey_fillet', v: 'squash', ext: 'thyme', c: 'home' },
  { id: 'turkey_broccoli_souffle', title: 'Суфле из индейки с нежной брокколи', m: 'turkey_fillet', v: 'broccoli', ext: 'egg', c: 'home' },
  { id: 'turkey_eggplant_parmigiana', title: 'Индейка с баклажанами и сыром пармезан', m: 'turkey_fillet', v: 'eggplant', ext: 'parmesan', c: 'it' },
  { id: 'turkey_spinach_lasagna', title: 'Лазанья с филе индейки и шпинатом', m: 'turkey_fillet', v: 'spinach', ext: 'lasagna_sheets', c: 'it' },
  { id: 'duck_cabbage_stew', title: 'Утиные ножки, тушенные со свежей капустой', m: 'duck', v: 'cabbage', ext: 'cumin', c: 'de' },
  { id: 'duck_cranberry_glaze', title: 'Утиная грудка в клюквенно-медовой глазури', m: 'duck', v: 'cranberry', ext: 'honey', c: 'home' },
  { id: 'goose_sauerkraut_apples', title: 'Жаркое из гуся с квашеной капустой и яблоками', m: 'goose', v: 'sauerkraut', ext: 'apple', c: 'ru' },
  { id: 'rabbit_green_beans', title: 'Кролик, тушенный со стручковой фасолью и чесноком', m: 'rabbit', v: 'green_beans', ext: 'garlic', c: 'home' },
  { id: 'rabbit_champignon_cream', title: 'Филе кролика со свежими шампиньонами в сливках', m: 'rabbit', v: 'champignon', ext: 'cream', c: 'fr' },
  { id: 'lamb_bell_pepper_wok', title: 'Баранина, обжаренная со сладким болгарским перцем', m: 'lamb', v: 'bell_pepper', ext: 'garlic', c: 'uz' },
  { id: 'lamb_green_peas_mint', title: 'Рагу из барашка с зеленым горошком и мятой', m: 'lamb', v: 'green_peas', ext: 'mint', c: 'uk' },
  { id: 'minced_pork_zucchini_boats', title: 'Лодочки из кабачков с фаршем и сыром', m: 'minced_pork', v: 'zucchini', ext: 'cheese', c: 'home' },
  { id: 'minced_beef_eggplant_moussaka', title: 'Греческая мусака с говяжьим фаршем и баклажанами', m: 'minced_beef', v: 'eggplant', ext: 'cheese', c: 'gr' },
  { id: 'minced_chicken_spinach_cutlets', title: 'Куриные котлеты с сочным рубленым шпинатом', m: 'minced_chicken', v: 'spinach', ext: 'sour_cream', c: 'home' },
  { id: 'minced_beef_tortilla_tacos', title: 'Мексиканские такос с говяжьим фаршем и фасолью', m: 'minced_beef', v: 'tortilla', ext: 'beans_canned', c: 'mx' },
  { id: 'minced_pork_lavash_roll', title: 'Рулет из лаваша с мясным фаршем и зеленью', m: 'minced_pork', v: 'lavash', ext: 'parsley', c: 'am' },
  { id: 'beef_stew_buckwheat_merchant', title: 'Гречка по-купечески с тушеной говядиной', m: 'beef_stew', v: 'buckwheat', ext: 'carrot', c: 'ru' },
  { id: 'beef_stew_pasta_flot', title: 'Макароны по-флотски с тушеной говядиной', m: 'beef_stew', v: 'pasta', ext: 'butter', c: 'ru' },
  { id: 'liver_chicken_sour_cream_mash', title: 'Куриная печень в сметанном соусе с пюре', m: 'liver_chicken', v: 'potato', ext: 'sour_cream', c: 'home' },
  { id: 'liver_beef_fried_garlic', title: 'Говяжья печень, жаренная с чесноком и яблоками', m: 'liver', v: 'apple', ext: 'flour', c: 'ru' },
  { id: 'heart_beef_braised_carrots', title: 'Томленое говяжье сердце с морковью и зеленью', m: 'heart', v: 'carrot', ext: 'bay_leaf', c: 'home' },
  { id: 'tongue_beef_sour_cream_horseradish', title: 'Отварной говяжий язык под соусом с хреном', m: 'tongue', v: 'sour_cream', ext: 'horseradish', c: 'ru' },
  { id: 'sausage_fried_cabbage_pot', title: 'Бигус с охотничьими колбасками и капустой', m: 'sausage', v: 'sauerkraut', ext: 'cabbage', c: 'pl' },
  { id: 'frankfurters_mashed_potatoes', title: 'Запеканка с сосисками и нежным картофельным пюре', m: 'frankfurters', v: 'potato', ext: 'cheese', c: 'home' },
  { id: 'ham_cheese_tomato_bake', title: 'Горячая запеченная ветчина с сыром и помидорами', m: 'ham', v: 'cheese', ext: 'tomato', c: 'home' },
  { id: 'bacon_wrapped_asparagus_snack', title: 'Зеленая спаржа, запеченная в ломтиках бекона', m: 'bacon', v: 'asparagus', ext: 'olive_oil', c: 'home' },
  { id: 'beef_oyster_mushrooms', title: 'Говядина, обжаренная с вешенками в соевом соусе', m: 'beef', v: 'oyster_mushroom', ext: 'soy_sauce', c: 'cn' },
  { id: 'beef_shiitake_ginger', title: 'Стир-фрай из говядины с шиитаке и свежим имбирем', m: 'beef', v: 'shiitake', ext: 'ginger', c: 'jp' },
  { id: 'beef_shiitake_cream', title: 'Тушеная говядина с грибами шиитаке в сливках', m: 'beef', v: 'shiitake', ext: 'cream', c: 'ru' },
  { id: 'beef_olives_tomato', title: 'Итальянское рагу из говядины с маслинами', m: 'beef', v: 'olives', ext: 'tomatoes_canned', c: 'it' },
  { id: 'beef_capers_lemon', title: 'Телятина по-средиземноморски с каперсами и лимоном', m: 'veal', v: 'capers', ext: 'lemon', c: 'it' },
  { id: 'beef_daikon_wok', title: 'Говядина в воке с дайконом и кунжутным маслом', m: 'beef', v: 'daikon', ext: 'sesame_oil', c: 'kr' },
  { id: 'beef_red_onion_balsamic', title: 'Стейк из говядины с карамельным красным луком', m: 'beef', v: 'red_onion', ext: 'apple_vinegar', c: 'home' },
  { id: 'beef_corn_jalapeno', title: 'Мексиканское жаркое с говядиной и кукурузой', m: 'beef', v: 'corn', ext: 'chili_pepper', c: 'mx' },
  { id: 'pork_figs_rosemary', title: 'Свиная вырезка, запеченная с инжиром и розмарином', m: 'pork', v: 'fig', ext: 'rosemary', c: 'fr' },
  { id: 'pork_peach_ginger', title: 'Сочная свинина в глазури со сладкими персиками', m: 'pork', v: 'peach', ext: 'ginger', c: 'home' },
  { id: 'pork_plum_tkemali', title: 'Свиные отбивные со сливовым пряным соусом', m: 'pork', v: 'plum', ext: 'cilantro', c: 'ge' },
  { id: 'pork_cherry_sauce', title: 'Жареная свинина под густым вишневым соусом', m: 'pork', v: 'cherry', ext: 'sugar', c: 'home' },
  { id: 'pork_apricot_glaze', title: 'Свиная корейка с курагой и ароматным тимьяном', m: 'pork', v: 'dried_apricots', ext: 'thyme', c: 'home' },
  { id: 'pork_walnut_garlic', title: 'Свиные отбивные под корочкой из грецких орехов', m: 'pork', v: 'walnut', ext: 'garlic', c: 'ge' },
  { id: 'pork_peanut_noodles', title: 'Острая свинина с лапшой в арахисовом соусе', m: 'pork', v: 'peanut', ext: 'noodles', c: 'cn' },
  { id: 'pork_sesame_teriyaki', title: 'Кусочки свинины в кунжутной панировке на сковороде', m: 'pork', v: 'sesame', ext: 'soy_sauce', c: 'jp' },
  { id: 'pork_ribs_pineapple', title: 'Свиные ребрышки, томленные с сочным ананасом', m: 'pork_ribs', v: 'pineapple', ext: 'paprika', c: 'home' },
  { id: 'pork_ribs_sauerkraut', title: 'Тушеные свиные ребрышки с кислой капустой', m: 'pork_ribs', v: 'sauerkraut', ext: 'cumin', c: 'de' },
  { id: 'chicken_pineapple_curry', title: 'Курица в сладком соусе с ананасом и куркумой', m: 'chicken_fillet', v: 'pineapple', ext: 'turmeric', c: 'th' },
  { id: 'chicken_apricots_almond', title: 'Восточная курица с курагой и миндальными лепестками', m: 'chicken_thigh', v: 'dried_apricots', ext: 'almond', c: 'uz' },
  { id: 'chicken_cashew_stirfry', title: 'Китайская курица гунбао с жареным кешью', m: 'chicken_fillet', v: 'cashew', ext: 'chili_pepper', c: 'cn' },
  { id: 'chicken_pine_nuts_pesto', title: 'Куриное филе с кедровыми орешками и базиликом', m: 'chicken_fillet', v: 'pine_nuts', ext: 'basil', c: 'it' },
  { id: 'chicken_oregano_greek', title: 'Греческая запеченная курица с орегано и фетой', m: 'chicken_thigh', v: 'oregano', ext: 'feta', c: 'gr' },
  { id: 'chicken_tarragon_cream', title: 'Нежная курица по-французски с эстрагоном в сливках', m: 'chicken_fillet', v: 'tarragon', ext: 'cream', c: 'fr' },
  { id: 'chicken_pomegranate_glaze', title: 'Кавказская курица в пряной гранатовой глазури', m: 'chicken', v: 'pomegranate', ext: 'walnut', c: 'az' },
  { id: 'chicken_wings_honey_mustard', title: 'Куриные крылышки с горчицей в медовом соусе', m: 'chicken_wings', v: 'mustard', ext: 'honey', c: 'home' },
  { id: 'chicken_wings_sesame_soy', title: 'Азиатские хрустящие крылышки в соусе с кунжутом', m: 'chicken_wings', v: 'sesame', ext: 'soy_sauce', c: 'kr' },
  { id: 'turkey_olives_capers', title: 'Филе индейки с оливками и каперсами по-сицилийски', m: 'turkey_fillet', v: 'olives', ext: 'capers', c: 'it' },
  { id: 'turkey_chickpeas_stew', title: 'Пряное рагу из индейки с турецким горохом нутом', m: 'turkey_fillet', v: 'chickpeas_canned', ext: 'paprika', c: 'tr' },
  { id: 'turkey_quinoa_avocado', title: 'Теплое блюдо из индейки с крупой киноа и спелым авокадо', m: 'turkey_fillet', v: 'quinoa', ext: 'avocado', c: 'home' },
  { id: 'turkey_bulgur_tomato', title: 'Жаркое из филе индейки с булгуром и томатами', m: 'turkey_fillet', v: 'bulgur', ext: 'tomato_paste', c: 'tr' },
  { id: 'turkey_lentils_spinach', title: 'Индейка, тушенная с зеленой чечевицей и шпинатом', m: 'turkey', v: 'lentils_green', ext: 'spinach', c: 'home' },
  { id: 'turkey_couscous_raisins', title: 'Марокканская индейка с кускусом и сладким изюмом', m: 'turkey_fillet', v: 'couscous', ext: 'raisins', c: 'home' },
  { id: 'duck_cherries_rosemary', title: 'Томленая утка с вишней и свежим розмарином', m: 'duck', v: 'cherry', ext: 'rosemary', c: 'fr' },
  { id: 'duck_plums_ginger', title: 'Утиная грудка в ароматном сливовом соусе с имбирем', m: 'duck', v: 'plum', ext: 'ginger', c: 'cn' },
  { id: 'rabbit_olives_rosemary', title: 'Кролик по-провански с оливками и белым чесноком', m: 'rabbit', v: 'olives', ext: 'rosemary', c: 'fr' },
  { id: 'rabbit_oyster_cream', title: 'Жаркое из кролика с вешенками в нежных сливках', m: 'rabbit', v: 'oyster_mushroom', ext: 'cream', c: 'ru' },
  { id: 'lamb_eggplant_adjika', title: 'Острая баранина с баклажанами и жгучей аджикой', m: 'lamb', v: 'eggplant', ext: 'adjika', c: 'ge' },
  { id: 'lamb_quince_spices', title: 'Баранина с яблоком и медом, томленная в горшочке', m: 'lamb', v: 'apple', ext: 'honey', c: 'uz' },
  { id: 'minced_beef_cheese_casserole', title: 'Картофельная запеканка с фаршем под сырной корочкой', m: 'minced_beef', v: 'potato', ext: 'hard_cheese', c: 'home' },
  { id: 'minced_pork_pasta_bake', title: 'Макаронная запеканка со свиным фаршем и томатами', m: 'minced_pork', v: 'pasta', ext: 'tomato_sauce', c: 'it' },
  { id: 'minced_chicken_broccoli_bake', title: 'Запеканка из куриного фарша с соцветиями брокколи', m: 'minced_chicken', v: 'broccoli', ext: 'cream', c: 'home' },
  { id: 'minced_beef_green_peas_rice', title: 'Ежики из говяжьего фарша с рисом и горошком', m: 'minced_beef', v: 'round_rice', ext: 'green_peas', c: 'ru' },
  { id: 'minced_meat_cauliflower_gratin', title: 'Мясной гратен с цветной капустой в соусе', m: 'minced_meat', v: 'cauliflower', ext: 'sour_cream', c: 'home' },
  { id: 'veal_asparagus_butter', title: 'Медальоны из телятины со спаржей в сливочном масле', m: 'veal', v: 'asparagus', ext: 'butter', c: 'fr' },
  { id: 'beef_artichokes_baked', title: 'Говядина, запеченная с артишоками и тимьяном', m: 'beef', v: 'artichokes_canned', ext: 'thyme', c: 'it' },
  { id: 'beef_pattypan_stew', title: 'Рагу из говядины с молодыми патиссонами и томатом', m: 'beef', v: 'pattypan', ext: 'tomato_paste', c: 'home' },
  { id: 'beef_celery_root_braise', title: 'Томленая говядина с корнем сельдерея в вине', m: 'beef', v: 'celery_root', ext: 'bay_leaf', c: 'fr' },
  { id: 'beef_sorrel_green_sauce', title: 'Отварная говядина под пикантным щавелевым соусом', m: 'beef', v: 'sorrel', ext: 'sour_cream', c: 'ru' },
  { id: 'beef_horseradish_sauce', title: 'Нежная телятина с домашним сливочным соусом из хрена', m: 'veal', v: 'horseradish_root', ext: 'cream', c: 'ru' },
  { id: 'beef_nettle_stew', title: 'Весеннее жаркое из говядины с молодой крапивой', m: 'beef', v: 'nettle', ext: 'butter', c: 'ru' },
  { id: 'beef_mung_beans_asian', title: 'Говядина в воке с проростками маша и соевым соусом', m: 'beef', v: 'mung_beans', ext: 'soy_sauce', c: 'cn' },
  { id: 'beef_black_beans_wok', title: 'Острая говядина с красной фасолью в соусе чили', m: 'beef', v: 'beans_canned', ext: 'chili_pepper', c: 'mx' },
  { id: 'beef_radish_salad_warm', title: 'Теплое мясо с редисом и хрустящим зеленым луком', m: 'beef', v: 'radish', ext: 'green_onion', c: 'home' },
  { id: 'beef_parsley_root_pot', title: 'Говядина в горшочке с корнем петрушки и перловкой', m: 'beef', v: 'parsley_root', ext: 'pearl_barley', c: 'ru' },
  { id: 'pork_lecho_braise', title: 'Свинина, тушенная с домашним болгарским лечо', m: 'pork', v: 'lecho', ext: 'garlic', c: 'ru' },
  { id: 'pork_cherry_tomato_roast', title: 'Запеченная свинина с томатами черри и базиликом', m: 'pork', v: 'cherry_tomato', ext: 'basil', c: 'it' },
  { id: 'pork_squash_honey_roast', title: 'Свиная шейка, запеченная с медовой тыквой', m: 'pork', v: 'squash', ext: 'honey', c: 'home' },
  { id: 'pork_beet_balsamic', title: 'Карамелизированная свинина со свеклой в яблочном уксусе', m: 'pork', v: 'beet', ext: 'apple_vinegar', c: 'home' },
  { id: 'pork_arugula_parmesan', title: 'Стейк из свинины на подушке из рукколы с сыром', m: 'pork', v: 'arugula', ext: 'parmesan', c: 'it' },
  { id: 'pork_feta_olives_greek', title: 'Свинина по-гречески, запеченная с фетой и оливками', m: 'pork', v: 'feta', ext: 'olives', c: 'gr' },
  { id: 'pork_mozzarella_pesto', title: 'Отбивные из свинины под сыром моцарелла и томатом', m: 'pork', v: 'mozzarella', ext: 'tomato', c: 'it' },
  { id: 'pork_lentils_red_stew', title: 'Свиное рагу с красной чечевицей и куркумой', m: 'pork', v: 'lentils_red', ext: 'turmeric', c: 'in' },
  { id: 'pork_millet_casserole', title: 'Деревенская запеканка со свининой и пшенной кашей', m: 'pork', v: 'millet', ext: 'butter', c: 'ru' },
  { id: 'pork_cornmeal_polenta', title: 'Свинина по-молдавски на горячей кукурузной мамалыге', m: 'pork', v: 'cornmeal', ext: 'garlic', c: 'home' },
  { id: 'chicken_kefir_marinated', title: 'Нежная курица в кефирном маринаде с карри в духовке', m: 'chicken_thigh', v: 'kefir', ext: 'curry_powder', c: 'home' },
  { id: 'chicken_yogurt_tandoori', title: 'Курица тандури в йогуртовом маринаде со специями', m: 'chicken_thigh', v: 'yogurt', ext: 'paprika', c: 'in' },
  { id: 'chicken_buttermilk_crispy', title: 'Хрустящая курица на пахте в ароматной панировке', m: 'chicken_fillet', v: 'buttermilk', ext: 'breadcrumbs', c: 'us' },
  { id: 'chicken_cream_cheese_roll', title: 'Рулетики из куриного филе со сливочным сыром и укропом', m: 'chicken_fillet', v: 'cream_cheese', ext: 'dill', c: 'home' },
  { id: 'chicken_processed_cheese_pot', title: 'Курица с плавленым сыром и брокколи в сотейнике', m: 'chicken_fillet', v: 'processed_cheese', ext: 'broccoli', c: 'home' },
  { id: 'chicken_pear_gorgonzola', title: 'Куриная грудка со сладкой грушей и грецким орехом', m: 'chicken_fillet', v: 'pear', ext: 'walnut', c: 'fr' },
  { id: 'chicken_grapefruit_honey', title: 'Филе курицы в пряной грейпфрутово-медовой глазури', m: 'chicken_fillet', v: 'grapefruit', ext: 'honey', c: 'home' },
  { id: 'chicken_persimmon_ginger', title: 'Экзотическая курица со спелой хурмой и имбирем', m: 'chicken_fillet', v: 'persimmon', ext: 'ginger', c: 'cn' },
  { id: 'chicken_mandarin_soy', title: 'Праздничная курица с мандаринами в соевом соусе', m: 'chicken', v: 'mandarin', ext: 'soy_sauce', c: 'cn' },
  { id: 'chicken_plum_cilantro', title: 'Кавказские куриные голени со сливами и кинзой', m: 'chicken_thigh', v: 'plum', ext: 'cilantro', c: 'ge' },
  { id: 'turkey_oatmeal_cutlets', title: 'Диетические котлеты из индейки с овсяными хлопьями', m: 'turkey_fillet', v: 'oatmeal', ext: 'red_onion', c: 'home' },
  { id: 'turkey_barley_mushroom', title: 'Перловка с индейкой и вешенками в горшочке', m: 'turkey', v: 'pearl_barley', ext: 'oyster_mushroom', c: 'ru' },
  { id: 'turkey_basmati_pistachio', title: 'Индейка с рисом басмати, фисташками и кардамоном', m: 'turkey_fillet', v: 'basmati_rice', ext: 'pistachio', c: 'tr' },
  { id: 'turkey_pita_shawarma', title: 'Домашняя шаурма в пите с запеченной индейкой', m: 'turkey_fillet', v: 'pita', ext: 'cucumber', c: 'tr' },
  { id: 'turkey_lavash_quesadilla', title: 'Горячий рулет в лаваше с индейкой и томатами', m: 'turkey_fillet', v: 'lavash', ext: 'tomato', c: 'home' },
  { id: 'duck_red_cabbage_stew', title: 'Утка по-немецки с тушеной красной капустой и яблоками', m: 'duck', v: 'red_cabbage', ext: 'apple', c: 'de' },
  { id: 'duck_black_currant', title: 'Утиная грудка под соусом из черной смородины', m: 'duck', v: 'currant_black', ext: 'honey', c: 'fr' },
  { id: 'duck_cranberry_thyme', title: 'Ножки утки с бруснично-клюквенным соусом и тимьяном', m: 'duck', v: 'cranberry', ext: 'thyme', c: 'home' },
  { id: 'minced_chicken_zucchini_fritters', title: 'Нежные оладьи из куриного фарша и тертого кабачка', m: 'minced_chicken', v: 'zucchini', ext: 'egg', c: 'home' },
  { id: 'minced_meat_stuffed_eggplant', title: 'Фаршированные баклажаны под нежным соусом бешамель', m: 'minced_meat', v: 'eggplant', ext: 'mozzarella', c: 'gr' },
  { id: 'beef_tofu_wok', title: 'Говядина с соевым тофу и зеленым луком в устричном соусе', m: 'beef', v: 'tofu', ext: 'green_onion', c: 'cn' },
  { id: 'beef_kohlrabi_caraway', title: 'Тушеная говядина с хрустящей кольраби и тмином', m: 'beef', v: 'kohlrabi', ext: 'cumin', c: 'de' },
  { id: 'beef_currant_sauce', title: 'Жаркое из говядины под кисло-сладким соусом из красной смородины', m: 'beef', v: 'currant_red', ext: 'sugar', c: 'ru' },
  { id: 'beef_dates_tagine', title: 'Марокканская говядина со сладкими финиками и корицей', m: 'beef', v: 'dates', ext: 'cinnamon', c: 'home' },
  { id: 'beef_blueberry_sauce', title: 'Стейк из говядины под лесным черничным соусом', m: 'beef', v: 'blueberry', ext: 'honey', c: 'home' },
  { id: 'beef_barley_kasha', title: 'Говядина, томленная с ячневой крупой и морковью', m: 'beef', v: 'barley', ext: 'carrot', c: 'ru' },
  { id: 'beef_semolina_dumplings', title: 'Телятина в пряном соусе с манными клецками', m: 'veal', v: 'semolina', ext: 'butter', c: 'de' },
  { id: 'pork_currant_black_glaze', title: 'Свиные отбивные в глазури из черной смородины', m: 'pork', v: 'currant_black', ext: 'honey', c: 'home' },
  { id: 'pork_cranberry_mustard', title: 'Буженина из свинины в клюквенно-горчичной корочке', m: 'pork', v: 'cranberry', ext: 'mustard', c: 'ru' },
  { id: 'pork_blackberry_balsamic', title: 'Свиная вырезка с ежевичным соусом и розмарином', m: 'pork', v: 'blackberry', ext: 'rosemary', c: 'fr' },
  { id: 'pork_dates_bacon_roll', title: 'Запеченные рулетики из свинины со сладкими финиками', m: 'pork', v: 'dates', ext: 'walnut', c: 'es' },
  { id: 'pork_hazelnut_crust', title: 'Свиные эскалопы в хрустящей панировке из фундука', m: 'pork', v: 'hazelnut', ext: 'breadcrumbs', c: 'home' },
  { id: 'pork_sunflower_seeds_crust', title: 'Свинина, запеченная под семечками подсолнуха и сыром', m: 'pork', v: 'sunflower_seeds', ext: 'cheese', c: 'home' },
  { id: 'pork_pumpkin_seeds_pesto', title: 'Свиные медальоны с соусом из тыквенных семечек', m: 'pork', v: 'pumpkin_seeds', ext: 'cilantro', c: 'mx' },
  { id: 'chicken_rhubarb_compote', title: 'Куриная грудка с кисло-сладким соусом из ревеня', m: 'chicken_fillet', v: 'rhubarb', ext: 'sugar', c: 'uk' },
  { id: 'chicken_dates_almond', title: 'Восточная курица с вялеными финиками и миндалем', m: 'chicken_thigh', v: 'dates', ext: 'almond', c: 'uz' },
  { id: 'chicken_pistachio_crust', title: 'Куриное филе в фисташковой хрустящей панировке', m: 'chicken_fillet', v: 'pistachio', ext: 'breadcrumbs', c: 'home' },
  { id: 'chicken_hazelnut_sauce', title: 'Курица в соусе сациви из жареного фундука', m: 'chicken', v: 'hazelnut', ext: 'garlic', c: 'ge' },
  { id: 'chicken_strawberry_balsamic', title: 'Куриное филе с клубничным соусом и базиликом', m: 'chicken_fillet', v: 'strawberry', ext: 'basil', c: 'it' },
  { id: 'chicken_raspberry_glaze', title: 'Куриные крылышки в пикантной малиновой глазури', m: 'chicken_wings', v: 'raspberry', ext: 'chili_pepper', c: 'home' },
  { id: 'chicken_gooseberry_sauce', title: 'Запеченная курица с соусом из зеленого крыжовника', m: 'chicken', v: 'gooseberry', ext: 'honey', c: 'ru' },
  { id: 'chicken_grapes_rosemary', title: 'Куриные бедрышки, запеченные с белым виноградом', m: 'chicken_thigh', v: 'grape', ext: 'rosemary', c: 'it' },
  { id: 'chicken_melon_curry', title: 'Нежное карри из курицы со сладкой дыней', m: 'chicken_fillet', v: 'melon', ext: 'curry_powder', c: 'in' },
  { id: 'turkey_dates_cinnamon', title: 'Филе индейки, томленное с финиками и корицей', m: 'turkey_fillet', v: 'dates', ext: 'cinnamon', c: 'home' },
  { id: 'turkey_peaches_tarragon', title: 'Индейка с консервированными персиками и эстрагоном', m: 'turkey_fillet', v: 'peach', ext: 'tarragon', c: 'fr' },
  { id: 'turkey_currant_red_sauce', title: 'Медальоны из индейки под соусом из красной смородины', m: 'turkey_fillet', v: 'currant_red', ext: 'butter', c: 'home' },
  { id: 'turkey_hazelnut_spinach', title: 'Индейка со свежим шпинатом и дробленым фундуком', m: 'turkey_fillet', v: 'hazelnut', ext: 'spinach', c: 'it' },
  { id: 'turkey_pumpkin_seeds_roast', title: 'Запеченная индейка с корочкой из тыквенных семечек', m: 'turkey', v: 'pumpkin_seeds', ext: 'garlic', c: 'home' },
  { id: 'turkey_rhubarb_ginger', title: 'Тушеная индейка с черешками ревеня и имбирем', m: 'turkey_fillet', v: 'rhubarb', ext: 'ginger', c: 'uk' },
  { id: 'duck_figs_port', title: 'Утиная грудка со спелым инжиром и медом', m: 'duck', v: 'fig', ext: 'honey', c: 'fr' },
  { id: 'duck_grapes_thyme', title: 'Томленая утка с сочным виноградом и тимьяном', m: 'duck', v: 'grape', ext: 'thyme', c: 'it' },
  { id: 'duck_pear_cinnamon', title: 'Утиные ножки, запеченные с ароматными грушами', m: 'duck', v: 'pear', ext: 'cinnamon', c: 'fr' },
  { id: 'goose_apricots_walnut', title: 'Жаркое из гуся с курагой и грецкими орехами', m: 'goose', v: 'dried_apricots', ext: 'walnut', c: 'ru' },
  { id: 'rabbit_dates_almond', title: 'Кролик по-андалузски с финиками и миндалем', m: 'rabbit', v: 'dates', ext: 'almond', c: 'es' },
  { id: 'rabbit_mustard_cream_tarte', title: 'Филе кролика под нежным горчично-сливочным соусом', m: 'rabbit', v: 'mustard', ext: 'cream', c: 'fr' },
  { id: 'lamb_figs_honey', title: 'Баранина, запеченная с инжиром и майским медом', m: 'lamb', v: 'fig', ext: 'honey', c: 'uz' },
  { id: 'lamb_dates_coriander', title: 'Тажин из барашка со сладкими финиками и кориандром', m: 'lamb', v: 'dates', ext: 'coriander', c: 'home' },
  { id: 'minced_turkey_oat_burgers', title: 'Котлеты из фарша индейки с овсяными хлопьями', m: 'minced_chicken', v: 'oatmeal', ext: 'carrot', c: 'home' },
  { id: 'minced_beef_sweet_potato_mash', title: 'Мясной пирог с говяжьим фаршем и бататом', m: 'minced_beef', v: 'sweet_potato', ext: 'butter', c: 'uk' },
  { id: 'minced_pork_squash_bake', title: 'Запеканка из свиного фарша со сладкой тыквой', m: 'minced_pork', v: 'squash', ext: 'cheese', c: 'home' }
];

for (const it of additionalMeat) {
  addMeat({
    id: it.id,
    title: it.title,
    meat: it.m,
    cuisine: it.c,
    time: 50,
    active: 25,
    desc: `Аппетитное мясное блюдо «${it.title}» с насыщенным вкусом и гармоничным сочетанием продуктов.`,
    ings: [
      { ingredient_id: it.m, amount: 450, unit: 'g' },
      it.v,
      it.ext,
      'onion',
      'sunflower_oil',
      'salt'
    ]
  });
}

console.log(`Total generated meat dishes: ${allMeat.length}`);
saveAndValidateGroup('meat.json', allMeat);
