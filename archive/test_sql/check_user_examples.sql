set serveroutput on size unlimited feedback off linesize 200 pagesize 0 trimout on
DECLARE
  PROCEDURE chk(p_q VARCHAR2) IS
    l_dist NUMBER;
  BEGIN
    SELECT ROUND(MIN(VECTOR_DISTANCE(c.embedding, VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING p_q AS data), COSINE)), 4)
    INTO   l_dist
    FROM   doc_chunks c;
    dbms_output.put_line('Query: "' || p_q || '" => Min Dist: ' || l_dist);
  END;
BEGIN
  chk('Cricket score');
  chk('cricket score');
  chk('Aaj ka mausam kaisa hai?');
  chk('weather');
  chk('Who is Rohit Labade?');
  chk('What is Safa Pathan age?');
END;
/
exit;
