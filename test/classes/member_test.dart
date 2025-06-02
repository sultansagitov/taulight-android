import 'package:flutter_test/flutter_test.dart';
import 'package:taulight/classes/chat_member.dart';

void main() {
  test('Member is parsed correctly from map', () {
    final map = {'nickname': 'testuser', 'status': 'offline'};
    final member = ChatMember.fromMap([], map);
    expect(member.nickname, 'testuser');
    expect(member.status, Status.offline);
  });
}