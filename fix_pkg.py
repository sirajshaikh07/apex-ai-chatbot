#!/usr/bin/env python3
"""
Applies exact string replacements to enterprise_rag_pkg.sql to enforce entity isolation.
"""

def main():
    path = '/home/ubuntu/docs/enterprise_rag_pkg.sql'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. key_cand WHERE clause
    old_key_pattern = r"WHERE\s+d\.status\s*=\s*'ACTIVE'\s+AND\s+\(\s+\(l_detected_person IS NOT NULL AND UPPER\(c\.chunk_text\) LIKE '%' \|\| UPPER\(l_detected_person\) \|\| '%'\)\s+OR\s+\(l_detected_proj IS NOT NULL AND UPPER\(c\.chunk_text\) LIKE '%' \|\| REPLACE\(l_detected_proj, '_', ' '\) \|\| '%'\)\s+OR\s+\(l_token1 IS NOT NULL AND LENGTH\(l_token1\) >= 3 AND UPPER\(c\.chunk_text\) LIKE '%' \|\| l_token1 \|\| '%'\)\s+OR\s+\(l_token2 IS NOT NULL AND LENGTH\(l_token2\) >= 3 AND UPPER\(c\.chunk_text\) LIKE '%' \|\| l_token2 \|\| '%'\)\s+OR\s+\(l_token3 IS NOT NULL AND LENGTH\(l_token3\) >= 3 AND UPPER\(c\.chunk_text\) LIKE '%' \|\| l_token3 \|\| '%'\)\s+\)"
    
    new_key_replacement = """WHERE  d.status = 'ACTIVE'
          AND  (l_detected_person IS NULL OR UPPER(c.chunk_text) LIKE '%' || UPPER(l_detected_person) || '%')
          AND  (
               (l_detected_person IS NOT NULL)
           OR  (l_detected_proj IS NOT NULL AND UPPER(c.chunk_text) LIKE '%' || REPLACE(l_detected_proj, '_', ' ') || '%')
           OR  (l_token1 IS NOT NULL AND LENGTH(l_token1) >= 3 AND UPPER(c.chunk_text) LIKE '%' || l_token1 || '%')
           OR  (l_token2 IS NOT NULL AND LENGTH(l_token2) >= 3 AND UPPER(c.chunk_text) LIKE '%' || l_token2 || '%')
           OR  (l_token3 IS NOT NULL AND LENGTH(l_token3) >= 3 AND UPPER(c.chunk_text) LIKE '%' || l_token3 || '%')
          )"""

    import re
    if re.search(old_key_pattern, content):
        content = re.sub(old_key_pattern, new_key_replacement, content, count=1)
        print("[SUCCESS] Replaced key_cand WHERE clause.")
    else:
        print("[WARN] Could not match key_cand pattern via regex.")

    # 2. retrieved_cand adjacent expansion
    old_retrieved_pattern = r"AND\s+\(\s+\(\s+\(UPPER\(p_question\) LIKE '%ALL%' OR UPPER\(p_question\) LIKE '%LIST%' OR UPPER\(p_question\) LIKE '%EVERY%' OR UPPER\(p_question\) LIKE '%TITLE%' OR UPPER\(p_question\) LIKE '%SAB%' OR UPPER\(p_question\) LIKE '%SAARE%'\)\s+AND c\.chunk_id = t\.chunk_id \)\s+OR\s+\(\s+NOT \(UPPER\(p_question\) LIKE '%ALL%' OR UPPER\(p_question\) LIKE '%LIST%' OR UPPER\(p_question\) LIKE '%EVERY%' OR UPPER\(p_question\) LIKE '%TITLE%' OR UPPER\(p_question\) LIKE '%SAB%' OR UPPER\(p_question\) LIKE '%SAARE%'\)\s+AND c\.chunk_no BETWEEN GREATEST\(1, t\.chunk_no - 1\) AND \(t\.chunk_no \+ 1\) \)\s+\)"

    new_retrieved_replacement = """AND (
           ( (l_detected_person IS NOT NULL OR UPPER(p_question) LIKE '%ALL%' OR UPPER(p_question) LIKE '%LIST%' OR UPPER(p_question) LIKE '%EVERY%' OR UPPER(p_question) LIKE '%TITLE%' OR UPPER(p_question) LIKE '%SAB%' OR UPPER(p_question) LIKE '%SAARE%')
             AND c.chunk_id = t.chunk_id )
           OR
           ( l_detected_person IS NULL
             AND NOT (UPPER(p_question) LIKE '%ALL%' OR UPPER(p_question) LIKE '%LIST%' OR UPPER(p_question) LIKE '%EVERY%' OR UPPER(p_question) LIKE '%TITLE%' OR UPPER(p_question) LIKE '%SAB%' OR UPPER(p_question) LIKE '%SAARE%')
             AND c.chunk_no BETWEEN GREATEST(1, t.chunk_no - 1) AND (t.chunk_no + 1) )
         )"""

    if re.search(old_retrieved_pattern, content):
        content = re.sub(old_retrieved_pattern, new_retrieved_replacement, content, count=1)
        print("[SUCCESS] Replaced retrieved_cand adjacent expansion.")
    else:
        print("[WARN] Could not match retrieved_cand pattern via regex.")

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == "__main__":
    main()
