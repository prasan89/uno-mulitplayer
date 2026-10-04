import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wilddeck/core/router/wilddeck_router.dart';
import 'package:wilddeck/features/game/vs_ai_game_screen.dart';
import 'package:wilddeck/shared/theme/wilddeck_theme.dart';
import 'package:wilddeck/shared/widgets/wilddeck_components.dart';

/// Result screen shown after a VS AI game ends.
class VsAIResultScreen extends StatefulWidget {
  final VsAIResultArgs args;
  const VsAIResultScreen({required this.args, super.key});

  @override
  State<VsAIResultScreen> createState() => _VsAIResultScreenState();
}

class _VsAIResultScreenState extends State<VsAIResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late AnimationController _shimmerCtrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  bool get _didWin => widget.args.winnerId == widget.args.humanPlayerId;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _shimmerCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    unawaited(_shimmerCtrl.repeat());
    _scale = CurvedAnimation(parent: _entranceCtrl, curve: Curves.elasticOut);
    _fade  = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeIn);
    unawaited(_entranceCtrl.forward());
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  void _playAgain() {
    // Navigate back to a fresh VS AI game with the same configuration.
    context.go(WildRoutes.vsAiSetup);
  }

  @override
  Widget build(BuildContext context) {
    final winnerId = widget.args.winnerId;
    final winnerName = _didWin
        ? 'You'
        : widget.args.gameArgs.bots
            .where((b) => b.id == winnerId)
            .map((b) => b.name)
            .firstOrNull ?? 'AI';

    return Scaffold(
      body: DecoratedBox(
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
                ScaleTransition(
                  scale: _scale,
                  child: _ResultBadge(didWin: _didWin),
                ),
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
                Text(_didWin ? 'You beat the AI opponents!' : '$winnerName wins this round',
                  style: const TextStyle(color: WildDeckTheme.textMuted, fontSize: 14)),
                const SizedBox(height: 32),
                _RewardsPanel(didWin: _didWin),
                const Spacer(),
                PrimaryButton(
                  label: 'PLAY AGAIN',
                  icon: Icons.replay_rounded,
                  onPressed: _playAgain,
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
  final bool didWin;
  const _RewardsPanel({required this.didWin});

  @override
  Widget build(BuildContext context) {
    final coins = didWin ? 150 : 25;
    final xp    = didWin ? 80  : 15;

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
          _RewardItem(
            icon: Icons.monetization_on_rounded,
            color: WildDeckTheme.gold,
            value: '+$coins', label: 'Coins'),
          Container(width: 1, height: 40, color: WildDeckTheme.navyBorder),
          _RewardItem(
            icon: Icons.star_rounded,
            color: WildDeckTheme.cardBlue,
            value: '+$xp', label: 'XP'),
          if (didWin) ...[
            Container(width: 1, height: 40, color: WildDeckTheme.navyBorder),
            const _RewardItem(
              icon: Icons.local_fire_department_rounded,
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
  final String value;
  final String label;
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
