set serveroutput on linesize 200 pagesize 100
SELECT index_name, index_type, status
FROM user_indexes
WHERE table_name = 'DOC_CHUNKS';
exit;
