import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth_controller.dart';
import 'theme.dart';

/// On wide screens (desktop web), the mobile-oriented buyer/factory UI is
/// centered inside a phone-width viewport on a soft backdrop, so it reads as a
/// real app instead of a stretched full-width page. The admin panel is a proper
/// desktop dashboard, so it is left full-width.
class MobileFrame extends ConsumerWidget {
  const MobileFrame({super.key, required this.child});
  final Widget child;

  static const double _maxWidth = 440;
  static const double _breakpoint = 640;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authControllerProvider).user?.role;
    final width = MediaQuery.sizeOf(context).width;

    // Admin dashboards want the full canvas; phones already fit.
    if (role == 'admin' || width <= _breakpoint) return child;

    final height = MediaQuery.sizeOf(context).height;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8EAF0), Color(0xFFDDE1EA)],
        ),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: _maxWidth,
          height: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.bg,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: MediaQuery(
              // Report the framed width to descendants so layouts size correctly.
              data: MediaQuery.of(context).copyWith(
                size: Size(_maxWidth, height),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
