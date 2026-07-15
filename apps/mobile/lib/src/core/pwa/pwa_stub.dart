/// Non-web fallback: native apps are installed via the store, so these are no-ops.
bool pwaInstallAvailable() => false;
void pwaTriggerInstall() {}

// Web Push is a web-only concern; native push would use FCM/APNs instead.
bool pushSupported() => false;
Future<String?> pushSubscribe(String vapidKey) async => null;
