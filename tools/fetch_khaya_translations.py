"""Fills in the missing Twi, Ga, Ewe and Dagbani words using the Khaya AI API.

Safe to run again and again: it only asks for words that don't have a
translation yet, and it stops cleanly when Khaya's call quota runs out, so a
later run carries on where this one stopped.

    set KHAYA_API_KEY=your-key-here          (Windows)
    set BOARD_ONLY=1                         (optional: skip the word library)
    set MAX_CALLS=60                         (optional: never spend more than this)
    export KHAYA_API_KEY=your-key-here       (macOS / Linux)
    python tools/fetch_khaya_translations.py

The key is read from the environment on purpose - never put it in a file
that gets committed.
"""
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TARGET = os.path.join(ROOT, 'lib', 'data', 'offline_translations.dart')
DATA_DIR = os.path.join(ROOT, 'lib', 'data')
LANGS = ['tw', 'gaa', 'ee', 'dag']
URL = 'https://translation-api.ghananlp.org/v1/translate'


def board_words():
    """Every English word the board shows, read from the data files."""
    words = set()
    for name in os.listdir(DATA_DIR):
        board_only = os.environ.get('BOARD_ONLY') == '1'
        wanted = ['core_vocabulary.dart', 'context_data.dart',
                  'collections_data.dart']
        if not board_only:
            wanted.append('library_vocabulary.dart')
        if name in wanted:
            text = open(os.path.join(DATA_DIR, name), encoding='utf-8').read()
            words.update(re.findall(r"label: '((?:[^'\\]|\\.)*)'", text))
            words.update(re.findall(r"LibraryWord\('((?:[^'\\]|\\.)*)'", text))
    words.add('feel')
    return words


def load_existing():
    if not os.path.exists(TARGET):
        return {}
    text = open(TARGET, encoding='utf-8').read()
    pairs = re.findall(r"'((?:gaa|tw|ee|dag)\|\|[^']*)':\s*'((?:[^'\\]|\\.)*)'", text)
    return {k: v.replace("\\'", "'") for k, v in pairs}


def translate(word, lang, key):
    body = json.dumps({'in': word, 'lang': f'en-{lang}'}).encode('utf-8')
    req = urllib.request.Request(
        URL, data=body, method='POST',
        headers={'Ocp-Apim-Subscription-Key': key,
                 'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=20) as resp:
        return json.loads(resp.read().decode('utf-8'))


def clean(lang, text):
    """Khaya sometimes treats a single word as a sentence. Drop the added
    full stop, and reject results that are clearly not a word or short
    phrase (long runs of words, or shouting in capitals)."""
    text = text.strip()
    if lang == 'dag':
        text = text.rstrip('.').strip()
    if len(text.split()) > 3 or (len(text) > 3 and text.isupper()):
        return None
    return text or None


def write(existing):
    lines = [
        '/// Pre-translated vocabulary so switching to Twi, Ga, Ewe or Dagbani does not need a',
        '/// live network call for the fixed board. Generated with',
        '/// tools/fetch_khaya_translations.py using the Khaya AI API.',
        '/// Key format matches the in-memory cache: "langCode||English label".',
        '/// Missing entries fall back to the English label until refreshed.',
        '/// DRAFT: machine translation, awaiting review by native speakers.',
        'class OfflineTranslations {',
        '  static const Map<String, String> data = {',
    ]
    for k in sorted(existing):
        key = k.replace("\\", "\\\\").replace("'", "\\'")
        val = existing[k].replace("\\", "\\\\").replace("'", "\\'")
        lines.append(f"    '{key}': '{val}',")
    lines += ['  };', '}', '']
    with open(TARGET, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))


def main():
    key = os.environ.get('KHAYA_API_KEY')
    if not key:
        sys.exit('Set KHAYA_API_KEY first (see the top of this file).')
    existing = load_existing()
    todo = [(lang, w) for w in sorted(board_words()) for lang in LANGS
            if f'{lang}||{w}' not in existing]
    print(f'{len(existing)} translations saved, {len(todo)} still to fetch.')
    limit = int(os.environ.get('MAX_CALLS', '0')) or len(todo)
    todo = todo[:limit]
    print(f'This run will use at most {len(todo)} calls.')
    done = 0
    try:
        for lang, word in todo:
            for attempt in range(4):
                try:
                    result = clean(lang, translate(word, lang, key))
                    if result:
                        existing[f'{lang}||{word}'] = result
                    done += 1
                    break
                except urllib.error.HTTPError as e:
                    if e.code in (403, 429):
                        print('Khaya quota reached - run this again later.')
                        raise SystemExit
                    print(f'skipped {lang}||{word}: HTTP {e.code}')
                    break
                except OSError:  # slow or dropped network: wait and retry
                    time.sleep(3 * (attempt + 1))
            time.sleep(0.3)
    finally:
        write(existing)
    print(f'Saved {done} new translations to {TARGET}')


if __name__ == '__main__':
    main()
