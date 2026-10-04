// Widget tests for CardWidget.
// Imports card_widget.dart directly, which exports its own WildCard,
// CardColor, and CardValue types.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wilddeck/features/game/widgets/card_widget.dart';

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Widget _buildCard({
  required WildCard card,
  bool isPlayable = true,
  bool isSelected = false,
  VoidCallback? onTap,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: CardWidget(
          card: card,
          isPlayable: isPlayable,
          isSelected: isSelected,
          onTap: onTap,
        ),
      ),
    ),
  );
}

void main() {
  // -------------------------------------------------------------------------
  // CardWidget renders red card with correct color
  // -------------------------------------------------------------------------

  group('CardWidget renders red card with correct color', () {
    testWidgets('red card is present in the widget tree', (tester) async {
      const card = WildCard(
        color: CardColor.red,
        value: CardValue.five,
        id: 'red-card',
      );

      await tester.pumpWidget(_buildCard(card: card));

      // The CardWidget itself should be found.
      expect(find.byType(CardWidget), findsOneWidget);
    });

    testWidgets('red card displays its value text', (tester) async {
      const card = WildCard(
        color: CardColor.red,
        value: CardValue.five,
        id: 'red-card',
      );

      await tester.pumpWidget(_buildCard(card: card));

      // The center label + two corner labels all show the display value.
      expect(find.text('5'), findsWidgets);
    });

    testWidgets('red card container has correct color', (tester) async {
      const card = WildCard(
        color: CardColor.red,
        value: CardValue.three,
        id: 'red-card-2',
      );

      await tester.pumpWidget(_buildCard(card: card));

      final containers = tester.widgetList<Container>(find.byType(Container));
      final redContainer = containers.firstWhere(
        (c) =>
            c.decoration is BoxDecoration &&
            (c.decoration as BoxDecoration).color ==
                const Color(0xFFE53935),
        orElse: () => throw TestFailure('No red container found'),
      );

      expect(redContainer, isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // CardWidget renders wild card
  // -------------------------------------------------------------------------

  group('CardWidget renders wild card', () {
    testWidgets('wild card uses gradient decoration', (tester) async {
      const card = WildCard(
        color: CardColor.wild,
        value: CardValue.wild,
        id: 'wild-card',
      );

      await tester.pumpWidget(_buildCard(card: card));

      final containers = tester.widgetList<Container>(find.byType(Container));
      final gradientContainer = containers.firstWhere(
        (c) =>
            c.decoration is BoxDecoration &&
            (c.decoration as BoxDecoration).gradient != null,
        orElse: () => throw TestFailure('No gradient container found'),
      );

      expect(gradientContainer, isNotNull);
    });

    testWidgets('wild card shows "W" label', (tester) async {
      const card = WildCard(
        color: CardColor.wild,
        value: CardValue.wild,
        id: 'wild-card',
      );

      await tester.pumpWidget(_buildCard(card: card));

      expect(find.text('W'), findsWidgets);
    });

    testWidgets('wildDrawFour card shows "+4" label', (tester) async {
      const card = WildCard(
        color: CardColor.wild,
        value: CardValue.wildDrawFour,
        id: 'wdf-card',
      );

      await tester.pumpWidget(_buildCard(card: card));

      expect(find.text('+4'), findsWidgets);
    });
  });

  // -------------------------------------------------------------------------
  // Playable card is tappable
  // -------------------------------------------------------------------------

  group('Playable card is tappable', () {
    testWidgets('tapping a playable card calls onTap', (tester) async {
      var tapped = false;
      const card = WildCard(
        color: CardColor.blue,
        value: CardValue.seven,
        id: 'tap-card',
      );

      await tester.pumpWidget(
        _buildCard(
          card: card,
          isPlayable: true,
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.byType(CardWidget));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('playable card is not wrapped in IgnorePointer that ignores',
        (tester) async {
      const card = WildCard(
        color: CardColor.green,
        value: CardValue.two,
        id: 'play-card',
      );

      await tester.pumpWidget(_buildCard(card: card, isPlayable: true));

      final ignorePointers = tester.widgetList<IgnorePointer>(
        find.byType(IgnorePointer),
      );

      // All IgnorePointers for a playable card should have ignoring == false.
      for (final ip in ignorePointers) {
        expect(ip.ignoring, isFalse,
            reason:
                'Expected no active IgnorePointer for a playable card');
      }
    });
  });

  // -------------------------------------------------------------------------
  // Unplayable card is not tappable (IgnorePointer)
  // -------------------------------------------------------------------------

  group('Unplayable card is not tappable (IgnorePointer)', () {
    testWidgets('IgnorePointer is set to ignoring=true for unplayable card',
        (tester) async {
      const card = WildCard(
        color: CardColor.yellow,
        value: CardValue.one,
        id: 'no-tap-card',
      );

      await tester.pumpWidget(
        _buildCard(card: card, isPlayable: false),
      );

      final ignorePointers = tester
          .widgetList<IgnorePointer>(find.byType(IgnorePointer))
          .toList();

      expect(
        ignorePointers.any((ip) => ip.ignoring == true),
        isTrue,
        reason: 'Expected at least one IgnorePointer with ignoring=true',
      );
    });

    testWidgets('tapping unplayable card does not fire onTap', (tester) async {
      var tapped = false;
      const card = WildCard(
        color: CardColor.blue,
        value: CardValue.skip,
        id: 'no-tap-card-2',
      );

      await tester.pumpWidget(
        _buildCard(
          card: card,
          isPlayable: false,
          onTap: () => tapped = true,
        ),
      );

      // tap() on an ignored widget is silently swallowed.
      await tester.tap(find.byType(CardWidget), warnIfMissed: false);
      await tester.pump();

      expect(tapped, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Selected card has higher elevation
  // -------------------------------------------------------------------------

  group('Selected card has higher elevation', () {
    testWidgets('selected card has larger box shadow blur radius',
        (tester) async {
      const card = WildCard(
        color: CardColor.green,
        value: CardValue.reverse,
        id: 'sel-card',
      );

      await tester.pumpWidget(_buildCard(card: card, isSelected: true));

      // The selected card should have a box shadow with blurRadius == 12.
      final containers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) {
        final deco = c.decoration;
        if (deco is! BoxDecoration) return false;
        final shadows = deco.boxShadow;
        return shadows != null &&
            shadows.any((s) => s.blurRadius == 12);
      }).toList();

      expect(containers, isNotEmpty,
          reason: 'Expected container with blurRadius==12 for selected card');
    });

    testWidgets('unselected card has smaller box shadow blur radius',
        (tester) async {
      const card = WildCard(
        color: CardColor.red,
        value: CardValue.six,
        id: 'unsel-card',
      );

      await tester.pumpWidget(_buildCard(card: card, isSelected: false));

      // For an unselected card the shadow blurRadius should be 6, not 12.
      final containers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) {
        final deco = c.decoration;
        if (deco is! BoxDecoration) return false;
        final shadows = deco.boxShadow;
        return shadows != null &&
            shadows.any((s) => s.blurRadius == 6);
      }).toList();

      expect(containers, isNotEmpty,
          reason: 'Expected container with blurRadius==6 for unselected card');
    });
  });
}
