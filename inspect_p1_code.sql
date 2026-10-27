SET LONG 100000 LONGC 100000 LINESIZE 300 PAGESIZE 500;
COL plug_name FORMAT A30;
COL plug_source FORMAT A100;

PROMPT === REGION SOURCES ===
SELECT plug_name, plug_source
FROM apex_application_page_plugs
WHERE application_id = 101 AND page_id = 1;

PROMPT === PAGE ATTRIBUTES (JS / CSS) ===
SELECT javascript_code, javascript_code_onload, inline_css
FROM apex_application_pages
WHERE application_id = 101 AND page_id = 1;

PROMPT === PROCESS SOURCE: Query Enterprise RAG AI ===
SELECT process_name, process_source
FROM apex_application_page_proc
WHERE application_id = 101 AND page_id = 1;

EXIT;
