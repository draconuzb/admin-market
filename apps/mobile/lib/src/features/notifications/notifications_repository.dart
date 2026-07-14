import '../../core/api/dio_client.dart';
import '../../models/notification.dart';
import '../../models/page.dart';

class NotificationsRepository {
  NotificationsRepository(this._api);
  final ApiClient _api;

  Future<Paged<AppNotification>> list({int page = 1}) async {
    final resp = await _api.get('/notifications', query: {'page': page});
    return Paged.fromJson(resp.data as Map<String, dynamic>, AppNotification.fromJson);
  }

  Future<int> unreadCount() async {
    final resp = await _api.get('/notifications/unread-count');
    return resp.data['count'] as int;
  }

  Future<void> markRead(int id) => _api.patch('/notifications/$id/read');

  Future<void> markAllRead() => _api.post('/notifications/read-all');
}
