import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

/// Low-level REST client for the game API.
///
/// All methods throw [ApiException] on non-2xx responses or network failures.
class ApiClient {
  final String baseUrl;
  final http.Client _httpClient;

  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  // ---------------------------------------------------------------------------
  // Core helpers
  // ---------------------------------------------------------------------------

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

  Future<Map<String, dynamic>> _get(
    String path, {
    required String token,
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParams,
    );
    developer.log('GET $uri', name: 'ApiClient');

    final response = await _httpClient.get(uri, headers: _headers(token));
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    required String token,
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    developer.log('POST $uri', name: 'ApiClient');

    final response = await _httpClient.post(
      uri,
      headers: _headers(token),
      body: jsonEncode(body),
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> _patch(
    String path, {
    required String token,
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    developer.log('PATCH $uri', name: 'ApiClient');

    final response = await _httpClient.patch(
      uri,
      headers: _headers(token),
      body: jsonEncode(body),
    );
    return _parseResponse(response);
  }

  Future<void> _delete(
    String path, {
    required String token,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    developer.log('DELETE $uri', name: 'ApiClient');

    final response = await _httpClient.delete(uri, headers: _headers(token));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.body,
      );
    }
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message;
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        message = json['message'] as String? ?? response.body;
      } catch (_) {
        message = response.body;
      }
      throw ApiException(statusCode: response.statusCode, message: message);
    }

    if (response.body.isEmpty) return {};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // Game endpoints
  // ---------------------------------------------------------------------------

  /// List all available public games.
  Future<List<Map<String, dynamic>>> listGames({required String token}) async {
    final response = await _get('/games', token: token);
    final games = response['games'];
    if (games is List) {
      return games.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Create a new game room.
  Future<Map<String, dynamic>> createGame({
    required String token,
    int maxPlayers = 4,
    bool allowBots = false,
  }) async {
    return _post(
      '/games',
      token: token,
      body: {'maxPlayers': maxPlayers, 'allowBots': allowBots},
    );
  }

  /// Fetch the current snapshot of a game.
  Future<Map<String, dynamic>> getGame({
    required String token,
    required String gameId,
  }) async {
    return _get('/games/$gameId', token: token);
  }

  /// Join an existing game.
  Future<Map<String, dynamic>> joinGame({
    required String token,
    required String gameId,
  }) async {
    return _post('/games/$gameId/join', token: token, body: {});
  }

  /// Leave a game.
  Future<void> leaveGame({
    required String token,
    required String gameId,
  }) async {
    await _delete('/games/$gameId/leave', token: token);
  }

  /// Start a game (host only).
  Future<Map<String, dynamic>> startGame({
    required String token,
    required String gameId,
  }) async {
    return _post('/games/$gameId/start', token: token, body: {});
  }

  // ---------------------------------------------------------------------------
  // Player / profile endpoints
  // ---------------------------------------------------------------------------

  /// Fetch the current user's profile.
  Future<Map<String, dynamic>> getProfile({required String token}) async {
    return _get('/profile', token: token);
  }

  /// Update the current user's display name.
  Future<Map<String, dynamic>> updateDisplayName({
    required String token,
    required String displayName,
  }) async {
    return _patch('/profile', token: token, body: {'displayName': displayName});
  }

  void dispose() {
    _httpClient.close();
  }
}

/// Thrown whenever the server returns a non-2xx status.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
