import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/wilddeck_router.dart';
import '../../shared/theme/wilddeck_theme.dart';
import '../../shared/widgets/wilddeck_components.dart';

/// Game Mode selection screen.
class GameModeScreen extends StatelessWidget {
  const GameModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: WildDeckTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WildDeckTopBar(title: 'Choose Mode'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      _ModeCard(
                        title: 'CLASSIC MATCH',
                        subtitle: '2–4 players  •  Standard rules',
                        description: 'The full WildDeck experience. Match ends when one player empties their hand.',
                        icon: Icons.style_rounded,
                        iconColor: WildDeckTheme.cardRed,
                        badge: 'POPULAR',
                        badgeColor: WildDeckTheme.cardRed,
                        onTap: () => context.push(
                          '${WildRoutes.matchmaking}?mode=classic',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ModeCard(
                        title: 'QUICK MATCH',
                        subtitle: 'Fast matchmaking  •  2–4 players',
                        description: 'Real players preferred. AI fills empty seats so you start faster.',
                        icon: Icons.bolt,
                        iconColor: WildDeckTheme.cardYellow,
                        badge: 'FAST',
                        badgeColor: WildDeckTheme.cardYellow,
                        onTap: () => context.push(
                          '${WildRoutes.matchmaking}?mode=quick',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ModeCard(
                        title: '2v2 TEAM',
                        subtitle: '4 players  •  Team play',
                        description: 'Play with a partner against another team. Coordinate your wild cards.',
                        icon: Icons.group_rounded,
                        iconColor: WildDeckTheme.cardBlue,
                        badge: 'SOON',
                        badgeColor: WildDeckTheme.textMuted,
                        locked: true,
                        onTap: null,
                      ),
                      const SizedBox(height: 16),
                      _ModeCard(
                        title: 'PRIVATE ROOM',
                        subtitle: 'Play with friends  •  Custom rules',
                        description: 'Create a room and share the code. Up to 4 players.',
                        icon: Icons.lock_outline_rounded,
                        iconColor: WildDeckTheme.cardGreen,
                        onTap: () => context.push(
                          '${WildRoutes.matchmaking}?mode=private',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ModeCard(
                        title: 'TOURNAMENT',
                        subtitle: 'Bracket style  •  Prize pool',
                        description: 'Compete in scheduled tournaments for big coin prizes.',
                        icon: Icons.emoji_events_rounded,
                        iconColor: WildDeckTheme.gold,
                        badge: 'SOON',
                        badgeColor: WildDeckTheme.textMuted,
                        locked: true,
                        onTap: null,
                      ),
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
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color iconColor;
  final String? badge;
  final Color? badgeColor;
  final bool locked;
  final VoidCallback? onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.iconColor,
    this.badge,
    this.badgeColor,
    this.locked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: locked ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: locked ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: WildDeckTheme.navySurface,
            borderRadius: WildDeckTheme.radiusLarge,
            border: Border.all(
              color: locked ? WildDeckTheme.navyBorder : iconColor.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: locked ? null : WildDeckTheme.cardShadow(iconColor),
          ),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: WildDeckTheme.radiusMedium,
                ),
                child: Icon(icon, color: iconColor, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title, style: const TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800,
                        )),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: (badgeColor ?? WildDeckTheme.cardRed).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: (badgeColor ?? WildDeckTheme.cardRed).withOpacity(0.5),
                              ),
                            ),
                            child: Text(badge!, style: TextStyle(
                              color: badgeColor ?? WildDeckTheme.cardRed,
                              fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1,
                            )),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(subtitle, style: const TextStyle(
                      color: WildDeckTheme.textMuted, fontSize: 11, letterSpacing: 0.3,
                    )),
                    const SizedBox(height: 6),
                    Text(description, style: const TextStyle(
                      color: WildDeckTheme.textSecond, fontSize: 12,
                    )),
                  ],
                ),
              ),
              if (!locked)
                const Icon(Icons.chevron_right_rounded, color: WildDeckTheme.textMuted)
              else
                const Icon(Icons.lock_outline, color: WildDeckTheme.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
