set heading off feedback off linesize 3000 pagesize 0 trimspool on echo off
SELECT '<<<CHUNK ' || chunk_no || '>>>' || CHR(10) || chunk_text || CHR(10) || '<<<END CHUNK>>>'
FROM doc_chunks
WHERE doc_id = 85
ORDER BY chunk_no;
exit;
