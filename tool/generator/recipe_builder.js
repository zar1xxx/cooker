const fs = require('fs');
const path = require('path');

const ingredientsData = JSON.parse(fs.readFileSync(path.join(__dirname, '../../assets/seed/ingredients.json'), 'utf8'));
const validIngredientIds = new Set(ingredientsData.ingredients.map(i => i.id));
const stapleIds = new Set(ingredientsData.ingredients.filter(i => i.is_staple).map(i => i.id));
const ingredientById = {};
for (const ing of ingredientsData.ingredients) {
  ingredientById[ing.id] = ing;
}

const nonCuttableCategories = new Set(['grains', 'bakery', 'spices']);
const nonCuttableIds = new Set([
  'water', 'milk', 'kefir', 'cream', 'sour_cream',
  'oil_vegetable', 'oil_sunflower', 'oil_olive', 'butter'
]);

function isNonCuttable(id) {
  if (id.startsWith('minced_')) return true;
  if (nonCuttableIds.has(id)) return true;
  const ing = ingredientById[id];
  if (ing && nonCuttableCategories.has(ing.category)) return true;
  return false;
}

const allowedDishTypes = new Set([
  'soup', 'main', 'side', 'salad', 'breakfast', 'snack', 'baking', 'dessert', 'drink', 'preserve'
]);

const allowedDishGroups = new Set([
  'soup', 'meat', 'fish_seafood', 'vegetable', 'porridge_side', 'salad_snack',
  'egg_dairy', 'baking', 'dessert', 'beverage', 'preserves'
]);

const allowedCuisines = new Set([
  'home', 'ru', 'it', 'ge', 'uz', 'fr', 'cn', 'jp', 'tr', 'gr', 'mx', 'es',
  'am', 'az', 'by', 'ua', 'kz', 'th', 'in', 'kr', 'de', 'uk', 'us', 'pl', 'lt'
]);

function countSentences(text) {
  const cleaned = text.trim();
  if (!cleaned) return 0;
  const parts = cleaned.split(/[.!?]+(?:\s+|$)/);
  return parts.filter(p => p.trim().length > 0).length;
}

const nonStapleCatalogNames = ingredientsData.ingredients
  .filter(i => !i.is_staple && i.name.length >= 4)
  .map(i => i.name.toLowerCase());

const allowedUnits = new Set([
  'g', 'kg', 'ml', 'l', 'pcs', 'tbsp', 'tsp', 'cup', 'pinch', 'to_taste'
]);

function validateSingleRecipe(recipe) {
  const id = recipe.id;
  if (!id || typeof id !== 'string') throw new Error(`Recipe has invalid id: ${id}`);
  if (!recipe.title || recipe.title.length < 2 || recipe.title.length > 80) {
    throw new Error(`${id}: invalid title length: "${recipe.title}"`);
  }
  if (!allowedDishTypes.has(recipe.dish_type)) {
    throw new Error(`${id}: invalid dish_type: "${recipe.dish_type}"`);
  }
  if (!allowedDishGroups.has(recipe.dish_group)) {
    throw new Error(`${id}: invalid dish_group: "${recipe.dish_group}"`);
  }
  if (!allowedCuisines.has(recipe.cuisine)) {
    throw new Error(`${id}: invalid cuisine: "${recipe.cuisine}"`);
  }
  // Ensure total_minutes is sufficient for sum of timers with 10% margin
  const sumTimers = recipe.steps.reduce((acc, st) => acc + (st.timer_seconds || 0), 0);
  if (sumTimers > 0) {
    const minRequiredMinutes = Math.ceil(sumTimers / (60 * 1.05));
    if (recipe.total_minutes < minRequiredMinutes) {
      recipe.total_minutes = minRequiredMinutes + 5;
    }
    if (recipe.active_minutes > recipe.total_minutes) {
      recipe.active_minutes = Math.max(10, Math.floor(recipe.total_minutes * 0.4));
    }
  }

  if (recipe.total_minutes < 5 || recipe.total_minutes > 300) {
    throw new Error(`${id}: invalid total_minutes: ${recipe.total_minutes}`);
  }
  if (recipe.active_minutes < 1 || recipe.active_minutes > recipe.total_minutes) {
    throw new Error(`${id}: invalid active_minutes: ${recipe.active_minutes} (total: ${recipe.total_minutes})`);
  }
  if (recipe.servings < 1 || recipe.servings > 12) {
    throw new Error(`${id}: invalid servings: ${recipe.servings}`);
  }
  if (!recipe.description || recipe.description.length < 10) {
    throw new Error(`${id}: invalid description length`);
  }

  // Validate ingredients
  if (!Array.isArray(recipe.ingredients) || recipe.ingredients.length === 0) {
    throw new Error(`${id}: ingredients array is empty`);
  }
  for (const ing of recipe.ingredients) {
    if (!validIngredientIds.has(ing.ingredient_id)) {
      throw new Error(`${id}: unknown ingredient_id "${ing.ingredient_id}"`);
    }
    if (ing.amount !== null && (typeof ing.amount !== 'number' || ing.amount <= 0)) {
      throw new Error(`${id}: invalid amount for "${ing.ingredient_id}": ${ing.amount}`);
    }
    if (!allowedUnits.has(ing.unit)) {
      throw new Error(`${id}: invalid unit "${ing.unit}" for "${ing.ingredient_id}"`);
    }
  }

  // Validate steps
  if (!Array.isArray(recipe.steps) || recipe.steps.length === 0) {
    throw new Error(`${id}: steps array is empty`);
  }
  if (recipe.dish_type === 'soup' && recipe.steps.length < 5) {
    throw new Error(`${id}: soup has ${recipe.steps.length} steps (minimum 5)`);
  }
  const hasMeat = recipe.ingredients.some(i => {
    if (i.ingredient_id.startsWith('minced_')) return true;
    const cat = ingredientById[i.ingredient_id]?.category;
    return cat === 'meat' || cat === 'poultry' || cat === 'fish';
  });
  if (recipe.dish_type === 'main' && hasMeat && recipe.steps.length < 4) {
    throw new Error(`${id}: meat main has ${recipe.steps.length} steps (minimum 4)`);
  }

  for (let idx = 0; idx < recipe.steps.length; idx++) {
    const step = recipe.steps[idx];
    const text = step.text;
    if (!text || typeof text !== 'string') {
      throw new Error(`${id}: step ${idx + 1} has no text`);
    }
    const lower = text.toLowerCase();

    // Sentence count
    const sentences = countSentences(text);
    if (sentences > 2) {
      throw new Error(`${id}: step ${idx + 1} has ${sentences} sentences (max 2): "${text}"`);
    }

    // Template phrases
    if (lower.includes('остальные продукты') || lower.includes('остальных продуктов') || lower.includes('остальными продуктами')) {
      throw new Error(`${id}: step ${idx + 1} has "остальные продукты"`);
    }

    // "до готовности"
    if (lower.includes('до готовности')) {
      const hasSign =
        lower.includes('мягкост') || lower.includes('прозрачн') || lower.includes('золотист') ||
        lower.includes('пока ') || lower.includes('румян') || lower.includes('выпари') ||
        lower.includes('загуст') || lower.includes('свернет') || lower.includes('готовности мяса') ||
        lower.includes('готовности риса') || lower.includes('готовности овощей');
      if (!hasSign) {
        throw new Error(`${id}: step ${idx + 1} has "до готовности" without readiness cue: "${text}"`);
      }
    }

    // Slicing non-cuttable
    if (lower.includes('нарежьте') || lower.includes('порежьте')) {
      for (const ingRef of recipe.ingredients) {
        const ingId = ingRef.ingredient_id;
        if (isNonCuttable(ingId)) {
          const ingName = (ingredientById[ingId]?.name || ingId).toLowerCase();
          if (lower.includes(ingName)) {
            throw new Error(`${id}: step ${idx + 1} slices non-cuttable "${ingName}"`);
          }
        }
      }
    }

    // Nominative listing
    for (const name1 of nonStapleCatalogNames) {
      if (!lower.includes(name1)) continue;
      for (const name2 of nonStapleCatalogNames) {
        if (name1 === name2) continue;
        if (lower.includes(`${name1}, ${name2}`) || lower.includes(`${name1} и ${name2}`)) {
          throw new Error(`${id}: step ${idx + 1} has nominative list "${name1}" & "${name2}"`);
        }
      }
    }
  }
}

function saveAndValidateGroup(filename, recipes) {
  console.log(`Validating ${recipes.length} recipes for ${filename}...`);
  const seenIds = new Set();
  const seenTitles = new Map();
  const stepMap = new Map();
  const ingSets = new Map();

  // Load baseline and other existing groups to check cross-file collisions
  const baselinePath = path.join(__dirname, 'baseline_125.json');
  const otherRecipes = [];
  if (fs.existsSync(baselinePath)) {
    const baseData = JSON.parse(fs.readFileSync(baselinePath, 'utf8'));
    otherRecipes.push(...(baseData.recipes || []));
  }
  const targetDir = path.join(__dirname, '../../assets/seed/recipes');
  if (fs.existsSync(targetDir)) {
    for (const f of fs.readdirSync(targetDir)) {
      if (f.endsWith('.json') && f !== filename) {
        try {
          const d = JSON.parse(fs.readFileSync(path.join(targetDir, f), 'utf8'));
          otherRecipes.push(...(d.recipes || []));
        } catch (_) {}
      }
    }
  }

  for (const r of otherRecipes) {
    seenIds.add(r.id);
    const normTitle = r.title.toLowerCase().replace(/ё/g, 'е').replace(/\s+/g, ' ').trim();
    seenTitles.set(normTitle, r.id);
    for (const s of r.steps || []) {
      const normStep = s.text.trim().toLowerCase();
      if (!stepMap.has(normStep)) stepMap.set(normStep, new Set());
      stepMap.get(normStep).add(r.id);
    }
    const nonStaples = new Set(
      (r.ingredients || [])
        .map(i => i.ingredient_id)
        .filter(id => !stapleIds.has(id))
    );
    ingSets.set(r.id, { set: nonStaples, isOther: true });
  }

  for (const r of recipes) {
    if (seenIds.has(r.id)) {
      throw new Error(`Duplicate id: "${r.id}"`);
    }
    seenIds.add(r.id);

    const normTitle = r.title.toLowerCase().replace(/ё/g, 'е').replace(/\s+/g, ' ').trim();
    if (seenTitles.has(normTitle)) {
      throw new Error(`Duplicate title "${r.title}" (${r.id} vs ${seenTitles.get(normTitle)})`);
    }
    seenTitles.set(normTitle, r.id);

    validateSingleRecipe(r);

    // Collect steps
    for (const s of r.steps) {
      const normStep = s.text.trim().toLowerCase();
      if (!stepMap.has(normStep)) stepMap.set(normStep, new Set());
      stepMap.get(normStep).add(r.id);
    }

    // Collect non-staples for Jaccard
    const nonStaples = new Set(
      r.ingredients
        .map(i => i.ingredient_id)
        .filter(id => !stapleIds.has(id))
    );
    ingSets.set(r.id, { set: nonStaples, isOther: false });
  }

  // Check phrase repeat counts
  for (const [phrase, ids] of stepMap.entries()) {
    if (ids.size > 3) {
      throw new Error(`Step phrase repeated in ${ids.size} recipes: "${phrase}" (${[...ids].slice(0, 4).join(', ')})`);
    }
  }

  // Check Jaccard for current group against itself AND against otherRecipes
  const currentIds = recipes.map(r => r.id);
  const allEntries = Array.from(ingSets.entries());
  const jaccardErrors = [];
  for (const curId of currentIds) {
    const s1 = ingSets.get(curId).set;
    for (const [otherId, entry] of allEntries) {
      if (curId === otherId) continue;
      if (!entry.isOther && curId > otherId) continue; // avoid checking current-current pairs twice
      const s2 = entry.set;
      let inter = 0;
      for (const item of s1) {
        if (s2.has(item)) inter++;
      }
      const union = s1.size + s2.size - inter;
      const jaccard = union === 0 ? 1.0 : inter / union;
      if (jaccard >= 0.85) {
        jaccardErrors.push(`High Jaccard ${(jaccard * 100).toFixed(1)}% between ${curId} and ${otherId}`);
      }
    }
  }

  if (jaccardErrors.length > 0) {
    console.error(`Total Jaccard violations: ${jaccardErrors.length}`);
    jaccardErrors.slice(0, 20).forEach(e => console.error(' -', e));
    throw new Error(`Jaccard check failed with ${jaccardErrors.length} collisions.`);
  }

  // Ensure output directory exists
  if (!fs.existsSync(targetDir)) {
    fs.mkdirSync(targetDir, { recursive: true });
  }

  const outPath = path.join(targetDir, filename);
  const outData = {
    version: 1,
    recipes: recipes
  };
  fs.writeFileSync(outPath, JSON.stringify(outData, null, 2), 'utf8');
  console.log(`✓ Successfully saved ${recipes.length} recipes to ${filename}`);
}

function smartIngredient(id, defaultAmount, defaultUnit) {
  if (defaultAmount !== undefined && defaultUnit !== undefined) {
    return { ingredient_id: id, amount: defaultAmount, unit: defaultUnit };
  }
  const ing = ingredientById[id];
  if (!ing) return { ingredient_id: id, amount: 100, unit: 'g' };

  if (id === 'salt' || id === 'to_taste') return { ingredient_id: id, amount: null, unit: 'to_taste' };
  if (id === 'chili_pepper') return { ingredient_id: id, amount: 1, unit: 'pcs' };
  if (id === 'bay_leaf') return { ingredient_id: id, amount: 2, unit: 'pcs' };
  if (id === 'broth_cube') return { ingredient_id: id, amount: 1, unit: 'pcs' };
  if (id === 'garlic') return { ingredient_id: id, amount: 3, unit: 'pcs' };
  if (id === 'egg') return { ingredient_id: id, amount: 2, unit: 'pcs' };
  if (['lemon', 'lime', 'orange', 'mandarin', 'onion', 'red_onion'].includes(id)) {
    return { ingredient_id: id, amount: 1, unit: 'pcs' };
  }
  if (['apple', 'pear', 'peach', 'banana', 'carrot', 'potato', 'bell_pepper', 'tomato', 'cucumber'].includes(id)) {
    return { ingredient_id: id, amount: 2, unit: 'pcs' };
  }
  if (['sunflower_oil', 'olive_oil', 'sesame_oil', 'vinegar', 'apple_vinegar', 'soy_sauce', 'tomato_paste', 'honey', 'mustard', 'horseradish', 'adjika', 'ketchup', 'mayonnaise', 'syrup'].includes(id)) {
    return { ingredient_id: id, amount: 2, unit: 'tbsp' };
  }
  if (['black_pepper', 'white_pepper', 'red_pepper', 'paprika', 'cinnamon', 'cloves', 'nutmeg', 'turmeric', 'coriander', 'cumin', 'mustard_seeds', 'cardamom', 'vanilla', 'vanilla_sugar', 'baking_soda', 'baking_powder', 'yeast', 'curry_powder', 'oregano', 'thyme', 'rosemary', 'tarragon'].includes(id)) {
    return { ingredient_id: id, amount: 1, unit: 'tsp' };
  }
  if (['parsley', 'dill', 'cilantro', 'basil', 'green_onion', 'mint', 'nettle', 'microgreens', 'spinach', 'arugula', 'sorrel'].includes(id)) {
    return { ingredient_id: id, amount: 30, unit: 'g' };
  }
  if (['ginger', 'horseradish_root', 'starch', 'cocoa', 'sesame', 'poppy_seeds'].includes(id)) {
    return { ingredient_id: id, amount: 20, unit: 'g' };
  }
  if (['walnut', 'almond', 'hazelnut', 'cashew', 'pistachio', 'peanut', 'pine_nuts', 'sunflower_seeds', 'pumpkin_seeds', 'coconut_flakes', 'prunes', 'raisins', 'dried_apricots', 'capers', 'olives'].includes(id)) {
    return { ingredient_id: id, amount: 50, unit: 'g' };
  }
  if (id === 'butter') return { ingredient_id: id, amount: 40, unit: 'g' };
  if (id === 'sugar') return { ingredient_id: id, amount: 50, unit: 'g' };
  if (id === 'breadcrumbs') return { ingredient_id: id, amount: 60, unit: 'g' };
  if (id === 'flour' || id === 'rye_flour' || id === 'wholegrain_flour') return { ingredient_id: id, amount: 100, unit: 'g' };
  if (['water', 'milk', 'kefir', 'cream', 'coconut_milk', 'whey', 'buttermilk', 'yogurt'].includes(id)) {
    return { ingredient_id: id, amount: 200, unit: 'ml' };
  }
  return { ingredient_id: id, amount: defaultAmount || 150, unit: defaultUnit || 'g' };
}

module.exports = {
  validateSingleRecipe,
  saveAndValidateGroup,
  smartIngredient,
  ingredientById,
  stapleIds,
  validIngredientIds
};
