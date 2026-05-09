@echo off
cd /d "%~dp0"
echo ===== MuKlang 測試提醒排程 %date% %time% =====
python send_ios_reminder.py >> reminder_log.txt 2>&1
python send_android_reminder.py >> reminder_log.txt 2>&1
echo ===== 完成 =====
