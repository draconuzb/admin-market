import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../pwa/pwa.dart';

final downloadServiceProvider = Provider<DownloadService>((ref) => DownloadService(ref));

/// Fetches an authenticated binary payload from the API and hands it to the
/// browser as a download (PDF invoices, Excel/CSV exports).
class DownloadService {
  DownloadService(this._ref);
  final Ref _ref;

  Future<bool> download(
    String path,
    String filename,
    String mime, {
    Map<String, dynamic>? query,
  }) async {
    final bytes = await _ref.read(apiClientProvider).getBytes(path, query: query);
    return downloadBytes(filename, bytes, mime);
  }
}
