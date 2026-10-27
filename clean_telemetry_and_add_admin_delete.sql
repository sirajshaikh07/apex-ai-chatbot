SET DEFINE OFF;
SET SERVEROUTPUT ON;

-- Switch to AIDEMO schema for direct table access
ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

-- 1. PURGE TESTING TELEMETRY & FEEDBACK AUDIT LOG (Reset metrics to 0)
BEGIN
  DELETE FROM AIDEMO.chat_history;
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Successfully purged chat_history. Total Invocations & Issues reset to 0.');
END;
/

-- 2. UPDATE USER APPROVALS REGION (Add Delete User button for Admin)
DECLARE
  l_source CLOB;
BEGIN
  l_source := q'[DECLARE
    l_html CLOB := '<div class="admin-wrap"><div class="admin-card">' ||
                   '<div class="admin-card-header">' ||
                       '<div class="admin-card-title"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#0284c7" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-3px; margin-right:6px;"><path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8.5" cy="7" r="4"/><line x1="20" y1="8" x2="20" y2="14"/><line x1="23" y1="11" x2="17" y2="11"/></svg> User Account Approval Requests</div>' ||
                   '</div>' ||
                   '<div style="overflow-x:auto;">' ||
                   '<table class="admin-table">' ||
                   '<thead><tr>' ||
                   '<th>#</th>' ||
                   '<th>Username</th>' ||
                   '<th>Full Name</th>' ||
                   '<th>Email</th>' ||
                   '<th>Requested At</th>' ||
                   '<th>Status</th>' ||
                   '<th>Actions</th>' ||
                   '</tr></thead><tbody>';
    l_count NUMBER := 0;
BEGIN
    FOR r IN (
        SELECT request_id, username, full_name, email, 
               TO_CHAR(requested_at, 'YYYY-MM-DD HH24:MI') as req_time,
               status
        FROM user_registrations
        ORDER BY DECODE(status, 'PENDING', 1, 2), request_id DESC
    ) LOOP
        l_count := l_count + 1;
        l_html := l_html || '<tr>' ||
            '<td>' || r.request_id || '</td>' ||
            '<td><strong>' || apex_escape.html(r.username) || '</strong></td>' ||
            '<td>' || apex_escape.html(r.full_name) || '</td>' ||
            '<td>' || apex_escape.html(r.email) || '</td>' ||
            '<td>' || r.req_time || '</td>' ||
            '<td>' ||
                CASE r.status 
                    WHEN 'PENDING'  THEN '<span class="badge-pending">⏳ Pending Approval</span>'
                    WHEN 'APPROVED' THEN '<span class="badge-approved">✔ Approved &amp; Active</span>'
                    ELSE '<span class="badge-rejected">✖ Rejected</span>'
                END ||
            '</td>' ||
            '<td>' ||
                CASE r.status
                    WHEN 'PENDING' THEN
                        '<button type="button" class="btn-action-sm btn-approve" data-id="' || r.request_id || '" data-user="' || apex_escape.html_attribute(r.username) || '" onclick="approveUser(this);">✔ Approve</button>' ||
                        '<button type="button" class="btn-action-sm btn-reject" data-id="' || r.request_id || '" data-user="' || apex_escape.html_attribute(r.username) || '" onclick="rejectUser(this);">✖ Reject</button>' ||
                        '<button type="button" class="btn-action-sm btn-delete" data-id="' || r.request_id || '" data-user="' || apex_escape.html_attribute(r.username) || '" onclick="deleteUser(this);" style="margin-left:6px;"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-1px; margin-right:3px;"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg> Delete</button>'
                    ELSE
                        '<button type="button" class="btn-action-sm btn-delete" data-id="' || r.request_id || '" data-user="' || apex_escape.html_attribute(r.username) || '" onclick="deleteUser(this);"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-1px; margin-right:3px;"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg> Delete User</button>'
                END ||
            '</td>' ||
        '</tr>';
    END LOOP;

    IF l_count = 0 THEN
        l_html := l_html || '<tr><td colspan="7" style="text-align:center; padding:2rem; color:#94a3b8;">No registered users or requests found.</td></tr>';
    END IF;

    l_html := l_html || '</tbody></table></div></div></div>';
    RETURN l_html;
END;]';

  UPDATE APEX_260200.WWV_FLOW_PAGE_PLUGS
  SET plug_source = l_source
  WHERE flow_id = 101 AND page_id = 2 AND plug_name = 'User Account Approvals';

  DBMS_OUTPUT.PUT_LINE('Updated User Account Approvals region with Delete User actions.');
  COMMIT;
END;
/

-- 3. UPDATE ADMIN SCRIPTS REGION (Add deleteUser and clearAuditLog JavaScript functions)
DECLARE
  l_scripts CLOB;
BEGIN
  l_scripts := q'[<script>
    if (typeof apex !== 'undefined' && apex.page) {
        apex.page.warnOnUnsavedChanges = function() { return false; };
    }
    window.approveUser = function(arg1, arg2) {
        try {
            var reqId = (typeof arg1 === 'object' && arg1 !== null) ? arg1.getAttribute('data-id') : arg1;
            var username = (typeof arg1 === 'object' && arg1 !== null) ? arg1.getAttribute('data-user') : arg2;
            if (!reqId) {
                alert('Error: Missing request ID');
                return;
            }
            if (confirm('Approve user "' + (username || reqId) + '"? This will activate their account immediately.')) {
                apex.item('P2_ACTION_REQ_ID').setValue(reqId);
                apex.submit({
                    request: 'APPROVE_USER',
                    set: { 'P2_ACTION_REQ_ID': reqId },
                    validate: false
                });
            }
        } catch (e) {
            console.error('Error in approveUser:', e);
            alert('Could not submit approval: ' + e.message);
        }
    };

    window.rejectUser = function(arg1, arg2) {
        try {
            var reqId = (typeof arg1 === 'object' && arg1 !== null) ? arg1.getAttribute('data-id') : arg1;
            var username = (typeof arg1 === 'object' && arg1 !== null) ? arg1.getAttribute('data-user') : arg2;
            if (!reqId) {
                alert('Error: Missing request ID');
                return;
            }
            if (confirm('Reject account request for "' + (username || reqId) + '"?')) {
                apex.item('P2_ACTION_REQ_ID').setValue(reqId);
                apex.submit({
                    request: 'REJECT_USER',
                    set: { 'P2_ACTION_REQ_ID': reqId },
                    validate: false
                });
            }
        } catch (e) {
            console.error('Error in rejectUser:', e);
            alert('Could not submit rejection: ' + e.message);
        }
    };

    window.deleteUser = function(arg1, arg2) {
        try {
            var reqId = (typeof arg1 === 'object' && arg1 !== null) ? arg1.getAttribute('data-id') : arg1;
            var username = (typeof arg1 === 'object' && arg1 !== null) ? arg1.getAttribute('data-user') : arg2;
            if (!reqId) {
                alert('Error: Missing request ID');
                return;
            }
            if (confirm('Permanently delete user account "' + (username || reqId) + '" and revoke all login access?')) {
                apex.item('P2_ACTION_REQ_ID').setValue(reqId);
                apex.submit({
                    request: 'DELETE_USER',
                    set: { 'P2_ACTION_REQ_ID': reqId },
                    validate: false
                });
            }
        } catch (e) {
            console.error('Error in deleteUser:', e);
            alert('Could not delete user: ' + e.message);
        }
    };

    window.deleteDoc = function(arg1, arg2) {
        try {
            var docId = (typeof arg1 === 'object' && arg1 !== null) ? arg1.getAttribute('data-id') : arg1;
            var docTitle = (typeof arg1 === 'object' && arg1 !== null) ? arg1.getAttribute('data-title') : arg2;
            if (!docId) {
                alert('Error: Missing document ID');
                return;
            }
            if (confirm('Permanently delete document "' + (docTitle || docId) + '" and all its vector embeddings?')) {
                apex.item('P2_DELETE_DOC_ID').setValue(docId);
                apex.submit({
                    request: 'DELETE_DOC',
                    set: { 'P2_DELETE_DOC_ID': docId },
                    validate: false
                });
            }
        } catch (e) {
            console.error('Error in deleteDoc:', e);
            alert('Could not delete document: ' + e.message);
        }
    };

    window.clearAuditLog = function() {
        if (confirm('Are you sure you want to permanently clear all AI performance & user feedback audit logs? All metrics will reset to 0.')) {
            apex.submit({
                request: 'CLEAR_AUDIT_LOG',
                validate: false
            });
        }
    };
</script>]';

  UPDATE APEX_260200.WWV_FLOW_PAGE_PLUGS
  SET plug_source = l_scripts
  WHERE flow_id = 101 AND page_id = 2 AND plug_name = 'Admin Scripts';

  DBMS_OUTPUT.PUT_LINE('Updated Admin Scripts region with deleteUser and clearAuditLog functions.');
  COMMIT;
END;
/

-- 4. UPDATE ACTIVE KNOWLEDGE BASE & OBSERVABILITY REGION
DECLARE
  l_obs CLOB;
BEGIN
  l_obs := q'[DECLARE
    l_html CLOB;
    l_count NUMBER := 0;
    l_total_chats NUMBER := 0;
    l_up_votes NUMBER := 0;
    l_down_votes NUMBER := 0;
    l_refusals NUMBER := 0;
    l_avg_latency NUMBER := 0;
    l_sat_rate NUMBER := 0;
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
    ELSE
      l_sat_rate := 0;
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

              -- Observability & Quality Audit Log Card
              '<div class="admin-card">' ||
                  '<div class="admin-card-header">' ||
                      '<div class="admin-card-title">' ||
                          '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-3px; margin-right:6px;"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>' ||
                          'AI Performance & User Feedback Audit Log' ||
                      '</div>' ||
                      '<div style="display:flex; align-items:center; gap:10px;">' ||
                          '<button type="button" class="btn-action-sm btn-delete" onclick="clearAuditLog();" style="padding:4px 10px; font-size:0.75rem;"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-1px; margin-right:3px;"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg> Clear Audit Log</button>' ||
                          '<div class="admin-card-badge">Live Observability</div>' ||
                      '</div>' ||
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
    RETURN l_html;
END;]';

  UPDATE APEX_260200.WWV_FLOW_PAGE_PLUGS
  SET plug_source = l_obs
  WHERE flow_id = 101 AND page_id = 2 AND plug_name = 'Active Knowledge Base';

  DBMS_OUTPUT.PUT_LINE('Updated Active Knowledge Base & Observability region with Clear Audit Log.');
  COMMIT;
END;
/

-- 5. ADD / UPDATE PAGE 2 PROCESSES FOR DELETE_USER AND CLEAR_AUDIT_LOG
DECLARE
  l_count NUMBER := 0;
  l_delete_user_code CLOB := q'[DECLARE
    l_uname VARCHAR2(255);
BEGIN
    IF :P2_ACTION_REQ_ID IS NOT NULL THEN
        BEGIN
            SELECT username INTO l_uname FROM AIDEMO.user_registrations WHERE request_id = :P2_ACTION_REQ_ID;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN l_uname := NULL;
        END;

        IF l_uname IS NOT NULL THEN
            BEGIN
                apex_util.set_workspace(p_workspace => 'AIWORKSPACE');
                IF apex_util.get_user_id(l_uname) IS NOT NULL THEN
                    apex_util.remove_user(p_user_name => l_uname);
                END IF;
            EXCEPTION
                WHEN OTHERS THEN NULL;
            END;
        END IF;

        DELETE FROM AIDEMO.user_registrations WHERE request_id = :P2_ACTION_REQ_ID;
        COMMIT;

        apex_application.g_print_success_message :=
            'User account "' || NVL(l_uname, 'ID ' || :P2_ACTION_REQ_ID) || '" and login access permanently deleted.';
        :P2_ACTION_REQ_ID := NULL;
    END IF;
END;]';

  l_clear_log_code CLOB := q'[BEGIN
    DELETE FROM AIDEMO.chat_history;
    COMMIT;
    apex_application.g_print_success_message := 'AI Performance & User Feedback Audit Log cleared successfully. All metrics reset to 0.';
END;]';

BEGIN
  -- Check and insert/update process DELETE_USER
  SELECT COUNT(*) INTO l_count
  FROM APEX_260200.WWV_FLOW_STEP_PROCESSING
  WHERE flow_id = 101 AND flow_step_id = 2 AND process_name = 'Delete User Account';

  IF l_count > 0 THEN
    UPDATE APEX_260200.WWV_FLOW_STEP_PROCESSING
    SET process_sql_clob = l_delete_user_code
    WHERE flow_id = 101 AND flow_step_id = 2 AND process_name = 'Delete User Account';
  ELSE
    INSERT INTO APEX_260200.WWV_FLOW_STEP_PROCESSING (
      ID, FLOW_ID, FLOW_STEP_ID, PROCESS_SEQUENCE, PROCESS_POINT,
      PROCESS_TYPE, PROCESS_NAME, STATIC_ID, PROCESS_SQL_CLOB,
      PROCESS_CLOB_LANGUAGE, PROCESS_ERROR_MESSAGE, ERROR_DISPLAY_LOCATION,
      PROCESS_WHEN, PROCESS_WHEN_TYPE, PROCESS_IS_STATEFUL_Y_N, INTERNAL_UID
    )
    SELECT
      APEX_260200.WWV_FLOW_ID.NEXT_VAL,
      FLOW_ID,
      FLOW_STEP_ID,
      50,
      PROCESS_POINT,
      PROCESS_TYPE,
      'Delete User Account',
      'delete-user',
      l_delete_user_code,
      PROCESS_CLOB_LANGUAGE,
      PROCESS_ERROR_MESSAGE,
      ERROR_DISPLAY_LOCATION,
      'DELETE_USER',
      PROCESS_WHEN_TYPE,
      'N',
      102005
    FROM APEX_260200.WWV_FLOW_STEP_PROCESSING
    WHERE flow_id = 101 AND flow_step_id = 2 AND process_name = 'Delete Knowledge Base Document';
  END IF;

  -- Check and insert/update process CLEAR_AUDIT_LOG
  SELECT COUNT(*) INTO l_count
  FROM APEX_260200.WWV_FLOW_STEP_PROCESSING
  WHERE flow_id = 101 AND flow_step_id = 2 AND process_name = 'Purge Audit Log';

  IF l_count > 0 THEN
    UPDATE APEX_260200.WWV_FLOW_STEP_PROCESSING
    SET process_sql_clob = l_clear_log_code
    WHERE flow_id = 101 AND flow_step_id = 2 AND process_name = 'Purge Audit Log';
  ELSE
    INSERT INTO APEX_260200.WWV_FLOW_STEP_PROCESSING (
      ID, FLOW_ID, FLOW_STEP_ID, PROCESS_SEQUENCE, PROCESS_POINT,
      PROCESS_TYPE, PROCESS_NAME, STATIC_ID, PROCESS_SQL_CLOB,
      PROCESS_CLOB_LANGUAGE, PROCESS_ERROR_MESSAGE, ERROR_DISPLAY_LOCATION,
      PROCESS_WHEN, PROCESS_WHEN_TYPE, PROCESS_IS_STATEFUL_Y_N, INTERNAL_UID
    )
    SELECT
      APEX_260200.WWV_FLOW_ID.NEXT_VAL,
      FLOW_ID,
      FLOW_STEP_ID,
      60,
      PROCESS_POINT,
      PROCESS_TYPE,
      'Purge Audit Log',
      'purge-audit-log',
      l_clear_log_code,
      PROCESS_CLOB_LANGUAGE,
      PROCESS_ERROR_MESSAGE,
      ERROR_DISPLAY_LOCATION,
      'CLEAR_AUDIT_LOG',
      PROCESS_WHEN_TYPE,
      'N',
      102006
    FROM APEX_260200.WWV_FLOW_STEP_PROCESSING
    WHERE flow_id = 101 AND flow_step_id = 2 AND process_name = 'Delete Knowledge Base Document';
  END IF;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Page 2 processes for DELETE_USER and CLEAR_AUDIT_LOG successfully created/updated.');
END;
/

EXIT;
