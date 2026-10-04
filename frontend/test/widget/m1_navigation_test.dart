import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wilddeck/core/router/wilddeck_router.dart';
import 'package:wilddeck/features/auth/screens/wilddeck_login_screen.dart';
import 'package:wilddeck/features/home/home_screen.dart';
import 'package:wilddeck/features/splash/splash_screen.dart';
import 'package:wilddeck/shared/theme/wilddeck_theme.dart';

/// Builds a testable MaterialApp backed by a given [GoRouter].
Widget _routerApp(GoRouter router) {
  return MaterialApp.router(
    routerConfig: router,
    theme: WildDeckTheme.theme,
  );
}

/// A router that starts at [initialLocation] and uses [WildRoutes].
/// Player is pre-seeded so auth guards pass.
GoRouter _buildRouter({required String initialLocation, bool loggedIn = true}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: WildRoutes.splash,   builder: (_, __) => const WildDeckSplashScreen()),
      GoRoute(path: WildRoutes.login,    builder: (_, __) => const WildDeckLoginScreen()),
      GoRoute(path: WildRoutes.home,     builder: (_, __) => const HomeScreen()),
      GoRoute(path: WildRoutes.gameMode, builder: (_, __) => const Scaffold(body: Text('GameMode'))),
    ],
    redirect: (context, state) {
      if (!loggedIn && state.matchedLocation != WildRoutes.login) return WildRoutes.login;
      return null;
    },
  );
}

void main() {
  group('Navigation: unauthenticated user is redirected', () {
    testWidgets('redirects to /login when not logged in', (tester) async {
      final router = _buildRouter(initialLocation: WildRoutes.home, loggedIn: false);
      await tester.pumpWidget(ProviderScope(child: _routerApp(router)));
      await tester.pumpAndSettle();
      expect(find.byType(WildDeckLoginScreen), findsOneWidget);
    });
  });

  group('WildRoutes constants', () {
    test('routes have correct path values', () {
      expect(WildRoutes.splash,   '/');
      expect(WildRoutes.login,    '/login');
      expect(WildRoutes.home,     '/home');
      expect(WildRoutes.gameMode, '/game-mode');
      expect(WildRoutes.game,     '/game/:gameId');
      expect(WildRoutes.gamePath('abc123'), '/game/abc123');
      expect(WildRoutes.resultPath('abc123'), '/result/abc123');
    });
  });

  group('WildDeck branding constraints', () {
    testWidgets('Splash screen does not contain UNO text', (tester) async {
      await tester.pumpWidget(const ProviderScope(
        child: MaterialApp(home: WildDeckSplashScreen()),
      ));
      await tester.pump();
      // Must not contain 'UNO' — IP constraint
      expect(find.textContaining('UNO'), findsNothing);
      // Must contain 'WILDDECK' branding
      expect(find.textContaining('WILDDECK'), findsWidgets);
    });

    testWidgets('Login screen does not contain UNO text', (tester) async {
      await tester.pumpWidget(const ProviderScope(
        child: MaterialApp(home: WildDeckLoginScreen()),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('UNO'), findsNothing);
      expect(find.textContaining('WILDDECK'), findsWidgets);
    });
  });
}
