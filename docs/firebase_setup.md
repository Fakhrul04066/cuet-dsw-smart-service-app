# Firebase Setup

Enable these products in the same Firebase project:

1. Firebase Authentication (Email/Password)
2. Cloud Firestore
3. Firebase Storage
4. Firebase App Check
5. Firebase AI Logic / Gemini

Deploy rules and indexes from the repository:

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage
```

Create student registry records through a trusted administrator process. Student self-registration is limited to the student role.

Create DSW staff users through a trusted process and set `/users/{uid}.role` to `dsw_officer` or `dsw_director`.

For Android release builds, register App Check with Play Integrity. For a production Flutter web staff dashboard, configure a web App Check provider/site key before enabling enforcement.
