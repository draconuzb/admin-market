import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/notification.dart';
import '../../models/page.dart';
import '../../providers.dart';
import 'notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref.watch(apiClientProvider)),
);

final notificationsProvider = FutureProvider<Paged<AppNotification>>((ref) {
  return ref.watch(notificationsRepositoryProvider).list();
});

/// Unread badge count. Invalidate to refresh (e.g. after opening the screen).
final unreadCountProvider = FutureProvider<int>((ref) async {
  try {
    return await ref.watch(notificationsRepositoryProvider).unreadCount();
  } catch (_) {
    return 0;
  }
});
