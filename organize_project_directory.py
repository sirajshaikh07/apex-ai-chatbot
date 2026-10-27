import os
import shutil
import glob

DOCS_DIR = "/home/ubuntu/docs"
ARCHIVE_PY_DIR = os.path.join(DOCS_DIR, "archive", "test_scripts")
ARCHIVE_SQL_DIR = os.path.join(DOCS_DIR, "archive", "test_sql")

os.makedirs(ARCHIVE_PY_DIR, exist_ok=True)
os.makedirs(ARCHIVE_SQL_DIR, exist_ok=True)

# Core Python files to KEEP in root /docs:
KEEP_PY = {
    "run_sql.py",
    "run_sys_sql.py",
    "ocr_service.py"
}

# Core SQL and Shell files to KEEP in root /docs:
KEEP_FILES = {
    "enterprise_rag_pkg.sql",
    "enterprise_rag_schema.sql",
    "setup_ords_chat.sql",
    "update_ingest_proc.sql",
    "fix_delete_proc.sql",
    "fix_schema_doc_sync.sql",
    "load_corpus.sql",
    "CREDENTIALS.md",
    "ENTERPRISE_INTEGRATION_GUIDE.md",
    "ENTERPRISE_RAG_MEMORY_ARCHITECTURE.md",
    "MASTER_ARCHITECTURE_PROMPT.md",
    "deploy_and_test_universal_rag.sh",
    "deploy_apex_app.sh",
    "05_workspace.sh",
    "06_apexlang.sh",
    "07_ollama.sh",
    "08_acl.sh",
    "08_llm_test.sh",
    "09_vector_setup.sh",
    "10_rag_service.sql",
    "10_rag_setup.sh",
    "install_ords.sh",
    "diagnose_8080.sh",
    "run_setup_backend.sh",
    "organize_project_directory.py"
}

print("=== ORGANIZING DOCS DIRECTORY ===")

# 1. Clean up / Archive test python files
moved_py = 0
for f in glob.glob(os.path.join(DOCS_DIR, "*.py")):
    fname = os.path.basename(f)
    if fname not in KEEP_PY and fname != "organize_project_directory.py":
        dest = os.path.join(ARCHIVE_PY_DIR, fname)
        shutil.move(f, dest)
        moved_py += 1

print(f"[1] Moved {moved_py} testing Python scripts to archive/test_scripts/")

# 2. Clean up / Archive test and temporary SQL files
moved_sql = 0
for f in glob.glob(os.path.join(DOCS_DIR, "*.sql")):
    fname = os.path.basename(f)
    if fname not in KEEP_FILES:
        # Check if it is a test, check, temp, eval, print, inspect script
        if (fname.startswith(("test_", "check_", "temp_", "eval_", "print_", "inspect_", "desc_", "verify_", "view_", "dump_"))
            or fname in {"auth_attr.sql", "auth_cols.sql", "clear_history.sql", "recompile.sql", "validate.sql", "sample_scan.png"}):
            dest = os.path.join(ARCHIVE_SQL_DIR, fname)
            shutil.move(f, dest)
            moved_sql += 1

print(f"[2] Moved {moved_sql} testing/scratch SQL scripts to archive/test_sql/")

# 3. Clean up root temp logs / text dumps
cleaned_logs = 0
for pattern in ["temp_*.sql", "sql_run.log", "test_query.log", "test_out.txt", "doc_85_content.txt", "ocr_verify.txt"]:
    for f in glob.glob(os.path.join(DOCS_DIR, pattern)):
        try:
            os.remove(f)
            cleaned_logs += 1
        except Exception:
            pass

print(f"[3] Cleaned up {cleaned_logs} temporary log and dump files.")

print("\n=== CURRENT ROOT DIRECTORY CONTENTS ===")
remaining = sorted(os.listdir(DOCS_DIR))
for r in remaining:
    full_p = os.path.join(DOCS_DIR, r)
    is_d = os.path.isdir(full_p)
    print(f" - {'[DIR] ' if is_d else '      '}{r}")

print("\nDirectory organization successfully completed!")
