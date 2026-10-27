set heading on feedback off linesize 300 pagesize 50
SELECT msg_id, user_name, user_prompt, substr(ai_response, 1, 150) as ai_resp, TO_CHAR(created_at, 'DD-MON HH24:MI:SS') as msg_time
FROM chat_history
ORDER BY msg_id DESC
FETCH FIRST 10 ROWS ONLY;
exit;
