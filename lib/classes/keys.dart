class ServerKey {
  final String address;
  final String publicKey;
  final String encryption;

  ServerKey({
    required this.address,
    required this.publicKey,
    required this.encryption,
  });

  factory ServerKey.fromMap(Map<String, String> json) {
    return ServerKey(
      address: json['address']!,
      publicKey: json['public']!,
      encryption: json['encryption']!,
    );
  }

  Map<String, String> toMap() {
    return {
      'address': address,
      'public': publicKey,
      'encryption': encryption,
    };
  }
}

class PersonalKey {
  final String encryption;
  final String? symKey;
  final String? publicKey;
  final String? privateKey;

  PersonalKey({
    required this.encryption,
    this.symKey,
    this.publicKey,
    this.privateKey,
  });

  factory PersonalKey.fromMap(Map<String, String> json) {
    return PersonalKey(
        encryption: json['encryption']!,
        symKey: json['sym'],
        publicKey: json['public'],
        privateKey: json['private'],
      );
  }

  Map<String, String> toMap() {
    return {
        'encryption': encryption,
        if (symKey != null) 'sym': symKey!,
        if (publicKey != null) 'public': publicKey!,
        if (privateKey != null) 'private': privateKey!,
      };
  }
}

class EncryptorKey {
  final String keyId;
  final String encryption;
  final String? symKey;
  final String? publicKey;

  EncryptorKey({
    required this.keyId,
    required this.encryption,
    this.symKey,
    this.publicKey,
  });

  factory EncryptorKey.fromMap(Map<String, String> json) {
    return EncryptorKey(
      keyId: json['key-id']!,
      encryption: json['encryption']!,
      symKey: json['sym'],
      publicKey: json['public'],
    );
  }

  Map<String, String> toMap() {
    return {
      'key-id': keyId,
      'encryption': encryption,
      if (symKey != null) 'sym': symKey!,
      if (publicKey != null) 'public': publicKey!,
    };
  }
}

class DEK {
  final String keyId;
  final String encryption;
  final String? symKey;
  final String? publicKey;
  final String? privateKey;

  DEK({
    required this.keyId,
    required this.encryption,
    this.symKey,
    this.publicKey,
    this.privateKey,
  });

  factory DEK.fromMap(Map<String, String> json) {
    return DEK(
      keyId: json['key-id']!,
      encryption: json['encryption']!,
      symKey: json['sym'],
      publicKey: json['public'],
      privateKey: json['private'],
    );
  }

  Map<String, String> toMap() {
    return {
      'key-id': keyId,
      'encryption': encryption,
      if (symKey != null) 'sym': symKey!,
      if (publicKey != null) 'public': publicKey!,
      if (privateKey != null) 'private': privateKey!,
    };
  }
}
