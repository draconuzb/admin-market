/// Non-web fallback: native apps are installed via the store, so these are no-ops.
bool pwaInstallAvailable() => false;
void pwaTriggerInstall() {}

// Web Push is a web-only concern; native push would use FCM/APNs instead.
bool pushSupported() => false;
Future<String?> pushSubscribe(String vapidKey) async => null;

// File download is a web-only concern (browser "Save as").
bool downloadBytes(String filename, List<int> bytes, String mime) => false;

// File picking is a web-only concern here.
Future<({String name, List<int> bytes})?> pickFile(String accept) async => null;
