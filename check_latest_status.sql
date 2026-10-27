SET LINESIZE 300;
SET PAGESIZE 100;
SET SERVEROUTPUT ON SIZE UNLIMITED;
ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

PROMPT ============================================================
PROMPT 1. LATEST DOCUMENTS IN SOURCE_DOCS
PROMPT ============================================================
SELECT doc_id, title, status, file_size, mime_type, 
       TO_CHAR(created_at, 'YYYY-MM-DD HH24:MI:SS') as created,
       TO_CHAR(ingested_at, 'YYYY-MM-DD HH24:MI:SS') as ingested
FROM source_docs
ORDER BY doc_id DESC
FETCH FIRST 10 ROWS ONLY;

PROMPT ============================================================
PROMPT 2. CHUNKS COUNT PER DOC_ID
PROMPT ============================================================
SELECT doc_id, COUNT(*) as chunks_cnt, MIN(chunk_no), MAX(chunk_no)
FROM doc_chunks
GROUP BY doc_id
ORDER BY doc_id DESC;

PROMPT ============================================================
PROMPT 3. LATEST CHAT HISTORY
PROMPT ============================================================
SELECT msg_id, TO_CHAR(created_at, 'HH24:MI:SS') as tm, 
       SUBSTR(user_prompt, 1, 80) as prompt,
       SUBSTR(sources, 1, 50) as src,
       retrieved_chunks, retrieved_chunk_ids,
       response_time_ms,
       SUBSTR(ai_response, 1, 150) as ans
FROM chat_history
ORDER BY msg_id DESC
FETCH FIRST 5 ROWS ONLY;

EXIT;
