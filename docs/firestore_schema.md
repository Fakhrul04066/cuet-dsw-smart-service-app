# Firestore Schema

Below is the practical schema used by this prototype.

## users

Fields:

- uid: string
- email: string
- name: string
- studentId: string
- department: string
- level: string
- term: string
- phone: string
- role: string (`student`, `official`, `admin`)
- createdAt: timestamp
- updatedAt: timestamp

## characterCertificates

Fields:

- id: string
- trackingNumber: string
- studentUid: string
- studentId: string
- studentName: string
- department: string
- level: string
- term: string
- email: string
- phone: string
- purpose: string
- status: string
- officialNote: string
- approvedCertificateUrl: string
- createdAt: timestamp
- updatedAt: timestamp

Subcollection:

- statusHistory
  - status: string
  - note: string
  - changedBy: string
  - changedAt: timestamp

## hallTransfers

Fields:

- id: string
- trackingNumber: string
- studentUid: string
- studentId: string
- studentName: string
- currentHall: string
- preferredHall: string
- reason: string
- status: string
- officialNote: string
- evidence: array of document metadata objects (optional)
- createdAt: timestamp
- updatedAt: timestamp

Subcollection:

- statusHistory
  - status: string
  - note: string
  - changedBy: string
  - changedAt: timestamp

## complaints

Fields:

- id: string
- trackingNumber: string
- studentUid: string
- studentId: string
- category: string
- title: string
- description: string
- isConfidential: boolean
- status: string
- assignedOffice: string
- urgency: string
- resolutionNote: string
- feedback: string
- createdAt: timestamp
- updatedAt: timestamp

Subcollection:

- statusHistory
  - status: string
  - note: string
  - changedBy: string
  - changedAt: timestamp

## notifications

Fields:

- id: string
- userUid: string
- title: string
- message: string
- type: string
- referenceId: string
- isRead: boolean
- createdAt: timestamp

## auditLogs

Fields:

- actorUid: string
- actorName: string
- actorRole: string
- action: string
- entityType: string
- entityId: string
- trackingNumber: string
- details: string
- createdAt: timestamp

## Document metadata format

For uploaded documents the metadata should include:

- url: string
- publicId: string
- fileName: string
- fileType: string
- uploadedAt: timestamp or ISO string
- uploadedBy: string

This is stored in the application document or a nested metadata array, depending on the backend implementation.
