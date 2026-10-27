set define off serveroutput on size unlimited feedback off linesize 200 pagesize 0 trimout on
DECLARE
  FUNCTION map_hinglish_token(p_w VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN CASE LOWER(p_w)
      -- Family
      WHEN 'bhai' THEN 'brother'
      WHEN 'bhaiyo' THEN 'brothers'
      WHEN 'bhaiya' THEN 'brother'
      WHEN 'behen' THEN 'sister'
      WHEN 'bahen' THEN 'sister'
      WHEN 'behno' THEN 'sisters'
      WHEN 'didi' THEN 'sister'
      WHEN 'pitaji' THEN 'father'
      WHEN 'pita' THEN 'father'
      WHEN 'papa' THEN 'father'
      WHEN 'baap' THEN 'father'
      WHEN 'walid' THEN 'father'
      WHEN 'abbu' THEN 'father'
      WHEN 'mataji' THEN 'mother'
      WHEN 'mata' THEN 'mother'
      WHEN 'maa' THEN 'mother'
      WHEN 'ammi' THEN 'mother'
      WHEN 'walida' THEN 'mother'
      WHEN 'mummy' THEN 'mother'
      WHEN 'parivar' THEN 'family'
      WHEN 'khandan' THEN 'family'
      WHEN 'gharwale' THEN 'family'
      WHEN 'shohar' THEN 'husband'
      WHEN 'pati' THEN 'husband'
      WHEN 'biwi' THEN 'wife'
      WHEN 'patni' THEN 'wife'
      WHEN 'bachhe' THEN 'children'
      WHEN 'bacche' THEN 'children'
      WHEN 'aulad' THEN 'children'
      
      -- Education
      WHEN 'padhai' THEN 'education'
      WHEN 'shiksha' THEN 'education'
      WHEN 'taleem' THEN 'education'
      WHEN 'qualification' THEN 'qualification'
      WHEN 'padha' THEN 'studied'
      WHEN 'padhi' THEN 'studied'
      WHEN 'padhe' THEN 'studied'
      WHEN 'degree' THEN 'degree'

      -- Job / Career
      WHEN 'naukri' THEN 'job'
      WHEN 'kam' THEN 'work'
      WHEN 'kaam' THEN 'work'
      WHEN 'rozgar' THEN 'job'
      WHEN 'karta' THEN 'work'
      WHEN 'karte' THEN 'work'
      WHEN 'karti' THEN 'work'
      WHEN 'placed' THEN 'placed'
      WHEN 'placement' THEN 'placement'
      WHEN 'tankhwah' THEN 'salary'
      WHEN 'vetan' THEN 'salary'
      WHEN 'salary' THEN 'salary'
      WHEN 'kamata' THEN 'earning'
      WHEN 'kamati' THEN 'earning'
      WHEN 'package' THEN 'package'
      WHEN 'ctc' THEN 'CTC'
      WHEN 'vyapar' THEN 'business'
      WHEN 'dhandha' THEN 'business'

      -- Attributes
      WHEN 'umar' THEN 'age'
      WHEN 'umra' THEN 'age'
      WHEN 'aayu' THEN 'age'
      WHEN 'age' THEN 'age'
      WHEN 'janam' THEN 'birth'
      WHEN 'janm' THEN 'birth'
      WHEN 'paida' THEN 'born'
      WHEN 'dob' THEN 'DOB'
      WHEN 'dharam' THEN 'religion'
      WHEN 'dharm' THEN 'religion'
      WHEN 'mazhab' THEN 'religion'
      WHEN 'jaat' THEN 'caste'
      WHEN 'jati' THEN 'caste'
      WHEN 'zaat' THEN 'caste'
      WHEN 'pata' THEN 'address'
      WHEN 'thikana' THEN 'address'
      WHEN 'rehte' THEN 'reside'
      WHEN 'rehta' THEN 'reside'
      WHEN 'rehti' THEN 'reside'
      WHEN 'ghar' THEN 'address'
      WHEN 'sheher' THEN 'city'
      WHEN 'phone' THEN 'phone'
      WHEN 'mobile' THEN 'mobile'
      WHEN 'sampark' THEN 'contact'
      WHEN 'rabta' THEN 'contact'
      WHEN 'number' THEN 'number'
      WHEN 'shadi' THEN 'marriage'
      WHEN 'vivah' THEN 'marriage'
      WHEN 'nikah' THEN 'marriage'
      WHEN 'naam' THEN 'name'
      WHEN 'nam' THEN 'name'
      WHEN 'shauq' THEN 'hobbies'
      WHEN 'pasand' THEN 'interests'

      -- Question words
      WHEN 'kitne' THEN 'count'
      WHEN 'kitna' THEN 'count'
      WHEN 'kitni' THEN 'count'
      WHEN 'kahan' THEN 'location'
      WHEN 'kidhar' THEN 'location'
      WHEN 'kab' THEN 'when'
      WHEN 'kaun' THEN 'who'
      WHEN 'kiska' THEN 'whose'
      WHEN 'kiski' THEN 'whose'
      WHEN 'kiske' THEN 'whose'
      WHEN 'kya' THEN 'what'
      WHEN 'batao' THEN 'details'
      WHEN 'bataiye' THEN 'details'
      WHEN 'bataye' THEN 'details'

      -- Glue / stop words (drop them)
      WHEN 'ke' THEN NULL
      WHEN 'ki' THEN NULL
      WHEN 'ka' THEN NULL
      WHEN 'ko' THEN NULL
      WHEN 'se' THEN NULL
      WHEN 'me' THEN NULL
      WHEN 'mein' THEN NULL
      WHEN 'par' THEN NULL
      WHEN 'aur' THEN NULL
      WHEN 'wo' THEN NULL
      WHEN 'woh' THEN NULL
      WHEN 'ye' THEN NULL
      WHEN 'yeh' THEN NULL
      WHEN 'unka' THEN NULL
      WHEN 'unki' THEN NULL
      WHEN 'unke' THEN NULL
      WHEN 'iska' THEN NULL
      WHEN 'iski' THEN NULL
      WHEN 'iske' THEN NULL
      WHEN 'hai' THEN NULL
      WHEN 'hain' THEN NULL
      WHEN 'tha' THEN NULL
      WHEN 'thi' THEN NULL
      WHEN 'the' THEN NULL
      WHEN 'hoga' THEN NULL
      WHEN 'hogi' THEN NULL
      WHEN 'hote' THEN NULL
      WHEN 'hota' THEN NULL
      WHEN 'hoti' THEN NULL
      WHEN 'hua' THEN NULL
      WHEN 'hui' THEN NULL
      WHEN 'hue' THEN NULL
      WHEN 'uska' THEN NULL
      WHEN 'uski' THEN NULL
      WHEN 'uske' THEN NULL
      
      -- Default: preserve original word as-is
      ELSE p_w
    END;
  END map_hinglish_token;

  FUNCTION resolve_hinglish (
    p_query IN VARCHAR2
  ) RETURN VARCHAR2 IS
    l_clean VARCHAR2(4000);
    l_word  VARCHAR2(200);
    l_mapped VARCHAR2(200);
    l_res   VARCHAR2(4000) := '';
    l_cnt   INTEGER;
  BEGIN
    -- Strip punctuation
    l_clean := REGEXP_REPLACE(p_query, '[?,.!;:()"\''\-\/]', ' ');
    l_clean := TRIM(REGEXP_REPLACE(l_clean, '\s+', ' '));

    l_cnt := REGEXP_COUNT(l_clean, '[^ ]+');
    FOR i IN 1 .. l_cnt LOOP
      l_word := REGEXP_SUBSTR(l_clean, '[^ ]+', 1, i);
      l_mapped := map_hinglish_token(l_word);
      IF l_mapped IS NOT NULL THEN
        IF l_res IS NOT NULL THEN
          l_res := l_res || ' ';
        END IF;
        l_res := l_res || l_mapped;
      END IF;
    END LOOP;

    RETURN l_res;
  END resolve_hinglish;

  PROCEDURE test(p_q VARCHAR2) IS
  BEGIN
    dbms_output.put_line('INPUT    : ' || p_q);
    dbms_output.put_line('RESOLVED : ' || resolve_hinglish(p_q));
    dbms_output.put_line('----------------------------------------------------');
  END;
BEGIN
  test('Safa ke kitne bhai hain aur wo kya karte hain?');
  test('Danish sheikh ki education aur naukri kya hai?');
  test('Rohit Labade kahan placed hua aur uska mobile number kya hai?');
  test('Safa ke pitaji ka naam kya hai aur wo kahan rehte hain?');
  test('Tamanna shaikh ki umar aur shadi status batao?');
END;
/
exit;
