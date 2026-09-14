# Issues Fixed From Physical-Device Testing

This repair pass addresses the issues reported from the Android physical-device screenshots.

## UI / form fixes

- Fixed request-type dropdown `RenderFlex overflow` on narrow Android screens by making the dropdown expanded and truncating long selected labels safely.
- Fixed the Character Certificate / Hall Transfer form-check dialog so it no longer shows contradictory or duplicated suggestion headings.
- Local form checking now reports “review the items above” when a field is unclear instead of simultaneously claiming that no major issue was detected.

## Firestore permission failures

The app already contained the new `service_requests` client module, but a new APK cannot update Firebase security rules. The updated `firestore.rules` now includes the business workflow and Director registry management, plus compatibility for legacy staff role labels.

The student tracking, officer queue and analytics screens now show a useful backend-setup message instead of exposing a raw `PERMISSION_DENIED` exception.

Deployment remains mandatory:

```powershell
firebase deploy --project cuet-dsw-smart-service --only firestore:rules,firestore:indexes,storage
```

## Student registration / registry

- Added **Student Registry Management** to the DSW Director dashboard.
- Director can add/update Student ID, name, department, batch, hall and active status.
- Student registration gives an actionable message when the ID is not yet in the registry.
- Registry writes remain protected from students and officers.

## AI Helpdesk

- Online Firebase AI / Gemini is still attempted first.
- Actual failures are logged with `AI HELPDESK ERROR:` for diagnosis.
- If Firebase AI Logic, App Check, quota or connectivity is unavailable, the Helpdesk now provides safe local DSW guidance instead of becoming unusable.
- The fallback never invents official CUET policy, fees, deadlines or decisions.

## AI request triage / analytics resilience

- Request priority analysis now has an advisory keyword-based fallback if online Gemini is unavailable.
- Analytics now has local operational insights if Gemini insight generation fails.
- Image analysis remains online-AI dependent because image interpretation cannot be safely replaced by a text-only fallback.

## Firestore indexes

Added a composite index for request type + student UID to support duplicate/request-history analysis efficiently.

## v3 navigation lifecycle fix

A debug-only red screen could appear with Flutter's framework assertion `_dependents.isEmpty` during login/logout or route replacement. The application had two independent navigation mechanisms reacting to the same Firebase authentication event: `AuthGate` rebuilt automatically from `authStateChanges`, while login/logout handlers also called `pushAndRemoveUntil`. The duplicated route-tree replacement could deactivate inherited widgets while descendants were still being torn down.

The v3 fix makes `AuthGate` the single owner of authentication navigation. Login now only signs in; dashboard logout buttons only sign out; the AuthGate switches between Login and the correct role dashboard. Profile logout returns to the root route and then signs out. This removes the competing route replacements.
