import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taulight/classes/records.dart';

import 'message_dto_test.dart';

void main() {
  group('ChatDTO', () {
    test('ChannelDTO is parsed correctly', () {
      final map = {
        'type': 'cn',
        'id': '1',
        'channel-title': 'General',
        'channel-owner': 'admin',
        'last-message': {
          'id': 'msg-1',
          'creation-date': '2024-04-01T12:00:00Z',
          'message': {
            'chat-id': 'chat-1',
            'nickname': 'john',
            'content': 'Hello',
            'sys': false,
            'repliedToMessages': ['msg-0']
          },
          'reactions': {
            'taulight:fire': ['rizl'],
          }
        }
      };

      final dto = ChatDTO.fromMap(FakeClient(), map);
      expect(dto, isA<ChannelDTO>());
      expect(dto.getTitle(), equals('General'));
    });

    test('DialogDTO is parsed correctly', () {
      final map = {
        'type': 'dl',
        'id': '2',
        'dialog-other': 'user123',
        'last-message': {
          'id': 'msg-1',
          'creation-date': '2024-04-01T12:00:00Z',
          'message': {
            'chat-id': 'chat-1',
            'nickname': 'john',
            'content': 'Hello',
            'sys': false,
            'repliedToMessages': ['msg-0']
          },
          'reactions': {
            'taulight:fire': ['rizl'],
          }
        }
      };

      final dto = ChatDTO.fromMap(FakeClient(), map);
      expect(dto, isA<DialogDTO>());
      expect(dto.getTitle(), equals('user123'));
    });

    test('throws on unknown type', () {
      final map = {'type': 'xyz', 'id': '3'};
      expect(() => ChatDTO.fromMap(FakeClient(), map),
          throwsA(isA<ErrorDescription>()));
    });
  });
}
