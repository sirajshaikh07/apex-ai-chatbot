SET DEFINE OFF;
SELECT page_id, region_id, region_name, source_type
FROM apex_application_page_regions
WHERE application_id = 101;

SELECT message, message_timestamp, call_stack
FROM apex_debug_messages
WHERE application_id = 101
ORDER BY message_timestamp DESC
FETCH FIRST 10 ROWS ONLY;

EXIT;
