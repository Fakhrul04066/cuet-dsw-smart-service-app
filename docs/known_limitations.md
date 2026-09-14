# Known Limitations

The application now implements the requested business workflow and AI-assisted modules, but these items should be completed before an institutional production launch:

1. AI calls currently originate from the authenticated Flutter client. For stronger trust boundaries, move AI enrichment/duplicate analysis to Cloud Functions or another trusted backend.
2. Notifications are stored and displayed in Firestore; FCM push delivery is not yet included.
3. Web App Check requires a deployed web provider/site key if the Flutter web dashboard is used in production.
4. Analytics uses current Firestore records and does not yet provide configurable date ranges, exports, or scheduled reports.
5. No formal CUET retention/privacy policy is encoded; institutional policy owners must define those requirements.
6. Legacy specialized Character Certificate and Hall Transfer workflows coexist with the new unified service-request workflow and can be migrated later.
7. Automated integration tests require a Flutter/Firebase Emulator environment and should be added to CI before release.
