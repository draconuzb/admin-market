import 'dart:js_interop';

// Bridges to the beforeinstallprompt handler installed in web/index.html.
@JS('_amInstall')
external _AmInstall? get _amInstall;

@JS('_amInstallTrigger')
external void _amInstallTrigger();

extension type _AmInstall(JSObject _) implements JSObject {
  external bool get available;
}

bool pwaInstallAvailable() {
  try {
    return _amInstall?.available ?? false;
  } catch (_) {
    return false;
  }
}

void pwaTriggerInstall() {
  try {
    _amInstallTrigger();
  } catch (_) {}
}

// ── Web Push (bridges window._push in index.html) ──
@JS('_push')
external _Push? get _push;

extension type _Push(JSObject _) implements JSObject {
  external JSBoolean supported();
  external JSPromise<JSString?> subscribe(JSString vapidKey);
}

bool pushSupported() {
  try {
    return _push?.supported().toDart ?? false;
  } catch (_) {
    return false;
  }
}

/// Requests permission + subscribes; returns the subscription JSON, or null.
Future<String?> pushSubscribe(String vapidKey) async {
  final p = _push;
  if (p == null) return null;
  try {
    final res = await p.subscribe(vapidKey.toJS).toDart;
    return res?.toDart;
  } catch (_) {
    return null;
  }
}
