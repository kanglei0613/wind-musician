"""
自動把 ios_emails.txt 裡的 email 加進 TestFlight 外測群組
用法: python3 add_testers.py
"""

import jwt, time, requests, json
from pathlib import Path

# ── 設定 ────────────────────────────────────────────────
ISSUER_ID  = "c89e3779-6722-4513-976b-c87e97087da5"
KEY_ID     = "RWH3KB6P35"
KEY_FILE   = Path(__file__).parent / "AuthKey_RWH3KB6P35.p8"
EMAIL_FILE = Path(__file__).parent / "ios_emails.txt"
BUNDLE_ID  = "com.kanglei.muklang"
# ────────────────────────────────────────────────────────

BASE = "https://api.appstoreconnect.apple.com/v1"

def make_token():
    key = KEY_FILE.read_text()
    payload = {
        "iss": ISSUER_ID,
        "iat": int(time.time()),
        "exp": int(time.time()) + 1200,
        "aud": "appstoreconnect-v1",
    }
    return jwt.encode(payload, key, algorithm="ES256", headers={"kid": KEY_ID})

def get(token, path):
    r = requests.get(f"{BASE}{path}", headers={"Authorization": f"Bearer {token}"})
    r.raise_for_status()
    return r.json()

def post(token, path, body):
    r = requests.post(
        f"{BASE}{path}",
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
        json=body,
    )
    return r

def find_app(token):
    data = get(token, "/apps")
    for app in data["data"]:
        if app["attributes"]["bundleId"] == BUNDLE_ID:
            return app["id"]
    raise ValueError(f"找不到 bundleId={BUNDLE_ID} 的 App")

def find_external_group(token, app_id):
    data = get(token, f"/apps/{app_id}/betaGroups")
    external = [g for g in data["data"] if not g["attributes"]["isInternalGroup"]]
    if not external:
        raise ValueError("找不到外部測試群組")
    if len(external) == 1:
        return external[0]["id"], external[0]["attributes"]["name"]
    # 多個群組時列出選擇
    print("找到多個外部群組：")
    for i, g in enumerate(external):
        print(f"  [{i}] {g['attributes']['name']} ({g['id']})")
    idx = int(input("請選擇群組編號: "))
    return external[idx]["id"], external[idx]["attributes"]["name"]

def get_tester_id_by_email(token, email, app_id):
    r = requests.get(
        f"{BASE}/betaTesters",
        headers={"Authorization": f"Bearer {token}"},
        params={"filter[email]": email, "filter[apps]": app_id},
    )
    if r.status_code == 200:
        data = r.json().get("data", [])
        if data:
            return data[0]["id"]
    return None

def add_tester(token, email, group_id, app_id):
    # 先查是否已存在
    existing_id = get_tester_id_by_email(token, email, app_id)
    if existing_id:
        return existing_id, "existing"

    # 建立 tester 並直接加入 betaGroup
    body = {
        "data": {
            "type": "betaTesters",
            "attributes": {"email": email},
            "relationships": {
                "betaGroups": {
                    "data": [{"type": "betaGroups", "id": group_id}]
                }
            }
        }
    }
    r = post(token, "/betaTesters", body)
    if r.status_code in (200, 201):
        return r.json()["data"]["id"], "created"

    # 409 → 已存在，不帶 app filter 再查一次
    if r.status_code == 409:
        r2 = requests.get(
            f"{BASE}/betaTesters",
            headers={"Authorization": f"Bearer {token}"},
            params={"filter[email]": email},
        )
        if r2.status_code == 200:
            data = r2.json().get("data", [])
            if data:
                return data[0]["id"], "existing"

    return None, f"error {r.status_code}: {r.text[:120]}"

def add_to_group(token, group_id, tester_ids):
    body = {
        "data": [{"type": "betaTesters", "id": tid} for tid in tester_ids]
    }
    r = post(token, f"/betaGroups/{group_id}/relationships/betaTesters", body)
    return r.status_code in (200, 201, 204)

def main():
    emails = [e.strip() for e in EMAIL_FILE.read_text().splitlines() if e.strip()]
    print(f"共 {len(emails)} 筆 email")

    token = make_token()
    app_id = find_app(token)
    print(f"App ID: {app_id}")

    group_id, group_name = find_external_group(token, app_id)
    print(f"目標群組: {group_name} ({group_id})")

    success, skipped, failed = [], [], []

    for i, email in enumerate(emails, 1):
        # 每 15 分鐘刷新一次 token
        if i % 200 == 0:
            token = make_token()

        tester_id, status = add_tester(token, email, group_id, app_id)
        if tester_id:
            success.append(tester_id)
            print(f"[{i}/{len(emails)}] {email} — {status}")
        else:
            failed.append(email)
            print(f"[{i}/{len(emails)}] {email} — ❌ {status}")

    # 批次加入群組（每批 100 筆）
    print(f"\n將 {len(success)} 人加入群組...")
    batch_size = 100
    for i in range(0, len(success), batch_size):
        batch = success[i:i+batch_size]
        ok = add_to_group(token, group_id, batch)
        print(f"  批次 {i//batch_size + 1}: {'✅' if ok else '❌'}")

    print(f"\n完成！成功: {len(success)}，失敗: {len(failed)}")
    if failed:
        print("失敗的 email:")
        for e in failed:
            print(f"  {e}")

if __name__ == "__main__":
    main()
