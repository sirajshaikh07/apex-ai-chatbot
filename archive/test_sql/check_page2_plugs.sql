SET LINESIZE 200;
SET PAGESIZE 100;
COL plug_name FORMAT a30;
COL plug_source_type FORMAT a25;
COL plug_id FORMAT 99999999999999999999;

SELECT id as plug_id, plug_name, plug_source_type, LENGTH(plug_source) as src_len
FROM APEX_260200.WWV_FLOW_PAGE_PLUGS
WHERE flow_id = 101 AND page_id = 2;

EXIT;
