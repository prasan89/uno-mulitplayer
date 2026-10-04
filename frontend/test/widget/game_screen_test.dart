// Widget tests for GameScreen.
// GameScreen accepts an optional [initialState] parameter which bypasses the
// demo-bootstrap so we can inject controlled state for each test case.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uno_multiplayer/features/game/screens/game_screen.dart';
import 'package:uno_multiplayer/features/game/widgets/card_widget.dart';
import 'package:uno_multiplayer/features/game/widgets/game_board.dart';
import 'package:uno_multiplayer/features/game/widgets/game_over_dialog.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns a minimal, non-game-over [GameState] suitable for pump tests.
GameState _activeState({
  bool isMyTurn = false,
  List<OpponentPlayer> opponents = const [],
  String? winnerName,
}) {
  return GameState(
    gameId: 'test-game-01',
    myHand: [
      const UnoCard(color: CardColor.red, value: CardValue.five, id: 'c1'),
      const UnoCard(color: CardColor.blue, value: CardValue.two, id: 'c2'),
    ],
    discardTopCard:
        const UnoCard(color: CardColor.red, value: CardValue.four, id: 'top'),
    drawPileCount: 40,
    isMyTurn: isMyTurn,
    canDraw: isMyTurn,
    opponents: opponents,
    winnerName: winnerName,
  );
}

/// Wraps [GameScreen] in a [MaterialApp]/[Navigator] so dialogs and routing work.
Widget _buildScreen(GameScreen screen) {
  return MaterialApp(
    home: screen,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // Screen renders without error given a valid game state
  // -------------------------------------------------------------------------

  group('Screen renders without error given a valid game state', () {
    testWidgets('GameScreen pumps without throwing', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          GameScreen(
            gameId: 'test-game-01',
            initialState: _activeState(),
          ),
        ),
      );

      // No exception should have been thrown. The screen scaffold is present.
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('GameBoard is rendered inside GameScreen', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          GameScreen(
            gameId: 'test-game-01',
            initialState: _activeState(),
          ),
        ),
      );

      expect(find.byType(GameBoard), findsOneWidget);
    });

    testWidgets('AppBar shows game id prefix', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          GameScreen(
            gameId: 'test-game-01',
            initialState: _activeState(),
          ),
        ),
      );

      // AppBar title shows "Game #<first-8-chars>".
      expect(find.text('Game #test-gam'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Shows "Your Turn" when it is current player turn
  // -------------------------------------------------------------------------

  group('Shows "Your Turn!" when it is current player turn', () {
    testWidgets('turn indicator reads "Your Turn!" when isMyTurn is true',
        (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          GameScreen(
            gameId: 'g1',
            initialState: _activeState(isMyTurn: true),
          ),
        ),
      );

      expect(find.text('Your Turn!'), findsOneWidget);
    });

    testWidgets('turn indicator reads "Waiting..." when isMyTurn is false',
        (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          GameScreen(
            gameId: 'g1',
            initialState: _activeState(isMyTurn: false),
          ),
        ),
      );

      expect(find.text('Waiting...'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Shows correct player count in opponents row
  // -------------------------------------------------------------------------

  group('Shows correct player count in opponents row', () {
    testWidgets('AppBar subtitle shows total player count (opponents + self)',
        (tester) async {
      final opponents = [
        const OpponentPlayer(id: 'p2', name: 'Alice', cardCount: 4),
        const OpponentPlayer(id: 'p3', name: 'Bob', cardCount: 2),
        const OpponentPlayer(id: 'p4', name: 'Charlie', cardCount: 6),
      ];

      await tester.pumpWidget(
        _buildScreen(
          GameScreen(
            gameId: 'g2',
            initialState: _activeState(opponents: opponents),
          ),
        ),
      );

      // GameScreen shows "<opponents.length + 1> players" in the AppBar.
      expect(find.text('4 players'), findsOneWidget);
    });

    testWidgets('AppBar subtitle shows "2 players" for 1 opponent',
        (tester) async {
      final opponents = [
        const OpponentPlayer(id: 'p2', name: 'Alice', cardCount: 3),
      ];

      await tester.pumpWidget(
        _buildScreen(
          GameScreen(
            gameId: 'g3',
            initialState: _activeState(opponents: opponents),
          ),
        ),
      );

      expect(find.text('2 players'), findsOneWidget);
    });

    testWidgets('no opponents results in "1 players" label', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          GameScreen(
            gameId: 'g4',
            initialState: _activeState(opponents: const []),
          ),
        ),
      );

      expect(find.text('1 players'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Game over dialog appears when winnerId is set
  // -------------------------------------------------------------------------

  group('Game over dialog appears when winnerId is set', () {
    testWidgets('GameOverDialog is shown when winnerName is set',
        (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          GameScreen(
            gameId: 'g5',
            initialState: _activeState(winnerName: 'Alice'),
          ),
        ),
      );

      // Let the post-frame callback fire.
      await tester.pump();
      await tester.pump();

      expect(find.byType(GameOverDialog), findsOneWidget);
    });

    testWidgets('GameOverDialog shows winner name', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          GameScreen(
            gameId: 'g6',
            initialState: _activeState(winnerName: 'Bob'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.text('Bob'), findsWidgets);
    });

    testWidgets('GameOverDialog shows "Game Over!" title', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          GameScreen(
            gameId: 'g7',
            initialState: _activeState(winnerName: 'Charlie'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.text('Game Over!'), findsOneWidget);
    });

    testWidgets('No GameOverDialog when winnerName is null', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          GameScreen(
            gameId: 'g8',
            initialState: _activeState(winnerName: null),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.byType(GameOverDialog), findsNothing);
    });
  });
}
