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
  final String encryption;
  final String? symKey;
  final String? publicKey;
  final String? privateKey;
  final Source source;

  PersonalKey({
    required this.encryption,
    required this.source,
    this.symKey,
    this.publicKey,
    this.privateKey,
  });

  factory PersonalKey.fromMap(Map<String, dynamic> json) {
    return PersonalKey(
      encryption: json['encryption']!,
      source: Source.fromMap(json['source']),
      symKey: json['sym'],
      publicKey: json['public'],
      privateKey: json['private'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'encryption': encryption,
      'source': source.toMap(),
      if (symKey != null) 'sym': symKey!,
      if (publicKey != null) 'public': publicKey!,
      if (privateKey != null) 'private': privateKey!,
    };
  }
}

class EncryptorKey {
  final String encryption;
  final String? symKey;
  final String? publicKey;
  final Source source;

  EncryptorKey({
    required this.encryption,
    required this.source,
    this.symKey,
    this.publicKey,
  });

  factory EncryptorKey.fromMap(Map<String, dynamic> json) {
    return EncryptorKey(
      encryption: json['encryption']!,
      source: Source.fromMap(json['source']),
      symKey: json['sym'],
      publicKey: json['public'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'encryption': encryption,
      'source': source.toMap(),
      if (symKey != null) 'sym': symKey!,
      if (publicKey != null) 'public': publicKey!,
    };
  }
}

class DEK {
  final UUID keyId;
  final String encryption;
  final String? symKey;
  final String? publicKey;
  final String? privateKey;
  final Source source;

  DEK({
    required this.keyId,
    required this.encryption,
    required this.source,
    this.symKey,
    this.publicKey,
    this.privateKey,
  });

  factory DEK.fromMap(Map<String, dynamic> map) {
    return DEK(
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
      'key-id': keyId.toString(),
      'encryption': encryption,
      'source': source.toMap(),
      if (symKey != null) 'sym': symKey!,
      if (publicKey != null) 'public': publicKey!,
      if (privateKey != null) 'private': privateKey!,
    };
  }
}
