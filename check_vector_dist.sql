SET SERVEROUTPUT ON;
DECLARE
  v_q1 VARCHAR2(1000) := 'What is the probationary period for new appointments and how long can it be extended?';
  v_q2 VARCHAR2(1000) := 'probation period kitna hai aur kitna extend ho sakta hai?';
  v_emb1 VECTOR;
  v_emb2 VECTOR;
  v_dist NUMBER;
BEGIN
  SELECT VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING v_q1 AS DATA) INTO v_emb1 FROM dual;
  SELECT VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING v_q2 AS DATA) INTO v_emb2 FROM dual;
  v_dist := VECTOR_DISTANCE(v_emb1, v_emb2, COSINE);
  DBMS_OUTPUT.PUT_LINE('Raw Cosine Distance between Q1 and Q2: ' || v_dist);
  
  -- Also check what prompt_embedding was saved in chat_history for msg_id 269
  FOR r IN (SELECT msg_id, user_prompt, (prompt_embedding IS NOT NULL) as has_emb FROM chat_history WHERE msg_id IN (269, 270)) LOOP
    DBMS_OUTPUT.PUT_LINE('Msg ' || r.msg_id || ': ' || r.user_prompt || ' | Has Embedding: ' || CASE WHEN r.has_emb THEN 'YES' ELSE 'NO' END);
  END LOOP;
END;
/
EXIT;
