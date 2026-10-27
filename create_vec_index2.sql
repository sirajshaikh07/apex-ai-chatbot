set serveroutput on
BEGIN
  BEGIN
    EXECUTE IMMEDIATE 'CREATE VECTOR INDEX doc_chunks_vec_idx ON doc_chunks (embedding)
                       ORGANIZATION NEIGHBOR GRAPH
                       DISTANCE COSINE
                       WITH TARGET ACCURACY 95';
    dbms_output.put_line('On-disk HNSW Vector Index created successfully!');
  EXCEPTION WHEN OTHERS THEN
    dbms_output.put_line('HNSW disk index: ' || SQLERRM);
  END;

  BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX doc_chunks_docid_idx ON doc_chunks (doc_id)';
    dbms_output.put_line('B-Tree Index on doc_id created successfully!');
  EXCEPTION WHEN OTHERS THEN
    dbms_output.put_line('B-tree doc_id index: ' || SQLERRM);
  END;
END;
/
exit;
