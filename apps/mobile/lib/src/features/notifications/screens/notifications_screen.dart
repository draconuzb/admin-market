import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../models/notification.dart';
import '../../../shared/widgets/async_views.dart';
import '../notifications_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static const _icons = {
    'order_status': Icons.local_shipping_outlined,
    'new_order': Icons.receipt_long_outlined,
    'account': Icons.verified_user_outlined,
  };
  static const _colors = {
    'order_status': AppTheme.accent,
    'new_order': AppTheme.warning,
    'account': AppTheme.success,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text('notifications.title'.tr()),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationsRepositoryProvider).markAllRead();
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadCountProvider);
            },
            child: Text('notifications.read_all'.tr()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(notificationsProvider);
          ref.invalidate(unreadCountProvider);
        },
        child: async.when(
          loading: () => const ListSkeleton(),
          error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(notificationsProvider),
          ),
          data: (page) => page.items.isEmpty
              ? Stack(children: [
                  ListView(),
                  EmptyView(
                      message: 'notifications.empty'.tr(),
                      icon: Icons.notifications_none_rounded),
                ])
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: page.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _tile(context, ref, page.items[i]),
                ),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, WidgetRef ref, AppNotification n) {
    final color = _colors[n.type] ?? AppTheme.accent;
    return GestureDetector(
      onTap: () async {
        if (!n.isRead) {
          await ref.read(notificationsRepositoryProvider).markRead(n.id);
          ref.invalidate(notificationsProvider);
          ref.invalidate(unreadCountProvider);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
          border: n.isRead
              ? null
              : Border.all(color: color.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icons[n.type] ?? Icons.notifications, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(n.title,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                      if (!n.isRead)
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  if (n.body != null && n.body!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(n.body!,
                        style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                  ],
                  const SizedBox(height: 4),
                  Text(DateFormat('dd.MM.yyyy HH:mm').format(n.createdAt),
                      style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
