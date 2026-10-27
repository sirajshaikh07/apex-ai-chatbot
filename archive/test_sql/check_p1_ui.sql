SELECT region_id, region_name, component_template_options, source_type
FROM apex_application_page_regions
WHERE application_id = 101 AND page_id = 1;

SELECT item_name, item_type, region_name
FROM apex_application_page_items i
JOIN apex_application_page_regions r ON i.region_id = r.region_id
WHERE i.application_id = 101 AND i.page_id = 1;

EXIT;
