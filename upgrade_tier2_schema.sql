ALTER TABLE chat_history ADD (user_feedback VARCHAR2(10));
ALTER TABLE chat_history ADD (feedback_category VARCHAR2(50));
ALTER TABLE chat_history ADD (feedback_comment VARCHAR2(1000));
ALTER TABLE chat_history ADD (feedback_time TIMESTAMP(6));
ALTER TABLE chat_history ADD (retrieved_chunk_ids VARCHAR2(500));
ALTER TABLE chat_history ADD (retrieval_scores VARCHAR2(500));
ALTER TABLE chat_history ADD (prompt_chars NUMBER);
ALTER TABLE chat_history ADD (completion_chars NUMBER);
ALTER TABLE chat_history ADD (is_refusal VARCHAR2(1) DEFAULT 'N');

desc chat_history;
exit;
