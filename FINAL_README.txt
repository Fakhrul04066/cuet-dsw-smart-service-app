CUET DSW SMART SERVICE - FINAL HANDOFF
======================================

IMPORTANT
---------
This copy contains source-code fixes plus the local Character Certificate PDF feature.
Before testing, you MUST fetch the new PDF packages and deploy the included Firestore rules.
The old deployed rules can continue showing permission-denied until you deploy firestore.rules.

1) FIRST COMMANDS ON WINDOWS
----------------------------
Open PowerShell in the extracted project folder and run:

flutter pub get
flutter analyze
firebase deploy --only firestore:rules --project cuet-dsw-smart-service
flutter run -d A7UH025829000885

If flutter analyze or the Firebase deploy command prints an error, stop and keep the exact terminal output.

2) MAIN FIXES IN THIS COPY
--------------------------
- Staff application writes are now narrow status/comment updates instead of rewriting the full application document.
- Firestore rules now validate the actual workflow transitions for student, officer and director.
- Legacy demo applications without studentUid can still be processed by staff without staff adding/changing a UID.
- Officer REJECTED transition is allowed only from OFFICER_REVIEW.
- Director workflow is OFFICER_APPROVED -> DIRECTOR_REVIEW -> APPROVED/REJECTED.
- Character Certificate issuance is APPROVED -> CERTIFICATE_ISSUED.
- Student correction resubmits the SAME application ID and returns it to OFFICER_REVIEW.
- Officer waits while status is CORRECTION_REQUIRED; the student must resubmit first.
- Application history and audit-log writes remain part of authority actions.
- Notification failure is treated as secondary and does not make an already-successful authoritative transition look failed.
- My Complaints uses a studentId-only Firestore query and sorts locally, avoiding the unnecessary composite-index dependency.
- Application history also sorts locally instead of requiring a composite query.
- Staff role normalization bug for DSW Director aliases was corrected.
- Student Dashboard remains organized as:
  Services: Character Certificate, Hall Transfer
  Personal Activity: My Applications, Online Complaint, My Complaints, Notifications
- Hall Transfer rows now show current hall -> requested hall instead of a blank purpose.
- Correction/rejection reasons remain visible to the student.

3) CHARACTER CERTIFICATE PDF
----------------------------
New local PDF support was added using:
- pdf
- printing

No Firebase Storage is used for the certificate PDF.

Flow:
Director APPROVES Character Certificate
-> application becomes APPROVED
-> Director chooses Issue Certificate
-> application becomes CERTIFICATE_ISSUED
-> student opens My Applications -> Character Certificate -> Application Details
-> View Certificate / Download PDF actions appear only for the owning student

PDF contains:
- CUET heading
- Directorate of Students Welfare
- Character Certificate title
- Student name
- Student ID
- Department
- Batch
- Hall
- Purpose
- Application/reference ID
- Issue date
- Director, Students Welfare signature area

Suggested/generated filename:
CUET_Character_Certificate_<studentId>_<applicationId>.pdf

The Download PDF button invokes the device save/share flow for the generated PDF.

4) PHYSICAL DEVICE TEST - DO THIS IN THIS ORDER
------------------------------------------------
A. STUDENT / COMPLAINT
1. Login as a student.
2. Open Personal Activity -> My Complaints.
3. Existing own complaints should load.
4. Confirm no other student's complaint is visible.
5. Submit a new Online Complaint and confirm it appears in My Complaints.

B. CHARACTER CERTIFICATE - CORRECTION FLOW
1. Student submits a new Character Certificate.
2. Confirm it appears in My Applications with status SUBMITTED.
3. Officer opens Character Certificate tab and presses Start review.
4. Confirm status becomes OFFICER_REVIEW without permission-denied.
5. Officer chooses Request correction and enters a REQUIRED reason.
6. Student opens the SAME application in My Applications.
7. Confirm the correction reason is visible.
8. Student chooses Correct and Resubmit.
9. Confirm the SAME application ID is kept and status returns to OFFICER_REVIEW.
10. Officer approves it.
11. Confirm status becomes OFFICER_APPROVED.

C. CHARACTER CERTIFICATE - DIRECTOR + PDF
1. Director opens Character Certificate tab.
2. Officer-approved application must be visible.
3. Press Start review -> DIRECTOR_REVIEW.
4. Press Approve -> APPROVED.
5. The same certificate remains available to Director with Issue Certificate.
6. Press Issue Certificate -> CERTIFICATE_ISSUED.
7. Student opens My Applications -> that application.
8. Verify View Certificate works.
9. Verify Download PDF opens the Android save/share flow.
10. Verify SUBMITTED/REJECTED/review-stage certificates do NOT expose certificate actions.

D. CHARACTER CERTIFICATE - REJECTION
1. Use another application.
2. Move it through Officer approval and Director review.
3. Director Reject must require a reason.
4. Student must see the Director rejection reason.

E. HALL TRANSFER
1. Student submits Hall Transfer.
2. Officer Start review -> OFFICER_REVIEW.
3. Test Request correction with required reason.
4. Student corrects current hall/requested hall/reason and resubmits the SAME ID.
5. Officer approves -> OFFICER_APPROVED.
6. Director Start review -> DIRECTOR_REVIEW.
7. Test final APPROVED on one request.
8. Test REJECTED + required reason on another request.
9. Student must see the final status/reason.

5) FIREBASE STORAGE LIMITATION
------------------------------
Firebase Storage uploads remain intentionally disabled in this demo project because enabling the project's Storage setup requires billing for the chosen Firebase configuration. Do not enable billing just for this course demo unless your instructor explicitly requires it.

The UI should show that file upload is unavailable in the demo version. The local certificate PDF feature does NOT require Firebase Storage.

6) NOT INCLUDED / OPTIONAL
--------------------------
- FCM push notifications were not made mandatory for this final stabilization pass.
- QR certificate verification is not included in this pass.
- Existing in-app Firestore notifications remain.
- Existing Gemini complaint suggestion logic remains and was intentionally not refactored.

7) IF PERMISSION-DENIED STILL APPEARS
-------------------------------------
First confirm that this exact command completed successfully AFTER extracting this final project:

firebase deploy --only firestore:rules --project cuet-dsw-smart-service

Then reproduce ONE action while flutter run is open and keep the terminal lines beginning with:
DIRECTOR_
CHANGE_STATUS_

Do not loosen the Firestore rules with allow read, write: if true.

8) SECURITY
-----------
No Firebase Admin/service-account private JSON is included in this package.
Keep any service-account key only on your own machine and never commit it to GitHub.

============================================================
V3 PRODUCT/UX UPDATES
============================================================
1. Formal business-style global theme: neutral institutional background,
   white surfaces, navy accents, restrained borders/radius.
2. Approved Hall Transfer automatically updates the student's hall in
   users/{uid}.hall after the Director approves the request.
3. Student Profile now uses live Firestore data and lets the student add,
   edit, or clear an optional mobile number. Institutional fields remain
   read-only.
4. Student Dashboard no longer contains a Notifications activity card.
   Notifications remain available from the top-right bell icon and badge.
5. Officer/Director user-facing workflow uses "Processing" wording rather
   than "Review". Approve/reject/correction decisions use an Official Note.
   Internal OFFICER_REVIEW/DIRECTOR_REVIEW status values are intentionally
   retained for database/workflow compatibility.
6. Character Certificate phone number is optional and validated only when
   supplied.

IMPORTANT FIRESTORE RULE CHANGE
Deploy the included firestore.rules before testing profile editing or
approved hall-transfer profile updates:

firebase deploy --only firestore:rules --project cuet-dsw-smart-service

V3 TEST CHECKLIST
- Student Dashboard: no Notifications card; bell icon remains.
- Student profile: edit mobile number, save, reopen profile, verify value.
- Student profile: clear mobile number and save (optional field).
- Officer: Start processing -> approve/reject/correction using Official Note.
- Director: Start processing -> approve/reject using Official Note.
- Hall Transfer: Director approves -> sign in as that student -> Hall value
  in dashboard/profile must equal requested hall.
- Character Certificate: leave phone blank and verify submission is allowed.
