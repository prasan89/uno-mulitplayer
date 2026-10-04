import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wilddeck/core/providers/wilddeck_providers.dart';
import 'package:wilddeck/core/router/wilddeck_router.dart';
import 'package:wilddeck/core/services/wilddeck_services.dart';
import 'package:wilddeck/shared/theme/wilddeck_theme.dart';
import 'package:wilddeck/shared/widgets/wilddeck_components.dart';

/// WildDeck Home Screen — player hub with Play Now CTA and secondary sections.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    final mock = player ?? const WildDeckPlayer(
      id: 'mock', displayName: 'WildAce',
      level: 7, xp: 630, coins: 2400, gems: 45,
      wins: 42, losses: 18,
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: WildDeckTheme.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _TopHeader(player: mock)),
              SliverToBoxAdapter(child: _HeroSection()),
              SliverToBoxAdapter(child: _QuickStatsRow(player: mock)),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(child: _SectionGrid()),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  final WildDeckPlayer player;
  const _TopHeader({required this.player});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.push(WildRoutes.profile),
            child: Row(
              children: [
                PlayerAvatar(displayName: player.displayName, size: 40),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(player.displayName,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    Row(children: [
                      const Icon(Icons.military_tech, color: WildDeckTheme.gold, size: 13),
                      Text(' Lv.${player.level}',
                        style: const TextStyle(color: WildDeckTheme.gold, fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          CoinBadge(amount: player.coins, compact: true),
          const SizedBox(width: 8),
          _GemBadge(amount: player.gems),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: WildDeckTheme.textSecond),
            onPressed: () => context.push(WildRoutes.settings),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}

class _GemBadge extends StatelessWidget {
  final int amount;
  const _GemBadge({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [WildDeckTheme.cardWild, Color(0xFF4527A0)],
        ),
        borderRadius: WildDeckTheme.radiusSmall,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.diamond, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text('$amount', style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800,
          )),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2040), Color(0xFF0D1020)],
        ),
        borderRadius: WildDeckTheme.radiusLarge,
        border: Border.all(color: WildDeckTheme.navyBorder),
        boxShadow: WildDeckTheme.panelShadow,
      ),
      child: Column(
        children: [
          // Card fan decoration
          _CardFanDecoration(),
          const SizedBox(height: 16),
          const Text('WILDDECK', style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 6,
          )),
          const SizedBox(height: 4),
          const Text('Play Wild. Win Fast.', style: TextStyle(
            color: WildDeckTheme.gold,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          )),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'PLAY NOW',
            icon: Icons.bolt,
            onPressed: () => context.push(WildRoutes.gameMode),
          ),
        ],
      ),
    );
  }
}

class _CardFanDecoration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cards = [
      (WildDeckTheme.cardRed, -20.0, -12.0),
      (WildDeckTheme.cardBlue, -8.0, -16.0),
      (WildDeckTheme.cardGreen, 4.0, -12.0),
      (WildDeckTheme.cardYellow, 16.0, -8.0),
    ];

    return SizedBox(
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: cards.asMap().entries.map((entry) {
          final i = entry.key;
          final (color, _, translateY) = entry.value;
          return Transform.translate(
            offset: Offset((i - 1.5) * 22, translateY),
            child: Transform.rotate(
              angle: (i - 1.5) * 0.18,
              child: Container(
                width: 38, height: 54,
                decoration: BoxDecoration(
                  gradient: WildDeckTheme.cardGradient(color),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  boxShadow: WildDeckTheme.cardShadow(color),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  final WildDeckPlayer player;
  const _QuickStatsRow({required this.player});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: WildDeckTheme.gold, size: 14),
              const SizedBox(width: 6),
              Text('Lv.${player.level}  •  ${(player.winRate * 100).toStringAsFixed(0)}% win rate',
                style: const TextStyle(color: WildDeckTheme.textSecond, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          XPBar(xp: player.xp, xpToNext: player.xpToNextLevel, height: 5),
          const SizedBox(height: 4),
          Text('${player.xp} / ${player.xpToNextLevel} XP to Lv.${player.level + 1}',
            style: const TextStyle(color: WildDeckTheme.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _SectionGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('QUICK ACCESS', style: TextStyle(
            color: WildDeckTheme.textMuted, fontSize: 11,
            fontWeight: FontWeight.w700, letterSpacing: 1.5,
          )),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: const [
              _GridTile(icon: Icons.people_alt_rounded, label: 'Friends',  color: WildDeckTheme.cardBlue,   route: WildRoutes.friends),
              _GridTile(icon: Icons.event_rounded,      label: 'Events',   color: WildDeckTheme.cardRed,    route: null),
              _GridTile(icon: Icons.assignment_rounded, label: 'Missions', color: WildDeckTheme.cardGreen,  route: WildRoutes.missions),
              _GridTile(icon: Icons.emoji_events,       label: 'League',   color: WildDeckTheme.gold,       route: WildRoutes.leaderboard),
              _GridTile(icon: Icons.storefront_rounded, label: 'Shop',     color: WildDeckTheme.cardWild,   route: WildRoutes.shop),
              _GridTile(icon: Icons.style_rounded,      label: 'Cards',    color: WildDeckTheme.platinum,   route: WildRoutes.shop),
            ],
          ),
        ],
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? route;

  const _GridTile({
    required this.icon, required this.label,
    required this.color, required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: route != null ? () => context.go(route!) : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: WildDeckTheme.navySurface,
          borderRadius: WildDeckTheme.radiusMedium,
          border: Border.all(color: WildDeckTheme.navyBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(
              color: WildDeckTheme.textSecond,
              fontSize: 12, fontWeight: FontWeight.w600,
            )),
          ],
        ),
      ),
    );
  }
}
