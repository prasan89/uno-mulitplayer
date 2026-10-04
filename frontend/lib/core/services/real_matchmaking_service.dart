import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:wilddeck/core/services/wilddeck_services.dart';

// ─── Lobby domain types ───────────────────────────────────────────────────────

/// One player slot in a lobby as reported by the server.
class LobbyPlayer {
  final String playerId;
  final String displayName;
  final int seatIndex;
  final bool isBot;
  final bool isReady;

  const LobbyPlayer({
    required this.playerId,
    required this.displayName,
    required this.seatIndex,
    required this.isBot,
    required this.isReady,
  });

  factory LobbyPlayer.fromJson(Map<String, dynamic> j) => LobbyPlayer(
        playerId: j['player_id'] as String? ?? '',
        displayName: j['display_name'] as String? ?? 'Player',
        seatIndex: j['seat_index'] as int? ?? 0,
        isBot: j['is_bot'] as bool? ?? false,
        isReady: j['is_ready'] as bool? ?? false,
      );
}

/// Full snapshot of a match lobby.
class LobbyState {
  final String gameId;
  final String roomCode;
  final List<LobbyPlayer> players;
  final int readyCount;
  final int maxPlayers;
  final bool gameStarting;
  final bool gameStarted;

  const LobbyState({
    required this.gameId,
    required this.roomCode,
    required this.players,
    required this.readyCount,
    required this.maxPlayers,
    this.gameStarting = false,
    this.gameStarted = false,
  });

  LobbyState copyWith({
    List<LobbyPlayer>? players,
    int? readyCount,
    bool? gameStarting,
    bool? gameStarted,
  }) =>
      LobbyState(
        gameId: gameId,
        roomCode: roomCode,
        players: players ?? this.players,
        readyCount: readyCount ?? this.readyCount,
        maxPlayers: maxPlayers,
        gameStarting: gameStarting ?? this.gameStarting,
        gameStarted: gameStarted ?? this.gameStarted,
      );

  /// Parse a `lobby_updated` WebSocket payload.
  factory LobbyState.fromPayload(Map<String, dynamic> payload) {
    final players = (payload['players'] as List<dynamic>? ?? [])
        .map((p) => LobbyPlayer.fromJson(p as Map<String, dynamic>))
        .toList();
    return LobbyState(
      gameId: payload['game_id'] as String? ?? '',
      roomCode: payload['room_code'] as String? ?? '',
      players: players,
      readyCount: payload['ready_count'] as int? ?? 0,
      maxPlayers: payload['max_players'] as int? ?? 4,
    );
  }
}

// ─── Real matchmaking service ─────────────────────────────────────────────────

/// Implements [IMatchmakingService] against the real WildDeck backend.
///
/// Call flow:
///  1. `searchForMatch` → POST /api/match/queue, then opens a WebSocket
///     connection and listens for `match_found` to emit [MatchmakingStatus.found].
///  2. `cancelSearch`   → DELETE /api/match/queue + close WebSocket.
///  3. `createPrivateRoom` → POST /api/match → returns room_code.
///  4. `joinPrivateRoom`   → POST /api/match/{code}/join.
class RealMatchmakingService implements IMatchmakingService {
  final String baseUrl;
  final Future<String> Function() getToken;

  final http.Client _http;
  final StreamController<MatchmakingState> _ctrl =
      StreamController<MatchmakingState>.broadcast();

  WebSocketChannel? _ws;
  StreamSubscription<dynamic>? _wsSub;
  Timer? _ticker;
  int _elapsedSeconds = 0;
  bool _cancelled = false;

  RealMatchmakingService({
    required this.baseUrl,
    required this.getToken,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  // ─── IMatchmakingService ─────────────────────────────────────────────────────

  @override
  Stream<MatchmakingState> searchForMatch({
    required String gameMode,
    required int maxPlayers,
    required bool fillWithBots,
  }) {
    _cancelled = false;
    _elapsedSeconds = 0;
    _startTicker();
    _emitSearching(maxPlayers);

    getToken().then((token) async {
      if (_cancelled) return;
      await _joinQueue(token: token, gameMode: gameMode);
      if (_cancelled) return;
      _connectWs(token: token, maxPlayers: maxPlayers);
    }).catchError((Object e, StackTrace st) {
      developer.log('searchForMatch error: $e\n$st', name: 'RealMatchmakingService');
      if (!_ctrl.isClosed) _ctrl.addError(e, st);
    });

    return _ctrl.stream;
  }

  @override
  Future<void> cancelSearch() async {
    _cancelled = true;
    _ticker?.cancel();
    _closeWs();
    await _leaveQueue();
    if (!_ctrl.isClosed) {
      _ctrl.add(const MatchmakingState(
        status: MatchmakingStatus.cancelled,
        slots: [],
      ));
    }
  }

  @override
  Future<String> createPrivateRoom() async {
    final token = await getToken();
    final resp = await _http.post(
      Uri.parse('$baseUrl/api/match'),
      headers: _headers(token),
      body: jsonEncode({'game_mode': 'private'}),
    );
    _checkStatus(resp, 'createPrivateRoom');
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return body['room_code'] as String? ?? '';
  }

  @override
  Future<void> joinPrivateRoom(String roomCode) async {
    final token = await getToken();
    final resp = await _http.post(
      Uri.parse('$baseUrl/api/match/$roomCode/join'),
      headers: _headers(token),
      body: jsonEncode({}),
    );
    _checkStatus(resp, 'joinPrivateRoom');
  }

  void dispose() {
    _ticker?.cancel();
    _closeWs();
    _ctrl.close();
    _http.close();
  }

  // ─── internals ───────────────────────────────────────────────────────────────

  Future<void> _joinQueue({required String token, required String gameMode}) async {
    final resp = await _http.post(
      Uri.parse('$baseUrl/api/match/queue'),
      headers: _headers(token),
      body: jsonEncode({'game_mode': gameMode, 'elo': 1000}),
    );
    if (resp.statusCode == 409) return; // already queued — non-fatal
    _checkStatus(resp, '_joinQueue');
  }

  Future<void> _leaveQueue() async {
    try {
      final token = await getToken();
      await _http.delete(
        Uri.parse('$baseUrl/api/match/queue'),
        headers: _headers(token),
      );
    } catch (e) {
      developer.log('leaveQueue ignored: $e', name: 'RealMatchmakingService');
    }
  }

  void _connectWs({required String token, required int maxPlayers}) {
    final wsBase = baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    // Use game_id=matchmaking; the hub accepts any valid ID — match_found is
    // delivered via SendToClient (keyed by Firebase UID), not by room broadcast.
    final wsUri = Uri.parse('$wsBase/ws')
        .replace(queryParameters: {'game_id': 'matchmaking', 'token': token});

    developer.log('WS connecting: $wsUri', name: 'RealMatchmakingService');

    try {
      _ws = WebSocketChannel.connect(wsUri);
      _wsSub = _ws!.stream.listen(
        (data) => _onWsMessage(data, maxPlayers: maxPlayers),
        onError: (Object e) =>
            developer.log('WS error: $e', name: 'RealMatchmakingService'),
        onDone: () =>
            developer.log('WS done', name: 'RealMatchmakingService'),
      );
    } catch (e) {
      developer.log('WS connect error: $e', name: 'RealMatchmakingService');
    }
  }

  void _onWsMessage(dynamic raw, {required int maxPlayers}) {
    if (raw is! String) return;
    try {
      final msg = jsonDecode(raw) as Map<String, dynamic>;
      final type = msg['type'] as String? ?? '';
      final payload = msg['payload'] as Map<String, dynamic>? ?? {};

      if (type == 'match_found') {
        _ticker?.cancel();
        final gameId = payload['game_id'] as String? ?? '';
        final rawPlayers = payload['players'] as List<dynamic>? ?? [];
        final slots = rawPlayers.asMap().entries.map((e) {
          return MatchmakingSlot(
            index: e.key,
            isOccupied: true,
            playerName: e.value as String?,
          );
        }).toList();

        _ctrl.add(MatchmakingState(
          status: MatchmakingStatus.found,
          slots: slots,
          matchId: gameId,
          elapsedSeconds: _elapsedSeconds,
        ));
        developer.log('match_found gameId=$gameId', name: 'RealMatchmakingService');
      }
    } catch (e) {
      developer.log('WS parse error: $e', name: 'RealMatchmakingService');
    }
  }

  void _emitSearching(int maxPlayers) {
    final slots = List<MatchmakingSlot>.generate(
      maxPlayers,
      (i) => i == 0
          ? const MatchmakingSlot(
              index: 0,
              isOccupied: true,
              isCurrentPlayer: true,
              playerName: 'You',
            )
          : MatchmakingSlot.empty(i),
    );
    _ctrl.add(MatchmakingState(
      status: MatchmakingStatus.searching,
      slots: slots,
      elapsedSeconds: _elapsedSeconds,
    ));
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_cancelled) _elapsedSeconds++;
    });
  }

  void _closeWs() {
    _wsSub?.cancel();
    _wsSub = null;
    _ws?.sink.close();
    _ws = null;
  }

  void _checkStatus(http.Response r, String op) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('$op failed: ${r.statusCode} ${r.body}');
    }
  }

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
}

// ─── Real lobby service ───────────────────────────────────────────────────────

/// Handles lobby-specific REST calls (ready/unready/start) and provides helpers
/// to parse lobby WebSocket events into [LobbyState] snapshots.
class RealLobbyService {
  final String baseUrl;
  final Future<String> Function() getToken;
  final http.Client _http;

  RealLobbyService({
    required this.baseUrl,
    required this.getToken,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  Future<void> setReady({required String matchId, required bool ready}) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/api/match/$matchId/ready');
    final resp = ready
        ? await _http.post(uri, headers: _authHeaders(token))
        : await _http.delete(uri, headers: _authHeaders(token));
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('setReady($ready) failed: ${resp.statusCode} ${resp.body}');
    }
  }

  Future<void> startLobby({required String matchId}) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/api/match/$matchId/start');
    final resp = await _http.post(
      uri,
      headers: _authHeaders(token),
      body: jsonEncode({}),
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('startLobby failed: ${resp.statusCode} ${resp.body}');
    }
  }

  void dispose() => _http.close();

  Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
}
