import 'package:flutter_test/flutter_test.dart';
import 'package:taulight/classes/chat_message_view_dto.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/user.dart';

class FakeClient extends Client {
  FakeClient()
      : super(
          uuid: '1234',
          address: 'example.com',
          link: '',
        );

  @override
  get user => FakeUser(this, "", "");
}

class FakeUser extends User {
  FakeUser(super.client, super.nickname, super.token);

  @override
  String get nickname => 'john';
}

void main() {
  test('ChatMessageViewDTO parses correctly', () {
    final client = FakeClient();

    final json = {
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
    };

    final dto = ChatMessageViewDTO.fromMap(client, json);
    expect(dto.isMe, isTrue);
    expect(dto.text, 'Hello');
    expect(dto.repliedToMessages, equals(['msg-0']));
  });
}
