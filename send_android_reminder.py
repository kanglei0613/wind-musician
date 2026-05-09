"""
查詢 Firebase App Distribution 未安裝者，發送提醒信（每人最多3次，每次間隔5天）
用法:
  python send_android_reminder.py           # 正式寄信
  python send_android_reminder.py --dry-run # 只列出名單，不寄信
"""

import requests, smtplib, sys, json
from pathlib import Path
from datetime import date
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from google.oauth2 import service_account
import google.auth.transport.requests
from email_config import GMAIL_ADDRESS, GMAIL_APP_PASS, FIREBASE_LINK

SERVICE_ACCOUNT_FILE = Path(__file__).parent / "wind-musician-firebase-adminsdk-fbsvc-bc2f829d06.json"
PROJECT_NUMBER  = "268061403551"
ANDROID_APP_ID  = "1:268061403551:android:59feb6324b5b10db3535aa"
BASE            = "https://firebaseappdistribution.googleapis.com/v1"
TRACKING        = Path(__file__).parent / "android_reminder_log.json"
MAX_REMINDERS   = 3
DRY_RUN         = "--dry-run" in sys.argv

SUBJECT = "【MuKlang】測試版邀請提醒 — Android"

BODY = """\
您好 👋

我是《MuKlang》的開發者，想提醒你 Android 測試版已經開放囉！

如果你還沒安裝，麻煩依以下步驟體驗看看 🙏

══ Android 安裝步驟 ═══════════════
1. 安裝 Firebase App Tester（Google Play 免費下載）
2. 用你的 Gmail 帳號登入
3. 點擊下方連結，再點「Download」安裝：

   {link}

安裝時若出現「為保護你的手機，已封鎖此類型的檔案」
→ 點「更多詳細資料」→「仍要安裝」即可。
══════════════════════════════════

這次測試主要希望確認：
  • 功能操作是否順暢
  • 有沒有閃退或異常
  • 使用上是否直覺
  • 不同手機上的穩定度

不需要特別專業，只要正常使用、隨手回饋感受就對我幫助很大了！
App 內有「問題回報」功能，任何小問題或建議都非常歡迎 💛

真的很感謝你願意幫忙測試，有你們的回饋能讓 App 變得更好 🙌
""".format(link=FIREBASE_LINK)


def get_token():
    creds = service_account.Credentials.from_service_account_file(
        str(SERVICE_ACCOUNT_FILE),
        scopes=["https://www.googleapis.com/auth/cloud-platform"]
    )
    creds.refresh(google.auth.transport.requests.Request())
    return creds.token

def get_latest_release(token):
    r = requests.get(
        f"{BASE}/projects/{PROJECT_NUMBER}/apps/{ANDROID_APP_ID}/releases",
        headers={"Authorization": f"Bearer {token}"},
        params={"pageSize": 1, "orderBy": "createTime desc"},
    )
    r.raise_for_status()
    releases = r.json().get("releases", [])
    if not releases:
        raise ValueError("找不到任何 release")
    return releases[0]["name"]

def get_not_installed(token, release_name):
    not_installed = []
    page_token = None
    while True:
        params = {"pageSize": 100}
        if page_token:
            params["pageToken"] = page_token
        r = requests.get(
            f"{BASE}/{release_name}/testers",
            headers={"Authorization": f"Bearer {token}"},
            params=params,
        )
        r.raise_for_status()
        data = r.json()
        for t in data.get("testers", []):
            if not t.get("lastActivityTime"):
                email = t.get("testerEmail") or t.get("name", "").split("/")[-1]
                not_installed.append(email)
        page_token = data.get("nextPageToken")
        if not page_token:
            break
    return not_installed

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
    msg.attach(MIMEText(BODY, "plain", "utf-8"))
    with smtplib.SMTP_SSL("smtp.gmail.com", 465) as smtp:
        smtp.login(GMAIL_ADDRESS, GMAIL_APP_PASS)
        smtp.sendmail(GMAIL_ADDRESS, to_email, msg.as_string())

def main():
    token = get_token()
    release_name = get_latest_release(token)
    print("查詢未安裝名單...")
    all_not_installed = get_not_installed(token, release_name)
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
