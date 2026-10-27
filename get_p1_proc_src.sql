SET LONG 50000 LONGC 50000;
SELECT process_source
FROM apex_application_page_proc
WHERE application_id = 101 AND page_id = 1 AND process_name = 'Query Enterprise RAG AI';
EXIT;
