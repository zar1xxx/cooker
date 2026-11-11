"""Python mirror of tool/detect_templated_recipes.dart (same rules).

Used where Dart cannot run. Reads assets/seed/recipes.json, returns the ids
of templated recipes. No text is generated here.
"""
import json, re, sys

PREFIX = 40
SHARED = 10


def normalize(text, title):
    t = (text or '').strip()
    if title:
        t = t.replace(title, '{T}').replace(title.lower(), '{T}')
    return re.sub(r'\d+', 'N', t)


def detect(recipes):
    prefix_ids, desc_ids, text_ids = {}, {}, {}
    for r in recipes:
        i, title = r['id'], r.get('title', '')
        d = normalize(r.get('description', ''), title)
        if d:
            desc_ids.setdefault(d, set()).add(i)
        for s in r.get('steps', []):
            t = normalize(s.get('text', ''), title)
            if not t:
                continue
            prefix_ids.setdefault(t[:PREFIX], set()).add(i)
            text_ids.setdefault(t, set()).add(i)
    out = {}
    for r in recipes:
        i, title = r['id'], r.get('title', '')
        reasons = []
        d = normalize(r.get('description', ''), title)
        if d and len(desc_ids.get(d, ())) >= SHARED:
            reasons.append('description-shared')
        shared = unique = 0
        steps = r.get('steps', [])
        for s in steps:
            t = normalize(s.get('text', ''), title)
            if not t:
                continue
            ids = prefix_ids.get(t[:PREFIX], set())
            others = len(ids) - (1 if i in ids else 0)
            if others >= SHARED:
                shared += 1
            if len(text_ids.get(t, {i})) == 1:
                unique += 1
        if shared >= 2:
            reasons.append('steps-shared(%d)' % shared)
        if steps and unique == 0:
            reasons.append('no-unique-step')
        if reasons:
            out[i] = '; '.join(reasons)
    return out


if __name__ == '__main__':
    path = sys.argv[1] if len(sys.argv) > 1 else 'assets/seed/recipes.json'
    data = json.load(open(path, encoding='utf-8'))
    det = detect(data['recipes'])
    print(len(det), 'templated of', len(data['recipes']))
