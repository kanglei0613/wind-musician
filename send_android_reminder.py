"""
查詢 Firebase App Distribution 未安裝者，發送提醒信（每人最多3次，每次間隔5天）
用法:
  python send_android_reminder.py           # 正式寄信
  python send_android_reminder.py --dry-run # 只列出名單，不寄信
"""

import smtplib, sys, json
from pathlib import Path
from datetime import date
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email_config import GMAIL_ADDRESS, GMAIL_APP_PASS, FIREBASE_LINK

TESTERS_FILE = Path(__file__).parent / "testers.txt"
TRACKING     = Path(__file__).parent / "android_reminder_log.json"
MAX_REMINDERS = 3
DRY_RUN      = "--dry-run" in sys.argv

SUBJECT = "【MuKlang】測試版邀請提醒 — Android"

PLAYSTORE_FIREBASE = "https://play.google.com/store/apps/details?id=com.google.firebase.appdistribution"

BODY_PLAIN = """\
您好 👋

我是《MuKlang》的開發者，想提醒你 Android 測試版已經開放囉！

══ 三步驟完成安裝 ══════════════════

第一步：還沒有 Firebase App Tester？先安裝它（Google Play 免費）
{playstore}

第二步：用你的 Gmail 帳號登入 Firebase App Tester

第三步：點擊下方連結，再點「Download」安裝 MuKlang
{link}

⚠ 若出現「為保護你的手機，已封鎖此類型的檔案」
→ 點「更多詳細資料」→「仍要安裝」即可，這是 Android 的正常提示。

════════════════════════════════════

只要正常使用，遇到任何問題或想法都可以透過 App 內的「問題回報」告訴我 💛
你的回饋對我真的很重要，謝謝你！🙌
""".format(link=FIREBASE_LINK, playstore=PLAYSTORE_FIREBASE)

BODY_HTML = """\
<!DOCTYPE html>
<html lang="zh-TW">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background:#f5f5f7;font-family:-apple-system,BlinkMacSystemFont,'Helvetica Neue',Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f5f5f7;padding:32px 16px;">
    <tr><td align="center">
      <table width="100%" style="max-width:520px;background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08);">

        <!-- Header -->
        <tr><td style="background:linear-gradient(135deg,#1a1a2e 0%,#16213e 100%);padding:36px 32px;text-align:center;">
          <div style="font-size:40px;margin-bottom:8px;">🎵</div>
          <h1 style="margin:0;color:#ffffff;font-size:22px;font-weight:700;letter-spacing:0.5px;">MuKlang 測試版</h1>
          <p style="margin:6px 0 0;color:#a0aec0;font-size:14px;">Android 測試版邀請提醒</p>
        </td></tr>

        <!-- Body -->
        <tr><td style="padding:32px;">
          <p style="margin:0 0 20px;color:#2d3748;font-size:16px;line-height:1.6;">您好 👋<br><br>
          我是《MuKlang》的開發者，你的測試版邀請還在等你！三個步驟完成安裝：</p>

          <!-- Step 1 -->
          <div style="background:#f7fafc;border-radius:12px;padding:20px 24px;margin-bottom:16px;border-left:4px solid #667eea;">
            <p style="margin:0 0 4px;font-size:12px;color:#718096;font-weight:600;text-transform:uppercase;letter-spacing:1px;">第一步</p>
            <p style="margin:0 0 12px;color:#2d3748;font-size:15px;font-weight:600;">還沒有 Firebase App Tester？先安裝它</p>
            <p style="margin:0 0 14px;color:#718096;font-size:13px;">Google Play 免費下載，這是接收測試版 App 的必要工具</p>
            <a href="{playstore}" style="display:inline-block;background:#01875f;color:#ffffff;text-decoration:none;padding:10px 20px;border-radius:8px;font-size:14px;font-weight:600;">
              ↗ 前往 Google Play 下載
            </a>
          </div>

          <!-- Step 2 -->
          <div style="background:#f7fafc;border-radius:12px;padding:20px 24px;margin-bottom:16px;border-left:4px solid #ed8936;">
            <p style="margin:0 0 4px;font-size:12px;color:#718096;font-weight:600;text-transform:uppercase;letter-spacing:1px;">第二步</p>
            <p style="margin:0 0 8px;color:#2d3748;font-size:15px;font-weight:600;">用你的 Gmail 帳號登入 Firebase App Tester</p>
            <p style="margin:0;color:#718096;font-size:13px;">請用收到這封信的 Gmail 帳號登入</p>
          </div>

          <!-- Step 3 -->
          <div style="background:#f7fafc;border-radius:12px;padding:20px 24px;margin-bottom:16px;border-left:4px solid #48bb78;">
            <p style="margin:0 0 4px;font-size:12px;color:#718096;font-weight:600;text-transform:uppercase;letter-spacing:1px;">第三步</p>
            <p style="margin:0 0 12px;color:#2d3748;font-size:15px;font-weight:600;">點擊連結，下載安裝 MuKlang</p>
            <p style="margin:0 0 14px;color:#718096;font-size:13px;">點下方按鈕 → 開啟 Firebase App Tester → 點「Download」</p>
            <a href="{link}" style="display:inline-block;background:linear-gradient(135deg,#667eea,#764ba2);color:#ffffff;text-decoration:none;padding:12px 28px;border-radius:8px;font-size:15px;font-weight:700;">
              📲 開啟 Android 安裝連結
            </a>
          </div>

          <!-- Warning -->
          <div style="background:#fffbeb;border-radius:10px;padding:16px 20px;margin-bottom:24px;">
            <p style="margin:0;color:#92400e;font-size:13px;line-height:1.7;">
              ⚠️ <strong>安裝時出現「為保護你的手機，已封鎖此類型的檔案」？</strong><br>
              這是正常的！點「更多詳細資料」→「仍要安裝」即可繼續。
            </p>
          </div>

          <p style="margin:0;color:#718096;font-size:14px;line-height:1.7;">
            不需要特別專業，正常使用就好。<br>
            App 內有「問題回報」功能，任何小問題或建議都非常歡迎 💛<br><br>
            謝謝你願意幫忙測試，你的回饋讓 App 變得更好 🙌
          </p>
        </td></tr>

        <!-- Footer -->
        <tr><td style="background:#f7fafc;padding:16px 32px;text-align:center;border-top:1px solid #e2e8f0;">
          <p style="margin:0;color:#a0aec0;font-size:12px;">MuKlang 開發者 kanglei</p>
        </td></tr>

      </table>
    </td></tr>
  </table>
</body>
</html>
""".format(link=FIREBASE_LINK, playstore=PLAYSTORE_FIREBASE)


def get_all_testers():
    """
    Firebase App Distribution REST API 不提供「未安裝」查詢，
    改從本地 testers.txt 讀取名單，由 log 檔控制寄信頻率與上限。
    """
    if not TESTERS_FILE.exists():
        raise FileNotFoundError(f"找不到 {TESTERS_FILE}，請確認測試者名單存在")
    emails = [line.strip() for line in TESTERS_FILE.read_text(encoding="utf-8").splitlines() if line.strip()]
    return emails

def load_log():
    if TRACKING.exists():
        return json.loads(TRACKING.read_text(encoding="utf-8"))
    return {}

def save_log(log):
    TRACKING.write_text(json.dumps(log, ensure_ascii=False, indent=2), encoding="utf-8")

def should_send(log, email):
    today = date.today().isoformat()
    rec = log.get(email, {"count": 0, "last_sent": None})
    if rec["count"] >= MAX_REMINDERS:
        return False
    if rec["last_sent"] is None:
        return True
    delta = (date.fromisoformat(today) - date.fromisoformat(rec["last_sent"])).days
    return delta >= 5

def send_email(to_email):
    msg = MIMEMultipart("alternative")
    msg["Subject"] = SUBJECT
    msg["From"]    = GMAIL_ADDRESS
    msg["To"]      = to_email
    msg.attach(MIMEText(BODY_PLAIN, "plain", "utf-8"))
    msg.attach(MIMEText(BODY_HTML,  "html",  "utf-8"))  # HTML 優先顯示
    with smtplib.SMTP_SSL("smtp.gmail.com", 465) as smtp:
        smtp.login(GMAIL_ADDRESS, GMAIL_APP_PASS)
        smtp.sendmail(GMAIL_ADDRESS, to_email, msg.as_string())

def main():
    print("查詢測試者名單...")
    all_not_installed = get_all_testers()
    log = load_log()
    today = date.today().isoformat()

    to_send = [e for e in all_not_installed if should_send(log, e)]
    skipped = len(all_not_installed) - len(to_send)

    print(f"未安裝: {len(all_not_installed)} 人 | 本次發送: {len(to_send)} 人 | 跳過(達上限或間隔不足): {skipped} 人")

    if not to_send:
        print("本次沒有需要寄信的對象。")
        return

    if DRY_RUN:
        print("[DRY RUN] 預計寄信名單：")
        for e in to_send:
            rec = log.get(e, {"count": 0})
            print(f"  {e}（第 {rec['count']+1} 次）")
        return

    success, failed = [], []
    for i, email in enumerate(to_send, 1):
        try:
            send_email(email)
            rec = log.get(email, {"count": 0, "last_sent": None})
            log[email] = {"count": rec["count"] + 1, "last_sent": today}
            success.append(email)
            print(f"[{i}/{len(to_send)}] ✅ {email}（第 {log[email]['count']} 次）")
        except Exception as ex:
            failed.append(email)
            print(f"[{i}/{len(to_send)}] ❌ {email} — {ex}")

    save_log(log)
    print(f"\n完成！成功: {len(success)}，失敗: {len(failed)}")

if __name__ == "__main__":
    main()
