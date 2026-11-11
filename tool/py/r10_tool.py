"""R10-05 helper: new hand-written recipes that use the new products.

  add FILE.json   check and add recipes to tool/seed_data/r10/new_recipes.json
  lint            re-check everything already added (cross-catalog repeats)
  status          counts and coverage of new products
  export          write assets/seed/recipes/r10_new.json (base fields only)
The script never writes recipe text; recipes come from hand-written batches.
"""
import json, os, sys, re, collections
sys.path.insert(0, os.path.dirname(__file__))
import r9_tools, r9_validator, r9_detect, r9_difficulty

STORE = 'tool/seed_data/r10/new_recipes.json'
NEW_IDS = 'tool/seed_data/r10/new_product_ids.json'
EXPORT = 'assets/seed/recipes/r10_new.json'
TYPES = {'main':{'meat','fish_seafood','vegetable','egg_dairy'},'soup':{'soup'},'baking':{'baking'},
 'dessert':{'dessert','egg_dairy'},'breakfast':{'egg_dairy','porridge_side','baking'},'drink':{'beverage'},
 'salad':{'salad_snack'},'preserve':{'preserves'},'side':{'porridge_side','vegetable'},'snack':{'salad_snack','egg_dairy'}}
CUIS = {'ru','home','it','fr','us','ge','tr','gr','cn','de','in','jp','uk','es','uz','mx','th','kr','pl','az','ua','am','lt','kz','by'}
UNITS = {'g','pcs','to_taste','tbsp','ml','tsp','l','kg'}
FIELDS = ['id','title','dish_type','dish_group','cuisine','total_minutes','active_minutes','cook_minutes','servings','description','ingredients','steps']

def store():
    return json.load(open(STORE, encoding='utf-8')) if os.path.exists(STORE) else []

def save_store(items):
    os.makedirs(os.path.dirname(STORE), exist_ok=True)
    json.dump(items, open(STORE, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)

def catalog_with(items):
    data = r9_tools.load()
    data = {'recipes': [r for r in data['recipes']] + [dict(r, quality='curated') for r in items]}
    return data

def check(items, existing_ids, ing, new_ids, hier, safety, all_items):
    errs = []
    seen = set()
    titles = {r['title'].lower() for r in r9_tools.load()['recipes']} | {r['title'].lower() for r in all_items if r not in items}
    for r in items:
        i = r.get('id', '?')
        if set(r) - set(FIELDS): errs.append(f'{i}: extra fields {set(r)-set(FIELDS)}')
        if any(f not in r for f in FIELDS): errs.append(f'{i}: missing fields'); continue
        if i in existing_ids or i in seen: errs.append(f'{i}: duplicate id')
        seen.add(i)
        if r['title'].lower() in titles: errs.append(f'{i}: duplicate title')
        if r['dish_group'] not in TYPES.get(r['dish_type'], ()): errs.append(f'{i}: bad type/group')
        if r['cuisine'] not in CUIS: errs.append(f'{i}: bad cuisine')
        if not 1 <= r['servings'] <= 12: errs.append(f'{i}: servings')
        ids = [x['ingredient_id'] for x in r['ingredients']]
        if len(set(ids)) != len(ids): errs.append(f'{i}: duplicate ingredient')
        for x in r['ingredients']:
            if x['ingredient_id'] not in ing: errs.append(f'{i}: unknown ingredient {x["ingredient_id"]}')
            if x['unit'] not in UNITS: errs.append(f'{i}: bad unit {x["unit"]}')
            if (x['amount'] is None) != (x['unit'] == 'to_taste'): errs.append(f'{i}: amount/unit mismatch {x}')
        if not set(ids) & new_ids: errs.append(f'{i}: uses no new product')
        if r['cook_minutes'] > r['total_minutes']: errs.append(f'{i}: cook > total')
        for k, s in enumerate(r['steps'], 1):
            if len(s['text']) < 20: errs.append(f'{i}: step {k} < 20 chars')
            if set(s) - {'text', 'timer_seconds'}: errs.append(f'{i}: step keys')
        # Dart adds the names and synonyms of the recipe's own products to
        # mention_words (ingredientTerms); mirror that here.
        local = json.loads(json.dumps(safety))
        for rule in local.get('heat_treatment', []):
            targets = set(rule['ingredient_ids'])
            for x in ids:
                if x in targets or targets & set(hier.get(x, [])):
                    v = ing[x]
                    pass  # seed_recipes_valid_test passes no ingredientTerms: keep strict
        errs += [f'{i}: {e}' for e in r9_validator.validate(r, hier, local)]
        errs += r9_tools.seed_quality_errors(r, ing)
    return errs

def lint_all(items, ing):
    data = catalog_with(items)
    # reuse R9 lint, but for the new ids
    applied = r9_tools.applied_ids
    r9_tools.applied_ids = lambda: {r['id'] for r in items}
    try:
        errors, warnings = r9_tools.lint_data(data, ing)
    finally:
        r9_tools.applied_ids = applied
    det = r9_detect.detect(data['recipes'])
    tmpl = [i for i in det if i in {r['id'] for r in items}] if isinstance(det, (dict, set, list)) else []
    errors += [f'{i}: detected as templated {det[i] if isinstance(det, dict) else ""}' for i in tmpl]
    return errors, warnings

def main():
    cmd = sys.argv[1]
    ing = r9_tools.ingredients()
    new_ids = set(json.load(open(NEW_IDS)))
    hier = r9_validator.hierarchy(list(ing.values()))
    safety = json.load(open('spec/ai/safety_minimums.json', encoding='utf-8'))
    r9_tools.READY = set(r9_tools.READY) | set(safety.get('ready_to_eat_ids', []))
    items = store()
    if cmd == 'add':
        batch = json.load(open(sys.argv[2], encoding='utf-8'))['recipes']
        ids_existing = {r['id'] for r in r9_tools.load()['recipes']} | {r['id'] for r in items if r['id'] not in {b['id'] for b in batch}}
        keep = [r for r in items if r['id'] not in {b['id'] for b in batch}]
        errs = check(batch, ids_existing, ing, new_ids, hier, safety, keep + batch)
        if not errs:
            e2, w2 = lint_all(keep + batch, ing)
            errs = [e for e in e2 if e.split(':')[0] in {b['id'] for b in batch} or 'appears in' in e]
        if errs:
            print('REFUSED'); print('\n'.join(errs)); sys.exit(1)
        save_store(keep + batch); print('added', len(batch), 'total', len(keep + batch))
    elif cmd == 'lint':
        e, w = lint_all(items, ing)
        for x in e: print('ERROR', x)
        print('errors', len(e), 'warnings', len(w))
    elif cmd == 'status':
        used = collections.Counter(x['ingredient_id'] for r in items for x in r['ingredients'] if x['ingredient_id'] in new_ids)
        print('recipes', len(items), 'new products used', len(used), 'of', len(new_ids))
        print(collections.Counter(r['dish_type'] for r in items))
    elif cmd == 'unused':
        used = {x['ingredient_id'] for r in items for x in r['ingredients']}
        un = [i for i in json.load(open(NEW_IDS)) if i not in used]
        for i in un: print(i, ing[i]['name'], ing[i]['category'])
    elif cmd == 'export':
        out = []
        for r in items:
            o = {k: r[k] for k in FIELDS}
            o['quality'] = 'curated'
            out.append(o)
        os.makedirs(os.path.dirname(EXPORT), exist_ok=True)
        json.dump({'version': 1, 'recipes': out}, open(EXPORT, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
        print('exported', len(out))

main()
