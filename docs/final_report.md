# Final Project Report

## Completed features

- Character Certificate workflow
- Hall Transfer workflow
- Complaint workflow
- AI advisory checks
- Complaint triage recommendation
- Notification structure
- Audit logging foundation
- Basic reporting
- UI skeleton for desktop and mobile flows
- Documentation for architecture and security

## Remaining prototype issues

- Real Cloudinary upload integration requires secure backend setup
- Real Gemini API integration requires backend configuration
- Firebase rules must be hardened in production before real deployment
- Real student/official accounts need final Firebase project setup
- FCM is optional and not required for the current prototype

## Final project structure

- lib/
  - models/
  - screens/
  - services/
  - widgets/
- docs/
- test/

## Firebase configuration required

- Firebase project creation
- Authentication enablement
- Firestore initialization
- Role-based user records
- Cloud Functions for privileged operations
- Secure environment configuration

## Cloudinary configuration required

- Cloudinary account
- signed upload implementation through backend
- allowed MIME type validation
- file size validation
- Firestore metadata storage

## Gemini configuration required

- Gemini API key in backend-only config
- structured JSON response handling
- manual-only decision flow in the UI

## Commands to run

### Student app

```bash
flutter pub get
flutter run
```

### Web admin dashboard

```bash
flutter pub get
flutter run -d chrome
```

## Demo credentials/setup

For local development, use demo-only accounts and sample records. Do not use real personal credentials.

Suggested demo roles:

- Student: `student.demo@cuet.local`
- Official: `official.demo@cuet.local`
- Admin: `admin.demo@cuet.local`

These should be created in the development Firebase project only.

## Recommended presentation sequence

1. Login as student
2. Show home page
3. Submit Character Certificate
4. Demonstrate AI form check
5. Show tracking and status updates
6. Submit complaint
7. Login as official
8. Review request and complaint triage
9. Manual assignment and update
10. Show notification and approved certificate option
11. Show reports and audit logs

## Overall status

This is a working prototype that matches the scope and security constraints for a student service app, with AI recommendations kept advisory and human decision-making preserved.
