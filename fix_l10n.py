import json, os

base = r'lib\l10n'

NEW_KEYS = {
    'app_zh.arb': {
        "drawerNotSignedIn": "尚未登入",
        "drawerSignOut": "登出",
        "loginTagline": "記錄你的每一次練習",
        "loginGoogleButton": "使用 Google 登入",
        "loginAppleButton": "使用 Apple 登入",
        "loginDisplayName": "顯示名稱",
        "loginPassword": "密碼",
        "loginForgotPassword": "忘記密碼？",
        "loginSignUp": "註冊",
        "loginSignIn": "登入",
        "loginAlreadyHaveAccount": "已有帳號？登入",
        "loginNoAccount": "還沒有帳號？註冊",
        "loginBenefitHint": "登入後可同步紀錄、加入樂團",
        "loginSkip": "略過",
        "loginFieldRequired": "此欄位為必填",
        "loginInvalidEmail": "請輸入有效的電子郵件",
        "loginPasswordTooShort": "密碼至少需要 6 個字元",
    },
    'app_en.arb': {
        "drawerNotSignedIn": "Not signed in",
        "drawerSignOut": "Sign Out",
        "loginTagline": "Record every practice session",
        "loginGoogleButton": "Sign in with Google",
        "loginAppleButton": "Sign in with Apple",
        "loginDisplayName": "Display Name",
        "loginPassword": "Password",
        "loginForgotPassword": "Forgot password?",
        "loginSignUp": "Sign Up",
        "loginSignIn": "Sign In",
        "loginAlreadyHaveAccount": "Already have an account? Sign in",
        "loginNoAccount": "No account? Sign up",
        "loginBenefitHint": "Sign in to sync records and join ensembles",
        "loginSkip": "Skip",
        "loginFieldRequired": "This field is required",
        "loginInvalidEmail": "Please enter a valid email",
        "loginPasswordTooShort": "Password must be at least 6 characters",
    },
    'app_ja.arb': {
        "drawerNotSignedIn": "未サインイン",
        "drawerSignOut": "サインアウト",
        "loginTagline": "練習のすべてを記録しよう",
        "loginGoogleButton": "Googleでサインイン",
        "loginAppleButton": "Appleでサインイン",
        "loginDisplayName": "表示名",
        "loginPassword": "パスワード",
        "loginForgotPassword": "パスワードをお忘れですか？",
        "loginSignUp": "登録",
        "loginSignIn": "サインイン",
        "loginAlreadyHaveAccount": "すでにアカウントをお持ちですか？サインイン",
        "loginNoAccount": "アカウントをお持ちでないですか？登録",
        "loginBenefitHint": "サインインして記録を同期し、アンサンブルに参加",
        "loginSkip": "スキップ",
        "loginFieldRequired": "このフィールドは必須です",
        "loginInvalidEmail": "有効なメールアドレスを入力してください",
        "loginPasswordTooShort": "パスワードは6文字以上必要です",
    },
    'app_ko.arb': {
        "drawerNotSignedIn": "로그인되지 않음",
        "drawerSignOut": "로그아웃",
        "loginTagline": "모든 연습을 기록하세요",
        "loginGoogleButton": "Google로 로그인",
        "loginAppleButton": "Apple로 로그인",
        "loginDisplayName": "표시 이름",
        "loginPassword": "비밀번호",
        "loginForgotPassword": "비밀번호를 잊으셨나요?",
        "loginSignUp": "회원가입",
        "loginSignIn": "로그인",
        "loginAlreadyHaveAccount": "이미 계정이 있으신가요? 로그인",
        "loginNoAccount": "계정이 없으신가요? 회원가입",
        "loginBenefitHint": "로그인하여 기록을 동기화하고 앙상블에 참여하세요",
        "loginSkip": "건너뛰기",
        "loginFieldRequired": "이 필드는 필수입니다",
        "loginInvalidEmail": "유효한 이메일을 입력해주세요",
        "loginPasswordTooShort": "비밀번호는 최소 6자 이상이어야 합니다",
    },
}

for fname, keys in NEW_KEYS.items():
    fpath = os.path.join(base, fname)
    with open(fpath, 'r', encoding='utf-8') as f:
        data = json.load(f)
    added = 0
    for k, v in keys.items():
        if k not in data:
            data[k] = v
            added += 1
    with open(fpath, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f'{fname}: added {added} keys')

print('\nDone! Now run: flutter run')
