#!/usr/bin/env python3
"""
Applies robust Active Knowledge Base Region on APEX Page 2
Handles large document counts (800+ docs) with zero ORA-06502 buffer overflow errors.
"""
import oracledb

def main():
    conn = oracledb.connect(
        user="AIDEMO", 
        password="Apex_26ai_2026Free", 
        dsn="20.0.1.130:1521/FREEPDB1"
    )
    cur = conn.cursor()

    robust_kb_source = """DECLARE
    l_html CLOB;
    l_row VARCHAR2(32767);
    l_total_docs NUMBER := 0;
    l_count NUMBER := 0;
BEGIN
    DBMS_LOB.CREATETEMPORARY(l_html, TRUE);
    
    SELECT COUNT(*) INTO l_total_docs FROM source_docs;

    l_row := '<div class="admin-wrap"><div class="admin-card">' ||
             '<div class="admin-card-header">' ||
                 '<div class="admin-card-title"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#0284c7" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-3px; margin-right:6px;"><ellipse cx="12" cy="5" rx="9" ry="3"/><path d="M21 12c0 1.66-4 3-9 3s-9-1.34-9-3"/><path d="M3 5v14c0 1.66 4 3 9 3s9-1.34 9-3V5"/></svg> Active Knowledge Base Documents in Oracle 26ai</div>' ||
                 '<div style="font-size:0.8rem; font-weight:600; color:#0284c7; background:#e0f2fe; padding:4px 12px; border-radius:9999px;">Total Documents: ' || l_total_docs || '</div>' ||
             '</div>' ||
             '<div style="overflow-x:auto;">' ||
             '<table class="admin-table">' ||
             '<thead><tr>' ||
             '<th>ID</th>' ||
             '<th>Document Title</th>' ||
             '<th>Source File</th>' ||
             '<th>Type</th>' ||
             '<th>Size</th>' ||
             '<th>Chunks (384-dim)</th>' ||
             '<th>Vectorized At</th>' ||
             '<th>Action</th>' ||
             '</tr></thead><tbody>';
    DBMS_LOB.APPEND(l_html, l_row);

    FOR r IN (
        SELECT d.doc_id, d.title, d.source_ref, d.mime_type, d.file_size,
               COUNT(c.chunk_id) as total_chunks,
               TO_CHAR(d.ingested_at, 'YYYY-MM-DD HH24:MI') as vectorized_at
        FROM source_docs d
        LEFT JOIN doc_chunks c ON d.doc_id = c.doc_id
        GROUP BY d.doc_id, d.title, d.source_ref, d.mime_type, d.file_size, d.ingested_at
        ORDER BY d.doc_id DESC
        FETCH FIRST 100 ROWS ONLY
    ) LOOP
        l_count := l_count + 1;
        l_row := '<tr>' ||
            '<td>' || r.doc_id || '</td>' ||
            '<td><strong>' || apex_escape.html(r.title) || '</strong></td>' ||
            '<td style="font-family:monospace; color:#64748b;">' || apex_escape.html(r.source_ref) || '</td>' ||
            '<td><span style="font-size:0.78rem; background:#f1f5f9; padding:2px 7px; border-radius:4px;">' || NVL(apex_escape.html(r.mime_type), 'text/plain') || '</span></td>' ||
            '<td>' || CASE WHEN r.file_size > 0 THEN ROUND(r.file_size / 1024, 1) || ' KB' ELSE '-' END || '</td>' ||
            '<td><span style="background:#e0f2fe; color:#0369a1; padding:3px 9px; border-radius:9999px; font-size:0.8rem; font-weight:600;">' || r.total_chunks || ' Chunks</span></td>' ||
            '<td style="font-size:0.85rem; color:#64748b;">' || NVL(r.vectorized_at, 'Pending') || '</td>' ||
            '<td>' ||
                '<button type="button" class="btn-action-sm btn-delete" data-id="' || r.doc_id || '" data-title="' || apex_escape.html_attribute(r.title) || '" onclick="deleteDoc(this);"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-1px; margin-right:3px;"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg> Delete</button>' ||
            '</td>' ||
        '</tr>';
        DBMS_LOB.APPEND(l_html, l_row);
    END LOOP;

    IF l_count = 0 THEN
        DBMS_LOB.APPEND(l_html, '<tr><td colspan="8" style="text-align:center; padding:2rem; color:#94a3b8;">No documents currently in knowledge base. Upload your original documents above!</td></tr>');
    ELSIF l_total_docs > 100 THEN
        DBMS_LOB.APPEND(l_html, '<tr><td colspan="8" style="text-align:center; padding:1rem; font-weight:600; color:#64748b; background:#f8fafc;">Showing 100 most recent of ' || l_total_docs || ' enterprise documents.</td></tr>');
    END IF;

    DBMS_LOB.APPEND(l_html, '</tbody></table></div></div></div>');
    RETURN l_html;
END;"""

    cur.execute("""
        UPDATE APEX_260200.WWV_FLOW_PAGE_PLUGS
        SET plug_source = :1
        WHERE flow_id = 101 AND page_id = 2 AND plug_name = 'Active Knowledge Base'
    """, [robust_kb_source])
    conn.commit()
    print(f"SUCCESS: Robust Active Knowledge Base region applied to Page 2! ({cur.rowcount} row updated)")

    cur.close()
    conn.close()

if __name__ == "__main__":
    main()
