set serveroutput on
DECLARE
  l_cnt NUMBER;
BEGIN
  SELECT count(*) INTO l_cnt FROM all_objects WHERE object_name = 'DBMS_VECTOR_CHAIN';
  dbms_output.put_line('DBMS_VECTOR_CHAIN exists: ' || l_cnt);

  SELECT count(*) INTO l_cnt FROM all_objects WHERE object_name = 'CTX_DOC';
  dbms_output.put_line('CTX_DOC exists: ' || l_cnt);
END;
/
exit;
