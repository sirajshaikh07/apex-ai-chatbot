SET SERVEROUTPUT ON;
DECLARE
  v_cnt NUMBER := 0;
BEGIN
  FOR r IN (
    SELECT msg_id, user_prompt
    FROM chat_history
    WHERE prompt_embedding IS NULL
      AND user_prompt IS NOT NULL
      AND ai_response IS NOT NULL
      AND NVL(is_refusal, 'N') = 'N'
  ) LOOP
    BEGIN
      UPDATE chat_history
      SET prompt_embedding = VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING r.user_prompt AS DATA)
      WHERE msg_id = r.msg_id;
      v_cnt := v_cnt + 1;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Skipping msg_id ' || r.msg_id || ': ' || SQLERRM);
    END;
  END LOOP;
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Backfilled embeddings for ' || v_cnt || ' previous chat questions.');
END;
/
EXIT;
