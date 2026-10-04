import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:wilddeck/core/providers/auth_provider.dart';
import 'package:wilddeck/core/providers/game_provider.dart' show apiBaseUrlProvider;
import 'package:wilddeck/core/providers/wilddeck_providers.dart';
import 'package:wilddeck/core/router/wilddeck_router.dart';
import 'package:wilddeck/core/services/real_matchmaking_service.dart';
import 'package:wilddeck/shared/theme/wilddeck_theme.dart';
import 'package:wilddeck/shared/widgets/wilddeck_components.dart';

/// Game Lobby screen — shows real-time player list with ready states.
///
/// Connects to the backend WebSocket on the match's game_id room and listens
/// for `lobby_updated`, `player_ready`, `player_unready`, `game_starting`, and
/// `game_started` events.  All state mutations go through the server —
/// the client never trusts its own player ID from state, only from Firebase auth.
class GameLobbyScreen extends ConsumerStatefulWidget {
  final String gameId;
  const GameLobbyScreen({required this.gameId, super.key});

  @override
  ConsumerState<GameLobbyScreen> createState() => _GameLobbyScreenState();
}

class _GameLobbyScreenState extends ConsumerState<GameLobbyScreen> {
  LobbyState? _lobby;
  bool _isReady = false;
  bool _starting = false;

  WebSocketChannel? _ws;
  StreamSubscription<dynamic>? _wsSub;
  String? _myPlayerId;

  @override
  void initState() {
    super.initState();
    _initLobby();
  }

  Future<void> _initLobby() async {
    final authNotifier = ref.read(authProvider.notifier);
    try {
      final token = await authNotifier.getIdToken();
      final user = ref.read(currentUserProvider);
      _myPlayerId = user?.uid;

      final baseUrl = ref.read(apiBaseUrlProvider);
      final wsBase = baseUrl
          .replaceFirst('https://', 'wss://')
          .replaceFirst('http://', 'ws://');
      final wsUri = Uri.parse('$wsBase/ws').replace(
        queryParameters: {'game_id': widget.gameId, 'token': token},
      );

      _ws = WebSocketChannel.connect(wsUri);
      _wsSub = _ws!.stream.listen(
        _onWsMessage,
        onError: (Object e) => debugPrint('Lobby WS error: $e'),
        onDone: () => debugPrint('Lobby WS closed'),
      );
    } catch (e) {
      debugPrint('Lobby initLobby error: $e');
      // Fall back to a minimal placeholder if auth fails.
      if (mounted) {
        setState(() {
          _lobby = LobbyState(
            gameId: widget.gameId,
            roomCode: widget.gameId.length > 6 ? widget.gameId.substring(0, 6) : widget.gameId,
            players: const [],
            readyCount: 0,
            maxPlayers: 4,
          );
        });
      }
    }
  }

  void _onWsMessage(dynamic raw) {
    if (raw is! String) return;
    try {
      final msg = jsonDecode(raw) as Map<String, dynamic>;
      final type = msg['type'] as String? ?? '';
      final payload = msg['payload'] as Map<String, dynamic>? ?? {};

      switch (type) {
        case 'lobby_updated':
          final lobby = LobbyState.fromPayload(payload);
          // Determine my own ready state from the server truth.
          final me = lobby.players
              .where((p) => p.playerId == _myPlayerId)
              .toList();
          final myReady = me.isNotEmpty && me.first.isReady;
          if (mounted) {
            setState(() {
              _lobby = lobby;
              _isReady = myReady;
            });
          }
          break;

        case 'player_ready':
        case 'player_unready':
          // Incremental update handled by lobby_updated broadcast; skip.
          break;

        case 'game_starting':
          if (mounted) setState(() => _starting = true);
          break;

        case 'game_started':
          final gameId = payload['game_id'] as String? ?? widget.gameId;
          if (mounted) {
            context.pushReplacement(WildRoutes.gamePath(gameId));
          }
          break;
      }
    } catch (e) {
      debugPrint('Lobby WS parse error: $e');
    }
  }

  Future<void> _toggleReady() async {
    final lobbyService = ref.read(realLobbyServiceProvider);
    try {
      await lobbyService.setReady(
        matchId: widget.gameId,
        ready: !_isReady,
      );
      // State will be updated via the lobby_updated WebSocket broadcast.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update ready state: $e')),
        );
      }
    }
  }

  Future<void> _startGame() async {
    final lobbyService = ref.read(realLobbyServiceProvider);
    setState(() => _starting = true);
    try {
      await lobbyService.startLobby(matchId: widget.gameId);
      // Navigation is triggered by the game_started WS event.
    } catch (e) {
      if (mounted) {
        setState(() => _starting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot start: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _ws?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lobby = _lobby;
    final roomCode = lobby?.roomCode ?? widget.gameId;
    final players = lobby?.players ?? [];
    final readyCount = lobby?.readyCount ?? 0;
    final maxPlayers = lobby?.maxPlayers ?? 4;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: WildDeckTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const WildDeckTopBar(title: 'Game Lobby'),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _RoomBadge(roomCode: roomCode),
                      const SizedBox(height: 28),
                      if (players.isEmpty)
                        const Expanded(
                          child: Center(
                            child: CircularProgressIndicator(color: WildDeckTheme.gold),
                          ),
                        )
                      else ...[
                        ...players.asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _LobbySeat(
                            player: e.value,
                            isMe: e.value.playerId == _myPlayerId,
                          ),
                        )),
                        const SizedBox(height: 8),
                        _ReadyBanner(readyCount: readyCount, maxPlayers: maxPlayers),
                      ],
                      const Spacer(),
                      // Ready toggle.
                      PrimaryButton(
                        label: _isReady ? 'UNREADY' : 'READY UP',
                        icon: _isReady ? Icons.cancel_outlined : Icons.check_circle_outline,
                        onPressed: _toggleReady,
                      ),
                      const SizedBox(height: 12),
                      // Start game (host only — show when enough players ready).
                      if (readyCount >= 2)
                        PrimaryButton(
                          label: 'START GAME',
                          icon: Icons.play_arrow_rounded,
                          isLoading: _starting,
                          onPressed: _starting ? null : _startGame,
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
  final String roomCode;
  const _RoomBadge({required this.roomCode});

  @override
  Widget build(BuildContext context) {
    final short = roomCode.length > 6 ? roomCode.substring(0, 6) : roomCode;
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
  final int readyCount;
  final int maxPlayers;

  const _ReadyBanner({required this.readyCount, required this.maxPlayers});

  @override
  Widget build(BuildContext context) {
    final allReady = readyCount >= maxPlayers;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: (allReady ? WildDeckTheme.success : WildDeckTheme.gold).withValues(alpha: 0.1),
        borderRadius: WildDeckTheme.radiusMedium,
        border: Border.all(
          color: (allReady ? WildDeckTheme.success : WildDeckTheme.gold).withValues(alpha: 0.4)),
      ),
      child: Center(
        child: Text('$readyCount / $maxPlayers Players Ready', style: TextStyle(
          color: allReady ? WildDeckTheme.success : WildDeckTheme.gold,
          fontSize: 14, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _LobbySeat extends StatelessWidget {
  final LobbyPlayer player;
  final bool isMe;

  const _LobbySeat({required this.player, required this.isMe});

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
          child: Center(child: Text('${player.seatIndex + 1}', style: const TextStyle(
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
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: player.isReady
                ? WildDeckTheme.success.withValues(alpha: 0.12)
                : WildDeckTheme.navyCard,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: player.isReady
                  ? WildDeckTheme.success.withValues(alpha: 0.4)
                  : WildDeckTheme.navyBorder)),
          child: Text(
            player.isReady ? 'READY' : 'WAITING',
            style: TextStyle(
              color: player.isReady ? WildDeckTheme.success : WildDeckTheme.textMuted,
              fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
        ),
      ]),
    );
  }
}
