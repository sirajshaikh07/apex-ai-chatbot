SET LINESIZE 250;
SET PAGESIZE 500;
SET SERVEROUTPUT ON SIZE UNLIMITED;

ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

DECLARE
  l_clob CLOB;
BEGIN
  DBMS_OUTPUT.PUT_LINE('========================================================');
  DBMS_OUTPUT.PUT_LINE('1. ACTIVE DOCUMENTS IN SOURCE_DOCS');
  DBMS_OUTPUT.PUT_LINE('========================================================');
  FOR d IN (SELECT doc_id, title, status, file_hash, LENGTH(content) as content_len FROM source_docs) LOOP
    DBMS_OUTPUT.PUT_LINE('DOC_ID: ' || d.doc_id || ' | TITLE: ' || d.title || ' | STATUS: ' || d.status || ' | CONTENT_LEN: ' || d.content_len);
  END LOOP;

  DBMS_OUTPUT.PUT_LINE(CHR(10) || '========================================================');
  DBMS_OUTPUT.PUT_LINE('2. ALL CHUNKS MENTIONING SIRAJ ACROSS ALL DOCUMENTS');
  DBMS_OUTPUT.PUT_LINE('========================================================');
  FOR c IN (
    SELECT c.doc_id, d.title, c.chunk_no, c.chunk_text
    FROM doc_chunks c
    JOIN source_docs d ON c.doc_id = d.doc_id
    WHERE UPPER(c.chunk_text) LIKE '%SIRAJ%'
    ORDER BY c.doc_id, c.chunk_no
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('--- DOC ' || c.doc_id || ' (' || c.title || ') CHUNK #' || c.chunk_no || ' ---');
    DBMS_OUTPUT.PUT_LINE(c.chunk_text);
    DBMS_OUTPUT.PUT_LINE(' ');
  END LOOP;

  DBMS_OUTPUT.PUT_LINE(CHR(10) || '========================================================');
  DBMS_OUTPUT.PUT_LINE('3. FULL CONTENT OF ALL_APP_DATA.TXT');
  DBMS_OUTPUT.PUT_LINE('========================================================');
  FOR d IN (SELECT title, content FROM source_docs WHERE UPPER(title) LIKE '%APP_DATA%' OR UPPER(title) LIKE '%ALL%') LOOP
    DECLARE
      l_offset NUMBER := 1;
      l_chunk_size NUMBER := 2000;
      l_len NUMBER := DBMS_LOB.GETLENGTH(d.content);
    BEGIN
      DBMS_OUTPUT.PUT_LINE('=== DOCUMENT: ' || d.title || ' (Length: ' || l_len || ' chars) ===');
      WHILE l_offset <= l_len LOOP
        DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(d.content, l_chunk_size, l_offset));
        l_offset := l_offset + l_chunk_size;
      END LOOP;
    END;
  END LOOP;
END;
/
EXIT;
