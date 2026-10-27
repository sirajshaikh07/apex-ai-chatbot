SET SERVEROUTPUT ON;
DECLARE
  v_q1 VARCHAR2(1000) := 'What is the probation period?';
  v_q2 VARCHAR2(1000) := 'How long is the probationary period?';
  v_q3 VARCHAR2(1000) := 'What is the probationary period for new appointments and how long can it be extended?';
  v_emb1 VECTOR;
  v_emb2 VECTOR;
  v_emb3 VECTOR;
BEGIN
  SELECT VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING v_q1 AS DATA) INTO v_emb1 FROM dual;
  SELECT VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING v_q2 AS DATA) INTO v_emb2 FROM dual;
  SELECT VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING v_q3 AS DATA) INTO v_emb3 FROM dual;
  
  DBMS_OUTPUT.PUT_LINE('Dist(q1, q2): ' || VECTOR_DISTANCE(v_emb1, v_emb2, COSINE));
  DBMS_OUTPUT.PUT_LINE('Dist(q2, q3): ' || VECTOR_DISTANCE(v_emb2, v_emb3, COSINE));
  DBMS_OUTPUT.PUT_LINE('Dist(q1, q3): ' || VECTOR_DISTANCE(v_emb1, v_emb3, COSINE));
END;
/
EXIT;
