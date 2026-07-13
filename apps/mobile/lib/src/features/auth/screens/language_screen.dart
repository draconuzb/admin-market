import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../providers.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  static const _langs = [
    ('uz', 'language.uz', '🇺🇿'),
    ('ru', 'language.ru', '🇷🇺'),
    ('en', 'language.en', '🇬🇧'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = context.locale.languageCode;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: Text('language.title'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            IosGroupedSection(
              margin: EdgeInsets.zero,
              children: [
                for (final (code, label, flag) in _langs)
                  ListTile(
                    leading: Text(flag, style: const TextStyle(fontSize: 24)),
                    title: Text(label.tr(), style: const TextStyle(fontSize: 16)),
                    trailing: current == code
                        ? const Icon(Icons.check, color: AppTheme.accent, size: 20)
                        : null,
                    onTap: () async {
                      await context.setLocale(Locale(code));
                      await ref.read(tokenStorageProvider).saveLanguage(code);
                    },
                  ),
              ],
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => context.go('/login'),
              child: Text('language.continue'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
