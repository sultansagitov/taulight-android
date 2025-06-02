import 'package:flutter_test/flutter_test.dart';
import 'package:taulight/classes/chat_member.dart';

void main() {
  group('Status', () {
    test('parses from string', () {
      expect(Status.fromString('online'), Status.online);
      expect(Status.fromString('OFFLINE'), Status.offline);
      expect(Status.fromString('unknown'), Status.hidden);
    });
  });
}