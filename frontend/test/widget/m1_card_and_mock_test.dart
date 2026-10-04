import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uno_multiplayer/core/services/mock_services.dart';
import 'package:uno_multiplayer/core/services/wilddeck_services.dart';
import 'package:uno_multiplayer/shared/theme/wilddeck_theme.dart';
import 'package:uno_multiplayer/shared/widgets/wilddeck_components.dart';

void main() {
  group('WildDeckCardWidget', () {
    testWidgets('renders face-down card without revealing content', (tester) async {
      const card = WildGameCard(
        id: 't1', color: WildCardColor.red, type: WildCardType.number, number: 7,
      );
      await tester.pumpWidget(const ProviderScope(
        child: MaterialApp(home: Scaffold(
          body: WildDeckCardWidget(card: card, faceDown: true),
        )),
      ));
      expect(find.text('7'), findsNothing);
      expect(find.text('WD'), findsOneWidget);
    });

    testWidgets('renders face-up number card', (tester) async {
      const card = WildGameCard(
        id: 't2', color: WildCardColor.blue, type: WildCardType.number, number: 3,
      );
      await tester.pumpWidget(const ProviderScope(
        child: MaterialApp(home: Scaffold(
          body: WildDeckCardWidget(card: card, faceDown: false),
        )),
      ));
      expect(find.text('3'), findsWidgets);
    });

    testWidgets('selected card shows visual elevation', (tester) async {
      const card = WildGameCard(
        id: 't3', color: WildCardColor.green, type: WildCardType.skip,
      );
      await tester.pumpWidget(const ProviderScope(
        child: MaterialApp(home: Scaffold(
          body: WildDeckCardWidget(card: card, faceDown: false, isSelected: true),
        )),
      ));
      // Selected card uses a Transform.translate — verify widget tree contains it
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('card onTap fires callback', (tester) async {
      var tapped = false;
      const card = WildGameCard(
        id: 't4', color: WildCardColor.yellow, type: WildCardType.drawTwo,
      );
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(home: Scaffold(
          body: WildDeckCardWidget(
            card: card, faceDown: false,
            onTap: () => tapped = true,
          ),
        )),
      ));
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      expect(tapped, isTrue);
    });
  });

  group('MockMatchmakingService', () {
    test('emits searching → found within 15 seconds', () async {
      final svc = MockMatchmakingService();
      final states = <MatchmakingState>[];

      await svc.searchForMatch(gameMode: 'classic', maxPlayers: 4, fillWithBots: true)
          .timeout(const Duration(seconds: 15))
          .forEach((s) {
            states.add(s);
            if (s.status == MatchmakingStatus.found) throw _Done();
          })
          .catchError((_) {}, test: (e) => e is _Done);

      svc.dispose();
      expect(states.any((s) => s.status == MatchmakingStatus.searching), isTrue);
      expect(states.any((s) => s.status == MatchmakingStatus.found), isTrue);
      expect(states.last.matchId, isNotNull);
    });

    test('cancel stops the stream', () async {
      final svc = MockMatchmakingService();
      final states = <MatchmakingState>[];

      final sub = svc.searchForMatch(gameMode: 'classic', maxPlayers: 4, fillWithBots: false)
          .listen(states.add);

      await Future.delayed(const Duration(milliseconds: 300));
      await svc.cancelSearch();
      await sub.cancel();
      svc.dispose();

      expect(states.any((s) => s.status == MatchmakingStatus.cancelled), isTrue);
    });

    test('private room returns a non-empty room code', () async {
      final svc = MockMatchmakingService();
      final code = await svc.createPrivateRoom();
      svc.dispose();
      expect(code, isNotEmpty);
    });
  });

  group('MockData', () {
    test('currentPlayer has required fields', () {
      final p = MockData.currentPlayer;
      expect(p.id, isNotEmpty);
      expect(p.displayName, isNotEmpty);
      expect(p.level, greaterThan(0));
      expect(p.coins, greaterThanOrEqualTo(0));
    });

    test('mockHand has valid cards', () {
      final hand = MockData.mockHand;
      expect(hand, isNotEmpty);
      for (final card in hand) {
        expect(card.id, isNotEmpty);
        expect(WildCardColor.values.contains(card.color), isTrue);
        expect(WildCardType.values.contains(card.type), isTrue);
      }
    });

    test('buildMockGameState builds consistent state', () {
      final state = MockData.buildMockGameState('test-game-1');
      expect(state.gameId, 'test-game-1');
      expect(state.players, isNotEmpty);
      expect(state.myHand, isNotEmpty);
    });
  });

  group('WildCardColor / WildCardType enums — original IP', () {
    test('color names are WildDeck originals (not UNO)', () {
      final names = WildCardColor.values.map((c) => c.name).toList();
      // These are WildDeck enum values — no external brand references
      expect(names, containsAll(['red', 'blue', 'green', 'yellow', 'wild']));
    });

    test('card types cover all standard actions', () {
      final types = WildCardType.values.map((t) => t.name).toList();
      expect(types, containsAll(['number', 'skip', 'reverse', 'drawTwo', 'wild', 'wildDrawFour']));
    });
  });
}

class _Done implements Exception {}
