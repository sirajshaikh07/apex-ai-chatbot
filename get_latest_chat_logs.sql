SET LINESIZE 300;
SET PAGESIZE 100;
SET SERVEROUTPUT ON SIZE UNLIMITED;

ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

BEGIN
  DBMS_OUTPUT.PUT_LINE('=== LATEST CHAT HISTORY LOGS ===');
  FOR r IN (
    SELECT msg_id, session_id, user_prompt, SUBSTR(ai_response, 1, 300) as ans,
           sources, retrieved_chunks, retrieved_chunk_ids, retrieval_scores,
           prompt_chars, completion_chars, response_time_ms, created_at
    FROM chat_history
    ORDER BY msg_id DESC
    FETCH FIRST 5 ROWS ONLY
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('--- MSG_ID: ' || r.msg_id || ' | Session: ' || r.session_id || ' | Time: ' || r.created_at || ' ---');
    DBMS_OUTPUT.PUT_LINE('Prompt: ' || r.user_prompt);
    DBMS_OUTPUT.PUT_LINE('Chunks: ' || r.retrieved_chunks || ' | IDs: ' || r.retrieved_chunk_ids);
    DBMS_OUTPUT.PUT_LINE('Scores: ' || r.retrieval_scores);
    DBMS_OUTPUT.PUT_LINE('Latency: ' || r.response_time_ms || ' ms | Prompt chars: ' || r.prompt_chars || ' | Resp chars: ' || r.completion_chars);
    DBMS_OUTPUT.PUT_LINE('Answer: ' || r.ans);
    DBMS_OUTPUT.PUT_LINE(' ');
  END LOOP;
END;
/
EXIT;
