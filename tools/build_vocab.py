"""Builds Echo's word library from tools/vocab/words_*.txt.

    python tools/build_vocab.py resolve    # match each word to an ARASAAC pictogram
    python tools/build_vocab.py download   # save the pictogram images into assets/library/
    python tools/build_vocab.py generate   # write the Dart files the app uses

Each step can be re-run: work already done is kept. Pictograms are
ARASAAC (Government of Aragon, author Sergio Palao), CC BY-NC-SA.
"""
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VOCAB = os.path.join(ROOT, 'tools', 'vocab')
RESOLVED = os.path.join(VOCAB, 'resolved.json')
IMAGES = os.path.join(ROOT, 'assets', 'library')
DATA = os.path.join(ROOT, 'lib', 'data')
HEADERS = {'User-Agent': 'EchoAAC/1.0 (educational AAC project)'}

# Words whose plain English search finds the wrong pictogram.
QUERY_ALIASES = {
    'Excuse me': 'excuse', 'Maybe': 'perhaps', 'Hurry': 'quickly',
    'Boss': 'boss', 'Trader': 'merchant', 'Stranger': 'unknown person',
    'Sleepy': 'tired', 'Frustrated': 'angry', 'Grateful': 'grateful',
    'Upset': 'annoyed', 'Peaceful': 'calm', 'Believe': 'believe',
    'Borrow': 'lend', 'Dangerous': 'danger', 'Busy': 'busy',
    'Possible': 'possible', 'Hidden': 'hide', 'Porridge': 'oatmeal',
    'Compound': 'yard', 'Stroller': 'baby carriage', 'Uniform': 'school uniform',
    'Headscarf': 'scarf', 'Puppy': 'puppy', 'Headmaster': 'principal',
    'Singing': 'sing', 'Quran': 'koran', 'Sermon': 'preach',
    'Tradition': 'custom', 'Discount': 'sale', 'Banknote': 'banknote',
    'Debt': 'owe', 'Profit': 'money', 'Bargain': 'negotiate',
    'Sell out': 'sold out', 'Crossing': 'pedestrian crossing',
    'Come here': 'come', 'Kind': 'kind', 'Cool': 'cool', 'Light': 'light',
    'Right': 'right', 'Fair': 'fair', 'Free': 'free', 'Bill': 'bill',
    'Change': 'change', 'Ring': 'ring', 'Well': 'well', 'Bank': 'bank',
    'Left': 'left', 'Fly insect': 'fly', 'Ring on finger': 'ring',
    'Watch on wrist': 'wristwatch', 'Clock': 'clock', 'Cook a meal': 'cook',
    'Go fishing': 'fishing', 'Get dressed': 'get dressed',
    'Scale for weighing': 'scales', 'Crab': 'crab', 'Crab meat': 'crab',
    'Crab meat ': 'crab', 'Lose game': 'lose', 'Draw picture': 'drawing',
    'Bottle for baby': 'baby bottle', 'Cards game': 'playing cards',
    'Football': 'football', 'Petrol': 'petrol', 'Hot drink': 'hot drink',
    'Cold drink': 'cold drink', 'Team game': 'team',
    'Broom stick': 'broom', 'Pray': 'pray', 'Fingernail': 'nail',
    'Old man': 'old man', 'Old woman': 'old woman', 'Sell out': 'sold out',
    'Full price': 'price', 'Free of charge': 'free', 'Ticket office': 'ticket',
    'Luggage cart': 'luggage', 'Crossing': 'crosswalk',
    'Drum beat': 'drum', 'Village chief': 'chief', 'Traditional dance': 'dance',
    'Break time': 'recess', 'Picture book': 'book', 'Water bottle': 'water bottle',
    'Drinking straw': 'straw', 'Lunch box': 'lunch box', 'Soup bowl': 'soup',
    'Watermelon juice': 'watermelon', 'Crab meat': 'crab',
    'Lonely': 'lonely', 'Grapes': 'grapes', 'Beans': 'beans',
}


# Words retried with a more specific search after the first pictogram was
# judged wrong by eye.
RETRY_ALIASES = {
    'Chief': 'chief', 'Guest': 'guest', 'Old man': 'elderly man',
    'Old woman': 'elderly woman', 'Catch': 'catch ball', 'Kick': 'kick ball',
    'Lift': 'lift', 'Pull': 'pull', 'Close': 'close door',
    'Turn off': 'switch off', 'Watch': 'look', 'Call': 'phone call',
    'Wave': 'wave hand', 'Wear': 'put on', 'Orange': 'orange fruit',
    'Corn': 'corn', 'Pot': 'saucepan', 'Pan': 'frying pan',
    'Glass': 'drinking glass', 'Key': 'door key', 'Sink': 'sink basin',
    'Mouse': 'mouse', 'Card': 'card', 'Eraser': 'rubber', 'Plane': 'aeroplane',
    'Shorts': 'shorts', 'Dress': 'dress', 'Cross': 'cross',
}


def dropped():
    path = os.path.join(VOCAB, 'drop.txt')
    if not os.path.exists(path):
        return set()
    return {ln.strip() for ln in open(path, encoding='utf-8')
            if ln.strip() and not ln.startswith('#')}


def existing_labels():
    labels = set()
    for name in ('core_vocabulary.dart', 'context_data.dart',
                 'collections_data.dart'):
        text = open(os.path.join(DATA, name), encoding='utf-8').read()
        labels.update(re.findall(r"label: '((?:[^'\\]|\\.)*)'", text))
    return labels


def read_words():
    """[(category_english, category_es, category_fr, [(en, es, fr)])]"""
    cats, seen = [], set(existing_labels()) | dropped()
    by_name = {}
    for f in sorted(os.listdir(VOCAB)):
        if not (f.startswith('words_') and f.endswith('.txt')):
            continue
        for raw in open(os.path.join(VOCAB, f), encoding='utf-8'):
            line = raw.strip()
            if not line:
                continue
            if line.startswith('#'):
                en, es, fr = [p.strip() for p in line[1:].split('|')]
                if en not in by_name:
                    by_name[en] = (en, es, fr, [])
                    cats.append(by_name[en])
                current = by_name[en]
                continue
            parts = [p.strip() for p in line.split('|')]
            if len(parts) != 3:
                print('bad line:', line)
                continue
            if parts[0] in seen:
                continue
            seen.add(parts[0])
            current[3].append(tuple(parts))
    return cats


def api(path):
    for attempt in range(4):
        try:
            req = urllib.request.Request(
                'https://api.arasaac.org/v1' + path, headers=HEADERS)
            with urllib.request.urlopen(req, timeout=25) as r:
                return json.loads(r.read().decode('utf-8'))
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return []
            time.sleep(2 * (attempt + 1))
        except Exception:
            time.sleep(2 * (attempt + 1))
    return None


def pick(query, results):
    """Choose the best pictogram for [query] from the API results."""
    q = query.lower()

    def keywords(p):
        return [k.get('keyword', '').lower() for k in p.get('keywords', [])]

    def ok(p):
        return not p.get('violence') and not p.get('sex')

    pool = [p for p in results if ok(p)] or results
    exact = [p for p in pool if q in keywords(p)]
    partial = [p for p in pool if any(q in k for k in keywords(p))]
    for group, label in ((exact, 'exact'), (partial, 'partial'), (pool, 'first')):
        if not group:
            continue
        # Prefer pictograms made for AAC that are not abstract schematics.
        group = sorted(group, key=lambda p: (
            not p.get('aac', False), p.get('schematic', False)))
        return group[0]['_id'], label
    return None, 'none'


def resolve():
    resolved = json.load(open(RESOLVED, encoding='utf-8')) if os.path.exists(RESOLVED) else {}
    words = [w for c in read_words() for w in c[3]]
    print(len(words), 'words;', len(resolved), 'already resolved')
    for i, (en, _, _) in enumerate(words):
        if en in resolved:
            continue
        query = RETRY_ALIASES.get(en) or QUERY_ALIASES.get(en, en.lower())
        results = api('/pictograms/en/search/' + urllib.parse.quote(query))
        if results is None:
            print('network problem, stopping - run again')
            break
        pid, how = pick(query, results)
        resolved[en] = {'id': pid, 'how': how, 'query': query}
        if i % 40 == 0:
            json.dump(resolved, open(RESOLVED, 'w', encoding='utf-8'), indent=0)
            print(i, en, '->', pid, how)
        time.sleep(0.12)
    json.dump(resolved, open(RESOLVED, 'w', encoding='utf-8'), indent=0)
    missing = [w for w, v in resolved.items() if not v['id']]
    print('done. no pictogram found for', len(missing), ':', missing[:60])


def download():
    resolved = json.load(open(RESOLVED, encoding='utf-8'))
    os.makedirs(IMAGES, exist_ok=True)
    ids = sorted({v['id'] for v in resolved.values() if v['id']})
    print(len(ids), 'unique pictograms')
    failed = []
    for n, pid in enumerate(ids):
        dest = os.path.join(IMAGES, f'{pid}.png')
        if os.path.exists(dest) and os.path.getsize(dest) > 0:
            continue
        url = f'https://static.arasaac.org/pictograms/{pid}/{pid}_300.png'
        try:
            req = urllib.request.Request(url, headers=HEADERS)
            with urllib.request.urlopen(req, timeout=30) as r:
                data = r.read()
            with open(dest, 'wb') as f:
                f.write(data)
        except Exception as e:
            failed.append(pid)
            print('failed', pid, e)
        if n % 100 == 0:
            print(n, 'of', len(ids))
        time.sleep(0.08)
    print('failed:', failed)


def dart(s):
    return s.replace('\\', '\\\\').replace("'", "\\'")


def slug(s):
    return re.sub(r'[^a-z0-9]+', '_', s.lower()).strip('_')


def generate():
    resolved = json.load(open(RESOLVED, encoding='utf-8'))
    have = {f[:-4] for f in os.listdir(IMAGES) if f.endswith('.png')}
    cats = read_words()

    lib, tr = [], {}
    total = 0
    for en, es, fr, words in cats:
        kept = []
        for w_en, w_es, w_fr in words:
            info = resolved.get(w_en)
            if not info or not info['id'] or str(info['id']) not in have:
                continue
            kept.append((w_en, str(info['id'])))
            tr[f'es||{w_en}'] = w_es
            tr[f'fr||{w_en}'] = w_fr
        if not kept:
            continue
        tr[f'es||{en}'] = es
        tr[f'fr||{en}'] = fr
        total += len(kept)
        lib.append((en, kept))

    used = {pid for _, kept in lib for _, pid in kept}
    removed = 0
    for f in os.listdir(IMAGES):
        if f.endswith('.png') and f[:-4] not in used:
            os.remove(os.path.join(IMAGES, f))
            removed += 1
    print('removed', removed, 'unused images')

    out = ["""// GENERATED by tools/build_vocab.py - do not edit by hand.
// Pictograms: ARASAAC (Government of Aragon), author Sergio Palao, CC BY-NC-SA.

class LibraryWord {
  final String label;
  final String pictogramId;
  const LibraryWord(this.label, this.pictogramId);
}

class LibraryCategory {
  final String id;
  final String label;
  final List<LibraryWord> words;
  const LibraryCategory(this.id, this.label, this.words);
}

class LibraryVocabulary {
  static const List<LibraryCategory> categories = [
"""]
    for en, kept in lib:
        out.append(f"    LibraryCategory('{slug(en)}', '{dart(en)}', [\n")
        for label, pid in kept:
            out.append(f"      LibraryWord('{dart(label)}', '{pid}'),\n")
        out.append('    ]),\n')
    out.append("""  ];

  /// English word -> bundled pictogram id, for every word in the library.
  static final Map<String, String> pictogramIds = {
    for (final c in categories)
      for (final w in c.words) w.label: w.pictogramId,
  };

  static int get wordCount =>
      categories.fold(0, (sum, c) => sum + c.words.length);
}
""")
    with open(os.path.join(DATA, 'library_vocabulary.dart'), 'w', encoding='utf-8') as f:
        f.write(''.join(out))

    t = ["""// GENERATED by tools/build_vocab.py - do not edit by hand.
// Spanish and French words for the word library. DRAFT: awaiting native review.
class LibraryTranslations {
  static const Map<String, String> data = {
"""]
    for k in sorted(tr):
        t.append(f"    '{dart(k)}': '{dart(tr[k])}',\n")
    t.append('  };\n}\n')
    with open(os.path.join(DATA, 'offline_translations_library.dart'), 'w', encoding='utf-8') as f:
        f.write(''.join(t))
    print(f'wrote {total} words in {len(lib)} categories')


if __name__ == '__main__':
    step = sys.argv[1] if len(sys.argv) > 1 else ''
    {'resolve': resolve, 'download': download, 'generate': generate}.get(
        step, lambda: print(__doc__))()
