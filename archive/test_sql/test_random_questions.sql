SET SERVEROUTPUT ON SIZE UNLIMITED;
SET LINESIZE 250;
SET FEEDBACK OFF;

ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

DECLARE
  PROCEDURE run_test(p_title VARCHAR2, p_q VARCHAR2) IS
    l_ans CLOB;
    l_src VARCHAR2(1000);
    l_t0  NUMBER := DBMS_UTILITY.GET_TIME;
    l_ms  NUMBER;
  BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '======================================================================');
    DBMS_OUTPUT.PUT_LINE('Q: ' || p_q);
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------------------------------');
    enterprise_rag_pkg.ask_with_context(
      p_question   => p_q,
      p_session_id => 777111,
      p_user_name  => 'ADMIN',
      p_answer     => l_ans,
      p_sources    => l_src
    );
    l_ms := ROUND((DBMS_UTILITY.GET_TIME - l_t0) * 10);
    DBMS_OUTPUT.PUT_LINE('SOURCES: ' || l_src || ' | TIME: ' || l_ms || ' ms');
    DBMS_OUTPUT.PUT_LINE('ANSWER:');
    DBMS_OUTPUT.PUT_LINE(l_ans);
  END;
BEGIN
  -- Test 1: Team Hierarchy (Non-task, reporting structure)
  run_test('TEST 1: Hierarchy', 'Who reports to Nasir?');

  -- Test 2: Blocked / Overdue items (Project status & edge conditions)
  run_test('TEST 2: Blocked/Overdue', 'Which tasks are currently blocked or overdue in C4T project?');

  -- Test 3: Aditya's tasks (Another person cross-project enumeration)
  run_test('TEST 3: Aditya Tasks', 'Give me title of all tasks assigned to Aditya');

  -- Test 4: Project ownership (Cross-project metadata)
  run_test('TEST 4: Project Owners', 'Who are the owners of the projects?');

  -- Test 5: Yogita's tasks
  run_test('TEST 5: Yogita Tasks', 'What tasks does Yogita have in C4T?');
END;
/
EXIT;
