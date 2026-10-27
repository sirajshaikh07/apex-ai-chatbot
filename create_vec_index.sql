set serveroutput on
BEGIN
  BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX doc_chunks_vec_idx';
  EXCEPTION WHEN OTHERS THEN NULL;
  END;

  EXECUTE IMMEDIATE 'CREATE VECTOR INDEX doc_chunks_vec_idx ON doc_chunks (embedding)
                     ORGANIZATION INMEMORY NEIGHBOR GRAPH
                     DISTANCE COSINE
                     WITH TARGET ACCURACY 95';
  dbms_output.put_line('HNSW Vector Index created successfully on DOC_CHUNKS(EMBEDDING)!');
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line('Note on vector index: ' || SQLERRM);
END;
/
exit;
