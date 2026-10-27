set define off serveroutput on size unlimited feedback off linesize 200 pagesize 0 trimout on
DECLARE
  PROCEDURE cmp(p_label VARCHAR2, p_raw VARCHAR2, p_resolved VARCHAR2) IS
    l_dist_raw NUMBER;
    l_dist_res NUMBER;
    l_doc_raw  VARCHAR2(100);
    l_doc_res  VARCHAR2(100);
  BEGIN
    SELECT ROUND(MIN(VECTOR_DISTANCE(c.embedding, VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING p_raw AS data), COSINE)), 4)
    INTO   l_dist_raw
    FROM   doc_chunks c;

    SELECT ROUND(MIN(VECTOR_DISTANCE(c.embedding, VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING p_resolved AS data), COSINE)), 4)
    INTO   l_dist_res
    FROM   doc_chunks c;

    dbms_output.put_line('=== ' || p_label || ' ===');
    dbms_output.put_line('RAW HINGLISH : "' || p_raw || '"');
    dbms_output.put_line('   -> Min Cosine Distance: ' || l_dist_raw);
    dbms_output.put_line('RESOLVED ENG : "' || p_resolved || '"');
    dbms_output.put_line('   -> Min Cosine Distance: ' || l_dist_res);
    dbms_output.put_line('IMPROVEMENT  : ' || ROUND((l_dist_raw - l_dist_res) * 100, 2) || '% sharper distance!');
    dbms_output.put_line('------------------------------------------------------------');
  END;
BEGIN
  cmp('TEST 1: Safa Brothers & Occupation',
      'Safa ke kitne bhai hain aur wo kya karte hain?',
      'Safa brother brothers count occupation job work');

  cmp('TEST 2: Danish Education & Job',
      'Danish sheikh ki education aur naukri kya hai?',
      'Danish sheikh education qualification job occupation work');

  cmp('TEST 3: Rohit Placement & Contact',
      'Rohit Labade kahan placed hua aur uska phone number kya hai?',
      'Rohit Labade placed placement company contact phone mobile number');

  cmp('TEST 4: Safa Father Name',
      'Safa ke pitaji ka naam kya hai?',
      'Safa father name details');

  cmp('TEST 5: Tamanna Shaikh Family Background',
      'Tamanna shaikh ke parivar me kaun kaun hai?',
      'Tamanna shaikh family members background father mother brother sister');
END;
/
exit;
