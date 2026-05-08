# 管樂人 MuKlang - Firebase App Distribution 自動發布腳本
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "[1/2] Adding 76 Android testers..."
firebase appdistribution:testers:add `
  --project wind-musician `
  --file testers.txt

Write-Host ""
Write-Host "[2/2] Distributing APK with release notes..."
$testers = (Get-Content testers.txt) -join ","
firebase appdistribution:distribute `
  build\app\outputs\flutter-apk\app-release.apk `
  --project wind-musician `
  --app 1:268061403551:android:59feb6324b5b10db3535aa `
  --release-notes-file release_notes.txt `
  --testers $testers

Write-Host ""
Write-Host "Done! 76 testers will receive the invitation email."
