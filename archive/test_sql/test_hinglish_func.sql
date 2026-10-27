set define off serveroutput on size unlimited feedback off linesize 200 pagesize 0 trimout on
DECLARE
  FUNCTION resolve_hinglish (
    p_query IN VARCHAR2
  ) RETURN VARCHAR2 IS
    l_res VARCHAR2(4000);
  BEGIN
    l_res := ' ' || LOWER(p_query) || ' ';
    
    -- Strip punctuation
    l_res := REGEXP_REPLACE(l_res, '[?,.!;:()"\''-]', ' ');

    -- Family relations
    l_res := REGEXP_REPLACE(l_res, '\b(bhai|bhaiyo|bhaiya)\b', ' brother brothers ');
    l_res := REGEXP_REPLACE(l_res, '\b(behen|bahen|behno|didi)\b', ' sister sisters ');
    l_res := REGEXP_REPLACE(l_res, '\b(pitaji|pita|papa|walid|abbu|abbu jaan|baap)\b', ' father father name ');
    l_res := REGEXP_REPLACE(l_res, '\b(mataji|mata|maa|ammi|walida|mummy)\b', ' mother mother name ');
    l_res := REGEXP_REPLACE(l_res, '\b(parivar|khandan|gharwale)\b', ' family family members background ');
    l_res := REGEXP_REPLACE(l_res, '\b(pati|shohar)\b', ' husband ');
    l_res := REGEXP_REPLACE(l_res, '\b(patni|biwi)\b', ' wife ');
    l_res := REGEXP_REPLACE(l_res, '\b(bachhe|bacche|aulad)\b', ' children ');

    -- Education & Studies
    l_res := REGEXP_REPLACE(l_res, '\b(padhai|shiksha|taleem|qualification)\b', ' education qualification degree ');
    l_res := REGEXP_REPLACE(l_res, '\b(padha|padhi|padhe|study|studied)\b', ' education graduate degree ');

    -- Job / Work / Placement / Salary
    l_res := REGEXP_REPLACE(l_res, '\b(naukri|kam|kaam|rozgar|mulazmat)\b', ' job occupation work career ');
    l_res := REGEXP_REPLACE(l_res, '\b(karta|karte|karti|karega|karegi)\b', ' occupation work job ');
    l_res := REGEXP_REPLACE(l_res, '\b(placed|placement)\b', ' placed placement company organization ');
    l_res := REGEXP_REPLACE(l_res, '\b(tankhwah|vetan|salary|kamata|kamati|aamdani)\b', ' salary package income ctc ');
    l_res := REGEXP_REPLACE(l_res, '\b(vyapar|dhandha)\b', ' business self employed ');

    -- Personal Attributes (Age, DOB, Religion, Address, Phone)
    l_res := REGEXP_REPLACE(l_res, '\b(umar|umra|aayu)\b', ' age date of birth ');
    l_res := REGEXP_REPLACE(l_res, '\b(janam|janm|paida|paidaish)\b', ' date of birth dob ');
    l_res := REGEXP_REPLACE(l_res, '\b(dharam|dharm|mazhab)\b', ' religion ');
    l_res := REGEXP_REPLACE(l_res, '\b(jaat|jati|zaat)\b', ' caste subcaste ');
    l_res := REGEXP_REPLACE(l_res, '\b(pata|thikana|rehte|rehta|rehti|ghar|sheher)\b', ' address city state location reside ');
    l_res := REGEXP_REPLACE(l_res, '\b(phone|mobile|sampark|rabta|no|number)\b', ' mobile phone contact number ');
    l_res := REGEXP_REPLACE(l_res, '\b(shadi|vivah|nikah)\b', ' marital status married unmarried ');
    l_res := REGEXP_REPLACE(l_res, '\b(naam|nam)\b', ' name ');
    l_res := REGEXP_REPLACE(l_res, '\b(shauq|pasand)\b', ' hobbies interests ');

    -- Question intent words
    l_res := REGEXP_REPLACE(l_res, '\b(kitne|kitna|kitni)\b', ' count total number ');
    l_res := REGEXP_REPLACE(l_res, '\b(kahan|kidhar)\b', ' where location place ');
    l_res := REGEXP_REPLACE(l_res, '\b(kab)\b', ' when date year ');
    l_res := REGEXP_REPLACE(l_res, '\b(kaun|kiska|kiski|kiske)\b', ' who which ');
    l_res := REGEXP_REPLACE(l_res, '\b(kya)\b', ' what details ');
    l_res := REGEXP_REPLACE(l_res, '\b(batao|bataiye|bataye|bata|chahiye|dikhaye)\b', ' show details ');

    -- Remove common Hinglish glue words
    l_res := REGEXP_REPLACE(l_res, '\b(ke|ki|ka|ko|se|me|mein|par|aur|wo|woh|ye|yeh|unka|unki|unke|iska|iski|iske|hai|hain|tha|thi|the|hoga|hogi|hote|hota|hoti)\b', ' ');

    -- Normalize multiple spaces
    l_res := TRIM(REGEXP_REPLACE(l_res, '\s+', ' '));
    
    RETURN l_res;
  END resolve_hinglish;

  PROCEDURE test(p_q VARCHAR2) IS
  BEGIN
    dbms_output.put_line('INPUT : ' || p_q);
    dbms_output.put_line('RESOLVED: ' || resolve_hinglish(p_q));
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
