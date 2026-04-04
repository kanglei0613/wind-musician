library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app.dart';
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
              child: Column(
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
                  Text(
                    l.drawerSignIn,
                    style: TextStyle(
                      color: cs.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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
                        onTap: () {},
                      ),
                      _DrawerItem(
                        icon: Icons.bug_report_outlined,
                        label: l.drawerBugReport,
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
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
        onSelected: (code) {
          ref.read(localeProvider.notifier).state = Locale(code);
          Navigator.pop(context);
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
        onChanged: (mode) {
          ref.read(colorModeProvider.notifier).state = mode;
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
