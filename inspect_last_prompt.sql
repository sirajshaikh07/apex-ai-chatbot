SET SERVEROUTPUT ON SIZE UNLIMITED;
SET DEFINE OFF;
ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

BEGIN
  DBMS_OUTPUT.PUT_LINE('Resolved Prompt: ' || enterprise_rag_pkg.g_last_resolved_prompt);
  DBMS_OUTPUT.PUT_LINE('Detected Person: ' || enterprise_rag_pkg.g_last_detected_person);
  DBMS_OUTPUT.PUT_LINE('Detected Project: ' || enterprise_rag_pkg.g_last_detected_proj);
  DBMS_OUTPUT.PUT_LINE('Retrieved Chunks Count: ' || enterprise_rag_pkg.g_last_retrieved_chunks);
  DBMS_OUTPUT.PUT_LINE('Retrieved Chunk IDs: ' || enterprise_rag_pkg.g_last_retrieved_chunk_ids);
  DBMS_OUTPUT.PUT_LINE('Retrieved Scores: ' || enterprise_rag_pkg.g_last_retrieval_scores);
END;
/
EXIT;
