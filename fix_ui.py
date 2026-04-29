import re, os

# ── router.dart ──────────────────────────────────────────────────────────────
with open(r'lib\router.dart', 'r', encoding='utf-8') as f:
    r = f.read()

r = r.replace("import 'package:flutter_riverpod/flutter_riverpod.dart';\n", '')
r = re.sub(r"/// 需要登入才能進入的路由\nconst _authRequiredRoutes.*?;\n\n", '', r, flags=re.DOTALL)
r = re.sub(r"  redirect: \(context, state\) \{.*?\  \},\n", '', r, flags=re.DOTALL)

with open(r'lib\router.dart', 'w', encoding='utf-8', newline='\n') as f:
    f.write(r)
print('router.dart: done')

# ── login_page.dart ──────────────────────────────────────────────────────────
with open(r'lib\features\auth\login_page.dart', 'r', encoding='utf-8') as f:
    p = f.read()

p = p.replace('  bool _isSignUp = false; // toggle between sign-in and sign-up',
              '  bool _isSignUp = false;\n  bool _showEmailForm = false;')

OLD_SCAFFOLD = '''    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 48),'''

NEW_SCAFFOLD = '''    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          TextButton(
            onPressed: _loading ? null : () => context.go('/tuner'),
            child: Text(l.loginSkip,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 12),'''

p = p.replace(OLD_SCAFFOLD, NEW_SCAFFOLD)

p = p.replace('                width: 88,\n                height: 88,',
              '                width: 64,\n                height: 64,')
p = p.replace('              borderRadius: BorderRadius.circular(24),',
              '              borderRadius: BorderRadius.circular(18),')
p = p.replace("                  size: 48,\n                  color: cs.onPrimaryContainer,",
              "                  size: 36,\n                  color: cs.onPrimaryContainer,")
p = p.replace("                  fontSize: 26,", "                  fontSize: 22,")
p = p.replace('              const SizedBox(height: 40),\n\n              // ── Google button',
              '              const SizedBox(height: 24),\n\n              // ── Google button')
p = p.replace('              const SizedBox(height: 28),\n\n              // ── Divider',
              '              const SizedBox(height: 18),\n\n              // ── Divider')

OLD_FORM_START = "              // ── Email form ─────────────────────────────────────────────\n              Form("
NEW_FORM_START = "              // ── Email toggle / form ────────────────────────────────────\n              if (!_showEmailForm)\n                OutlinedButton(\n                  onPressed: () => setState(() => _showEmailForm = true),\n                  style: OutlinedButton.styleFrom(\n                    padding: const EdgeInsets.symmetric(vertical: 13),\n                    side: BorderSide(color: cs.outline),\n                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),\n                  ),\n                  child: const Text('Email 登入 / 註冊',\n                      style: TextStyle(fontSize: 14)),\n                ),\n              if (_showEmailForm)\n              Form("
p = p.replace(OLD_FORM_START, NEW_FORM_START)

OLD_SKIP = '''
              const SizedBox(height: 12),

              Text(
                l.loginBenefitHint,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // ── Guest mode ──────────────────────────────────────────────
              TextButton(
                onPressed: _loading ? null : () => context.go('/tuner'),
                child: Text(
                  l.loginSkip,
                  style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                ),
              ),

              const SizedBox(height: 24),'''

NEW_SKIP = '''
              const SizedBox(height: 16),

              Center(
                child: Text(
                  l.loginBenefitHint,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),'''

p = p.replace(OLD_SKIP, NEW_SKIP)

with open(r'lib\features\auth\login_page.dart', 'w', encoding='utf-8', newline='\n') as f:
    f.write(p)
print('login_page.dart: done')
print('Now run: flutter run')
