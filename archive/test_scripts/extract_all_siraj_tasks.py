import re
import json

def parse():
    with open('/home/ubuntu/docs/sql_run.log', 'r', encoding='utf-8', errors='ignore') as f:
        text = f.read()

    # Find the JSON part or extract all task blocks
    # Tasks have format:
    # { "id": "...", "done": true/false, ..., "name": "...", ..., "assignee": "Siraj", ... "status": "dn"/"ns" }
    
    # Let's find all json-like blocks or match them with regex
    pattern = re.compile(r'\{\s*"id":\s*"([^"]+)",\s*"done":\s*(true|false),.*?"name":\s*"([^"]+)",.*?"assignee":\s*"([^"]+)",.*?"status":\s*"([^"]+)"', re.DOTALL)
    
    matches = pattern.findall(text)
    print(f"Total tasks found via regex 1: {len(matches)}")
    
    # If regex was too strict, let's parse using json or line-by-line
    siraj_tasks = []
    
    # Let's do a more robust block search
    # Find all { ... "assignee": "Siraj" ... }
    blocks = re.split(r'\{\s*"id":', text)
    print(f"Total raw blocks: {len(blocks)}")
    
    all_siraj = []
    for b in blocks:
        if '"assignee": "Siraj"' in b or '"assignee":"Siraj"' in b:
            # extract name
            name_m = re.search(r'"name":\s*"([^"]+)"', b)
            done_m = re.search(r'"done":\s*(true|false)', b)
            status_m = re.search(r'"status":\s*"([^"]+)"', b)
            pid_m = re.search(r'"pid":\s*"([^"]+)"', b)
            dl_m = re.search(r'"dl":\s*"([^"]+)"', b)
            desc_m = re.search(r'"desc":\s*"([^"]*)"', b)
            
            name = name_m.group(1) if name_m else "UNKNOWN"
            done = done_m.group(1) if done_m else "UNKNOWN"
            status = status_m.group(1) if status_m else "UNKNOWN"
            pid = pid_m.group(1) if pid_m else ""
            dl = dl_m.group(1) if dl_m else ""
            desc = desc_m.group(1) if desc_m else ""
            
            all_siraj.append({
                "name": name,
                "done": done,
                "status": status,
                "pid": pid,
                "dl": dl,
                "desc": desc
            })
            
    print(f"\n=======================================================")
    print(f"TOTAL TASKS ASSIGNED TO SIRAJ: {len(all_siraj)}")
    print(f"=======================================================")
    
    completed = [t for t in all_siraj if t["done"] == "true" or t["status"] == "dn"]
    open_tasks = [t for t in all_siraj if t["done"] == "false" or t["status"] != "dn"]
    
    print(f"\n--- COMPLETED TASKS (done=true or status=dn): {len(completed)} ---")
    for i, t in enumerate(completed, 1):
        print(f"{i}. [{t['pid']}] {t['name']} (Deadline: {t['dl']})")
        if t['desc']:
            print(f"   Desc: {t['desc']}")
            
    print(f"\n--- NOT COMPLETED / OPEN TASKS (done=false): {len(open_tasks)} ---")
    for i, t in enumerate(open_tasks, 1):
        print(f"{i}. [{t['pid']}] {t['name']} (Status: {t['status']}, Deadline: {t['dl']})")

if __name__ == "__main__":
    parse()
