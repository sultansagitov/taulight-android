import 'package:taulight/classes/nickname.dart';

abstract class Source {
  final DateTime createdAt;
  get type => runtimeType.toString();

  const Source({required this.createdAt});

  factory Source.fromMap(Map map) {
    final String name = map["name"]!;
    final data = map["data"]!;
    final DateTime createdAt = DateTime.parse(data["createdAt"]);

    switch (name) {
      case "GeneratedSource":
        return GeneratedSource(createdAt: createdAt);
      case "QRSource":
        return QRSource(createdAt: createdAt);
      case "LinkSource":
        final String link = data["link"]!;
        return LinkSource(link: link, createdAt: createdAt);
      case "ServerSource":
        final String address = data["address"]!;
        return ServerSource(address: address, createdAt: createdAt);
      case "DEKServerSource":
        final String address = data["address"]! as String;
        final member = data["personalKeyOwner"]! as String;
        final split = member.split("@");
        final nickname = Nickname.checked(split[0]);
        final memberAddress = split[1];
        return DEKServerSource(
          address: address,
          createdAt: createdAt,
          memberNickname: nickname,
          memberAddress: memberAddress,
        );
      default:
        throw Exception("Unknown name \"$name\"");
    }
  }

  Map<String, String> toMap() => {"createdAt": createdAt.toIso8601String()};

  Map<String, dynamic> toFullMap() => {'name': type, 'data': toMap()};
}

class QRSource extends Source {
  const QRSource({required super.createdAt});

  factory QRSource.now() => QRSource(createdAt: DateTime.now());
}

class GeneratedSource extends Source {
  const GeneratedSource({required super.createdAt});
}

class LinkSource extends Source {
  final String link;

  const LinkSource({required this.link, required super.createdAt});
}

class ServerSource extends Source {
  final String address;

  const ServerSource({required this.address, required super.createdAt});

  @override
  Map<String, String> toMap() => {...super.toMap(), 'address': address};
}

class DEKServerSource extends ServerSource {
  final Nickname memberNickname;
  final String memberAddress;

  const DEKServerSource({
    required this.memberNickname,
    required this.memberAddress,
    required super.address,
    required super.createdAt,
  });

  @override
  Map<String, String> toMap() => {
        ...super.toMap(),
        'personalKeyOwner': "$memberNickname@$memberAddress",
      };
}
