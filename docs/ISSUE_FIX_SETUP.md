# Required Setup After the Issue-Fix Build

The Flutter code and Firebase security configuration must both be updated. Installing a new APK does **not** automatically deploy Firestore or Storage Rules.

## 1. Deploy the updated backend rules

From the project root in PowerShell:

```powershell
firebase login
firebase deploy --project cuet-dsw-smart-service --only firestore:rules,firestore:indexes,storage
```

Or run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\deploy_backend.ps1
```

This enables the unified `service_requests` module for students and DSW staff and enables Director-only student registry management.

## 2. Populate the student registry

Sign in as a DSW Director and open **Student Registry Management**. Add the real student ID, name, department, batch, hall, and Active status.

A student can create an account only after their Student ID exists under:

```text
student_registry/{studentId}
```

This is intentional institutional access control, not an open self-registration list.

## 3. AI Helpdesk

The Helpdesk now has a safe offline guidance fallback, so it no longer becomes unusable when Firebase AI Logic is unavailable.

To enable online Gemini responses as well:

1. Enable **Firebase AI Logic** for `cuet-dsw-smart-service`.
2. In Firebase Console, configure **App Check** for the Android app.
3. Debug builds use `AndroidDebugProvider`; register the debug token in Firebase App Check when enforcement is enabled.
4. Restart the app after changing App Check settings.

The terminal now prints the real AI error with prefix:

```text
AI HELPDESK ERROR:
```

This is useful for diagnosing App Check, API enablement, quota, or model-access problems.

## 4. Retest

After deploying rules and restarting the app, verify:

- Student registration after Director adds the ID
- New DSW Service Request
- Track Service Requests
- DSW Officer Request Queue
- DSW Analytics
- AI DSW Helpdesk
- Character Certificate AI Form Check

