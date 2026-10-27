set define off serveroutput on size unlimited feedback off linesize 200 pagesize 0 trimout on
DECLARE
  FUNCTION resolve_hinglish (
    p_query IN VARCHAR2
  ) RETURN VARCHAR2 IS
    l_res VARCHAR2(4000);

    PROCEDURE map_word(p_words VARCHAR2, p_rep VARCHAR2) IS
    BEGIN
      l_res := REGEXP_REPLACE(l_res, '(^| )(' || p_words || ')( |$)', ' ' || p_rep || ' ', 1, 0, 'i');
      l_res := REGEXP_REPLACE(l_res, '(^| )(' || p_words || ')( |$)', ' ' || p_rep || ' ', 1, 0, 'i');
    END map_word;
  BEGIN
    l_res := ' ' || LOWER(p_query) || ' ';
    
    -- Strip punctuation
    l_res := REGEXP_REPLACE(l_res, '[?,.!;:()"\''\-\/]', ' ');

    -- Family relations
    map_word('bhai|bhaiyo|bhaiya|brother|brothers', 'brother brothers');
    map_word('behen|bahen|behno|didi|sister|sisters', 'sister sisters');
    map_word('pitaji|pita|papa|walid|abbu|baap|father', 'father name');
    map_word('mataji|mata|maa|ammi|walida|mummy|mother', 'mother name');
    map_word('parivar|khandan|gharwale|family', 'family background members');
    map_word('pati|shohar|husband', 'husband');
    map_word('patni|biwi|wife', 'wife');
    map_word('bachhe|bacche|aulad|children', 'children');

    -- Education & Studies
    map_word('padhai|shiksha|taleem|qualification|qualifications', 'education qualification degree');
    map_word('padha|padhi|padhe|study|studied|degree', 'education graduate degree');

    -- Job / Work / Placement / Salary
    map_word('naukri|kam|kaam|rozgar|mulazmat|job|jobs', 'job occupation work career');
    map_word('karta|karte|karti|karega|karegi', 'occupation work job');
    map_word('placed|placement', 'placed placement company organization');
    map_word('tankhwah|vetan|salary|kamata|kamati|aamdani|package|ctc', 'salary package income ctc');
    map_word('vyapar|dhandha|business', 'business self employed');

    -- Personal Attributes (Age, DOB, Religion, Address, Phone)
    map_word('umar|umra|aayu|age', 'age date of birth');
    map_word('janam|janm|paida|paidaish|dob', 'date of birth dob');
    map_word('dharam|dharm|mazhab|religion', 'religion');
    map_word('jaat|jati|zaat|caste', 'caste subcaste');
    map_word('pata|thikana|rehte|rehta|rehti|ghar|sheher|address|city', 'address city state location reside');
    map_word('phone|mobile|sampark|rabta|no|number|contact', 'mobile phone contact number');
    map_word('shadi|vivah|nikah|marital', 'marital status married unmarried');
    map_word('naam|nam|name', 'name');
    map_word('shauq|pasand|hobbies|hobby', 'hobbies interests');

    -- Question intent words
    map_word('kitne|kitna|kitni', 'count total number');
    map_word('kahan|kidhar', 'where location place');
    map_word('kab', 'when date year');
    map_word('kaun|kiska|kiski|kiske', 'who which');
    map_word('kya', 'what details');
    map_word('batao|bataiye|bataye|bata|chahiye|dikhaye', 'show details');

    -- Remove common Hinglish glue words
    map_word('ke|ki|ka|ko|se|me|mein|par|aur|wo|woh|ye|yeh|unka|unki|unke|iska|iski|iske|hai|hain|tha|thi|the|hoga|hogi|hote|hota|hoti', '');

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
