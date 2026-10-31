"""
fast_translate_all.py
Translates all remaining untranslated question_ur and question_en fields in assets/data/quiz_questions.json
using robust multi-endpoint fallback.

Usage: python3 fast_translate_all.py
"""

import json
import time
import random
import requests
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

DATA_FILE = 'assets/data/quiz_questions.json'
SAVE_EVERY = 25

# Multiple fallback endpoints & clients
ENDPOINTS = [
    ('https://translate.googleapis.com/translate_a/single', {'client': 'dict-chrome-ex'}),
    ('https://translate.googleapis.com/translate_a/single', {'client': 'gtx'}),
    ('https://translate.googleapis.com/translate_a/single', {'client': 'at'}),
    ('https://translate.googleapis.com/translate_a/single', {'client': 't'}),
]

USER_AGENTS = [
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
]


def translate_text(text, dest='ur'):
    if not text or not text.strip():
        return text

    for ep_url, base_params in ENDPOINTS:
        params = dict(base_params)
        params.update({'sl': 'it', 'tl': dest, 'dt': 't', 'q': text})
        headers = {'User-Agent': random.choice(USER_AGENTS)}

        try:
            r = requests.get(ep_url, params=params, headers=headers, timeout=8, verify=False)
            if r.status_code == 200:
                data = r.json()
                if data and data[0]:
                    if isinstance(data[0][0], list):
                        result = ''.join(item[0] for item in data[0] if isinstance(item, list) and item[0])
                    else:
                        result = data[0][0]
                    if result and result.strip() != text.strip():
                        return result
        except Exception:
            pass

    return text


def main():
    print("=" * 60)
    print("  Patente Italiana — Fast Question Translator (100% Completion)")
    print("=" * 60)

    # Connection Test
    print("\n🔍 Testing translation engines...")
    test_ur = translate_text("La carreggiata è a doppio senso", dest='ur')
    test_en = translate_text("La carreggiata è a doppio senso", dest='en')
    print(f"   UR Test: {test_ur}")
    print(f"   EN Test: {test_en}")

    if test_ur == "La carreggiata è a doppio senso":
        print("❌ Translation test failed. Aborting.")
        return

    print("✅ Translation engine is ready!")

    print(f"\n📂 Loading {DATA_FILE}...")
    with open(DATA_FILE, 'r', encoding='utf-8') as f:
        data = json.load(f)

    ur_missing = set(i for i, q in enumerate(data) if q.get('question_ur', '') == q.get('question_it', ''))
    en_missing = set(i for i, q in enumerate(data) if q.get('question_en', '') == q.get('question_it', ''))
    all_missing = sorted(ur_missing | en_missing)

    total_missing = len(all_missing)
    print(f"📊 Missing UR: {len(ur_missing)} | Missing EN: {len(en_missing)} | Total Unique: {total_missing}")
    print("🚀 Translating...\n")

    done = 0
    success_ur = 0
    success_en = 0

    for idx in all_missing:
        q = data[idx]
        it_text = q.get('question_it', '')
        needs_ur = idx in ur_missing
        needs_en = idx in en_missing
        done += 1

        pct = done / total_missing * 100
        status_line = f"[{done:4d}/{total_missing}] {pct:5.1f}% | ID: {q.get('id')}"

        if needs_ur:
            res_ur = translate_text(it_text, dest='ur')
            if res_ur and res_ur != it_text:
                q['question_ur'] = res_ur
                success_ur += 1
                status_line += " | UR ✓"
            else:
                status_line += " | UR ✗"
            time.sleep(0.1)

        if needs_en:
            res_en = translate_text(it_text, dest='en')
            if res_en and res_en != it_text:
                q['question_en'] = res_en
                success_en += 1
                status_line += " | EN ✓"
            else:
                status_line += " | EN ✗"
            time.sleep(0.1)

        print(status_line, flush=True)

        if done % SAVE_EVERY == 0:
            with open(DATA_FILE, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            print(f"   💾 Saved progress ({done}/{total_missing})")

    # Save final
    with open(DATA_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    rem_ur = sum(1 for q in data if q.get('question_ur', '') == q.get('question_it', ''))
    rem_en = sum(1 for q in data if q.get('question_en', '') == q.get('question_it', ''))

    print("\n" + "=" * 60)
    print(f"🎉 COMPLETED!")
    print(f"   Successfully translated UR: {success_ur}")
    print(f"   Successfully translated EN: {success_en}")
    print(f"   Remaining Untranslated UR: {rem_ur}")
    print(f"   Remaining Untranslated EN: {rem_en}")
    print("=" * 60)


if __name__ == '__main__':
    main()
