// Widget tests for PlayerHand.
// LastCardButton visibility is driven by GameBoard's showLastCardButton flag which
// wraps PlayerHand, so Last Card button tests exercise GameBoard directly.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wilddeck/features/game/widgets/card_widget.dart';
import 'package:wilddeck/features/game/widgets/game_board.dart';
import 'package:wilddeck/features/game/widgets/last_card_button.dart';
import 'package:wilddeck/features/game/widgets/player_hand.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _buildHand({
  required List<WildCard> cards,
  Set<String>? playableCardIds,
  String? selectedCardId,
  void Function(WildCard)? onCardTap,
}) {
  return MaterialApp(
    home: Scaffold(
      body: PlayerHand(
        cards: cards,
        playableCardIds: playableCardIds ?? cards.map((c) => c.id).toSet(),
        selectedCardId: selectedCardId,
        onCardTap: onCardTap ?? (_) {},
      ),
    ),
  );
}

/// Builds a minimal [GameBoard] so we can test LastCardButton visibility.
Widget _buildBoard({
  required List<WildCard> hand,
  required bool showLastCardButton,
  bool isMyTurn = true,
}) {
  return MaterialApp(
    home: Scaffold(
      body: GameBoard(
        gameId: 'test',
        opponents: const [],
        myHand: hand,
        playableCardIds: hand.map((c) => c.id).toSet(),
        isMyTurn: isMyTurn,
        showLastCardButton: showLastCardButton,
        onCardSelected: (_) {},
        onCardPlayed: (_) {},
        onDrawCard: () {},
        onCallLastCard: () {},
        onColorPick: () async => null,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // Shows correct number of cards
  // -------------------------------------------------------------------------

  group('Shows correct number of cards', () {
    testWidgets('renders 5 CardWidgets for a 5-card hand', (tester) async {
      final cards = List.generate(
        5,
        (i) => WildCard(
          color: CardColor.red,
          value: CardValue.values[i],
          id: 'card-$i',
        ),
      );

      await tester.pumpWidget(_buildHand(cards: cards));

      expect(find.byType(CardWidget), findsNWidgets(5));
    });

    testWidgets('renders 1 CardWidget for a 1-card hand', (tester) async {
      final cards = [
        const WildCard(
          color: CardColor.blue,
          value: CardValue.two,
          id: 'solo',
        ),
      ];

      await tester.pumpWidget(_buildHand(cards: cards));

      expect(find.byType(CardWidget), findsOneWidget);
    });

    testWidgets('renders "No cards in hand" message for empty hand',
        (tester) async {
      await tester.pumpWidget(_buildHand(cards: const []));

      expect(find.text('No cards in hand'), findsOneWidget);
      expect(find.byType(CardWidget), findsNothing);
    });

    testWidgets('renders 3 CardWidgets for a 3-card hand', (tester) async {
      final cards = List.generate(
        3,
        (i) => WildCard(
          color: CardColor.green,
          value: CardValue.values[i + 1],
          id: 'g-$i',
        ),
      );

      await tester.pumpWidget(_buildHand(cards: cards));

      expect(find.byType(CardWidget), findsNWidgets(3));
    });
  });

  // -------------------------------------------------------------------------
  // Last Card button visible when 1 card
  // -------------------------------------------------------------------------

  group('Last Card button visible when 1 card', () {
    testWidgets(
        'LastCardButton has opacity 1.0 (visible) when hand has 1 card and isMyTurn',
        (tester) async {
      final cards = [
        const WildCard(
          color: CardColor.yellow,
          value: CardValue.nine,
          id: 'last-card',
        ),
      ];

      await tester.pumpWidget(
        _buildBoard(
          hand: cards,
          showLastCardButton: true,
        ),
      );

      final lastCardButton = tester.widget<LastCardButton>(find.byType(LastCardButton));
      expect(lastCardButton.isVisible, isTrue);
    });

    testWidgets('LastCardButton widget is present in GameBoard', (tester) async {
      final cards = [
        const WildCard(
          color: CardColor.red,
          value: CardValue.five,
          id: 'wild-card',
        ),
      ];

      await tester.pumpWidget(
        _buildBoard(
          hand: cards,
          showLastCardButton: true,
        ),
      );

      expect(find.byType(LastCardButton), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Last Card button hidden when 2+ cards
  // -------------------------------------------------------------------------

  group('Last Card button hidden when 2+ cards', () {
    testWidgets('LastCardButton isVisible is false when showLastCardButton is false',
        (tester) async {
      final cards = List.generate(
        3,
        (i) => WildCard(
          color: CardColor.blue,
          value: CardValue.values[i],
          id: 'mc-$i',
        ),
      );

      await tester.pumpWidget(
        _buildBoard(
          hand: cards,
          showLastCardButton: false,
        ),
      );

      final lastCardButton = tester.widget<LastCardButton>(find.byType(LastCardButton));
      expect(lastCardButton.isVisible, isFalse);
    });

    testWidgets(
        'LastCardButton isVisible is false when isMyTurn is false even with 1 card',
        (tester) async {
      final cards = [
        const WildCard(
          color: CardColor.green,
          value: CardValue.three,
          id: 'not-my-turn',
        ),
      ];

      await tester.pumpWidget(
        _buildBoard(
          hand: cards,
          showLastCardButton: true,
          isMyTurn: false,
        ),
      );

      final lastCardButton = tester.widget<LastCardButton>(find.byType(LastCardButton));
      // GameBoard passes (showLastCardButton && isMyTurn) to LastCardButton.
      expect(lastCardButton.isVisible, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Tap on card calls playCard
  // -------------------------------------------------------------------------

  group('Tap on card calls playCard', () {
    testWidgets('tapping a playable card invokes onCardTap', (tester) async {
      WildCard? tappedCard;
      const card = WildCard(
        color: CardColor.red,
        value: CardValue.seven,
        id: 'tap-me',
      );

      await tester.pumpWidget(
        _buildHand(
          cards: [card],
          playableCardIds: {'tap-me'},
          onCardTap: (c) => tappedCard = c,
        ),
      );

      await tester.tap(find.byType(CardWidget));
      await tester.pump();

      expect(tappedCard, isNotNull);
      expect(tappedCard!.id, equals('tap-me'));
    });

    testWidgets('tapping an unplayable card does not invoke onCardTap',
        (tester) async {
      WildCard? tappedCard;
      const card = WildCard(
        color: CardColor.blue,
        value: CardValue.zero,
        id: 'no-play',
      );

      await tester.pumpWidget(
        _buildHand(
          cards: [card],
          playableCardIds: const {}, // nothing is playable
          onCardTap: (c) => tappedCard = c,
        ),
      );

      await tester.tap(find.byType(CardWidget), warnIfMissed: false);
      await tester.pump();

      expect(tappedCard, isNull);
    });

    testWidgets('tapping correct card in multi-card hand invokes callback',
        (tester) async {
      final tapped = <String>[];
      final cards = [
        const WildCard(color: CardColor.red, value: CardValue.one, id: 'c1'),
        const WildCard(color: CardColor.blue, value: CardValue.two, id: 'c2'),
        const WildCard(color: CardColor.green, value: CardValue.three, id: 'c3'),
      ];

      await tester.pumpWidget(
        _buildHand(
          cards: cards,
          playableCardIds: {'c1', 'c2', 'c3'},
          onCardTap: (c) => tapped.add(c.id),
        ),
      );

      // Tap the first card widget.
      await tester.tap(find.byType(CardWidget).first);
      await tester.pump();

      expect(tapped, isNotEmpty);
    });
  });
}
