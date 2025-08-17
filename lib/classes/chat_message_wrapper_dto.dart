import 'package:taulight/classes/chat_message_view_dto.dart';
import 'package:taulight/classes/client.dart';

class ChatMessageWrapperDTO {
  final String? decrypted;
  final ChatMessageViewDTO view;

  const ChatMessageWrapperDTO(this.view, [this.decrypted]);

  factory ChatMessageWrapperDTO.fromMap(Client client, map) {
    final view = ChatMessageViewDTO.fromMap(client, map["message"]);
    return ChatMessageWrapperDTO(view, map["decrypted"]);
  }
}
