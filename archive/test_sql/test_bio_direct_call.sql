set serveroutput on size unlimited feedback off linesize 200
DECLARE
  l_clob CLOB;
  l_prompt CLOB;
  l_ans CLOB;
BEGIN
  SELECT chunk_text INTO l_clob FROM doc_chunks WHERE doc_id = 103;

  l_prompt := 'You are an intelligent, accurate, and professional AI Assistant.' || CHR(10) ||
              'Answer the user question based strictly on the document context below.' || CHR(10) || CHR(10) ||
              'RELEVANT DOCUMENTATION PASSAGES:' || CHR(10) ||
              '--- Document: bio_data.txt ---' || CHR(10) ||
              l_clob || CHR(10) || CHR(10) ||
              'Current User Question: Who is Safa Himmatkha Pathan?' || CHR(10) ||
              'Assistant Answer:';

  IF apex_application.g_flow_id IS NULL THEN
    apex_session.create_session (
      p_app_id   => 101,
      p_page_id  => 1,
      p_username => 'AIDEMO_ADMIN'
    );
  END IF;

  l_ans := apex_ai.generate (
    p_service_static_id => 'local_ollama',
    p_prompt            => l_prompt
  );

  dbms_output.put_line('AI RESPONSE:');
  dbms_output.put_line(l_ans);
END;
/
exit;
