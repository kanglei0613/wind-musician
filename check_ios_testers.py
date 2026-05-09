"""
查詢 TestFlight 外測群組的測試者安裝狀態
用法: python3 check_ios_testers.py
"""

import jwt, time, requests
from pathlib import Path
from collections import defaultdict

# ── 設定 ────────────────────────────────────────────────
ISSUER_ID  = "c89e3779-6722-4513-976b-c87e97087da5"
KEY_ID     = "RWH3KB6P35"
KEY_FILE   = Path(__file__).parent / "AuthKey_RWH3KB6P35.p8"
GROUP_ID   = "672ec8f5-af48-4913-b2f0-f89f747ab5c4"
# ────────────────────────────────────────────────────────

BASE = "https://api.appstoreconnect.apple.com/v1"

def make_token():
    payload = {
        "iss": ISSUER_ID,
        "iat": int(time.time()),
        "exp": int(time.time()) + 1200,
        "aud": "appstoreconnect-v1",
    }
    return jwt.encode(payload, KEY_FILE.read_text(), algorithm="ES256", headers={"kid": KEY_ID})

def get_all_testers(token):
    testers = []
    url = f"{BASE}/betaGroups/{GROUP_ID}/betaTesters"
    params = {"limit": 200, "fields[betaTesters]": "email,firstName,lastName,betaStatus,inviteType"}

    while url:
        r = requests.get(url, headers={"Authorization": f"Bearer {token}"}, params=params)
        r.raise_for_status()
        data = r.json()
        testers.extend(data.get("data", []))
        url = data.get("links", {}).get("next")
        params = {}  # next url 已包含所有參數

    return testers

def main():
    token = make_token()
    print("查詢中...")
    testers = get_all_testers(token)

    # 依狀態分組
    groups = defaultdict(list)
    for t in testers:
        status = t["attributes"].get("betaStatus", "UNKNOWN")
        email  = t["attributes"].get("email", "")
        groups[status].append(email)

    total = len(testers)
    installed = groups.get("INSTALLED", [])
    accepted  = groups.get("ACCEPTED", [])
    invited   = groups.get("INVITED", [])

    print(f"\n=== TestFlight 安裝狀態 (共 {total} 人) ===")
    print(f"✅ 已安裝   : {len(installed)} 人")
    print(f"📨 已接受   : {len(accepted)} 人")
    print(f"📩 已邀請   : {len(invited)} 人（尚未行動）")
    print(f"安裝率      : {len(installed)/total*100:.1f}%")

    if invited:
        print(f"\n--- 尚未安裝的名單（{len(invited)} 人）---")
        for e in sorted(invited):
            print(f"  {e}")

    # 匯出未安裝名單
    out = Path(__file__).parent / "ios_not_installed.txt"
    not_installed = sorted(invited + accepted)
    out.write_text("\n".join(not_installed))
    print(f"\n未安裝名單已儲存至 ios_not_installed.txt（共 {len(not_installed)} 人）")

if __name__ == "__main__":
    main()
