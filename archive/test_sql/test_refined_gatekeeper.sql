set serveroutput on size unlimited feedback off linesize 200 pagesize 0 trimout on
DECLARE
  FUNCTION extract_topic(p_query VARCHAR2) RETURN VARCHAR2 IS
    l_t VARCHAR2(500);
  BEGIN
    l_t := REGEXP_REPLACE(p_query, '[?.,!]', '');
    l_t := REGEXP_REPLACE(l_t, '^(what is the|what is|tell me about|who is|can you tell me|where is|how is|how to|give me|show me|aaj ka)\s+', '', 1, 1, 'i');
    l_t := REGEXP_REPLACE(l_t, '\s+(kya hai|kaisa hai|batao|hai)$', '', 1, 1, 'i');
    l_t := TRIM(l_t);
    IF l_t IS NULL OR LENGTH(l_t) < 2 THEN
      l_t := TRIM(p_query);
    END IF;
    RETURN l_t;
  END extract_topic;

  PROCEDURE test_query(p_q VARCHAR2) IS
    l_min_dist       NUMBER := 999;
    l_topic          VARCHAR2(500);
    l_gate_action    VARCHAR2(1000);
    l_is_common_ood  BOOLEAN := FALSE;
    l_subject_in_db  NUMBER := 0;
    l_ood_matched    VARCHAR2(100) := NULL;
  BEGIN
    l_topic := extract_topic(p_q);

    -- 1. Min vector distance
    SELECT NVL(ROUND(MIN(VECTOR_DISTANCE(c.embedding, VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING p_q AS data), COSINE)), 4), 999)
    INTO   l_min_dist
    FROM   doc_chunks c;

    -- 2. Check for common out-of-domain topics (weather, mausam, cricket, sports, recipes, stocks, jokes, etc.)
    FOR term IN (
      SELECT COLUMN_VALUE as word
      FROM TABLE(sys.odcivarchar2list(
        'MAUSAM', 'WEATHER', 'TEMPERATURE', 'FORECAST', 'RAIN',
        'CRICKET', 'SCORE', 'IPL', 'FOOTBALL', 'HOCKEY', 'TENNIS',
        'RECIPE', 'CAKE', 'PIZZA', 'BIRYANI',
        'STOCK', 'SENSEX', 'NIFTY', 'BITCOIN', 'CRYPTO',
        'JOKE', 'CHUTKULA', 'SHAYARI', 'HOROSCOPE', 'RASHIFAL'
      ))
    ) LOOP
      IF DBMS_LOB.INSTR(UPPER(p_q), term.word) > 0 THEN
        l_is_common_ood := TRUE;
        l_ood_matched := term.word;
        -- Check if this specific term exists in any uploaded document chunk
        SELECT COUNT(*) INTO l_subject_in_db
        FROM   doc_chunks c
        WHERE  DBMS_LOB.INSTR(UPPER(c.chunk_text), term.word) > 0;
        EXIT;
      END IF;
    END LOOP;

    -- 3. Gatekeeper Decision:
    -- A) Cosine Distance >= 0.82 (Direct requirement: no good match found in vector space)
    -- B) Common Out-of-Domain Topic NOT present in any uploaded document
    IF l_min_dist >= 0.82 OR (l_is_common_ood AND l_subject_in_db = 0) THEN
      l_gate_action := 'REJECT (0.01s Gatekeeper) => "The uploaded documents do not contain information regarding ' || l_topic || '."';
    ELSE
      l_gate_action := 'PASS TO LLM (Min Dist: ' || l_min_dist || ')';
    END IF;

    dbms_output.put_line('Q: "' || p_q || '"');
    dbms_output.put_line('   Min Dist: ' || l_min_dist || ' | OOD Term: ' || NVL(l_ood_matched, 'NONE') || ' | In DB: ' || l_subject_in_db);
    dbms_output.put_line('   Gate Action: ' || l_gate_action);
    dbms_output.put_line('------------------------------------------------------------');
  END;
BEGIN
  dbms_output.put_line('=== TEST RESULTS ===');
  test_query('Who is Rohit Labade?');
  test_query('What is Safa Pathan contact number?');
  test_query('Tell me about Tamanna Shaikh education');
  test_query('Cricket score');
  test_query('Aaj ka mausam kaisa hai?');
  test_query('What is the weather today?');
  test_query('What is the refund policy for cancellation of airline tickets?');
  test_query('Tell me about stock prices');
  test_query('How to bake a chocolate cake?');
  test_query('What is the score of today cricket match?');
END;
/
exit;
