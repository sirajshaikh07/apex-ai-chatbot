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
    l_min_dist   NUMBER := 999;
    l_key_count  NUMBER := 0;
    l_topic      VARCHAR2(500);
    l_clean_q    VARCHAR2(1000);
    l_is_ood     BOOLEAN := FALSE;
    l_norm_q     VARCHAR2(1000);
    l_gate_action VARCHAR2(1000);
  BEGIN
    l_norm_q := TRIM(LOWER(REGEXP_REPLACE(p_q, '[^a-zA-Z0-9 ]', ' ')));
    l_topic  := extract_topic(p_q);

    -- 1. Min vector distance
    SELECT NVL(ROUND(MIN(VECTOR_DISTANCE(c.embedding, VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING p_q AS data), COSINE)), 4), 999)
    INTO   l_min_dist
    FROM   doc_chunks c;

    -- 2. Keyword presence in doc_chunks
    l_clean_q := REGEXP_REPLACE(UPPER(p_q), '[^A-Z0-9 ]', ' ');
    l_clean_q := REGEXP_REPLACE(l_clean_q, '\b(WHAT|WHEN|WHERE|WHICH|WHO|WHOM|WHOSE|WHY|HOW|THE|IS|ARE|WAS|WERE|AM|AN|A|IN|ON|AT|TO|FOR|OF|WITH|BY|FROM|ABOUT|TELL|ME|GIVE|SHOW|CAN|YOU|PLEASE|PERSON|DETAILS|DATA|INFO|INFORMATION|AAJ|KA|KE|KI|KO|HAI|HO|THA|THI|THE)\b', ' ');
    l_clean_q := TRIM(REGEXP_REPLACE(l_clean_q, '\s+', ' '));

    FOR word IN (
      SELECT REGEXP_SUBSTR(l_clean_q, '[^ ]+', 1, LEVEL) as w
      FROM   dual
      CONNECT BY REGEXP_SUBSTR(l_clean_q, '[^ ]+', 1, LEVEL) IS NOT NULL
      FETCH FIRST 5 ROWS ONLY
    ) LOOP
      IF LENGTH(word.w) >= 3 THEN
        SELECT l_key_count + COUNT(*) INTO l_key_count
        FROM   doc_chunks c
        WHERE  DBMS_LOB.INSTR(UPPER(c.chunk_text), word.w) > 0;
      END IF;
    END LOOP;

    -- 3. Out of domain keyword pattern check (weather, sports, recipes, general chitchat)
    IF REGEXP_LIKE(l_norm_q, '\b(mausam|weather|temperature|forecast|rain|cricket|score|match|ipl|football|recipe|cake|cook|pizza|biryani|movie|cinema|actor|actress|stock|sensex|nifty|horoscope|rashifal|joke|chutkula|shayari|song)\b') THEN
      l_is_ood := TRUE;
    END IF;

    -- Gatekeeper Decision
    -- Rule 1: Cosine dist >= 0.82 (strict threshold)
    -- Rule 2: Cosine dist >= 0.70 and zero keyword matches in documents
    -- Rule 3: Explicit OOD query and zero keyword matches in documents
    IF l_min_dist >= 0.82 OR (l_min_dist >= 0.70 AND l_key_count = 0) OR (l_is_ood AND l_key_count = 0) THEN
      l_gate_action := 'REJECT (0.01s Gatekeeper) => "The uploaded documents do not contain information regarding ' || l_topic || '."';
    ELSE
      l_gate_action := 'PASS TO LLM (Relevant match found)';
    END IF;

    dbms_output.put_line('Q: "' || p_q || '"');
    dbms_output.put_line('   Min Dist: ' || l_min_dist || ' | Key Matches: ' || l_key_count || ' | OOD Flag: ' || CASE WHEN l_is_ood THEN 'YES' ELSE 'NO' END);
    dbms_output.put_line('   Gate Action: ' || l_gate_action);
    dbms_output.put_line('------------------------------------------------------------');
  END;
BEGIN
  dbms_output.put_line('=== EVALUATING GATEKEEPER LOGIC ===');
  test_query('Who is Rohit Labade?');
  test_query('What is Safa Pathan contact number?');
  test_query('Tell me about Tamanna Shaikh education');
  test_query('Cricket score');
  test_query('Aaj ka mausam kaisa hai?');
  test_query('What is the weather today?');
  test_query('What is the refund policy for cancellation of airline tickets?');
  test_query('Tell me about stock prices');
  test_query('How to bake a chocolate cake?');
END;
/
exit;
