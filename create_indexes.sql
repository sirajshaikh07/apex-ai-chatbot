set serveroutput on
BEGIN
  BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX idx_user_reg_status ON user_registrations (status, request_id)';
    dbms_output.put_line('Index on user_registrations(status, request_id) created.');
  EXCEPTION WHEN OTHERS THEN dbms_output.put_line(SQLERRM);
  END;

  BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX idx_source_docs_title ON source_docs (title)';
    dbms_output.put_line('Index on source_docs(title) created.');
  EXCEPTION WHEN OTHERS THEN dbms_output.put_line(SQLERRM);
  END;

  BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX idx_chat_hist_sess ON chat_history (session_id, created_at)';
    dbms_output.put_line('Index on chat_history(session_id, created_at) created.');
  EXCEPTION WHEN OTHERS THEN dbms_output.put_line(SQLERRM);
  END;
END;
/
exit;
