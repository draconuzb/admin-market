/// Cross-platform PWA install API. On web it talks to the browser's
/// `beforeinstallprompt`; elsewhere it is a no-op.
export 'pwa_stub.dart' if (dart.library.js_interop) 'pwa_web.dart';
