# CUET DSW Smart Service App

A mobile and web-based smart service platform for the Directorate of Students' Welfare (DSW) of Chittagong University of Engineering & Technology (CUET).

The system focuses on three student services:

1. Character Certificate Application
2. Hall Transfer Application
3. Online Complaint System

## Project Objective

The goal of this project is to reduce paper-based processing, physical office visits, and repeated follow-up by providing secure and traceable digital workflows for selected DSW services.

## Main Features

### Student Application

- Student login
- Character Certificate application
- Hall Transfer application
- Complaint submission
- Application tracking
- Status history
- Notifications
- Document upload
- Approved certificate download
- Student profile

### Administrative Dashboard

Authorized officials will be able to:

- Review applications
- Request corrections
- Update application status
- Approve or reject requests
- Assign complaints
- Add resolution notes
- View reports
- View audit logs

## AI Features

The application will use Google Gemini API for:

- Form completeness checking
- Detecting unclear or inconsistent information
- Suggesting corrections
- Complaint classification
- Complaint summarization
- Urgency indication
- Responsible office recommendation

AI recommendations are advisory only.

All final decisions are made by authorized CUET officials.

## Technology Stack

### Frontend
- Flutter
- Dart
- Material 3

### Backend
- Firebase

### Database
- Cloud Firestore

### Authentication
- Firebase Authentication

### File Storage
- Cloudinary

### AI
- Google Gemini API

### Development Tools
- VS Code
- Android Studio
- Git
- GitHub
- Postman

## Current Development Status

### Completed
- Flutter project setup
- Student frontend foundation
- Splash screen
- Login screen
- Home screen
- Main navigation
- Basic reusable widgets

### Planned
- Complete student service forms
- Firebase Authentication
- Firestore integration
- Administrative dashboard
- Cloudinary integration
- Gemini AI integration
- Testing
- Documentation

## Project Structure

```text
lib/
├── main.dart
├── models/
├── screens/
├── theme/
└── widgets/
