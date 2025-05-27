import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/records.dart';

class ChatMessageWrapperDTO {
  final String? decrypted;
  final ChatMessageViewDTO view;

  const ChatMessageWrapperDTO(this.view, [this.decrypted]);

  factory ChatMessageWrapperDTO.fromMap(Client client, map) {
    var view = ChatMessageViewDTO.fromMap(client, map["message"]);
    return ChatMessageWrapperDTO(view, map["decrypted"]);
  }
}
