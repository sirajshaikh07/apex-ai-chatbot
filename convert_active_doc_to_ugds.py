#!/usr/bin/env python3
"""
Converts raw active_doc_raw.txt into UGDS Canonical Markdown format
with atomic single-line records and explicit '---' delimiters.
"""

import re
import sys

def main():
    with open('/home/ubuntu/docs/active_doc_raw.txt', 'r', encoding='utf-8', errors='replace') as f:
        content = f.read()

    lines = content.splitlines()
    output = []
    output.append("# [DOCUMENT: Task Tracker - Enterprise Application Data]")
    output.append("> **Type:** Enterprise Task Registry | **Format:** UGDS Canonical Markdown | **Delimited:** Record Level")
    output.append("")

    current_project = "General"
    task_pattern = re.compile(r'^\s*(\d+)\.\s+(.+)$')
    attr_pattern = re.compile(r'^\s*(Assignee|Status|Priority|Deadline|Repeats|Description|Comments):\s*(.*)$', re.IGNORECASE)

    current_task = None
    
    for line in lines:
        line_str = line.strip()
        if not line_str:
            continue
            
        # Detect Project Headers
        if line_str.startswith("PROJECT:") or ("PROJECT:" in line_str and "===" in line_str):
            if current_task:
                output.append(format_task_line(current_task))
                output.append("---")
                current_task = None
            proj_name = re.sub(r'^[=\s]*PROJECT:\s*', '', line_str, flags=re.IGNORECASE)
            proj_name = re.sub(r'[=\s]*$', '', proj_name)
            current_project = proj_name.strip()
            output.append(f"\n## [SECTION: Project {current_project}]")
            continue
            
        # Detect Project Meta (Owner / Team / Status)
        if line_str.startswith("Owner:") or line_str.startswith("Team:") or line_str.startswith("Status:"):
            output.append(f"> **{line_str}**")
            continue

        # Detect Task Start (e.g. "15. Check forticlient console...")
        m_task = task_pattern.match(line_str)
        if m_task:
            if current_task:
                output.append(format_task_line(current_task))
                output.append("---")
            current_task = {
                "num": m_task.group(1),
                "name": m_task.group(2).strip(),
                "project": current_project,
                "attrs": {}
            }
            continue

        # Detect Task Attributes (Assignee, Status, Priority, Deadline)
        m_attr = attr_pattern.match(line_str)
        if m_attr and current_task:
            attr_key = m_attr.group(1).title()
            attr_val = m_attr.group(2).strip()
            current_task["attrs"][attr_key] = attr_val
            continue

        # If continuation of task description/comment, keep short summary
        if current_task and len(current_task.get("extra", "")) < 200:
            if not any(line_str.startswith(x) for x in ["===", "Change request", "Requested by", "Proposed:"]):
                current_task["extra"] = (current_task.get("extra", "") + " " + line_str).strip()

    if current_task:
        output.append(format_task_line(current_task))
        output.append("---")

    final_text = "\n".join(output)
    with open('/home/ubuntu/docs/all_app_data_ugds.txt', 'w', encoding='utf-8') as f:
        f.write(final_text)

    print(f"[SUCCESS] Generated UGDS Canonical Document: /home/ubuntu/docs/all_app_data_ugds.txt")
    print(f"Total lines: {len(output)}")

def format_task_line(task):
    attrs = task["attrs"]
    parts = [
        f"- **Task {task['num']}:** Task: {task['name']}",
        f"**Project:** {task['project']}"
    ]
    if "Assignee" in attrs:
        parts.append(f"**Assignee:** {attrs['Assignee']}")
    if "Status" in attrs:
        parts.append(f"**Status:** {attrs['Status']}")
    if "Priority" in attrs:
        parts.append(f"**Priority:** {attrs['Priority']}")
    if "Deadline" in attrs:
        parts.append(f"**Deadline:** {attrs['Deadline']}")
    if task.get("extra"):
        parts.append(f"**Details:** {task['extra'][:100]}")
    return " | ".join(parts)

if __name__ == "__main__":
    main()
