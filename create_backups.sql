set serveroutput on size unlimited feedback off linesize 200 pagesize 0 trimout on
BEGIN
  -- Backup source_docs
  BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE source_docs_bak PURGE';
  EXCEPTION WHEN OTHERS THEN NULL;
  END;
  EXECUTE IMMEDIATE 'CREATE TABLE source_docs_bak AS SELECT * FROM source_docs';
  dbms_output.put_line('Backed up SOURCE_DOCS -> SOURCE_DOCS_BAK');

  -- Backup doc_chunks
  BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE doc_chunks_bak PURGE';
  EXCEPTION WHEN OTHERS THEN NULL;
  END;
  EXECUTE IMMEDIATE 'CREATE TABLE doc_chunks_bak AS SELECT * FROM doc_chunks';
  dbms_output.put_line('Backed up DOC_CHUNKS -> DOC_CHUNKS_BAK');

  -- Backup chat_history
  BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE chat_history_bak PURGE';
  EXCEPTION WHEN OTHERS THEN NULL;
  END;
  EXECUTE IMMEDIATE 'CREATE TABLE chat_history_bak AS SELECT * FROM chat_history';
  dbms_output.put_line('Backed up CHAT_HISTORY -> CHAT_HISTORY_BAK');
END;
/
exit;
