import 'package:flutter_test/flutter_test.dart';
import 'package:taulight/services/storage_service.dart';

void main() {
  group('UserRecord', () {
    test('creation and conversion to Map', () {
      final user = UserRecord('testUser', 'testToken', 'test-KeyID');

      expect(user.nickname, equals('testUser'));
      expect(user.token, equals('testToken'));

      final map = user.toMap();
      expect(map, {
        'nickname': 'testUser',
        'token': 'testToken',
        'key-id': 'test-KeyID',
      });
    });

    test('creation from JSON', () {
      final json = {
        'nickname': 'testUser',
        'token': 'testToken',
        'key-id': 'test-KeyID',
      };

      final user = UserRecord.fromJSON(json);

      expect(user.nickname, equals('testUser'));
      expect(user.token, equals('testToken'));
    });
  });

  group('ServerRecord', () {
    test('creation without user', () {
      final server = ServerRecord(
        name: 'TestServer',
        link: 'sandnode://test.com',
      );

      expect(server.name, equals('TestServer'));
      expect(server.link, equals('sandnode://test.com'));
      expect(server.user, isNull);
    });

    test('creation with user', () {
      final user = UserRecord('testUser', 'testToken', 'test-KeyID');
      final server = ServerRecord(
        name: 'TestServer',
        link: 'sandnode://test.com',
        user: user,
      );

      expect(server.name, equals('TestServer'));
      expect(server.link, equals('sandnode://test.com'));
      expect(server.user, isNotNull);
      expect(server.user?.nickname, equals('testUser'));
      expect(server.user?.token, equals('testToken'));
    });

    test('conversion to Map without user', () {
      final server = ServerRecord(
        name: 'TestServer',
        link: 'sandnode://test.com',
      );

      final map = server.toMap();
      expect(map, {
        'name': 'TestServer',
        'link': 'sandnode://test.com',
      });
    });

    test('conversion to Map with user', () {
      final user = UserRecord('testUser', 'testToken', 'test-KeyID');
      final server = ServerRecord(
        name: 'TestServer',
        link: 'sandnode://test.com',
        user: user,
      );

      final map = server.toMap();
      expect(map, {
        'name': 'TestServer',
        'link': 'sandnode://test.com',
        'user': {
          'nickname': 'testUser',
          'token': 'testToken',
          'key-id': 'test-KeyID',
        },
      });
    });

    test('creation from JSON without user', () {
      final json = {
        'name': 'TestServer',
        'link': 'sandnode://test.com',
      };

      final server = ServerRecord.fromJSON(json);

      expect(server.name, equals('TestServer'));
      expect(server.link, equals('sandnode://test.com'));
      expect(server.user, isNull);
    });

    test('creation from JSON with user', () {
      final json = {
        'name': 'TestServer',
        'link': 'sandnode://test.com',
        'user': {
          'nickname': 'testUser',
          'token': 'testToken',
          'key-id': 'test-KeyID',
        },
      };

      final server = ServerRecord.fromJSON(json);

      expect(server.name, equals('TestServer'));
      expect(server.link, equals('sandnode://test.com'));
      expect(server.user, isNotNull);
      expect(server.user?.nickname, equals('testUser'));
      expect(server.user?.token, equals('testToken'));
    });
  });
}
