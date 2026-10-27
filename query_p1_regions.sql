SET LONG 100000 LONGC 100000 LINESIZE 300 PAGESIZE 500;
COL region_name FORMAT A25;
COL region_source FORMAT A100;

SELECT region_name, region_source
FROM apex_application_page_regions
WHERE application_id = 101 AND page_id = 1;

EXIT;
