"""Python mirror of the parts of lib/core/ai/recipe_validator.dart that a
rewritten recipe can break: size limits, garbage text, timer sum, heat
treatment (D-R2). Used in the sandbox where Dart cannot run; the real
validator runs in test/seed_recipes_valid_test.dart on the PC."""
import json, re

_REPEAT = re.compile(r'([^\s])\1{3,}')
_ALLOWED = re.compile(r"^[Ѐ-ӿa-zA-Z0-9\s\.,\-–—!?'\"«»\(\)%;:/№°~+&=@\[\]]+$")


def garbage(text):
    t = text.strip()
    if not t:
        return None
    if '**' in t:
        return 'contains **'
    if _REPEAT.search(t):
        return 'repeated chars'
    if not _ALLOWED.match(t):
        bad = sorted({c for c in t if not _ALLOWED.match(c)})
        return 'forbidden chars %s' % bad
    return None


def heat_minutes(step, text):
    m = (step.get('timer_seconds') or 0) / 60
    for g in re.findall(r'(\d+)\s*(?:мин|минут|минуты)', text):
        m = max(m, float(g))
    for g in re.findall(r'(\d+(?:[.,]\d+)?)\s*(?:ч|час|часа|часов)', text):
        m = max(m, float(g.replace(',', '.')) * 60)
    return m


def hierarchy(ingredients):
    by = {i['id']: i for i in ingredients}
    out = {}
    for i in ingredients:
        parents, p = [], i.get('parent_id')
        while p and p not in parents:
            parents.append(p)
            p = by.get(p, {}).get('parent_id')
        out[i['id']] = parents
    return out


def validate(recipe, hier, safety):
    errs = []
    title = recipe['title']
    for field, val in (('title', title), ('description', recipe.get('description', ''))):
        g = garbage(val)
        if g:
            errs.append(f'{field}: {g}')
    if len(recipe.get('description', '')) > 300:
        errs.append('description > 300 chars')
    total = recipe['total_minutes']
    if not 5 <= total <= 600:
        errs.append('total_minutes out of range')
    act = recipe.get('active_minutes')
    if act is not None and (act < 1 or act > total):
        errs.append('active_minutes out of range')
    steps = recipe['steps']
    if not 2 <= len(steps) <= 20:
        errs.append('steps count must be 2..20')
    timers = 0
    for k, s in enumerate(steps, 1):
        t = s['text']
        if not 3 <= len(t.strip()) <= 240:
            errs.append(f'step {k}: length {len(t.strip())} not in 3..240')
        g = garbage(t)
        if g:
            errs.append(f'step {k}: {g}')
        tm = s.get('timer_seconds')
        if tm is not None:
            if tm < 0 or tm > 36000:
                errs.append(f'step {k}: timer out of range')
            timers += tm
    if timers > round(total * 60 * 1.1):
        errs.append(f'timers {timers}s exceed total {total} min (+10%)')
    full = ' '.join([title, recipe.get('description', '')] + [s['text'] for s in steps]).lower()
    for stop in safety.get('stop_list', []):
        if stop.lower().strip() and stop.lower().strip() in full:
            errs.append(f'stop-list: {stop}')
    ids = {i['ingredient_id'] for i in recipe['ingredients']}
    heat_ids = ids - set(safety.get('ready_to_eat_ids', []))
    for rule in safety.get('heat_treatment', []):
        if recipe['dish_type'] in rule.get('except_dish_types', []):
            continue
        targets = set(rule['ingredient_ids'])
        has = any(i in targets or targets & set(hier.get(i, [])) for i in heat_ids)
        if not has:
            continue
        mention = [w.lower().strip() for w in rule.get('mention_words', []) if w.strip()]
        start = next((k for k, s in enumerate(steps)
                      if any(w in s['text'].lower() for w in mention)), 0)
        keys = rule.get('keywords', [])
        total_heat = 0.0
        for s in steps[start:]:
            tx = s['text'].lower()
            if any(k in tx for k in keys):
                total_heat += heat_minutes(s, tx)
        if total_heat < rule.get('min_minutes', 10):
            errs.append(f"heat: {rule['category']} needs {rule.get('min_minutes', 10)} min, has {total_heat:g}")
    return errs
