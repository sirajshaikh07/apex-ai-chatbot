set serveroutput on
DECLARE
  l_blob BLOB;
  l_clob CLOB;
  l_raw  RAW(100);
BEGIN
  l_raw := UTL_RAW.CAST_TO_RAW('Testing Oracle 26ai native document text extraction.');
  DBMS_LOB.CREATETEMPORARY(l_blob, TRUE);
  DBMS_LOB.WRITEAPPEND(l_blob, UTL_RAW.LENGTH(l_raw), l_raw);
  
  l_clob := DBMS_VECTOR_CHAIN.UTL_TO_TEXT(l_blob);
  DBMS_OUTPUT.PUT_LINE('Extracted CLOB: ' || DBMS_LOB.SUBSTR(l_clob, 100, 1));
END;
/
exit;
