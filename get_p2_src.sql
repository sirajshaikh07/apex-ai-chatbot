SET LONG 50000 LONGC 50000;
SELECT region_name, region_source
FROM apex_application_page_regions
WHERE application_id = 101 AND page_id = 2 AND region_name IN ('Active Knowledge Base', 'Admin Scripts');
EXIT;
