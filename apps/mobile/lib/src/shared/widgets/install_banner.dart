import 'package:flutter/material.dart';

import '../../core/pwa/pwa.dart';
import '../../core/theme.dart';

/// Dismissible "Install app" banner shown only on web when the browser has
/// offered a PWA install prompt. No-op (hidden) on native / when unavailable.
class InstallBanner extends StatefulWidget {
  const InstallBanner({super.key});

  @override
  State<InstallBanner> createState() => _InstallBannerState();
}

class _InstallBannerState extends State<InstallBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed || !pwaInstallAvailable()) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF007AFF), Color(0xFF5AC8FA)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.install_mobile_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Ilovani telefoningizga o'rnating",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            TextButton(
              onPressed: () {
                pwaTriggerInstall();
                setState(() => _dismissed = true);
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.accent,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("O'rnatish", style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.9), size: 20),
              onPressed: () => setState(() => _dismissed = true),
            ),
          ],
        ),
      ),
    );
  }
}
