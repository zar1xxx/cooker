/// Household ingredient catalog. One product per line:
/// `id|name|synonyms|category|parent|staple`.
/// Synonyms are separated by `;`. An empty parent means no parent.
library;

const ingredientLines = '''
potato|картофель|картошка;картошку;картофелина|vegetables||
onion|лук репчатый|лук;луковица;лучок|vegetables||
red_onion|лук красный|красный лук;лук-шалот|vegetables|onion|
carrot|морковь|морковка;морковку|vegetables||
beet|свёкла|свекла;бурак;буряк|vegetables||
cabbage|капуста белокочанная|капуста;капустка|vegetables||
red_cabbage|капуста краснокочанная|красная капуста|vegetables|cabbage|
cauliflower|капуста цветная|цветная капуста|vegetables|cabbage|
broccoli|брокколи|брокколи|vegetables|cabbage|
kohlrabi|капуста кольраби|кольраби|vegetables|cabbage|
brussels_sprouts|капуста брюссельская|брюссельская капуста|vegetables|cabbage|
zucchini|кабачок|кабачки;цукини|vegetables||
squash|тыква|тыкву;тыковка|vegetables||
pattypan|патиссон|патиссоны|vegetables||
cucumber|огурец|огурцы;огурчик|vegetables||
tomato|помидор|томат;помидоры;томаты|vegetables||
cherry_tomato|помидоры черри|черри|vegetables|tomato|
bell_pepper|перец болгарский|сладкий перец;болгарский перец|vegetables||
chili_pepper|перец острый|чили;острый перец|vegetables||
eggplant|баклажан|баклажаны;синенькие|vegetables||
radish|редис|редиска|vegetables||
daikon|дайкон|редис белый|vegetables|radish|
turnip|репа|репка|vegetables||
celery|сельдерей стеблевой|сельдерей|vegetables||
celery_root|сельдерей корневой|корень сельдерея|vegetables|celery|
parsley_root|корень петрушки|петрушка корневая|vegetables||
leek|лук-порей|порей|vegetables|onion|
garlic|чеснок|чесночок;зубчик чеснока|vegetables||
spinach|шпинат|шпинат|vegetables||
lettuce|салат листовой|листья салата;салат|vegetables||
arugula|рукола|руккола|vegetables||
sorrel|щавель|щавель|vegetables||
green_peas|горошек зелёный|зелёный горошек;свежий горох|vegetables||
green_beans|фасоль стручковая|зелёная фасоль;стручковая фасоль|vegetables||
corn|кукуруза|кукуруза в початках|vegetables||
asparagus|спаржа|спаржа|vegetables||
sweet_potato|батат|сладкий картофель|vegetables||
avocado|авокадо|авокадо|vegetables||
olives|оливки|маслины|vegetables||
capers|каперсы|каперсы|vegetables||
sauerkraut|капуста квашеная|квашеная капуста;кислая капуста|vegetables|cabbage|
pickles|огурцы солёные|солёные огурцы;огурчики|vegetables|cucumber|
seaweed|морская капуста|ламинария|vegetables||
artichoke|артишок|артишоки|vegetables||
parsnip|пастернак|пастернак|vegetables||
rhubarb|ревень|ревень|vegetables||
horseradish_root|хрен корень|корень хрена|vegetables|horseradish|
Jerusalem_artichoke|топинамбур|топинамбур|vegetables||
apple|яблоко|яблоки;яблочко|fruits||
pear|груша|груши|fruits||
banana|банан|бананы|fruits||
orange|апельсин|апельсины|fruits||
mandarin|мандарин|мандарины|fruits||
lemon|лимон|лимоны|fruits||
lime|лайм|лаймы|fruits||
grapefruit|грейпфрут|грейпфруты|fruits||
peach|персик|персики|fruits||
apricot|абрикос|абрикосы|fruits||
plum|слива|сливы;сливка|fruits||
cherry|вишня|вишни|fruits||
sweet_cherry|черешня|черешни|fruits||
grape|виноград|виноградины|fruits||
strawberry|земляника|клубника;земляничка|fruits||
raspberry|малина|малинка|fruits||
blackberry|ежевика|ежевика|fruits||
blueberry|голубика|голубика|fruits||
cranberry|клюква|клюква|fruits||
currant_black|смородина чёрная|чёрная смородина|fruits||
currant_red|смородина красная|красная смородина|fruits||
gooseberry|крыжовник|крыжовник|fruits||
watermelon|арбуз|арбузик|fruits||
melon|дыня|дынька|fruits||
kiwi|киви|киви|fruits||
pineapple|ананас|ананасы|fruits||
pomegranate|гранат|гранаты|fruits||
persimmon|хурма|хурма|fruits||
fig|инжир|инжир|fruits||
dates|финики|финик|fruits||
prunes|чернослив|чернослив|fruits||
raisins|изюм|изюм|fruits||
dried_apricots|курага|курага|fruits||
dried_fruits|сухофрукты|сушёные фрукты|fruits||
coconut|кокос|кокосовая стружка|fruits||
meat|мясо|мясо|meat||
beef|говядина|говядину;говядинка|meat|meat|
beef_stew|говядина тушёная|тушёнка говяжья|meat|beef|
veal|телятина|телятину|meat|beef|
pork|свинина|свинину;свининка|meat|meat|
pork_ribs|рёбра свиные|свиные рёбра|meat|pork|
bacon|бекон|бекон|meat|pork|
ham|ветчина|ветчину|meat|pork|
sausage|колбаса|колбаска|meat||
frankfurters|сосиски|сосиска|meat||
minced_meat|фарш|фарш мясной|meat||
minced_pork|фарш свиной|свиной фарш|meat|minced_meat|
minced_beef|фарш говяжий|говяжий фарш|meat|minced_meat|
minced_chicken|фарш куриный|куриный фарш|meat|minced_meat|
liver|печень|печёнка|meat||
liver_chicken|печень куриная|куриная печень|meat|liver|
heart|сердце|сердечки|meat||
tongue|язык|язык говяжий|meat||
lamb|баранина|баранину|meat|meat|
rabbit|кролик|крольчатина|meat|meat|
lard|сало|шпик|meat||
chicken|курица|кура;курятина;курочка|poultry||
chicken_fillet|куриное филе|филе;грудка;куриная грудка|poultry|chicken|
chicken_thigh|куриное бедро|бёдра;куриные бёдра|poultry|chicken|
chicken_wings|куриные крылья|крылышки|poultry|chicken|
turkey|индейка|индюшатина|poultry||
turkey_fillet|индюшиное филе|филе индейки|poultry|turkey|
duck|утка|утиное мясо|poultry||
goose|гусь|гусятина|poultry||
fish|рыба|рыбу;рыбка|fish||
seafood|морепродукты|дары моря|fish||
pollock|минтай|минтай|fish|fish|
cod|треска|треску|fish|fish|
hake|хек|хек|fish|fish|
salmon|лосось|сёмга;красная рыба|fish|fish|
trout|форель|форель|fish|fish|
herring|сельдь|селёдка|fish|fish|
mackerel|скумбрия|скумбрия|fish|fish|
pike|щука|щуку|fish|fish|
perch|окунь|окунь|fish|fish|
carp|карп|карп|fish|fish|
catfish|сом|сом|fish|fish|
shrimp|креветки|креветка|fish|seafood|
squid|кальмар|кальмары|fish|seafood|
mussels|мидии|мидия|fish|seafood|
crab_sticks|крабовые палочки|крабовые палочки|fish|seafood|
egg|яйца|яйцо;яички|dairy||
milk|молоко|молочко|dairy||
kefir|кефир|кефирчик|dairy||
yogurt|йогурт|йогурт натуральный|dairy||
sour_cream|сметана|сметанка|dairy||
cream|сливки|сливочки|dairy||
butter|масло сливочное|сливочное масло|dairy||
cheese|сыр|сырок|dairy||
hard_cheese|сыр твёрдый|твёрдый сыр|dairy|cheese|
processed_cheese|сыр плавленый|плавленый сырок|dairy|cheese|
cottage_cheese|творог|творожок|dairy||
feta|сыр фета|фета|dairy|cheese|
mozzarella|моцарелла|моцарелла|dairy|cheese|
parmesan|пармезан|пармезан|dairy|hard_cheese|
cream_cheese|сливочный сыр|крем-сыр|dairy|cheese|
condensed_milk|молоко сгущённое|сгущёнка|dairy||
curdled_milk|ряженка|ряженка|dairy||
buttermilk|пахта|пахта|dairy||
ice_cream|мороженое|пломбир|dairy||
powdered_milk|молоко сухое|сухое молоко|dairy||
whey|сыворотка|сыворотка|dairy||
tofu|тофу|соевый творог|dairy||
rice|рис|рисовая крупа|grains||
round_rice|рис круглозёрный|рис для каши|grains|rice|
basmati_rice|рис басмати|басмати|grains|rice|
buckwheat|гречка|гречневая крупа;греча|grains||
oatmeal|овсянка|овсяные хлопья;геркулес|grains||
rolled_oats|хлопья овсяные|овсяные хлопья|grains|oatmeal|
semolina|манка|манная крупа|grains||
millet|пшено|пшённая крупа|grains||
barley|ячмень|ячневая крупа|grains||
pearl_barley|перловка|перловая крупа|grains|barley|
cornmeal|кукурузная крупа|полента|grains||
couscous|кускус|кускус|grains||
bulgur|булгур|булгур|grains||
quinoa|киноа|киноа|grains||
pasta|макароны|паста;макаронные изделия|grains||
spaghetti|спагетти|спагетти|grains|pasta|
vermicelli|вермишель|вермишель|grains|pasta|
noodles|лапша|лапша яичная|grains|pasta|
lasagna_sheets|листы для лазаньи|лазанья|grains|pasta|
flour|мука пшеничная|мука|bakery||
rye_flour|мука ржаная|ржаная мука|bakery|flour|
wholegrain_flour|мука цельнозерновая|цельнозерновая мука|bakery|flour|
starch|крахмал|кукурузный крахмал|bakery||
breadcrumbs|сухари панировочные|панировочные сухари|bakery||
bread|хлеб|хлебушек|bakery||
white_bread|хлеб белый|батон;белый хлеб|bakery|bread|
black_bread|хлеб чёрный|ржаной хлеб;чёрный хлеб|bakery|bread|
lavash|лаваш|лаваш тонкий|bakery||
pita|пита|пита|bakery||
tortilla|тортилья|лепёшка|bakery||
beans_dry|фасоль сухая|фасоль;сухая фасоль|legumes||
beans_red|фасоль красная|красная фасоль|legumes|beans_dry|
beans_white|фасоль белая|белая фасоль|legumes|beans_dry|
chickpeas_dry|нут сухой|нут;турецкий горох|legumes||
lentils_red|чечевица красная|красная чечевица|legumes||
lentils_green|чечевица зелёная|зелёная чечевица|legumes||
peas_dry|горох сухой|сухой горох;горох|legumes||
soybeans|соя|соевые бобы|legumes||
mung_beans|маш|бобы мунг|legumes||
azuki|адзуки|красные бобы|legumes||
mushrooms|грибы|грибочки|mushrooms||
champignon|шампиньоны|шампиньон|mushrooms|mushrooms|
oyster_mushroom|вешенки|вешенка|mushrooms|mushrooms|
forest_mushrooms|грибы лесные|лесные грибы|mushrooms|mushrooms|
porcini|белые грибы|боровики|mushrooms|forest_mushrooms|
chanterelles|лисички|лисичка|mushrooms|forest_mushrooms|
honey_mushrooms|опята|опёнок|mushrooms|forest_mushrooms|
shiitake|шиитаке|шиитаке|mushrooms|mushrooms|
tomatoes_canned|помидоры консервированные|консервированные помидоры|canned|tomato|
tomato_paste|томатная паста|паста томатная|canned|tomato|
tomato_sauce|томатный соус|соус томатный|canned|tomato|
peas_canned|горошек консервированный|консервированный горошек|canned|green_peas|
corn_canned|кукуруза консервированная|консервированная кукуруза|canned|corn|
beans_canned|фасоль консервированная|консервированная фасоль|canned||
chickpeas_canned|нут консервированный|консервированный нут|canned||
tuna_canned|тунец консервированный|тунец в масле|canned|fish|
saury_canned|сайра консервированная|сайра|canned|fish|
sardines_canned|сардины консервированные|сардины|canned|fish|
coconut_milk|молоко кокосовое|кокосовое молоко|canned||
jam|варенье|джем;повидло|canned||
preserves|консервы домашние|заготовки|canned||
mushrooms_canned|грибы консервированные|консервированные грибы|canned||
artichokes_canned|артишоки консервированные|консервированные артишоки|canned||
lecho|лечо|лечо домашнее|canned||
salt|соль||spices||staple
water|вода||spices||staple
sugar|сахар|сахарный песок|sweets||staple
black_pepper|перец чёрный молотый|перец;чёрный перец|spices||staple
sunflower_oil|масло подсолнечное|растительное масло;масло растительное|spices||staple
olive_oil|масло оливковое|оливковое масло|spices||
white_pepper|перец белый|белый перец|spices||
red_pepper|перец красный молотый|красный перец|spices||
paprika|паприка|паприка молотая|spices||
bay_leaf|лавровый лист|лаврушка|spices||
cinnamon|корица|корица молотая|spices||
cloves|гвоздика|гвоздика|spices||
nutmeg|мускатный орех|мускат|spices||
ginger|имбирь|корень имбиря|spices||
turmeric|куркума|куркума|spices||
coriander|кориандр|кинза семена|spices||
cumin|зира|кумин|spices||
mustard_seeds|горчица семена|семена горчицы|spices||
cardamom|кардамон|кардамон|spices||
vanilla|ваниль|стручок ванили|spices||
vanilla_sugar|ванильный сахар|ванилин|spices||
baking_soda|сода пищевая|сода|spices||
baking_powder|разрыхлитель|пекарский порошок|spices||
yeast|дрожжи|дрожжи сухие|spices||
vinegar|уксус|уксус столовый|spices||
apple_vinegar|уксус яблочный|яблочный уксус|spices|vinegar|
soy_sauce|соевый соус|соевый соус|spices||
ketchup|кетчуп|кетчуп|spices||
mayonnaise|майонез|майонез|spices||
mustard|горчица|горчица столовая|spices||
horseradish|хрен|хрен столовый|spices||
adjika|аджика|аджика|spices||
broth_cube|бульонный кубик|кубик бульона|spices||
curry_powder|карри|порошок карри|spices||
sesame_oil|масло кунжутное|кунжутное масло|spices||
nuts|орехи|орешки|nuts||
walnut|грецкие орехи|грецкий орех|nuts|nuts|
almond|миндаль|миндальный орех|nuts|nuts|
hazelnut|фундук|лесной орех|nuts|nuts|
cashew|кешью|орех кешью|nuts|nuts|
pistachio|фисташки|фисташка|nuts|nuts|
peanut|арахис|земляной орех|nuts|nuts|
pine_nuts|кедровые орехи|кедровый орех|nuts|nuts|
sunflower_seeds|семечки подсолнечника|семечки|nuts||
pumpkin_seeds|семечки тыквенные|тыквенные семечки|nuts||
sesame|кунжут|семена кунжута|nuts||
poppy_seeds|мак|семена мака|nuts||
coconut_flakes|стружка кокосовая|кокосовая стружка|nuts|coconut|
honey|мёд|мед|sweets||
chocolate|шоколад|шоколадка|sweets||
cocoa|какао|какао-порошок|sweets||
caramel|карамель|карамель|sweets||
halva|халва|халва|sweets||
marshmallow|зефир|зефир|sweets||
cookies|печенье|печеньице|sweets||
gingerbread|пряники|пряник|sweets||
syrup|сироп|сироп сахарный|sweets||
parsley|петрушка|петрушка зелень|greens||
dill|укроп|укропчик|greens||
cilantro|кинза|кориандр зелень|greens||
basil|базилик|базилик свежий|greens||
green_onion|лук зелёный|перо лука;зелёный лук|greens|onion|
mint|мята|мята свежая|greens||
oregano|орегано|душица|greens||
thyme|чабрец|тимьян|greens||
rosemary|розмарин|розмарин|greens||
tarragon|тархун|эстрагон|greens||
nettle|крапива|крапива|greens||
microgreens|микрозелень|ростки|greens||
''';
