"""Python port of lib/core/catalog/difficulty_calculator.dart (calculateFromJson)."""

_RULES = [
    (3, ['слоен', 'корж', 'слоев', 'пропитк', 'выпекать корж', 'наполеон', 'медовик', 'пахлав', 'круассан']),
    (2, ['расстойк', 'опар', 'дрожжев', 'дать подняться тест', 'поднимется тест',
         'в теплое место для подъем', 'в тёплое место для подъем', 'кулебяк', 'хачапури']),
    (2, ['раскатать', 'раскатыва', 'скалк', 'раскатк', 'раскатай']),
    (2, ['карамел', 'темперир', 'до янтарного цвет', 'макарон', 'глазирование', 'эклеры']),
]
_MOLD_COMPLEX = ['пельмен', 'вареник', 'хинкал', 'лепить пельмени', 'лепим пельмени', 'лепим вареники', 'защипну']
_MOLD_SIMPLE = ['котлет', 'сырник', 'сформировать', 'сформовать', 'формуем', 'слепи', 'голубц', 'оладь']
_AFTER = [
    ['выпек', 'выпекать', 'духовк', 'запекани', 'запечь', 'шарлотк', 'бисквит'],
    ['блин', 'блинчик', 'оладь', 'панкейк'],
    ['водян баня', 'водяной бан', 'на пару', 'суфле'],
    ['фритюр', 'в большом количестве масла', 'фритюрниц'],
    ['пока варится', 'пока закипает', 'пока запекается', 'пока тушится', 'параллельно',
     'одновременно', 'тем временем', 'солянк', 'лазань', 'борщ', 'холодец', 'оливье'],
]


def _any(text, pats):
    return any(p in text for p in pats)


def difficulty(recipe):
    total = recipe.get('total_minutes', 30)
    active = recipe.get('active_minutes')
    if active is None or active <= 0:
        active = total if total <= 20 else int(round(total * 0.5 + 1e-9))
    steps = [s['text'] for s in recipe.get('steps', [])]
    n_ing = len(recipe.get('ingredients', []))
    pts = 0
    pts += 3 if active > 50 else 2 if active >= 31 else 1 if active >= 16 else 0
    n = len(steps)
    pts += 3 if n >= 11 else 2 if n >= 8 else 1 if n >= 5 else 0
    pts += 3 if n_ing >= 13 else 2 if n_ing >= 9 else 1 if n_ing >= 6 else 0
    text = ' '.join([recipe.get('title', ''), recipe.get('description') or '', *steps]).lower()
    for weight, pats in _RULES:
        if _any(text, pats):
            pts += weight
    if _any(text, _MOLD_COMPLEX):
        pts += 1
    elif _any(text, _MOLD_SIMPLE):
        pts += 1
    for pats in _AFTER:
        if _any(text, pats):
            pts += 1
    return 'easy' if pts <= 3 else 'medium' if pts <= 7 else 'hard'
