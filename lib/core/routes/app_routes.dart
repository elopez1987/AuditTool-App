import 'package:audit_tool/auth/login_screen.dart';
import 'package:audit_tool/auth/profile_screen.dart';
import 'package:audit_tool/core/api_settings_screen.dart';
import 'package:audit_tool/home_page.dart';
import 'package:audit_tool/splash_screen.dart';
import 'package:flutter/material.dart';

/// Nombres de rutas: un solo lugar para todas.
class AppRoutes {
  AppRoutes._();
  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  static const profile = '/profile';
  static const apiSettings = '/api-settings';
  static const audit = '/audit'; // arguments: Audit
}

final navigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerate(RouteSettings s) {
    final Widget page;
    switch (s.name) {
      case AppRoutes.splash:
        page = const SplashScreen();
      case AppRoutes.login:
        page = const LoginScreen();
      case AppRoutes.home:
        page = const HomePage();
      case AppRoutes.profile:
        page = const ProfileScreen();
      case AppRoutes.apiSettings:
        page = const ApiSettingsScreen();
      /*  case AppRoutes.audit:
        page = AuditPage(audit: s.arguments as Audit); */
      default:
        page = const LoginScreen();
    }
    return MaterialPageRoute(settings: s, builder: (_) => page);
  }

  /// Usable desde cualquier lugar (también desde el cliente HTTP).
  static void resetToLogin() {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (_) => false,
    );
  }
}
