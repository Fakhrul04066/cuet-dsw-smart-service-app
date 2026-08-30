# CUET DSW Smart Service App

## Project

Digitize the CUET Directorate of Students' Welfare service flows for:

- Character Certificate
- Hall Transfer
- Student Complaint

## Purpose

This prototype provides a Flutter mobile app for students and a Flutter web dashboard for officials/admins to manage requests, apply AI-assisted advisory checks, and review status changes in a controlled human-in-the-loop workflow.

## Tech stack

### Frontend

- Flutter / Dart

### Backend

- Firebase

### Database

- Cloud Firestore

### Authentication

- Firebase Authentication

### Storage

- Cloudinary

### AI

- Google Gemini API

### Tools

- Android Studio
- VS Code
- Git
- GitHub
- Postman

## Architecture

Student Flutter App
|
v
Firebase Authentication
|
v
Cloud Firestore
|
+---- Cloudinary
|
+---- Firebase Functions
|
+---- Gemini API

Flutter Web Admin Dashboard
|
+---- same Firebase backend

## Scope status

This project includes the required prototype flows for:

- student application forms
- status tracking and history
- notifications
- complaint triage suggestion
- form completeness checks
- secure design patterns for API usage
- admin dashboard review flow
- documentation and demo preparation

Important: Gemini and Cloudinary integrations must be completed through backend services with environment-based secrets. AI is advisory only and does not make official decisions.

## Documentation

All project documentation is under the docs/ folder:

- architecture.md
- firebase_setup.md
- firestore_schema.md
- security_rules.md
- cloudinary_setup.md
- gemini_setup.md
- testing.md
- student_manual.md
- admin_manual.md
- demo_guide.md
- known_limitations.md

## Quick start

```bash
flutter pub get
flutter run
```

For the admin dashboard:

```bash
flutter pub get
flutter run -d chrome
```

## Security note

Never commit secrets, API keys, or backend configuration values to the repository. Keep them in protected Firebase environment configuration or secure server-side secret storage.

## Known limitations

- This is a prototype, not a full production deployment.
- Gemini recommendations are probabilistic and advisory only.
- Real Cloudinary and Gemini backend integration requires a configured Firebase backend.
- FCM is optional and not required for the current prototype.

See docs/known_limitations.md for the complete limitation list.
