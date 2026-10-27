set feedback on
DELETE FROM doc_chunks;
DELETE FROM source_docs;
COMMIT;
SELECT COUNT(*) as remaining_docs FROM source_docs;
SELECT COUNT(*) as remaining_chunks FROM doc_chunks;
exit;
