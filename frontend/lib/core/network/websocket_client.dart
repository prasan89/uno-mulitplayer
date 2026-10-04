import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:wilddeck/core/models/message.dart';

/// Manages a WebSocket connection to the game server.
///
/// Features:
/// - Automatic reconnection with exponential backoff (1s → 2s → 4s → 8s → 16s max)
/// - Periodic ping every 30 s; pong timeout treated as disconnect after 60 s
/// - Bearer-token authentication via the `Authorization` header (passed as a
///   subprotocol query-param on platforms where custom headers are not
///   supported by `web_socket_channel`).
class WebSocketClient {
  static const _maxBackoffSeconds = 16;
  static const _pingIntervalSeconds = 30;
  static const _pongTimeoutSeconds = 60;

  final _messageController = StreamController<ServerMessage>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _channelSubscription;
  Timer? _pingTimer;
  Timer? _pongTimeoutTimer;
  Timer? _reconnectTimer;

  String? _baseUrl;
  String? _token;

  bool _intentionalDisconnect = false;
  int _reconnectAttempt = 0;

  /// Emits every [ServerMessage] received from the server.
  Stream<ServerMessage> get messages => _messageController.stream;

  /// Connect to [baseUrl] (e.g. `wss://example.com`) using a Bearer [token].
  Future<void> connect(String baseUrl, String token) async {
    _baseUrl = baseUrl;
    _token = token;
    _intentionalDisconnect = false;
    _reconnectAttempt = 0;
    await _connect();
  }

  Future<void> _connect() async {
    if (_baseUrl == null || _token == null) return;

    final uri = Uri.parse(_baseUrl!).replace(
      queryParameters: {'token': _token!},
    );

    developer.log('WebSocket connecting to $uri', name: 'WebSocketClient');

    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      _reconnectAttempt = 0;

      _channelSubscription = _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
      );

      _startPing();
      developer.log('WebSocket connected', name: 'WebSocketClient');
    } catch (e) {
      developer.log('WebSocket connection error: $e', name: 'WebSocketClient');
      _scheduleReconnect();
    }
  }

  void _onData(dynamic raw) {
    _resetPongTimeout();
    if (raw is! String) return;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;

      // Handle pong specially before full decode
      if (json['type'] == 'pong') {
        _cancelPongTimeout();
        return;
      }

      final message = ServerMessage.fromJson(json);
      _messageController.add(message);
    } catch (e) {
      developer.log('Failed to parse server message: $e',
          name: 'WebSocketClient');
    }
  }

  void _onError(Object error) {
    developer.log('WebSocket error: $error', name: 'WebSocketClient');
  }

  void _onDone() {
    developer.log('WebSocket closed', name: 'WebSocketClient');
    _cleanup();
    if (!_intentionalDisconnect) {
      _scheduleReconnect();
    }
  }

  /// Send a [ClientMessage] to the server.
  Future<void> send(ClientMessage message) async {
    if (_channel == null) {
      throw StateError('WebSocket is not connected');
    }
    final payload = jsonEncode(message.toJson());
    _channel!.sink.add(payload);
  }

  /// Close the connection permanently (no reconnect).
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _cleanup();
    await _channel?.sink.close();
    _channel = null;
    developer.log('WebSocket disconnected', name: 'WebSocketClient');
  }

  // ---------------------------------------------------------------------------
  // Ping / Pong
  // ---------------------------------------------------------------------------

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(
      const Duration(seconds: _pingIntervalSeconds),
      (_) => _sendPing(),
    );
  }

  void _sendPing() {
    if (_channel == null) return;
    try {
      _channel!.sink.add(jsonEncode({'type': 'ping'}));
      _startPongTimeout();
    } catch (_) {}
  }

  void _startPongTimeout() {
    _pongTimeoutTimer?.cancel();
    _pongTimeoutTimer = Timer(
      const Duration(seconds: _pongTimeoutSeconds),
      () {
        developer.log('Pong timeout — treating as disconnect',
            name: 'WebSocketClient');
        _onDone();
      },
    );
  }

  void _resetPongTimeout() {
    if (_pongTimeoutTimer != null) {
      _startPongTimeout();
    }
  }

  void _cancelPongTimeout() {
    _pongTimeoutTimer?.cancel();
    _pongTimeoutTimer = null;
  }

  // ---------------------------------------------------------------------------
  // Reconnect
  // ---------------------------------------------------------------------------

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    final delaySeconds = _backoffDelay(_reconnectAttempt);
    _reconnectAttempt++;
    developer.log(
      'Reconnect attempt $_reconnectAttempt in ${delaySeconds}s',
      name: 'WebSocketClient',
    );
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), _connect);
  }

  int _backoffDelay(int attempt) {
    // 1, 2, 4, 8, 16, 16, 16 …
    final delay = 1 << attempt; // 2^attempt
    return delay.clamp(1, _maxBackoffSeconds);
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  void _cleanup() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _pongTimeoutTimer?.cancel();
    _pongTimeoutTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _channelSubscription?.cancel();
    _channelSubscription = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
