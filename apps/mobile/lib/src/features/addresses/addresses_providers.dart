import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/address.dart';
import '../../providers.dart';

final addressesProvider = FutureProvider<List<Address>>((ref) async {
  return ref.watch(addressesRepositoryProvider).list();
});
