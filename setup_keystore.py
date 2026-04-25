#!/usr/bin/env python3
"""
Wind Musician - Release Keystore Setup
Run this from the wind_musician project folder (where pubspec.yaml is).
"""
import os, sys, subprocess, textwrap

# ── paths ──────────────────────────────────────────────────────────────────
PROJECT_DIR   = os.getcwd()
ANDROID_DIR   = os.path.join(PROJECT_DIR, "android")
APP_DIR       = os.path.join(ANDROID_DIR, "app")
KEYSTORE_PATH = os.path.join(ANDROID_DIR, "upload-keystore.jks")
KEY_PROPS     = os.path.join(ANDROID_DIR, "key.properties")
BUILD_GRADLE  = os.path.join(APP_DIR, "build.gradle.kts")

KEYTOOL = r"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"

# ── helpers ─────────────────────────────────────────────────────────────────
def banner(msg):
    print(f"\n{'='*60}\n  {msg}\n{'='*60}")

def ask(prompt, default=None):
    suffix = f" [{default}]" if default else ""
    val = input(f"{prompt}{suffix}: ").strip()
    return val if val else default

# ── step 1: generate keystore ────────────────────────────────────────────────
banner("步驟 1 / 4  產生 Release Keystore")

if os.path.exists(KEYSTORE_PATH):
    print(f"⚠  已存在 {KEYSTORE_PATH}")
    skip = ask("跳過產生（直接使用現有的）？[y/n]", "y")
    generate = skip.lower() != "y"
else:
    generate = True

if generate:
    print("\n請輸入 Keystore 相關資訊（輸入後請記下來，遺失無法復原）\n")
    store_pass  = ask("Keystore 密碼（至少 6 字元）")
    key_alias   = ask("Key alias（識別名稱）", "upload")
    key_pass    = ask("Key 密碼（至少 6 字元，可與 Keystore 密碼相同）", store_pass)
    dname_cn    = ask("您的姓名", "Wind Musician")
    dname_o     = ask("組織名稱", "KangLei")
    dname_c     = ask("國家代碼（2 碼）", "TW")

    cmd = [
        KEYTOOL,
        "-genkey", "-v",
        "-keystore", KEYSTORE_PATH,
        "-alias", key_alias,
        "-keyalg", "RSA",
        "-keysize", "2048",
        "-validity", "10000",
        "-storepass", store_pass,
        "-keypass", key_pass,
        "-dname", f"CN={dname_cn}, O={dname_o}, C={dname_c}",
    ]

    print("\n正在產生 keystore...")
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print("❌ 產生失敗：")
        print(result.stderr)
        sys.exit(1)
    print("✅ Keystore 產生完成")
else:
    print("\n請輸入現有 keystore 的資訊\n")
    store_pass = ask("Keystore 密碼")
    key_alias  = ask("Key alias", "upload")
    key_pass   = ask("Key 密碼", store_pass)

# ── step 2: write key.properties ─────────────────────────────────────────────
banner("步驟 2 / 4  寫入 key.properties")

key_props_content = f"""storePassword={store_pass}
keyPassword={key_pass}
keyAlias={key_alias}
storeFile=../upload-keystore.jks
"""
with open(KEY_PROPS, "w", encoding="utf-8", newline="\n") as f:
    f.write(key_props_content)
print(f"✅ 已寫入 {KEY_PROPS}")

# ── step 3: update build.gradle.kts ──────────────────────────────────────────
banner("步驟 3 / 4  更新 build.gradle.kts")

build_gradle_content = """import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.kanglei.wind_musician"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            keyAlias     = keystoreProperties["keyAlias"]   as String
            keyPassword  = keystoreProperties["keyPassword"] as String
            storeFile    = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    defaultConfig {
        applicationId = "com.kanglei.wind_musician"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
"""

with open(BUILD_GRADLE, "w", encoding="utf-8", newline="\n") as f:
    f.write(build_gradle_content)
print(f"✅ 已更新 {BUILD_GRADLE}")

# ── step 4: print release SHA-1 ───────────────────────────────────────────────
banner("步驟 4 / 4  取得 Release SHA-1（需加到 Firebase）")

sha1_cmd = [
    KEYTOOL,
    "-list", "-v",
    "-keystore", KEYSTORE_PATH,
    "-alias", key_alias,
    "-storepass", store_pass,
]
result = subprocess.run(sha1_cmd, capture_output=True, text=True)
sha1_line = [l for l in result.stdout.splitlines() if "SHA1" in l]
if sha1_line:
    sha1 = sha1_line[0].strip()
    print(f"\n🔑 Release {sha1}")
    print("""
⚠  請記得把這個 SHA-1 加到 Firebase Console：
   專案設定 → 你的 Android App → 新增指紋 → 貼上上方 SHA-1 → 儲存
   然後重新下載 google-services.json 放進 android/app/
""")
else:
    print("無法自動取得 SHA-1，請手動執行：")
    print(f'  & "{KEYTOOL}" -list -v -keystore "{KEYSTORE_PATH}" -alias {key_alias}')

# ── done ──────────────────────────────────────────────────────────────────────
banner("完成！")
print("""
下一步：
  1. 把 Release SHA-1 加到 Firebase，重新下載 google-services.json
  2. 測試打包：  flutter build appbundle --release
  3. AAB 位置：  build\\app\\outputs\\bundle\\release\\app-release.aab
""")
