#!/usr/bin/env python3
"""
Applies Real-Time Token Streaming UI to APEX Page 1 (Chat Input Bar)
via Python oracledb (clean parameter binding, zero ORA-17090 error).
"""

import oracledb

def main():
    ui_source = """
<div class="chat-app-wrapper">
    <div class="chat-input-wrapper">
        <div class="chat-pill-box">
            <input type="text" id="userChatInput" 
                   placeholder="Ask a question or type a message..." 
                   autocomplete="off" 
                   onkeydown="if(event.key==='Enter'||event.keyCode===13){event.preventDefault();sendChatStreaming();}" />
            <button type="button" id="btnSend" class="btn-action-send" title="Send message (Enter)" onclick="sendChatStreaming();">
                <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="22" y1="2" x2="11" y2="13"></line>
                    <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
                </svg>
            </button>
            <button type="button" id="btnClear" class="btn-action-clear" title="Clear chat history" onclick="apex.submit('CLEAR');">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <polyline points="3 6 5 6 21 6"></polyline>
                    <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                </svg>
            </button>
        </div>
        <div class="chat-input-caption">
            <span id="streamingStatusNotice" style="color:#0284c7; font-weight:500;">⚡ Real-Time Streaming Active</span> &bull; Press <strong>Enter ↵</strong> to send
        </div>
    </div>
</div>

<style>
/* Real-time Streaming Cursor & Markdown Styling */
.typing-cursor {
    display: inline-block;
    width: 8px;
    height: 16px;
    background: #0284c7;
    margin-left: 3px;
    vertical-align: -2px;
    border-radius: 2px;
    animation: blink-cursor 0.8s infinite;
}
@keyframes blink-cursor {
    0%, 100% { opacity: 1; }
    50% { opacity: 0; }
}
.pulse-thinking {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    color: #0284c7;
    font-size: 0.8rem;
    font-weight: 500;
    margin-left: 8px;
}
.pulse-dot {
    width: 6px;
    height: 6px;
    background: #0284c7;
    border-radius: 50%;
    animation: pulse-dot-anim 1.4s infinite ease-in-out both;
}
.pulse-dot:nth-child(1) { animation-delay: -0.32s; }
.pulse-dot:nth-child(2) { animation-delay: -0.16s; }
@keyframes pulse-dot-anim {
    0%, 80%, 100% { transform: scale(0); }
    40% { transform: scale(1.0); }
}
</style>

<script>
window.isGenerating = false;

function escapeHtml(text) {
    if (!text) return "";
    var map = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#039;' };
    return text.replace(/[&<>"']/g, function(m) { return map[m]; });
}

function formatMarkdown(text) {
    if (!text) return "";
    var html = escapeHtml(text);
    // Bold **text**
    html = html.replace(/\\*\\*(.*?)\\*\\*/g, '<strong>$1</strong>');
    // Bullet points
    html = html.replace(/^[ \\t]*[\\*\\-][ \\t]+(.*)$/gm, '&bull; $1');
    // Numbered lists
    html = html.replace(/^[ \\t]*(\\d+)\\.[ \\t]+(.*)$/gm, '<b>$1.</b> $2');
    // Line breaks
    html = html.replace(/\\n/g, '<br/>');
    return html;
}

function getApexSession() {
    if (typeof apex !== 'undefined' && apex.item && apex.item('pInstance')) {
        return apex.item('pInstance').getValue();
    }
    var hiddenSession = document.querySelector('input[name="p_instance"]');
    if (hiddenSession) return hiddenSession.value;
    var match = window.location.href.match(/session=([0-9]+)/);
    return match ? match[1] : '0';
}

function getApexUser() {
    var userEl = document.querySelector('.t-Header-navUser, .app-user-name');
    return userEl ? userEl.innerText.trim() : 'USER';
}

async function sendChatStreaming() {
    var input = document.getElementById('userChatInput');
    var text = input ? input.value.trim() : '';
    if (!text) return;

    if (window.isGenerating) {
        console.warn('Resetting stuck generation lock...');
        window.isGenerating = false;
    }

    window.isGenerating = true;
    input.value = '';
    var btnSend = document.getElementById('btnSend');
    if (btnSend) btnSend.disabled = true;

    var chatScroll = document.getElementById('chatHistoryScroll');
    if (!chatScroll) {
        var wrapper = document.querySelector('.chat-app-wrapper');
        if (wrapper) {
            chatScroll = document.createElement('div');
            chatScroll.id = 'chatHistoryScroll';
            chatScroll.className = 'chat-thread-container';
            wrapper.prepend(chatScroll);
        }
    }

    // Hide empty state if present
    var emptyState = document.querySelector('.chat-empty-state');
    if (emptyState) emptyState.style.display = 'none';

    var now = new Date();
    var timeStr = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

    // 1. Immediately render User Message Bubble
    var userHtml = '<div class="msg-row-user">' +
        '<div class="bubble-user">' +
            '<div class="bubble-user-time">You &bull; ' + timeStr + '</div>' +
            '<div>' + escapeHtml(text) + '</div>' +
        '</div>' +
    '</div>';
    chatScroll.insertAdjacentHTML('beforeend', userHtml);

    // 2. Immediately render AI Message Bubble with Thinking Pulse
    var streamUid = 'stream_' + Date.now();
    var aiHtml = '<div class="msg-row-ai" id="row_' + streamUid + '">' +
        '<div class="bubble-ai">' +
            '<div class="bubble-ai-badge">' +
                '<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="#0284c7" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-3px; margin-right:5px;"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><path d="m9 12 2 2 4-4"/></svg> Enterprise AI' +
                '<span class="pulse-thinking" id="thinking_' + streamUid + '"><span class="pulse-dot"></span><span class="pulse-dot"></span><span class="pulse-dot"></span> Thinking...</span>' +
            '</div>' +
            '<div class="bubble-ai-text" id="text_' + streamUid + '"><span class="typing-cursor"></span></div>' +
            '<div id="footer_' + streamUid + '" style="display:none; justify-content:space-between; align-items:center; margin-top:10px; padding-top:8px; border-top:1px solid #e2e8f0; font-size:0.75rem;"></div>' +
        '</div>' +
    '</div>';
    chatScroll.insertAdjacentHTML('beforeend', aiHtml);
    chatScroll.scrollTop = chatScroll.scrollHeight;

    var sessionId = getApexSession();
    var userName = getApexUser();
    var fullResponse = '';
    var textContainer = document.getElementById('text_' + streamUid);
    var thinkingIndicator = document.getElementById('thinking_' + streamUid);

    try {
        var response = await fetch('/api/chat/stream', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                question: text,
                session_id: sessionId,
                user_name: userName
            })
        });

        if (!response.ok) {
            throw new Error('HTTP ' + response.status + ': ' + response.statusText);
        }

        var reader = response.body.getReader();
        var decoder = new TextDecoder('utf-8');
        var buffer = '';

        while (true) {
            var res = await reader.read();
            if (res.done) break;
            buffer += decoder.decode(res.value, { stream: true });

            var lines = buffer.split('\\n');
            buffer = lines.pop(); // keep last incomplete line

            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim();
                if (!line || !line.startsWith('data: ')) continue;
                try {
                    var payload = JSON.parse(line.substring(6).trim());
                    if (payload.error) {
                        if (thinkingIndicator) {
                            thinkingIndicator.remove();
                            thinkingIndicator = null;
                        }
                        textContainer.innerHTML = '<span style="color:#dc2626; font-weight:500;">⚠️ ' + escapeHtml(payload.error) + '</span>';
                        break;
                    }
                    if (payload.token) {
                        if (thinkingIndicator) {
                            thinkingIndicator.remove();
                            thinkingIndicator = null;
                        }
                        fullResponse += payload.token;
                        textContainer.innerHTML = formatMarkdown(fullResponse) + '<span class="typing-cursor"></span>';
                        if (chatScroll) chatScroll.scrollTop = chatScroll.scrollHeight;
                    }
                    if (payload.done) {
                        textContainer.innerHTML = formatMarkdown(fullResponse);

                        var footer = document.getElementById('footer_' + streamUid);
                        if (footer) {
                            var msgId = payload.msg_id || 0;
                            var sources = payload.sources || '';
                            footer.style.display = 'flex';
                            footer.innerHTML =
                                '<div class="ai-sources" style="color:#64748b; font-size:0.75rem;">' +
                                    (sources ? '📁 <b>Source:</b> ' + escapeHtml(sources) : '') +
                                '</div>' +
                                '<div class="ai-feedback-actions" id="feedback_box_' + msgId + '" style="display:flex; align-items:center; gap:6px;">' +
                                    '<span style="color:#94a3b8; margin-right:2px;">Helpful?</span>' +
                                    '<button type="button" class="btn-fb-up" title="Helpful answer" onclick="submitChatFeedback(' + msgId + ', \\'UP\\');" style="background:#f8fafc; border:1px solid #cbd5e1; border-radius:6px; cursor:pointer; padding:3px 7px; font-size:0.85rem; transition:all 0.2s;">👍</button>' +
                                    '<button type="button" class="btn-fb-down" title="Report issue" onclick="openFeedbackModal(' + msgId + ');" style="background:#f8fafc; border:1px solid #cbd5e1; border-radius:6px; cursor:pointer; padding:3px 7px; font-size:0.85rem; transition:all 0.2s;">👎</button>' +
                                '</div>';
                        }
                        if (chatScroll) chatScroll.scrollTop = chatScroll.scrollHeight;
                    }
                } catch (pe) {
                    // Ignore JSON parse errors on incomplete chunks
                }
            }
        }
    } catch (err) {
        console.error('Streaming request failed:', err);
        if (thinkingIndicator) thinkingIndicator.remove();
        textContainer.innerHTML = '<span style="color:#dc2626;">⚠️ Unable to reach streaming service (' + escapeHtml(err.message) + '). Falling back to standard mode...</span>';
        setTimeout(function() {
            apex.item('P1_QUESTION').setValue(text);
            apex.submit('SEND');
        }, 1500);
    } finally {
        window.isGenerating = false;
        input.disabled = false;
        if (btnSend) btnSend.disabled = false;
        input.focus();
        chatScroll.scrollTop = chatScroll.scrollHeight;
    }
}

function quickAsk(questionText) {
    var input = document.getElementById('userChatInput');
    if (input) {
        input.value = questionText;
        sendChatStreaming();
    }
}

document.addEventListener('DOMContentLoaded', function() {
    if (typeof apex !== 'undefined' && apex.page) {
        apex.page.warnOnUnsavedChanges = function() { return false; };
    }
    var input = document.getElementById('userChatInput');
    if (input) {
        input.addEventListener('keydown', function(e) {
            if (e.key === 'Enter') {
                e.preventDefault();
                sendChatStreaming();
            }
        });
        input.focus();
    }
    var scrollBox = document.getElementById('chatHistoryScroll');
    if (scrollBox) {
        scrollBox.scrollTop = scrollBox.scrollHeight;
    }
});
</script>
"""

    print("Connecting to Oracle Database 26ai as SYSDBA...")
    conn = oracledb.connect(
        user="sys",
        password="Apex_26ai_2026Free",
        dsn="20.0.1.130:1521/FREEPDB1",
        mode=oracledb.AUTH_MODE_SYSDBA
    )
    cursor = conn.cursor()

    try:
        sql = """
        UPDATE APEX_260200.WWV_FLOW_PAGE_PLUGS
        SET plug_source = :1
        WHERE flow_id = 101 AND page_id = 1 AND plug_name = 'Chat Input Bar'
        """
        cursor.execute(sql, [ui_source])
        conn.commit()
        print(f"SUCCESS: Updated {cursor.rowcount} row(s) on APEX Page 1 (Chat Input Bar) with Real-Time Token Streaming UI!")
    finally:
        cursor.close()
        conn.close()

if __name__ == "__main__":
    main()
