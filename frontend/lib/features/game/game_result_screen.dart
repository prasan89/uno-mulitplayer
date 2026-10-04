import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wilddeck/core/providers/wilddeck_providers.dart';
import 'package:wilddeck/core/router/wilddeck_router.dart';
import 'package:wilddeck/shared/theme/wilddeck_theme.dart';
import 'package:wilddeck/shared/widgets/wilddeck_components.dart';

/// Game result screen — win/lose, reward summary, play-again and home buttons.
class GameResultScreen extends ConsumerStatefulWidget {
  final String gameId;
  const GameResultScreen({super.key, required this.gameId});

  @override
  ConsumerState<GameResultScreen> createState() => _GameResultScreenState();
}

class _GameResultScreenState extends ConsumerState<GameResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late AnimationController _shimmerCtrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  // Mock win/loss result
  static const bool _didWin = true;
  static const int _coinsEarned = 150;
  static const int _xpEarned = 80;
  static const String _rank = '#2';

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _shimmerCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _scale = CurvedAnimation(parent: _entranceCtrl, curve: Curves.elasticOut);
    _fade  = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeIn);
    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: _didWin ? WildDeckTheme.heroGradient : WildDeckTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(children: [
                const SizedBox(height: 32),
                ScaleTransition(scale: _scale, child: _ResultBadge(didWin: _didWin)),
                const SizedBox(height: 24),
                Text(_didWin ? 'YOU WIN!' : 'BETTER LUCK NEXT TIME',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _didWin ? WildDeckTheme.gold : WildDeckTheme.textSecond,
                    fontSize: _didWin ? 34 : 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  )),
                const SizedBox(height: 8),
                Text(_didWin ? 'Rank $_rank  •  First to empty hand'
                              : 'You finished rank $_rank',
                  style: const TextStyle(color: WildDeckTheme.textMuted, fontSize: 14)),
                const SizedBox(height: 32),
                // Rewards
                _RewardsPanel(coins: _coinsEarned, xp: _xpEarned, didWin: _didWin),
                const SizedBox(height: 28),
                // XP bar
                const _XPProgress(xpEarned: _xpEarned, total: 1000, prev: 630),
                const Spacer(),
                PrimaryButton(
                  label: 'PLAY AGAIN',
                  icon: Icons.replay_rounded,
                  onPressed: () => context.go(WildRoutes.gameMode),
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  label: 'Back to Home',
                  onPressed: () => context.go(WildRoutes.home),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultBadge extends StatelessWidget {
  final bool didWin;
  const _ResultBadge({required this.didWin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120, height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: didWin
              ? [WildDeckTheme.gold, const Color(0xFFFF8F00)]
              : [WildDeckTheme.navySurface, WildDeckTheme.navyMid],
        ),
        boxShadow: didWin ? WildDeckTheme.buttonGlow(WildDeckTheme.gold) : WildDeckTheme.panelShadow,
      ),
      child: Center(child: Icon(
        didWin ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
        color: Colors.white, size: 56,
      )),
    );
  }
}

class _RewardsPanel extends StatelessWidget {
  final int coins, xp;
  final bool didWin;
  const _RewardsPanel({required this.coins, required this.xp, required this.didWin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WildDeckTheme.navySurface,
        borderRadius: WildDeckTheme.radiusLarge,
        border: Border.all(color: WildDeckTheme.navyBorder),
        boxShadow: WildDeckTheme.panelShadow,
      ),
      child: Column(children: [
        const Text('REWARDS EARNED', style: TextStyle(
          color: WildDeckTheme.textMuted, fontSize: 11,
          fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _RewardItem(icon: Icons.monetization_on_rounded,
            color: WildDeckTheme.gold, value: '+$coins', label: 'Coins'),
          Container(width: 1, height: 40, color: WildDeckTheme.navyBorder),
          _RewardItem(icon: Icons.star_rounded,
            color: WildDeckTheme.cardBlue, value: '+$xp', label: 'XP'),
          if (didWin) ...[
            Container(width: 1, height: 40, color: WildDeckTheme.navyBorder),
            _RewardItem(icon: Icons.local_fire_department_rounded,
              color: WildDeckTheme.cardRed, value: '+1', label: 'Win Streak'),
          ],
        ]),
      ]),
    );
  }
}

class _RewardItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value, label;
  const _RewardItem({required this.icon, required this.color,
    required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: color, size: 28),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: WildDeckTheme.textMuted, fontSize: 11)),
    ]);
  }
}

class _XPProgress extends StatelessWidget {
  final int xpEarned, total, prev;
  const _XPProgress({required this.xpEarned, required this.total, required this.prev});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Level Progress', style: TextStyle(color: WildDeckTheme.textSecond, fontSize: 13)),
        Text('${prev + xpEarned} / $total XP',
          style: const TextStyle(color: WildDeckTheme.textMuted, fontSize: 12)),
      ]),
      const SizedBox(height: 8),
      XPBar(xp: prev + xpEarned, xpToNext: total, height: 8, showLabel: false),
    ]);
  }
}
