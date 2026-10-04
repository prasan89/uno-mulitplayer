import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wilddeck/core/router/wilddeck_router.dart';
import 'package:wilddeck/core/services/wilddeck_services.dart';
import 'package:wilddeck/shared/theme/wilddeck_theme.dart';
import 'package:wilddeck/shared/widgets/wilddeck_components.dart';

class GameLobbyScreen extends StatefulWidget {
  final String gameId;
  const GameLobbyScreen({super.key, required this.gameId});

  @override
  State<GameLobbyScreen> createState() => _GameLobbyScreenState();
}

class _GameLobbyScreenState extends State<GameLobbyScreen> {
  bool _starting = false;

  static final List<WildGamePlayer> _mockSeats = [
    const WildGamePlayer(id: 'me',  displayName: 'WildAce',   cardCount: 0),
    const WildGamePlayer(id: 'p2',  displayName: 'Blaze',     cardCount: 0),
    WildGamePlayer(id: 'p3', displayName: 'Bot Alpha', cardCount: 0, isBot: true),
    WildGamePlayer(id: 'p4', displayName: 'Bot Beta',  cardCount: 0, isBot: true),
  ];

  Future<void> _startGame() async {
    setState(() => _starting = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) context.pushReplacement(WildRoutes.gamePath(widget.gameId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: WildDeckTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WildDeckTopBar(title: 'Game Lobby'),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _RoomBadge(gameId: widget.gameId),
                      const SizedBox(height: 28),
                      ..._mockSeats.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _LobbySeat(
                          player: e.value,
                          seatIndex: e.key + 1,
                          isMe: e.value.id == 'me',
                        ),
                      )),
                      const SizedBox(height: 8),
                      _ReadyBanner(),
                      const Spacer(),
                      PrimaryButton(
                        label: 'START GAME',
                        icon: Icons.play_arrow_rounded,
                        isLoading: _starting,
                        onPressed: _startGame,
                      ),
                      const SizedBox(height: 12),
                      SecondaryButton(
                        label: 'Leave Lobby',
                        onPressed: () => Navigator.of(context).pop(),
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

class _RoomBadge extends StatelessWidget {
  final String gameId;
  const _RoomBadge({required this.gameId});

  @override
  Widget build(BuildContext context) {
    final short = gameId.length > 10 ? gameId.substring(0, 10) : gameId;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: WildDeckTheme.navySurface,
        borderRadius: WildDeckTheme.radiusMedium,
        border: Border.all(color: WildDeckTheme.navyBorder),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.tag, color: WildDeckTheme.textMuted, size: 14),
        const SizedBox(width: 6),
        Text('Room  $short', style: const TextStyle(
          color: WildDeckTheme.textSecond, fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _ReadyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: WildDeckTheme.success.withValues(alpha: 0.1),
        borderRadius: WildDeckTheme.radiusMedium,
        border: Border.all(color: WildDeckTheme.success.withValues(alpha: 0.4)),
      ),
      child: const Center(
        child: Text('4/4 Players Ready', style: TextStyle(
          color: WildDeckTheme.success, fontSize: 14, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _LobbySeat extends StatelessWidget {
  final WildGamePlayer player;
  final int seatIndex;
  final bool isMe;

  const _LobbySeat({required this.player, required this.seatIndex, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? WildDeckTheme.gold.withValues(alpha: 0.06) : WildDeckTheme.navySurface,
        borderRadius: WildDeckTheme.radiusMedium,
        border: Border.all(
          color: isMe ? WildDeckTheme.gold.withValues(alpha: 0.3) : WildDeckTheme.navyBorder),
      ),
      child: Row(children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(color: WildDeckTheme.navyCard, borderRadius: BorderRadius.circular(6)),
          child: Center(child: Text('$seatIndex', style: const TextStyle(
            color: WildDeckTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w700))),
        ),
        const SizedBox(width: 12),
        PlayerAvatar(displayName: player.displayName, size: 38, isBot: player.isBot),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(isMe ? 'You' : player.displayName, style: TextStyle(
              color: isMe ? WildDeckTheme.gold : Colors.white,
              fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            if (player.isBot)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: WildDeckTheme.navyCard, borderRadius: BorderRadius.circular(4)),
                child: const Text('AI', style: TextStyle(
                  color: WildDeckTheme.textMuted, fontSize: 9, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 2),
          Text(player.isBot ? 'AI Player' : 'Human',
            style: const TextStyle(color: WildDeckTheme.textMuted, fontSize: 11)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: WildDeckTheme.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: WildDeckTheme.success.withValues(alpha: 0.4))),
          child: const Text('READY', style: TextStyle(
            color: WildDeckTheme.success, fontSize: 10,
            fontWeight: FontWeight.w800, letterSpacing: 1)),
        ),
      ]),
    );
  }
}
