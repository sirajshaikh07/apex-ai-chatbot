SELECT object_name, object_type, status 
FROM user_objects 
WHERE object_name IN ('ENTERPRISE_RAG_PKG', 'POLICY_RAG_PKG');
exit;
