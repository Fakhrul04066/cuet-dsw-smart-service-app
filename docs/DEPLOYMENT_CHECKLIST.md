# Deployment Checklist

## Firebase
- [ ] Enable Email/Password Authentication.
- [ ] Enable Cloud Firestore.
- [ ] Enable Firebase Storage.
- [ ] Enable Firebase AI Logic / Gemini API for the Firebase project.
- [ ] Register Android App Check with Play Integrity.
- [ ] If deploying web, configure an App Check web provider and site key.
- [ ] Deploy `firestore.rules`.
- [ ] Deploy `firestore.indexes.json`.
- [ ] Deploy `storage.rules`.

## Data setup
- [ ] Sign in as a DSW Director and populate `student_registry` using **Student Registry Management** (or Admin SDK for bulk import).
- [ ] Create DSW officer accounts.
- [ ] Set officer `/users/{uid}.role` to `dsw_officer`.
- [ ] Create director account(s) with role `dsw_director`.
- [ ] Verify staff department/name fields used for assignment labels.

## Functional acceptance tests
- [ ] Student registers/signs in.
- [ ] Student submits each of the six request categories.
- [ ] PDF upload succeeds.
- [ ] JPG/PNG upload succeeds.
- [ ] Oversized/unsupported file is rejected.
- [ ] Student sees tracking number and submission notification.
- [ ] Officer moves request to Under Review.
- [ ] Officer assigns it to a valid responsible officer.
- [ ] Assigned officer resolves it with an official resolution note.
- [ ] Another officer cannot resolve an assignment that does not belong to them.
- [ ] Director can view/resolve as authorized.
- [ ] Student sees status history and notifications.
- [ ] Complaint AI triage returns advisory output.
- [ ] Staff-wide duplicate analysis can be run.
- [ ] Image complaint analysis works for uploaded images.
- [ ] AI helpdesk answers service questions without making official decisions.
- [ ] Analytics dashboard loads aggregate metrics and AI insights.

## Production controls
- [ ] Move AI processing to trusted server-side functions before institutional rollout.
- [ ] Add FCM push notifications.
- [ ] Add Firebase Emulator security-rule tests to CI.
- [ ] Configure Crashlytics/monitoring.
- [ ] Establish backup, retention and deletion policy.
- [ ] Establish confidential complaint access policy.
- [ ] Complete privacy/security review.
- [ ] Complete UAT with students and DSW staff.
