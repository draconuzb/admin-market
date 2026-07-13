import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.accent, Color(0xFF3A6BF0)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 40,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset('assets/logo_512.png', width: 112, height: 112),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'app_name'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 30),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
