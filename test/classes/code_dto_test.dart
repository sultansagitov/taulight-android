import 'package:flutter_test/flutter_test.dart';
import 'package:taulight/classes/code_dto.dart';

void main() {
  test('CodeDTO parses correctly', () {
    final map = {
      'title': 'Invite',
      'receiver-nickname': 'user1',
      'sender-nickname': 'admin',
      'creation-date': '2024-01-01T10:00:00Z',
      'activation-date': '2024-01-02T10:00:00Z',
      'expires-date': '2030-01-01T10:00:00Z',
    };

    final dto = CodeDTO.fromMap(map);
    expect(dto.title, 'Invite');
    expect(dto.receiver?.toString(), 'user1');
    expect(dto.sender.toString(), 'admin');
    expect(dto.activation, isNotNull);
    expect(dto.isExpired, false);
  });
}
