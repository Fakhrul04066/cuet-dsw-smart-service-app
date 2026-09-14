# Architecture

## Client applications

```text
Student Flutter App / Staff Flutter Workspace
                 |
                 +--> Firebase Authentication
                 |
                 +--> Cloud Firestore
                 |      +-- users
                 |      +-- service_requests/history
                 |      +-- complaints/statusHistory
                 |      +-- applications/application_history (legacy)
                 |      +-- notifications
                 |      +-- audit_logs
                 |
                 +--> Firebase Storage
                 |      +-- service request documents
                 |      +-- complaint evidence
                 |      +-- legacy application documents
                 |
                 +--> Firebase AI Logic (Gemini)
                        +-- triage / priority suggestions
                        +-- duplicate assessment
                        +-- image evidence description
                        +-- helpdesk
                        +-- aggregated management insights
```

## Business workflow

Unified service requests use one predictable state machine:

`SUBMITTED → UNDER_REVIEW → ASSIGNED → RESOLVED`

- Students create requests.
- Staff starts review.
- A request is assigned only to a user whose role is `dsw_officer`.
- The assigned officer, or an authorized director, records the resolution.
- Every transition creates a history item and notification.
- Staff transitions are also written to `audit_logs`.

## Trust boundaries

Firestore and Storage Rules are the primary authorization boundary. AI output is advisory and has no authority to move workflow state. For institutional production, AI processing should be moved from the Flutter client to trusted server-side functions so that advisory metadata cannot be forged by a modified client.
