set define off feedback on echo off linesize 200

DELETE FROM doc_chunks;
DELETE FROM source_docs;
COMMIT;

INSERT INTO source_docs (title, source_ref, content)
VALUES (
  '01_cloud_sla.txt',
  '01_cloud_sla.txt',
  '[DOCUMENT: Enterprise Cloud SLA & Support Policy 2026]
The Enterprise Cloud Service Level Agreement outlines response and resolution commitments.
Severity 1 Critical Outage: System completely unavailable. Response time is strictly under 15 minutes with 24x7 phone, SMS, and pager alerts. Dedicated bridge established immediately.
Severity 2 Major Degradation: Core workflows impacted. Response time is under 2 hours during normal business hours (Monday to Friday, 8 AM to 6 PM IST).
Severity 3 Minor Issue: Non-critical anomalies or inquiries. Response time is under 24 business hours.
Annual Uptime Commitment: A guaranteed target of 99.95% availability calculated on an annual basis, excluding weekly scheduled maintenance windows (Sunday 02:00 to 04:00 AM IST).
Penalty Credits: Service credits of 5% of monthly billing for each full 0.1% uptime drop below 99.95%.'
);

INSERT INTO source_docs (title, source_ref, content)
VALUES (
  '02_leave_policy.txt',
  '02_leave_policy.txt',
  '[DOCUMENT: Enterprise Leave & Attendance Policy 2026]
All full-time employees are entitled to standard paid leaves according to the annual calendar.
Annual Earned Leave: Employees accrue 18 days of paid vacation per calendar year. Up to 10 days of unused earned leave can be carried forward to the following year.
Casual Leave: A total of 12 casual leaves are provided per annum for personal or urgent obligations. Casual leaves cannot be clubbed with earned leave for more than 3 continuous days.
Sick Leave: A total of 10 days of medical leave is granted each year. A medical practitioner certificate is mandatory if sick leave exceeds 2 consecutive business days.
Maternity and Paternity Leave: Female employees are eligible for 26 weeks of fully paid maternity leave. Male employees receive 2 weeks of paid paternity leave.
Unpaid Leave of Absence: Permitted only with prior approval from HR and department vice president for emergency situations.'
);

INSERT INTO source_docs (title, source_ref, content)
VALUES (
  '03_data_security.txt',
  '03_data_security.txt',
  '[DOCUMENT: Enterprise Information Security & Compliance Standard 2026]
Data Classification and Encryption:
All sensitive customer and company data at rest must be encrypted using AES-256 standard encryption.
Data in transit across public and internal networks must mandate TLS 1.3 encryption with verified digital certificates.
Authentication Standards:
Passwords must be a minimum of 14 characters containing uppercase, lowercase, numbers, and special symbols.
Multi-Factor Authentication (MFA) using hardware tokens or authenticator apps is mandatory for all internal and VPN access.
Device Security and Patching:
All employee laptops must run managed endpoint detection and response (EDR) software with automatic daily definition updates.
Security vulnerabilities categorized as Critical must be patched within 7 calendar days of vendor release.
Incident Reporting:
Any security anomaly, phishing attempt, or potential data breach must be reported immediately to security-ops@enterprise.com.'
);

INSERT INTO source_docs (title, source_ref, content)
VALUES (
  '04_expense_policy.txt',
  '04_expense_policy.txt',
  '[DOCUMENT: Enterprise Travel & Expense Reimbursement Policy 2026]
Business Travel Guidelines:
All business travel requests must receive prior written approval from the reporting manager at least 14 days in advance of departure.
Flight bookings must be made through the corporate travel portal selecting economy class for domestic flights under 6 hours duration.
Lodging and Meals Per-Diem:
Hotel accommodation limits are capped at Tier 1 metro cities: INR 6,500 per night, and Tier 2 cities: INR 4,500 per night inclusive of taxes.
Daily meal allowance is set at INR 1,500 per diem for full travel days without requiring itemized food receipts.
Expense Submission Deadline:
All travel expense claims accompanied by digital receipts must be submitted via the finance portal within 15 calendar days of return from travel.
Late submissions beyond 30 days require exceptional sign-off by the Chief Financial Officer (CFO).'
);

INSERT INTO source_docs (title, source_ref, content)
VALUES (
  '05_support_escalation.txt',
  '05_support_escalation.txt',
  '[DOCUMENT: Enterprise Technical Support & Escalation Matrix 2026]
Tier 1 First Line Support:
The 24x7 service desk handles initial ticket triage, user account unlocking, and basic troubleshooting. Target resolution window is 1 hour.
Tier 2 Senior Engineering:
Unresolved technical anomalies are escalated to Tier 2 engineering within 30 minutes of triage failure. Tier 2 engineers have direct access to application logs and staging environments.
Tier 3 Architecture and Core Development:
Critical bugs, database corruptions, or cloud infrastructure outages requiring source code modification are escalated to Tier 3 product architecture.
Executive Incident Bridge:
If an outage remains unresolved after 60 minutes, the Incident Commander opens a mandatory Executive War Room with the VP of Engineering and customer success leadership.
Customer communication updates must be posted every 30 minutes on the public status page until full resolution.'
);

COMMIT;

PROMPT === SOURCE_DOCS Loaded Summary ===
SELECT doc_id, title, length(content) as content_char_len FROM source_docs ORDER BY doc_id;

exit;
