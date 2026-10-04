// Widget tests for PlayerHand.
// UnoButton visibility is driven by GameBoard's showUnoButton flag which
// wraps PlayerHand, so UNO button tests exercise GameBoard directly.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uno_multiplayer/features/game/widgets/card_widget.dart';
import 'package:uno_multiplayer/features/game/widgets/player_hand.dart';
import 'package:uno_multiplayer/features/game/widgets/game_board.dart';
import 'package:uno_multiplayer/features/game/widgets/uno_button.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _buildHand({
  required List<UnoCard> cards,
  Set<String>? playableCardIds,
  String? selectedCardId,
  void Function(UnoCard)? onCardTap,
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

/// Builds a minimal [GameBoard] so we can test UnoButton visibility.
Widget _buildBoard({
  required List<UnoCard> hand,
  required bool showUnoButton,
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
        canDraw: false,
        showUnoButton: showUnoButton,
        onCardSelected: (_) {},
        onCardPlayed: (_) {},
        onDrawCard: () {},
        onCallUno: () {},
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
        (i) => UnoCard(
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
        const UnoCard(
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
        (i) => UnoCard(
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
  // UNO button visible when 1 card
  // -------------------------------------------------------------------------

  group('UNO button visible when 1 card', () {
    testWidgets(
        'UnoButton has opacity 1.0 (visible) when hand has 1 card and isMyTurn',
        (tester) async {
      final cards = [
        const UnoCard(
          color: CardColor.yellow,
          value: CardValue.nine,
          id: 'last-card',
        ),
      ];

      await tester.pumpWidget(
        _buildBoard(
          hand: cards,
          showUnoButton: true,
          isMyTurn: true,
        ),
      );

      final unoButton = tester.widget<UnoButton>(find.byType(UnoButton));
      expect(unoButton.isVisible, isTrue);
    });

    testWidgets('UnoButton widget is present in GameBoard', (tester) async {
      final cards = [
        const UnoCard(
          color: CardColor.red,
          value: CardValue.five,
          id: 'uno-card',
        ),
      ];

      await tester.pumpWidget(
        _buildBoard(
          hand: cards,
          showUnoButton: true,
          isMyTurn: true,
        ),
      );

      expect(find.byType(UnoButton), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // UNO button hidden when 2+ cards
  // -------------------------------------------------------------------------

  group('UNO button hidden when 2+ cards', () {
    testWidgets('UnoButton isVisible is false when showUnoButton is false',
        (tester) async {
      final cards = List.generate(
        3,
        (i) => UnoCard(
          color: CardColor.blue,
          value: CardValue.values[i],
          id: 'mc-$i',
        ),
      );

      await tester.pumpWidget(
        _buildBoard(
          hand: cards,
          showUnoButton: false,
        ),
      );

      final unoButton = tester.widget<UnoButton>(find.byType(UnoButton));
      expect(unoButton.isVisible, isFalse);
    });

    testWidgets(
        'UnoButton isVisible is false when isMyTurn is false even with 1 card',
        (tester) async {
      final cards = [
        const UnoCard(
          color: CardColor.green,
          value: CardValue.three,
          id: 'not-my-turn',
        ),
      ];

      await tester.pumpWidget(
        _buildBoard(
          hand: cards,
          showUnoButton: true,
          isMyTurn: false,
        ),
      );

      final unoButton = tester.widget<UnoButton>(find.byType(UnoButton));
      // GameBoard passes (showUnoButton && isMyTurn) to UnoButton.
      expect(unoButton.isVisible, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Tap on card calls playCard
  // -------------------------------------------------------------------------

  group('Tap on card calls playCard', () {
    testWidgets('tapping a playable card invokes onCardTap', (tester) async {
      UnoCard? tappedCard;
      const card = UnoCard(
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
      UnoCard? tappedCard;
      const card = UnoCard(
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
        const UnoCard(color: CardColor.red, value: CardValue.one, id: 'c1'),
        const UnoCard(color: CardColor.blue, value: CardValue.two, id: 'c2'),
        const UnoCard(color: CardColor.green, value: CardValue.three, id: 'c3'),
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
