import 'package:flutter_test/flutter_test.dart';
import 'package:taulight/utils.dart';

void main() {
  group('link2address with scheme and query', () {
    test('sandnode scheme with domain', () {
      expect(link2address('sandnode://example.com'), 'example.com');
    });

    test('https scheme with domain and default port stripped', () {
      expect(link2address('https://example.com:52525'), 'example.com');
    });

    test('https scheme with domain and non-default port', () {
      expect(link2address('https://example.com:8080'), 'example.com:8080');
    });

    test('http scheme with IPv4', () {
      expect(link2address('http://192.168.1.1'), '192.168.1.1');
    });

    test('https scheme with IPv4 and port', () {
      expect(link2address('https://192.168.1.1:9090'), '192.168.1.1:9090');
    });

    test('http scheme with IPv6', () {
      expect(link2address('http://[2001:db8::1]'), '[2001:db8::1]');
    });

    test('https scheme with IPv6 and port', () {
      expect(link2address('https://[2001:db8::1]:6000'), '[2001:db8::1]:6000');
    });

    test('domain with query params', () {
      expect(link2address('example.com?foo=bar&x=1'), 'example.com');
    });

    test('domain with port and query params', () {
      expect(link2address('example.com:8080?foo=bar'), 'example.com:8080');
    });

    test('http scheme with query params', () {
      expect(link2address('http://example.com?foo=bar'), 'example.com');
    });

    test('https scheme with port and query params', () {
      expect(
        link2address('https://example.com:8080?foo=bar&baz=qux'),
        'example.com:8080',
      );
    });
  });

  group('link2address valid inputs', () {
    test('domain without port', () {
      expect(link2address('example.com'), 'example.com');
    });

    test('domain with 52525 to default, stripped', () {
      expect(link2address('example.com:52525'), 'example.com');
    });

    test('domain with another port', () {
      expect(link2address('example.com:8080'), 'example.com:8080');
    });

    test('localhost without port', () {
      expect(link2address('localhost'), 'localhost');
    });

    test('localhost with 52525 to default, stripped', () {
      expect(link2address('localhost:52525'), 'localhost');
    });

    test('localhost with another port', () {
      expect(link2address('localhost:8080'), 'localhost:8080');
    });

    test('IPv4 without port', () {
      expect(link2address('192.168.1.1'), '192.168.1.1');
    });

    test('IPv4 with 52525 to default, stripped', () {
      expect(link2address('192.168.1.1:52525'), '192.168.1.1');
    });

    test('IPv4 with another port', () {
      expect(link2address('192.168.1.1:1234'), '192.168.1.1:1234');
    });

    test('IPv6 ::1 without port', () {
      expect(link2address('::1'), '[::1]');
    });

    test('IPv6 ::1 with 52525 to default, stripped', () {
      expect(link2address('[::1]:52525'), '[::1]');
    });

    test('IPv6 ::1 with another port', () {
      expect(link2address('[::1]:9999'), '[::1]:9999');
    });

    test('long IPv6 without port', () {
      expect(link2address('2001:db8::abcd'), '[2001:db8::abcd]');
    });

    test('long IPv6 with 52525 to default, stripped', () {
      expect(link2address('[2001:db8::abcd]:52525'), '[2001:db8::abcd]');
    });

    test('long IPv6 with another port', () {
      expect(link2address('[2001:db8::abcd]:7777'), '[2001:db8::abcd]:7777');
    });

    test('full IPv6 without port', () {
      expect(
        link2address('2001:0db8:1234:5678:9abc:def0:1357:abcd'),
        '[2001:0db8:1234:5678:9abc:def0:1357:abcd]',
      );
    });

    test('full IPv6 with 52525 to default, stripped', () {
      expect(
        link2address('[2001:0db8:1234:5678:9abc:def0:1357:abcd]:52525'),
        '[2001:0db8:1234:5678:9abc:def0:1357:abcd]',
      );
    });

    test('full IPv6 with another port', () {
      expect(
        link2address('[2001:0db8:1234:5678:9abc:def0:1357:abcd]:7777'),
        '[2001:0db8:1234:5678:9abc:def0:1357:abcd]:7777',
      );
    });
  });

  group('link2address invalid inputs', () {
    test('empty string', () {
      expect(() => link2address(''), throwsFormatException);
    });

    test('non-numeric port', () {
      expect(() => link2address('example.com:abc'), throwsFormatException);
    });

    test('double port', () {
      expect(() => link2address('example.com:123:456'), throwsFormatException);
    });

    test('IPv6 bracket not closed', () {
      expect(() => link2address('[2001:db8::1'), throwsFormatException);
    });

    test('garbage input', () {
      expect(() => link2address('!!!@@@###'), throwsFormatException);
    });
  });
}
