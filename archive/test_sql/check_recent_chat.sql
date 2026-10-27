set heading on feedback off linesize 200 pagesize 50
SELECT msg_id, session_id, user_name, user_prompt, substr(ai_response, 1, 100) as ai_resp, TO_CHAR(created_at, 'HH24:MI:SS') as msg_time
FROM chat_history
ORDER BY msg_id DESC
FETCH FIRST 10 ROWS ONLY;
exit;
