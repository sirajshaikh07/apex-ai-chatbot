import os

corpus_dir = "/home/ubuntu/docs/corpus"
sql_file = "/home/ubuntu/docs/load_corpus.sql"

with open(sql_file, "w") as out:
    out.write("set define off feedback on echo off\n")
    out.write("DELETE FROM doc_chunks;\n")
    out.write("DELETE FROM source_docs;\n")
    out.write("COMMIT;\n\n")
    
    for fname in sorted(os.listdir(corpus_dir)):
        if fname.endswith(".txt"):
            with open(os.path.join(corpus_dir, fname)) as f:
                content = f.read().replace("'", "''")
            out.write(f"INSERT INTO source_docs (title, source_ref, content)\n")
            out.write(f"VALUES ('{fname}', '{fname}', '{content}');\n\n")
            
    out.write("COMMIT;\n\n")
    out.write("PROMPT === SOURCE_DOCS Ingestion Check ===\n")
    out.write("SELECT doc_id, title, length(content) as content_len FROM source_docs ORDER BY doc_id;\n")
    out.write("exit;\n")

print(f"Generated {sql_file} successfully.")
