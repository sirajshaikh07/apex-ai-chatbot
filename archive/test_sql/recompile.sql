ALTER PACKAGE policy_rag_pkg COMPILE BODY;
SHOW ERRORS PACKAGE BODY policy_rag_pkg;
SELECT object_type, object_name, status
FROM user_objects
WHERE object_name = 'POLICY_RAG_PKG';
exit;
