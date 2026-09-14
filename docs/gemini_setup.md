# Gemini / Firebase AI Setup

## Current AI functions

Firebase AI Logic with Gemini is used for advisory features:

- request/complaint summary
- suggested priority and responsible office
- risk-tag suggestions
- duplicate-request verification
- image-based evidence description for JPG/PNG attachments
- DSW helpdesk responses
- aggregate operational analytics insights

## Human-in-the-loop rule

Gemini must never:

- approve or reject a request
- assign an officer automatically
- resolve a request automatically
- create a disciplinary or medical finding
- invent CUET policy, fees, deadlines, or eligibility rules

The app stores AI priority as a **suggestion** (`aiSuggestedPriority`) rather than allowing student-side AI processing to overwrite the operational priority.

## Firebase configuration

Enable Firebase AI Logic for the Firebase project and verify the Gemini model is available for the project/region used by the app. The current client uses `gemini-2.5-flash` through the `firebase_ai` Flutter package.

## App Check

Android debug builds use the App Check debug provider and Android release builds use Play Integrity. If App Check enforcement is enabled, a physical-device debug build must have its debug token registered in **Firebase Console → App Check → your Android app → Manage debug tokens**. Otherwise Firebase AI Logic can reject requests even though the Flutter UI is working.

The Helpdesk logs the underlying online-AI failure with `AI HELPDESK ERROR:` and automatically provides safe local service guidance when Gemini is unavailable. The priority analyzer also provides a transparent heuristic fallback so AI outages do not block operations.

Before enforcing App Check for Flutter Web, configure an approved web provider such as reCAPTCHA in Firebase and update application bootstrap accordingly.

## Production recommendation

For an institutional deployment, move AI enrichment to trusted Cloud Functions/server-side code. This centralizes abuse controls, auditability, retry behavior, throttling and privileged cross-record duplicate detection.

AI failure must never block the core DSW workflow; staff can continue processing requests manually.
