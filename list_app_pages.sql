SELECT page_id, page_name, page_mode, page_title
FROM apex_application_pages
WHERE application_id = 101
ORDER BY page_id;
EXIT;
