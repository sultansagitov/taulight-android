import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taulight/classes/chat_dto.dart';
import 'package:taulight/classes/uuid.dart';

import 'message_dto_test.dart';

void main() {
  group('ChatDTO', () {
    test('GroupDTO is parsed correctly', () {
      final map = {
        'chat': {
          'type': 'gr',
          'id': UUID.random().toString(),
          'group-title': 'General',
          'group-owner': 'admin',
          'avatar': UUID.random().toString(),
          'last-message': {
            'id': UUID.random().toString(),
            'creation-date': '2024-04-01T12:00:00Z',
            'message': {
              'chat-id': UUID.random().toString(),
              'sent-datetime': '2024-04-01T12:00:00Z',
              'nickname': 'john',
              'content': 'Hello',
              'sys': false,
              'replied-to-messages': [UUID.random().toString()]
            },
            'reactions': {
              'taulight:fire': ['rizl'],
            }
          }
        }
      };

      final dto = ChatDTO.fromMap(FakeClient(), map);
      expect(dto, isA<GroupDTO>());
      expect(dto.getTitle(), equals('General'));
    });

    test('DialogDTO is parsed correctly', () {
      final map = {
        'chat': {
          'type': 'dl',
          'id': UUID.random().toString(),
          'dialog-other': 'user123',
          'avatar': UUID.random().toString(),
          'last-message': {
            'id': UUID.random().toString(),
            'creation-date': '2024-04-01T12:00:00Z',
            'message': {
              'chat-id': UUID.random().toString(),
              'sent-datetime': '2024-04-01T12:00:00Z',
              'nickname': 'john',
              'content': 'Hello',
              'sys': false,
              'replied-to-messages': [UUID.random().toString()]
            },
            'reactions': {
              'taulight:fire': ['rizl'],
            }
          }
        }
      };

      final dto = ChatDTO.fromMap(FakeClient(), map);
      expect(dto, isA<DialogDTO>());
      expect(dto.getTitle(), equals('user123'));
    });

    test('throws on unknown type', () {
      final map = {
        'chat': {'type': 'xyz', 'id': UUID.random().toString()}
      };
      expect(() => ChatDTO.fromMap(FakeClient(), map),
          throwsA(isA<ErrorDescription>()));
    });
  });
}
