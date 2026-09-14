# Testing Plan

## Unit/widget tests
Run:

```bash
flutter test
```

Add tests for:
- request model serialization
- workflow transition validation
- AI response normalization/fallbacks
- tracking UI and status chips
- helpdesk unavailable-state handling

## Firebase Emulator integration tests
Test rules for:
- student can create/read own request
- student cannot read another student's request
- student cannot move workflow state
- staff can start review
- assignment target must be a DSW officer
- unassigned/wrong officer cannot resolve another officer's request
- director override works
- history is readable by owner/staff and not by unrelated students
- Storage ownership/MIME/size checks

## End-to-end acceptance
Use `docs/DEPLOYMENT_CHECKLIST.md` as the UAT checklist.
