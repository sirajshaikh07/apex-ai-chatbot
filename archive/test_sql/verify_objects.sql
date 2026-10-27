set serveroutput on linesize 120
SELECT object_type, object_name, status
FROM user_objects
WHERE object_name IN ('SOURCE_DOCS', 'DOC_CHUNKS', 'USER_REGISTRATIONS', 'INGEST_FILE_DOCUMENT', 'INGEST_DOCUMENT_BLOB', 'APPROVE_USER_REGISTRATION', 'REJECT_USER_REGISTRATION', 'DELETE_DOCUMENT', 'POLICY_RAG_PKG')
ORDER BY object_type, object_name;
exit;
