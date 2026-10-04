import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/wilddeck_providers.dart';
import '../../core/services/wilddeck_services.dart';
import '../../shared/theme/wilddeck_theme.dart';
import '../../shared/widgets/wilddeck_components.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider) ?? const WildDeckPlayer(
      id: 'mock', displayName: 'WildAce',
      level: 7, xp: 630, xpToNextLevel: 1000,
      coins: 2400, gems: 45, wins: 42, losses: 18,
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: WildDeckTheme.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(slivers: [
            SliverToBoxAdapter(child: WildDeckTopBar(title: 'Profile')),
            SliverToBoxAdapter(child: _ProfileHero(player: player)),
            SliverToBoxAdapter(child: _StatsGrid(player: player)),
            SliverToBoxAdapter(child: _AchievementsSection()),
            SliverToBoxAdapter(child: _MatchHistorySection()),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ]),
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final WildDeckPlayer player;
  const _ProfileHero({required this.player});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Stack(alignment: Alignment.bottomRight, children: [
          PlayerAvatar(displayName: player.displayName, size: 88),
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [WildDeckTheme.cardRed, WildDeckTheme.cardWild]),
              shape: BoxShape.circle,
              border: Border.all(color: WildDeckTheme.navyDeep, width: 2)),
            child: const Icon(Icons.edit, color: Colors.white, size: 14),
          ),
        ]),
        const SizedBox(height: 14),
        Text(player.displayName, style: const TextStyle(
          color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.military_tech, color: WildDeckTheme.gold, size: 16),
          Text(' Level ${player.level}  •  WildDeck Player',
            style: const TextStyle(color: WildDeckTheme.textMuted, fontSize: 13)),
        ]),
        const SizedBox(height: 16),
        XPBar(xp: player.xp, xpToNext: player.xpToNextLevel, height: 8, showLabel: true),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          CoinBadge(amount: player.coins),
          Text('${player.xp} / ${player.xpToNextLevel} XP',
            style: const TextStyle(color: WildDeckTheme.textMuted, fontSize: 12)),
        ]),
      ]),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final WildDeckPlayer player;
  const _StatsGrid({required this.player});

  @override
  Widget build(BuildContext context) {
    final winRate = (player.winRate * 100).toStringAsFixed(1);
    final total = player.wins + player.losses;
    final stats = [
      ('GAMES', '$total',       Icons.sports_esports_rounded, WildDeckTheme.cardBlue),
      ('WINS',  '${player.wins}', Icons.emoji_events_rounded,  WildDeckTheme.gold),
      ('WIN %', '$winRate%',    Icons.bar_chart_rounded,      WildDeckTheme.cardGreen),
      ('STREAK','5',            Icons.local_fire_department,  WildDeckTheme.cardRed),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WildDeckTheme.navySurface,
        borderRadius: WildDeckTheme.radiusLarge,
        border: Border.all(color: WildDeckTheme.navyBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('STATS', style: TextStyle(
          color: WildDeckTheme.textMuted, fontSize: 11,
          fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: stats.map((s) {
          final (label, value, icon, color) = s;
          return Column(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 18,
              fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: WildDeckTheme.textMuted, fontSize: 10,
              fontWeight: FontWeight.w700, letterSpacing: 1)),
          ]);
        }).toList()),
      ]),
    );
  }
}

class _AchievementsSection extends StatelessWidget {
  static const _items = [
    ('First Win', 'Win your first match', true, WildDeckTheme.gold),
    ('Wild Card', 'Play 10 wild cards', true, WildDeckTheme.cardWild),
    ('Dominator', 'Win 5 in a row', false, WildDeckTheme.cardRed),
    ('Speed Run', 'Win in under 3 minutes', false, WildDeckTheme.cardBlue),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('ACHIEVEMENTS', style: TextStyle(
          color: WildDeckTheme.textMuted, fontSize: 11,
          fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        ..._items.map((entry) {
          final (title, desc, unlocked, color) = entry;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: WildDeckTheme.navySurface,
              borderRadius: WildDeckTheme.radiusMedium,
              border: Border.all(
                color: unlocked ? color.withOpacity(0.3) : WildDeckTheme.navyBorder)),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: unlocked ? color.withOpacity(0.15) : WildDeckTheme.navyCard,
                  shape: BoxShape.circle),
                child: Icon(
                  unlocked ? Icons.military_tech : Icons.lock_outline,
                  color: unlocked ? color : WildDeckTheme.textDisabled, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(
                  color: unlocked ? Colors.white : WildDeckTheme.textMuted,
                  fontSize: 14, fontWeight: FontWeight.w700)),
                Text(desc, style: const TextStyle(color: WildDeckTheme.textMuted, fontSize: 11)),
              ])),
              if (unlocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: WildDeckTheme.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4)),
                  child: const Text('DONE', style: TextStyle(
                    color: WildDeckTheme.success, fontSize: 9, fontWeight: FontWeight.w800))),
            ]),
          );
        }),
      ]),
    );
  }
}

class _MatchHistorySection extends StatelessWidget {
  static const _history = [
    (true,  'Classic Match', '3v3', '2m 45s'),
    (false, 'Quick Match',   '2v2', '4m 12s'),
    (true,  'Classic Match', '4v4', '7m 01s'),
    (true,  'Quick Match',   '2v2', '1m 58s'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('RECENT MATCHES', style: TextStyle(
          color: WildDeckTheme.textMuted, fontSize: 11,
          fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        ..._history.map((entry) {
          final (win, mode, size, duration) = entry;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: WildDeckTheme.navySurface,
              borderRadius: WildDeckTheme.radiusMedium,
              border: Border.all(color: WildDeckTheme.navyBorder)),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: win ? WildDeckTheme.success.withOpacity(0.12)
                             : WildDeckTheme.error.withOpacity(0.12),
                  shape: BoxShape.circle),
                child: Icon(win ? Icons.check_rounded : Icons.close_rounded,
                  color: win ? WildDeckTheme.success : WildDeckTheme.error, size: 18)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(mode, style: const TextStyle(color: Colors.white, fontSize: 13,
                  fontWeight: FontWeight.w600)),
                Text('$size  •  $duration',
                  style: const TextStyle(color: WildDeckTheme.textMuted, fontSize: 11)),
              ])),
              Text(win ? 'WIN' : 'LOSS', style: TextStyle(
                color: win ? WildDeckTheme.success : WildDeckTheme.error,
                fontSize: 12, fontWeight: FontWeight.w800)),
            ]),
          );
        }),
      ]),
    );
  }
}
