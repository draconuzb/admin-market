import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/order.dart';
import '../../providers.dart';

final ordersListProvider = FutureProvider<List<Order>>((ref) async {
  final page = await ref.watch(ordersRepositoryProvider).list();
  return page.items;
});

final orderDetailProvider = FutureProvider.family<Order, int>((ref, id) {
  return ref.watch(ordersRepositoryProvider).detail(id);
});
