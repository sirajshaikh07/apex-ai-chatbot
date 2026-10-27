SELECT button_name, label, action, page_id
FROM apex_application_page_buttons
WHERE application_id = 101;

SELECT dynamic_action_name, page_id
FROM apex_application_page_da
WHERE application_id = 101;
EXIT;
