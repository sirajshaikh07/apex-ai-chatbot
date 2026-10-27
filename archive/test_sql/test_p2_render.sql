SET DEFINE OFF SERVEROUTPUT ON SIZE UNLIMITED;
DECLARE
    l_html CLOB;
    l_count NUMBER := 0;
    l_total_chats NUMBER := 0;
    l_up_votes NUMBER := 0;
    l_down_votes NUMBER := 0;
    l_refusals NUMBER := 0;
    l_avg_latency NUMBER := 0;
    l_sat_rate NUMBER := 100;
BEGIN
    -- Query Observability Metrics (Tier 2 Item 11 & 19)
    SELECT COUNT(*),
           NVL(SUM(CASE WHEN user_feedback = 'UP' THEN 1 ELSE 0 END), 0),
           NVL(SUM(CASE WHEN user_feedback = 'DOWN' THEN 1 ELSE 0 END), 0),
           NVL(SUM(CASE WHEN is_refusal = 'Y' THEN 1 ELSE 0 END), 0),
           NVL(ROUND(AVG(response_time_ms)), 0)
    INTO   l_total_chats, l_up_votes, l_down_votes, l_refusals, l_avg_latency
    FROM   chat_history;

    IF (l_up_votes + l_down_votes) > 0 THEN
      l_sat_rate := ROUND((l_up_votes * 100) / (l_up_votes + l_down_votes), 1);
    END IF;

    l_html := '<div class="admin-wrap">' ||
              -- Observability Dashboard Summary Cards
              '<div style="display:grid; grid-template-columns:repeat(auto-fit, minmax(200px, 1fr)); gap:14px; margin-bottom:24px;">' ||
                  '<div style="background:#ffffff; border:1px solid #e2e8f0; border-radius:12px; padding:16px; box-shadow:0 1px 3px rgba(0,0,0,0.05);">' ||
                      '<div style="font-size:0.78rem; font-weight:600; text-transform:uppercase; color:#64748b; letter-spacing:0.5px;">Total Invocations</div>' ||
                      '<div style="font-size:1.75rem; font-weight:800; color:#0f172a; margin-top:4px;">' || l_total_chats || '</div>' ||
                      '<div style="font-size:0.75rem; color:#94a3b8; margin-top:2px;">Chat history turns</div>' ||
                  '</div>' ||
                  '<div style="background:#ffffff; border:1px solid #e2e8f0; border-radius:12px; padding:16px; box-shadow:0 1px 3px rgba(0,0,0,0.05);">' ||
                      '<div style="font-size:0.78rem; font-weight:600; text-transform:uppercase; color:#059669; letter-spacing:0.5px;">Satisfaction Rate</div>' ||
                      '<div style="font-size:1.75rem; font-weight:800; color:#059669; margin-top:4px;">' || l_sat_rate || '%</div>' ||
                      '<div style="font-size:0.75rem; color:#64748b; margin-top:2px;">👍 ' || l_up_votes || ' upvotes</div>' ||
                  '</div>' ||
                  '<div style="background:#ffffff; border:1px solid #e2e8f0; border-radius:12px; padding:16px; box-shadow:0 1px 3px rgba(0,0,0,0.05);">' ||
                      '<div style="font-size:0.78rem; font-weight:600; text-transform:uppercase; color:#dc2626; letter-spacing:0.5px;">Issues Reported</div>' ||
                      '<div style="font-size:1.75rem; font-weight:800; color:#dc2626; margin-top:4px;">' || l_down_votes || '</div>' ||
                      '<div style="font-size:0.75rem; color:#64748b; margin-top:2px;">👎 Thumbs down logged</div>' ||
                  '</div>' ||
                  '<div style="background:#ffffff; border:1px solid #e2e8f0; border-radius:12px; padding:16px; box-shadow:0 1px 3px rgba(0,0,0,0.05);">' ||
                      '<div style="font-size:0.78rem; font-weight:600; text-transform:uppercase; color:#0284c7; letter-spacing:0.5px;">Grounding Refusals</div>' ||
                      '<div style="font-size:1.75rem; font-weight:800; color:#0284c7; margin-top:4px;">' || l_refusals || '</div>' ||
                      '<div style="font-size:0.75rem; color:#64748b; margin-top:2px;">Out-of-domain shielded</div>' ||
                  '</div>' ||
                  '<div style="background:#ffffff; border:1px solid #e2e8f0; border-radius:12px; padding:16px; box-shadow:0 1px 3px rgba(0,0,0,0.05);">' ||
                      '<div style="font-size:0.78rem; font-weight:600; text-transform:uppercase; color:#7c3aed; letter-spacing:0.5px;">Avg Latency</div>' ||
                      '<div style="font-size:1.75rem; font-weight:800; color:#7c3aed; margin-top:4px;">' || l_avg_latency || '<span style="font-size:0.9rem; font-weight:500;"> ms</span></div>' ||
                      '<div style="font-size:0.75rem; color:#64748b; margin-top:2px;">Hybrid search + LLM</div>' ||
                  '</div>' ||
              '</div>' ||

              -- Active Knowledge Base Card
              '<div class="admin-card" style="margin-bottom:24px;">' ||
                  '<div class="admin-card-header">' ||
                      '<div class="admin-card-title">' ||
                          '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-3px; margin-right:6px;"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/></svg>' ||
                          'Active Knowledge Base Documents (Tier 1 Verified)' ||
                      '</div>' ||
                      '<div class="admin-card-badge">Oracle 26ai In-DB Vector Search</div>' ||
                  '</div>' ||
                  '<div class="admin-table-wrap">' ||
                      '<table class="admin-table">' ||
                          '<thead>' ||
                              '<tr>' ||
                                  '<th>Doc ID</th>' ||
                                  '<th>Title</th>' ||
                                  '<th>Status</th>' ||
                                  '<th>SHA-256 Hash</th>' ||
                                  '<th>Chunks</th>' ||
                                  '<th>Vectorized At</th>' ||
                                  '<th>Actions</th>' ||
                              '</tr>' ||
                          '</thead>' ||
                          '<tbody>';

    FOR r IN (
        SELECT d.doc_id,
               d.title,
               NVL(d.status, 'ACTIVE') as status,
               SUBSTR(NVL(d.file_hash, 'N/A'), 1, 12) || '...' as short_hash,
               COUNT(c.chunk_id) as total_chunks,
               TO_CHAR(d.ingested_at, 'YYYY-MM-DD HH24:MI') as vectorized_at
        FROM source_docs d
        LEFT JOIN doc_chunks c ON d.doc_id = c.doc_id
        GROUP BY d.doc_id, d.title, d.status, d.file_hash, d.ingested_at
        ORDER BY d.doc_id ASC
    ) LOOP
        l_count := l_count + 1;
        l_html := l_html ||
            '<tr>' ||
                '<td><b>#' || r.doc_id || '</b></td>' ||
                '<td style="font-weight:600; color:#0f172a;">' || apex_escape.html(r.title) || '</td>' ||
                '<td><span style="background:#dcfce7; color:#15803d; padding:2px 8px; border-radius:9999px; font-size:0.75rem; font-weight:700;">' || r.status || '</span></td>' ||
                '<td><code style="font-size:0.78rem; background:#f1f5f9; padding:2px 6px; border-radius:4px; color:#475569;">' || r.short_hash || '</code></td>' ||
                '<td><span style="background:#e0f2fe; color:#0369a1; padding:3px 9px; border-radius:9999px; font-size:0.8rem; font-weight:600;">' || r.total_chunks || ' Chunks</span></td>' ||
                '<td style="font-size:0.85rem; color:#64748b;">' || NVL(r.vectorized_at, 'Pending') || '</td>' ||
                '<td>' ||
                    '<button type="button" class="btn-action-sm btn-delete" data-id="' || r.doc_id || '" data-title="' || apex_escape.html_attribute(r.title) || '" onclick="deleteDoc(this);"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-1px; margin-right:3px;"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg> Delete</button>' ||
                '</td>' ||
            '</tr>';
    END LOOP;

    IF l_count = 0 THEN
        l_html := l_html || '<tr><td colspan="7" style="text-align:center; padding:2rem; color:#94a3b8;">No documents currently in knowledge base. Upload your original documents above!</td></tr>';
    END IF;

    l_html := l_html || '</tbody></table></div></div>' ||

              -- Observability & Quality Audit Log Card (Tier 2 Item 10 & 11)
              '<div class="admin-card">' ||
                  '<div class="admin-card-header">' ||
                      '<div class="admin-card-title">' ||
                          '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-3px; margin-right:6px;"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>' ||
                          'AI Performance & User Feedback Audit Log' ||
                      '</div>' ||
                      '<div class="admin-card-badge">Live Observability</div>' ||
                  '</div>' ||
                  '<div class="admin-table-wrap">' ||
                      '<table class="admin-table">' ||
                          '<thead>' ||
                              '<tr>' ||
                                  '<th>Time</th>' ||
                                  '<th>User Question</th>' ||
                                  '<th>Feedback</th>' ||
                                  '<th>Category / Reason</th>' ||
                                  '<th>User Comment</th>' ||
                                  '<th>Latency</th>' ||
                                  '<th>Guardrail</th>' ||
                              '</tr>' ||
                          '</thead>' ||
                          '<tbody>';

    l_count := 0;
    FOR f IN (
        SELECT msg_id,
               user_prompt,
               SUBSTR(ai_response, 1, 80) as ans_snippet,
               user_feedback,
               feedback_category,
               feedback_comment,
               response_time_ms,
               is_refusal,
               TO_CHAR(created_at, 'MM-DD HH24:MI') as chat_time
        FROM   chat_history
        ORDER BY msg_id DESC
        FETCH FIRST 8 ROWS ONLY
    ) LOOP
        l_count := l_count + 1;
        l_html := l_html ||
            '<tr>' ||
                '<td style="font-size:0.8rem; color:#64748b; white-space:nowrap;">' || f.chat_time || '</td>' ||
                '<td style="font-weight:600; color:#0f172a; max-width:240px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;">' || apex_escape.html(f.user_prompt) || '</td>' ||
                '<td>' ||
                    CASE 
                        WHEN f.user_feedback = 'UP' THEN '<span style="background:#ecfdf5; color:#059669; padding:2px 8px; border-radius:9999px; font-weight:700; font-size:0.75rem;">👍 Helpful</span>'
                        WHEN f.user_feedback = 'DOWN' THEN '<span style="background:#fef2f2; color:#dc2626; padding:2px 8px; border-radius:9999px; font-weight:700; font-size:0.75rem;">👎 Issue</span>'
                        ELSE '<span style="color:#94a3b8; font-size:0.75rem;">Pending</span>'
                    END ||
                '</td>' ||
                '<td style="font-size:0.82rem; color:#334155;">' || NVL(apex_escape.html(f.feedback_category), '<span style="color:#cbd5e1;">-</span>') || '</td>' ||
                '<td style="font-size:0.82rem; color:#64748b; font-style:italic; max-width:180px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;">' || NVL(apex_escape.html(f.feedback_comment), '<span style="color:#cbd5e1;">-</span>') || '</td>' ||
                '<td style="font-size:0.82rem; color:#475569; font-weight:600;">' || NVL(TO_CHAR(f.response_time_ms), '0') || ' ms</td>' ||
                '<td>' ||
                    CASE WHEN f.is_refusal = 'Y' 
                         THEN '<span style="background:#fef3c7; color:#b45309; padding:2px 6px; border-radius:4px; font-size:0.72rem; font-weight:700;">Shielded</span>'
                         ELSE '<span style="background:#f1f5f9; color:#475569; padding:2px 6px; border-radius:4px; font-size:0.72rem;">Passed</span>'
                    END ||
                '</td>' ||
            '</tr>';
    END LOOP;

    IF l_count = 0 THEN
        l_html := l_html || '<tr><td colspan="7" style="text-align:center; padding:1.5rem; color:#94a3b8;">No chat telemetry recorded yet. Start interacting in AI Chat!</td></tr>';
    END IF;

    l_html := l_html || '</tbody></table></div></div></div>';
    DBMS_OUTPUT.PUT_LINE('HTML Generated Successfully! Length: ' || LENGTH(l_html));
END;
/
EXIT;
