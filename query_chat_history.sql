SELECT count(*) from chat_history;
SELECT msg_id, session_id, user_prompt, SUBSTR(ai_response, 1, 60), created_at FROM chat_history ORDER BY msg_id DESC FETCH FIRST 5 ROWS ONLY;
EXIT;
