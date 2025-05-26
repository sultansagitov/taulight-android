import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/records.dart';

class ChatMessageWrapperDTO {
  final String decrypted;
  final ChatMessageViewDTO view;

  const ChatMessageWrapperDTO(this.decrypted, this.view);

  factory ChatMessageWrapperDTO.fromMap(Client client, map) {
    return ChatMessageWrapperDTO(
      map["decrypted"],
      ChatMessageViewDTO.fromMap(client, map["message"]),
    );
  }
}
