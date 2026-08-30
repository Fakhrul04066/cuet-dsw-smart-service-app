# Cloudinary Setup

## Purpose

Cloudinary is used to store supporting documents, hall transfer evidence, complaint attachments, and final approved certificate files.

## Supported file types

- PDF
- JPG
- JPEG
- PNG

## File constraints

Use a sensible maximum size, such as 5 MB per upload, unless the project team has a stricter requirement.

## Secure design

Do not expose the Cloudinary API secret in the Flutter app or in tracked source files.

Use one of the following patterns:

- Cloudinary signed uploads through Firebase Cloud Functions
- A backend endpoint that returns a safe upload signature or upload URL
- A server-side validation layer before metadata storage

## Metadata stored in Firestore

The file metadata should include:

- url
- publicId
- fileName
- fileType
- uploadedAt
- uploadedBy

## Prototype note

This project contains the document metadata service and safe design pattern, but the actual Cloudinary upload integration must be completed in the backend layer using Firebase Functions or a secure server environment.
