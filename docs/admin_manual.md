# DSW Officer & Director Manual

## Access

Operational access is role based. Staff profiles in `/users/{uid}` must use either:

- `dsw_officer`
- `dsw_director`

Students cannot self-assign a staff role.

## Unified request queue

Open **DSW Officer Request Queue** (or **DSW Request Oversight** for director view) to manage the six unified service categories.

The enforced workflow is:

`SUBMITTED → UNDER_REVIEW → ASSIGNED → RESOLVED`

### 1. Start review

A newly submitted request can only move to **Under Review**.

### 2. Run AI analysis

Staff can re-run AI analysis from the queue. Staff-side analysis can:

- predict a suggested priority
- summarize the request
- suggest the responsible office
- flag risk indicators
- compare against a broader request set for possible duplicates
- analyze JPG/PNG supporting evidence

AI output is advisory. Staff remain responsible for every workflow decision.

### 3. Assign officer

An **Under Review** request can be assigned only to a Firestore user whose role is `dsw_officer`. The student and responsible officer receive in-app workflow notifications.

### 4. Resolve

An **Assigned** request can be resolved by the assigned officer or a DSW director. A non-empty official resolution note is required.

## Application history and audit trail

Each unified request has a history subcollection containing status, action, note, actor and timestamp. Staff workflow transitions also create immutable audit-log records.

## Complaint operations

The complaint management screen supports the same business status sequence and officer assignment. Staff can run cross-record AI duplicate/image analysis, review AI suggestions, then make the actual administrative decision manually.

## Analytics dashboard

The analytics dashboard shows operational KPIs such as:

- total/open/resolved requests
- high or urgent predicted/official priorities
- unresolved complaints
- duplicate flags
- average resolution time
- request/status/category breakdowns

Gemini receives aggregated metrics only for management insights; case text and student identifiers are not sent in the analytics prompt.

## Security responsibilities

- Do not share staff accounts.
- Do not resolve a request without an official outcome note.
- Treat confidential complaints and uploaded documents as restricted records.
- Do not treat AI output as an official decision.
- Review Firebase audit logs and access rules before production launch.
