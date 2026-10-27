SET LONG 50000 LONGC 50000;
SELECT region_source
FROM apex_application_page_regions
WHERE application_id = 101 AND page_id = 1 AND region_name = 'Message Stream';
EXIT;
