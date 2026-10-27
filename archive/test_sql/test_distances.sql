set serveroutput on size unlimited feedback off linesize 200 pagesize 0 trimout on
DECLARE
  PROCEDURE test_dist(p_q VARCHAR2) IS
    l_min_dist NUMBER := 999;
    l_best_title VARCHAR2(200);
    l_best_txt VARCHAR2(300);
  BEGIN
    FOR r IN (
      SELECT d.title, DBMS_LOB.SUBSTR(c.chunk_text, 100, 1) as txt,
             ROUND(VECTOR_DISTANCE(c.embedding, VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING p_q AS data), COSINE), 4) as dist
      FROM   source_docs d
      JOIN   doc_chunks c ON d.doc_id = c.doc_id
      ORDER BY dist ASC
      FETCH FIRST 1 ROWS ONLY
    ) LOOP
      l_min_dist := r.dist;
      l_best_title := r.title;
      l_best_txt := r.txt;
    END LOOP;
    dbms_output.put_line('Q: "' || p_q || '" => Min Cosine Dist: ' || l_min_dist || ' (Best doc: ' || l_best_title || ')');
  END;
BEGIN
  dbms_output.put_line('=== TESTING COSINE DISTANCES ===');
  test_dist('Who is Rohit Labade?');
  test_dist('What is Safa Pathan contact number?');
  test_dist('Tell me about Tamanna Shaikh education');
  test_dist('Aaj ka mausam kaisa hai?');
  test_dist('What is the cricket score?');
  test_dist('What is the refund policy for cancellation of airline tickets?');
  test_dist('Tell me about stock market today');
END;
/
exit;
