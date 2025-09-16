import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/nickname.dart';
import 'package:taulight/classes/uuid.dart';

abstract class ExceptionMessage implements Exception {
  final String? message;
  const ExceptionMessage([this.message]);

  @override
  String toString() => "${runtimeType.toString()}: $message";
}

abstract class ClientException implements Exception {
  final Client client;

  const ClientException(this.client);

  @override
  String toString() {
    return "${runtimeType.toString()}: $client";
  }
}

class AddressedMemberNotFoundException extends ClientException {
  final Nickname nickname;
  const AddressedMemberNotFoundException(super.client, this.nickname);
}

class IncorrectFormatChannelException extends ExceptionMessage {
  IncorrectFormatChannelException([super.message]);
}

class IncorrectUserDataException extends ExceptionMessage {
  IncorrectUserDataException([super.message]);
}

class ClientNotFoundException extends ExceptionMessage {
  ClientNotFoundException([UUID? clientID]) : super(clientID?.toString());
}

class InvalidSandnodeLinkException extends ExceptionMessage {
  InvalidSandnodeLinkException([super.message]);
}

class KeyStorageNotFoundException extends ExceptionMessage {
  KeyStorageNotFoundException([super.message]);
}

class DisconnectException extends ClientException {
  DisconnectException(super.client) {
    client.connected = false;
  }
}

class ConnectionException extends DisconnectException {
  ConnectionException(super.client);
}

class BackClientNotFoundException extends DisconnectException {
  BackClientNotFoundException(super.client);
}

class ChatNotFoundException extends ClientException {
  ChatNotFoundException(super.client);
}

class UnauthorizedException extends ClientException {
  UnauthorizedException(super.client);
}

class BusyNicknameException extends ClientException {
  BusyNicknameException(super.client);
}

class PermissionDeniedException extends ClientException {
  PermissionDeniedException(super.client);
}

class LinkDoesNotMatchException extends ExceptionMessage {
  LinkDoesNotMatchException([super.message]);
}

class NotFoundException extends ClientException {
  dynamic object;

  NotFoundException(super.client, this.object);
}

class InvalidArgumentException extends ClientException {
  InvalidArgumentException(super.client);
}

class ExpiredTokenException extends InvalidArgumentException {
  ExpiredTokenException(super.client) {
    client.user?.expiredToken = true;
  }
}

class NoEffectException implements Exception {
  final dynamic object;
  const NoEffectException([this.object]);

  @override
  String toString() {
    return "NoEffectException: $object";
  }
}
