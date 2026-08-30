# Gemini Setup

## Purpose

Google Gemini is used for advisory support only in this project. It helps with:

- checking missing form fields
- flagging unclear statements
- identifying possible inconsistencies
- categorizing complaint content
- suggesting urgency and responsible office
- summarizing complaint issues

## Important rule

Gemini is not allowed to:

- approve applications
- reject applications
- make final decisions
- resolve complaints automatically
- assign complaints without official confirmation

## Secure backend usage

The API key must live in Firebase environment config or a secure backend service. It must never be embedded in Flutter code or committed to Git.

## Recommended backend pattern

- Cloud Function receives form/complaint data
- Function calls Gemini
- Function returns a structured JSON payload
- Flutter app shows the result as advisory only

## Failure handling

The UI must gracefully handle Gemini failures and continue with manual input. The app should display:

AI assistance is currently unavailable. You may continue manually.
