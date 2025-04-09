import 'package:taulight/classes/client.dart';

class ExceptionMessage implements Exception {
  String? message;
  ExceptionMessage([this.message]);

  @override
  String toString() {
    return "${runtimeType.toString()}: $message";
  }
}

class ClientException implements Exception {
  final Client client;

  ClientException(this.client);

  @override
  String toString() {
    return "${runtimeType.toString()}: $client";
  }
}

class IncorrectFormatChannelException implements Exception {}

class IncorrectUserDataException implements Exception {}

class ClientNotFoundException extends ExceptionMessage {
  ClientNotFoundException([super.message]);
}

class InvalidSandnodeLinkException extends ExceptionMessage {
  InvalidSandnodeLinkException([super.message]);
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

class NotFound extends ClientException {
  dynamic object;

  NotFound(super.client, this.object);
}

class AddressedMemberNotFoundException extends ClientException {
  String nickname;
  AddressedMemberNotFoundException(super.client, this.nickname);
}

class InvalidTokenException extends ClientException {
  InvalidTokenException(super.client) {
    client.user?.authorized = false;
  }
}

class ExpiredTokenException extends InvalidTokenException {
  ExpiredTokenException(super.client);
}

class NotFoundException implements Exception {
  final String code;
  NotFoundException(this.code);

  @override
  String toString() {
    return "NotFoundException: $code";
  }
}

class NoEffectException implements Exception {
  final dynamic object;
  NoEffectException([this.object]);

  @override
  String toString() {
    return "NoEffectException: $object";
  }
}
