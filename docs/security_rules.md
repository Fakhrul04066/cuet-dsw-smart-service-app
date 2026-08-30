# Security Review

## Authentication

- Only authenticated users should access protected application records.
- Anonymous visitors should not be able to read application data.
- Role checks should be enforced server-side in Firestore rules or Cloud Functions.

## Authorization principles

- Students can access only records where `studentUid` matches their own UID.
- Students cannot modify official fields such as status, final decision, or assignment data.
- Officials/admins can review and update application state, but normal students cannot.
- Confidential complaints must remain restricted to authorized officials/admins.
- Audit logs must be write-protected from normal student access.

## Suggested rule pattern

Use rules that compare the authenticated user's UID to the `studentUid` on the document and restrict modification to roles such as `official` or `admin`.

## Cloudinary review

- Do not store Cloudinary secrets in Flutter code.
- Use signed upload generation or backend-generated upload URLs.
- Restrict allowed file types and file size.
- Validate file type and file size before storing metadata.

## Gemini review

- Keep the API key in backend config only.
- Do not commit the key to git.
- Add backend error handling for model failure and timeout.
- Return safe advisory output without final decision logic.

## Git hygiene

Sensitive configuration should be ignored by Git. Ensure `.env` and backend secret files are in `.gitignore`.
