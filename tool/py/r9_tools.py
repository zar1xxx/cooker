"""R9 pipeline helpers (Python mirror of the Dart tools, for the sandbox).

Commands (run from the project root):
  mark                      add `quality` to every recipe in recipes.json
  queue                     write docs/reports/rewrite/queue.csv
  show [N]                  print the next N (default 20) recipes of one dish_type
  apply BATCH.json          apply a hand-written batch (checks first)
  lint                      lint all curated recipes
  status                    counts

The scripts never generate recipe text. They only read, check and write JSON.
"""
import csv, json, os, re, sys
sys.path.insert(0, os.path.dirname(__file__))
import r9_detect, r9_difficulty, r9_validator

RECIPES = 'assets/seed/recipes.json'
INGREDIENTS = 'assets/seed/ingredients.json'
QUEUE = 'docs/reports/rewrite/queue.csv'
PRIORITY = 'tool/seed_data/priority_dishes.csv'
ALLOWED = {'id', 'description', 'steps', 'total_minutes', 'active_minutes',
           'cook_minutes', 'kcal_per_serving'}
TYPE_ORDER = ['main', 'soup', 'breakfast', 'salad', 'side', 'baking',
              'dessert', 'snack', 'drink', 'preserve']
RAW_ANIMAL_CATEGORIES = {'meat', 'poultry', 'fish'}
READY = {'ham', 'beef_stew', 'tuna_canned', 'saury_canned', 'sardines_canned',
         'lard', 'bacon', 'sausage', 'frankfurters', 'crab_sticks', 'herring'}
MAX_SAME_STEP = 3
APPLIED = 'tool/seed_data/rewrite/applied_ids.txt'
SKIPPED = 'tool/seed_data/rewrite/skipped_ids.txt'


def skipped_ids():
    if not os.path.exists(SKIPPED):
        return set()
    return {l.split('|')[0].strip() for l in open(SKIPPED, encoding='utf-8') if l.strip()}


def applied_ids():
    if not os.path.exists(APPLIED):
        return set()
    return {l.strip() for l in open(APPLIED, encoding='utf-8') if l.strip()}


def load():
    return json.load(open(RECIPES, encoding='utf-8'))


def save(data):
    with open(RECIPES, 'w', encoding='utf-8', newline='') as f:
        f.write(json.dumps(data, ensure_ascii=False, indent=2))


def ingredients():
    return {i['id']: i for i in json.load(open(INGREDIENTS, encoding='utf-8'))['ingredients']}


def cmd_mark():
    data = load()
    det = r9_detect.detect(data['recipes'])
    n_t = n_c = 0
    for r in data['recipes']:
        if r.get('quality') == 'curated':
            q = 'curated'
        else:
            q = 'template' if r['id'] in det else 'curated'
        r['quality'] = q
        n_t += q == 'template'
        n_c += q == 'curated'
    save(data)
    print('template', n_t, 'curated', n_c)


def priority_rank(title, kws):
    low = title.lower()
    for rank, kw in kws:
        if re.search(r'(^|[^а-яё])' + re.escape(kw), low):
            return rank
    return 10_000


def cmd_queue():
    skip = skipped_ids()
    data = load()
    kws = []
    with open(PRIORITY, encoding='utf-8') as f:
        for row in csv.DictReader(f):
            kws.append((int(row['rank']), row['keyword'].lower()))
    groups, rest = {}, []
    for r in data['recipes']:
        if r.get('quality') != 'template':
            continue
        if r['id'] in skip:
            continue
        pr = priority_rank(r['title'], kws)
        t = TYPE_ORDER.index(r['dish_type']) if r['dish_type'] in TYPE_ORDER else 99
        row = (pr, t, r['id'], r['title'], r['dish_type'])
        (rest if pr == 10_000 else groups.setdefault(pr, [])).append(row)
    # Round-robin over the priority keywords, 2 recipes per keyword per round,
    # so the first batches cover many different famous dishes.
    rows = []
    for g in groups.values():
        g.sort(key=lambda x: x[2])
    rounds = max((len(g) + 1) // 2 for g in groups.values())
    for rnd in range(rounds):
        for pr in sorted(groups):
            rows.extend(groups[pr][rnd * 2:(rnd + 1) * 2])
    rest.sort(key=lambda x: (x[1], x[2]))
    rows.extend(rest)
    os.makedirs(os.path.dirname(QUEUE), exist_ok=True)
    with open(QUEUE, 'w', encoding='utf-8', newline='') as f:
        w = csv.writer(f, lineterminator='\n')
        w.writerow(['position', 'id', 'title', 'dish_type', 'priority'])
        for pos, (pr, t, i, title, dt) in enumerate(rows, 1):
            w.writerow([pos, i, title, dt, '' if pr == 10_000 else pr])
    print('queue', len(rows))


def next_batch(n=20):
    data = load()
    by_id = {r['id']: r for r in data['recipes']}
    pending = []
    with open(QUEUE, encoding='utf-8') as f:
        for row in csv.DictReader(f):
            r = by_id[row['id']]
            if r.get('quality') == 'template' and r['id'] not in skipped_ids():
                pending.append(r)
    if not pending:
        return []
    import collections
    near = collections.Counter(r['dish_type'] for r in pending[:80])
    dt = max(near, key=lambda k: (near[k], -TYPE_ORDER.index(k)))
    return [r for r in pending if r['dish_type'] == dt][:n]


def cmd_show(n=20):
    ing = ingredients()
    for r in next_batch(n):
        print(f"## {r['id']} | {r['title']} | {r['dish_type']} | {r['cuisine']} | порц {r['servings']} | "
              f"всего {r['total_minutes']} акт {r['active_minutes']} гот {r.get('cook_minutes')} | ккал {r.get('kcal_per_serving')}")
        print('   ' + '; '.join(
            f"{ing[i['ingredient_id']]['name']}[{i['ingredient_id']}] {'' if i['amount'] is None else format(i['amount'], 'g')} {i['unit']}"
            for i in r['ingredients']))


def norm(text, title):
    return r9_detect.normalize(text, title)


def check_batch(data, batch):
    by_id = {r['id']: r for r in data['recipes']}
    errors = []
    seen = set()
    for item in batch['recipes']:
        i = item.get('id')
        if i not in by_id:
            errors.append(f'{i}: unknown id'); continue
        if i in seen:
            errors.append(f'{i}: duplicate in batch')
        seen.add(i)
        bad = set(item) - ALLOWED
        if bad:
            errors.append(f'{i}: forbidden fields {sorted(bad)}')
        if 'description' not in item or 'steps' not in item:
            errors.append(f'{i}: description and steps required')
            continue
        for k, s in enumerate(item['steps']):
            if set(s) - {'text', 'timer_seconds'}:
                errors.append(f'{i}: step {k + 1} has extra keys')
            if len(s.get('text', '')) < 20:
                errors.append(f'{i}: step {k + 1} shorter than 20 chars')
    return errors


def validator_errors(recipe, hier, safety):
    return r9_validator.validate(recipe, hier, safety)


def cmd_apply(path):
    data = load()
    batch = json.load(open(path, encoding='utf-8'))
    errors = check_batch(data, batch)
    if errors:
        print('REFUSED'); print('\n'.join(errors)); sys.exit(1)
    by_id = {r['id']: r for r in data['recipes']}
    hier = r9_validator.hierarchy(list(ingredients().values()))
    safety = json.load(open('spec/ai/safety_minimums.json', encoding='utf-8'))
    # dry run on copies: refuse the whole batch if the validator rejects any
    problems = []
    for item in batch['recipes']:
        trial = json.loads(json.dumps(by_id[item['id']]))
        for k in ALLOWED - {'id'}:
            if k in item:
                trial[k] = item[k]
        problems += [f"{item['id']}: {e}" for e in validator_errors(trial, hier, safety)]
        problems += seed_quality_errors(trial, ingredients())
    if problems:
        print('REFUSED (validator)'); print('\n'.join(problems)); sys.exit(1)
    for item in batch['recipes']:
        r = by_id[item['id']]
        for k in ALLOWED - {'id'}:
            if k in item:
                r[k] = item[k]
        r['quality'] = 'curated'
        r['difficulty'] = r9_difficulty.difficulty(r)
    save(data)
    ids = applied_ids() | {item['id'] for item in batch['recipes']}
    os.makedirs(os.path.dirname(APPLIED), exist_ok=True)
    with open(APPLIED, 'w', encoding='utf-8', newline='') as f:
        f.write(''.join(i + '\n' for i in sorted(ids)))
    print('applied', len(batch['recipes']))


READINESS = ('мягкост', 'прозрачн', 'золотист', 'пока ', 'румян', 'выпари',
             'загуст', 'свернет', 'готовности мяса', 'готовности риса',
             'готовности овощей')
NON_CUT_CATS = {'grains', 'bakery', 'spices'}
NON_CUT_IDS = {'water', 'milk', 'kefir', 'cream', 'sour_cream', 'oil_vegetable',
               'oil_sunflower', 'oil_olive', 'butter'}


def seed_quality_errors(r, ing):
    """Python port of test/seed_quality_test.dart and heat_cumulative_test.dart
    (R2-02 padding check) for one recipe."""
    errs, i = [], r['id']
    ids = [x['ingredient_id'] for x in r['ingredients']]
    non_staple = [v['name'].lower() for v in ing.values()
                  if not v.get('is_staple') and len(v['name']) >= 4]
    meat = any(x.startswith('minced_') or (x in ing and ing[x]['category'] in RAW_ANIMAL_CATEGORIES) for x in ids)
    if r['dish_type'] == 'soup' and len(r['steps']) < 5:
        errs.append(f'{i}: soup needs >= 5 steps')
    if r['dish_type'] == 'main' and meat and len(r['steps']) < 4:
        errs.append(f'{i}: meat main needs >= 4 steps')
    for k, s in enumerate(r['steps'], 1):
        t = s['text']; low = t.lower()
        if 'остальн' in low and 'продукт' in low:
            errs.append(f'{i}: step {k} "остальные продукты"')
        if 'до готовности' in low and not any(c in low for c in READINESS):
            errs.append(f'{i}: step {k} "до готовности" without readiness cue')
        if 'нарежьте' in low or 'порежьте' in low:
            for x in ids:
                v = ing.get(x)
                if v and (x.startswith('minced_') or x in NON_CUT_IDS or v.get('category') in NON_CUT_CATS) \
                        and v['name'].lower() in low:
                    errs.append(f'{i}: step {k} chops non-cuttable "{v["name"]}"')
        if re.search(r'\d+ минут: ', t):
            errs.append(f'{i}: step {k} looks like padded heat step ("N минут: ")')
        sentences = [p for p in re.split(r'[.!?]+(?:\s+|$)', t.strip()) if p.strip()]
        if len(sentences) > 2:
            errs.append(f'{i}: step {k} has {len(sentences)} sentences (max 2)')
        for a in non_staple:
            if a not in low:
                continue
            for b in non_staple:
                if a != b and (f'{a}, {b}' in low or f'{a} и {b}' in low):
                    errs.append(f'{i}: step {k} lists catalog names "{a}" and "{b}"')
    return errs


def lint_data(data, ing):
    errors, warnings = [], []
    recipes = data['recipes']
    step_count, desc_count = {}, {}
    for r in recipes:
        t = r['title']
        for s in set(norm(x['text'], t) for x in r['steps']):
            step_count[s] = step_count.get(s, 0) + 1
        d = norm(r['description'], t)
        desc_count[d] = desc_count.get(d, 0) + 1
    applied = applied_ids()
    stems = {}
    for i, v in ing.items():
        for name in [v['name']] + list(v.get('synonyms', [])):
            w = name.lower().split()[-1]
            if len(w) >= 5 and not v.get('is_staple'):
                stems.setdefault(w[:max(5, len(w) - 2)], set()).add(i)
    for r in recipes:
        if r['id'] not in applied:
            continue  # only recipes rewritten in R9 are linted
        i, t = r['id'], r['title']
        steps = r['steps']
        texts = [norm(s['text'], t) for s in steps]
        for k, s in enumerate(steps):
            if len(s['text']) < 20:
                errors.append(f'{i}: step {k + 1} shorter than 20 chars')
        if len(set(texts)) != len(texts):
            errors.append(f'{i}: repeated step inside recipe')
        for x in texts:
            if step_count.get(x, 0) > MAX_SAME_STEP:
                errors.append(f'{i}: step appears in {step_count[x]} recipes: {x[:50]}')
        if desc_count.get(norm(r['description'], t), 0) > 1:
            errors.append(f'{i}: description is not unique')
        errors += seed_quality_errors(r, ing)
        timers = sum(s.get('timer_seconds', 0) for s in steps)
        if timers / 60 > r['total_minutes']:
            errors.append(f"{i}: timers {timers // 60} min > total {r['total_minutes']}")
        ids = {x['ingredient_id'] for x in r['ingredients']}
        raw = [x for x in ids if x not in READY and (
            ing[x]['category'] in RAW_ANIMAL_CATEGORIES or x == 'egg')]
        if r['dish_type'] == 'drink':
            raw = [x for x in raw if x != 'egg']
        if raw and not any(s.get('timer_seconds') for s in steps):
            errors.append(f'{i}: raw {raw} but no step with timer_seconds')
        body = ' '.join(s['text'] for s in steps).lower()
        m = re.findall(r'(\d+)\s*(?:яйц|яиц)', body)
        if m:
            have = next((x['amount'] for x in r['ingredients'] if x['ingredient_id'] == 'egg'), 0)
            if any(int(v) > have for v in m):
                errors.append(f'{i}: step mentions more eggs than in ingredients ({have})')
        for stem, owners in stems.items():
            if re.search(r'(^|[^а-яё])' + re.escape(stem), body) and not (owners & ids):
                warnings.append(f'{i}: mentions "{stem}" not in ingredients')
    return errors, warnings


def cmd_lint():
    data = load()
    errors, warnings = lint_data(data, ingredients())
    for e in errors:
        print('ERROR', e)
    for w in warnings:
        print('warn ', w)
    cur = sum(1 for r in data['recipes'] if r.get('quality') == 'curated')
    print(f'curated {cur}, errors {len(errors)}, warnings {len(warnings)}')
    sys.exit(1 if errors else 0)


def cmd_status():
    data = load()
    import collections
    c = collections.Counter((r.get('quality'), r['dish_type']) for r in data['recipes'])
    q = collections.Counter(r.get('quality') for r in data['recipes'])
    print(dict(q))
    for dt in TYPE_ORDER:
        print(dt, 'template', c[('template', dt)], 'curated', c[('curated', dt)])


if __name__ == '__main__':
    cmd = sys.argv[1]
    {'mark': cmd_mark, 'queue': cmd_queue, 'status': cmd_status, 'lint': cmd_lint,
     'show': lambda: cmd_show(int(sys.argv[2]) if len(sys.argv) > 2 else 20),
     'apply': lambda: cmd_apply(sys.argv[2])}[cmd]()
