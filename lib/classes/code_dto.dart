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
    var activationString = map["activation-date"];
    DateTime? activation;

    if (activationString != null) {
      activation = DateTime.parse(activationString as String);
    }

    return CodeDTO(
      title: map["title"] as String,
      receiver: map["receiver-nickname"] as String?,
      sender: map["sender-nickname"] as String,
      creation: DateTime.parse(map["creation-date"] as String),
      expires: DateTime.parse(map["expires-date"] as String),
      activation: activation,
    );
  }
}
