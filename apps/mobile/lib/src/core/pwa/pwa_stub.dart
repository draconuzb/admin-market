/// Non-web fallback: native apps are installed via the store, so these are no-ops.
bool pwaInstallAvailable() => false;
void pwaTriggerInstall() {}
