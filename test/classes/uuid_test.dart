import 'package:flutter_test/flutter_test.dart';
import 'package:taulight/classes/uuid.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('UUID', () {
    test('UUID.nil is 16 zero bytes', () {
      expect(UUID.nil.toString(), equals(Uuid.unparse(List.filled(16, 0))));
    });

    test('UUID.random generates different values', () {
      final uuid1 = UUID.random();
      final uuid2 = UUID.random();
      expect(uuid1.toString(), isNot(equals(uuid2.toString())));
    });

    test('UUID.fromString parses valid UUID correctly', () {
      final raw = const Uuid().v4();
      final uuid = UUID.fromString(raw);
      expect(uuid.toString(), equals(raw));
    });

    test('UUID.fromNullableString returns null when input is null', () {
      expect(UUID.fromNullableString(null), isNull);
    });

    test('UUID.fromNullableString parses valid string', () {
      final raw = const Uuid().v4();
      final uuid = UUID.fromNullableString(raw);
      expect(uuid!.toString(), equals(raw));
    });

    test('== operator compares string value, not instance identity', () {
      final raw = const Uuid().v4();
      final uuid1 = UUID.fromString(raw);
      final uuid2 = UUID.fromString(raw);
      expect(uuid1, equals(uuid2));
    });

    test('hashCode is consistent with ==', () {
      final raw = const Uuid().v4();
      final uuid1 = UUID.fromString(raw);
      final uuid2 = UUID.fromString(raw);
      expect(uuid1.hashCode, equals(uuid2.hashCode));
    });

    test('different UUIDs are not equal', () {
      final uuid1 = UUID.random();
      final uuid2 = UUID.random();
      expect(uuid1, isNot(equals(uuid2)));
    });
  });
}
