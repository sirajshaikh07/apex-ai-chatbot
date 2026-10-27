SELECT id, process_name, process_sequence, process_point, process_type
FROM APEX_260200.WWV_FLOW_STEP_PROCESSING
WHERE flow_id = 101 AND flow_step_id = 1;
EXIT;
