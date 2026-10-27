set define off serveroutput on size unlimited feedback off linesize 200 pagesize 0 trimout on
DECLARE
  l_q VARCHAR2(200) := 'Safa count brother what work';
BEGIN
  dbms_output.put_line('=== VECTOR SEARCH WITH RESOLVED ENGLISH QUERY ===');
  FOR r IN (
    SELECT c.chunk_no, d.title,
           ROUND(VECTOR_DISTANCE(c.embedding, VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING l_q AS data), COSINE), 4) as dist,
           DBMS_LOB.SUBSTR(c.chunk_text, 150, 1) as txt
    FROM   source_docs d
    JOIN   doc_chunks c ON d.doc_id = c.doc_id
    ORDER BY dist ASC
    FETCH FIRST 3 ROWS ONLY
  ) LOOP
    dbms_output.put_line('Rank: Dist=' || r.dist || ' | Doc: ' || r.title || ' Chunk ' || r.chunk_no);
    dbms_output.put_line('Text: ' || r.txt);
    dbms_output.put_line('----------------------------------------------------');
  END LOOP;
END;
/
exit;
