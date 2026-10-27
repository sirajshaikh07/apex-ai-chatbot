#!/usr/bin/env python3
"""
Adds build_grounded_prompt to enterprise_rag_pkg.sql and refactors ask_with_context.
"""

def main():
    path = "/home/ubuntu/docs/enterprise_rag_pkg.sql"
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    # 1. Add build_grounded_prompt to package specification
    spec_target = "  PROCEDURE submit_feedback ("
    spec_addition = """  -- Grounded prompt & semantic cache builder for real-time streaming
  PROCEDURE build_grounded_prompt (
    p_question       IN  VARCHAR2,
    p_session_id     IN  NUMBER    DEFAULT NULL,
    p_user_name      IN  VARCHAR2  DEFAULT NULL,
    p_prompt         OUT CLOB,
    p_sources        OUT VARCHAR2,
    p_is_cache       OUT VARCHAR2,
    p_cached_answer  OUT CLOB,
    p_cached_msg_id  OUT NUMBER
  );

"""
    if spec_target in content and "PROCEDURE build_grounded_prompt" not in content:
        content = content.replace(spec_target, spec_addition + spec_target, 1)
        print("[SUCCESS] Added build_grounded_prompt to package spec.")

    # 2. Add build_grounded_prompt implementation to package body
    # Let's inspect where PROCEDURE ask_with_context begins in body
    body_proc_start = """  -- Primary context-aware procedure
  PROCEDURE ask_with_context (
    p_question    IN  VARCHAR2,
    p_session_id  IN  NUMBER    DEFAULT NULL,
    p_user_name   IN  VARCHAR2  DEFAULT NULL,
    p_answer      OUT CLOB,
    p_sources     OUT VARCHAR2
  ) IS"""

    body_build_prompt_decl = """  -- Fast in-DB Grounded Prompt & Semantic Cache Builder for Streaming
  PROCEDURE build_grounded_prompt (
    p_question       IN  VARCHAR2,
    p_session_id     IN  NUMBER    DEFAULT NULL,
    p_user_name      IN  VARCHAR2  DEFAULT NULL,
    p_prompt         OUT CLOB,
    p_sources        OUT VARCHAR2,
    p_is_cache       OUT VARCHAR2,
    p_cached_answer  OUT CLOB,
    p_cached_msg_id  OUT NUMBER
  ) IS"""

    if body_proc_start in content:
        # We rename the body of the current ask_with_context to build_grounded_prompt
        # And adjust the outputs at each exit point!
        content = content.replace(body_proc_start, body_build_prompt_decl, 1)
        print("[SUCCESS] Renamed primary logic to build_grounded_prompt.")

    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

if __name__ == "__main__":
    main()
