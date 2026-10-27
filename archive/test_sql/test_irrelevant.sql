set serveroutput on size unlimited feedback off linesize 200 pagesize 0 trimout on
DECLARE
  PROCEDURE test_dist(p_q VARCHAR2) IS
    l_min_dist NUMBER := 999;
    l_best_title VARCHAR2(200);
  BEGIN
    FOR r IN (
      SELECT d.title,
             ROUND(VECTOR_DISTANCE(c.embedding, VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING p_q AS data), COSINE), 4) as dist
      FROM   source_docs d
      JOIN   doc_chunks c ON d.doc_id = c.doc_id
      ORDER BY dist ASC
      FETCH FIRST 1 ROWS ONLY
    ) LOOP
      l_min_dist := r.dist;
      l_best_title := r.title;
    END LOOP;
    dbms_output.put_line('Q: "' || p_q || '" => Min Cosine Dist: ' || l_min_dist);
  END;
BEGIN
  test_dist('What is the weather today in Delhi?');
  test_dist('What is the score of today cricket match?');
  test_dist('Who won the world cup?');
  test_dist('Tell me about stock prices');
  test_dist('How to bake a chocolate cake?');
  test_dist('Give me a recipe for pizza');
  test_dist('What is the capital of France?');
END;
/
exit;
