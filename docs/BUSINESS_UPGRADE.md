# Business Upgrade Implementation

## Requested capability review

### Already present before this upgrade
- Firebase Authentication and student/staff role routing
- Character certificate workflow
- Hall transfer workflow
- Complaint submission and staff complaint management
- In-app notification collection
- Basic AI complaint classification
- Application history for legacy application types
- Firestore/Storage security rules

### Added or completed in this upgrade
- Unified business service request model
- Six service categories requested by the project scope
- Exact workflow: `SUBMITTED → UNDER_REVIEW → ASSIGNED → RESOLVED`
- Responsible-officer assignment using real `dsw_officer` user profiles
- Student request tracking with tracking numbers
- Unified request history timeline
- Firebase Storage uploads enabled for supporting documents
- Staff request queue and oversight screen
- Staff audit logging for unified workflow changes
- AI complaint priority/category/office recommendation
- AI duplicate complaint detection with staff-wide analysis
- AI multimodal image evidence analysis
- AI DSW helpdesk
- AI-assisted operational analytics dashboard
- Aggregated analytics prompt design to avoid sending personal case data to Gemini
- Notification routing for new unified service requests
- Stronger App Check release configuration on Android
- Business-oriented README and deployment guidance
- Removal of local IDE caches and JVM crash logs from the project package

## Workflow ownership

### Student
- submit request/complaint;
- upload supporting documents;
- receive tracking number;
- see current state and responsible officer;
- view request history and notifications;
- use AI helpdesk.

### DSW officer
- start review;
- examine AI advisory information;
- assign a responsible officer;
- process requests assigned to them;
- add an official resolution note;
- manage complaints and run AI duplicate/image analysis;
- view analytics.

### DSW director
- monitor all requests and complaints;
- use the unified request operations screen;
- override/resolution authority where allowed by security rules;
- view operational analytics and AI insights.

## AI human-in-the-loop rules

AI is not allowed to:
- approve or reject a student request;
- resolve a complaint;
- assign disciplinary responsibility;
- infer identity/sensitive traits from an uploaded image;
- invent CUET policy, eligibility, deadlines, fees, or official contact data.

Staff remain the decision maker.
