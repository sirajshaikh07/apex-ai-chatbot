SET SERVEROUTPUT ON;
DECLARE
  v_raw VARCHAR2(1000) := 'probation period kitna hai aur kitna extend ho sakta hai?';
  v_trans VARCHAR2(1000);
  v_q1 VARCHAR2(1000) := 'What is the probationary period for new appointments and how long can it be extended?';
  v_emb1 VECTOR;
  v_emb2 VECTOR;
  v_dist NUMBER;
BEGIN
  v_trans := ENTERPRISE_RAG_PKG.RESOLVE_HINGLISH(v_raw);
  DBMS_OUTPUT.PUT_LINE('Raw Hindi:      ' || v_raw);
  DBMS_OUTPUT.PUT_LINE('Resolved Query: ' || v_trans);
  
  SELECT VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING v_q1 AS DATA) INTO v_emb1 FROM dual;
  SELECT VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING v_trans AS DATA) INTO v_emb2 FROM dual;
  v_dist := VECTOR_DISTANCE(v_emb1, v_emb2, COSINE);
  DBMS_OUTPUT.PUT_LINE('Cosine Distance with resolved query: ' || v_dist);
END;
/
EXIT;
