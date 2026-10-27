#!/usr/bin/env python3
"""
Tunes Semantic Cache threshold to 0.0800 and adds exact normalized match.
"""

def main():
    path = "/home/ubuntu/docs/enterprise_rag_pkg.sql"
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    old_condition = "AND VECTOR_DISTANCE(prompt_embedding, l_q_embedding, COSINE) <= 0.0500 -- > 95% similarity"
    new_condition = """AND (
            VECTOR_DISTANCE(prompt_embedding, l_q_embedding, COSINE) <= 0.0800 -- > 92% semantic match
         OR REGEXP_REPLACE(LOWER(user_prompt), '[^a-z0-9]', '') = REGEXP_REPLACE(LOWER(p_question), '[^a-z0-9]', '')
        )"""

    if old_condition in content:
        content = content.replace(old_condition, new_condition, 1)
        print("[SUCCESS] Updated Semantic Cache threshold to 0.0800 + normalized exact match.")
    else:
        print("[WARN] Target condition not found.")

    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

if __name__ == "__main__":
    main()
