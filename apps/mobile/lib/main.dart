import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/core/responsive.dart';
import 'src/core/theme.dart';
import 'src/core/theme_controller.dart';
import 'src/providers.dart';
import 'src/routing/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: EasyLocalization(
        supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('uz'),
        startLocale: const Locale('uz'),
        child: const AdminMarketApp(),
      ),
    ),
  );
}

class AdminMarketApp extends ConsumerWidget {
  const AdminMarketApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final mode = ref.watch(themeModeProvider);
    final platform = MediaQuery.platformBrightnessOf(context);
    // Keep the global brightness flag in sync with the effective theme so the
    // AppTheme.* getters used across screens resolve to the right palette.
    AppTheme.isDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system && platform == Brightness.dark);

    return MaterialApp.router(
      title: 'Admin Market',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      routerConfig: router,
      builder: (context, child) => MobileFrame(child: child ?? const SizedBox()),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}
