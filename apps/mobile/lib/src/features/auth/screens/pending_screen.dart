import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../auth_controller.dart';

class PendingScreen extends ConsumerWidget {
  const PendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text('pending.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 22),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_top_rounded,
                    size: 40, color: AppTheme.accent),
              ),
              const SizedBox(height: 24),
              Text('pending.title'.tr(),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text('pending.message'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 15, height: 1.5)),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: () => ref.read(authControllerProvider.notifier).refreshUser(),
                icon: const Icon(Icons.refresh, size: 20),
                label: Text('pending.refresh'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
