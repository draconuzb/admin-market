import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../providers.dart';
import '../../auth/auth_controller.dart';

/// iOS Settings-style profile screen.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _langs = {'uz': 'language.uz', 'ru': 'language.ru', 'en': 'language.en'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final current = context.locale.languageCode;
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Profile header ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, top + 20, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Text('profile.title'.tr(),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                if (user != null) ...[
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppTheme.accent, AppTheme.accentLight]),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      user.fullName.isNotEmpty
                          ? user.fullName.characters.first.toUpperCase() : '?',
                      style: const TextStyle(
                          fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user.fullName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(user.phone,
                      style: const TextStyle(
                          fontSize: 15, color: AppTheme.textSecondary)),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Language section ──
          IosGroupedSection(
            header: 'profile.language'.tr(),
            children: [
              for (final entry in _langs.entries)
                ListTile(
                  dense: true,
                  title: Text(entry.value.tr(), style: const TextStyle(fontSize: 16)),
                  trailing: current == entry.key
                      ? const Icon(Icons.check, color: AppTheme.accent, size: 20)
                      : null,
                  onTap: () async {
                    await context.setLocale(Locale(entry.key));
                    await ref.read(tokenStorageProvider).saveLanguage(entry.key);
                  },
                ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Logout ──
          IosGroupedSection(
            children: [
              ListTile(
                dense: true,
                title: Text('common.logout'.tr(),
                    style: TextStyle(fontSize: 16, color: AppTheme.danger),
                    textAlign: TextAlign.center),
                onTap: () => ref.read(authControllerProvider.notifier).logout(),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
