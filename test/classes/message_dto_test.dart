import 'package:flutter_test/flutter_test.dart';
import 'package:taulight/classes/chat_message_view_dto.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/nickname.dart';
import 'package:taulight/classes/user.dart';
import 'package:taulight/classes/uuid.dart';

class FakeClient extends Client {
  FakeClient() : super(uuid: UUID.nil, address: 'example.com');

  @override
  get user => FakeUser(this);
}

class FakeUser extends User {
  FakeUser(Client client) : super(client, Nickname("a"), "");

  @override
  Nickname get nickname => Nickname('john');
}

void main() {
  test('ChatMessageViewDTO parses correctly', () {
    final client = FakeClient();

    final repliedToMessages = UUID.random();
    final json = {
      'id': UUID.random().toString(),
      'creation-date': '2024-04-01T12:00:00Z',
      'message': {
        'chat-id': UUID.random().toString(),
        'sent-datetime': '2024-04-01T12:00:00Z',
        'nickname': 'john',
        'content': 'Hello',
        'sys': false,
        'replied-to-messages': [repliedToMessages.toString()]
      },
      'reactions': {
        'taulight:fire': ['rizl'],
      }
    };

    final dto = ChatMessageViewDTO.fromMap(client, json);
    expect(dto.isMe, isTrue);
    expect(dto.text, 'Hello');
    expect(dto.repliedToMessages.length, equals(1));
    expect(dto.repliedToMessages.single, repliedToMessages);
  });
}
