"""
查詢 TestFlight 未安裝者，發送提醒信（每人最多3次，每次間隔5天）
用法:
  python send_ios_reminder.py           # 正式寄信
  python send_ios_reminder.py --dry-run # 只列出名單，不寄信
"""

import jwt, time, requests, smtplib, sys, json
from pathlib import Path
from datetime import date, datetime
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email_config import GMAIL_ADDRESS, GMAIL_APP_PASS, TESTFLIGHT_LINK

ISSUER_ID    = "c89e3779-6722-4513-976b-c87e97087da5"
KEY_ID       = "RWH3KB6P35"
KEY_FILE     = Path(__file__).parent / "AuthKey_RWH3KB6P35.p8"
GROUP_ID     = "672ec8f5-af48-4913-b2f0-f89f747ab5c4"
BASE         = "https://api.appstoreconnect.apple.com/v1"
TRACKING     = Path(__file__).parent / "ios_reminder_log.json"
MAX_REMINDERS = 3
DRY_RUN      = "--dry-run" in sys.argv

SUBJECT = "【MuKlang】測試版邀請提醒 — iOS"

APPSTORE_TESTFLIGHT = "https://apps.apple.com/app/testflight/id899247664"

BODY_PLAIN = """\
您好 👋

我是《MuKlang》的開發者，想提醒你 iOS 測試版已經開放囉！

══ 兩步驟完成安裝 ══════════════════

第一步：還沒有 TestFlight？先安裝它（App Store 免費）
{appstore}

第二步：點擊邀請連結，在 TestFlight 中點「接受」→「安裝」
{link}

════════════════════════════════════

只要正常使用，遇到任何問題或想法都可以透過 App 內的「問題回報」告訴我 💛
你的回饋對我真的很重要，謝謝你！🙌
""".format(link=TESTFLIGHT_LINK, appstore=APPSTORE_TESTFLIGHT)

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
          <p style="margin:6px 0 0;color:#a0aec0;font-size:14px;">iOS TestFlight 邀請提醒</p>
        </td></tr>

        <!-- Body -->
        <tr><td style="padding:32px;">
          <p style="margin:0 0 20px;color:#2d3748;font-size:16px;line-height:1.6;">您好 👋<br><br>
          我是《MuKlang》的開發者，你的測試版邀請還在等你！只需兩個步驟就能安裝：</p>

          <!-- Step 1 -->
          <div style="background:#f7fafc;border-radius:12px;padding:20px 24px;margin-bottom:16px;border-left:4px solid #667eea;">
            <p style="margin:0 0 4px;font-size:12px;color:#718096;font-weight:600;text-transform:uppercase;letter-spacing:1px;">第一步</p>
            <p style="margin:0 0 12px;color:#2d3748;font-size:15px;font-weight:600;">還沒有 TestFlight？先安裝它</p>
            <p style="margin:0 0 14px;color:#718096;font-size:13px;">App Store 免費下載，不到一分鐘</p>
            <a href="{appstore}" style="display:inline-block;background:#000000;color:#ffffff;text-decoration:none;padding:10px 20px;border-radius:8px;font-size:14px;font-weight:600;">
              ↗ 前往 App Store 下載 TestFlight
            </a>
          </div>

          <!-- Step 2 -->
          <div style="background:#f7fafc;border-radius:12px;padding:20px 24px;margin-bottom:28px;border-left:4px solid #48bb78;">
            <p style="margin:0 0 4px;font-size:12px;color:#718096;font-weight:600;text-transform:uppercase;letter-spacing:1px;">第二步</p>
            <p style="margin:0 0 12px;color:#2d3748;font-size:15px;font-weight:600;">點擊邀請連結，接受並安裝</p>
            <p style="margin:0 0 14px;color:#718096;font-size:13px;">點下方按鈕 → 在 TestFlight 中點「接受」→「安裝」，完成！</p>
            <a href="{link}" style="display:inline-block;background:linear-gradient(135deg,#667eea,#764ba2);color:#ffffff;text-decoration:none;padding:12px 28px;border-radius:8px;font-size:15px;font-weight:700;">
              📲 開啟 TestFlight 邀請連結
            </a>
          </div>

          <!-- Note -->
          <div style="background:#fffbeb;border-radius:10px;padding:16px 20px;margin-bottom:24px;">
            <p style="margin:0;color:#92400e;font-size:13px;line-height:1.6;">
              💡 <strong>已有 TestFlight？</strong>直接點第二步的按鈕就好，不需要重新安裝。
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
""".format(link=TESTFLIGHT_LINK, appstore=APPSTORE_TESTFLIGHT)


def make_token():
    payload = {
        "iss": ISSUER_ID,
        "iat": int(time.time()),
        "exp": int(time.time()) + 1200,
        "aud": "appstoreconnect-v1",
    }
    return jwt.encode(payload, KEY_FILE.read_text(), algorithm="ES256", headers={"kid": KEY_ID})

def get_not_installed(token):
    """
    取得群組內所有測試者的 email。
    Apple API 的 betaStatus 不支援從 betaGroups 端點查詢，
    改為取全部測試者，讓 log 機制控制寄信頻率與上限。
    """
    emails = []
    url = f"{BASE}/betaGroups/{GROUP_ID}/betaTesters"
    params = {"limit": 200, "fields[betaTesters]": "email"}
    while url:
        r = requests.get(url, headers={"Authorization": f"Bearer {token}"}, params=params)
        r.raise_for_status()
        data = r.json()
        for t in data.get("data", []):
            email = t["attributes"].get("email")
            if email:
                emails.append(email)
        url = data.get("links", {}).get("next")
        params = {}
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
    token = make_token()
    print("查詢未安裝名單...")
    all_not_installed = get_not_installed(token)
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
