#!/usr/bin/env python3
"""
Robust parser for active_doc_raw.txt that handles flattened or wrapped lines,
extracting projects, tasks, assignees, and statuses into clean UGDS Markdown.
"""

import re
import sys

def parse_and_convert():
    with open('/home/ubuntu/docs/active_doc_raw.txt', 'r', encoding='utf-8', errors='replace') as f:
        text = f.read()

    # Split by PROJECT markers
    proj_parts = re.split(r'[=]{10,}\s*PROJECT:\s*', text, flags=re.IGNORECASE)
    
    ugds_lines = [
        "# [DOCUMENT: Enterprise Task Registry - All Projects]",
        "> **Format:** UGDS Canonical Markdown | **Standard:** Record-Level Atomic Units",
        ""
    ]

    total_tasks_found = 0

    for part in proj_parts[1:]:
        # Extract project name (up to the next ===)
        m_proj = re.match(r'^\s*([^=\n]+)\s*[=]{10,}(.*)', part, re.DOTALL)
        if not m_proj:
            continue
        proj_name = m_proj.group(1).strip()
        body = m_proj.group(2).strip()

        ugds_lines.append(f"\n## [SECTION: Project {proj_name}]")

        # Extract Project Metadata (Owner, Team, Status)
        m_meta = re.search(r'Owner:\s*([^\n]+?)\s+Team:\s*([^\n]+?)\s+Status:\s*([^\n]+?)(?=\s+Tasks:|\s+Created:|\s+Change|\s+\d+\.|\Z)', body, re.IGNORECASE)
        if m_meta:
            ugds_lines.append(f"> **Owner:** {m_meta.group(1).strip()} | **Team:** {m_meta.group(2).strip()} | **Status:** {m_meta.group(3).strip()}")

        # Match all tasks inside this project
        # Each task starts with '<number>. <Title> Assignee: <Name> Status: <Status>'
        task_regex = re.compile(
            r'(?:^|\s+)(\d+)\.\s+(.+?)\s+Assignee:\s*([A-Za-z0-9_-]+)\s+Status:\s*([A-Za-z0-9 ]+?)(?=\s+Priority:|\s+Deadline:|\s+Repeats:|\s+Description:|\s+Comments:|\s+\d+\.|\Z)',
            re.DOTALL
        )

        # Better: split by task numbers
        # Find all positions of " <num>. "
        matches = list(re.finditer(r'(?:^|\s+)(\d+)\.\s+', body))
        for i, match in enumerate(matches):
            num = match.group(1)
            start_pos = match.end()
            end_pos = matches[i+1].start() if i + 1 < len(matches) else len(body)
            task_chunk = body[start_pos:end_pos].strip()

            # Parse fields within task_chunk
            m_assignee = re.search(r'\bAssignee:\s*([A-Za-z0-9_-]+)', task_chunk, re.IGNORECASE)
            m_status = re.search(r'\bStatus:\s*([A-Za-z0-9 ]+?)(?=\s+(?:Priority|Deadline|Repeats|Description|Comments)|\s*$)', task_chunk, re.IGNORECASE)
            m_priority = re.search(r'\bPriority:\s*([A-Za-z]+)', task_chunk, re.IGNORECASE)
            m_deadline = re.search(r'\bDeadline:\s*([0-9]{4}-[0-9]{2}-[0-9]{2})', task_chunk, re.IGNORECASE)

            # Title is from start to "Assignee:"
            if m_assignee:
                task_title = task_chunk[:m_assignee.start()].strip()
            else:
                task_title = task_chunk[:100].strip()

            assignee = m_assignee.group(1).strip() if m_assignee else "Unassigned"
            status = m_status.group(1).strip() if m_status else "Open"
            priority = m_priority.group(1).strip() if m_priority else "Normal"
            deadline = m_deadline.group(1).strip() if m_deadline else "None"

            # Clean task_title of line breaks or long junk
            task_title = re.sub(r'\s+', ' ', task_title)
            # Remove any trailing 'Assignee' or junk
            task_title = re.sub(r'\s*Assignee.*$', '', task_title, flags=re.IGNORECASE).strip()

            record_line = f"- **Task {num}:** Task: {task_title} | Project: {proj_name} | Assignee: {assignee} | Status: {status} | Priority: {priority} | Deadline: {deadline}"
            ugds_lines.append(record_line)
            ugds_lines.append("---")
            total_tasks_found += 1

    final_ugds = "\n".join(ugds_lines)
    with open('/home/ubuntu/docs/all_app_data_clean_ugds.txt', 'w', encoding='utf-8') as f:
        f.write(final_ugds)

    print(f"[SUCCESS] Parsed and converted {total_tasks_found} tasks into UGDS format.")
    print(f"Output saved to: /home/ubuntu/docs/all_app_data_clean_ugds.txt")

if __name__ == "__main__":
    parse_and_convert()
