SET LINESIZE 2000 PAGESIZE 0 FEEDBACK OFF HEADING OFF ECHO OFF TRIMSPOOL ON SERVEROUTPUT ON;
DECLARE
    l_clob CLOB;
BEGIN
    SELECT region_source INTO l_clob
    FROM apex_application_page_regions
    WHERE application_id = 101 AND page_id = 1 AND region_name = 'Message Stream';
    DBMS_OUTPUT.PUT_LINE(l_clob);
END;
/
EXIT;
