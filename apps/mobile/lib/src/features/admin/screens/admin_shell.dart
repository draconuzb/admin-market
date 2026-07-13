import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/auth_controller.dart';

/// Admin web shell with a side navigation rail.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinations = [
      (Icons.how_to_reg_outlined, 'admin.nav_registrations'.tr()),
      (Icons.people_outline, 'admin.nav_users'.tr()),
      (Icons.inventory_2_outlined, 'admin.nav_products'.tr()),
      (Icons.settings_outlined, 'admin.nav_settings'.tr()),
      (Icons.bar_chart_outlined, 'admin.nav_reports'.tr()),
    ];
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: (i) =>
                shell.goBranch(i, initialLocation: i == shell.currentIndex),
            labelType: NavigationRailLabelType.all,
            leading: Column(
              children: [
                const SizedBox(height: 8),
                Icon(Icons.storefront, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 8),
              ],
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'common.logout'.tr(),
                    onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                  ),
                ),
              ),
            ),
            destinations: [
              for (final (icon, label) in destinations)
                NavigationRailDestination(icon: Icon(icon), label: Text(label)),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: shell),
        ],
      ),
    );
  }
}
