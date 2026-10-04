import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wilddeck/core/router/wilddeck_router.dart';
import 'package:wilddeck/features/game/ai_game_service.dart';
import 'package:wilddeck/shared/theme/wilddeck_theme.dart';
import 'package:wilddeck/shared/widgets/wilddeck_components.dart';

/// VS AI setup screen — choose difficulty and opponent count, then start.
class VsAISetupScreen extends StatefulWidget {
  const VsAISetupScreen({super.key});

  @override
  State<VsAISetupScreen> createState() => _VsAISetupScreenState();
}

class _VsAISetupScreenState extends State<VsAISetupScreen> {
  AIDifficulty _difficulty = AIDifficulty.normal;
  int _botCount = 3;

  static const _difficulties = [
    (AIDifficulty.easy,   'EASY',   'Relaxed play for learning the game',     WildDeckTheme.cardGreen),
    (AIDifficulty.normal, 'NORMAL', 'Balanced opponents that feel natural',   WildDeckTheme.cardBlue),
    (AIDifficulty.hard,   'HARD',   'Competitive AI that reacts strategically', WildDeckTheme.cardRed),
  ];

  void _start() {
    // Build the bot list based on selected difficulty + count
    final bots = List.generate(_botCount, (i) {
      final personality = AIPersonalities.atSeat(i);
      return AIPlayer(
        id: 'bot_${personality.name.toLowerCase()}_$i',
        name: personality.name,
        difficulty: _difficulty,
        personality: personality,
      );
    });

    unawaited(context.push(
      WildRoutes.vsAiGame,
      extra: VsAIGameArgs(
        humanPlayerId: 'local_human',
        humanName: 'You',
        bots: bots,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: WildDeckTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const WildDeckTopBar(title: 'Play VS AI'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 4),
                      // --- Difficulty ---
                      const Text('DIFFICULTY', style: TextStyle(
                        color: WildDeckTheme.textMuted, fontSize: 11,
                        fontWeight: FontWeight.w700, letterSpacing: 1.5,
                      )),
                      const SizedBox(height: 12),
                      ..._difficulties.map((entry) {
                        final (diff, label, desc, color) = entry;
                        final selected = _difficulty == diff;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GestureDetector(
                            onTap: () => setState(() => _difficulty = diff),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: selected
                                    ? color.withValues(alpha: 0.12)
                                    : WildDeckTheme.navySurface,
                                borderRadius: WildDeckTheme.radiusLarge,
                                border: Border.all(
                                  color: selected ? color : WildDeckTheme.navyBorder,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.18),
                                    borderRadius: WildDeckTheme.radiusMedium,
                                  ),
                                  child: Icon(
                                    diff == AIDifficulty.easy
                                        ? Icons.sentiment_satisfied_rounded
                                        : diff == AIDifficulty.normal
                                            ? Icons.psychology_rounded
                                            : Icons.whatshot_rounded,
                                    color: color, size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(label, style: TextStyle(
                                        color: selected ? color : Colors.white,
                                        fontSize: 14, fontWeight: FontWeight.w800,
                                      )),
                                      const SizedBox(height: 3),
                                      Text(desc, style: const TextStyle(
                                        color: WildDeckTheme.textSecond, fontSize: 12,
                                      )),
                                    ],
                                  ),
                                ),
                                if (selected)
                                  Icon(Icons.check_circle_rounded, color: color, size: 22),
                              ]),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                      // --- Opponent count ---
                      const Text('OPPONENTS', style: TextStyle(
                        color: WildDeckTheme.textMuted, fontSize: 11,
                        fontWeight: FontWeight.w700, letterSpacing: 1.5,
                      )),
                      const SizedBox(height: 12),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: WildDeckTheme.navySurface,
                          borderRadius: WildDeckTheme.radiusLarge,
                          border: Border.all(color: WildDeckTheme.navyBorder),
                        ),
                        child: Row(
                          children: [1, 2, 3].map((count) {
                            final selected = _botCount == count;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _botCount = count),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? WildDeckTheme.cardBlue.withValues(alpha: 0.15)
                                        : Colors.transparent,
                                    borderRadius: WildDeckTheme.radiusLarge,
                                    border: selected
                                        ? Border.all(color: WildDeckTheme.cardBlue, width: 1.5)
                                        : null,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('$count', style: TextStyle(
                                        color: selected ? WildDeckTheme.cardBlue : Colors.white,
                                        fontSize: 24, fontWeight: FontWeight.w900,
                                      )),
                                      const SizedBox(height: 4),
                                      Text(count == 1 ? '1v1' : '1v$count', style: const TextStyle(
                                        color: WildDeckTheme.textMuted, fontSize: 11,
                                      )),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // --- AI Opponents Preview ---
                      const Text('YOUR OPPONENTS', style: TextStyle(
                        color: WildDeckTheme.textMuted, fontSize: 11,
                        fontWeight: FontWeight.w700, letterSpacing: 1.5,
                      )),
                      const SizedBox(height: 12),
                      ..._buildOpponentPreviews(),
                      const SizedBox(height: 28),
                      PrimaryButton(
                        label: 'START GAME',
                        icon: Icons.play_arrow_rounded,
                        onPressed: _start,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOpponentPreviews() {
    return List.generate(_botCount, (i) {
      final p = AIPersonalities.atSeat(i);
      final traitLabel = i == 0
          ? 'Aggressive'
          : i == 1
              ? 'Strategic'
              : i == 2
                  ? 'Casual'
                  : 'Risk Taker';
      final traitColor = i == 0
          ? WildDeckTheme.cardRed
          : i == 1
              ? WildDeckTheme.cardBlue
              : i == 2
                  ? WildDeckTheme.cardGreen
                  : WildDeckTheme.gold;

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: WildDeckTheme.navySurface,
            borderRadius: WildDeckTheme.radiusMedium,
            border: Border.all(color: WildDeckTheme.navyBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              PlayerAvatar(displayName: p.name, size: 36, isBot: true),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: const TextStyle(
                    color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700,
                  )),
                  Text(traitLabel, style: TextStyle(
                    color: traitColor, fontSize: 11, fontWeight: FontWeight.w600,
                  )),
                ],
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: WildDeckTheme.textMuted.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('AI', style: TextStyle(
                  color: WildDeckTheme.textMuted, fontSize: 9,
                  fontWeight: FontWeight.w800, letterSpacing: 1,
                )),
              ),
            ]),
          ),
        ),
      );
    }).toList();
  }
}

/// Arguments passed when navigating to the VS AI game screen.
class VsAIGameArgs {
  final String humanPlayerId;
  final String humanName;
  final List<AIPlayer> bots;

  const VsAIGameArgs({
    required this.humanPlayerId,
    required this.humanName,
    required this.bots,
  });
}
