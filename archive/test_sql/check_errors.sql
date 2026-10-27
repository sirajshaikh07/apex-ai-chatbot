SELECT name, type, line, position, text FROM user_errors WHERE name IN ('ENTERPRISE_RAG_PKG', 'POLICY_RAG_PKG', 'TRG_CHAT_HISTORY_OBSERVABILITY');
EXIT;
