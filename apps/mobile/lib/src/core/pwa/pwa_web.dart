import 'dart:convert';
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

// ── File download (bridges window._download in index.html) ──
@JS('_download')
external JSBoolean _download(JSString filename, JSString base64, JSString mime);

/// Triggers a browser "Save as" for the given bytes. Web only.
bool downloadBytes(String filename, List<int> bytes, String mime) {
  try {
    return _download(filename.toJS, base64Encode(bytes).toJS, mime.toJS).toDart;
  } catch (_) {
    return false;
  }
}

// ── File picker (bridges window._pickFile in index.html) ──
@JS('_pickFile')
external JSPromise<JSString?> _pickFile(JSString accept);

/// Opens a browser file dialog; returns the chosen file, or null if cancelled.
Future<({String name, List<int> bytes})?> pickFile(String accept) async {
  try {
    final res = await _pickFile(accept.toJS).toDart;
    final s = res?.toDart;
    if (s == null) return null;
    final m = jsonDecode(s) as Map<String, dynamic>;
    return (name: m['name'] as String, bytes: base64Decode(m['data'] as String));
  } catch (_) {
    return null;
  }
}
