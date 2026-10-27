set pagesize 100 linesize 200 feedback off
SELECT count(*) as total_docs FROM source_docs;
SELECT count(*) as total_chunks FROM doc_chunks;
SELECT count(*) as total_chat FROM chat_history;
SELECT count(*) as total_registrations FROM user_registrations;
exit;
