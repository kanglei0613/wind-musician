library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/guide/user_guide_page.dart';
import '../../shared/constants/app_constants.dart';
import '../../shared/theme/color_mode_provider.dart';
import '../../l10n/app_localizations.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final colorMode = ref.watch(colorModeProvider);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    final authState = ref.watch(authStateProvider);
    final firebaseUser = authState.valueOrNull;
    final isSignedIn = firebaseUser != null;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: cs.surfaceContainerHighest,
                    width: 1,
                  ),
                ),
              ),
              child: isSignedIn
                  ? _SignedInHeaderWrapper(firebaseUid: firebaseUser.uid, photoUrl: firebaseUser.photoURL)
                  : _SignedOutHeader(
                      onSignIn: () {
                        Navigator.of(context).pop();
                        context.go('/login');
                      },
                      l: l,
                      cs: cs,
                    ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerSection(
                    title: l.drawerAppearance,
                    items: [
                      _DrawerItem(
                        icon: Icons.palette_outlined,
                        label: l.drawerColorMode,
                        onTap: () => _showColorPicker(context, ref, colorMode, l),
                      ),
                      _DrawerItem(
                        icon: Icons.language,
                        label: l.settingsLanguage,
                        trailing: _languageLabel(locale.languageCode, l),
                        onTap: () => _showLanguagePicker(context, ref, l),
                      ),
                    ],
                  ),

                  _DrawerSection(
                    title: l.drawerSupport,
                    items: [
                      _DrawerItem(
                        icon: Icons.menu_book_outlined,
                        label: l.drawerUserGuide,
                        onTap: () {
                          Navigator.of(context).pop(); // 關閉抽屜
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const UserGuidePage(),
                            ),
                          );
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.bug_report_outlined,
                        label: l.drawerBugReport,
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push('/feedback');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (isSignedIn)
              ListTile(
                leading: Icon(Icons.logout, color: cs.error, size: 20),
                title: Text(
                  l.drawerSignOut,
                  style: TextStyle(color: cs.error, fontSize: 14),
                ),
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                onTap: () async {
                  Navigator.of(context).pop();
                  await ref.read(authServiceProvider).signOut();
                },
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'v1.0.0',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _languageLabel(String code, AppLocalizations l) {
    switch (code) {
      case 'zh': return l.langZh;
      case 'en': return l.langEn;
      case 'ja': return l.langJa;
      case 'ko': return l.langKo;
      default: return l.langZh;
    }
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref, AppLocalizations l) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _LanguagePicker(
        currentCode: ref.read(localeProvider).languageCode,
        onSelected: (code) async {
          ref.read(localeProvider.notifier).state = Locale(code);
          // 持久化語言選擇，冷啟動時從 SharedPreferences 恢復
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.keyLocale, code);
          // 同步到 Firestore（已登入時）
          final uid = ref.read(authStateProvider).valueOrNull?.uid;
          if (uid != null) {
            ref.read(userRepositoryProvider).updateSettings(uid, language: code);
          }
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showColorPicker(
    BuildContext context,
    WidgetRef ref,
    ColorMode current,
    AppLocalizations l,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ColorModePicker(
        current: current,
        onChanged: (mode) async {
          ref.read(colorModeProvider.notifier).state = mode;
          // 持久化 Color Mode，冷啟動時從 SharedPreferences 恢復
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.keyColorScheme, mode.scheme.name);
          await prefs.setString(AppConstants.keyColorBrightness, mode.brightness.name);
          // 同步到 Firestore（已登入時）
          final uid = ref.read(authStateProvider).valueOrNull?.uid;
          if (uid != null) {
            ref.read(userRepositoryProvider).updateSettings(
              uid,
              colorScheme: mode.scheme.name,
              colorBrightness: mode.brightness.name,
            );
          }
        },
      ),
    );
  }
}

class _ColorModePicker extends StatefulWidget {
  final ColorMode current;
  final ValueChanged<ColorMode> onChanged;

  const _ColorModePicker({
    required this.current,
    required this.onChanged,
  });

  @override
  State<_ColorModePicker> createState() => _ColorModePickerState();
}

class _ColorModePickerState extends State<_ColorModePicker> {
  late AppColorScheme _scheme;
  late AppBrightness _brightness;

  static const _schemeColors = {
    AppColorScheme.black: Color(0xFF0F1923),
    AppColorScheme.gray: Color(0xFF4A4A4A),
    AppColorScheme.white: Color(0xFFF5F5F5),
    AppColorScheme.blue: Color(0xFF3b82f6),
    AppColorScheme.pink: Color(0xFFEC4899),
    AppColorScheme.purple: Color(0xFF8B5CF6),
    AppColorScheme.green: Color(0xFF10B981),
    AppColorScheme.yellow: Color(0xFFF59E0B),
  };

  @override
  void initState() {
    super.initState();
    _scheme = widget.current.scheme;
    _brightness = widget.current.brightness;
  }

  void _update({AppColorScheme? scheme, AppBrightness? brightness}) {
    setState(() {
      if (scheme != null) _scheme = scheme;
      if (brightness != null) _brightness = brightness;
    });
    widget.onChanged(ColorMode(scheme: _scheme, brightness: _brightness));
  }

  String _schemeLabel(AppColorScheme scheme, AppLocalizations l) {
    switch (scheme) {
      case AppColorScheme.black: return l.colorBlack;
      case AppColorScheme.gray: return l.colorGray;
      case AppColorScheme.white: return l.colorWhite;
      case AppColorScheme.blue: return l.colorBlue;
      case AppColorScheme.pink: return l.colorPink;
      case AppColorScheme.purple: return l.colorPurple;
      case AppColorScheme.green: return l.colorGreen;
      case AppColorScheme.yellow: return l.colorYellow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.drawerColorMode,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 20),

          Text(l.drawerThemeColor,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),

          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: AppColorScheme.values.map((scheme) {
              final isSelected = scheme == _scheme;
              final color = _schemeColors[scheme]!;
              final label = _schemeLabel(scheme, l);

              return GestureDetector(
                onTap: () => _update(scheme: scheme),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? cs.primary
                              : cs.surfaceContainerHighest,
                          width: isSelected ? 3 : 1.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? cs.primary : cs.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          Text(l.drawerBrightness,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _update(brightness: AppBrightness.dark),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _brightness == AppBrightness.dark
                          ? cs.primary.withAlpha(40)
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _brightness == AppBrightness.dark
                            ? cs.primary
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.dark_mode,
                          size: 16,
                          color: _brightness == AppBrightness.dark
                              ? cs.primary
                              : cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Dark',
                          style: TextStyle(
                            color: _brightness == AppBrightness.dark
                                ? cs.primary
                                : cs.onSurfaceVariant,
                            fontSize: 13,
                            fontWeight: _brightness == AppBrightness.dark
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: GestureDetector(
                  onTap: () => _update(brightness: AppBrightness.light),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _brightness == AppBrightness.light
                          ? cs.primary.withAlpha(40)
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _brightness == AppBrightness.light
                            ? cs.primary
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.light_mode,
                          size: 16,
                          color: _brightness == AppBrightness.light
                              ? cs.primary
                              : cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Light',
                          style: TextStyle(
                            color: _brightness == AppBrightness.light
                                ? cs.primary
                                : cs.onSurfaceVariant,
                            fontSize: 13,
                            fontWeight: _brightness == AppBrightness.light
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(l.tunerDone, style: const TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  final String currentCode;
  final ValueChanged<String> onSelected;

  const _LanguagePicker({
    required this.currentCode,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    final languages = [
      ('zh', l.langZh),
      ('en', l.langEn),
      ('ja', l.langJa),
      ('ko', l.langKo),
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.settingsLanguage,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...languages.map((lang) {
            final isSelected = lang.$1 == currentCode;
            return GestureDetector(
              onTap: () => onSelected(lang.$1),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? cs.primary.withAlpha(30)
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? cs.primary : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      lang.$2,
                      style: TextStyle(
                        color: isSelected ? cs.primary : cs.onSurface,
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      Icon(Icons.check_circle, color: cs.primary, size: 18),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Drawer header variants ────────────────────────────────────────────────────

/// Loads the Firestore AppUser so the header can show the saved displayName
/// and allow editing it.
class _SignedInHeaderWrapper extends ConsumerWidget {
  final String firebaseUid;
  final String? photoUrl;

  const _SignedInHeaderWrapper({
    required this.firebaseUid,
    required this.photoUrl,
  });

  Future<void> _showRenameDialog(BuildContext context, WidgetRef ref, String currentName) async {
    final ctrl = TextEditingController(text: currentName);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('更改名稱'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 30,
          decoration: const InputDecoration(hintText: '輸入新名稱'),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => Navigator.of(ctx).pop(true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('儲存')),
        ],
      ),
    );
    ctrl.dispose();

    if (confirmed != true) return;
    final newName = ctrl.text.trim();
    if (newName.isEmpty || newName == currentName) return;

    await ref.read(authServiceProvider).updateDisplayName(newName);
    ref.invalidate(currentUserProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final firestoreName = userAsync.valueOrNull?.displayName ?? '';
    final email = userAsync.valueOrNull?.email ?? '';

    // Hide Apple private relay addresses — they're meaningless to users.
    final showEmail = email.isNotEmpty && !email.contains('privaterelay.apple.com');

    return GestureDetector(
      onTap: () => _showRenameDialog(context, ref, firestoreName),
      child: _SignedInHeader(
        displayName: firestoreName,
        email: showEmail ? email : '',
        photoUrl: photoUrl,
        showEditHint: true,
      ),
    );
  }
}

class _SignedInHeader extends StatelessWidget {
  final String displayName;
  final String email;
  final String? photoUrl;
  final bool showEditHint;

  const _SignedInHeader({
    required this.displayName,
    required this.email,
    required this.photoUrl,
    this.showEditHint = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: cs.surfaceContainerHighest,
          backgroundImage:
              photoUrl != null ? NetworkImage(photoUrl!) : null,
          child: photoUrl == null
              ? Icon(Icons.person, color: cs.onSurfaceVariant, size: 28)
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      displayName.isNotEmpty ? displayName : '設定名稱',
                      style: TextStyle(
                        color: displayName.isNotEmpty ? cs.onSurface : cs.onSurfaceVariant,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showEditHint) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.edit_outlined, size: 14, color: cs.onSurfaceVariant),
                  ],
                ],
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SignedOutHeader extends StatelessWidget {
  final VoidCallback onSignIn;
  final AppLocalizations l;
  final ColorScheme cs;

  const _SignedOutHeader({
    required this.onSignIn,
    required this.l,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person_outline,
            color: cs.onSurfaceVariant,
            size: 28,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                l.drawerNotSignedIn,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ),
            FilledButton.tonal(
              onPressed: onSignIn,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(l.drawerSignIn, style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l.drawerSignInDesc,
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _DrawerSection extends StatelessWidget {
  final String title;
  final List<_DrawerItem> items;

  const _DrawerSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            title,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items,
      ],
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: cs.onSurfaceVariant, size: 20),
      title: Text(label, style: TextStyle(color: cs.onSurface, fontSize: 14)),
      trailing: trailing != null
          ? Text(trailing!,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12))
          : Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 16),
      onTap: onTap,
      dense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
