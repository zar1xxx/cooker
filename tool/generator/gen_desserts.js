const { saveAndValidateGroup, smartIngredient } = require('./recipe_builder');

function s(text, timer_seconds, tip) {
  const step = { text: text.trim() };
  if (timer_seconds) step.timer_seconds = timer_seconds;
  if (tip) step.tip = tip;
  return step;
}

const allDesserts = [];

function addDessert(def) {
  const id = `des_${def.id}`;
  const title = def.title;
  const time = def.time || 30;
  const active = def.active || 15;
  const servings = def.servings || 4;
  const cuisine = def.cuisine || 'home';
  const desc = def.desc || `Нежный домашний десерт «${title}» к чаю или праздничному столу.`;

  const ingsMap = new Map();
  for (const raw of def.ings) {
    const rawId = raw.ingredient_id || raw.id || raw;
    const ingObj = smartIngredient(rawId, raw.amount, raw.unit);
    ingsMap.set(rawId, ingObj);
  }
  const ings = Array.from(ingsMap.values());

  const hasEgg = ingsMap.has('egg');
  let heatVerb = def.verb || 'подготовьте основу и соедините компоненты';
  let heatSec = def.heatSec || 0;
  if (hasEgg) {
    if (!['вар', 'жар', 'запек'].some(k => heatVerb.toLowerCase().includes(k))) {
      heatVerb = 'запекайте в духовке или варите на водяной бане';
    }
    if (heatSec < 300) heatSec = 600;
  }

  const heatMin = Math.ceil((heatSec || 300) / 60);

  const steps = def.steps || (
    def.mode === 'cold'
      ? [
          s(`Для десерта «${title}» подготовьте все фрукты, ягоды, молочную или сладкую основу.`),
          s(`Тщательно взбейте или аккуратно перемешайте базовую массу для «${title}» до гладкой однородной текстуры.`),
          s(`Выложите слоями или распределите смесь для «${title}» по креманкам, стаканам или форме.`),
          s(`Охладите десерт «${title}» в холодильнике, затем украсьте перед подачей на стол.`, def.chillSec || 1200)
        ]
      : [
          s(`Для десерта «${title}» отмерьте все компоненты и подготовьте форму или сотейник.`),
          s(`Соедините базовые продукты${hasEgg ? ' с яйцом' : ''} и перемешайте массу для «${title}» до однородности.`),
          s(`${heatVerb.charAt(0).toUpperCase() + heatVerb.slice(1)} десерт «${title}» в течение ${heatMin} минут до нужной консистенции.`, heatSec || 600),
          s(`Остудите готовый десерт «${title}» до комфортной температуры и подавайте к чаю.`)
        ]
  );

  allDesserts.push({
    id: id,
    title: title,
    dish_type: 'dessert',
    dish_group: 'dessert',
    cuisine: cuisine,
    total_minutes: Math.max(time, Math.ceil((heatSec || 0) / 60) + 15),
    active_minutes: active,
    servings: servings,
    description: desc,
    ingredients: ings,
    steps: steps
  });
}

// 1. Creamy, Panna Cotta, Trifles, Cheesecakes & Custards (35) - no raw egg!
const creamyList = [
  { id: 'pannacotta_vanilla_berry_coulis', title: 'Итальянская сливочная панна-котта с малиновым соусом', m: 'cream', a: 'raspberry', b: 'vanilla_sugar', d: 'sugar', e: 'milk', c: 'it', verb: 'прогрейте сливки на тихом огне', mode: 'warm', heatSec: 360 },
  { id: 'pannacotta_coconut_pineapple', title: 'Экзотическая панна-котта на кокосовом молоке с ананасом', m: 'coconut_milk', a: 'pineapple', b: 'vanilla', d: 'sugar', e: 'lime', c: 'home', mode: 'cold' },
  { id: 'pannacotta_sour_cream_cherry', title: 'Нежное сметанное бланманже с кисло-сладким вишневым соусом', m: 'sour_cream', a: 'cherry', b: 'milk', d: 'sugar', e: 'vanilla_sugar', c: 'ru', mode: 'cold' },
  { id: 'tiramisu_cookies_cream_cheese_cocoa', title: 'Домашний десерт Тирамису из печенья со сливочным сыром и какао', m: 'cookies', a: 'cream_cheese', b: 'cream', d: 'cocoa', e: 'vanilla', c: 'it', mode: 'cold' },
  { id: 'trifle_chocolate_banana_caramel', title: 'Слоеный шоколадный трайфл в стакане с бананом и карамелью', m: 'cookies', a: 'banana', b: 'caramel', d: 'chocolate', e: 'cream', c: 'uk', mode: 'cold' },
  { id: 'trifle_strawberry_yogurt_granola', title: 'Легкий трайфл со свежей клубникой, йогуртом и хрустящими хлопьями', m: 'strawberry', a: 'yogurt', b: 'rolled_oats', d: 'honey', e: 'mint', c: 'home', mode: 'cold' },
  { id: 'cheesecake_no_bake_blueberry_lemon', title: 'Чизкейк без выпечки из сливочного сыра с голубикой и лимоном', m: 'cream_cheese', a: 'blueberry', b: 'cookies', d: 'butter', e: 'lemon', c: 'us', mode: 'cold' },
  { id: 'cheesecake_no_bake_cottage_peach', title: 'Нежный творожный чизкейк с персиками на песочной крошке', m: 'cottage_cheese', a: 'peach', b: 'cookies', d: 'butter', d2: 'cream', e: 'vanilla_sugar', c: 'home', mode: 'cold' },
  { id: 'cheesecake_baked_pumpkin_cinnamon', title: 'Запеченный тыквенный чизкейк с пряной корицей и сметаной', m: 'cream_cheese', a: 'squash', b: 'egg', d: 'cinnamon', e: 'sour_cream', c: 'us', verb: 'запекайте в форме в духовке', heatSec: 2400 },
  { id: 'creme_brulee_baked_custard_vanilla', title: 'Классический запеченный крем-брюле со сливками и ванилью', m: 'cream', a: 'egg', b: 'sugar', d: 'vanilla', e: 'milk', c: 'fr', verb: 'запекайте на водяной бане в духовке', heatSec: 2100 },
  { id: 'sabayon_berry_cooked_cream', title: 'Теплый французский крем сабайон с ежевикой и свежей мятой', m: 'egg', a: 'blackberry', b: 'sugar', d: 'cream', e: 'mint', c: 'fr', verb: 'варите крем на водяной бане при постоянном взбивании', heatSec: 420 },
  { id: 'ptichye_moloko_chocolate_glaze', title: 'Домашнее суфле Птичье молоко под глянцевой шоколадной глазурью', m: 'cottage_cheese', a: 'chocolate', b: 'butter', d: 'cream', e: 'condensed_milk', c: 'ru', mode: 'cold' },
  { id: 'paskha_tsarskaya_cottage_raisins', title: 'Сливочная творожная пасха с изюмом, курагой и миндалем', m: 'cottage_cheese', a: 'butter', b: 'cream', d: 'raisins', e: 'dried_apricots', c: 'ru', mode: 'cold' },
  { id: 'paskha_chocolate_hazelnut', title: 'Шоколадная творожная пасха с тертым шоколадом и фундуком', m: 'cottage_cheese', a: 'chocolate', b: 'hazelnut', d: 'sour_cream', e: 'butter', c: 'ru', mode: 'cold' },
  { id: 'cottage_terrine_currant_black', title: 'Слоеный творожный террин с протертой черной смородиной', m: 'cottage_cheese', a: 'currant_black', b: 'yogurt', d: 'honey', e: 'cookies', c: 'home', mode: 'cold' },
  { id: 'syrok_glazed_cottage_vanilla', title: 'Домашние глазированные творожные сырки в темном шоколаде', m: 'cottage_cheese', a: 'chocolate', b: 'butter', d: 'condensed_milk', e: 'vanilla_sugar', c: 'ru', mode: 'cold' },
  { id: 'syrok_glazed_cottage_coconut', title: 'Творожные сырки в молочной глазури с кокосовой стружкой', m: 'cottage_cheese', a: 'coconut_flakes', b: 'butter', d: 'condensed_milk', e: 'chocolate', c: 'ru', mode: 'cold' },
  { id: 'pudding_chocolate_starch_silky', title: 'Шелковистый шоколадный пудинг на молоке и кукурузном крахмале', m: 'milk', a: 'chocolate', b: 'cocoa', d: 'starch', e: 'butter', c: 'home', verb: 'варите до загустения на медленном огне', heatSec: 420 },
  { id: 'pudding_vanilla_caramel_starch', title: 'Нежный ванильный пудинг под густым карамельным соусом', m: 'milk', a: 'starch', b: 'caramel', d: 'vanilla', e: 'butter', c: 'de', verb: 'варите крем до густоты на слабом огне', heatSec: 420 },
  { id: 'pudding_chia_oatmeal_mango_coconut', title: 'Кокосовый пудинг с хлопьями, персиком и сладким сиропом', m: 'coconut_milk', a: 'rolled_oats', b: 'peach', d: 'syrup', e: 'almond', c: 'home', mode: 'cold' },
  { id: 'pudding_semolina_orange_almond', title: 'Восточный манный пудинг с апельсиновой цедрой и миндалем', m: 'semolina', a: 'milk', b: 'orange', d: 'almond', e: 'honey', c: 'tr', verb: 'варите до густоты на слабом огне', heatSec: 480 },
  { id: 'pudding_bread_butter_baked_raisins', title: 'Английский запеченный хлебный пудинг с изюмом и корицей', m: 'white_bread', a: 'milk', b: 'egg', d: 'raisins', e: 'cinnamon', c: 'uk', verb: 'запекайте в разогретой духовке', heatSec: 1800 },
  { id: 'pudding_tapioca_millet_sweet_pumpkin', title: 'Кремовый десертный пудинг из пшена на кокосовом молоке с тыквой', m: 'millet', a: 'coconut_milk', b: 'squash', d: 'honey', e: 'cardamom', c: 'home', verb: 'варите до нежной кремовой текстуры', heatSec: 1200 },
  { id: 'parfait_yogurt_blackberry_cashew', title: 'Воздушный йогуртовый парфе с ежевикой, медом и кешью', m: 'yogurt', a: 'blackberry', b: 'honey', d: 'cashew', e: 'mint', c: 'home', mode: 'cold' },
  { id: 'parfait_kefir_berry_jam_biscuit', title: 'Быстрый десерт из ряженки с вареньем и рассыпчатым печеньем', m: 'curdled_milk', a: 'jam', b: 'cookies', d: 'walnut', e: 'cinnamon', c: 'ru', mode: 'cold' },
  { id: 'flan_baked_condensed_milk_caramel', title: 'Латиноамериканский запеченный флан на сгущенке и молоке', m: 'condensed_milk', a: 'milk', b: 'egg', d: 'caramel', e: 'vanilla', c: 'es', verb: 'запекайте в форме на водяной бане', heatSec: 2400 },
  { id: 'catalan_cream_orange_cinnamon', title: 'Испанский каталонский крем с корицей и цедрой апельсина', m: 'milk', a: 'egg', b: 'starch', d: 'orange', e: 'cinnamon', c: 'es', verb: 'варите на слабом огне до густого заварного крема', heatSec: 480 },
  { id: 'gingerbread_cake_sour_cream_banana', title: 'Торт без выпечки из шоколадных пряников со сметаной и бананом', m: 'gingerbread', a: 'sour_cream', b: 'banana', d: 'walnut', e: 'chocolate', c: 'ru', mode: 'cold' },
  { id: 'cookie_house_cottage_cheese_banana', title: 'Домик из печенья с творожным кремом, бананом и глазурью', m: 'cookies', a: 'cottage_cheese', b: 'banana', d: 'butter', e: 'cocoa', c: 'ru', mode: 'cold' },
  { id: 'marshmallow_cake_kiwi_strawberry', title: 'Праздничный торт без выпечки из зефира со сливками и киви', m: 'marshmallow', a: 'cream', b: 'kiwi', d: 'strawberry', e: 'cookies', c: 'ru', mode: 'cold' },
  { id: 'waffle_cake_condensed_milk_peanut', title: 'Хрустящий десертный торт из печенья с вареной сгущенкой и арахисом', m: 'cookies', a: 'condensed_milk', b: 'butter', d: 'peanut', e: 'chocolate', c: 'ru', mode: 'cold' },
  { id: 'prunes_walnut_sour_cream_classic', title: 'Классический чернослив, начиненный орехами под сметанным кремом', m: 'prunes', a: 'walnut', b: 'sour_cream', d: 'honey', e: 'chocolate', c: 'ru', mode: 'cold' },
  { id: 'dates_cream_cheese_pistachio', title: 'Сладкие финики со сливочным сыром, медом и фисташкой', m: 'dates', a: 'cream_cheese', b: 'pistachio', d: 'honey', e: 'orange', c: 'home', mode: 'cold' },
  { id: 'baked_alaska_apple_souffle_egg', title: 'Воздушное яблочно-белковое суфле в формочках из духовки', m: 'apple', a: 'egg', b: 'sugar', d: 'cinnamon', e: 'butter', c: 'fr', verb: 'запекайте в разогретой духовке до подъема', heatSec: 900 },
  { id: 'cottage_milk_custard_berry', title: 'Заварной творожно-яичный крем с малиной и сахарной пудрой', m: 'cottage_cheese', a: 'egg', b: 'milk', d: 'raspberry', e: 'vanilla_sugar', c: 'home', verb: 'запекайте в формочках на водяной бане', heatSec: 1200 }
];

for (const it of creamyList) {
  addDessert({
    id: it.id,
    title: it.title,
    cuisine: it.c,
    time: it.mode === 'cold' ? 25 : 40,
    active: 15,
    mode: it.mode,
    verb: it.verb,
    heatSec: it.heatSec,
    ings: [it.m, it.a, it.b, it.d, it.e, ...(it.d2 ? [it.d2] : [])]
  });
}

// 2. Baked, Caramelized & Warm Fruit Desserts (30)
const warmFruits = [
  { id: 'baked_apples_prunes_walnut_honey', title: 'Запеченные яблоки с черносливом, орехами и душистым медом', m: 'apple', a: 'prunes', b: 'walnut', d: 'honey', e: 'cinnamon', c: 'ru', verb: 'запекайте в духовке', heatSec: 1500 },
  { id: 'baked_apples_berries_oat_crunch', title: 'Печеные яблоки под хрустящей овсяной посыпкой с клюквой', m: 'apple', a: 'oatmeal', b: 'cranberry', d: 'butter', e: 'honey', c: 'home', verb: 'запекайте в духовке', heatSec: 1500 },
  { id: 'baked_pears_chocolate_almond', title: 'Ароматные груши в духовке с миндалем и темным шоколадом', m: 'pear', a: 'chocolate', b: 'almond', d: 'butter', e: 'cinnamon', c: 'fr', verb: 'запекайте в форме', heatSec: 1500 },
  { id: 'baked_pears_ricotta_cranberry', title: 'Половинки печеных груш со сливочным сыром и клюквенным сиропом', m: 'pear', a: 'cream_cheese', b: 'cranberry', d: 'syrup', e: 'walnut', c: 'it', verb: 'запекайте в духовке', heatSec: 1500 },
  { id: 'poached_pears_spiced_plum_syrup', title: 'Пряные томленые груши в сливово-пряном сиропе с гвоздикой', m: 'pear', a: 'plum', b: 'cinnamon', d: 'cloves', e: 'honey', c: 'fr', verb: 'варите груши на тихом огне', heatSec: 1200 },
  { id: 'caramelized_banana_butter_cream', title: 'Карамелизированные на сковороде бананы с пломбиром и орехами', m: 'banana', a: 'butter', b: 'ice_cream', d: 'walnut', e: 'caramel', c: 'us', verb: 'обжаривайте бананы до карамельной корочки', heatSec: 360 },
  { id: 'caramelized_pineapple_coconut_lime', title: 'Жареный ананас в карамельном масле с лаймом и кокосом', m: 'pineapple', a: 'lime', b: 'coconut_flakes', d: 'butter', e: 'honey', c: 'th', verb: 'обжаривайте кольца на сковороде', heatSec: 480 },
  { id: 'baked_peaches_hazelnut_honey', title: 'Сочные персики на гриле или в духовке с фундуком и медом', m: 'peach', a: 'hazelnut', b: 'honey', d: 'butter', e: 'yogurt', c: 'it', verb: 'запекайте половинки персиков', heatSec: 900 },
  { id: 'baked_plums_cottage_oat_crisp', title: 'Теплый сливовый крамбл с творогом, корицей и хлопьями', m: 'plum', a: 'cottage_cheese', b: 'rolled_oats', d: 'cinnamon', e: 'butter', c: 'home', verb: 'запекайте в духовке', heatSec: 1500 },
  { id: 'baked_figs_cheese_thyme_honey', title: 'Праздничный десерт из печеного инжира со сливочным сыром', m: 'fig', a: 'cream_cheese', b: 'honey', d: 'walnut', e: 'thyme', c: 'gr', verb: 'запекайте инжир в форме', heatSec: 720 },
  { id: 'crumble_rhubarb_strawberry_almond', title: 'Теплый английский крамбл с ревенем, клубникой и миндалем', m: 'rhubarb', a: 'strawberry', b: 'almond', d: 'butter', e: 'flour', c: 'uk', verb: 'запекайте до румяной крошки', heatSec: 1500 },
  { id: 'crumble_cherry_chocolate_oats', title: 'Шоколадно-вишневый крамбл с овсяной крошкой и пломбиром', m: 'cherry', a: 'chocolate', b: 'rolled_oats', d: 'ice_cream', e: 'butter', c: 'uk', verb: 'запекайте в духовке', heatSec: 1500 },
  { id: 'crumble_apple_pear_hazelnut', title: 'Хрустящий яблочно-грушевый крамбл с жареным фундуком', m: 'apple', a: 'pear', b: 'hazelnut', d: 'oatmeal', e: 'butter', c: 'home', verb: 'запекайте под хрустящей шапкой', heatSec: 1500 },
  { id: 'crumble_peach_raspberry_coconut', title: 'Ароматный летний крамбл с персиком, малиной и кокосом', m: 'peach', a: 'raspberry', b: 'coconut_flakes', d: 'rolled_oats', e: 'butter', c: 'home', verb: 'запекайте до золотистой крошки', heatSec: 1380 },
  { id: 'baked_pumpkin_honey_cranberry', title: 'Сладкая печеная тыква дольками с медом, клюквой и корицей', m: 'squash', a: 'honey', b: 'cranberry', d: 'cinnamon', e: 'pumpkin_seeds', c: 'ru', verb: 'запекайте ломтики тыквы', heatSec: 1800 },
  { id: 'baked_persimmon_walnut_yogurt', title: 'Теплая печеная хурма с грецким орехом и густым йогуртом', m: 'persimmon', a: 'walnut', b: 'yogurt', d: 'honey', e: 'cinnamon', c: 'ge', verb: 'запекайте хурму до мягкости', heatSec: 900 },
  { id: 'baked_grapefruit_honey_mint', title: 'Карамелизованный грейпфрут в духовке с медом и корицей', m: 'grapefruit', a: 'honey', b: 'cinnamon', d: 'mint', e: 'butter', c: 'home', verb: 'запекайте под верхним жаром', heatSec: 600 },
  { id: 'baked_apricots_almond_sour_cream', title: 'Запеченные половинки абрикосов с миндальной посыпкой и сметаной', m: 'apricot', a: 'almond', b: 'sour_cream', d: 'honey', e: 'vanilla_sugar', c: 'home', verb: 'запекайте в духовке', heatSec: 900 },
  { id: 'baked_grapes_lemon_rosemary', title: 'Томленый сладкий виноград в духовке с лимонным кремом и сыром', m: 'grape', a: 'cream_cheese', b: 'lemon', d: 'honey', e: 'cookies', c: 'it', verb: 'запекайте виноград с медом', heatSec: 900 },
  { id: 'fried_apples_honey_pancake_rings', title: 'Румяные дольки яблок на сковороде с корицей и мороженым', m: 'apple', a: 'butter', b: 'cinnamon', d: 'ice_cream', e: 'honey', c: 'de', verb: 'обжаривайте ломтики на сливочном масле', heatSec: 480 },
  { id: 'gajar_halwa_carrot_milk_cardamom', title: 'Восточный сладкий десерт из моркови в молоке с кардамоном', m: 'carrot', a: 'milk', b: 'butter', d: 'cardamom', e: 'cashew', c: 'in', verb: 'варите тертую морковь в молоке', heatSec: 1500 },
  { id: 'sweet_pumpkin_coconut_tapioca', title: 'Теплый тыквенно-рисовый десерт на кокосовом молоке с корицей', m: 'squash', a: 'round_rice', b: 'coconut_milk', d: 'cinnamon', e: 'raisins', c: 'th', verb: 'варите до мягкости крупы', heatSec: 1200 },
  { id: 'blueberry_cobbler_biscuit_top', title: 'Ароматный ягодный коблер с голубикой под нежной корочкой', m: 'blueberry', a: 'flour', b: 'butter', d: 'milk', e: 'lemon', c: 'us', verb: 'запекайте в духовке', heatSec: 1500 },
  { id: 'blackberry_apple_crisp_warm', title: 'Теплый десерт с ежевикой, яблоками и хрустящей крошкой', m: 'blackberry', a: 'apple', b: 'rolled_oats', d: 'butter', e: 'vanilla_sugar', c: 'home', verb: 'запекайте в керамической форме', heatSec: 1500 },
  { id: 'gooseberry_custard_baked_pot', title: 'Запеченный крыжовник с медом, яйцом и нежной сметанной шапкой', m: 'gooseberry', a: 'sour_cream', b: 'egg', d: 'honey', e: 'almond', c: 'ru', verb: 'запекайте в формочках в духовке', heatSec: 1200 },
  { id: 'cherry_meringue_egg_custard', title: 'Французский вишневый десерт флогнард с ванилью в духовке', m: 'cherry', a: 'egg', b: 'milk', d: 'flour', e: 'vanilla_sugar', c: 'fr', verb: 'запекайте до легкого румянца', heatSec: 1620 },
  { id: 'sweet_cornmeal_berry_polenta', title: 'Теплый сладкий пудинг из кукурузной крупы с малиной и медом', m: 'cornmeal', a: 'milk', b: 'raspberry', d: 'honey', e: 'butter', c: 'it', verb: 'варите кашу на молоке до нежности', heatSec: 900 },
  { id: 'fondue_chocolate_banana_strawberry', title: 'Домашнее шоколадное фондю со сливками, клубникой и бананом', m: 'chocolate', a: 'cream', b: 'strawberry', d: 'banana', e: 'marshmallow', c: 'fr', verb: 'растапливайте шоколад со сливками на слабом огне', heatSec: 360 },
  { id: 'poached_apricots_cinnamon_yogurt', title: 'Пряные томленые абрикосы в сиропе с густым йогуртом', m: 'apricot', a: 'syrup', b: 'yogurt', d: 'cinnamon', e: 'pistachio', c: 'home', verb: 'варите абрикосы в сиропе', heatSec: 480 },
  { id: 'baked_banana_chocolate_boat', title: 'Запеченные банановые лодочки с шоколадом, зефиром и орехом', m: 'banana', a: 'chocolate', b: 'marshmallow', d: 'peanut', e: 'cinnamon', c: 'us', verb: 'запекайте в духовке до расплавления', heatSec: 600 }
];

for (const it of warmFruits) {
  addDessert({
    id: it.id,
    title: it.title,
    cuisine: it.c,
    time: 35,
    active: 15,
    mode: 'warm',
    verb: it.verb,
    heatSec: it.heatSec,
    ings: [it.m, it.a, it.b, it.d, it.e]
  });
}

// 3. Mousses, Ice Creams, Sorbets & Fruit Salads (35) - no eggs!
const coldFruitMousse = [
  { id: 'mousse_cranberry_semolina_russian', title: 'Традиционный русский клюквенный мусс на манке со взбитой пенкой', m: 'cranberry', a: 'semolina', b: 'sugar', d: 'water', e: 'vanilla_sugar', c: 'ru', verb: 'варите отвар с манкой и взбивайте', mode: 'warm', heatSec: 420 },
  { id: 'mousse_currant_red_semolina', title: 'Воздушный мусс из красной смородины на манной крупе', m: 'currant_red', a: 'semolina', b: 'sugar', d: 'water', e: 'mint', c: 'ru', verb: 'варите и остудите перед взбиванием', mode: 'warm', heatSec: 420 },
  { id: 'mousse_avocado_chocolate_cocoa', title: 'Веганский шелковистый шоколадный мусс из спелого авокадо', m: 'avocado', a: 'cocoa', b: 'honey', d: 'banana', e: 'vanilla', c: 'home', mode: 'cold' },
  { id: 'mousse_cottage_strawberry_mint', title: 'Воздушный ягодный мусс из творога с клубникой и мятой', m: 'cottage_cheese', a: 'strawberry', b: 'milk', d: 'honey', e: 'mint', c: 'home', mode: 'cold' },
  { id: 'mousse_raspberry_white_cream', title: 'Нежный малиново-сливочный мусс с лимонной кислинкой', m: 'raspberry', a: 'cream', b: 'lemon', d: 'condensed_milk', e: 'vanilla', c: 'fr', mode: 'cold' },
  { id: 'mousse_peach_yogurt_cardamom', title: 'Бархатный персиковый мусс на йогурте с щепоткой кардамона', m: 'peach', a: 'yogurt', b: 'cardamom', d: 'honey', e: 'almond', c: 'home', mode: 'cold' },
  { id: 'ice_cream_strawberry_condensed_cream', title: 'Домашнее клубничное мороженое из сливок и сгущенного молока', m: 'strawberry', a: 'cream', b: 'condensed_milk', d: 'vanilla', e: 'lemon', c: 'home', mode: 'cold' },
  { id: 'ice_cream_pistachio_cream_honey', title: 'Сливочное фисташковое мороженое в домашней морозилке', m: 'cream', a: 'pistachio', b: 'condensed_milk', d: 'milk', e: 'vanilla', c: 'it', mode: 'cold' },
  { id: 'ice_cream_chocolate_caramel_walnut', title: 'Домашнее шоколадно-карамельное мороженое с грецким орехом', m: 'chocolate', a: 'cream', b: 'caramel', d: 'walnut', e: 'cocoa', c: 'us', mode: 'cold' },
  { id: 'ice_cream_cherry_yogurt_frozen', title: 'Освежающий вишневый замороженный йогурт с кусочками шоколада', m: 'cherry', a: 'yogurt', b: 'honey', d: 'chocolate', e: 'vanilla', c: 'home', mode: 'cold' },
  { id: 'ice_cream_banana_peanut_butter', title: 'Сливочно-банановое мороженое с арахисом и медом', m: 'banana', a: 'peanut', b: 'honey', d: 'cocoa', e: 'milk', c: 'us', mode: 'cold' },
  { id: 'ice_cream_halva_sesame_creamy', title: 'Восточное мороженое со вкусом халвы, сливок и кунжута', m: 'halva', a: 'cream', b: 'condensed_milk', d: 'sesame', e: 'vanilla', c: 'tr', mode: 'cold' },
  { id: 'sorbet_watermelon_lime_mint', title: 'Освежающий летний арбузный сорбет с соком лайма и мятой', m: 'watermelon', a: 'lime', b: 'mint', d: 'honey', e: 'strawberry', c: 'home', mode: 'cold' },
  { id: 'sorbet_melon_orange_ginger', title: 'Ароматный дынный сорбет с апельсиновым соком и мятой', m: 'melon', a: 'orange', b: 'mint', d: 'honey', e: 'lemon', c: 'home', mode: 'cold' },
  { id: 'sorbet_raspberry_lemon_mint', title: 'Яркий кисло-сладкий малиновый сорбет с лимоном без молока', m: 'raspberry', a: 'lemon', b: 'sugar', d: 'water', e: 'mint', c: 'fr', mode: 'cold' },
  { id: 'sorbet_currant_black_apple', title: 'Витаминный сорбет из черной смородины с яблочным пюре', m: 'currant_black', a: 'apple', b: 'honey', d: 'lemon', e: 'mint', c: 'ru', mode: 'cold' },
  { id: 'sorbet_kiwi_pineapple_lime', title: 'Тропический зеленый сорбет из киви со спелым ананасом и лаймом', m: 'kiwi', a: 'pineapple', b: 'lime', d: 'honey', e: 'mint', c: 'home', mode: 'cold' },
  { id: 'fruit_salad_watermelon_melon_mint', title: 'Освежающий летний салат из арбуза и дыни с лаймом и мятой', m: 'watermelon', a: 'melon', b: 'mint', d: 'lime', e: 'honey', c: 'home', mode: 'cold' },
  { id: 'fruit_salad_citrus_pomegranate', title: 'Зимний цитрусовый салат с апельсином, грейпфрутом и гранатом', m: 'orange', a: 'grapefruit', b: 'pomegranate', d: 'honey', e: 'mint', c: 'home', mode: 'cold' },
  { id: 'fruit_salad_berry_yogurt_poppy', title: 'Ягодный салат с клубникой, голубикой, йогуртом и маком', m: 'strawberry', a: 'blueberry', b: 'yogurt', d: 'poppy_seeds', e: 'honey', c: 'home', mode: 'cold' },
  { id: 'fruit_salad_pear_grape_walnut', title: 'Осенний фруктовый салат с грушей, виноградом и орехами', m: 'pear', a: 'grape', b: 'walnut', d: 'yogurt', e: 'cinnamon', c: 'home', mode: 'cold' },
  { id: 'fruit_salad_peach_apricot_pistachio', title: 'Летний нежный салат из персиков и абрикосов с фисташками', m: 'peach', a: 'apricot', b: 'pistachio', d: 'yogurt', e: 'mint', c: 'home', mode: 'cold' },
  { id: 'fruit_salad_tropical_mango_coconut', title: 'Экзотический салат с ананасом, бананом, киви и стружкой кокоса', m: 'pineapple', a: 'banana', b: 'kiwi', d: 'coconut_flakes', e: 'yogurt', c: 'th', mode: 'cold' },
  { id: 'fruit_salad_persimmon_mandarin_nuts', title: 'Новогодний десертный салат из хурмы с мандаринами и орехом', m: 'persimmon', a: 'mandarin', b: 'walnut', d: 'sour_cream', e: 'honey', c: 'ru', mode: 'cold' },
  { id: 'fruit_salad_sweet_cherry_cream_cheese', title: 'Легкий десерт из черешни со сливочным сыром и печеньем', m: 'sweet_cherry', a: 'cream_cheese', b: 'cookies', d: 'honey', e: 'mint', c: 'home', mode: 'cold' },
  { id: 'milk_jelly_kefir_blackberry', title: 'Нежное кефирное желе с ежевикой и медовой ноткой', m: 'kefir', a: 'blackberry', b: 'honey', d: 'vanilla', e: 'starch', c: 'ru', verb: 'прогрейте ягодную основу с крахмалом', mode: 'warm', heatSec: 360 },
  { id: 'ice_cream_coconut_dark_chocolate', title: 'Кокосовое мороженое без сахара с кусочками шоколада', m: 'coconut_milk', a: 'chocolate', b: 'coconut_flakes', d: 'dates', e: 'vanilla', c: 'home', mode: 'cold' },
  { id: 'nice_cream_blueberry_banana_oats', title: 'Полезное бананово-черничное мороженое за 5 минут', m: 'banana', a: 'blueberry', b: 'yogurt', d: 'rolled_oats', e: 'honey', c: 'home', mode: 'cold' },
  { id: 'carrot_apple_honey_raisins_vitamin', title: 'Сладкий тертый десерт из моркови с яблоком, изюмом и медом', m: 'carrot', a: 'apple', b: 'raisins', d: 'honey', e: 'walnut', c: 'ru', mode: 'cold' },
  { id: 'cottage_melon_honey_mint', title: 'Свежий творожный крем со спелой дыней, медом и мятой', m: 'cottage_cheese', a: 'melon', b: 'honey', d: 'mint', e: 'yogurt', c: 'home', mode: 'cold' },
  { id: 'cottage_kiwi_banana_cocoa', title: 'Полосатый творожно-шоколадный десерт с бананом и киви', m: 'cottage_cheese', a: 'kiwi', b: 'banana', d: 'cocoa', e: 'sour_cream', c: 'home', mode: 'cold' },
  { id: 'yogurt_granola_plum_cinnamon', title: 'Печеные сливы с йогуртом, орехами и овсяными хлопьями', m: 'plum', a: 'yogurt', b: 'rolled_oats', d: 'walnut', e: 'cinnamon', c: 'home', verb: 'запекайте сливы перед подачей', mode: 'warm', heatSec: 720 },
  { id: 'watermelon_feta_sweet_mint_honey', title: 'Греческий сладкий десерт из арбуза с сыром фета и медом', m: 'watermelon', a: 'feta', b: 'honey', d: 'mint', e: 'lime', c: 'gr', mode: 'cold' },
  { id: 'strawberry_ice_cream_balsamic_chocolate', title: 'Клубника со сливочным пломбиром и шоколадной стружкой', m: 'strawberry', a: 'ice_cream', b: 'chocolate', d: 'mint', e: 'walnut', c: 'home', mode: 'cold' },
  { id: 'baked_apples_ice_cream_caramel', title: 'Горячие карамельные яблоки с шариком холодного пломбира', m: 'apple', a: 'ice_cream', b: 'caramel', d: 'cinnamon', e: 'butter', c: 'home', verb: 'запекайте или припустите яблоки в масле', mode: 'warm', heatSec: 720 }
];

for (const it of coldFruitMousse) {
  addDessert({
    id: it.id,
    title: it.title,
    cuisine: it.c,
    time: 25,
    active: 15,
    mode: it.mode,
    verb: it.verb,
    heatSec: it.heatSec,
    ings: [it.m, it.a, it.b, it.d, it.e]
  });
}

// 4. Confections, Truffles, Chocolate Salami, Candied Nuts & Traditional Sweets (30)
const confections = [
  { id: 'chocolate_sausage_cookies_walnut', title: 'Любимая шоколадная колбаса из печенья с какао и орехами', m: 'cookies', a: 'butter', b: 'condensed_milk', d: 'cocoa', e: 'walnut', c: 'ru', mode: 'cold' },
  { id: 'kartoshka_russian_cake_rum_cocoa', title: 'Домашнее пирожное Картошка из печенья на сгущенке с какао', m: 'cookies', a: 'condensed_milk', b: 'butter', d: 'cocoa', e: 'vanilla_sugar', c: 'ru', mode: 'cold' },
  { id: 'kartoshka_rusks_sour_cream', title: 'Классическое пирожное Картошка из сухарей со сметаной', m: 'breadcrumbs', a: 'butter', b: 'sugar', d: 'cocoa', e: 'milk', c: 'ru', mode: 'cold' },
  { id: 'raffaello_cottage_coconut_almond', title: 'Домашние творожные конфеты с миндалем в кокосовой стружке', m: 'cottage_cheese', a: 'coconut_flakes', b: 'almond', d: 'condensed_milk', e: 'vanilla_sugar', c: 'home', mode: 'cold' },
  { id: 'raffaello_condensed_butter_wafers', title: 'Сливочные кокосовые шарики со сгущенкой и целым миндалем', m: 'condensed_milk', a: 'coconut_flakes', b: 'almond', d: 'butter', e: 'cookies', c: 'home', mode: 'cold' },
  { id: 'energy_balls_dates_cashew_cocoa', title: 'Полезные шоколадные конфеты из фиников, кешью и ароматного какао', m: 'dates', a: 'cashew', b: 'cocoa', d: 'coconut_flakes', e: 'rolled_oats', c: 'home', mode: 'cold' },
  { id: 'energy_balls_dried_apricots_almond', title: 'Витаминные конфеты из кураги, изюма, миндаля и меда', m: 'dried_apricots', a: 'raisins', b: 'almond', d: 'honey', e: 'lemon', c: 'home', mode: 'cold' },
  { id: 'energy_balls_prunes_pumpkin_seeds', title: 'Полезные конфеты без сахара с черносливом и семечками тыквы', m: 'prunes', a: 'pumpkin_seeds', b: 'sunflower_seeds', d: 'honey', e: 'cocoa', c: 'home', mode: 'cold' },
  { id: 'chocolate_truffles_dark_cream', title: 'Изысканные шоколадные трюфели на жирных сливках с какао', m: 'chocolate', a: 'cream', b: 'butter', d: 'cocoa', e: 'vanilla', c: 'fr', mode: 'cold' },
  { id: 'chocolate_truffles_orange_hazelnut', title: 'Ароматные трюфели с апельсиновой цедрой и фундуком', m: 'chocolate', a: 'hazelnut', b: 'orange', d: 'cream', e: 'cinnamon', c: 'fr', mode: 'cold' },
  { id: 'kozinaki_sunflower_honey_crunchy', title: 'Домашние хрустящие козинаки из семечек подсолнуха на меду', m: 'sunflower_seeds', a: 'honey', b: 'sugar', d: 'lemon', e: 'butter', c: 'ge', verb: 'прогрейте медовую карамель и уложите семечки', mode: 'warm', heatSec: 360 },
  { id: 'kozinaki_peanut_sesame_caramel', title: 'Восточный грильяж с жареным арахисом и кунжутом на меду', m: 'peanut', a: 'sesame', b: 'honey', d: 'sugar', e: 'butter', c: 'ge', verb: 'обжарьте арахис с кунжутом и уварите сироп', mode: 'warm', heatSec: 420 },
  { id: 'kozinaki_walnut_trad_georgian', title: 'Грузинский праздничный гозинаки с грецким орехом и медом', m: 'walnut', a: 'honey', b: 'sugar', d: 'butter', e: 'vanilla', c: 'ge', verb: 'обжарьте орехи и проварите в меду', mode: 'warm', heatSec: 420 },
  { id: 'candied_almonds_cinnamon_sugar', title: 'Пряный карамельный миндаль с корицей к праздничному столу', m: 'almond', a: 'sugar', b: 'cinnamon', d: 'butter', e: 'water', c: 'de', verb: 'обжаривайте миндаль в сиропе до карамелизации', mode: 'warm', heatSec: 600 },
  { id: 'candied_orange_peels_chocolate', title: 'Домашние апельсиновые цукаты в темной шоколадной глазури', m: 'orange', a: 'sugar', b: 'chocolate', d: 'water', e: 'lemon', c: 'it', verb: 'варите апельсиновые корочки в сиропе до прозрачности', mode: 'warm', heatSec: 1800 },
  { id: 'halva_chocolate_fudge_walnut', title: 'Домашняя шоколадная халва со сливочным маслом и орехами', m: 'halva', a: 'chocolate', b: 'butter', d: 'walnut', e: 'cream', c: 'home', mode: 'cold' },
  { id: 'halva_semolina_butter_nuts_turkish', title: 'Восточная теплая манная халва на масле с кедровым орешком', m: 'semolina', a: 'butter', b: 'sugar', d: 'pine_nuts', e: 'milk', c: 'tr', verb: 'обжаривайте крупу в масле и залейте молоком', mode: 'warm', heatSec: 600 },
  { id: 'halva_flour_honey_butter_uzbek', title: 'Узбекская домашняя мучная халва с медом и орехами', m: 'flour', a: 'butter', b: 'honey', d: 'walnut', e: 'sugar', c: 'uz', verb: 'обжаривайте муку на масле до орехового аромата', mode: 'warm', heatSec: 600 },
  { id: 'fudge_milk_sugar_soviet_sherbet', title: 'Сливочный домашний щербет с арахисом на сгущенном молоке', m: 'condensed_milk', a: 'milk', b: 'peanut', d: 'butter', e: 'sugar', c: 'ru', verb: 'варите молочную смесь до густой карамели', mode: 'warm', heatSec: 900 },
  { id: 'chocolate_bark_pistachio_cranberry', title: 'Праздничная плитка шоколада с фисташками, сушеной клюквой и миндалем', m: 'chocolate', a: 'pistachio', b: 'cranberry', d: 'almond', e: 'coconut_flakes', c: 'home', mode: 'cold' },
  { id: 'coconut_bounty_bars_homemade', title: 'Домашние шоколадные батончики с сочной кокосовой начинкой', m: 'coconut_flakes', a: 'condensed_milk', b: 'chocolate', d: 'butter', e: 'vanilla', c: 'home', mode: 'cold' },
  { id: 'snickers_date_peanut_caramel_bars', title: 'Полезные батончики с финиками, жареным арахисом и шоколадом', m: 'dates', a: 'peanut', b: 'chocolate', d: 'caramel', e: 'butter', c: 'home', mode: 'cold' },
  { id: 'pastila_apple_baked_honey', title: 'Домашняя мягкая яблочная пастила из печеных яблок с медом', m: 'apple', a: 'honey', b: 'cinnamon', d: 'water', e: 'lemon', c: 'ru', verb: 'запекайте яблоки, взбейте и подсушите в духовке', mode: 'warm', heatSec: 3600 },
  { id: 'marmalade_plum_lemon_homemade', title: 'Домашний ароматный сливовый мармелад в сахарной обсыпке', m: 'plum', a: 'sugar', b: 'lemon', d: 'apple', e: 'starch', c: 'ru', verb: 'варите фруктовое пюре до плотного загустения', mode: 'warm', heatSec: 1200 },
  { id: 'banana_chocolate_sushi_rolls', title: 'Веселые сладкие роллы из банана с шоколадом и кокосом', m: 'banana', a: 'chocolate', b: 'coconut_flakes', d: 'cream_cheese', e: 'peanut', c: 'home', mode: 'cold' },
  { id: 'lava_sweet_roll_tortilla_apple', title: 'Хрустящие рулетики из тортильи с яблоком, карамелью и корицей', m: 'tortilla', a: 'apple', b: 'caramel', d: 'cinnamon', e: 'butter', c: 'us', verb: 'обжаривайте рулетики на сливочном масле', mode: 'warm', heatSec: 420 },
  { id: 'lavash_cherry_cottage_sweet_roll', title: 'Быстрый запеченный рулет из лаваша с вишней и творогом', m: 'lavash', a: 'cottage_cheese', b: 'cherry', d: 'egg', e: 'vanilla_sugar', c: 'ru', verb: 'запекайте в духовке со взбитым яйцом', mode: 'warm', heatSec: 1200 },
  { id: 'strawberry_chocolate_dipped_nuts', title: 'Спелая клубника в растопленном шоколаде с крошкой фисташек', m: 'strawberry', a: 'chocolate', b: 'pistachio', d: 'coconut_flakes', e: 'cream', c: 'home', mode: 'cold' },
  { id: 'baked_marshmallow_fruit_dip', title: 'Запеченный зефир с шоколадом под соусом и печеньем', m: 'marshmallow', a: 'chocolate', b: 'cookies', d: 'cream', e: 'banana', c: 'us', verb: 'запекайте массу до румяной шапочки', mode: 'warm', heatSec: 480 },
  { id: 'apple_chips_crispy_cinnamon', title: 'Хрустящие яблочные чипсы с корицей, лимоном и кардамоном', m: 'apple', a: 'cinnamon', b: 'lemon', d: 'cardamom', e: 'sugar', c: 'home', verb: 'запекайте тонкие дольки в духовке до хруста', mode: 'warm', heatSec: 2700 }
];

for (const it of confections) {
  addDessert({
    id: it.id,
    title: it.title,
    cuisine: it.c,
    time: it.mode === 'cold' ? 25 : 40,
    active: 20,
    mode: it.mode,
    verb: it.verb,
    heatSec: it.heatSec,
    ings: [it.m, it.a, it.b, it.d, it.e]
  });
}

// 5. Dessert Bowls, Sweet Grits, Thick Kissels & Berry Sauces (25)
const bowlsAndSauces = [
  { id: 'oatmeal_dessert_carrot_cake_walnut', title: 'Сладкий десерт в стиле морковного торта с хлопьями и изюмом', m: 'rolled_oats', a: 'carrot', b: 'walnut', d: 'raisins', e: 'cream_cheese', c: 'home', verb: 'варите до мягкости и увенчайте сыром', mode: 'warm', heatSec: 420 },
  { id: 'oatmeal_dessert_apple_caramel_pecan', title: 'Теплая десертная овсянка с карамельными яблоками и корицей', m: 'oatmeal', a: 'apple', b: 'caramel', d: 'cinnamon', e: 'yogurt', c: 'home', verb: 'варите на молоке до кремовой густоты', mode: 'warm', heatSec: 420 },
  { id: 'rice_sweet_coconut_mango_thai', title: 'Тайский сладкий рис на кокосовом молоке со спелым персиком', m: 'round_rice', a: 'coconut_milk', b: 'peach', d: 'sesame', e: 'sugar', c: 'th', verb: 'варите рис в сладком кокосовом молоке', mode: 'warm', heatSec: 1200 },
  { id: 'rice_sweet_pumpkin_vanilla_raisins', title: 'Сладкая десертная рисовая запеканка с тыквой и изюмом', m: 'round_rice', a: 'squash', b: 'raisins', d: 'egg', e: 'vanilla_sugar', c: 'ru', verb: 'запекайте в форме в духовке', mode: 'warm', heatSec: 1800 },
  { id: 'couscous_sweet_dates_orange_milk', title: 'Восточный сладкий кускус на молоке с финиками и апельсином', m: 'couscous', a: 'milk', b: 'dates', d: 'orange', e: 'honey', c: 'home', verb: 'варите в горячем молоке и дайте настояться', mode: 'warm', heatSec: 300 },
  { id: 'kissel_thick_cherry_sliceable', title: 'Густой десертный вишневый кисель, который можно резать ложкой', m: 'cherry', a: 'starch', b: 'sugar', d: 'water', e: 'cinnamon', c: 'ru', verb: 'варите с крахмалом до плотной консистенции', mode: 'warm', heatSec: 420 },
  { id: 'kissel_thick_milk_chocolate_sauce', title: 'Густой домашний молочный кисель с ванилью и шоколадной стружкой', m: 'milk', a: 'starch', b: 'chocolate', d: 'vanilla_sugar', e: 'butter', c: 'ru', verb: 'варите молоко с крахмалом до густоты', mode: 'warm', heatSec: 360 },
  { id: 'kissel_thick_currant_black_berry', title: 'Ягодный десерт из черной смородины со сливками и печеньем', m: 'currant_black', a: 'starch', b: 'cream', d: 'cookies', e: 'sugar', c: 'ru', verb: 'варите густую ягодную основу с крахмалом', mode: 'warm', heatSec: 420 },
  { id: 'cottage_baked_currant_red_semolina', title: 'Пышный творожно-ягодный десерт с красной смородиной из духовки', m: 'cottage_cheese', a: 'currant_red', b: 'semolina', d: 'egg', e: 'sour_cream', c: 'ru', verb: 'запекайте в силиконовых формочках', mode: 'warm', heatSec: 1500 },
  { id: 'cottage_baked_banana_cocoa', title: 'Шоколадно-творожный мусс-пудинг из духовки со спелым бананом', m: 'cottage_cheese', a: 'banana', b: 'cocoa', d: 'egg', e: 'yogurt', c: 'home', verb: 'запекайте до нежного схватывания', mode: 'warm', heatSec: 1500 },
  { id: 'apple_blackberry_sauce_yogurt', title: 'Пряное яблочно-ежевичное пюре с медом и густым йогуртом', m: 'apple', a: 'blackberry', b: 'yogurt', d: 'honey', e: 'ginger', c: 'home', verb: 'варите фрукты на медленном огне', mode: 'warm', heatSec: 900 },
  { id: 'plum_hazelnut_parfait_cream', title: 'Сливовый парфе с карамельным кремом и дробленым фундуком', m: 'plum', a: 'cream', b: 'hazelnut', d: 'caramel', e: 'cookies', c: 'home', mode: 'cold' },
  { id: 'melon_prosciutto_sweet_honey_yogurt', title: 'Летний легкий десерт из дыни со взбитым творогом и миндалем', m: 'melon', a: 'cottage_cheese', b: 'almond', d: 'honey', e: 'mint', c: 'home', mode: 'cold' },
  { id: 'pumpkin_dates_sweet_creamy', title: 'Нежный сладкий крем из печеной тыквы с финиками и корицей', m: 'squash', a: 'dates', b: 'cream', d: 'cinnamon', e: 'walnut', c: 'home', verb: 'запекайте тыкву и взбейте в пюре', mode: 'warm', heatSec: 1500 },
  { id: 'pomegranate_yogurt_pistachio_bowl', title: 'Десертная пиала из йогурта с гранатом, фисташками и медом', m: 'yogurt', a: 'pomegranate', b: 'pistachio', d: 'honey', e: 'vanilla_sugar', c: 'home', mode: 'cold' },
  { id: 'sweet_croutons_milk_vanilla_granny', title: 'Теплые сладкие гренки из белого хлеба в молоке с корицей', m: 'white_bread', a: 'milk', b: 'egg', d: 'sugar', e: 'cinnamon', c: 'ru', verb: 'обжаривайте гренки на сливочном масле', mode: 'warm', heatSec: 360 },
  { id: 'fried_banana_peanut_croutons', title: 'Сладкие жареные тосты с карамельным бананом и арахисом', m: 'white_bread', a: 'banana', b: 'peanut', d: 'butter', e: 'egg', c: 'us', verb: 'обжаривайте гренки с обеих сторон', mode: 'warm', heatSec: 360 },
  { id: 'cherry_dumplings_vareniki_sweet', title: 'Домашние вареники с вишней, медом и прохладной сметаной', m: 'flour', a: 'cherry', b: 'sour_cream', d: 'sugar', e: 'butter', c: 'ua', verb: 'варите в подсоленной кипящей воде', mode: 'warm', heatSec: 420 },
  { id: 'lazy_vareniki_strawberry_butter', title: 'Ленивые творожные вареники с клубникой и сливочным маслом', m: 'cottage_cheese', a: 'strawberry', b: 'flour', d: 'egg', e: 'butter', c: 'ru', verb: 'варите до всплытия в кипящей воде', mode: 'warm', heatSec: 300 },
  { id: 'sweet_curd_rolls_jam_lavash', title: 'Сладкие запеченные рулеты с творогом, яблоком и вареньем', m: 'cottage_cheese', a: 'apple', b: 'jam', d: 'butter', e: 'egg', c: 'home', verb: 'запекайте в форме с яйцом', mode: 'warm', heatSec: 1200 },
  { id: 'almond_cream_apricots_chilled', title: 'Охлажденный миндальный крем со спелыми абрикосами', m: 'almond', a: 'apricot', b: 'cream', d: 'honey', e: 'vanilla', c: 'home', mode: 'cold' },
  { id: 'sweet_millet_baked_raisins_cottage', title: 'Сладкая пшенная бабка с творогом и изюмом к полднику', m: 'millet', a: 'cottage_cheese', b: 'raisins', d: 'egg', e: 'milk', c: 'ru', verb: 'запекайте в разогретой духовке', mode: 'warm', heatSec: 1800 },
  { id: 'orange_curd_parfait_cookies', title: 'Ароматный апельсиновый мусс с крошкой печенья и сливками', m: 'orange', a: 'cream', b: 'cookies', d: 'starch', e: 'sugar', c: 'uk', verb: 'варите апельсиновую основу с крахмалом', mode: 'warm', heatSec: 360 },
  { id: 'coconut_kiwi_tapioca_pear_salad', title: 'Фруктовый салат с грушей, киви и сладким кокосовым кремом', m: 'pear', a: 'kiwi', b: 'coconut_milk', d: 'honey', e: 'pistachio', c: 'home', mode: 'cold' },
  { id: 'sweet_currant_ice_cream_pie', title: 'Быстрый торт-мороженое с черной смородиной и печеньем', m: 'ice_cream', a: 'currant_black', b: 'cookies', d: 'chocolate', e: 'mint', c: 'home', mode: 'cold' }
];

for (const it of bowlsAndSauces) {
  addDessert({
    id: it.id,
    title: it.title,
    cuisine: it.c,
    time: 30,
    active: 15,
    mode: it.mode || 'warm',
    verb: it.verb,
    heatSec: it.heatSec,
    ings: [it.m, it.a, it.b, it.d, it.e]
  });
}

console.log(`Total generated desserts: ${allDesserts.length}`);
saveAndValidateGroup('desserts.json', allDesserts);
