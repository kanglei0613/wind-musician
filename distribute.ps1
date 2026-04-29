# Wind Musician - Build + Firebase App Distribution
# Usage: .\distribute.ps1 -ReleaseNote "fix bug"

param(
    [string]$ReleaseNote = "New Update"
)

$ErrorActionPreference = "Stop"

Write-Host "[BUILD] Building release APK..." -ForegroundColor Cyan
flutter build apk --release
if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] Build failed" -ForegroundColor Red; exit 1 }

$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $apkPath)) {
    Write-Host "[ERROR] APK not found" -ForegroundColor Red; exit 1
}

$sizeMB = [math]::Round((Get-Item $apkPath).length / 1MB, 1)
Write-Host "[OK] APK size: $sizeMB MB" -ForegroundColor Green

Write-Host "[UPLOAD] Uploading to Firebase App Distribution..." -ForegroundColor Cyan
firebase appdistribution:distribute $apkPath `
    --app "1:268061403551:android:35d9537c5e30b10d3535aa" `
    --groups "testers" `
    --release-notes $ReleaseNote

if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] Upload failed" -ForegroundColor Red; exit 1 }

Write-Host "[DONE] Done! Testers will receive an email notification." -ForegroundColor Green
