set define off serveroutput on linesize 200 feedback on

PROMPT === Checking POLICY_RAG_PKG status ===
SELECT object_name, object_type, status 
FROM user_objects 
WHERE object_name = 'POLICY_RAG_PKG';

SELECT line, position, text 
FROM user_errors 
WHERE name = 'POLICY_RAG_PKG';

PROMPT === Checking ORDS Module and Handlers ===
SELECT name, uri_prefix, status 
FROM user_ords_modules;

SELECT module_name, pattern, method, source_type 
FROM user_ords_handlers;

exit;
