# Firebase Setup

## 1. Create project

1. Create a Firebase project in the Firebase Console.
2. Register an Android app and optionally a web app.
3. Download the client config files for Flutter when needed.
4. Enable Firebase Authentication.
5. Enable Cloud Firestore.
6. Optionally enable Firebase Cloud Functions for secure backend operations.

## 2. Authentication

Enable the following, depending on your implementation:

- Email/password authentication for prototype testing and local demo use
- Custom user records in Firestore with role values such as `student`, `official`, and `admin`

## 3. Firestore

Create the collections listed in the Firestore schema document:

- users
- characterCertificates
- hallTransfers
- complaints
- notifications
- auditLogs

## 4. Backend operations

Use Firebase Cloud Functions for:

- signed Cloudinary uploads
- Gemini API calls
- validation and secret management
- notification generation when needed

## 5. Secrets

Do not store keys in:

- Flutter source files
- tracked Git files
- public configuration

Keep private values in Firebase environment config or a secure backend secret store.

## 6. Local development

For local development, use a secure environment configuration and keep all secrets out of version control.
