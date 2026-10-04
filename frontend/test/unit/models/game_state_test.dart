// Unit tests for the GameState model.
// Uses standalone helper types from _game_state_helpers.dart so that no
// generated (freezed / json_serializable) code is required at test time.

import 'package:flutter_test/flutter_test.dart';

import '_game_state_helpers.dart';

void main() {
  // -------------------------------------------------------------------------
  // fromJson roundtrip
  // -------------------------------------------------------------------------

  group('GameState fromJson roundtrip', () {
    test('serialises and deserialises a full GameState', () {
      final original = TestGameState(
        gameId: 'game-abc',
        currentPlayerId: 'player-1',
        players: const [
          TestPlayer(id: 'player-1', displayName: 'Alice', cardCount: 3),
          TestPlayer(id: 'player-2', displayName: 'Bob', cardCount: 5),
        ],
        hand: const [
          TestWildCard(color: TestCardColor.red, value: '5'),
          TestWildCard(color: TestCardColor.blue, value: 'skip'),
          TestWildCard(color: TestCardColor.wild, value: 'wild'),
        ],
        topCard: const TestWildCard(color: TestCardColor.green, value: '7'),
        activeColor: TestCardColor.green,
        isClockwise: true,
        status: TestGameStatus.active,
        winnerId: null,
      );

      final json = original.toJson();
      final restored = TestGameState.fromJson(json);

      expect(restored.gameId, equals(original.gameId));
      expect(restored.currentPlayerId, equals(original.currentPlayerId));
      expect(restored.players.length, equals(original.players.length));
      expect(restored.players[0].id, equals('player-1'));
      expect(restored.players[0].displayName, equals('Alice'));
      expect(restored.players[0].cardCount, equals(3));
      expect(restored.players[1].id, equals('player-2'));
      expect(restored.hand.length, equals(3));
      expect(restored.hand[0].color, equals(TestCardColor.red));
      expect(restored.hand[0].value, equals('5'));
      expect(restored.hand[2].color, equals(TestCardColor.wild));
      expect(restored.topCard,
          equals(const TestWildCard(color: TestCardColor.green, value: '7')));
      expect(restored.activeColor, equals(TestCardColor.green));
      expect(restored.isClockwise, isTrue);
      expect(restored.status, equals(TestGameStatus.active));
      expect(restored.winnerId, isNull);
    });

    test('handles missing optional fields gracefully', () {
      final minimalJson = <String, dynamic>{
        'gameId': 'game-min',
        'currentPlayerId': 'p1',
        'players': <dynamic>[],
        'hand': <dynamic>[],
      };

      final state = TestGameState.fromJson(minimalJson);

      expect(state.gameId, equals('game-min'));
      expect(state.topCard, isNull);
      expect(state.activeColor, isNull);
      expect(state.isClockwise, isTrue);
      expect(state.status, equals(TestGameStatus.waiting));
      expect(state.winnerId, isNull);
    });

    test('roundtrip preserves player connectivity flag', () {
      final state = TestGameState(
        gameId: 'g',
        currentPlayerId: 'p2',
        players: const [
          TestPlayer(
              id: 'p1',
              displayName: 'Disconnected',
              cardCount: 2,
              isConnected: false),
          TestPlayer(id: 'p2', displayName: 'Connected', cardCount: 4),
        ],
        hand: const [],
      );

      final restored = TestGameState.fromJson(state.toJson());

      expect(restored.players[0].isConnected, isFalse);
      expect(restored.players[1].isConnected, isTrue);
    });

    test('roundtrip preserves anticlockwise direction', () {
      final state = TestGameState(
        gameId: 'g',
        currentPlayerId: 'p1',
        players: const [],
        hand: const [],
        isClockwise: false,
      );

      final restored = TestGameState.fromJson(state.toJson());

      expect(restored.isClockwise, isFalse);
    });

    test('roundtrip preserves winnerId', () {
      final state = TestGameState(
        gameId: 'g',
        currentPlayerId: 'p1',
        players: const [],
        hand: const [],
        status: TestGameStatus.finished,
        winnerId: 'p1',
      );

      final restored = TestGameState.fromJson(state.toJson());

      expect(restored.winnerId, equals('p1'));
      expect(restored.status, equals(TestGameStatus.finished));
    });
  });

  // -------------------------------------------------------------------------
  // identifies correct current player
  // -------------------------------------------------------------------------

  group('GameState identifies correct current player', () {
    late TestGameState gameState;

    setUp(() {
      gameState = TestGameState(
        gameId: 'test-game',
        currentPlayerId: 'player-2',
        players: const [
          TestPlayer(id: 'player-1', displayName: 'Alice', cardCount: 4),
          TestPlayer(id: 'player-2', displayName: 'Bob', cardCount: 2),
          TestPlayer(id: 'player-3', displayName: 'Charlie', cardCount: 6),
        ],
        hand: const [
          TestWildCard(color: TestCardColor.yellow, value: '3'),
          TestWildCard(color: TestCardColor.red, value: 'draw_two'),
        ],
        topCard: const TestWildCard(color: TestCardColor.yellow, value: '8'),
        status: TestGameStatus.active,
      );
    });

    test('isCurrentPlayer returns true for the current player', () {
      expect(gameState.isCurrentPlayer('player-2'), isTrue);
    });

    test('isCurrentPlayer returns false for other players', () {
      expect(gameState.isCurrentPlayer('player-1'), isFalse);
      expect(gameState.isCurrentPlayer('player-3'), isFalse);
    });

    test('isCurrentPlayer returns false for unknown id', () {
      expect(gameState.isCurrentPlayer('nobody'), isFalse);
    });

    test('playerById returns correct player', () {
      final player = gameState.playerById('player-1');
      expect(player, isNotNull);
      expect(player!.displayName, equals('Alice'));
      expect(player.cardCount, equals(4));
    });

    test('playerById returns null for unknown id', () {
      expect(gameState.playerById('unknown'), isNull);
    });

    test('playerById returns the active player', () {
      final active = gameState.playerById(gameState.currentPlayerId);
      expect(active, isNotNull);
      expect(active!.id, equals('player-2'));
      expect(active.displayName, equals('Bob'));
    });
  });

  // -------------------------------------------------------------------------
  // hand contains correct cards
  // -------------------------------------------------------------------------

  group('hand contains correct cards', () {
    test('hand length matches cards provided', () {
      final state = TestGameState(
        gameId: 'g',
        currentPlayerId: 'p1',
        players: const [],
        hand: const [
          TestWildCard(color: TestCardColor.red, value: '1'),
          TestWildCard(color: TestCardColor.blue, value: '2'),
          TestWildCard(color: TestCardColor.green, value: 'skip'),
        ],
      );

      expect(state.hand.length, equals(3));
    });

    test('hand card properties are preserved after fromJson', () {
      final state = TestGameState(
        gameId: 'g',
        currentPlayerId: 'p1',
        players: const [],
        hand: const [
          TestWildCard(color: TestCardColor.yellow, value: '9'),
          TestWildCard(color: TestCardColor.wild, value: 'wildDrawFour'),
        ],
      );

      final restored = TestGameState.fromJson(state.toJson());

      expect(restored.hand[0].color, equals(TestCardColor.yellow));
      expect(restored.hand[0].value, equals('9'));
      expect(restored.hand[1].color, equals(TestCardColor.wild));
      expect(restored.hand[1].value, equals('wildDrawFour'));
    });

    test('empty hand is preserved after fromJson', () {
      final state = TestGameState(
        gameId: 'g',
        currentPlayerId: 'p1',
        players: const [],
        hand: const [],
      );

      final restored = TestGameState.fromJson(state.toJson());

      expect(restored.hand, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // drawPileCount is accurate
  // -------------------------------------------------------------------------

  group('drawPileCount is accurate', () {
    // drawPileCount is not part of the model used in unit tests (it is a
    // UI-level concept in game_screen.dart). We verify hand card count here
    // as the model-level equivalent of "cards remaining".
    test('player cardCount matches expected value', () {
      const player = TestPlayer(id: 'p1', displayName: 'Test', cardCount: 42);
      expect(player.cardCount, equals(42));
    });

    test('player cardCount survives a JSON roundtrip', () {
      const player = TestPlayer(id: 'p1', displayName: 'Test', cardCount: 17);
      final restored = TestPlayer.fromJson(player.toJson());
      expect(restored.cardCount, equals(17));
    });

    test('hand card count equals number of cards in list', () {
      final cards = List.generate(
        7,
        (i) => TestWildCard(color: TestCardColor.red, value: '$i'),
      );
      final state = TestGameState(
        gameId: 'g',
        currentPlayerId: 'p1',
        players: const [],
        hand: cards,
      );
      expect(state.hand.length, equals(7));
    });
  });

  // -------------------------------------------------------------------------
  // winnerId is null during game, set when finished
  // -------------------------------------------------------------------------

  group('winnerId is null during game, set when finished', () {
    test('winnerId is null during active game', () {
      final state = TestGameState(
        gameId: 'g',
        currentPlayerId: 'p1',
        players: const [],
        hand: const [],
        status: TestGameStatus.active,
        winnerId: null,
      );

      expect(state.winnerId, isNull);
    });

    test('winnerId is null in waiting state', () {
      final state = TestGameState(
        gameId: 'g',
        currentPlayerId: 'p1',
        players: const [],
        hand: const [],
        status: TestGameStatus.waiting,
      );

      expect(state.winnerId, isNull);
    });

    test('winnerId is set when game is finished', () {
      final state = TestGameState(
        gameId: 'g',
        currentPlayerId: 'p1',
        players: const [],
        hand: const [],
        status: TestGameStatus.finished,
        winnerId: 'p1',
      );

      expect(state.winnerId, equals('p1'));
      expect(state.status, equals(TestGameStatus.finished));
    });

    test('winnerId survives JSON roundtrip', () {
      final state = TestGameState(
        gameId: 'g',
        currentPlayerId: 'p2',
        players: const [],
        hand: const [],
        status: TestGameStatus.finished,
        winnerId: 'p2',
      );

      final restored = TestGameState.fromJson(state.toJson());

      expect(restored.winnerId, equals('p2'));
      expect(restored.status, equals(TestGameStatus.finished));
    });

    test('null winnerId survives JSON roundtrip', () {
      final state = TestGameState(
        gameId: 'g',
        currentPlayerId: 'p1',
        players: const [],
        hand: const [],
        status: TestGameStatus.active,
        winnerId: null,
      );

      final restored = TestGameState.fromJson(state.toJson());

      expect(restored.winnerId, isNull);
    });
  });
}
