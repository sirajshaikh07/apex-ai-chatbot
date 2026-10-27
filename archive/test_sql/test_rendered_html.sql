set serveroutput on linesize 300 pagesize 100 long 50000
DECLARE
  l_html CLOB := '';
BEGIN
  FOR r IN (
      SELECT request_id, username, full_name, email, 
             TO_CHAR(requested_at, 'YYYY-MM-DD HH24:MI') as req_time,
             status
      FROM user_registrations
      ORDER BY DECODE(status, 'PENDING', 1, 2), request_id DESC
  ) LOOP
      l_html := l_html || 
          '<button type="button" class="btn-action-sm btn-approve" data-id="' || r.request_id || '" data-user="' || apex_escape.html_attribute(r.username) || '" onclick="approveUser(this);">✔ Approve</button>' || chr(10) ||
          '<button type="button" class="btn-action-sm btn-reject" data-id="' || r.request_id || '" data-user="' || apex_escape.html_attribute(r.username) || '" onclick="rejectUser(this);">✖ Reject</button>' || chr(10);
  END LOOP;
  dbms_output.put_line(l_html);
END;
/
exit;
