set pagesize 100 linesize 200 feedback off
SELECT display_as, count(*) 
FROM apex_application_page_items 
WHERE display_as LIKE '%FILE%'
GROUP BY display_as;
exit;
