SET DEFINE OFF;
DECLARE
  l_source CLOB;
BEGIN
  l_source := q'[DECLARE
    l_output CLOB := '<div class="chat-app-wrapper"><div id="chatHistoryScroll" class="chat-thread-container">';
    l_has_rows BOOLEAN := FALSE;
BEGIN
    FOR r IN (
        SELECT msg_id, user_prompt, ai_response, sources, user_feedback, feedback_category,
               TO_CHAR(created_at, 'HH24:MI') as msg_time
        FROM chat_history
        WHERE session_id = :APP_SESSION
        ORDER BY msg_id ASC
    ) LOOP
        l_has_rows := TRUE;
        l_output := l_output ||
            '<!-- User Bubble -->' ||
            '<div class="msg-row-user">' ||
                '<div class="bubble-user">' ||
                    '<div class="bubble-user-time">You &bull; ' || r.msg_time || '</div>' ||
                    '<div>' || apex_escape.html(r.user_prompt) || '</div>' ||
                '</div>' ||
            '</div>' ||
            '<!-- AI Bubble -->' ||
            '<div class="msg-row-ai">' ||
                '<div class="bubble-ai">' ||
                    '<div class="bubble-ai-badge">' ||
                        '<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="#0284c7" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-3px; margin-right:5px;"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><path d="m9 12 2 2 4-4"/></svg> Enterprise AI' ||
                    '</div>' ||
                    '<div class="bubble-ai-text">' || apex_escape.html(r.ai_response) || '</div>' ||
                    -- Feedback & Sources bar
                    '<div class="ai-footer-bar" style="display:flex; justify-content:space-between; align-items:center; margin-top:10px; padding-top:8px; border-top:1px solid #e2e8f0; font-size:0.75rem;">' ||
                        '<div class="ai-sources" style="color:#64748b; font-size:0.75rem;">' ||
                            CASE WHEN r.sources IS NOT NULL THEN '📁 <b>Source:</b> ' || apex_escape.html(r.sources) ELSE '' END ||
                        '</div>' ||
                        '<div class="ai-feedback-actions" id="feedback_box_' || r.msg_id || '" style="display:flex; align-items:center; gap:6px;">' ||
                            CASE 
                                WHEN r.user_feedback = 'UP' THEN
                                    '<span style="background:#ecfdf5; color:#059669; border:1px solid #a7f3d0; padding:2px 8px; border-radius:12px; font-weight:600;">👍 Helpful</span>'
                                WHEN r.user_feedback = 'DOWN' THEN
                                    '<span style="background:#fef2f2; color:#dc2626; border:1px solid #fecaca; padding:2px 8px; border-radius:12px; font-weight:600;">👎 ' || NVL(apex_escape.html(r.feedback_category), 'Reported') || '</span>'
                                ELSE
                                    '<span style="color:#94a3b8; margin-right:2px;">Helpful?</span>' ||
                                    '<button type="button" class="btn-fb-up" title="Helpful answer" onclick="submitChatFeedback(' || r.msg_id || ', ''UP'');" style="background:#f8fafc; border:1px solid #cbd5e1; border-radius:6px; cursor:pointer; padding:3px 7px; font-size:0.85rem; transition:all 0.2s;" onmouseover="this.style.background=''#e2e8f0'';" onmouseout="this.style.background=''#f8fafc'';">👍</button>' ||
                                    '<button type="button" class="btn-fb-down" title="Report issue" onclick="openFeedbackModal(' || r.msg_id || ');" style="background:#f8fafc; border:1px solid #cbd5e1; border-radius:6px; cursor:pointer; padding:3px 7px; font-size:0.85rem; transition:all 0.2s;" onmouseover="this.style.background=''#e2e8f0'';" onmouseout="this.style.background=''#f8fafc'';">👎</button>'
                            END ||
                        '</div>' ||
                    '</div>' ||
                '</div>' ||
            '</div>';
    END LOOP;

    IF NOT l_has_rows THEN
        l_output := l_output ||
            '<div class="chat-empty-state">' ||
                '<div class="chat-empty-icon">💬</div>' ||
                '<div class="chat-empty-title">Enterprise AI Assistant Active</div>' ||
                '<div class="chat-empty-desc">Ask questions about uploaded documents, candidate bio-data, policies, tasks, or projects.</div>' ||
            '</div>';
    END IF;

    -- Feedback Modal & Script Container
    l_output := l_output ||
        '<!-- Feedback Modal Pop-up -->' ||
        '<div id="aiFeedbackModal" style="display:none; position:fixed; z-index:99999; inset:0; background:rgba(15,23,42,0.6); backdrop-filter:blur(3px); align-items:center; justify-content:center;">' ||
            '<div style="background:#ffffff; border-radius:14px; width:90%; max-width:440px; padding:22px; box-shadow:0 25px 50px -12px rgba(0,0,0,0.25); border:1px solid #e2e8f0;">' ||
                '<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">' ||
                    '<h3 style="margin:0; color:#0f172a; font-size:1.15rem; font-weight:700; display:flex; align-items:center; gap:8px;">' ||
                        '<span>👎</span> Tell Us What Happened' ||
                    '</h3>' ||
                    '<button type="button" onclick="closeFeedbackModal();" style="background:none; border:none; font-size:1.3rem; color:#94a3b8; cursor:pointer;">&times;</button>' ||
                '</div>' ||
                '<p style="color:#64748b; font-size:0.875rem; margin:0 0 14px 0;">Help us refine the Enterprise AI by identifying the issue:</p>' ||
                '<input type="hidden" id="modal_fb_msg_id" value="" />' ||
                '<div style="display:flex; flex-direction:column; gap:9px; margin-bottom:16px;">' ||
                    '<label style="display:flex; align-items:center; gap:9px; font-size:0.9rem; color:#334155; cursor:pointer; background:#f8fafc; padding:8px 12px; border-radius:8px; border:1px solid #e2e8f0;">' ||
                        '<input type="radio" name="fb_category_choice" value="Right info not found" checked />' ||
                        '<span><b>Right info not found</b> (Information exists in document but wasn''t returned)</span>' ||
                    '</label>' ||
                    '<label style="display:flex; align-items:center; gap:9px; font-size:0.9rem; color:#334155; cursor:pointer; background:#f8fafc; padding:8px 12px; border-radius:8px; border:1px solid #e2e8f0;">' ||
                        '<input type="radio" name="fb_category_choice" value="Wrong answer" />' ||
                        '<span><b>Wrong answer</b> (Answer is factually incorrect or misinterpreted)</span>' ||
                    '</label>' ||
                    '<label style="display:flex; align-items:center; gap:9px; font-size:0.9rem; color:#334155; cursor:pointer; background:#f8fafc; padding:8px 12px; border-radius:8px; border:1px solid #e2e8f0;">' ||
                        '<input type="radio" name="fb_category_choice" value="Incomplete details" />' ||
                        '<span><b>Incomplete details</b> (Partial info returned, missed key facts)</span>' ||
                    '</label>' ||
                '</div>' ||
                '<textarea id="modal_fb_comment" placeholder="Optional details (e.g. expected specific phone number, brother count, etc.)..." style="width:100%; border:1px solid #cbd5e1; border-radius:8px; padding:10px; font-size:0.875rem; box-sizing:border-box; min-height:65px; font-family:inherit;"></textarea>' ||
                '<div style="display:flex; justify-content:flex-end; gap:10px; margin-top:16px;">' ||
                    '<button type="button" onclick="closeFeedbackModal();" style="padding:8px 16px; background:#f1f5f9; color:#475569; border:none; border-radius:8px; cursor:pointer; font-weight:600; font-size:0.875rem;">Cancel</button>' ||
                    '<button type="button" onclick="confirmFeedbackSubmission();" style="padding:8px 18px; background:#ef4444; color:#ffffff; border:none; border-radius:8px; cursor:pointer; font-weight:600; font-size:0.875rem; box-shadow:0 2px 4px rgba(239,68,68,0.3);">Submit Feedback</button>' ||
                '</div>' ||
            '</div>' ||
        '</div>' ||
        '<script>' ||
        'window.openFeedbackModal = function(msgId) {' ||
        '    document.getElementById("modal_fb_msg_id").value = msgId;' ||
        '    document.getElementById("modal_fb_comment").value = "";' ||
        '    document.getElementById("aiFeedbackModal").style.display = "flex";' ||
        '};' ||
        'window.closeFeedbackModal = function() {' ||
        '    document.getElementById("aiFeedbackModal").style.display = "none";' ||
        '};' ||
        'window.confirmFeedbackSubmission = function() {' ||
        '    var msgId = document.getElementById("modal_fb_msg_id").value;' ||
        '    var catEl = document.querySelector("input[name=\"fb_category_choice\"]:checked");' ||
        '    var cat = catEl ? catEl.value : "Right info not found";' ||
        '    var comm = document.getElementById("modal_fb_comment").value;' ||
        '    submitChatFeedback(msgId, "DOWN", cat, comm);' ||
        '    closeFeedbackModal();' ||
        '};' ||
        'window.submitChatFeedback = function(msgId, type, category, comment) {' ||
        '    apex.server.process("SUBMIT_FEEDBACK", {' ||
        '        x01: msgId,' ||
        '        x02: type,' ||
        '        x03: category || "",' ||
        '        x04: comment || ""' ||
        '    }, {' ||
        '        success: function(pData) {' ||
        '            var box = document.getElementById("feedback_box_" + msgId);' ||
        '            if (box) {' ||
        '                if (type === "UP") {' ||
        '                    box.innerHTML = "<span style=\"background:#ecfdf5; color:#059669; border:1px solid #a7f3d0; padding:2px 8px; border-radius:12px; font-weight:600;\">👍 Helpful</span>";' ||
        '                } else {' ||
        '                    box.innerHTML = "<span style=\"background:#fef2f2; color:#dc2626; border:1px solid #fecaca; padding:2px 8px; border-radius:12px; font-weight:600;\">👎 " + (category || "Reported") + "</span>";' ||
        '                }' ||
        '            }' ||
        '        },' ||
        '        error: function(err) {' ||
        '            console.error("Feedback error:", err);' ||
        '        }' ||
        '    });' ||
        '};' ||
        '</script>' ||
        '</div></div>';
    RETURN l_output;
END;]';

  UPDATE APEX_260200.WWV_FLOW_PAGE_PLUGS
  SET plug_source = l_source
  WHERE flow_id = 101 AND page_id = 1 AND plug_name = 'Message Stream';

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Updated Message Stream on Page 1 with Tier 2 Feedback UI');
END;
/
EXIT;
