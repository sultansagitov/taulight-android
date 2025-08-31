import 'package:flutter_test/flutter_test.dart';
import 'package:taulight/classes/nickname.dart';

void main() {
  group('Nickname', () {
    test('accepts single character nicknames', () {
      expect(Nickname.checked('a').toString(), 'a');
      expect(Nickname.checked('Z').toString(), 'Z');
      expect(Nickname.checked('1').toString(), '1');
      expect(Nickname.checked('_').toString(), '_');
      expect(Nickname.checked('.').toString(), '.');
    });

    test('accepts long nickname', () {
      final long = 'user_${'1234567890' * 10}';
      final nick = Nickname.checked(long);
      expect(nick.toString(), long);
    });

    test('case sensitivity preserved', () {
      final lower = Nickname.checked('nick');
      final upper = Nickname.checked('NICK');
      expect(lower == upper, isFalse);
    });

    test('throws if only spaces', () {
      expect(() => Nickname.checked('   '), throwsArgumentError);
    });

    test('throws if newline or tab inside', () {
      expect(() => Nickname.checked('nick\nname'), throwsArgumentError);
      expect(() => Nickname.checked('nick\tname'), throwsArgumentError);
    });

    test('throws on symbols', () {
      for (final bad in ['!', '@', '#', '-', '+', '=', '💀']) {
        expect(() => Nickname.checked('nick$bad'), throwsArgumentError,
            reason: 'Should reject $bad');
      }
    });

    test('checkedNullable returns Nickname for valid input', () {
      final n = Nickname.checkedNullable('OkNick');
      expect(n, isA<Nickname>());
      expect(n.toString(), 'OkNick');
    });

    test('checkedNullable throws if invalid', () {
      expect(() => Nickname.checkedNullable('bad nick'), throwsArgumentError);
    });

    test('hashCode aligns with equality', () {
      final n1 = Nickname.checked('hashTest');
      final n2 = Nickname.checked('hashTest');
      final set = {n1};
      expect(set.contains(n2), isTrue);
    });

    test('different runtimeType should not be equal', () {
      final n1 = Nickname.checked('abc');
      final other = 'abc';
      expect(n1 == other, isFalse);
    });

    test('toString returns original string', () {
      final raw = 'XyZ_123';
      expect(Nickname.checked(raw).toString(), raw);
    });
  });
}
