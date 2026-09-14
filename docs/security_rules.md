# Security Design

- Students can read their own service requests and complaints only.
- Staff can read operational queues.
- Students cannot promote themselves to staff roles.
- Unified request state changes are staff-only.
- Assignment targets must be valid `dsw_officer` profiles.
- An assigned request can be resolved by the assigned officer or a director.
- History and audit records are append-only from the client perspective.
- Storage validates ownership, MIME types and a 5 MB limit.
- AI output is advisory and does not authorize a workflow action.
- Android release App Check uses Play Integrity; debug builds use the debug provider.

## Production recommendation
Move AI enrichment and cross-record duplicate processing to Cloud Functions/Admin SDK before institutional rollout. That creates a trusted server boundary for AI-generated metadata and supports secure notification fan-out.
