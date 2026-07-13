import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../providers.dart';
import '../../../shared/widgets/async_views.dart';
import '../admin_providers.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  Future<void> _act(BuildContext context, WidgetRef ref, int id, String action) async {
    try {
      await ref.read(adminRepositoryProvider).actOnUser(id, action);
      ref.invalidate(adminUsersProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminUsersProvider);
    return Scaffold(
      appBar: AppBar(title: Text('admin.users_title'.tr())),
      body: async.when(
        loading: () => const ListSkeleton(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(adminUsersProvider),
        ),
        data: (page) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: page.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final u = page.items[i];
            final blocked = u.status == 'blocked';
            final isAdmin = u.role == 'admin';
            return Card(
              child: ListTile(
                title: Text(u.fullName),
                subtitle: Text('${u.phone} · ${u.role}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _statusChip(u.status),
                    const SizedBox(width: 8),
                    if (!isAdmin)
                      TextButton(
                        onPressed: () => _act(context, ref, u.id, blocked ? 'unblock' : 'block'),
                        child: Text(blocked ? 'admin.unblock'.tr() : 'admin.block'.tr(),
                            style: TextStyle(color: blocked ? Colors.green : Colors.red)),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final color = switch (status) {
      'active' => const Color(0xFF1E9E4A),
      'blocked' => const Color(0xFFD23B3B),
      _ => const Color(0xFFEA8600),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
