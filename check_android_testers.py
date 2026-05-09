"""
查詢 Firebase App Distribution Android 測試者狀態
用法: python3 check_android_testers.py
"""

import json, requests
from pathlib import Path
from collections import defaultdict
import google.auth
import google.auth.transport.requests
from google.oauth2 import service_account

# ── 設定 ────────────────────────────────────────────────
SERVICE_ACCOUNT_FILE = Path(__file__).parent / "wind-musician-firebase-adminsdk-fbsvc-bc2f829d06.json"
PROJECT_NUMBER = "268061403551"   # 從 app ID 第二段取得
PROJECT_ID     = "wind-musician"
ANDROID_APP_ID = "1:268061403551:android:59feb6324b5b10db3535aa"
# ────────────────────────────────────────────────────────

SCOPES = ["https://www.googleapis.com/auth/cloud-platform"]
BASE   = "https://firebaseappdistribution.googleapis.com/v1"

def get_token():
    creds = service_account.Credentials.from_service_account_file(
        str(SERVICE_ACCOUNT_FILE), scopes=SCOPES
    )
    creds.refresh(google.auth.transport.requests.Request())
    return creds.token

def get(token, path, params=None):
    r = requests.get(
        f"{BASE}{path}",
        headers={"Authorization": f"Bearer {token}"},
        params=params or {},
    )
    r.raise_for_status()
    return r.json()

def get_latest_release(token):
    data = get(token, f"/projects/{PROJECT_NUMBER}/apps/{ANDROID_APP_ID}/releases",
               {"pageSize": 1, "orderBy": "createTime desc"})
    releases = data.get("releases", [])
    if not releases:
        raise ValueError("找不到任何 release")
    r = releases[0]
    print(f"最新 release: {r['displayVersion']} (build {r['buildVersion']}) — {r['createTime'][:10]}")
    return r["name"]  # projects/.../apps/.../releases/xxxxx

def get_testers(token, release_name):
    testers = []
    page_token = None
    while True:
        params = {"pageSize": 100}
        if page_token:
            params["pageToken"] = page_token
        data = get(token, f"/{release_name}/testers", params)
        testers.extend(data.get("testers", []))
        page_token = data.get("nextPageToken")
        if not page_token:
            break
    return testers

def main():
    token = get_token()
    print("查詢中...")

    release_name = get_latest_release(token)
    testers = get_testers(token, release_name)

    # Firebase App Distribution tester 狀態：
    # lastActivityTime 存在 → 有互動過（通常代表已安裝）
    # displayName / groups 等 metadata
    installed, invited = [], []

    for t in testers:
        email = t.get("name", "").split("/")[-1]  # name 格式: projects/.../testers/{email}
        email = t.get("testerEmail") or email
        if t.get("lastActivityTime"):
            installed.append(email)
        else:
            invited.append(email)

    total = len(testers)
    print(f"\n=== Firebase App Distribution 狀態 (共 {total} 人) ===")
    print(f"✅ 有互動/安裝 : {len(installed)} 人")
    print(f"📩 未有動作   : {len(invited)} 人")
    if total > 0:
        print(f"安裝率        : {len(installed)/total*100:.1f}%")

    if invited:
        print(f"\n--- 尚未安裝的名單（{len(invited)} 人）---")
        for e in sorted(invited):
            print(f"  {e}")

    out = Path(__file__).parent / "android_not_installed.txt"
    out.write_text("\n".join(sorted(invited)))
    print(f"\n未安裝名單已儲存至 android_not_installed.txt（共 {len(invited)} 人）")

if __name__ == "__main__":
    main()
