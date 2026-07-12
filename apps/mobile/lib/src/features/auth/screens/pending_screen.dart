import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth_controller.dart';

class PendingScreen extends ConsumerWidget {
  const PendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('pending.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_top, size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 20),
            Text('pending.title'.tr(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text('pending.message'.tr(), textAlign: TextAlign.center),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: () => ref.read(authControllerProvider.notifier).refreshUser(),
              icon: const Icon(Icons.refresh),
              label: Text('pending.refresh'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
