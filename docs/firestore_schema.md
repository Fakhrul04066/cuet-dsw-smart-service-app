# Firestore Schema

## users/{uid}
Core identity/profile document. Roles used by workflow authorization: `student`, `dsw_officer`, `dsw_director`.

## service_requests/{requestId}
Key fields:
- trackingNumber
- studentUid / studentId / studentName
- requestType
- title / description
- status: SUBMITTED | UNDER_REVIEW | ASSIGNED | RESOLVED
- priority (official/operational; defaults to NORMAL)
- assignedOfficerUid / assignedOfficerName
- documents[]
- resolutionNote
- AI advisory fields: aiSummary, aiSuggestedPriority, aiPriorityReason, aiRiskTags, suggestedOffice, aiDuplicateScore, aiDuplicateRequestId, aiDuplicateReason, aiImageAssessment
- createdAt / updatedAt / resolvedAt

### service_requests/{requestId}/history/{historyId}
- status
- action
- note
- performedBy
- timestamp

## complaints/{complaintId}
Includes tracking number, student identity, category, title/description, priority, status, assignment fields, attachments and AI advisory fields for category/priority, duplicate detection and image evidence.

### complaints/{complaintId}/statusHistory/{historyId}
Status timeline for complaint processing.

## notifications/{notificationId}
- userUid
- title
- message
- type
- referenceId
- isRead
- createdAt

## audit_logs/{logId}
Immutable staff workflow audit records.

## applications / application_history
Legacy Character Certificate and Hall Transfer workflow collections retained for compatibility.
