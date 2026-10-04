// Unit tests for the standalone UnoCard model helpers used in unit tests.
// These tests exercise serialization / deserialization and enum coverage
// using the same self-contained helper types that game_state_test.dart relies on.

import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Minimal standalone card model (mirrors lib/core/models/card.dart without
// generated code or freezed dependencies).
// ---------------------------------------------------------------------------

enum _CardColor {
  red,
  green,
  blue,
  yellow,
  wild;

  static const _jsonValues = {
    'red': _CardColor.red,
    'green': _CardColor.green,
    'blue': _CardColor.blue,
    'yellow': _CardColor.yellow,
    'wild': _CardColor.wild,
  };

  String toJson() => name;

  static _CardColor fromJson(String value) =>
      _jsonValues[value] ?? (throw ArgumentError('Unknown CardColor: $value'));
}

enum _CardType {
  number,
  skip,
  reverse,
  drawTwo,
  wild,
  wildDrawFour;

  static const _jsonValues = {
    'number': _CardType.number,
    'skip': _CardType.skip,
    'reverse': _CardType.reverse,
    'drawTwo': _CardType.drawTwo,
    'wild': _CardType.wild,
    'wildDrawFour': _CardType.wildDrawFour,
  };

  String toJson() => name;

  static _CardType fromJson(String value) =>
      _jsonValues[value] ?? (throw ArgumentError('Unknown CardType: $value'));
}

class _UnoCard {
  final String id;
  final _CardColor color;
  final _CardType type;
  final int? value;

  const _UnoCard({
    required this.id,
    required this.color,
    required this.type,
    this.value,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'color': color.toJson(),
        'type': type.toJson(),
        if (value != null) 'value': value,
      };

  factory _UnoCard.fromJson(Map<String, dynamic> json) {
    return _UnoCard(
      id: json['id'] as String,
      color: _CardColor.fromJson(json['color'] as String),
      type: _CardType.fromJson(json['type'] as String),
      value: json['value'] as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _UnoCard &&
      other.id == id &&
      other.color == color &&
      other.type == type &&
      other.value == value;

  @override
  int get hashCode => Object.hash(id, color, type, value);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // Serialization
  // -------------------------------------------------------------------------

  group('UnoCard serializes to JSON correctly for all card types', () {
    test('number card serializes with value', () {
      const card = _UnoCard(
        id: 'card-1',
        color: _CardColor.red,
        type: _CardType.number,
        value: 5,
      );

      final json = card.toJson();

      expect(json['id'], equals('card-1'));
      expect(json['color'], equals('red'));
      expect(json['type'], equals('number'));
      expect(json['value'], equals(5));
    });

    test('skip card serializes without value', () {
      const card = _UnoCard(
        id: 'card-2',
        color: _CardColor.blue,
        type: _CardType.skip,
      );

      final json = card.toJson();

      expect(json['type'], equals('skip'));
      expect(json.containsKey('value'), isFalse);
    });

    test('reverse card serializes without value', () {
      const card = _UnoCard(
        id: 'card-3',
        color: _CardColor.green,
        type: _CardType.reverse,
      );

      final json = card.toJson();

      expect(json['type'], equals('reverse'));
    });

    test('drawTwo card serializes without value', () {
      const card = _UnoCard(
        id: 'card-4',
        color: _CardColor.yellow,
        type: _CardType.drawTwo,
      );

      final json = card.toJson();

      expect(json['type'], equals('drawTwo'));
    });

    test('wild card serializes with wild color and null value', () {
      const card = _UnoCard(
        id: 'card-5',
        color: _CardColor.wild,
        type: _CardType.wild,
      );

      final json = card.toJson();

      expect(json['color'], equals('wild'));
      expect(json['type'], equals('wild'));
      expect(json.containsKey('value'), isFalse);
    });

    test('wildDrawFour card serializes correctly', () {
      const card = _UnoCard(
        id: 'card-6',
        color: _CardColor.wild,
        type: _CardType.wildDrawFour,
      );

      final json = card.toJson();

      expect(json['color'], equals('wild'));
      expect(json['type'], equals('wildDrawFour'));
    });
  });

  // -------------------------------------------------------------------------
  // Deserialization
  // -------------------------------------------------------------------------

  group('UnoCard deserializes from JSON', () {
    test('deserializes a number card', () {
      final json = <String, dynamic>{
        'id': 'c1',
        'color': 'green',
        'type': 'number',
        'value': 7,
      };

      final card = _UnoCard.fromJson(json);

      expect(card.id, equals('c1'));
      expect(card.color, equals(_CardColor.green));
      expect(card.type, equals(_CardType.number));
      expect(card.value, equals(7));
    });

    test('deserializes a wild card with null value', () {
      final json = <String, dynamic>{
        'id': 'c2',
        'color': 'wild',
        'type': 'wild',
      };

      final card = _UnoCard.fromJson(json);

      expect(card.color, equals(_CardColor.wild));
      expect(card.type, equals(_CardType.wild));
      expect(card.value, isNull);
    });

    test('deserializes a skip card', () {
      final json = <String, dynamic>{
        'id': 'c3',
        'color': 'red',
        'type': 'skip',
      };

      final card = _UnoCard.fromJson(json);

      expect(card.type, equals(_CardType.skip));
      expect(card.value, isNull);
    });

    test('roundtrip is lossless', () {
      const original = _UnoCard(
        id: 'rt-1',
        color: _CardColor.yellow,
        type: _CardType.drawTwo,
      );

      final restored = _UnoCard.fromJson(original.toJson());

      expect(restored, equals(original));
    });

    test('roundtrip for number card preserves value', () {
      const original = _UnoCard(
        id: 'rt-2',
        color: _CardColor.blue,
        type: _CardType.number,
        value: 3,
      );

      final restored = _UnoCard.fromJson(original.toJson());

      expect(restored, equals(original));
      expect(restored.value, equals(3));
    });
  });

  // -------------------------------------------------------------------------
  // Wild card has null value
  // -------------------------------------------------------------------------

  group('Wild card has null value', () {
    test('wild type card constructed without value has null value', () {
      const card = _UnoCard(
        id: 'w1',
        color: _CardColor.wild,
        type: _CardType.wild,
      );

      expect(card.value, isNull);
    });

    test('wildDrawFour card constructed without value has null value', () {
      const card = _UnoCard(
        id: 'w2',
        color: _CardColor.wild,
        type: _CardType.wildDrawFour,
      );

      expect(card.value, isNull);
    });

    test('wild card from JSON with no value field has null value', () {
      final json = <String, dynamic>{
        'id': 'w3',
        'color': 'wild',
        'type': 'wildDrawFour',
      };

      final card = _UnoCard.fromJson(json);

      expect(card.value, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // CardColor enum serialization
  // -------------------------------------------------------------------------

  group('All CardColor enum values serialize correctly', () {
    for (final entry in <_CardColor, String>{
      _CardColor.red: 'red',
      _CardColor.green: 'green',
      _CardColor.blue: 'blue',
      _CardColor.yellow: 'yellow',
      _CardColor.wild: 'wild',
    }.entries) {
      test('${entry.key.name} serializes to "${entry.value}"', () {
        expect(entry.key.toJson(), equals(entry.value));
      });

      test('"${entry.value}" deserializes to ${entry.key.name}', () {
        expect(_CardColor.fromJson(entry.value), equals(entry.key));
      });
    }
  });

  // -------------------------------------------------------------------------
  // CardType enum serialization
  // -------------------------------------------------------------------------

  group('All CardType enum values serialize correctly', () {
    for (final entry in <_CardType, String>{
      _CardType.number: 'number',
      _CardType.skip: 'skip',
      _CardType.reverse: 'reverse',
      _CardType.drawTwo: 'drawTwo',
      _CardType.wild: 'wild',
      _CardType.wildDrawFour: 'wildDrawFour',
    }.entries) {
      test('${entry.key.name} serializes to "${entry.value}"', () {
        expect(entry.key.toJson(), equals(entry.value));
      });

      test('"${entry.value}" deserializes to ${entry.key.name}', () {
        expect(_CardType.fromJson(entry.value), equals(entry.key));
      });
    }
  });
}
