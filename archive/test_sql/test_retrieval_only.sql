set serveroutput on size unlimited feedback off linesize 120
DECLARE
  l_start NUMBER := DBMS_UTILITY.GET_TIME;
  l_cnt NUMBER := 0;
  l_q VARCHAR2(100) := 'How many projects are there';
BEGIN
  FOR r IN (
    SELECT c.chunk_id, ROUND(VECTOR_DISTANCE(c.embedding, VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING l_q AS data), COSINE), 4) as dist
    FROM doc_chunks c
    ORDER BY dist ASC
    FETCH FIRST 5 ROWS ONLY
  ) LOOP
    l_cnt := l_cnt + 1;
    dbms_output.put_line('Chunk ' || r.chunk_id || ' dist: ' || r.dist);
  END LOOP;
  dbms_output.put_line('Retrieval time: ' || ((DBMS_UTILITY.GET_TIME - l_start)*10) || ' ms, rows: ' || l_cnt);
END;
/
exit;
