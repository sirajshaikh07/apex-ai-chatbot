set serveroutput on
DECLARE
  l_username VARCHAR2(50) := 'YOGI';
  l_html VARCHAR2(500);
BEGIN
  -- Old way (broken):
  l_html := '<button onclick="approveUser(' || 2 || ', ''' || apex_escape.js_literal(l_username) || ''');">Approve</button>';
  dbms_output.put_line('Old broken HTML: ' || l_html);

  -- Correct way (clean):
  l_html := '<button onclick="approveUser(' || 2 || ', ' || apex_escape.js_literal(l_username) || ');">Approve</button>';
  dbms_output.put_line('Correct HTML:    ' || l_html);
END;
/
exit;
