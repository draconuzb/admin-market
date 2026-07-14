import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/admin.dart';
import '../../models/catalog.dart';
import '../../providers.dart';

final factoryProductsProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(factoryRepositoryProvider).products();
});

final factoryStatsProvider = FutureProvider<FactoryStats>((ref) {
  return ref.watch(factoryRepositoryProvider).stats();
});

final factoryAnalyticsProvider = FutureProvider<FactoryAnalytics>((ref) {
  return ref.watch(factoryRepositoryProvider).analytics();
});
