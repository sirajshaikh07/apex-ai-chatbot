#!/usr/bin/env python3
"""
Applies Strategy 1 (Smart Context Budgeting) and Strategy 3 (Semantic Caching)
to enterprise_rag_pkg.sql.
"""

def main():
    pkg_path = "/home/ubuntu/docs/enterprise_rag_pkg.sql"
    with open(pkg_path, "r", encoding="utf-8") as f:
        content = f.read()

    # 1. Add Semantic Cache check right after l_search_q := resolve_hinglish(l_resolved_q);
    target_cache_hook = "l_search_q := resolve_hinglish(l_resolved_q);"
    
    cache_check_code = """l_search_q := resolve_hinglish(l_resolved_q);

    -- =========================================================================
    -- Strategy 3: In-Database Semantic Answer Caching (< 20ms response)
    -- =========================================================================
    DECLARE
      l_q_embedding VECTOR;
    BEGIN
      SELECT VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING l_search_q AS DATA)
      INTO l_q_embedding FROM dual;

      FOR hit IN (
        SELECT ai_response, sources, msg_id,
               ROUND(VECTOR_DISTANCE(prompt_embedding, l_q_embedding, COSINE), 4) as cache_dist
        FROM chat_history
        WHERE prompt_embedding IS NOT NULL
          AND (user_feedback IS NULL OR user_feedback = 'UP')
          AND NVL(is_refusal, 'N') = 'N'
          AND ai_response IS NOT NULL
          AND DBMS_LOB.GETLENGTH(ai_response) > 20
          AND VECTOR_DISTANCE(prompt_embedding, l_q_embedding, COSINE) <= 0.0500 -- > 95% similarity
        ORDER BY cache_dist ASC
        FETCH FIRST 1 ROW ONLY
      ) LOOP
        p_answer := hit.ai_response;
        p_sources := hit.sources || ' [⚡ Instant Semantic Cache Hit]';
        l_elapsed_ms := ROUND((DBMS_UTILITY.GET_TIME - l_start_time) * 10);
        
        g_last_resolved_prompt     := l_resolved_q;
        g_last_detected_proj       := l_detected_proj;
        g_last_detected_person     := l_detected_person;
        g_last_retrieved_chunks    := 0;
        g_last_retrieved_chunk_ids := 'CACHE_HIT';
        g_last_retrieval_scores    := TO_CHAR(hit.cache_dist);
        g_last_prompt_chars        := LENGTH(p_question);
        g_last_completion_chars    := DBMS_LOB.GETLENGTH(p_answer);
        g_last_is_refusal          := 'N';
        g_last_response_time_ms    := GREATEST(15, l_elapsed_ms);
        RETURN;
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN NULL;
    END;"""

    if target_cache_hook in content and "Strategy 3: In-Database Semantic Answer Caching" not in content:
        content = content.replace(target_cache_hook, cache_check_code, 1)
        print("[SUCCESS] Injected Strategy 3: Semantic Cache Check into ask_with_context.")
    else:
        print("[INFO] Strategy 3 hook already present or anchor not found.")

    # 2. Strategy 1: Smart Context Budgeting in top_cand
    old_top_cand = """      top_cand AS (
        SELECT doc_id, chunk_id, chunk_no, dist
        FROM ranked_cand
        WHERE cand_rank <= CASE 
          WHEN (UPPER(p_question) LIKE '%ALL%' OR UPPER(p_question) LIKE '%LIST%' OR UPPER(p_question) LIKE '%EVERY%' OR UPPER(p_question) LIKE '%TITLE%' OR UPPER(p_question) LIKE '%SAB%' OR UPPER(p_question) LIKE '%SAARE%') THEN 25 
          ELSE 6 
        END
      ),"""

    new_top_cand = """      top_cand AS (
        SELECT doc_id, chunk_id, chunk_no, dist
        FROM ranked_cand
        WHERE cand_rank <= CASE 
          WHEN (UPPER(p_question) LIKE '%ALL%' OR UPPER(p_question) LIKE '%LIST%' OR UPPER(p_question) LIKE '%EVERY%' OR UPPER(p_question) LIKE '%TITLE%' OR UPPER(p_question) LIKE '%SAB%' OR UPPER(p_question) LIKE '%SAARE%') THEN 25 
          ELSE 2 -- Strategy 1: Smart Context Budgeting for point queries (Top 2 dense chunks)
        END
      ),"""

    if old_top_cand in content:
        content = content.replace(old_top_cand, new_top_cand, 1)
        print("[SUCCESS] Injected Strategy 1: Top 2 chunks budgeting into top_cand.")
    else:
        print("[INFO] top_cand replacement pattern already updated or not found.")

    # 3. Strategy 1: Smart Context window budgeting cap (1500 chars for point queries, 3500 for list queries)
    old_ctx_cap = """      -- Context window budgeting: cap raw chunk context at 3,500 chars (dense UGDS format, executes in < 15s on CPU)
      IF NVL(DBMS_LOB.GETLENGTH(l_context), 0) < 3500 THEN"""

    new_ctx_cap = """      -- Strategy 1: Smart Context Window Budgeting (1,500 chars for point queries, 3,500 for lists)
      IF NVL(DBMS_LOB.GETLENGTH(l_context), 0) < CASE
           WHEN (UPPER(p_question) LIKE '%ALL%' OR UPPER(p_question) LIKE '%LIST%' OR UPPER(p_question) LIKE '%EVERY%' OR UPPER(p_question) LIKE '%TITLE%' OR UPPER(p_question) LIKE '%SAB%' OR UPPER(p_question) LIKE '%SAARE%') THEN 3500
           ELSE 1500
         END THEN"""

    if old_ctx_cap in content:
        content = content.replace(old_ctx_cap, new_ctx_cap, 1)
        print("[SUCCESS] Injected Strategy 1: 1,500 chars dynamic context budget cap.")
    else:
        print("[INFO] Context cap replacement pattern already updated or not found.")

    # 4. Update prompt instruction to emphasize complete, thorough answers without truncating
    old_prompt_instr = "'9. Clean Formatting: Be concise, clear, and professional. Provide the direct answer first, using clean bullet points where appropriate.' || CHR(10) || CHR(10);"
    new_prompt_instr = "'9. Complete & Accurate Explanation: Answer thoroughly, accurately, and completely based SOLELY on the provided context passages. Do not cut off or truncate key details, numbers, durations, conditions, or exceptions.' || CHR(10) || CHR(10);"

    if old_prompt_instr in content:
        content = content.replace(old_prompt_instr, new_prompt_instr, 1)
        print("[SUCCESS] Updated system prompt to guarantee complete, detailed explanations.")

    # 5. Save prompt_embedding in overloaded ask_with_context INSERT into chat_history
    old_insert = """    INSERT INTO chat_history (
      session_id, user_name, user_prompt, ai_response, sources,
      resolved_prompt, detected_project, detected_person,
      retrieved_chunks, retrieved_chunk_ids, retrieval_scores,
      prompt_chars, completion_chars, is_refusal, response_time_ms
    ) VALUES (
      p_session_id, p_user_name, p_question, p_answer, p_sources,
      g_last_resolved_prompt, g_last_detected_proj, g_last_detected_person,
      g_last_retrieved_chunks, g_last_retrieved_chunk_ids, g_last_retrieval_scores,
      g_last_prompt_chars, g_last_completion_chars, g_last_is_refusal, g_last_response_time_ms
    ) RETURNING msg_id INTO p_msg_id;"""

    new_insert = """    INSERT INTO chat_history (
      session_id, user_name, user_prompt, ai_response, sources,
      resolved_prompt, detected_project, detected_person,
      retrieved_chunks, retrieved_chunk_ids, retrieval_scores,
      prompt_chars, completion_chars, is_refusal, response_time_ms,
      prompt_embedding
    ) VALUES (
      p_session_id, p_user_name, p_question, p_answer, p_sources,
      g_last_resolved_prompt, g_last_detected_proj, g_last_detected_person,
      g_last_retrieved_chunks, g_last_retrieved_chunk_ids, g_last_retrieval_scores,
      g_last_prompt_chars, g_last_completion_chars, g_last_is_refusal, g_last_response_time_ms,
      VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING NVL(g_last_resolved_prompt, p_question) AS DATA)
    ) RETURNING msg_id INTO p_msg_id;"""

    if old_insert in content:
        content = content.replace(old_insert, new_insert, 1)
        print("[SUCCESS] Added prompt_embedding to chat_history INSERT.")

    with open(pkg_path, "w", encoding="utf-8") as f:
        f.write(content)

    print("Completed updating enterprise_rag_pkg.sql.")

if __name__ == "__main__":
    main()
