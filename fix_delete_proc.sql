set serveroutput on size unlimited feedback on
-- 1. Clean stale records whose source document no longer exists
DELETE FROM project_members 
WHERE project_code IN (SELECT project_code FROM enterprise_projects WHERE source_doc_id NOT IN (SELECT doc_id FROM source_docs));

DELETE FROM enterprise_projects 
WHERE source_doc_id NOT IN (SELECT doc_id FROM source_docs);

COMMIT;

-- 2. Update delete_document procedure to maintain relational integrity
CREATE OR REPLACE PROCEDURE delete_document (
  p_doc_id IN NUMBER
) AS
BEGIN
  -- Delete associated project members
  DELETE FROM project_members 
  WHERE project_code IN (SELECT project_code FROM enterprise_projects WHERE source_doc_id = p_doc_id);

  -- Delete associated enterprise projects
  DELETE FROM enterprise_projects WHERE source_doc_id = p_doc_id;

  -- Delete associated memories
  DELETE FROM conversation_memories WHERE project_code IN (SELECT project_code FROM enterprise_projects WHERE source_doc_id = p_doc_id);

  -- Delete chunks & document
  DELETE FROM doc_chunks WHERE doc_id = p_doc_id;
  DELETE FROM source_docs WHERE doc_id = p_doc_id;
  COMMIT;
END delete_document;
/
exit;
