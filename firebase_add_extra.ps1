Write-Host ""
Write-Host "Adding 8 extra testers..."
$testers = (Get-Content testers_extra.txt) -join ","
firebase appdistribution:testers:add `
  --project wind-musician `
  --file testers_extra.txt

Write-Host ""
Write-Host "Distributing release to new testers..."
firebase appdistribution:distribute `
  build\app\outputs\flutter-apk\app-release.apk `
  --project wind-musician `
  --app 1:268061403551:android:59feb6324b5b10db3535aa `
  --release-notes-file release_notes.txt `
  --testers $testers

Write-Host ""
Write-Host "Done!"
