import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/wilddeck_providers.dart';
import '../services/wilddeck_services.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/screens/wilddeck_login_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/game_mode/game_mode_screen.dart';
import '../../features/matchmaking/matchmaking_screen.dart';
import '../../features/game_lobby/game_lobby_screen.dart';
import '../../features/game/game_table_screen.dart';
import '../../features/game/wild_color_picker_screen.dart';
import '../../features/game/game_result_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/friends/friends_screen.dart';
import '../../features/shop/shop_screen.dart';
import '../../features/missions/missions_screen.dart';
import '../../features/leaderboard/leaderboard_screen.dart';
import '../../features/settings/settings_screen.dart';

// Route name constants — use these everywhere instead of raw strings.
class WildRoutes {
  static const splash      = '/';
  static const login       = '/login';
  static const home        = '/home';
  static const gameMode    = '/game-mode';
  static const matchmaking = '/matchmaking';
  static const gameLobby   = '/lobby';
  static const game        = '/game/:gameId';
  static const profile     = '/profile';
  static const friends     = '/friends';
  static const shop        = '/shop';
  static const missions    = '/missions';
  static const leaderboard = '/leaderboard';
  static const settings    = '/settings';

  static const wildColorPicker = '/wild-color';
  static const gameResult      = '/result/:gameId';

  static String gamePath(String gameId) => '/game/$gameId';
  static String resultPath(String gameId) => '/result/$gameId';
}

final routerProvider = Provider<GoRouter>((ref) {
  final playerAsync = ref.watch(playerProvider);

  return GoRouter(
    initialLocation: WildRoutes.splash,
    redirect: (context, state) {
      if (playerAsync.isLoading) return WildRoutes.splash;
      final isLoggedIn = playerAsync.valueOrNull != null;
      final loc = state.matchedLocation;

      // Always allow splash and login through
      if (loc == WildRoutes.splash || loc == WildRoutes.login) return null;

      if (!isLoggedIn) return WildRoutes.login;
      return null;
    },
    routes: [
      GoRoute(
        path: WildRoutes.splash,
        name: 'splash',
        builder: (_, __) => const WildDeckSplashScreen(),
      ),
      GoRoute(
        path: WildRoutes.login,
        name: 'login',
        builder: (_, __) => const WildDeckLoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => _HomeShell(child: child),
        routes: [
          GoRoute(
            path: WildRoutes.home,
            name: 'home',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: WildRoutes.leaderboard,
            name: 'leaderboard',
            builder: (_, __) => const LeaderboardScreen(),
          ),
          GoRoute(
            path: WildRoutes.missions,
            name: 'missions',
            builder: (_, __) => const MissionsScreen(),
          ),
          GoRoute(
            path: WildRoutes.shop,
            name: 'shop',
            builder: (_, __) => const ShopScreen(),
          ),
          GoRoute(
            path: WildRoutes.friends,
            name: 'friends',
            builder: (_, __) => const FriendsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: WildRoutes.gameMode,
        name: 'game-mode',
        builder: (_, __) => const GameModeScreen(),
      ),
      GoRoute(
        path: WildRoutes.matchmaking,
        name: 'matchmaking',
        builder: (context, state) {
          final mode = state.uri.queryParameters['mode'] ?? 'classic';
          return MatchmakingScreen(gameMode: mode);
        },
      ),
      GoRoute(
        path: WildRoutes.gameLobby,
        name: 'game-lobby',
        builder: (context, state) {
          final gameId = state.uri.queryParameters['gameId'] ?? 'demo';
          return GameLobbyScreen(gameId: gameId);
        },
      ),
      GoRoute(
        path: WildRoutes.game,
        name: 'game',
        builder: (context, state) {
          final gameId = state.pathParameters['gameId'] ?? 'demo';
          return GameTableScreen(gameId: gameId);
        },
      ),
      GoRoute(
        path: WildRoutes.wildColorPicker,
        name: 'wild-color',
        builder: (context, state) {
          final card = state.extra as WildGameCard?;
          return WildColorPickerScreen(card: card);
        },
      ),
      GoRoute(
        path: WildRoutes.gameResult,
        name: 'game-result',
        builder: (context, state) {
          final gameId = state.pathParameters['gameId'] ?? 'demo';
          return GameResultScreen(gameId: gameId);
        },
      ),
      GoRoute(
        path: WildRoutes.profile,
        name: 'profile',
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: WildRoutes.settings,
        name: 'settings',
        builder: (_, __) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF0B0E1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.white38),
            const SizedBox(height: 16),
            const Text('Page not found',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(WildRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Shell that wraps bottom-nav screens.
class _HomeShell extends ConsumerStatefulWidget {
  final Widget child;
  const _HomeShell({required this.child});

  @override
  ConsumerState<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<_HomeShell> {
  static const _tabs = [
    WildRoutes.home,
    WildRoutes.leaderboard,
    WildRoutes.missions,
    WildRoutes.shop,
    WildRoutes.friends,
  ];

  int _indexForPath(String path) {
    final idx = _tabs.indexWhere((t) => path.startsWith(t));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final currentIdx = _indexForPath(loc);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _WildDeckBottomNav(
        currentIndex: currentIdx,
        onTap: (i) => context.go(_tabs[i]),
      ),
    );
  }
}

class _WildDeckBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _WildDeckBottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(icon: Icons.home_rounded,        label: 'Home'),
    _NavItem(icon: Icons.leaderboard_rounded,  label: 'Rank'),
    _NavItem(icon: Icons.assignment_rounded,   label: 'Missions'),
    _NavItem(icon: Icons.storefront_rounded,   label: 'Shop'),
    _NavItem(icon: Icons.people_alt_rounded,   label: 'Friends'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141829),
        border: Border(top: BorderSide(color: Color(0xFF2E3550), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final active = i == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: active
                            ? BoxDecoration(
                                color: const Color(0xFFFFB300).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              )
                            : null,
                        child: Icon(item.icon,
                          color: active ? const Color(0xFFFFB300) : const Color(0xFF546E7A),
                          size: 22),
                      ),
                      const SizedBox(height: 2),
                      Text(item.label, style: TextStyle(
                        color: active ? const Color(0xFFFFB300) : const Color(0xFF546E7A),
                        fontSize: 10, fontWeight: FontWeight.w600,
                      )),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
