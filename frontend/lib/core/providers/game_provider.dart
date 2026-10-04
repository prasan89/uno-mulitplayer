import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/card.dart';
import '../models/game_state.dart';
import '../models/message.dart';
import '../network/api_client.dart';
import '../network/websocket_client.dart';
import 'auth_provider.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// The base URL used for REST calls (e.g. `https://api.example.com`).
final apiBaseUrlProvider = Provider<String>(
  (_) => const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  ),
);

/// The base URL used for WebSocket connections (e.g. `wss://api.example.com`).
final wsBaseUrlProvider = Provider<String>(
  (_) => const String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'ws://localhost:8080/ws',
  ),
);

final apiClientProvider = Provider<ApiClient>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  final client = ApiClient(baseUrl: baseUrl);
  ref.onDispose(client.dispose);
  return client;
});

final webSocketClientProvider = Provider<WebSocketClient>((ref) {
  final client = WebSocketClient();
  ref.onDispose(client.dispose);
  return client;
});

/// Primary game provider — holds the full [GameState] for the active game.
final gameProvider =
    AsyncNotifierProvider.autoDispose<GameNotifier, GameState?>(
  GameNotifier.new,
);

// ---------------------------------------------------------------------------
// GameNotifier
// ---------------------------------------------------------------------------

class GameNotifier extends AutoDisposeAsyncNotifier<GameState?> {
  String? _currentGameId;
  StreamSubscription<ServerMessage>? _messageSubscription;

  WebSocketClient get _ws => ref.read(webSocketClientProvider);
  ApiClient get _api => ref.read(apiClientProvider);
  AuthNotifier get _auth => ref.read(authProvider.notifier);

  @override
  Future<GameState?> build() async {
    ref.onDispose(_dispose);
    return null;
  }

  // ---------------------------------------------------------------------------
  // Public actions
  // ---------------------------------------------------------------------------

  /// Join (or re-join) a game by [gameId].
  Future<void> joinGame(String gameId) async {
    state = const AsyncLoading();

    try {
      final token = await _auth.getIdToken();
      _currentGameId = gameId;

      // Fetch initial snapshot via REST.
      final raw = await _api.joinGame(token: token, gameId: gameId);
      final snapshot = GameState.fromJson(raw);
      state = AsyncData(snapshot);

      // Open WebSocket for real-time updates.
      final wsUrl = ref.read(wsBaseUrlProvider);
      await _ws.connect(wsUrl, token);

      // Subscribe to incoming messages.
      _messageSubscription?.cancel();
      _messageSubscription = _ws.messages.listen(
        _handleServerMessage,
        onError: (Object e) {
          developer.log('WS message error: $e', name: 'GameNotifier');
        },
      );

      // Tell the server we want updates for this game.
      await _ws.send(ClientMessage.joinGame(gameId: gameId));

      developer.log('Joined game $gameId', name: 'GameNotifier');
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Play a card from the current player's hand.
  ///
  /// [cardId] is the [UnoCard.id] to play.
  /// [chosenColor] must be provided when playing a Wild or Wild Draw Four.
  Future<void> playCard(String cardId, {CardColor? chosenColor}) async {
    _ensureInGame();
    try {
      await _ws.send(
        ClientMessage.playCard(cardId: cardId, chosenColor: chosenColor),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Draw a card from the pile (or accept a pending draw penalty).
  Future<void> drawCard() async {
    _ensureInGame();
    try {
      await _ws.send(const ClientMessage.drawCard());
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Declare UNO before playing your second-to-last card.
  Future<void> callUno() async {
    _ensureInGame();
    try {
      await _ws.send(const ClientMessage.callUno());
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Challenge a Wild Draw Four (must be done immediately after it is played).
  Future<void> challengeDraw4() async {
    _ensureInGame();
    try {
      await _ws.send(const ClientMessage.challengeDraw4());
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Message handling
  // ---------------------------------------------------------------------------

  void _handleServerMessage(ServerMessage msg) {
    msg.map(
      gameState: (m) => _applyState(m.state),
      gameUpdate: (m) => _applyState(m.state),
      gameStarted: (m) => _applyState(m.state),
      error: (m) {
        developer.log('Server error ${m.code}: ${m.message}',
            name: 'GameNotifier');
        state = AsyncError(
          ServerError(code: m.code, message: m.message),
          StackTrace.current,
        );
      },
      pong: (_) {
        // handled by WebSocketClient internally
      },
      playerJoined: (m) {
        final current = state.valueOrNull;
        if (current == null) return;
        final updated = current.copyWith(
          players: [
            ...current.players.where((p) => p.id != m.player.id),
            m.player,
          ],
        );
        state = AsyncData(updated);
      },
      playerLeft: (m) {
        final current = state.valueOrNull;
        if (current == null) return;
        final updated = current.copyWith(
          players: current.players
              .map(
                (p) => p.id == m.playerId ? p.copyWith(isConnected: false) : p,
              )
              .toList(),
        );
        state = AsyncData(updated);
      },
      gameOver: (m) {
        final current = state.valueOrNull;
        if (current == null) return;
        final updated = current.copyWith(
          phase: GamePhase.finished,
          winnerId: m.winnerId,
        );
        state = AsyncData(updated);
      },
    );
  }

  void _applyState(GameState newState) {
    state = AsyncData(newState);
    developer.log(
      'Game state updated: phase=${newState.phase.name} '
      'turn=${newState.currentPlayerId}',
      name: 'GameNotifier',
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _ensureInGame() {
    if (_currentGameId == null) {
      throw StateError('Not currently in a game');
    }
  }

  void _dispose() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _currentGameId = null;
  }
}

// ---------------------------------------------------------------------------
// Ancillary types
// ---------------------------------------------------------------------------

/// Thrown by [GameNotifier] when the server returns an error message.
class ServerError implements Exception {
  final String code;
  final String message;

  const ServerError({required this.code, required this.message});

  @override
  String toString() => 'ServerError($code): $message';
}
