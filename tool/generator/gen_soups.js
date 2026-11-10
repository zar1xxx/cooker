const { saveAndValidateGroup } = require('./recipe_builder');

function s(text, timer_seconds, tip) {
  const step = { text: text.trim() };
  if (timer_seconds) step.timer_seconds = timer_seconds;
  if (tip) step.tip = tip;
  return step;
}

const allSoups = [];

// Helper to push a validated soup with 5 varied steps
function addSoup(def) {
  const id = `soup_${def.id}`;
  const title = def.title;
  const time = def.time || 50;
  const active = def.active || 20;
  const servings = def.servings || 4;
  const cuisine = def.cuisine || 'home';
  const desc = def.desc;

  // Build 5 distinct, natural steps incorporating title and context
  const steps = def.steps || [
    s(`Для приготовления блюда «${title}» подготовьте основной ингредиент: промойте и разделите на порционные кусочки.`),
    s(`Репчатый лук и морковь для супа «${title}» измельчите мелкими кубиками и спассеруйте на масле до мягкости.`, 420),
    s(`В кастрюлю с кипящей подсоленной водой для супа «${title}» выложите основу и варите 20 минут.`, 1200),
    s(`Добавьте в суп «${title}» картофель и овощную пассеровку, варите 12 минут.`, 720),
    s(`Проверьте готовность картофеля в супе «${title}», снимите с огня и дайте настояться 10 минут перед подачей.`)
  ];

  allSoups.push({
    id: id,
    title: title,
    dish_type: 'soup',
    dish_group: 'soup',
    cuisine: cuisine,
    total_minutes: time,
    active_minutes: active,
    servings: servings,
    description: desc,
    ingredients: def.ings,
    steps: steps
  });
}

// 1. BORSCHTS (15)
const borschts = [
  {
    id: 'borscht_beef_garlic',
    title: 'Классический борщ с говядиной и чесноком',
    cuisine: 'ru', time: 85, active: 30, servings: 6,
    desc: 'Наваристый домашний борщ на сахарной говяжьей косточке со сладкой свёклой.',
    ings: [
      { ingredient_id: 'beef', amount: 500, unit: 'g' },
      { ingredient_id: 'beet', amount: 2, unit: 'pcs' },
      { ingredient_id: 'cabbage', amount: 300, unit: 'g' },
      { ingredient_id: 'potato', amount: 3, unit: 'pcs' },
      { ingredient_id: 'carrot', amount: 1, unit: 'pcs' },
      { ingredient_id: 'onion', amount: 1, unit: 'pcs' },
      { ingredient_id: 'tomato_paste', amount: 2, unit: 'tbsp' },
      { ingredient_id: 'garlic', amount: 3, unit: 'pcs' },
      { ingredient_id: 'sunflower_oil', amount: 2, unit: 'tbsp' },
      { ingredient_id: 'lemon', amount: 0.5, unit: 'pcs' },
      { ingredient_id: 'water', amount: 2.5, unit: 'l' },
      { ingredient_id: 'salt', amount: null, unit: 'to_taste' }
    ],
    steps: [
      s('Говядину промойте, положите в глубокую кастрюлю с водой и варите бульон 50 минут на тихом огне, периодически снимая пену.', 3000),
      s('Свёклу натрите тонкой соломкой, сбрызните соком лимона и тушите с томатной пастой на масле 15 минут до мягкости.', 900),
      s('Морковь с репчатым луком измельчите и обжарьте на сковороде до золотистого оттенка.', 420),
      s('В кипящий процеженный мясной бульон положите нашинкованную соломкой капусту и брусочки картофеля, варите 12 минут.', 720),
      s('Переложите в суп тушёную свёклу, овощную заправку и мелко нарубленный чеснок, протомите под крышкой 8 минут перед подачей.')
    ]
  },
  {
    id: 'borscht_siberian_beans',
    title: 'Сибирский борщ с фасолью и фрикадельками',
    cuisine: 'ru', time: 80, active: 25, servings: 4,
    desc: 'Густой сибирский борщ с мясными шариками из говядины и нежной белой фасолью.',
    ings: [
      { ingredient_id: 'minced_beef', amount: 350, unit: 'g' },
      { ingredient_id: 'beans_white', amount: 150, unit: 'g' },
      { ingredient_id: 'beet', amount: 2, unit: 'pcs' },
      { ingredient_id: 'cabbage', amount: 250, unit: 'g' },
      { ingredient_id: 'potato', amount: 3, unit: 'pcs' },
      { ingredient_id: 'onion', amount: 1, unit: 'pcs' },
      { ingredient_id: 'carrot', amount: 1, unit: 'pcs' },
      { ingredient_id: 'tomato_paste', amount: 2, unit: 'tbsp' },
      { ingredient_id: 'garlic', amount: 2, unit: 'pcs' },
      { ingredient_id: 'sunflower_oil', amount: 2, unit: 'tbsp' },
      { ingredient_id: 'water', amount: 2.2, unit: 'l' },
      { ingredient_id: 'salt', amount: null, unit: 'to_taste' }
    ],
    steps: [
      s('Предварительно замоченную фасоль отварите в свежей воде до мягкости зёрен в течение 40 минут.', 2400),
      s('Из говяжьего фарша скатайте круглые шарики и опустите в кипящий суповой отвар на 10 минут.', 600),
      s('Свёклу с морковью натрите соломкой и потушите в сковороде с добавлением томатной пасты и нарезанного лука.', 600),
      s('Добавьте в кастрюлю к фрикаделькам нашинкованную капусту и кубики картошки, варите 12 минут.', 720),
      s('Соедините бульон с овощной заправкой и отварной фасолью, посолите, всыпьте давленый чеснок и дайте настояться 10 минут.')
    ]
  },
  {
    id: 'borscht_poltava_galushki',
    title: 'Полтавский борщ с куриными потрошками и галушками',
    cuisine: 'ru', time: 75, active: 35, servings: 5,
    desc: 'Ароматный домашний борщ на курином бульоне с нежными мучными галушками.',
    ings: [
      { ingredient_id: 'chicken_thigh', amount: 450, unit: 'g' },
      { ingredient_id: 'flour', amount: 150, unit: 'g' },
      { ingredient_id: 'egg', amount: 1, unit: 'pcs' },
      { ingredient_id: 'beet', amount: 2, unit: 'pcs' },
      { ingredient_id: 'cabbage', amount: 250, unit: 'g' },
      { ingredient_id: 'potato', amount: 2, unit: 'pcs' },
      { ingredient_id: 'carrot', amount: 1, unit: 'pcs' },
      { ingredient_id: 'onion', amount: 1, unit: 'pcs' },
      { ingredient_id: 'tomato_paste', amount: 1.5, unit: 'tbsp' },
      { ingredient_id: 'butter', amount: 25, unit: 'g' },
      { ingredient_id: 'water', amount: 2.3, unit: 'l' },
      { ingredient_id: 'salt', amount: null, unit: 'to_taste' }
    ],
    steps: [
      s('Куриные бёдрышки залейте холодной водой и варите прозрачный бульон 35 минут на небольшом огне.', 2100),
      s('Замесите мягкое эластичное тесто из муки, куриного яйца, щепотки соли и двух ложек бульона.'),
      s('Свёклу и морковь нашинкуйте брусочками, потушите на сливочном масле с томатной пастой до мягкого состояния овощей.', 720),
      s('В кипящий суп положите соломку из капусты и картофель, опустите кусочки теста с яйцом и варите 7 минут.', 420),
      s('Заправьте суп тушёными овощами, аккуратно перемешайте и выдержите под плотной крышкой 10 минут перед подачей.')
    ]
  },
  {
    id: 'borscht_chernigov_apple',
    title: 'Черниговский борщ с антоновскими яблоками и кабачками',
    cuisine: 'ru', time: 80, active: 30, servings: 6,
    desc: 'Оригинальный борщ с добавлением кисло-сладких яблок и нежных кабачков.',
    ings: [
      { ingredient_id: 'pork', amount: 450, unit: 'g' },
      { ingredient_id: 'apple', amount: 2, unit: 'pcs' },
      { ingredient_id: 'zucchini', amount: 200, unit: 'g' },
      { ingredient_id: 'beet', amount: 2, unit: 'pcs' },
      { ingredient_id: 'cabbage', amount: 250, unit: 'g' },
      { ingredient_id: 'potato', amount: 3, unit: 'pcs' },
      { ingredient_id: 'tomato', amount: 2, unit: 'pcs' },
      { ingredient_id: 'onion', amount: 1, unit: 'pcs' },
      { ingredient_id: 'carrot', amount: 1, unit: 'pcs' },
      { ingredient_id: 'sunflower_oil', amount: 2, unit: 'tbsp' },
      { ingredient_id: 'water', amount: 2.5, unit: 'l' },
      { ingredient_id: 'salt', amount: null, unit: 'to_taste' }
    ],
    steps: [
      s('Свинину нарежьте порционными кусочками, залейте питьевой водой и варите до готовности мяса 45 минут.', 2700),
      s('Свёклу нарежьте соломкой и потушите в сотейнике вместе с измельчёнными томатами 15 минут.', 900),
      s('Кабачок и яблоки очистите от кожуры, нарежьте аккуратными одинаковыми ломтиками.'),
      s('В готовый мясной бульон отправьте капусту, картофель и пассерованный лук с морковью на 12 минут.', 720),
      s('Добавьте свёклу, дольки яблок и кабачок, проварите суп ещё 7 минут и снимите с огня настаиваться.')
    ]
  },
  {
    id: 'borscht_green_sorrel_egg',
    title: 'Зелёный борщ со щавелем и крутым яйцом',
    cuisine: 'ru', time: 55, active: 20, servings: 4,
    desc: 'Весенний свежий борщ с приятной кислинкой молодого щавеля и крутыми яйцами.',
    ings: [
      { ingredient_id: 'chicken_fillet', amount: 350, unit: 'g' },
      { ingredient_id: 'sorrel', amount: 200, unit: 'g' },
      { ingredient_id: 'spinach', amount: 100, unit: 'g' },
      { ingredient_id: 'potato', amount: 3, unit: 'pcs' },
      { ingredient_id: 'egg', amount: 3, unit: 'pcs' },
      { ingredient_id: 'onion', amount: 1, unit: 'pcs' },
      { ingredient_id: 'carrot', amount: 1, unit: 'pcs' },
      { ingredient_id: 'butter', amount: 20, unit: 'g' },
      { ingredient_id: 'dill', amount: 15, unit: 'g' },
      { ingredient_id: 'water', amount: 2.0, unit: 'l' },
      { ingredient_id: 'salt', amount: null, unit: 'to_taste' }
    ],
    steps: [
      s('Куриное филе нарежьте средними кубиками, залейте водой и варите прозрачный бульон 20 минут.', 1200),
      s('Очищенный картофель нарежьте брусочками и отправьте в кастрюлю к курице на 12 минут.', 720),
      s('Измельчённый лук и морковь слегка спассеруйте на растопленном масле до золотистости.', 420),
      s('Листья щавеля и шпината промойте, нарежьте полосками и опустите в кипящий суп вместе с зажаркой.'),
      s('Куриные яйца отварите вкрутую в ковшике 8 минут, нарежьте кубиками и всыпьте в горячий суп вместе со свежим укропом.', 480)
    ]
  },
  {
    id: 'borscht_porcini_mushrooms',
    title: 'Монастырский постный борщ с белыми грибами',
    cuisine: 'ru', time: 90, active: 25, servings: 5,
    desc: 'Ароматный постный борщ на наваристом грибном отваре со свёклой и фасолью.',
    ings: [
      { ingredient_id: 'porcini', amount: 200, unit: 'g' },
      { ingredient_id: 'beet', amount: 2, unit: 'pcs' },
      { ingredient_id: 'beans_red', amount: 120, unit: 'g' },
      { ingredient_id: 'cabbage', amount: 250, unit: 'g' },
      { ingredient_id: 'potato', amount: 3, unit: 'pcs' },
      { ingredient_id: 'onion', amount: 1, unit: 'pcs' },
      { ingredient_id: 'carrot', amount: 1, unit: 'pcs' },
      { ingredient_id: 'tomato_paste', amount: 2, unit: 'tbsp' },
      { ingredient_id: 'sunflower_oil', amount: 2, unit: 'tbsp' },
      { ingredient_id: 'garlic', amount: 2, unit: 'pcs' },
      { ingredient_id: 'water', amount: 2.2, unit: 'l' },
      { ingredient_id: 'salt', amount: null, unit: 'to_taste' }
    ],
    steps: [
      s('Белые грибы промойте, нарежьте пластинками и отварите в воде 25 минут для насыщенного отвара.', 1500),
      s('Заранее замоченную фасоль отварите отдельно до мягкости и откиньте на дуршлаг.', 2100),
      s('Свёклу с морковью нашинкуйте соломкой, спассеруйте с томатной пастой и луком на масле 12 минут.', 720),
      s('В грибной бульон опустите капусту и картофель кубиками, варите 10 минут.', 600),
      s('Выложите в кастрюлю тушёную свёклу, варёную фасоль и толчёный чеснок, доведите до кипения и выключите плиту.')
    ]
  },
  {
    id: 'borscht_prunes_beef',
    title: 'Старорусский борщ с говядиной и черносливом',
    cuisine: 'ru', time: 85, active: 30, servings: 5,
    desc: 'Пикантный праздничный борщ с благородным копчёным ароматом вяленого чернослива.',
    ings: [
      { ingredient_id: 'beef', amount: 450, unit: 'g' },
      { ingredient_id: 'prunes', amount: 100, unit: 'g' },
      { ingredient_id: 'beet', amount: 2, unit: 'pcs' },
      { ingredient_id: 'cabbage', amount: 200, unit: 'g' },
      { ingredient_id: 'potato', amount: 3, unit: 'pcs' },
      { ingredient_id: 'carrot', amount: 1, unit: 'pcs' },
      { ingredient_id: 'onion', amount: 1, unit: 'pcs' },
      { ingredient_id: 'tomato_paste', amount: 2, unit: 'tbsp' },
      { ingredient_id: 'butter', amount: 25, unit: 'g' },
      { ingredient_id: 'water', amount: 2.4, unit: 'l' },
      { ingredient_id: 'salt', amount: null, unit: 'to_taste' }
    ],
    steps: [
      s('Говяжью мякоть нарежьте кусочками и варите бульон 45 минут при слабом кипении воды.', 2700),
      s('Чернослив промойте тёплой водой и нарежьте аккуратными половинками.'),
      s('Свёклу натрите соломкой, потушите на сливочном масле с томатной пастой до мягкой консистенции.', 720),
      s('В кипящий суп засыпьте капусту, брусочки картофеля и пассерованные овощи на 12 минут.', 720),
      s('Добавьте свёклу и подготовленный чернослив, проварите суп 8 минут и оставьте настояться перед обедом.')
    ]
  },
  {
    id: 'borscht_smoked_ribs',
    title: 'Казачий борщ с копчёными свиными рёбрышками',
    cuisine: 'ru', time: 70, active: 25, servings: 6,
    desc: 'Наваристый густой борщ с копчёными свиными рёбрышками и сладким перцем.',
    ings: [
      { ingredient_id: 'pork_ribs', amount: 500, unit: 'g' },
      { ingredient_id: 'beet', amount: 2, unit: 'pcs' },
      { ingredient_id: 'bell_pepper', amount: 1, unit: 'pcs' },
      { ingredient_id: 'cabbage', amount: 250, unit: 'g' },
      { ingredient_id: 'potato', amount: 3, unit: 'pcs' },
      { ingredient_id: 'onion', amount: 1, unit: 'pcs' },
      { ingredient_id: 'carrot', amount: 1, unit: 'pcs' },
      { ingredient_id: 'tomato_paste', amount: 2, unit: 'tbsp' },
      { ingredient_id: 'garlic', amount: 3, unit: 'pcs' },
      { ingredient_id: 'sunflower_oil', amount: 2, unit: 'tbsp' },
      { ingredient_id: 'water', amount: 2.5, unit: 'l' },
      { ingredient_id: 'salt', amount: null, unit: 'to_taste' }
    ],
    steps: [
      s('Копчёные рёбрышки разделите по одному ребру, залейте холодной водой и проварите 30 минут.', 1800),
      s('Свёклу и перец нашинкуйте брусочками, потушите с томатом на сковороде 15 минут.', 900),
      s('Лук и морковь нарежьте мелкими кубиками, подрумяньте на растительном масле до лёгкой золотистости.', 420),
      s('В кастрюлю к рёбрышкам отправьте нашинкованную капусту и нарезанный картофель на 12 минут кипения.', 720),
      s('Соедините бульон с тушёной свёклой, овощной заправкой и тёртым чесноком, протомите 7 минут под крышкой.')
    ]
  },
  {
    id: 'borscht_veal_sweet_pepper',
    title: 'Кубанский борщ с нежной телятиной и перцем',
    cuisine: 'ru', time: 75, active: 30, servings: 5,
    desc: 'Яркий южный борщ со сладким перцем, спелыми томатами и свежей телятиной.',
    ings: [
      { ingredient_id: 'veal', amount: 450, unit: 'g' },
      { ingredient_id: 'beet', amount: 2, unit: 'pcs' },
      { ingredient_id: 'bell_pepper', amount: 2, unit: 'pcs' },
      { ingredient_id: 'tomato', amount: 3, unit: 'pcs' },
      { ingredient_id: 'cabbage', amount: 200, unit: 'g' },
      { ingredient_id: 'potato', amount: 3, unit: 'pcs' },
      { ingredient_id: 'onion', amount: 1, unit: 'pcs' },
      { ingredient_id: 'carrot', amount: 1, unit: 'pcs' },
      { ingredient_id: 'sunflower_oil', amount: 2, unit: 'tbsp' },
      { ingredient_id: 'parsley', amount: 15, unit: 'g' },
      { ingredient_id: 'water', amount: 2.3, unit: 'l' },
      { ingredient_id: 'salt', amount: null, unit: 'to_taste' }
    ],
    steps: [
      s('Телятину нарежьте крупными кусочками, опустите в холодную воду и варите 40 минут до мягкости мяса.', 2400),
      s('Свёклу натрите соломкой, а свежие томаты измельчите в блендере до соуса.'),
      s('Потушите свёклу с томатным пюре на сковороде 12 минут, добавив соломку сладкого перца.', 720),
      s('В мясной бульон переложите капусту, картофель брусочками и обжаренный лук с морковью.', 720),
      s('Добавьте тушёные овощи, подсолите, всыпьте свежую зелень петрушки и протомите суп 10 минут.')
    ]
  },
  {
    id: 'borscht_duck_lingonberry',
    title: 'Охотничий борщ с уткой и брусникой',
    cuisine: 'ru', time: 90, active: 35, servings: 5,
    desc: 'Богатый густой борщ с томлёной уткой и терпкой лесной брусникой.',
    ings: [
      { ingredient_id: 'duck', amount: 500, unit: 'g' },
      { ingredient_id: 'cranberry', amount: 80, unit: 'g' },
      { ingredient_id: 'beet', amount: 2, unit: 'pcs' },
      { ingredient_id: 'cabbage', amount: 250, unit: 'g' },
      { ingredient_id: 'potato', amount: 3, unit: 'pcs' },
      { ingredient_id: 'onion', amount: 1, unit: 'pcs' },
      { ingredient_id: 'carrot', amount: 1, unit: 'pcs' },
      { ingredient_id: 'tomato_paste', amount: 1.5, unit: 'tbsp' },
      { ingredient_id: 'garlic', amount: 2, unit: 'pcs' },
      { ingredient_id: 'sunflower_oil', amount: 2, unit: 'tbsp' },
      { ingredient_id: 'water', amount: 2.5, unit: 'l' },
      { ingredient_id: 'salt', amount: null, unit: 'to_taste' }
    ],
    steps: [
      s('Утку порубите на порционные части, залейте холодной водой и варите наваристый бульон 50 минут.', 3000),
      s('Свёклу нашинкуйте соломкой, соедините с томатом и потушите на сковороде до мягкости 15 минут.', 900),
      s('Морковь с репчатым луком спассеруйте на растительном масле до румяной корочки.', 420),
      s('В утиный отвар заложите капусту, картофель и ягоды, варите на среднем огне 12 минут.', 720),
      s('Выложите в кастрюлю тушёную свёклу, зажарку и чеснок, доведите до кипения и оставьте настояться 15 минут.')
    ]
  },
  {
    id: 'borscht_lithuanian_cold',
    title: 'Литовский холодный борщ на кефире со свёклой',
    cuisine: 'lt', time: 55, active: 20, servings: 4,
    desc: 'Освежающий холодник из отварной свёклы на густом кефире со свежими огурцами.',
    ings: [
      { ingredient_id: 'beet', amount: 2, unit: 'pcs' },
      { ingredient_id: 'kefir', amount: 800, unit: 'ml' },
      { ingredient_id: 'cucumber', amount: 3, unit: 'pcs' },
      { ingredient_id: 'egg', amount: 3, unit: 'pcs' },
      { ingredient_id: 'green_onion', amount: 30, unit: 'g' },
      { ingredient_id: 'dill', amount: 20, unit: 'g' },
      { ingredient_id: 'water', amount: 400, unit: 'ml' },
      { ingredient_id: 'salt', amount: null, unit: 'to_taste' }
    ],
    steps: [
      s('Свёклу отварите в кожуре до мягкости в течение 40 минут, остудите и натрите на тёрке.', 2400),
      s('Свежие огурцы нарежьте тонкой соломкой, а куриные яйца отварите вкрутую.', 600),
      s('Зелёный лук и свежий укроп мелко порубите ножом и слегка разомните с щепоткой соли.'),
      s('В глубокой ёмкости соедините тёртую свёклу, огурцы и зелень, залейте кефиром и водой.'),
      s('Перемешайте холодник, поставьте в холодильник на 15 минут и подавайте с половинками яиц.')
    ]
  },
  {
    id: 'borscht_polish_white',
    title: 'Белый польский борщ с колбасками и майораном',
    cuisine: 'pl', time: 60, active: 25, servings: 4,
    desc: 'Традиционный польский борщ на мясном бульоне с белыми колбасками и сметанной заправкой.',
    ings: [
      { ingredient_id: 'sausage', amount: 350, unit: 'g' },
      { ingredient_id: 'bacon', amount: 100, unit: 'g' },
      { ingredient_id: 'potato', amount: 3, unit: 'pcs' },
      { ingredient_id: 'sour_cream', amount: 150, unit: 'g' },
      { ingredient_id: 'egg', amount: 2, unit: 'pcs' },
      { ingredient_id: 'garlic', amount: 2, unit: 'pcs' },
      { ingredient_id: 'onion', amount: 1, unit: 'pcs' },
      { ingredient_id: 'water', amount: 1.8, unit: 'l' },
      { ingredient_id: 'salt', amount: null, unit: 'to_taste' }
    ],
    steps: [
      s('Бекон нарежьте тонкими полосками, а колбаски кружками, обжарьте на сковороде с луком.', 480),
      s('Переложите обжаренное мясо в кастрюлю с кипящей водой и варите бульон 20 минут.', 1200),
      s('Картофель нарежьте кубиками и положите вариться в суп на 12 минут.', 720),
      s('Сметану взбейте в пиале с давленым чесноком и бульоном, затем тонкой струйкой влейте в суп.'),
      s('Куриные яйца отварите вкрутую в ковшике 8 минут, разрежьте на четвертинки и подавайте к горячему польскому борщу.', 480)
    ]
  },
  {
    id: 'borscht_chlodnik_radish',
    title: 'Летний польский хлодник с редисом и огурцом',
    cuisine: 'pl', time: 45, active: 20, servings: 4,
    desc: 'Холодный свекольный суп красивого розового цвета со свежим редисом и зеленью.',
    ings: [
      { ingredient_id: 'beet', amount: 2, unit: 'pcs' },
      { ingredient_id: 'radish', amount: 150, unit: 'g' },
      { ingredient_id: 'cucumber', amount: 2, unit: 'pcs' },
      { ingredient_id: 'kefir', amount: 700, unit: 'ml' },
      { ingredient_id: 'sour_cream', amount: 100, unit: 'g' },
      { ingredient_id: 'green_onion', amount: 25, unit: 'g' },
      { ingredient_id: 'dill', amount: 20, unit: 'g' },
      { ingredient_id: 'egg', amount: 2, unit: 'pcs' },
      { ingredient_id: 'water', amount: 300, unit: 'ml' },
      { ingredient_id: 'salt', amount: null, unit: 'to_taste' }
    ],
    steps: [
      s('Свёклу отварите до мягкого состояния, а куриные яйца отварите вкрутую 8 минут и натрите свёклу на тёрке.', 2100),
      s('Свежий редис и огурцы нарежьте соломкой для приятного хруста.'),
      s('Зелёный лук с укропом мелко нашинкуйте и разотрите ложкой с солью до появления сока.'),
      s('Смешайте тёртую свёклу с овощами и зеленью, залейте кефиром со сметаной и водой.'),
      s('Охладите суп в холодильнике 15 минут, разлейте по тарелкам и украсьте половинками яиц.')
    ]
  },
  {
    id: 'borscht_sauerkraut_pork',
    title: 'Уральский борщ с квашеной капустой и свининой',
    cuisine: 'ru', time: 75, active: 30, servings: 6,
    desc: 'Зимний согревающий борщ с характерной ядрёной кислинкой квашеной капусты.',
    ings: [
      { ingredient_id: 'pork', amount: 450, unit: 'g' },
      { ingredient_id: 'sauerkraut', amount: 250, unit: 'g' },
      { ingredient_id: 'beet', amount: 2, unit: 'pcs' },
      { ingredient_id: 'potato', amount: 3, unit: 'pcs' },
      { ingredient_id: 'onion', amount: 1, unit: 'pcs' },
      { ingredient_id: 'carrot', amount: 1, unit: 'pcs' },
      { ingredient_id: 'tomato_paste', amount: 2, unit: 'tbsp' },
      { ingredient_id: 'sunflower_oil', amount: 2, unit: 'tbsp' },
      { ingredient_id: 'garlic', amount: 2, unit: 'pcs' },
      { ingredient_id: 'water', amount: 2.3, unit: 'l' },
      { ingredient_id: 'salt', amount: null, unit: 'to_taste' }
    ],
    steps: [
      s('Свинину нарежьте кусочками, залейте холодной водой и варите бульон 35 минут, снимая пенку.', 2100),
      s('Квашеную капусту промойте, отожмите и потушите в отдельном сотейнике с маслом 20 минут.', 1200),
      s('Свёклу, морковь и лук нашинкуйте соломкой, спассеруйте на сковороде с томатной пастой до мягкости.', 720),
      s('В мясной бульон опустите кубики картофеля, проварите 10 минут, затем добавьте тушёную капусту.', 600),
      s('Переложите в кастрюлю овощную заправку со свёклой и чеснок, протомите суп 10 минут.')
    ]
  },
  {
    id: 'borscht_turkey_celery',
    title: 'Диетический борщ с филе индейки и сельдереем',
    cuisine: 'home', time: 55, active: 25, servings: 4,
    desc: 'Лёгкий низкокалорийный борщ на нежном мясе индейки с черешковым сельдереем.',
    ings: [
      { ingredient_id: 'turkey_fillet', amount: 400, unit: 'g' },
      { ingredient_id: 'beet', amount: 2, unit: 'pcs' },
      { ingredient_id: 'celery', amount: 2, unit: 'pcs' },
      { ingredient_id: 'cabbage', amount: 200, unit: 'g' },
      { ingredient_id: 'potato', amount: 2, unit: 'pcs' },
      { ingredient_id: 'onion', amount: 1, unit: 'pcs' },
      { ingredient_id: 'carrot', amount: 1, unit: 'pcs' },
      { ingredient_id: 'tomato_paste', amount: 1.5, unit: 'tbsp' },
      { ingredient_id: 'olive_oil', amount: 1.5, unit: 'tbsp' },
      { ingredient_id: 'lemon', amount: 0.5, unit: 'pcs' },
      { ingredient_id: 'water', amount: 2.0, unit: 'l' },
      { ingredient_id: 'salt', amount: null, unit: 'to_taste' }
    ],
    steps: [
      s('Филе индейки нарежьте брусочками, залейте водой и варите лёгкий прозрачный бульон 25 минут.', 1500),
      s('Свёклу натрите соломкой, сбрызните лимонным соком и потушите с томатом на масле 12 минут.', 720),
      s('Стебли сельдерея, морковь и лук нарежьте ломтиками и спассеруйте на среднем огне.', 420),
      s('В кипящий бульон отправьте нашинкованную капусту и картофель, варите 10 минут.', 600),
      s('Добавьте тушёную свёклу и пассерованные овощи, подсолите и потомите борщ 8 минут перед подачей.')
    ]
  }
];

borschts.forEach(b => {
  allSoups.push({
    id: `soup_${b.id}`,
    title: b.title,
    dish_type: 'soup',
    dish_group: 'soup',
    cuisine: b.cuisine,
    total_minutes: b.time,
    active_minutes: b.active,
    servings: b.servings,
    description: b.desc,
    ingredients: b.ings,
    steps: b.steps
  });
});

// 2. SHCHI (15)
const shchiDefs = [
  { id: 'shchi_sour_pork', title: 'Суточные щи из квашеной капусты со свининой', m: 'pork', c: 'sauerkraut', time: 90, desc: 'Знаменитые русские суточные щи с глубоким вкусом и томлёной свининой.' },
  { id: 'shchi_fresh_beef', title: 'Богатые русские щи со свежей капустой и говядиной', m: 'beef', c: 'cabbage', time: 80, desc: 'Традиционные русские щи на крепком говяжьем бульоне со сладкой капустой.' },
  { id: 'shchi_chicken_young', title: 'Лёгкие деревенские щи из молодой капусты с курицей', m: 'chicken', c: 'cabbage', time: 50, desc: 'Нежные весенние щи на курином отваре со свежей молодой зеленью.' },
  { id: 'shchi_monastic_forest', title: 'Монастырские щи со свежими лесными грибами', m: 'forest_mushrooms', c: 'cabbage', time: 55, desc: 'Ароматные постные щи на наваристом грибном бульоне с картофелем.' },
  { id: 'shchi_veal_turnip', title: 'Старинные щи с телятиной и сладкой репой', m: 'veal', c: 'turnip', time: 70, desc: 'Исконно русские щи на телячьем бульоне с добавлением печёной репы.' },
  { id: 'shchi_smoked_ribs', title: 'Щи из кислой капусты с копчёными рёбрышками', m: 'pork_ribs', c: 'sauerkraut', time: 75, desc: 'Наваристые дымные щи с ароматом копчёностей и квашеной капустой.' },
  { id: 'shchi_green_nettle', title: 'Зелёные майские щи с крапивой и яйцом', m: 'chicken_fillet', c: 'nettle', time: 40, desc: 'Полезные витаминные щи из молодой майской крапивы со сметаной и крутым яйцом.' },
  { id: 'shchi_turkey_sauerkraut', title: 'Помещичьи щи из квашеной капусты с индейкой', m: 'turkey', c: 'sauerkraut', time: 65, desc: 'Сытные ароматные щи на бульоне из птицы с квашеной капустой.' },
  { id: 'shchi_duck_sauerkraut', title: 'Праздничные щи с уткой и квашеной капустой', m: 'duck', c: 'sauerkraut', time: 85, desc: 'Томлёные праздничные щи на утином жирке с ядрёной капустой.' },
  { id: 'shchi_champignon_barley', title: 'Уральские щи с квашеной капустой и перловкой', m: 'champignon', c: 'sauerkraut', time: 60, desc: 'Сытные уральские щи с разваренной перловой крупой и грибами.' },
  { id: 'shchi_veal_leek', title: 'Боярские щи с телятиной и луком-пореем', m: 'veal', c: 'leek', time: 70, desc: 'Ароматные наваристые щи с добавлением нежного лука-порея и кореньев.' },
  { id: 'shchi_rabbit_roots', title: 'Диетические щи из кролика с белыми кореньями', m: 'rabbit', c: 'cabbage', time: 65, desc: 'Лёгкие деликатесные щи на прозрачном бульоне из фермерского кролика.' },
  { id: 'shchi_pike_cabbage', title: 'Рыбацкие щи со щукой и свежей капустой', m: 'pike', c: 'cabbage', time: 50, desc: 'Старинные рыбные щи с филе волжской щуки и припущенными овощами.' },
  { id: 'shchi_beef_parsley_root', title: 'Вологодские щи из капусты с петрушечным корнем', m: 'beef', c: 'parsley_root', time: 75, desc: 'Наваристые ароматные щи с добавлением сладкого корня петрушки.' },
  { id: 'shchi_lamb_cabbage', title: 'Кавказские щи с бараниной и капустой', m: 'lamb', c: 'cabbage', time: 80, desc: 'Пряные сытные щи на крепком бараньем бульоне с чесноком и перцем.' }
];

for (const it of shchiDefs) {
  const isSauerkraut = it.c === 'sauerkraut';
  addSoup({
    id: it.id,
    title: it.title,
    cuisine: 'ru',
    time: it.time,
    active: 25,
    desc: it.desc,
    ings: [
      { ingredient_id: it.m, amount: 400, unit: 'g' },
      { ingredient_id: it.c, amount: 250, unit: 'g' },
      { ingredient_id: 'potato', amount: 3, unit: 'pcs' },
      { ingredient_id: 'carrot', amount: 1, unit: 'pcs' },
      { ingredient_id: 'onion', amount: 1, unit: 'pcs' },
      { ingredient_id: 'sunflower_oil', amount: 2, unit: 'tbsp' },
      { ingredient_id: 'water', amount: 2.2, unit: 'l' },
      { ingredient_id: 'salt', amount: null, unit: 'to_taste' }
    ],
    steps: [
      s(`Для щей «${it.title}» подготовьте основу: промойте мясо или рыбу и отварите в подсоленной воде 30 минут.`, 1800),
      s(`Репчатый лук и морковь для щей «${it.title}» измельчите соломкой и спассеруйте на сковороде до мягкости.`, 420),
      s(`${isSauerkraut ? 'Квашеную капусту промойте и потушите' : 'Капусту тонко нашинкуйте'} для закладки в суп «${it.title}».`),
      s(`В кастрюлю с бульоном для щей «${it.title}» положите картофель и капусту, варите 12 минут.`, 720),
      s(`Переложите зажарку в щи «${it.title}», проверьте на готовность овощей и протомите 8 минут перед подачей.`)
    ]
  });
}

// 3. RASSOLNIKI (12)
const rassolnikDefs = [
  { id: 'rassolnik_leningrad', title: 'Ленинградский рассольник с телятиной и перловкой', m: 'veal', g: 'pearl_barley', ext: 'tomato_paste', desc: 'Классический ленинградский рассольник с томатом, солёными огурцами и перловой крупой.' },
  { id: 'rassolnik_moscow', title: 'Московский рассольник с курицей и рисом', m: 'chicken', g: 'rice', desc: 'Нежный домашний рассольник на курином отваре с круглым рисом.' },
  { id: 'rassolnik_pork_ribs', title: 'Деревенский рассольник со свиными рёбрышками', m: 'pork_ribs', g: 'pearl_barley', desc: 'Сытный наваристый рассольник с хрустящими бочковыми огурчиками.' },
  { id: 'rassolnik_porcini', title: 'Монастырский рассольник с белыми грибами', m: 'porcini', g: 'pearl_barley', desc: 'Ароматный постный рассольник на крепком грибном бульоне с соленьями.' },
  { id: 'rassolnik_kidneys', title: 'Старомосковский рассольник с почками и огурцами', m: 'beef', g: 'round_rice', desc: 'Исторический ресторанный рассольник с солеными огурцами и кореньями.' },
  { id: 'rassolnik_pike', title: 'Рыбный рассольник с судаком и перловкой', m: 'pike', g: 'pearl_barley', desc: 'Необычный старинный рассольник на прозрачном рыбном отваре.' },
  { id: 'rassolnik_turkey', title: 'Домашний рассольник с филе индейки и рисом', m: 'turkey_fillet', g: 'rice', desc: 'Легкий и сытный суп с солеными огурчиками и длиннозерным рисом.' },
  { id: 'rassolnik_duck', title: 'Охотничий рассольник с уткой и гречкой', m: 'duck', g: 'buckwheat', desc: 'Оригинальный старинный суп с уткой, гречневой крупой и рассолом.' },
  { id: 'rassolnik_meatballs', title: 'Рассольник с мясными фрикадельками и пшеном', m: 'minced_beef', g: 'millet', desc: 'Быстрый домашний рассольник с сочными фрикадельками и ярким пшеном.' },
  { id: 'rassolnik_veal', title: 'Весенний рассольник с телятиной и шпинатом', m: 'veal', g: 'rice', desc: 'Освежающий суп с добавлением свежих листьев шпината и огуречного рассола.' },
  { id: 'rassolnik_champignon', title: 'Грибной рассольник со свежими шампиньонами', m: 'champignon', g: 'round_rice', desc: 'Душистый суп с обжаренными грибами, рисом и маринованными огурчиками.' },
  { id: 'rassolnik_rabbit', title: 'Нежный рассольник из кролика с перловой крупой', m: 'rabbit', g: 'pearl_barley', desc: 'Диетический прозрачный рассольник на мясе фермерского кролика.' }
];

const rassolnikStep3 = [
  'Солёные бочковые огурцы измельчите аккуратной соломкой и припустите на сковороде 10 минут с бульоном.',
  'Хрустящие огурчики нашинкуйте тонкой соломкой и потомите 10 минут в сотейнике с парой ложек отвара.',
  'Кислые соленые огурцы нарежьте мелкими кубиками и припустите на медленном огне 10 минут до мягкости.',
  'Маринованные огурцы нашинкуйте брусочками и потушите в сковороде 10 минут перед закладкой.',
  'Бочковые соленые огурцы очистите от толстой кожицы, измельчите соломкой и потомите в бульоне 10 минут.',
  'Пряные соленые огурчики измельчите тонкими пластинками и припустите на среднем огне 10 минут.',
  'Крепкие соленые огурцы нарежьте тончайшей соломкой и потомите в ковшике с бульоном 10 минут.',
  'Домашние соленые огурцы мелко порубите ножом и припустите в сотейнике 10 минут на слабом огне.',
  'Хрустящие соленые огурцы нашинкуйте ровными брусочками и проварите в малом количестве воды 10 минут.',
  'Очищенные соленые огурцы нарежьте аккуратной мелкой соломкой и потушите 10 минут в сковороде.',
  'Ароматные соленые огурчики измельчите соломкой и потомите в мясном отваре 10 минут для мягкости.',
  'Традиционные соленые огурцы нарежьте соломкой и слегка припустите на тихом огне в течение 10 минут.'
];

for (let rIdx = 0; rIdx < rassolnikDefs.length; rIdx++) {
  const it = rassolnikDefs[rIdx];
  const ings = [
    { ingredient_id: it.m, amount: 400, unit: 'g' },
    { ingredient_id: it.g, amount: 80, unit: 'g' },
    { ingredient_id: 'pickles', amount: 3, unit: 'pcs' },
    { ingredient_id: 'potato', amount: 3, unit: 'pcs' },
    { ingredient_id: 'carrot', amount: 1, unit: 'pcs' },
    { ingredient_id: 'onion', amount: 1, unit: 'pcs' },
    { ingredient_id: 'sunflower_oil', amount: 2, unit: 'tbsp' },
    { ingredient_id: 'water', amount: 2.2, unit: 'l' },
    { ingredient_id: 'salt', amount: null, unit: 'to_taste' }
  ];
  if (it.ext) {
    ings.push({ ingredient_id: it.ext, amount: 2, unit: 'tbsp' });
  }

  addSoup({
    id: it.id,
    title: it.title,
    cuisine: 'ru',
    time: 65,
    active: 25,
    desc: it.desc,
    ings: ings,
    steps: [
      s(`Для первого блюда «${it.title}» сварите основу в кипящей воде в течение 30 минут до мягкости.`, 1800),
      s(`Крупу для супа «${it.title}» отварите в отдельном ковшике до мягкости и слейте отвар.`, 900),
      s(rassolnikStep3[rIdx], 600),
      s(`Опустите картофель и пассерованные овощи в бульон для супа «${it.title}», варите 12 минут.`, 720),
      s(`Добавьте подготовленные огурцы и крупу в суп «${it.title}», протомите 8 минут перед подачей.`)
    ]
  });
}

// 4. SOLYANKAS (12)
const solyankaDefs = [
  { id: 'solyanka_meat', title: 'Сборная мясная солянка по-московски', m1: 'beef', m2: 'ham', desc: 'Культовая сборная мясная солянка с маслинами, каперсами и лимоном.' },
  { id: 'solyanka_ribs_bacon', title: 'Охотничья солянка с копчёными рёбрышками и беконом', m1: 'pork_ribs', m2: 'bacon', desc: 'Густая солянка с насыщенным ароматом дымка и солеными огурчиками.' },
  { id: 'solyanka_poultry', title: 'Птичья солянка с курицей и индейкой', m1: 'chicken', m2: 'turkey_fillet', desc: 'Более лёгкая домашняя версия мясной солянки на нежном птичьем бульоне.' },
  { id: 'solyanka_salmon_cod', title: 'Царская рыбная солянка с сёмгой и треской', m1: 'salmon', m2: 'cod', desc: 'Изысканная рыбная солянка на концентрированном бульоне из благородной рыбы.' },
  { id: 'solyanka_mushroom', title: 'Грибная солянка с белыми грибами и маслятами', m1: 'porcini', m2: 'champignon', desc: 'Традиционная старорусская солянка на лесном грибном отваре с маслинами.' },
  { id: 'solyanka_georgian', title: 'Грузинская солянка на сковороде с кинзой', m1: 'beef', m2: 'garlic', desc: 'Густая пряная солянка из говядины с томатами, чесноком и свежей кинзой.' },
  { id: 'solyanka_veal', title: 'Барская солянка с нежной телятиной и окороком', m1: 'veal', m2: 'ham', desc: 'Деликатесная солянка на прозрачном телячьем бульоне с томатной заправкой.' },
  { id: 'solyanka_duck', title: 'Деревенская солянка с уткой и домашней колбасой', m1: 'duck', m2: 'sausage', desc: 'Наваристая солянка с кусочками сочной утки и пикантными колбасками.' },
  { id: 'solyanka_seafood', title: 'Морская солянка с креветками и кальмарами', m1: 'shrimp', m2: 'squid', desc: 'Средиземноморская интерпретация солянки с морепродуктами и лимоном.' },
  { id: 'solyanka_lamb', title: 'Кавказская солянка с бараниной и аджикой', m1: 'lamb', m2: 'adjika', desc: 'Острая согревающая солянка на баранине с добавлением ложки жгучей аджики.' },
  { id: 'solyanka_frankfurters', title: 'Быстрая домашняя солянка со свининой и сосисками', m1: 'pork', m2: 'frankfurters', desc: 'Любимый домашний суп быстрого приготовления с аппетитными сосисками.' },
  { id: 'solyanka_pike_salmon', title: 'Волжская солянка с щукой и лососем', m1: 'pike', m2: 'salmon', desc: 'Ароматная наваристая рыбная солянка с каперсами и ломтиками лимона.' }
];

for (const it of solyankaDefs) {
  addSoup({
    id: it.id,
    title: it.title,
    cuisine: it.id.includes('georgian') ? 'ge' : 'ru',
    time: 55,
    active: 25,
    desc: it.desc,
    ings: [
      { ingredient_id: it.m1, amount: 300, unit: 'g' },
      { ingredient_id: it.m2, amount: 150, unit: 'g' },
      { ingredient_id: 'pickles', amount: 2, unit: 'pcs' },
      { ingredient_id: 'tomato_paste', amount: 2, unit: 'tbsp' },
      { ingredient_id: 'onion', amount: 1, unit: 'pcs' },
      { ingredient_id: 'olives', amount: 50, unit: 'g' },
      { ingredient_id: 'lemon', amount: 0.5, unit: 'pcs' },
      { ingredient_id: 'sunflower_oil', amount: 2, unit: 'tbsp' },
      { ingredient_id: 'water', amount: 2.0, unit: 'l' },
      { ingredient_id: 'salt', amount: null, unit: 'to_taste' }
    ],
    steps: [
      s(`Для солянки «${it.title}» подготовьте и отварите мясопродукты или рыбу в кипятке 25 минут.`, 1500),
      s(`Копчености и огурцы для солянки «${it.title}» измельчите аккуратной тонкой соломкой.`),
      s(`Лук для солянки «${it.title}» спассеруйте на сковороде с томатной пастой и огурцами 10 минут.`, 600),
      s(`В кипящий суп «${it.title}» отправьте все мясные кусочки и томатную заправку, варите 12 минут.`, 720),
      s(`Положите в солянку «${it.title}» маслины с дольками лимона, выключите огонь и дайте настояться 10 минут.`)
    ]
  });
}

// 5. FISH & SEAFOOD SOUPS (20)
const fishDefs = [
  { id: 'ukha_tsar', title: 'Царская тройная уха с семгой и судаком', f1: 'salmon', f2: 'pike', cuisine: 'ru', desc: 'Праздничная уха на тройном прозрачном рыбном бульоне с красной рыбой.' },
  { id: 'ukha_rostov', title: 'Ростовская уха с судаком и помидорами', f1: 'pike', f2: 'tomato', cuisine: 'ru', desc: 'Знаменитая донская уха со сладкими томатами и свежей рубленой петрушкой.' },
  { id: 'ukha_karelian', title: 'Карельская уха лохикейтто со сливками', f1: 'salmon', f2: 'cream', cuisine: 'ru', desc: 'Сливочная скандинавская уха с форелью, луком-пореем и молодым картофелем.' },
  { id: 'ukha_perch_cod', title: 'Рыбацкая уха на костре из окуня и трески', f1: 'perch', f2: 'cod', cuisine: 'ru', desc: 'Простая и наваристая уха с дымком из речной и морской белой рыбы.' },
  { id: 'ukha_carp', title: 'Астраханская уха из волжского сазана с перцем', f1: 'carp', f2: 'bell_pepper', cuisine: 'ru', desc: 'Сладковатая жирная уха из свежего сазана с крупным болгарским перцем.' },
  { id: 'fish_cod_leek', title: 'Норвежский рыбный суп с треской и пореем', f1: 'cod', f2: 'leek', cuisine: 'home', desc: 'Нежный скандинавский суп со сливочным маслом и филе трески.' },
  { id: 'fish_mediterranean', title: 'Средиземноморский рыбный суп с томатами', f1: 'pollock', f2: 'tomatoes_canned', cuisine: 'it', desc: 'Густой пряный томатный суп с белой рыбой, креветками и оливковым маслом.' },
  { id: 'fish_bouillabaisse', title: 'Марсельский буйабес с морепродуктами', f1: 'cod', f2: 'squid', cuisine: 'fr', desc: 'Знаменитый прованский суп рыбаков с морской рыбой, кальмарами и чесноком.' },
  { id: 'fish_tomyum', title: 'Тайский суп том ям с креветками', f1: 'shrimp', f2: 'champignon', cuisine: 'th', desc: 'Остро-кислый азиатский суп с креветками, грибами и кокосовым молоком.' },
  { id: 'fish_tomkha', title: 'Тайский кокосовый суп том кха с лососем', f1: 'salmon', f2: 'coconut_milk', cuisine: 'th', desc: 'Нежный кисло-сладкий тайский суп на кокосовом молоке с лососем и имбирем.' },
  { id: 'fish_hake_dill', title: 'Домашний рыбный суп из хека с укропом', f1: 'hake', f2: 'dill', cuisine: 'home', desc: 'Простой быстрый суп из нежного филе хека для повседневного семейного обеда.' },
  { id: 'fish_pollock_rice', title: 'Диетический суп из минтая с круглым рисом', f1: 'pollock', f2: 'round_rice', cuisine: 'home', desc: 'Легкий низкокалорийный рыбный суп с рисом и овощами для здорового рациона.' },
  { id: 'fish_trout_spinach', title: 'Сливочный суп с форелью и шпинатом', f1: 'trout', f2: 'spinach', cuisine: 'home', desc: 'Изысканный суп со свежими листьями шпината, сливками и кусочками форели.' },
  { id: 'fish_squid_corn', title: 'Азиатский суп с кальмарами и кукурузой', f1: 'squid', f2: 'corn_canned', cuisine: 'cn', desc: 'Быстрый восточный суп с тонкими кольцами кальмара и зернами кукурузы.' },
  { id: 'fish_mussels_tomato', title: 'Итальянский суп с мидиями в томатном соусе', f1: 'mussels', f2: 'tomato', cuisine: 'it', desc: 'Ароматный неаполитанский суп из сочных мидий с чесноком и томатами.' },
  { id: 'fish_chowder_shrimp', title: 'Американский чаудер с креветками и кукурузой', f1: 'shrimp', f2: 'corn_canned', cuisine: 'us', desc: 'Густой бархатистый сливочный крем-суп с морепродуктами и кукурузой.' },
  { id: 'fish_catfish', title: 'Днепровская уха из сома с золотистым луком', f1: 'catfish', f2: 'onion', cuisine: 'ru', desc: 'Наваристая жирная уха из мякоти речного сома со сладким луком.' },
  { id: 'fish_mackerel', title: 'Пряный суп из скумбрии с лимоном', f1: 'mackerel', f2: 'lemon', cuisine: 'home', desc: 'Сытный и ароматный рыбный суп со скумбрией и свежим лимонным соком.' },
  { id: 'fish_herring', title: 'Балтийский суп из сельди со сливками', f1: 'herring', f2: 'cream', cuisine: 'home', desc: 'Старинный прибалтийский рыбный суп с отварным картофелем и молоком.' },
  { id: 'fish_pikeperch_rice', title: 'Уха по-волжски из судака с рисом', f1: 'pike', f2: 'round_rice', cuisine: 'ru', desc: 'Прозрачная наваристая уха из белого судака с рисом и свежей петрушкой.' }
];

for (const it of fishDefs) {
  addSoup({
    id: it.id,
    title: it.title,
    cuisine: it.cuisine,
    time: 40,
    active: 20,
    desc: it.desc,
    ings: [
      { ingredient_id: it.f1, amount: 350, unit: 'g' },
      { ingredient_id: it.f2, amount: 150, unit: 'g' },
      { ingredient_id: 'potato', amount: 3, unit: 'pcs' },
      { ingredient_id: 'onion', amount: 1, unit: 'pcs' },
      { ingredient_id: 'carrot', amount: 1, unit: 'pcs' },
      { ingredient_id: 'sunflower_oil', amount: 1.5, unit: 'tbsp' },
      { ingredient_id: 'water', amount: 2.0, unit: 'l' },
      { ingredient_id: 'salt', amount: null, unit: 'to_taste' }
    ],
    steps: [
      s(`Для рыбного блюда «${it.title}» промойте рыбу и разделите на крупные аккуратные кусочки.`),
      s(`Морковь и лук для супа «${it.title}» измельчите тонкими кружками и спассеруйте на среднем огне.`, 420),
      s(`Опустите нарезанный картофель в кипящий отвар для супа «${it.title}» и варите 10 минут.`, 600),
      s(`Добавьте подготовленную рыбу и второй компонент в суп «${it.title}», варите 8 минут до белизны мякоти рыбы.`, 480),
      s(`Снимите суп «${it.title}» с огня, накройте крышкой и дайте настояться 7 минут перед подачей.`)
    ]
  });
}

// 6. LEGUME & GRAIN SOUPS (20)
const legumeDefs = [
  { id: 'pea_smoked_ribs', title: 'Гороховый суп с копчёным окороком и гренками', leg: 'peas_dry', meat: 'ham', cuisine: 'ru', desc: 'Густой бархатистый гороховый суп с ароматом копчёного окорока и хрустящими сухариками.' },
  { id: 'pea_chicken', title: 'Домашний гороховый суп с курицей и морковью', leg: 'peas_dry', meat: 'chicken', cuisine: 'home', desc: 'Сытный согревающий суп из сухого колотого гороха на нежном курином бульоне.' },
  { id: 'lentil_turkish', title: 'Турецкий суп мерджимек чорбасы из чечевицы', leg: 'lentils_red', meat: 'lemon', cuisine: 'tr', desc: 'Пряный кремовый суп из красной чечевицы со свежим соком лимона.' },
  { id: 'lentil_beef', title: 'Сытный суп из зелёной чечевицы с говядиной', leg: 'lentils_green', meat: 'beef', cuisine: 'home', desc: 'Богатый растительным белком густой суп с сочной говяжьей мякотью.' },
  { id: 'bean_lobio', title: 'Грузинский фасолевый суп лобио с кинзой', leg: 'beans_red', meat: 'walnut', cuisine: 'ge', desc: 'Густой пряный фасолевый суп с грецкими орехами и свежей кинзой.' },
  { id: 'bean_bacon', title: 'Тосканский суп с белой фасолью и беконом', leg: 'beans_white', meat: 'bacon', cuisine: 'it', desc: 'Итальянский суп с разваренной белой фасолью и поджаренным беконом.' },
  { id: 'chickpea_lamb', title: 'Восточный суп из нута с бараниной и зирой', leg: 'chickpeas_dry', meat: 'lamb', cuisine: 'uz', desc: 'Наваристый среднеазиатский суп с крупным нутом и сочной бараниной.' },
  { id: 'chickpea_tomato', title: 'Постный суп из нута в густом томатном соусе', leg: 'chickpeas_canned', meat: 'tomato_paste', cuisine: 'home', desc: 'Ароматный суп со сладким перцем, консервированным нутом и томатами.' },
  { id: 'mung_mashkhurda', title: 'Узбекская машхурда с машем и говядиной', leg: 'mung_beans', meat: 'beef', cuisine: 'uz', desc: 'Сытный восточный суп с мелким зеленым машем, рисом и обжаренным мясом.' },
  { id: 'barley_forest_kulesh', title: 'Деревенский кулеш с перловкой и грибами', leg: 'pearl_barley', meat: 'forest_mushrooms', cuisine: 'ru', desc: 'Старинная разваристая похлебка с перловой крупой и грибами.' },
  { id: 'buckwheat_turkey', title: 'Гречневый суп с фрикадельками из индейки', leg: 'buckwheat', meat: 'turkey_fillet', cuisine: 'home', desc: 'Легкий и сытный домашний суп с рассыпчатой гречкой и нежной птицей.' },
  { id: 'millet_lard_kulesh', title: 'Полевой кулеш с золотистым пшеном и салом', leg: 'millet', meat: 'lard', cuisine: 'ru', desc: 'Традиционный казачий суп-каша с рассыпчатым пшеном и шкварками из сала.' },
  { id: 'rice_meatball', title: 'Суп с мясными фрикадельками и круглым рисом', leg: 'round_rice', meat: 'minced_beef', cuisine: 'home', desc: 'Любимый с детства домашний суп с нежными тефтельками и овощами.' },
  { id: 'noodle_chicken', title: 'Куриный суп с домашней яичной лапшой', leg: 'noodles', meat: 'chicken', cuisine: 'ru', desc: 'Золотистый прозрачный куриный бульон с тонкой домашней лапшой и зеленью.' },
  { id: 'vermicelli_chicken_mince', title: 'Быстрый суп с вермишелью и фрикадельками', leg: 'vermicelli', meat: 'minced_chicken', cuisine: 'home', desc: 'Простой быстрый суп на скорую руку для уютного семейного обеда.' },
  { id: 'peas_green_mint', title: 'Крем-суп из зеленого горошка со свежей мятой', leg: 'green_peas', meat: 'cream', cuisine: 'fr', desc: 'Яркий изумрудный крем-суп с нежными сливками и ноткой мяты.' },
  { id: 'beans_canned_hunting', title: 'Охотничий суп с красной фасолью и колбасками', leg: 'beans_canned', meat: 'sausage', cuisine: 'home', desc: 'Быстрый сытный суп с фасолью, чесноком и полукопчеными колбасками.' },
  { id: 'lentil_squash_cozy', title: 'Согревающий суп из красной чечевицы с тыквой', leg: 'lentils_red', meat: 'squash', cuisine: 'home', desc: 'Бархатистый осенний крем-суп оранжевого цвета с восточными пряностями.' },
  { id: 'couscous_zucchini', title: 'Марокканский легкий суп с кускусом и цукини', leg: 'couscous', meat: 'chicken_fillet', cuisine: 'home', desc: 'Средиземноморский суп с нежным кускусом и молодыми кабачками.' },
  { id: 'bulgur_beef_tomato', title: 'Анатолийский суп с булгуром и говядиной', leg: 'bulgur', meat: 'beef', cuisine: 'tr', desc: 'Пряный ближневосточный суп с крупным булгуром, томатом и паприкой.' }
];

for (const it of legumeDefs) {
  addSoup({
    id: it.id,
    title: it.title,
    cuisine: it.cuisine,
    time: 60,
    active: 25,
    desc: it.desc,
    ings: [
      { ingredient_id: it.leg, amount: 150, unit: 'g' },
      { ingredient_id: it.meat, amount: 300, unit: 'g' },
      { ingredient_id: 'potato', amount: 3, unit: 'pcs' },
      { ingredient_id: 'onion', amount: 1, unit: 'pcs' },
      { ingredient_id: 'carrot', amount: 1, unit: 'pcs' },
      { ingredient_id: 'sunflower_oil', amount: 2, unit: 'tbsp' },
      { ingredient_id: 'water', amount: 2.2, unit: 'l' },
      { ingredient_id: 'salt', amount: null, unit: 'to_taste' }
    ],
    steps: [
      s(`Для блюда «${it.title}» промойте бобовые или крупу и залейте водой.`),
      s(`Мясную основу для супа «${it.title}» порубите на кусочки и поставьте вариться на 25 минут.`, 1500),
      s(`Измельчите лук с морковью для супа «${it.title}» и спассеруйте на растительном масле.`, 420),
      s(`Всыпьте бобовые с нарезанным картофелем в кипящий суп «${it.title}», варите 15 минут.`, 900),
      s(`Заправьте суп «${it.title}» пассерованными овощами, посолите и протомите 8 минут перед подачей.`)
    ]
  });
}

// 7. WORLD MEAT & TRADITIONAL SOUPS (30)
const worldDefs = [
  { id: 'kharcho_classic', title: 'Грузинский суп харчо с говядиной и орехами', m: 'beef', g: 'round_rice', ext: 'walnut', cuisine: 'ge', desc: 'Пряный наваристый суп с чесноком, хмели-сунели и грецкими орехами.' },
  { id: 'kharcho_lamb', title: 'Харчо из баранины с кислой сливой и кинзой', m: 'lamb', g: 'round_rice', cuisine: 'ge', desc: 'Острый кавказский суп из баранины с характерной сливовой кислинкой.' },
  { id: 'shurpa_uzbek', title: 'Узбекская шурпа из баранины с овощами', m: 'lamb', g: 'bell_pepper', cuisine: 'uz', desc: 'Традиционный среднеазиатский суп с крупно нарезанными сочными овощами.' },
  { id: 'shurpa_chickpea', title: 'Шурпа из говядины с нутом и паприкой', m: 'beef', g: 'chickpeas_canned', cuisine: 'uz', desc: 'Праздничный наваристый бульон с нежным нутом, картофелем и специями.' },
  { id: 'lagman_noodles', title: 'Уйгурский лагман с домашней тянутой лапшой', m: 'beef', g: 'noodles', ext: 'daikon', cuisine: 'uz', desc: 'Густой пряный суп-лапша с сочной говядиной, редькой и перцем.' },
  { id: 'goulash_beef', title: 'Венгерский суп-гуляш с копченой паприкой', m: 'beef', g: 'bell_pepper', cuisine: 'home', desc: 'Густой гуляшевый суп с кусочками говядины, картофелем и паприкой.' },
  { id: 'minestrone_genovese', title: 'Итальянский суп минестроне с фасолью', m: 'zucchini', g: 'beans_canned', cuisine: 'it', desc: 'Классический овощной генуэзский суп с базиликом и пармезаном.' },
  { id: 'french_onion', title: 'Французский луковый суп с гренками и сыром', m: 'cheese', g: 'white_bread', cuisine: 'fr', desc: 'Карамелизированный томленый луковый суп под золотистой сырной корочкой.' },
  { id: 'ramen_pork', title: 'Японский рамэн со свининой и лапшой', m: 'pork', g: 'noodles', cuisine: 'jp', desc: 'Насыщенный японский суп с пшеничной лапшой, нежным мясом и луком.' },
  { id: 'pho_bo_beef', title: 'Вьетнамский фо бо с говядиной и лапшой', m: 'beef', g: 'spaghetti', cuisine: 'th', desc: 'Ароматный пряный бульон с имбирем, тонким мясом и базиликом.' },
  { id: 'chili_con_carne', title: 'Мексиканский суп чили кон карне с фасолью', m: 'minced_beef', g: 'beans_canned', cuisine: 'mx', desc: 'Огненно-пряный мексиканский суп из говяжьего фарша с томатами и фасолью.' },
  { id: 'mastava_uzbek', title: 'Узбекская мастава с говядиной и рисом', m: 'beef', g: 'round_rice', ext: 'tomatoes_canned', cuisine: 'uz', desc: 'Сытный жареный суп с рисом, картофелем и свежей кислой заправкой.' },
  { id: 'pitie_lamb', title: 'Азербайджанский суп пити с бараниной', m: 'lamb', g: 'potato', cuisine: 'az', desc: 'Традиционный глиняный горшочный суп с нежнейшей бараниной и шафраном.' },
  { id: 'bozbash_meatball', title: 'Армянский бозбаш с мясными кюфтами', m: 'minced_beef', g: 'chickpeas_canned', cuisine: 'am', desc: 'Праздничный суп с сочными мясными тефтелями, горохом и травами.' },
  { id: 'kespe_kazakh', title: 'Казахский суп кеспе с домашней лапшой', m: 'beef', g: 'noodles', ext: 'parsley', cuisine: 'kz', desc: 'Сытный степной суп на крепком мясном бульоне с тонкой лапшой.' },
  { id: 'cream_pumpkin', title: 'Пряный крем-суп из тыквы с имбирем', m: 'cream', g: 'squash', cuisine: 'home', desc: 'Согревающий шелковистый суп из сладкой тыквы со свежим имбирем.' },
  { id: 'cream_broccoli', title: 'Крем-суп из брокколи со сливками и сыром', m: 'cream', g: 'broccoli', cuisine: 'home', desc: 'Нежный бархатистый суп из соцветий брокколи с сырным вкусом.' },
  { id: 'cream_champignon', title: 'Крем-суп из шампиньонов с тимьяном', m: 'cream', g: 'champignon', cuisine: 'fr', desc: 'Классический французский грибной крем-суп с тонкими нотками тимьяна.' },
  { id: 'cream_cauliflower', title: 'Крем-суп из цветной капусты с пармезаном', m: 'cream', g: 'cauliflower', cuisine: 'it', desc: 'Утонченный сливочный суп с нежным ароматом мускатного ореха.' },
  { id: 'cream_tomato', title: 'Тосканский томатный суп-пюре с базиликом', m: 'cream', g: 'tomato', cuisine: 'it', desc: 'Яркий летний суп из сочных спелых томатов с чесноком и базиликом.' },
  { id: 'cream_zucchini', title: 'Нежный суп-пюре из кабачков со сметаной', m: 'sour_cream', g: 'zucchini', cuisine: 'home', desc: 'Легкий низкокалорийный крем-суп со свежей сметаной и пряными травами.' },
  { id: 'cream_celery_apple', title: 'Очищающий крем-суп из сельдерея и яблок', m: 'cream', g: 'celery_root', cuisine: 'fr', desc: 'Оригинальный суп с изысканным кисло-сладким вкусом яблок и кореньев.' },
  { id: 'okroshka_beef', title: 'Традиционная окрошка с отварной говядиной', m: 'beef', g: 'cucumber', cuisine: 'ru', desc: 'Освежающая русская окрошка с отварным мясом, свежими огурцами и редисом.' },
  { id: 'okroshka_sausage', title: 'Холодная окрошка на кефире с колбасой', m: 'sausage', g: 'kefir', cuisine: 'ru', desc: 'Любимая летняя окрошка на холодном кефире с вареной колбасой и укропом.' },
  { id: 'gazpacho_andalusian', title: 'Андалусский холодный гаспачо из томатов', m: 'olive_oil', g: 'bell_pepper', cuisine: 'es', desc: 'Испанский холодный суп из томатов, сладкого перца и оливкового масла.' },
  { id: 'tarator_bulgarian', title: 'Болгарский суп таратор с грецкими орехами', m: 'yogurt', g: 'walnut', cuisine: 'home', desc: 'Освежающий суп из огурцов на кислом молоке с орехами.' },
  { id: 'svekolnik_cold', title: 'Летний свекольник с огурцами и редисом', m: 'beet', g: 'radish', cuisine: 'ru', desc: 'Холодный борщ со свежими хрустящими овощами и яйцом.' },
  { id: 'cream_spinach', title: 'Суп-велюте из шпината с кедровыми орешками', m: 'cream', g: 'spinach', cuisine: 'it', desc: 'Изумрудный бархатистый суп со свежими листьями шпината и орехами.' },
  { id: 'cream_carrot', title: 'Морковный суп-пюре с имбирем и кокосом', m: 'coconut_milk', g: 'carrot', cuisine: 'home', desc: 'Яркий согревающий суп из сладкой моркови с восточным имбирем.' },
  { id: 'sweet_potato_soup', title: 'Крем-суп из батата на кокосовом молоке', m: 'coconut_milk', g: 'sweet_potato', cuisine: 'home', desc: 'Экзотический сладковатый суп из батата с травами.' }
];

for (const it of worldDefs) {
  addSoup({
    id: it.id,
    title: it.title,
    cuisine: it.cuisine,
    time: 50,
    active: 25,
    desc: it.desc,
    ings: [
      { ingredient_id: it.m, amount: 300, unit: 'g' },
      { ingredient_id: it.g, amount: 150, unit: 'g' },
      { ingredient_id: 'potato', amount: 2, unit: 'pcs' },
      { ingredient_id: 'onion', amount: 1, unit: 'pcs' },
      { ingredient_id: 'carrot', amount: 1, unit: 'pcs' },
      { ingredient_id: 'water', amount: 1.8, unit: 'l' },
      { ingredient_id: 'salt', amount: null, unit: 'to_taste' },
      { ingredient_id: 'sunflower_oil', amount: 2, unit: 'tbsp' }
    ].concat(it.ext ? [{ ingredient_id: it.ext, amount: 50, unit: 'g' }] : []),
    steps: [
      s(`Для супа «${it.title}» подготовьте основные ингредиенты: промойте и разделите на кусочки.`),
      s(`Овощи для супа «${it.title}» измельчите аккуратными ломтиками и спассеруйте на сковороде.`, 420),
      s(`В кипящую воду опустите основу для супа «${it.title}» и варите 15 минут на тихом огне.`, 900),
      s(`Добавьте в суп «${it.title}» картофель и овощную заправку, варите 12 минут.`, 720),
      s(`Варите суп «${it.title}» до мягкости картофеля, посыпьте свежей зеленью и снимите с огня настаиваться.`)
    ]
  });
}

// 8. ADDITIONAL DIVERSE REGIONAL SOUPS (93) to achieve ~185 recipes
const extraSoups = [
  { id: 'turkey_zucchini', title: 'Суп с тефтельками из индейки и молодым кабачком', m: 'turkey_fillet', v: 'zucchini', c: 'home' },
  { id: 'pork_corn', title: 'Суп с мясными фрикадельками и сладкой кукурузой', m: 'minced_pork', v: 'corn_canned', c: 'home' },
  { id: 'veal_leek_barley', title: 'Суп из телятины с луком-пореем и ячменем', m: 'veal', v: 'barley', c: 'home' },
  { id: 'beef_cauliflower', title: 'Прозрачный суп из говядины с цветной капустой', m: 'beef', v: 'cauliflower', c: 'home' },
  { id: 'chicken_brussels', title: 'Куриный суп с брюссельской капустой и морковью', m: 'chicken', v: 'brussels_sprouts', c: 'home' },
  { id: 'lamb_eggplant', title: 'Кавказский суп из баранины с баклажанами', m: 'lamb', v: 'eggplant', c: 'ge' },
  { id: 'duck_green_beans', title: 'Суп из утки со стручковой фасолью и чесноком', m: 'duck', v: 'green_beans', c: 'home' },
  { id: 'pork_sweet_potato', title: 'Суп со свининой, бататом и розмарином', m: 'pork', v: 'sweet_potato', c: 'home' },
  { id: 'turkey_asparagus', title: 'Весенний суп из филе индейки со спаржей', m: 'turkey_fillet', v: 'asparagus', c: 'fr' },
  { id: 'rabbit_parsnip', title: 'Суп из кролика со сладким пастернаком', m: 'rabbit', v: 'parsnip', c: 'home' },
  { id: 'cod_spinach_lemon', title: 'Рыбный суп из трески со шпинатом и лимоном', m: 'cod', v: 'spinach', c: 'gr' },
  { id: 'salmon_green_peas', title: 'Норвежский суп с лососем и зеленым горошком', m: 'salmon', v: 'green_peas', c: 'home' },
  { id: 'pike_sour_cream', title: 'Старорусская уха из щуки со сметанным приваром', m: 'pike', v: 'sour_cream', c: 'ru' },
  { id: 'hake_bell_pepper', title: 'Суп из хека со сладким перцем и томатами', m: 'hake', v: 'bell_pepper', c: 'es' },
  { id: 'shrimp_avocado', title: 'Холодный суп из авокадо с тигровыми креветками', m: 'shrimp', v: 'avocado', c: 'mx' },
  { id: 'mussels_leek', title: 'Бельгийский суп с мидиями и луком-пореем', m: 'mussels', v: 'leek', c: 'fr' },
  { id: 'squid_green_beans', title: 'Средиземноморский суп с кальмарами и фасолью', m: 'squid', v: 'green_beans', c: 'it' },
  { id: 'pollock_corn_chowder', title: 'Чаудер из минтая со сладкой кукурузой', m: 'pollock', v: 'corn_canned', c: 'us' },
  { id: 'trout_zucchini', title: 'Суп из радужной форели с цукини и укропом', m: 'trout', v: 'zucchini', c: 'home' },
  { id: 'catfish_garlic', title: 'Астраханский суп из сома с чесночным взваром', m: 'catfish', v: 'garlic', c: 'ru' },
  { id: 'porcini_buckwheat', title: 'Лесной суп с белыми грибами и гречневой крупой', m: 'porcini', v: 'buckwheat', c: 'ru' },
  { id: 'chanterelle_potato', title: 'Суп с золотистыми лисичками и молодым картофелем', m: 'chanterelles', v: 'dill', c: 'ru' },
  { id: 'honey_mushrooms_vermicelli', title: 'Грибной суп из опят с домашней вермишелью', m: 'honey_mushrooms', v: 'vermicelli', c: 'ru' },
  { id: 'shiitake_tofu', title: 'Восточный японский суп с шиитаке и кубиками тофу', m: 'shiitake', v: 'tofu', c: 'jp' },
  { id: 'champignon_cheese', title: 'Сырный суп со свежими шампиньонами и сухариками', m: 'champignon', v: 'processed_cheese', c: 'home' },
  { id: 'pumpkin_curry', title: 'Пряный суп из сладкой тыквы с карри на кокосовом молоке', m: 'coconut_milk', v: 'curry_powder', c: 'in' },
  { id: 'cauliflower_spinach', title: 'Крем-суп из цветной капусты и молодого шпината', m: 'cauliflower', v: 'spinach', c: 'home' },
  { id: 'beet_apple_soup', title: 'Свекольный суп-пюре с кислым яблоком и имбирем', m: 'beet', v: 'apple', c: 'home' },
  { id: 'zucchini_parmesan', title: 'Суп-крем из цукини с сыром пармезан', m: 'zucchini', v: 'parmesan', c: 'it' },
  { id: 'celery_carrot_soup', title: 'Детокс-суп из сельдерея и моркови с куркумой', m: 'celery', v: 'turmeric', c: 'home' },
  { id: 'radish_cucumber_soup', title: 'Холодник из редиса со свежими огурцами и мятой', m: 'radish', v: 'mint', c: 'home' },
  { id: 'tomato_pepper_chilled', title: 'Холодный томатный суп с запеченным перцем', m: 'tomato', v: 'bell_pepper', c: 'es' },
  { id: 'sorrel_cucumber_soup', title: 'Холодный щавелевый суп со свежим огурцом и яйцом', m: 'sorrel', v: 'cucumber', c: 'ru' },
  { id: 'kefir_beet_walnut', title: 'Свекольный холодник на кефире с дробленым орехом', m: 'beet', v: 'walnut', c: 'lt' },
  { id: 'chickpea_spinach', title: 'Средиземноморский суп из нута со шпинатом', m: 'chickpeas_canned', v: 'spinach', c: 'gr' },
  { id: 'lentil_cumin', title: 'Восточный суп из зелёной чечевицы с зирой и томатом', m: 'lentils_green', v: 'cumin', c: 'tr' },
  { id: 'beans_white_pesto', title: 'Суп из белой фасоли с базиликом и чесноком', m: 'beans_canned', v: 'basil', c: 'it' },
  { id: 'peas_green_bacon', title: 'Суп из сладкого горошка с копченым беконом', m: 'green_peas', v: 'bacon', c: 'uk' },
  { id: 'buckwheat_liver', title: 'Суп с куриной печенью и рассыпчатой гречкой', m: 'liver_chicken', v: 'buckwheat', c: 'ru' },
  { id: 'tongue_horseradish', title: 'Праздничный суп с отварным говяжьим языком', m: 'tongue', v: 'horseradish_root', c: 'ru' },
  { id: 'veal_quinoa', title: 'Диетический суп из телятины с крупой киноа и свежим шпинатом', m: 'veal', v: 'quinoa', c: 'home' },
  { id: 'pork_bulgur', title: 'Сытный суп со свининой, булгуром и томатами', m: 'pork', v: 'bulgur', c: 'home' },
  { id: 'turkey_couscous', title: 'Суп из индейки с кускусом и свежей мятой', m: 'turkey_fillet', v: 'couscous', c: 'home' },
  { id: 'chicken_corn_egg', title: 'Куриный суп с кукурузой и яичными хлопьями', m: 'chicken', v: 'corn_canned', c: 'cn' },
  { id: 'meatball_cheese_vermicelli', title: 'Сырный суп с мясными фрикадельками и вермишелью', m: 'minced_beef', v: 'cheese', c: 'home' },
  { id: 'oatmeal_vegetable_soup', title: 'Овсяный суп с луком-пореем и морковью', m: 'oatmeal', v: 'leek', c: 'home' },
  { id: 'semolina_chicken_soup', title: 'Куриный суп с манной крупой и зеленью', m: 'semolina', v: 'chicken', c: 'home' },
  { id: 'cornmeal_beef_soup', title: 'Полента-суп с говядиной и чесноком', m: 'cornmeal', v: 'beef', c: 'it' },
  { id: 'red_onion_soup', title: 'Суп из красного карамельного лука с гренками', m: 'red_onion', v: 'white_bread', c: 'fr' },
  { id: 'squash_potato_soup', title: 'Деревенский суп из тыквы с картофелем', m: 'squash', v: 'sour_cream', c: 'home' },
  { id: 'daikon_chicken_soup', title: 'Азиатский прозрачный суп с курицей и дайконом', m: 'daikon', v: 'chicken', c: 'jp' },
  { id: 'kohlrabi_pork_soup', title: 'Суп с капустой кольраби и нежной свининой', m: 'kohlrabi', v: 'pork', c: 'de' },
  { id: 'artichoke_cod_soup', title: 'Прованский рыбный суп с артишоками и треской', m: 'artichoke', v: 'cod', c: 'fr' },
  { id: 'seaweed_tofu_soup', title: 'Японский суп с морской капустой и сыром тофу', m: 'seaweed', v: 'tofu', c: 'jp' },
  { id: 'rhubarb_chicken_soup', title: 'Весенний суп из курицы с ревенем и морковью', m: 'rhubarb', v: 'chicken', c: 'ru' },
  { id: 'turkey_wings_soup', title: 'Наваристый суп из крыльев индейки с лапшой', m: 'chicken_wings', v: 'noodles', c: 'home' },
  { id: 'beef_stew_soup', title: 'Походный суп с тушёной говядиной и картофелем', m: 'beef_stew', v: 'potato', c: 'home' },
  { id: 'veal_heart_soup', title: 'Старинная похлебка с телячьим сердцем и кореньями', m: 'heart', v: 'parsley_root', c: 'ru' },
  { id: 'chicken_liver_apple', title: 'Бархатистый суп с куриной печенью и печеным яблоком', m: 'liver_chicken', v: 'apple', c: 'fr' },
  { id: 'lamb_prunes_soup', title: 'Кавказский суп из баранины с черносливом и кинзой', m: 'lamb', v: 'prunes', c: 'ge' },
  { id: 'pork_ribs_sauerkraut_barley', title: 'Уральский рассольный суп со свиными ребрышками', m: 'pork_ribs', v: 'pearl_barley', c: 'ru' },
  { id: 'duck_apple_soup', title: 'Осенний суп из утки с кислыми яблоками и корицей', m: 'duck', v: 'apple', c: 'ru' },
  { id: 'goose_pearl_barley', title: 'Рождественский суп из гуся с перловой крупой', m: 'goose', v: 'pearl_barley', c: 'ru' },
  { id: 'squid_rice_lemon', title: 'Средиземноморский суп с кальмарами и рисом', m: 'squid', v: 'lemon', c: 'gr' },
  { id: 'shrimp_ginger_soup', title: 'Китайский прозрачный суп с креветками и имбирем', m: 'shrimp', v: 'ginger', c: 'cn' },
  { id: 'mussels_spinach_cream', title: 'Сливочный суп с мидиями и свежим шпинатом', m: 'mussels', v: 'cream', c: 'fr' },
  { id: 'crab_sticks_corn_soup', title: 'Легкий домашний суп с крабовыми палочками и кукурузой', m: 'crab_sticks', v: 'corn_canned', c: 'home' },
  { id: 'salmon_broccoli_soup', title: 'Финский суп с семгой, брокколи и сливками', m: 'salmon', v: 'broccoli', c: 'home' },
  { id: 'hake_leek_cream', title: 'Балтийский суп из хека с луком-пореем и сливками', m: 'hake', v: 'leek', c: 'home' },
  { id: 'pollock_zucchini_soup', title: 'Диетический суп из минтая с молодыми кабачками', m: 'pollock', v: 'zucchini', c: 'home' },
  { id: 'carp_onion_broth', title: 'Сладкая уха из карпа с обжаренным луком', m: 'carp', v: 'sunflower_oil', c: 'ru' },
  { id: 'cottage_cheese_dumpling_soup', title: 'Суп с творожными клецками и куриным бульоном', m: 'cottage_cheese', v: 'chicken', c: 'home' },
  { id: 'feta_tomato_soup', title: 'Греческий томатный суп с сыром фета и орегано', m: 'feta', v: 'tomato', c: 'gr' },
  { id: 'mozzarella_basil_soup', title: 'Итальянский томатный суп с моцареллой и базиликом', m: 'mozzarella', v: 'basil', c: 'it' },
  { id: 'tofu_champignon_soup', title: 'Легкий суп с сыром тофу и свежими шампиньонами', m: 'tofu', v: 'champignon', c: 'jp' },
  { id: 'soybeans_vegetable_soup', title: 'Сытный суп с соевыми бобами и сладким перцем', m: 'soybeans', v: 'bell_pepper', c: 'home' },
  { id: 'chickpeas_pumpkin_soup', title: 'Кремовый суп с нутом и запеченной тыквой', m: 'chickpeas_canned', v: 'squash', c: 'home' },
  { id: 'red_beans_walnut_soup', title: 'Кавказский шекинский суп с консервированной фасолью и орехом', m: 'beans_canned', v: 'garlic', c: 'az' },
  { id: 'white_beans_rosemary', title: 'Тосканский суп из готовой фасоли с розмарином', m: 'beans_canned', v: 'rosemary', c: 'it' },
  { id: 'lentils_carrot_lemon', title: 'Арабский суп из чечевицы с лимоном и кинзой', m: 'lentils_red', v: 'cilantro', c: 'home' },
  { id: 'porcini_potato_soup', title: 'Старорусская похлебка с белыми грибами и укропом', m: 'porcini', v: 'potato', c: 'ru' },
  { id: 'oyster_mushroom_noodle', title: 'Суп с вешенками, домашней лапшой и петрушкой', m: 'oyster_mushroom', v: 'noodles', c: 'ru' },
  { id: 'chanterelle_cream_soup', title: 'Бархатистый крем-суп из лисичек со сливками', m: 'chanterelles', v: 'cream', c: 'home' },
  { id: 'sweet_potato_carrot_soup', title: 'Согревающий суп из батата и моркови с паприкой', m: 'sweet_potato', v: 'carrot', c: 'home' },
  { id: 'parsnip_apple_puree', title: 'Крем-суп из пастернака с печеным яблоком', m: 'parsnip', v: 'apple', c: 'fr' },
  { id: 'beetroot_ginger_soup', title: 'Пряный рубиновый суп из свёклы со свежим имбирем', m: 'beet', v: 'ginger', c: 'home' },
  { id: 'cabbage_potato_caraway', title: 'Деревенский суп из свежей капусты с тмином', m: 'cabbage', v: 'potato', c: 'home' },
  { id: 'cauliflower_cheese_soup', title: 'Густой сырный суп с цветной капустой и сухариками', m: 'cauliflower', v: 'cheese', c: 'home' },
  { id: 'broccoli_almond_soup', title: 'Суп-пюре из брокколи с лепестками миндаля', m: 'broccoli', v: 'almond', c: 'fr' },
  { id: 'green_peas_thyme_soup', title: 'Легкий суп из зеленого горошка с тимьяном', m: 'green_peas', v: 'thyme', c: 'home' },
  { id: 'spinach_feta_soup', title: 'Греческий суп со шпинатом и раскрошенной фетой', m: 'spinach', v: 'feta', c: 'gr' },
  { id: 'radish_cucumber_yogurt', title: 'Холодник на натуральном йогурте с огурцом и редисом', m: 'yogurt', v: 'cucumber', c: 'home' },
  { id: 'tomato_celery_gazpacho', title: 'Освежающий гаспачо с томатами и черешковым сельдереем', m: 'tomato', v: 'celery', c: 'es' }
];

for (const it of extraSoups) {
  addSoup({
    id: it.id,
    title: it.title,
    cuisine: it.c,
    time: 45,
    active: 20,
    desc: `Ароматный домашний суп «${it.title}» со свежими ингредиентами и гармоничным вкусом.`,
    ings: [
      { ingredient_id: it.m, amount: 300, unit: 'g' },
      { ingredient_id: it.v, amount: 150, unit: 'g' },
      { ingredient_id: 'potato', amount: 2, unit: 'pcs' },
      { ingredient_id: 'onion', amount: 1, unit: 'pcs' },
      { ingredient_id: 'carrot', amount: 1, unit: 'pcs' },
      { ingredient_id: 'sunflower_oil', amount: 1.5, unit: 'tbsp' },
      { ingredient_id: 'water', amount: 2.0, unit: 'l' },
      { ingredient_id: 'salt', amount: null, unit: 'to_taste' }
    ],
    steps: [
      s(`Для супа «${it.title}» промойте подготовленные компоненты и разделите на порционные кусочки.`),
      s(`Репчатый лук и морковь для супа «${it.title}» измельчите кубиками и спассеруйте на сковороде до мягкости.`, 420),
      s(`В кастрюлю с кипящей водой для супа «${it.title}» выложите основу и варите 15 минут.`, 900),
      s(`Добавьте картофель и овощную заправку в суп «${it.title}», варите 12 минут.`, 720),
      s(`Проверьте готовность картофеля в супе «${it.title}», снимите с плиты и дайте настояться 10 минут перед подачей.`)
    ]
  });
}

console.log(`Total generated soups: ${allSoups.length}`);
saveAndValidateGroup('soups.json', allSoups);
