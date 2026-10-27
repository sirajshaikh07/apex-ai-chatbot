set serveroutput on size unlimited feedback off linesize 120
DECLARE
  l_cnt NUMBER;
BEGIN
  DELETE FROM doc_chunks WHERE doc_id = 85;

  INSERT INTO doc_chunks (doc_id, chunk_no, chunk_text, embedding, project_code, keywords)
  SELECT d.doc_id, 
         ROW_NUMBER() OVER (PARTITION BY d.doc_id ORDER BY c.chunk_offset),
         c.chunk_text,
         VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING c.chunk_text AS data),
         CASE 
           WHEN DBMS_LOB.INSTR(UPPER(c.chunk_text), 'PSPCL ANALYTICS') > 0 THEN 'PSPCL_ANALYTICS'
           WHEN DBMS_LOB.INSTR(UPPER(c.chunk_text), 'PSPCL') > 0 THEN 'PSPCL'
           WHEN DBMS_LOB.INSTR(UPPER(c.chunk_text), 'C4T') > 0 THEN 'C4T'
           WHEN DBMS_LOB.INSTR(UPPER(c.chunk_text), 'APEX LLM') > 0 THEN 'APEX_LLM'
           WHEN DBMS_LOB.INSTR(UPPER(c.chunk_text), 'ARCON') > 0 THEN 'ARCON'
           ELSE NULL
         END,
         CASE
           WHEN DBMS_LOB.INSTR(UPPER(c.chunk_text), 'SIRAJ') > 0 THEN 'Siraj'
           ELSE NULL
         END ||
         CASE
           WHEN DBMS_LOB.INSTR(UPPER(c.chunk_text), 'ADITYA') > 0 THEN ', Aditya'
           ELSE NULL
         END ||
         CASE
           WHEN DBMS_LOB.INSTR(UPPER(c.chunk_text), 'YOGITA') > 0 THEN ', Yogita'
           ELSE NULL
         END ||
         CASE
           WHEN DBMS_LOB.INSTR(UPPER(c.chunk_text), 'AMRISH') > 0 THEN ', Amrish'
           ELSE NULL
         END ||
         CASE
           WHEN DBMS_LOB.INSTR(UPPER(c.chunk_text), 'NASIR') > 0 THEN ', Nasir'
           ELSE NULL
         END
  FROM   source_docs d,
         VECTOR_CHUNKS(d.content BY words MAX 500 OVERLAP 50
                       SPLIT BY recursively LANGUAGE american NORMALIZE all) c
  WHERE  d.doc_id = 85;

  SELECT count(*) INTO l_cnt FROM doc_chunks WHERE doc_id = 85;
  dbms_output.put_line('New chunk count for Doc 85: ' || l_cnt);
  COMMIT;
END;
/
exit;
