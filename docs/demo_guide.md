# Operational Walkthrough

Use this flow for a stakeholder, viva, or product demonstration.

1. Sign in as a student.
2. Open **DSW Service Center**.
3. Submit one request (for example financial assistance or event permission) with a supporting document/image.
4. Save the generated tracking number.
5. Open **Track Service Requests** and show the Submitted status and history.
6. Open **AI DSW Helpdesk** and ask a service-process question.
7. Sign in as a DSW officer or director.
8. Open the unified request queue.
9. Run AI analysis and show predicted priority, summary, duplicate/image advisory fields.
10. Move the request to **Under Review**.
11. Assign it to a responsible `dsw_officer`.
12. Show the assignment notification and audit/history behavior.
13. Sign in as the assigned officer (or use director oversight) and resolve the request with an official note.
14. Return to the student view and show the Resolved status, resolution note, notification, and full history.
15. Open the analytics dashboard and explain that Gemini receives aggregate metrics only.

## Presentation points

- The official lifecycle is enforced: Submitted → Under Review → Assigned → Resolved.
- AI is advisory and never performs the official approval/assignment/resolution decision.
- Students see only their own service records; staff use role-based operational access.
- Uploaded evidence is restricted by Storage Rules and file validation.
- For institutional production, add FCM push delivery, web App Check, emulator/rules tests, monitoring and CUET-approved privacy/retention policies.
