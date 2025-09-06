import 'package:taulight/classes/chat_message_view_dto.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/uuid.dart';

class ChatMessageWrapperDTO {
  final String? decrypted;
  final ChatMessageViewDTO view;
  bool isLoading = false;

  ChatMessageWrapperDTO(this.view, [this.decrypted]);

  factory ChatMessageWrapperDTO.fromMap(Client client, map) {
    final view = ChatMessageViewDTO.fromMap(client, map["message"]);
    return ChatMessageWrapperDTO(view, map["decrypted"]);
  }

  factory ChatMessageWrapperDTO.loading(
    ChatMessageViewDTO message, [
    String? decrypted,
  ]) =>
      ChatMessageWrapperDTO(message, decrypted)..isLoading = true;

  void onLoad(dynamic map) {
    isLoading = false;
    view.id = UUID.fromString(map["id"]!);
    view.creationDate = DateTime.parse(map["creation-date"]!).toLocal();
    view.keyID = UUID.fromNullableString(map["key"]);
  }
}
