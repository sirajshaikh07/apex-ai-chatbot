set serveroutput on linesize 160
SELECT line, position, text
FROM user_errors
WHERE name = 'POLICY_RAG_PKG'
ORDER BY sequence;
exit;
