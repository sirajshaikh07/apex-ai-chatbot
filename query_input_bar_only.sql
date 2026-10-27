SET DEFINE OFF;
SET LONG 100000 LONGC 100000 LINESIZE 300 PAGESIZE 500;
SELECT region_source
FROM apex_application_page_regions
WHERE application_id = 101 AND page_id = 1 AND region_name = 'Chat Input Bar';
EXIT;
