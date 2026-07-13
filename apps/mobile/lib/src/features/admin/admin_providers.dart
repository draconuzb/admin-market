import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/admin.dart';
import '../../models/page.dart';
import '../../providers.dart';

final adminRegistrationsProvider = FutureProvider<Paged<Registration>>((ref) {
  return ref.watch(adminRepositoryProvider).registrations();
});

final adminUsersProvider = FutureProvider<Paged<AdminUserRow>>((ref) {
  return ref.watch(adminRepositoryProvider).users();
});

final adminProductsProvider = FutureProvider<Paged<AdminProduct>>((ref) {
  return ref.watch(adminRepositoryProvider).products();
});

final adminSettingsProvider = FutureProvider<Map<String, String>>((ref) {
  return ref.watch(adminRepositoryProvider).getSettings();
});

final adminReportProvider = FutureProvider<ReportSummary>((ref) {
  return ref.watch(adminRepositoryProvider).reportSummary();
});
