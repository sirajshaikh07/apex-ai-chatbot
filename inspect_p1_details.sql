SET LINESIZE 250 PAGESIZE 200;
COL component_type FORMAT A20;
COL component_name FORMAT A30;
COL detail FORMAT A80;

PROMPT === REGIONS ON PAGE 1 ===
SELECT region_id, region_name, source_type, template
FROM apex_application_page_regions
WHERE application_id = 101 AND page_id = 1;

PROMPT === ITEMS ON PAGE 1 ===
SELECT item_id, item_name, display_as, item_source_type
FROM apex_application_page_items
WHERE application_id = 101 AND page_id = 1;

PROMPT === BUTTONS ON PAGE 1 ===
SELECT button_id, button_name, button_action, redirect_url
FROM apex_application_page_buttons
WHERE application_id = 101 AND page_id = 1;

PROMPT === PROCESSES ON PAGE 1 ===
SELECT process_id, process_name, process_type, execution_sequence
FROM apex_application_page_proc
WHERE application_id = 101 AND page_id = 1;

PROMPT === DYNAMIC ACTIONS ON PAGE 1 ===
SELECT dynamic_action_id, dynamic_action_name, when_event_name, when_element
FROM apex_application_page_da
WHERE application_id = 101 AND page_id = 1;

PROMPT === DA ACTIONS ON PAGE 1 ===
SELECT action_id, dynamic_action_id, action_sequence, action_name, action_code
FROM apex_application_page_da_acts
WHERE application_id = 101 AND page_id = 1;

EXIT;
