set serveroutput on
DECLARE
  l_raw RAW(32);
BEGIN
  l_raw := DBMS_CRYPTO.HASH(UTL_RAW.CAST_TO_RAW('test content'), 2); -- 2 = HASH_SH256
  dbms_output.put_line('DBMS_CRYPTO SHA-256 works: ' || RAWTOHEX(l_raw));
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line('DBMS_CRYPTO error: ' || SQLERRM);
END;
/
exit;
