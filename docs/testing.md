# Testing Guide

## Flutter tests

Run:

```bash
flutter test
```

## Static analysis

Run:

```bash
flutter analyze
```

## Core test coverage areas

- login form validation
- character certificate form validation
- hall transfer form validation
- complaint form validation
- workflow navigation tests
- AI advisory logic tests
- failure handling tests for Gemini/unavailable case

## Manual security checks

- student cannot access another student application
- student cannot modify official decision fields
- official/admin permissions are enforced
- confidential complaint access is restricted
- malformed file upload is rejected
- oversized upload is rejected

## Cloudinary checks

- valid PDF allowed
- valid image allowed
- invalid extension rejected
- oversized file rejected

## AI checks

- missing field detection
- unclear text detection
- complaint category suggestion
- urgency suggestion
- safe handling when service fails
