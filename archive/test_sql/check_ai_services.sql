SELECT table_name FROM all_tables WHERE table_name LIKE '%AI_SERVICE%' OR table_name LIKE '%GEN_AI%';
SELECT view_name FROM all_views WHERE view_name LIKE '%AI_SERVICE%';
exit;
