class CodeDTO {
  final String title;
  final String? receiver;
  final String sender;
  final DateTime creation;
  final DateTime? activation;
  final DateTime expires;

  bool get isExpired => DateTime.now().isAfter(expires);

  CodeDTO({
    required this.title,
    required this.receiver,
    required this.sender,
    required this.creation,
    required this.expires,
    this.activation,
  });

  factory CodeDTO.fromMap(map) {
    final activationString = map["activation-date"];
    DateTime? activation;

    if (activationString != null) {
      activation = DateTime.parse(activationString);
    }

    return CodeDTO(
      title: map["title"]!,
      receiver: map["receiver-nickname"],
      sender: map["sender-nickname"]!,
      creation: DateTime.parse(map["creation-date"]),
      expires: DateTime.parse(map["expires-date"]),
      activation: activation,
    );
  }
}
