import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taulight/classes/records.dart';

void main() {
  group('ChatDTO', () {
    test('ChannelDTO is parsed correctly', () {
      final map = {
        'type': 'cn',
        'id': '1',
        'channel-title': 'General',
        'channel-owner': 'admin'
      };

      final dto = ChatDTO.fromMap(map);
      expect(dto, isA<ChannelDTO>());
      expect(dto.getTitle(), equals('General'));
    });

    test('DialogDTO is parsed correctly', () {
      final map = {
        'type': 'dl',
        'id': '2',
        'dialog-other': 'user123'
      };

      final dto = ChatDTO.fromMap(map);
      expect(dto, isA<DialogDTO>());
      expect(dto.getTitle(), equals('user123'));
    });

    test('throws on unknown type', () {
      final map = {'type': 'xyz', 'id': '3'};
      expect(() => ChatDTO.fromMap(map), throwsA(isA<ErrorDescription>()));
    });
  });
}