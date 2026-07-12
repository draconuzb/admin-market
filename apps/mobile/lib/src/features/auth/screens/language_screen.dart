import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  static const _langs = [
    ('uz', 'language.uz'),
    ('ru', 'language.ru'),
    ('en', 'language.en'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = context.locale.languageCode;
    return Scaffold(
      appBar: AppBar(title: Text('language.title'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final (code, label) in _langs)
              Card(
                child: RadioListTile<String>(
                  value: code,
                  groupValue: current,
                  title: Text(label.tr()),
                  onChanged: (v) async {
                    if (v == null) return;
                    await context.setLocale(Locale(v));
                    await ref.read(tokenStorageProvider).saveLanguage(v);
                  },
                ),
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
