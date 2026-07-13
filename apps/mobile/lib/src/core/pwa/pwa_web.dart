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
