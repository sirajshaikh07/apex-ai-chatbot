SET DEFINE OFF;
SET SERVEROUTPUT ON;

DECLARE
  l_source CLOB;
BEGIN
  l_source := q'[DECLARE
    l_html CLOB;
    l_count NUMBER := 0;
    l_total_chats NUMBER := 0;
    l_up_votes NUMBER := 0;
    l_down_votes NUMBER := 0;
    l_refusals NUMBER := 0;
    l_avg_latency NUMBER := 0;
    l_sat_rate NUMBER := 100;
    l_search_query VARCHAR2(4000);
    l_clean_keyword VARCHAR2(4000);
    l_res_count NUMBER := 0;
BEGIN
    -- Handle Hybrid Sandbox Query State: Read directly from session state
    IF :REQUEST = 'SANDBOX_CLEAR' THEN
        l_search_query := NULL;
    ELSE
        l_search_query := TRIM(NVL(:P2_ACTION_REQ_ID, apex_util.get_session_state('P2_ACTION_REQ_ID')));
    END IF;

    -- Query Observability Metrics
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

    l_html := l_html || '</tbody></table></div></div>';

    -- =========================================================================
    -- FEATURE 4: HYBRID SEARCH SANDBOX (TESTING REGION & OBSERVABILITY BOOST)
    -- =========================================================================
    l_html := l_html ||
        '<div class="admin-card" id="sandbox-card" style="margin-bottom:24px; border: 1.5px solid #c7d2fe; box-shadow: 0 4px 6px -1px rgba(99, 102, 241, 0.08);">' ||
            '<div class="admin-card-header" style="background: linear-gradient(135deg, #f8fafc 0%, #eef2ff 100%); padding: 12px 16px; border-radius: 11px 11px 0 0;">' ||
                '<div class="admin-card-title" style="color: #3730a3; font-weight: 700;">' ||
                    '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#4f46e5" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-3px; margin-right:8px;"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/><line x1="11" y1="8" x2="11" y2="14"/><line x1="8" y1="11" x2="14" y2="11"/></svg>' ||
                    'Hybrid Search Sandbox (Vector + BM25 Diagnostic Console)' ||
                '</div>' ||
                '<div class="admin-card-badge" style="background:#4338ca; color:#ffffff; font-weight: 600; padding: 4px 10px; border-radius: 9999px; font-size: 0.75rem;">Oracle 26ai In-DB BM25 + Vector Engine</div>' ||
            '</div>' ||
            '<div style="padding: 16px;">' ||
                '<p style="font-size:0.86rem; color:#475569; margin: 0 0 14px 0;">' ||
                    'Test prompt relevance and inspect real-time <strong>BM25 Keyword Match Scores</strong> (Oracle Text) and <strong>Cosine Vector Distances</strong> (Oracle 26ai Embeddings) directly against indexed knowledge chunks.' ||
                '</p>' ||

                -- Sandbox Search Bar
                '<div style="display:flex; gap:10px; align-items:center; margin-bottom: 18px;">' ||
                    '<div style="position:relative; flex:1;">' ||
                        '<input type="text" id="sandboxSearchInput" ' ||
                               'value="' || apex_escape.html_attribute(NVL(l_search_query, '')) || '" ' ||
                               'placeholder="Enter test prompt or keyword (e.g. probationary period, gifts from supplier, grievance)..." ' ||
                               'onkeydown="if(event.key===''Enter''||event.keyCode===13){event.preventDefault();submitSandboxSearch();}" ' ||
                               'style="width:100%; box-sizing:border-box; padding: 10px 14px; border: 1.5px solid #cbd5e1; border-radius: 8px; font-size: 0.9rem; outline: none; transition: border-color 0.2s;" />' ||
                    '</div>' ||
                    '<button type="button" id="btnSandboxSearch" onclick="submitSandboxSearch();" ' ||
                            'style="background:#4f46e5; color:#ffffff; border:none; padding:10px 18px; border-radius:8px; font-weight:600; font-size:0.88rem; cursor:pointer; display:flex; align-items:center; gap:6px; box-shadow:0 1px 2px rgba(0,0,0,0.05);">' ||
                        '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>' ||
                        'Test Hybrid Search' ||
                    '</button>' ||
                    '<button type="button" onclick="clearSandboxSearch();" ' ||
                            'style="background:#f1f5f9; color:#475569; border:1px solid #cbd5e1; padding:10px 14px; border-radius:8px; font-weight:600; font-size:0.88rem; cursor:pointer;">' ||
                        'Clear' ||
                    '</button>' ||
                '</div>';

    -- Execute Sandbox Query if Query string provided
    IF l_search_query IS NOT NULL AND LENGTH(l_search_query) > 0 THEN
        l_html := l_html ||
            '<div style="margin-top: 10px;">' ||
                '<div style="font-size:0.8rem; font-weight:700; text-transform:uppercase; color:#64748b; letter-spacing:0.5px; margin-bottom:10px;">' ||
                    'Top 5 Hybrid Candidates for: <span style="color:#1e1b4b; text-transform:none;">"' || apex_escape.html(l_search_query) || '"</span>' ||
                '</div>';

        -- Sanitize query for Oracle Text CONTAINS by stripping punctuation
        l_clean_keyword := TRIM(REGEXP_REPLACE(l_search_query, '[^a-zA-Z0-9 ]', ' '));

        BEGIN
            FOR s IN (
                SELECT c.chunk_no, 
                       NVL(d.title, 'Corporate Document') as doc_title,
                       NVL(SCORE(1), 0) AS keyword_score,
                       ROUND(VECTOR_DISTANCE(c.embedding, VECTOR_EMBEDDING(aidemo.all_minilm_l12_v2 USING l_search_query AS data), COSINE), 4) AS vector_distance,
                       c.chunk_text
                FROM aidemo.doc_chunks c
                LEFT JOIN aidemo.source_docs d ON c.doc_id = d.doc_id
                WHERE (c.chunk_text IS NOT NULL AND l_clean_keyword IS NOT NULL AND CONTAINS(c.chunk_text, l_clean_keyword, 1) > 0)
                   OR VECTOR_DISTANCE(c.embedding, VECTOR_EMBEDDING(aidemo.all_minilm_l12_v2 USING l_search_query AS data), COSINE) < 0.70
                ORDER BY vector_distance ASC
                FETCH FIRST 5 ROWS ONLY
            ) LOOP
                l_res_count := l_res_count + 1;
                l_html := l_html ||
                    '<div style="background:#f8fafc; border:1px solid #e2e8f0; border-left:4px solid #4f46e5; border-radius:8px; padding:12px 16px; margin-bottom:10px;">' ||
                        '<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:8px; flex-wrap:wrap; gap:6px;">' ||
                            '<div style="font-size:0.85rem; font-weight:700; color:#1e293b;">' ||
                                '<span style="color:#6366f1; margin-right:6px;">#' || l_res_count || '</span>' ||
                                apex_escape.html(s.doc_title) || ' <span style="font-size:0.75rem; color:#64748b; font-weight:500;">(Chunk #' || s.chunk_no || ')</span>' ||
                            '</div>' ||
                            '<div style="display:flex; gap:8px; align-items:center;">' ||
                                '<span style="background:' || CASE WHEN s.keyword_score > 0 THEN '#fef3c7' ELSE '#f1f5f9' END || '; color:' || CASE WHEN s.keyword_score > 0 THEN '#92400e' ELSE '#64748b' END || '; padding:3px 9px; border-radius:9999px; font-size:0.75rem; font-weight:700;">' ||
                                    'BM25 Score: ' || s.keyword_score ||
                                '</span>' ||
                                '<span style="background:' || CASE WHEN s.vector_distance < 0.35 THEN '#ecfdf5' WHEN s.vector_distance < 0.55 THEN '#eff6ff' ELSE '#fef2f2' END || '; color:' || CASE WHEN s.vector_distance < 0.35 THEN '#047857' WHEN s.vector_distance < 0.55 THEN '#1d4ed8' ELSE '#b91c1c' END || '; padding:3px 9px; border-radius:9999px; font-size:0.75rem; font-weight:700;">' ||
                                    'Vector Distance: ' || s.vector_distance ||
                                '</span>' ||
                            '</div>' ||
                        '</div>' ||
                        '<div style="font-family:ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,monospace; font-size:0.82rem; color:#334155; line-height:1.5; max-height:120px; overflow-y:auto; background:#ffffff; padding:10px; border-radius:6px; border:1px solid #e2e8f0; white-space:pre-wrap;">' ||
                            apex_escape.html(SUBSTR(s.chunk_text, 1, 600)) ||
                        '</div>' ||
                    '</div>';
            END LOOP;
        EXCEPTION
            WHEN OTHERS THEN
                -- If CONTAINS syntax throws error on special chars, fallback cleanly to Vector-Only evaluation
                FOR s IN (
                    SELECT c.chunk_no, 
                           NVL(d.title, 'Corporate Document') as doc_title,
                           0 AS keyword_score,
                           ROUND(VECTOR_DISTANCE(c.embedding, VECTOR_EMBEDDING(aidemo.all_minilm_l12_v2 USING l_search_query AS data), COSINE), 4) AS vector_distance,
                           c.chunk_text
                    FROM aidemo.doc_chunks c
                    LEFT JOIN aidemo.source_docs d ON c.doc_id = d.doc_id
                    WHERE VECTOR_DISTANCE(c.embedding, VECTOR_EMBEDDING(aidemo.all_minilm_l12_v2 USING l_search_query AS data), COSINE) < 0.70
                    ORDER BY vector_distance ASC
                    FETCH FIRST 5 ROWS ONLY
                ) LOOP
                    l_res_count := l_res_count + 1;
                    l_html := l_html ||
                        '<div style="background:#f8fafc; border:1px solid #e2e8f0; border-left:4px solid #4f46e5; border-radius:8px; padding:12px 16px; margin-bottom:10px;">' ||
                            '<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:8px; flex-wrap:wrap; gap:6px;">' ||
                                '<div style="font-size:0.85rem; font-weight:700; color:#1e293b;">' ||
                                    '<span style="color:#6366f1; margin-right:6px;">#' || l_res_count || '</span>' ||
                                    apex_escape.html(s.doc_title) || ' <span style="font-size:0.75rem; color:#64748b; font-weight:500;">(Chunk #' || s.chunk_no || ')</span>' ||
                                '</div>' ||
                                '<div style="display:flex; gap:8px; align-items:center;">' ||
                                    '<span style="background:#f1f5f9; color:#64748b; padding:3px 9px; border-radius:9999px; font-size:0.75rem; font-weight:700;">BM25: 0 (Vector-only)</span>' ||
                                    '<span style="background:#ecfdf5; color:#047857; padding:3px 9px; border-radius:9999px; font-size:0.75rem; font-weight:700;">Vector Distance: ' || s.vector_distance || '</span>' ||
                                '</div>' ||
                            '</div>' ||
                            '<div style="font-family:ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,monospace; font-size:0.82rem; color:#334155; line-height:1.5; max-height:120px; overflow-y:auto; background:#ffffff; padding:10px; border-radius:6px; border:1px solid #e2e8f0; white-space:pre-wrap;">' ||
                                apex_escape.html(SUBSTR(s.chunk_text, 1, 600)) ||
                            '</div>' ||
                        '</div>';
                END LOOP;
        END;

        IF l_res_count = 0 THEN
            l_html := l_html ||
                '<div style="text-align:center; padding:1.5rem; color:#64748b; background:#f8fafc; border-radius:8px; border:1px dashed #cbd5e1;">' ||
                    'No chunks matched with Vector Distance &lt; 0.70 or Keyword CONTAINS for this query.' ||
                '</div>';
        END IF;

        l_html := l_html || '</div>';
    ELSE
        l_html := l_html ||
            '<div style="text-align:center; padding:1.5rem; color:#64748b; background:#f8fafc; border-radius:8px; border:1px dashed #cbd5e1; font-size:0.86rem;">' ||
                '💡 Enter any question or phrase above and click <strong>"Test Hybrid Search"</strong> to observe how Oracle 26ai indexes score and rank chunks in real-time.' ||
            '</div>';
    END IF;

    l_html := l_html || '</div></div>';

    -- =========================================================================
    -- CARD 3: Observability & Quality Audit Log Card
    -- =========================================================================
    l_html := l_html ||
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

    -- Inline JavaScript handlers for Sandbox
    l_html := l_html ||
        '<script>' ||
        'window.submitSandboxSearch = function() {' ||
            'var inp = document.getElementById("sandboxSearchInput");' ||
            'if(!inp) return;' ||
            'var q = inp.value.trim();' ||
            'if(!q) { alert("Please enter a prompt or keyword to test."); return; }' ||
            'var btn = document.getElementById("btnSandboxSearch");' ||
            'if(btn) { btn.innerHTML = "⏳ Searching..."; btn.disabled = true; }' ||
            'if(typeof apex !== "undefined") {' ||
                'apex.item("P2_ACTION_REQ_ID").setValue(q);' ||
                'apex.submit({ request: "SANDBOX_SEARCH", set: { "P2_ACTION_REQ_ID": q }, validate: false });' ||
            '}' ||
        '};' ||
        'window.clearSandboxSearch = function() {' ||
            'if(typeof apex !== "undefined") {' ||
                'apex.item("P2_ACTION_REQ_ID").setValue("");' ||
                'apex.submit({ request: "SANDBOX_CLEAR", set: { "P2_ACTION_REQ_ID": "" }, validate: false });' ||
            '}' ||
        '};' ||
        '</script>';

    RETURN l_html;
END;]';

  UPDATE APEX_260200.WWV_FLOW_PAGE_PLUGS
  SET plug_source = l_source
  WHERE flow_id = 101 AND page_id = 2 AND plug_name = 'Active Knowledge Base';

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('SUCCESS: Hybrid Search Sandbox (Feature 4) applied to Page 2 with Session State fix!');
END;
/
EXIT;
