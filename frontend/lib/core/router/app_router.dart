import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:wilddeck/features/auth/screens/login_screen.dart';
import 'package:wilddeck/features/auth/screens/register_screen.dart';
import 'package:wilddeck/features/auth/screens/profile_screen.dart';
import 'package:wilddeck/features/auth/screens/splash_screen.dart';
import 'package:wilddeck/features/lobby/screens/lobby_screen.dart';
import 'package:wilddeck/features/game/screens/game_screen.dart';
import 'package:wilddeck/features/leaderboard/screens/leaderboard_screen.dart';

/// Returns whether the current user is authenticated.
/// Replace this with a real check against your auth provider (e.g. Riverpod).
bool _isAuthenticated() {
  // TODO: wire up to FirebaseAuth.instance.currentUser != null
  return false;
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (BuildContext context, GoRouterState state) {
    final isLoggedIn = _isAuthenticated();
    final isOnAuthRoute = state.matchedLocation.startsWith('/auth');
    final isOnSplash = state.matchedLocation == '/splash';

    // Always allow splash through — it handles its own redirect
    if (isOnSplash) return null;

    // Not logged in and not on an auth route → send to login
    if (!isLoggedIn && !isOnAuthRoute) {
      return '/auth/login';
    }

    // Logged in but on an auth route → send to lobby
    if (isLoggedIn && isOnAuthRoute) {
      return '/lobby';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/auth/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/auth/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/lobby',
      builder: (context, state) => const LobbyScreen(),
    ),
    GoRoute(
      path: '/game/:gameId',
      builder: (context, state) {
        final gameId = state.pathParameters['gameId'] ?? '';
        return GameScreen(gameId: gameId);
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/leaderboard',
      builder: (context, state) => const LeaderboardScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64),
          const SizedBox(height: 16),
          Text(
            'Page not found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            state.error?.toString() ?? 'Unknown route',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/splash'),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),
);
