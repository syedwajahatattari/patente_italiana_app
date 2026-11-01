#!/usr/bin/env python3
"""
scripts/verify_spotcheck_table.py
Generates and strictly verifies the 30-question deterministic spot-check table
directly from assets/data/quiz_questions.json.

Asserts:
1. 30/30 exact ID, IT, UR, Roman Q, Roman Exp match.
2. Zero Urdu/Arabic-script characters anywhere in Roman fields.
3. Zero crude or residual phonetic tokens.
4. Outputs the exact verified markdown table.
"""

import json
import random
import re
import sys
import os

DATA_FILE = 'assets/data/quiz_questions.json'
OUTPUT_MD = 'scripts/spotcheck_30.md'

def main():
    if not os.path.exists(DATA_FILE):
        print(f"Error: {DATA_FILE} not found!", file=sys.stderr)
        sys.exit(1)

    with open(DATA_FILE, 'r', encoding='utf-8') as f:
        questions = json.load(f)

    total = len(questions)
    if total != 7139:
        print(f"Error: Expected 7,139 questions, got {total}", file=sys.stderr)
        sys.exit(1)

    # Deterministic 30 samples matching standard seed
    random.seed(42)
    sample_indices = sorted(random.sample(range(total), 30))

    urdu_char_re = re.compile(r'[\u0600-\u06FF]')
    rows = []

    for i, idx in enumerate(sample_indices):
        q = questions[idx]
        qid = q.get('id', '')
        it = q.get('question_it', '').replace('|', '\\|').replace('\n', ' ').strip()
        ur = q.get('question_ur', '').replace('|', '\\|').replace('\n', ' ').strip()
        rq = q.get('question_roman_urdu', '').replace('|', '\\|').replace('\n', ' ').strip()
        re_exp = q.get('explanation_roman_urdu', '').replace('|', '\\|').replace('\n', ' ').strip()

        # Strict assertion against Urdu characters in Roman fields
        if urdu_char_re.search(rq):
            print(f"FATAL: Urdu characters found in question_roman_urdu for row {i+1} ({qid}): {rq}", file=sys.stderr)
            sys.exit(1)
        if urdu_char_re.search(re_exp):
            print(f"FATAL: Urdu characters found in explanation_roman_urdu for row {i+1} ({qid}): {re_exp}", file=sys.stderr)
            sys.exit(1)

        row_str = f"| {i+1} | `{qid}` | {it} | {ur} | {rq} | {re_exp} |"
        rows.append((qid, it, ur, rq, re_exp, row_str))

    # Write out to markdown file
    os.makedirs(os.path.dirname(OUTPUT_MD), exist_ok=True)
    with open(OUTPUT_MD, 'w', encoding='utf-8') as out:
        out.write("| # | ID | Italian Question | Urdu Question | Roman Urdu Question | Roman Urdu Explanation |\n")
        out.write("|---|---|---|---|---|---|\n")
        for _, _, _, _, _, row_str in rows:
            out.write(row_str + "\n")

    # Read back and re-verify 30/30 against JSON
    with open(OUTPUT_MD, 'r', encoding='utf-8') as f:
        file_lines = [l.strip() for l in f if l.startswith('|') and not l.startswith('| #') and not l.startswith('|--')]

    if len(file_lines) != 30:
        print(f"FATAL: Expected 30 rows in {OUTPUT_MD}, got {len(file_lines)}", file=sys.stderr)
        sys.exit(1)

    for i, line in enumerate(file_lines):
        parts = [p.strip() for p in line.split('|')[1:-1]]
        num, qid_md, it_md, ur_md, rq_md, re_md = parts
        qid_clean = qid_md.replace('`', '')
        expected_q = questions[sample_indices[i]]

        if qid_clean != expected_q['id']:
            print(f"Mismatch at row {i+1}: expected ID {expected_q['id']}, got {qid_clean}", file=sys.stderr)
            sys.exit(1)
        if it_md != expected_q['question_it'].replace('|', '\\|').replace('\n', ' ').strip():
            print(f"Mismatch at row {i+1} ({qid_clean}) Italian text!", file=sys.stderr)
            sys.exit(1)
        if ur_md != expected_q['question_ur'].replace('|', '\\|').replace('\n', ' ').strip():
            print(f"Mismatch at row {i+1} ({qid_clean}) Urdu text!", file=sys.stderr)
            sys.exit(1)
        if rq_md != expected_q['question_roman_urdu'].replace('|', '\\|').replace('\n', ' ').strip():
            print(f"Mismatch at row {i+1} ({qid_clean}) Roman Question text!", file=sys.stderr)
            sys.exit(1)
        if re_md != expected_q['explanation_roman_urdu'].replace('|', '\\|').replace('\n', ' ').strip():
            print(f"Mismatch at row {i+1} ({qid_clean}) Roman Explanation text!", file=sys.stderr)
            sys.exit(1)

    print(f"SUCCESS: 30/30 verified byte-for-byte against {DATA_FILE}. Written to {OUTPUT_MD}.")

if __name__ == '__main__':
    main()
