import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:driver_app/l10n/app_localizations.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/map/screens/map_screen.dart';
import 'features/orders/screens/order_incoming_screen.dart';
import 'features/orders/screens/order_active_screen.dart';
import 'features/settings/screens/settings_screen.dart';

final localeProvider = StateProvider<Locale>((ref) => const Locale('en'));
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

final _routerProvider = Provider<GoRouter>((ref) {
  final authId = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: authId != null ? '/map' : '/login',
    redirect: (context, state) {
      final loggedIn = authId != null;
      final onAuth = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      if (!loggedIn && !onAuth) return '/login';
      if (loggedIn && onAuth) return '/map';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/map', builder: (_, __) => const MapScreen()),
      GoRoute(path: '/order/incoming', builder: (_, __) => const OrderIncomingScreen()),
      GoRoute(path: '/order/active', builder: (_, __) => const OrderActiveScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    ],
  );
});

class DriverApp extends ConsumerWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'D-helper Rider',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      locale: locale,
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
        Locale('fr'),
        Locale('ar'),
      ],
    );
  }
}
