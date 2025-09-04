import 'package:taulight/classes/nickname.dart';
import 'package:taulight/classes/sources.dart';
import 'package:taulight/classes/uuid.dart';

class ServerKey {
  final String address;
  final String publicKey;
  final String encryption;
  final Source source;

  ServerKey({
    required this.address,
    required this.publicKey,
    required this.encryption,
    required this.source,
  });

  factory ServerKey.fromMap(Map<String, dynamic> json) {
    return ServerKey(
      address: json['address']!,
      publicKey: json['public']!,
      encryption: json['encryption']!,
      source: Source.fromMap(json['source']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'public': publicKey,
      'encryption': encryption,
      'source': source.toMap(),
    };
  }
}

class PersonalKey {
  final Nickname nickname;
  final String address;
  final String encryption;
  final String? symKey;
  final String? publicKey;
  final String? privateKey;
  final Source source;

  PersonalKey({
    required this.nickname,
    required this.address,
    required this.encryption,
    required this.source,
    this.symKey,
    this.publicKey,
    this.privateKey,
  });

  factory PersonalKey.fromMap(Map<String, dynamic> json) {
    return PersonalKey(
      nickname: Nickname(json['nickname']),
      address: json['address']!,
      encryption: json['encryption']!,
      source: Source.fromMap(json['source']),
      symKey: json['sym'],
      publicKey: json['public'],
      privateKey: json['private'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nickname': nickname.toString(),
      'address': address,
      'encryption': encryption,
      'source': source.toMap(),
      if (symKey != null) 'sym': symKey!,
      if (publicKey != null) 'public': publicKey!,
      if (privateKey != null) 'private': privateKey!,
    };
  }
}

class EncryptorKey {
  final Nickname nickname;
  final String address;
  final String encryption;
  final String? symKey;
  final String? publicKey;
  final Source source;

  EncryptorKey({
    required this.nickname,
    required this.address,
    required this.encryption,
    required this.source,
    this.symKey,
    this.publicKey,
  });

  factory EncryptorKey.fromMap(Map<String, dynamic> json) {
    return EncryptorKey(
      nickname: Nickname(json['nickname']),
      address: json['address']!,
      encryption: json['encryption']!,
      source: Source.fromMap(json['source']),
      symKey: json['sym'],
      publicKey: json['public'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nickname': nickname.toString(),
      'address': address,
      'encryption': encryption,
      'source': source.toMap(),
      if (symKey != null) 'sym': symKey!,
      if (publicKey != null) 'public': publicKey!,
    };
  }
}

class DEK {
  final Nickname firstNickname;
  final String firstAddress;
  final Nickname secondNickname;
  final String secondAddress;
  final UUID keyId;
  final String encryption;
  final String? symKey;
  final String? publicKey;
  final String? privateKey;
  final Source source;

  DEK({
    required this.firstNickname,
    required this.firstAddress,
    required this.secondNickname,
    required this.secondAddress,
    required this.keyId,
    required this.encryption,
    required this.source,
    this.symKey,
    this.publicKey,
    this.privateKey,
  });

  factory DEK.fromMap(Map<String, dynamic> map) {
    return DEK(
      firstNickname: Nickname(map['first-nickname']),
      firstAddress: map['first-address']!,
      secondNickname: Nickname(map['second-nickname']),
      secondAddress: map['second-address']!,
      keyId: UUID.fromString(map['key-id']),
      encryption: map['encryption']!,
      source: Source.fromMap(map['source']),
      symKey: map['sym'],
      publicKey: map['public'],
      privateKey: map['private'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'first-nickname': firstNickname.toString(),
      'first-address': firstAddress,
      'second-nickname': secondNickname.toString(),
      'second-address': secondAddress,
      'key-id': keyId.toString(),
      'encryption': encryption,
      'source': source.toMap(),
      if (symKey != null) 'sym': symKey!,
      if (publicKey != null) 'public': publicKey!,
      if (privateKey != null) 'private': privateKey!,
    };
  }
}
