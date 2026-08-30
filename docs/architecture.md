# Architecture

## Overview

This project is a Flutter-based student service app for CUET DSW. It supports three primary flows:

- Character Certificate
- Hall Transfer
- Student Complaint

The student app is implemented in Flutter for Android/mobile. The admin dashboard is also built in Flutter, using the same Firebase backend and Firestore collections.

## High-level flow

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
+---- Google Gemini API

Flutter Web Admin Dashboard
|
+---- same Firebase backend

## Components

### Student app

The mobile app handles:

- login and role checks
- application forms
- document upload metadata
- AI advisory checks
- complaint submission
- tracking status history
- notifications
- approved certificate download

### Admin dashboard

The web dashboard handles:

- request review
- status changes
- correction requests
- complaint assignment
- reporting and audit logs

### Firebase backend

Firebase provides:

- Authentication
- Firestore persistence
- role-based access patterns
- audit log collection
- optional Cloud Functions for privileged operations

### Cloudinary

Cloudinary is used for document storage, with the actual upload signed or generated server-side. The Flutter app stores metadata such as URL, public ID, name, type, uploadedAt, and uploader.

### Gemini API

Gemini is used only as an advisory assistant. It can suggest missing fields, summarize issues, recommend urgency, or suggest office assignment, but it never decides outcomes for the student or official workflows.

## Design principles

- AI is advisory only
- Secrets remain server-side
- Students access only their own records
- Officials/admin enforce application review
- Confidential complaints remain restricted
- Audit logs keep a record of status and assignment changes
