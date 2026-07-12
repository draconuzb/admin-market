import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers.dart';
import '../../auth/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _langs = {'uz': 'language.uz', 'ru': 'language.ru', 'en': 'language.en'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final current = context.locale.languageCode;

    return Scaffold(
      appBar: AppBar(title: Text('profile.title'.tr())),
      body: ListView(
        children: [
          const SizedBox(height: 12),
          if (user != null)
            Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  child: Text(
                    user.fullName.isNotEmpty ? user.fullName.characters.first : '?',
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user.fullName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                Text(user.phone, style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          const SizedBox(height: 20),
          _sectionHeader(context, 'profile.language'.tr()),
          for (final entry in _langs.entries)
            RadioListTile<String>(
              value: entry.key,
              groupValue: current,
              title: Text(entry.value.tr()),
              onChanged: (v) async {
                if (v == null) return;
                await context.setLocale(Locale(v));
                await ref.read(tokenStorageProvider).saveLanguage(v);
              },
            ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text('common.logout'.tr(), style: const TextStyle(color: Colors.red)),
            onTap: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Text(text,
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700)),
      );
}
