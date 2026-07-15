import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/pwa/pwa.dart';
import '../../providers.dart';

final pushServiceProvider = Provider<PushService>((ref) => PushService(ref));

class PushService {
  PushService(this._ref);
  final Ref _ref;

  bool get supported => pushSupported();

  /// Requests permission, subscribes to Web Push, and registers with the API.
  /// Returns true on success.
  Future<bool> enable() async {
    if (!pushSupported()) return false;
    final api = _ref.read(apiClientProvider);
    final keyResp = await api.get('/push/vapid-public-key');
    final key = keyResp.data['key'] as String;
    final subJson = await pushSubscribe(key);
    if (subJson == null) return false; // denied or unsupported
    final sub = jsonDecode(subJson) as Map<String, dynamic>;
    await api.post('/push/subscribe', data: {
      'endpoint': sub['endpoint'],
      'keys': sub['keys'],
    });
    return true;
  }
}
