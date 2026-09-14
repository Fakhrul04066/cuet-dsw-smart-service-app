$ErrorActionPreference = 'Stop'

Write-Host 'CUET DSW backend deployment' -ForegroundColor Cyan

if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
  Write-Host 'Firebase CLI is not installed.' -ForegroundColor Yellow
  Write-Host 'Run: npm install -g firebase-tools'
  exit 1
}

Write-Host 'Using Firebase project: cuet-dsw-smart-service'
Write-Host 'If Firebase asks you to sign in, run firebase login first.' -ForegroundColor Yellow

firebase deploy --project cuet-dsw-smart-service --only firestore:rules,firestore:indexes,storage

if ($LASTEXITCODE -ne 0) {
  throw 'Firebase deployment failed. Review the output above.'
}

Write-Host 'Backend rules/indexes/storage rules deployed successfully.' -ForegroundColor Green
Write-Host 'Restart the Flutter app and sign in again before retesting protected modules.'
