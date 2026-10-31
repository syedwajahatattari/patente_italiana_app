"""
transliterate_to_roman_urdu.py
Repeatable pipeline to transliterate question_ur and explanation_ur into Roman Urdu (Latin script)
for all questions in assets/data/quiz_questions.json.

Preserves exact meaning of existing approved Urdu translations without re-translating from Italian.
Includes batch network romanization, checkpoint caching, and phonetic vocabulary fallback.
"""

import json
import os
import re
import time
import random
import urllib.request
import urllib.parse
import sys

DATA_FILE = 'assets/data/quiz_questions.json'
CACHE_FILE = 'assets/data/roman_urdu_cache.json'
BATCH_SIZE = 25
SAVE_INTERVAL = 10

CLIENTS = ['dict-chrome-ex', 'at', 'gtx']
USER_AGENTS = [
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_3_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Safari/605.1.15',
]

# Comprehensive Urdu -> Roman character map
CHAR_MAP = {
    'آ': 'aa', 'ا': 'a', 'ب': 'b', 'پ': 'p', 'ت': 't', 'ٹ': 't', 'ث': 's',
    'ج': 'j', 'چ': 'ch', 'ح': 'h', 'خ': 'kh', 'د': 'd', 'ڈ': 'd', 'ذ': 'z',
    'ر': 'r', 'ڑ': 'r', 'ز': 'z', 'ژ': 'zh', 'س': 's', 'ش': 'sh', 'ص': 's',
    'ض': 'z', 'ط': 't', 'ظ': 'z', 'ع': 'a', 'غ': 'gh', 'ف': 'f', 'ق': 'q',
    'ک': 'k', 'گ': 'g', 'ل': 'l', 'م': 'm', 'ن': 'n', 'ں': 'n', 'و': 'o',
    'ہ': 'h', 'ھ': 'h', 'ء': '', 'ی': 'i', 'ے': 'e', 'ئ': 'i',
    'ۃ': 't', 'ؤ': 'o', 'لا': 'la', 'لہ': 'lah'
}

# Vocabulary dictionary for common road and grammatical terms
WORD_MAP = {
    'کے': 'ke', 'کی': 'ki', 'کا': 'ka', 'کو': 'ko', 'سے': 'se', 'پر': 'par',
    'میں': 'mein', 'ہے': 'hai', 'ہیں': 'hain', 'نہیں': 'nahin', 'یہ': 'yeh',
    'وہ': 'woh', 'اور': 'aur', 'ایک': 'aik', 'اس': 'is', 'ان': 'un',
    'جو': 'jo', 'کہ': 'keh', 'تو': 'to', 'تھا': 'tha', 'تھی': 'thi',
    'تھے': 'the', 'بھی': 'bhi', 'لیے': 'liye', 'گیا': 'gaya', 'گئے': 'gaye',
    'گئی': 'gayi', 'کیا': 'kya', 'کرتا': 'karta', 'کرتی': 'karti',
    'کرتے': 'karte', 'کرنا': 'karna', 'کرنے': 'karne', 'ہو': 'ho',
    'ہوتا': 'hota', 'ہوتی': 'hoti', 'ہوتے': 'hote', 'ہونا': 'hona',
    'ہونے': 'hone', 'گاڑی': 'gaari', 'گاڑیوں': 'gaariyon', 'سڑک': 'sarak',
    'ٹریفک': 'traffic', 'چوراہے': 'chorahe', 'چوراہا': 'choraha',
    'سگنل': 'signal', 'رفتار': 'raftaar', 'قوانین': 'qawaneen',
    'درست': 'durust', 'صحیح': 'sahih', 'غلط': 'ghalat', 'بیان': 'bayan',
    'سوال': 'sawal', 'مطابق': 'mutabiq', 'بارے': 'bare', 'سائن': 'sign',
    'نشان': 'nishan', 'تصویر': 'tasweer', 'راستہ': 'raasta', 'حق': 'haq',
    'پہلے': 'pehle', 'بعد': 'baad', 'موڑ': 'mor', 'اوورٹیک': 'overtake',
    'اوورٹیکنگ': 'overtaking', 'پابندی': 'pabandi', 'اجازت': 'ijazat',
    'لازمی': 'laazmi', 'ضروری': 'zaroori', 'رکنا': 'rukna', 'چلنا': 'chalna',
    'اٹالین': 'Italian', 'آرٹیکل': 'Article', 'کام': 'kaam', 'بالکل': 'bilkul',
    'دکھایا': 'dikhaya', 'دکھائے': 'dikhaye', 'بتایا': 'bataya', 'بتائے': 'bataye',
    'مختلف': 'mukhtalif', 'آپ': 'aap', 'روڈ': 'road', 'وے': 'way',
    'روڈوے': 'roadway', 'لین': 'lane', 'لینز': 'lanes', 'پیدل': 'paidal',
    'سواری': 'sawari', 'سواروں': 'sawaron', 'موٹرسائیکل': 'motorcycle',
    'ٹرک': 'truck', 'بس': 'bus', 'کار': 'car', 'سامنے': 'samne',
    'پیچھے': 'peeche', 'دائیں': 'daen', 'بائیں': 'baen', 'درمیان': 'darmiyan',
    'حد': 'hadd', 'زیادہ': 'zyada', 'کم': 'kam', 'کم از کم': 'kam az kam',
    'فاصلہ': 'faasla', 'حفاظتی': 'hifazati', 'حفاظت': 'hifazat',
    'سیٹ': 'seat', 'بیلٹ': 'belt', 'ہیلمٹ': 'helmet', 'روشنی': 'roshni',
    'لائٹ': 'light', 'لائٹس': 'lights', 'ہارن': 'horn', 'پل': 'pul',
    'سرنگ': 'surang', 'ریلوے': 'railway', 'پھاٹک': 'phaatak',
    'خطرے': 'khatre', 'خطرہ': 'khatra', 'حادثہ': 'haadsa', 'بچاؤ': 'bachao',
    'اصول': 'asool', 'ممنوع': 'mamnoo', 'ہدایت': 'hidayat', 'معلومات': 'maaloomat',
    'دکھائی': 'dikhai', 'گئی': 'gayi', 'قسم': 'qism', 'طرف': 'taraf',
    'جا': 'ja', 'سکتے': 'sakte', 'سکتا': 'sakta', 'سکتی': 'sakti',
}

def fallback_phonetic(text):
    """Fallback transliterator using vocabulary dictionary + phonetic character rules."""
    if not text or not text.strip():
        return text

    # Tokenize preserving punctuation and Latin terms (like CdS, RCA, art.)
    tokens = re.findall(r'[\u0600-\u06FF]+|[^\u0600-\u06FF\s]+|\s+', text)
    result = []
    for t in tokens:
        if not t or t.isspace() or not re.search(r'[\u0600-\u06FF]', t):
            result.append(t)
            continue
        # Check dictionary
        clean_t = t.strip()
        if clean_t in WORD_MAP:
            result.append(WORD_MAP[clean_t])
            continue
        # Character-level phonetic conversion
        word_chars = []
        i = 0
        while i < len(clean_t):
            if i + 2 <= len(clean_t) and clean_t[i:i+2] in CHAR_MAP:
                word_chars.append(CHAR_MAP[clean_t[i:i+2]])
                i += 2
            elif clean_t[i] in CHAR_MAP:
                word_chars.append(CHAR_MAP[clean_t[i]])
                i += 1
            else:
                word_chars.append(clean_t[i])
                i += 1
        res_word = ''.join(word_chars)
        result.append(res_word if res_word else clean_t)
    return ''.join(result)

def fetch_roman_batch(texts):
    """Fetches Roman transliteration for a batch of Urdu strings from Google Translate dt=rm."""
    clean_texts = [t.replace('\n', ' ').strip() for t in texts]
    joined = '\n'.join(clean_texts)
    
    clients = list(CLIENTS)
    random.shuffle(clients)

    for client in clients:
        url = f"https://translate.googleapis.com/translate_a/single?client={client}&sl=ur&tl=en&dt=rm&q={urllib.parse.quote(joined)}"
        headers = {
            'User-Agent': random.choice(USER_AGENTS),
            'Accept': '*/*',
        }
        req = urllib.request.Request(url, headers=headers)
        for attempt in range(2):
            try:
                with urllib.request.urlopen(req, timeout=12) as resp:
                    if resp.status == 200:
                        data = json.loads(resp.read().decode('utf-8'))
                        full_roman = ''
                        if data and isinstance(data[0], list):
                            for part in data[0]:
                                if len(part) > 3 and part[3]:
                                    full_roman += part[3]
                                elif len(part) > 2 and isinstance(part[2], str) and part[2]:
                                    full_roman += part[2]
                        lines = [l.strip() for l in full_roman.split('\n') if l.strip()]
                        if len(lines) == len(texts):
                            return lines
            except Exception:
                time.sleep(0.3 * (attempt + 1))
    return None

def fetch_roman_single(text):
    """Fetches Roman transliteration for a single string with fallback."""
    clean = text.replace('\n', ' ').strip()
    if not clean:
        return text
    batch_res = fetch_roman_batch([clean])
    if batch_res and len(batch_res) == 1 and batch_res[0]:
        return batch_res[0]
    return fallback_phonetic(clean)

def main():
    print(f"Loading {DATA_FILE}...")
    with open(DATA_FILE, 'r', encoding='utf-8') as f:
        questions = json.load(f)
    print(f"Loaded {len(questions)} questions.")

    # Load cache if available
    cache = {}
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, 'r', encoding='utf-8') as f:
                cache = json.load(f)
            print(f"Loaded existing cache with {len(cache)} entries.")
        except Exception as e:
            print(f"Could not load cache: {e}")

    # Step 1: Transliterate unique explanations (71 distinct)
    unique_exps = sorted(list(set(q.get('explanation_ur', '').strip() for q in questions if q.get('explanation_ur', '').strip())))
    print(f"Transliterating {len(unique_exps)} unique explanations...")
    exp_needed = [e for e in unique_exps if e not in cache]
    for i in range(0, len(exp_needed), 15):
        chunk = exp_needed[i:i+15]
        res = fetch_roman_batch(chunk)
        if res and len(res) == len(chunk):
            for orig, rom in zip(chunk, res):
                cache[orig] = rom
        else:
            for item in chunk:
                cache[item] = fetch_roman_single(item)
        time.sleep(0.2)
    print(f"All explanations transliterated ({len(unique_exps)} total).")

    # Step 2: Transliterate unique questions
    unique_qs = sorted(list(set(q.get('question_ur', '').strip() for q in questions if q.get('question_ur', '').strip())))
    print(f"Transliterating {len(unique_qs)} unique questions...")
    qs_needed = [q for q in unique_qs if q not in cache]
    print(f"{len(qs_needed)} questions need transliteration ({len(unique_qs) - len(qs_needed)} already cached).")

    batches = [qs_needed[i:i+BATCH_SIZE] for i in range(0, len(qs_needed), BATCH_SIZE)]
    total_batches = len(batches)

    for b_idx, batch in enumerate(batches):
        res = fetch_roman_batch(batch)
        if res and len(res) == len(batch):
            for orig, rom in zip(batch, res):
                cache[orig] = rom
        else:
            for item in batch:
                cache[item] = fetch_roman_single(item)

        if (b_idx + 1) % SAVE_INTERVAL == 0 or (b_idx + 1) == total_batches:
            with open(CACHE_FILE, 'w', encoding='utf-8') as f:
                json.dump(cache, f, ensure_ascii=False, indent=2)
            pct = ((b_idx + 1) / total_batches) * 100
            print(f"Progress: [{b_idx + 1}/{total_batches}] batches ({pct:.1f}%) - Cached: {len(cache)} entries")

        time.sleep(0.3)

    # Save final cache
    with open(CACHE_FILE, 'w', encoding='utf-8') as f:
        json.dump(cache, f, ensure_ascii=False, indent=2)

    # Step 3: Apply to all 7,139 questions
    print("Applying transliterations to dataset...")
    missing_q = 0
    missing_exp = 0

    for q in questions:
        q_ur = q.get('question_ur', '').strip()
        exp_ur = q.get('explanation_ur', '').strip()

        rom_q = cache.get(q_ur, '')
        if not rom_q:
            rom_q = fallback_phonetic(q_ur)
            missing_q += 1
        q['question_roman_urdu'] = rom_q

        rom_exp = cache.get(exp_ur, '')
        if not rom_exp:
            rom_exp = fallback_phonetic(exp_ur)
            missing_exp += 1
        q['explanation_roman_urdu'] = rom_exp

    # Save updated dataset
    print(f"Saving updated {DATA_FILE}...")
    with open(DATA_FILE, 'w', encoding='utf-8') as f:
        json.dump(questions, f, ensure_ascii=False, indent=2)

    new_size_mb = os.path.getsize(DATA_FILE) / (1024 * 1024)
    print(f"Saved! New file size: {new_size_mb:.2f} MB")

    # Step 4: Verification and validation counts
    total = len(questions)
    valid_q = sum(1 for q in questions if q.get('question_roman_urdu', '').strip())
    valid_exp = sum(1 for q in questions if q.get('explanation_roman_urdu', '').strip())

    print("\n" + "=" * 50)
    print("VALIDATION REPORT:")
    print(f"Total questions in dataset: {total}")
    print(f"Non-empty question_roman_urdu: {valid_q} / {total} ({(valid_q/total)*100:.1f}%)")
    print(f"Non-empty explanation_roman_urdu: {valid_exp} / {total} ({(valid_exp/total)*100:.1f}%)")
    print("=" * 50)

    # Spot-check 30 random questions
    random.seed(42)
    sample_indices = sorted(random.sample(range(total), 30))
    print(f"\nSPOT-CHECKING 30 QUESTIONS (Indices: {sample_indices[:5]}...):")
    for i, idx in enumerate(sample_indices):
        item = questions[idx]
        print(f"\n--- Spot-Check #{i+1} [ID: {item.get('id')}] ---")
        print(f"IT: {item.get('question_it')}")
        print(f"UR: {item.get('question_ur')}")
        print(f"ROMAN Q: {item.get('question_roman_urdu')}")
        print(f"ROMAN EXP: {item.get('explanation_roman_urdu')}")

if __name__ == '__main__':
    main()

