import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import 'profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(apiClientProvider)),
);

final profileProvider = FutureProvider<Profile>((ref) {
  return ref.watch(profileRepositoryProvider).get();
});
