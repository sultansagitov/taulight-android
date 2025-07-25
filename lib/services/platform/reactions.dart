import 'package:taulight/classes/chat_message_view_dto.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/services/platform/platform_service.dart';

class PlatformReactionService {
  static final _instance = PlatformReactionService._internal();
  static PlatformReactionService get ins => _instance;
  PlatformReactionService._internal();

  Future<void> react(
    Client client,
    ChatMessageViewDTO message,
    String reactionType,
  ) async {
    Result result = await PlatformService.ins.chain(
      "ReactionRequestClientChain.react",
      client: client,
      params: [message.id, reactionType],
    );

    if (result is ExceptionResult) {
      if (result.name == "NotFoundException") {
        throw ChatNotFoundException(client);
      }
      throw result.getCause(client);
    }
  }

  Future<void> unreact(
    Client client,
    ChatMessageViewDTO message,
    String reactionType,
  ) async {
    Result result = await PlatformService.ins.chain(
      "ReactionRequestClientChain.unreact",
      client: client,
      params: [message.id, reactionType],
    );

    if (result is ExceptionResult) {
      if (result.name == "NotFoundException") {
        throw ChatNotFoundException(client);
      }
      throw result.getCause(client);
    }
  }
}
