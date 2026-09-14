# CUET DSW Operations & Student Services

> **v3 stability fix:** Authentication navigation is now owned only by `AuthGate`, preventing the Flutter `_dependents.isEmpty` lifecycle assertion seen during login/logout or route replacement.


A business-oriented Flutter + Firebase platform for the **CUET Directorate of Students' Welfare (DSW)**. It provides a student mobile experience and staff operations workspace for service requests, complaints, document handling, assignment, tracking, notifications, audit history, and advisory AI features.

> **AI policy:** Gemini output is advisory only. AI never approves, rejects, assigns, or resolves an official request. DSW staff remain responsible for all administrative decisions.


## Important: deploy backend rules after installing this build

A Flutter APK update does **not** update Firestore/Storage security rules. If **Track Service Requests**, **DSW Officer Request Queue**, or **DSW Analytics** shows `PERMISSION_DENIED`, deploy the rules included in this project:

```powershell
firebase deploy --project cuet-dsw-smart-service --only firestore:rules,firestore:indexes,storage
```

The DSW Director can then use **Student Registry Management** to add/update students who are allowed to self-register. See `docs/ISSUE_FIX_SETUP.md` for the exact recovery steps.

## Core business workflow

```text
Student submits request
        ↓
SUBMITTED
        ↓
DSW staff starts review
        ↓
UNDER_REVIEW
        ↓
Request assigned to responsible DSW officer
        ↓
ASSIGNED
        ↓
Officer records official resolution
        ↓
RESOLVED
```

Every transition is written to request history, the student is notified, and staff workflow actions are written to the audit log.

## Implemented modules

| Module | Status | Notes |
| --- | --- | --- |
| Complaint/request submission | ✅ | Unified DSW service request form + dedicated complaint flow |
| Application tracking | ✅ | Tracking number, live status, responsible officer, resolution |
| Document upload | ✅ | Firebase Storage; PDF/JPG/PNG; 5 MB/file validation |
| DSW officer dashboard | ✅ | Existing specialist queues + unified service request queue |
| Assign request to responsible officer | ✅ | Staff can assign a request to a `dsw_officer` account |
| Business workflow | ✅ | Submitted → Under Review → Assigned → Resolved |
| Notifications | ✅ | Submission, status update and assignment notifications |
| Application history | ✅ | Firestore history subcollection for every unified request |
| Analytics dashboard | ✅ | Operational KPIs + Gemini-generated aggregated insights |
| Audit logging | ✅ | Staff actions on unified requests are logged |

## Service categories

The unified **DSW Service Center** supports:

- Hall-related request
- Financial assistance request
- Student welfare complaint
- Event permission
- Certificate / recommendation request
- General grievance

The original specialized **Character Certificate** and **Hall Transfer** flows are preserved for compatibility and can be migrated into the unified workflow later.

## AI capabilities

### AI request & complaint priority prediction
Requests and complaints are analyzed using Firebase AI Logic / Gemini. The model suggests priority, summary, responsible office, and related advisory fields. Predicted priority is stored separately from the official operational priority, and staff verify the recommendation before acting on it.

### AI duplicate complaint detector
A two-stage detector is included:

1. lexical similarity finds likely candidates;
2. Gemini verifies whether the candidate describes substantially the same incident/request.

Students can automatically detect repeated submissions from their own history. Staff can run broader duplicate analysis across request/complaint records from the operational management screens.

### AI image-based complaint analysis
JPG/PNG evidence uploaded to Firebase Storage can be analyzed with Gemini multimodal input. The result describes only visible evidence and is shown as an advisory note to staff.

### AI DSW Helpdesk
Students can open **AI DSW Helpdesk** from the dashboard to ask about supported services and the request process. The assistant is explicitly instructed not to invent university rules, deadlines, fees, or official decisions.

### AI analytics
The staff analytics dashboard calculates KPIs locally from Firestore and sends only **aggregated metrics** to Gemini for management insights. Student names, IDs, complaint text, and other personal records are not included in the analytics prompt.

## Technology stack

- **Frontend:** Flutter / Dart
- **Authentication:** Firebase Authentication
- **Database:** Cloud Firestore
- **Documents:** Firebase Storage
- **AI:** Firebase AI Logic with Gemini
- **Security:** Firestore Rules, Storage Rules, Firebase App Check
- **PDF:** `pdf` + `printing`

## Project structure

```text
lib/
├── models/
│   ├── service_request.dart
│   ├── complaint.dart
│   └── ...
├── services/
│   ├── service_request_service.dart
│   ├── service_request_ai_service.dart
│   ├── analytics_service.dart
│   ├── complaint_service_data.dart
│   ├── firebase_storage_service.dart
│   └── ...
├── screens/
│   ├── service_request_submission_screen.dart
│   ├── my_service_requests_screen.dart
│   ├── service_request_management_screen.dart
│   ├── analytics_dashboard_screen.dart
│   ├── ai_helpdesk_screen.dart
│   └── ...
└── widgets/
```

## Firebase collections

```text
users/{uid}
student_registry/{studentId}
service_requests/{requestId}
  └── history/{historyId}
complaints/{complaintId}
  └── statusHistory/{historyId}
applications/{applicationId}          # legacy specialized flows
application_history/{historyId}       # legacy specialized flows
notifications/{notificationId}
audit_logs/{logId}
```

## Local setup

### 1. Requirements

- Flutter SDK compatible with Dart `^3.9.2`
- Android Studio or VS Code
- A Firebase project with Authentication, Firestore, Storage, App Check, and Firebase AI Logic enabled

### 2. Install packages

```bash
flutter pub get
```

### 3. Firebase configuration

The supplied project already contains generated Firebase configuration for its existing Firebase project. If you use another Firebase project, regenerate configuration with FlutterFire CLI.

Deploy the security configuration:

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage
```

### 4. Create staff accounts

Staff accounts must have a `/users/{uid}` profile whose `role` is one of:

```text
dsw_officer
dsw_director
```

Student self-registration cannot create a staff role.

### 5. Run

```bash
flutter run
```

For Flutter web:

```bash
flutter run -d chrome
```

## Security notes

- Students can read only their own requests/complaints.
- Staff can read operational queues.
- Assignment targets must resolve to a `dsw_officer` profile.
- An assigned request can be resolved by the assigned officer or a DSW director.
- Uploaded files are limited by MIME type and file size in both client code and Storage Rules.
- App Check uses the debug provider in debug builds and Play Integrity in Android release builds.
- Secrets should never be committed to source control.

## Production hardening still recommended

The project is now structured as a business workflow application, but before an institutional production launch you should still:

- move AI enrichment and notification fan-out to trusted Cloud Functions / server-side code;
- configure release App Check for every platform used, including web if deploying the web dashboard;
- add FCM push delivery in addition to in-app Firestore notifications;
- add automated Firebase Emulator integration tests for rules and workflow transitions;
- define retention, privacy, confidential-complaint, and records-management policies with CUET DSW;
- add monitoring/crash reporting and a formal backup/restore process;
- perform accessibility, security, privacy, and user-acceptance testing.

See `docs/BUSINESS_UPGRADE.md` for the implementation checklist and `docs/DEPLOYMENT_CHECKLIST.md` for rollout steps.
