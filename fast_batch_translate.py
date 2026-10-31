"""
fast_batch_translate.py
Translates all remaining questions where question_ur == question_it or question_en == question_it
using robust multi-client Google Translate rotation with automatic progress saving and retry logic.
"""

import json
import time
import random
import urllib.request
import urllib.parse
import concurrent.futures
import sys

DATA_FILE = 'assets/data/quiz_questions.json'
SAVE_INTERVAL = 25
MAX_WORKERS = 5

CLIENTS = ['dict-chrome-ex', 'at', 'gtx']
USER_AGENTS = [
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_3_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Safari/605.1.15',
]

def translate_single(text, lang='ur'):
    if not text or not text.strip():
        return text
    
    clients_to_try = list(CLIENTS)
    random.shuffle(clients_to_try)

    for client in clients_to_try:
        url = f"https://translate.googleapis.com/translate_a/single?client={client}&sl=it&tl={lang}&dt=t&q={urllib.parse.quote(text)}"
        headers = {
            'User-Agent': random.choice(USER_AGENTS),
            'Accept': '*/*',
        }
        req = urllib.request.Request(url, headers=headers)
        for attempt in range(2):
            try:
                with urllib.request.urlopen(req, timeout=7) as resp:
                    if resp.status == 200:
                        data = json.loads(resp.read().decode('utf-8'))
                        res = ''.join(item[0] for item in data[0] if item and item[0])
                        if res and res.strip() != text.strip():
                            return res
            except Exception:
                time.sleep(0.3 * (attempt + 1))
    return None

def process_item(item):
    idx, q = item
    it = q.get('question_it', '')
    needs_ur = q.get('question_ur', '').strip() == it.strip()
    needs_en = q.get('question_en', '').strip() == it.strip()

    ur_res = None
    en_res = None

    if needs_ur:
        ur_res = translate_single(it, 'ur')
    if needs_en:
        en_res = translate_single(it, 'en')

    return idx, ur_res, en_res

def main():
    print(f"Loading {DATA_FILE}...")
    with open(DATA_FILE, 'r', encoding='utf-8') as f:
        data = json.load(f)

    to_translate = []
    for idx, q in enumerate(data):
        it = q.get('question_it', '').strip()
        needs_ur = q.get('question_ur', '').strip() == it
        needs_en = q.get('question_en', '').strip() == it
        if needs_ur or needs_en:
            to_translate.append((idx, q))

    total = len(to_translate)
    print(f"Found {total} questions needing translation.")
    if total == 0:
        print("All questions are already 100% translated!")
        return

    completed = 0
    success_ur = 0
    success_en = 0
    t0 = time.time()

    with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        for idx, ur_res, en_res in executor.map(process_item, to_translate):
            completed += 1
            if ur_res:
                data[idx]['question_ur'] = ur_res
                success_ur += 1
            if en_res:
                data[idx]['question_en'] = en_res
                success_en += 1

            if completed % 10 == 0 or completed == total:
                elapsed = time.time() - t0
                rate = completed / elapsed if elapsed > 0 else 1
                eta = (total - completed) / rate if rate > 0 else 0
                print(f"Progress: [{completed}/{total}] {completed/total*100:5.1f}% | UR+ {success_ur} | EN+ {success_en} | Rate: {rate:.1f} q/s | ETA: {eta:.0f}s", flush=True)

            if completed % SAVE_INTERVAL == 0:
                with open(DATA_FILE, 'w', encoding='utf-8') as f:
                    json.dump(data, f, ensure_ascii=False, indent=2)

    with open(DATA_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"\nFinished! Total translated UR: {success_ur}, EN: {success_en}. Saved to {DATA_FILE}.")

if __name__ == '__main__':
    main()
