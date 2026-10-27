#!/usr/bin/env python3
"""
Updates enterprise_rag_pkg.sql to:
1. Boost chunks that match detected person AND pending status ('NOT STARTED' / 'IN PROGRESS') to dist = 0.0300.
2. Order retrieved passages by n.dist ASC, c.doc_id, c.chunk_no instead of strictly chunk_no.
3. Apply strict line-level Assignee Isolation in l_safe_chunk so other people's tasks are completely stripped.
4. Skip chunks that do not contain the target person's records.
"""

import re

def main():
    path = '/home/ubuntu/docs/enterprise_rag_pkg.sql'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Boost in key_cand for detected person + pending status
    old_key_boost = """      key_cand AS (
        SELECT c.doc_id, c.chunk_id, c.chunk_no,
               CASE
                 -- Highest boost: Detected entity + Query keyword match
                 WHEN l_detected_person IS NOT NULL AND UPPER(c.chunk_text) LIKE '%' || UPPER(l_detected_person) || '%'
                  AND l_token1 IS NOT NULL AND UPPER(c.chunk_text) LIKE '%' || l_token1 || '%'
                 THEN 0.0500"""

    new_key_boost = """      key_cand AS (
        SELECT c.doc_id, c.chunk_id, c.chunk_no,
               CASE
                 -- Absolute highest priority: Detected entity + Pending status match
                 WHEN l_detected_person IS NOT NULL AND UPPER(c.chunk_text) LIKE '%' || UPPER(l_detected_person) || '%'
                  AND (UPPER(c.chunk_text) LIKE '%NOT STARTED%' OR UPPER(c.chunk_text) LIKE '%IN PROGRESS%')
                  AND (UPPER(l_search_q) LIKE '%NOT STARTED%' OR UPPER(l_search_q) LIKE '%IN PROGRESS%' OR UPPER(l_search_q) LIKE '%PENDING%')
                 THEN 0.0300
                 -- Highest boost: Detected entity + Query keyword match
                 WHEN l_detected_person IS NOT NULL AND UPPER(c.chunk_text) LIKE '%' || UPPER(l_detected_person) || '%'
                  AND l_token1 IS NOT NULL AND UPPER(c.chunk_text) LIKE '%' || l_token1 || '%'
                 THEN 0.0500"""

    if old_key_boost in content:
        content = content.replace(old_key_boost, new_key_boost, 1)
        print("[SUCCESS] Applied key_cand pending status boost.")
    else:
        print("[WARN] Could not find old_key_boost.")

    # 2. Change ORDER BY in retrieved_cand loop to order by relevance first
    old_order = """      SELECT d.title, c.chunk_id, c.chunk_no, c.chunk_text, n.dist
      FROM retrieved_cand n
      JOIN doc_chunks c ON n.chunk_id = c.chunk_id
      JOIN source_docs d ON c.doc_id = d.doc_id
      WHERE n.rn = 1 AND d.status = 'ACTIVE'
      ORDER BY c.doc_id, c.chunk_no"""

    new_order = """      SELECT d.title, c.chunk_id, c.chunk_no, c.chunk_text, n.dist
      FROM retrieved_cand n
      JOIN doc_chunks c ON n.chunk_id = c.chunk_id
      JOIN source_docs d ON c.doc_id = d.doc_id
      WHERE n.rn = 1 AND d.status = 'ACTIVE'
      ORDER BY n.dist ASC, c.doc_id, c.chunk_no"""

    if old_order in content:
        content = content.replace(old_order, new_order, 1)
        print("[SUCCESS] Reordered passage loop by dist ASC.")
    else:
        print("[WARN] Could not find old_order.")

    # 3. Add Strict Assignee Line Isolation Filter
    old_filter_anchor = """      -- If plain text task list, compact Description and Comments for list/enumeration queries so all chunks fit within context budget
      IF (UPPER(p_question) LIKE '%ALL%' OR UPPER(p_question) LIKE '%LIST%' OR UPPER(p_question) LIKE '%EVERY%' OR UPPER(p_question) LIKE '%TITLE%' OR UPPER(p_question) LIKE '%SAB%' OR UPPER(p_question) LIKE '%SAARE%') THEN
        IF INSTR(UPPER(l_safe_chunk), 'ASSIGNEE:') > 0 OR INSTR(UPPER(l_safe_chunk), 'STATUS:') > 0 THEN
          l_safe_chunk := REGEXP_REPLACE(l_safe_chunk, 'Description:\s*[^0-9\\n]{25,}', 'Description: [omitted] ');
          l_safe_chunk := REGEXP_REPLACE(l_safe_chunk, 'Comments?:\\s*[^0-9\\n]{25,}', 'Comments: [omitted] ');
        END IF;
      END IF;"""

    new_filter_insertion = """      -- If plain text task list, compact Description and Comments for list/enumeration queries so all chunks fit within context budget
      IF (UPPER(p_question) LIKE '%ALL%' OR UPPER(p_question) LIKE '%LIST%' OR UPPER(p_question) LIKE '%EVERY%' OR UPPER(p_question) LIKE '%TITLE%' OR UPPER(p_question) LIKE '%SAB%' OR UPPER(p_question) LIKE '%SAARE%') THEN
        IF INSTR(UPPER(l_safe_chunk), 'ASSIGNEE:') > 0 OR INSTR(UPPER(l_safe_chunk), 'STATUS:') > 0 THEN
          l_safe_chunk := REGEXP_REPLACE(l_safe_chunk, 'Description:\s*[^0-9\\n]{25,}', 'Description: [omitted] ');
          l_safe_chunk := REGEXP_REPLACE(l_safe_chunk, 'Comments?:\\s*[^0-9\\n]{25,}', 'Comments: [omitted] ');
        END IF;
      END IF;

      -- Strict Assignee Isolation: If a specific person is requested, strip all tasks belonging to other people
      IF l_detected_person IS NOT NULL AND INSTR(UPPER(l_safe_chunk), 'ASSIGNEE:') > 0 THEN
        DECLARE
          l_temp_chunk VARCHAR2(32767);
          l_filtered   VARCHAR2(32767) := '';
          l_line       VARCHAR2(4000);
          l_line_cnt   INTEGER;
        BEGIN
          -- Normalize custom delimiter '----' or '---' to line breaks
          l_temp_chunk := REGEXP_REPLACE(l_safe_chunk, '\\-{3,}', CHR(10));
          l_line_cnt := REGEXP_COUNT(l_temp_chunk, '[^' || CHR(10) || CHR(13) || ']+');
          FOR idx IN 1 .. l_line_cnt LOOP
            l_line := TRIM(REGEXP_SUBSTR(l_temp_chunk, '[^' || CHR(10) || CHR(13) || ']+', 1, idx));
            IF l_line IS NOT NULL THEN
              IF INSTR(UPPER(l_line), 'ASSIGNEE:') > 0 THEN
                -- Must match the detected person
                IF UPPER(l_line) LIKE '%' || UPPER(l_detected_person) || '%' THEN
                  IF l_filtered IS NOT NULL THEN
                    l_filtered := l_filtered || CHR(10);
                  END IF;
                  l_filtered := l_filtered || l_line;
                END IF;
              ELSE
                -- Keep non-assignee lines ONLY IF they are not assigned to someone else
                IF INSTR(UPPER(l_line), 'OWNER:') = 0 OR UPPER(l_line) LIKE '%' || UPPER(l_detected_person) || '%' THEN
                  IF l_filtered IS NOT NULL THEN
                    l_filtered := l_filtered || CHR(10);
                  END IF;
                  l_filtered := l_filtered || l_line;
                END IF;
              END IF;
            END IF;
          END LOOP;

          IF l_filtered IS NOT NULL THEN
            l_safe_chunk := l_filtered;
          END IF;
        END;
      END IF;

      -- Skip chunks that do not contain the target person's records after filtering
      IF l_detected_person IS NOT NULL AND INSTR(UPPER(l_safe_chunk), UPPER(l_detected_person)) = 0 THEN
        CONTINUE;
      END IF;"""

    if old_filter_anchor in content:
        content = content.replace(old_filter_anchor, new_filter_insertion, 1)
        print("[SUCCESS] Added Assignee Isolation Filter.")
    else:
        print("[WARN] Could not find old_filter_anchor.")

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("[DONE] Updated enterprise_rag_pkg.sql")

if __name__ == '__main__':
    main()
