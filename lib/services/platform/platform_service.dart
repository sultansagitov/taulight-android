import 'package:flutter/services.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/exceptions.dart';

class PlatformService {
  static final PlatformService _instance = PlatformService._internal();
  static PlatformService get ins => _instance;
  PlatformService._internal();

  static const methodChannelName = 'net.result.taulight/messenger';
  final MethodChannel platform = MethodChannel(methodChannelName);

  void setMethodCallHandler(Future Function(MethodCall call)? handler) {
    platform.setMethodCallHandler(handler);
  }

  Future<Result> method(String methodName, [Map<String, dynamic>? args]) async {
    print("Called on platform --- \"$methodName\"");
    Map result = (await platform.invokeMethod<Map>(methodName, args ?? {}))!;
    var chainMethodName = methodName == "chain" ? args!["method"] : "";
    print("Result of \"$methodName\" - $chainMethodName - $result");

    var error = result["error"];
    if (error != null) {
      return ExceptionResult(error["name"], error["message"]);
    }

    return SuccessResult(result["success"]);
  }

  Future<Result> chain(
    String methodName, {
    required Client client,
    List<dynamic>? params,
  }) async {
    return await method("chain", {
      "uuid": client.uuid,
      "method": methodName,
      if (params != null) "params": params,
    });
  }
}

abstract class Result {}

class ExceptionResult extends Result implements Exception {
  final String name;
  final String? msg;

  ExceptionResult(this.name, [this.msg]);

  Exception getCause([Client? client]) {
    const list = [
      "InterruptedException",
      "UnexpectedSocketDisconnectException",
    ];

    if (list.contains(name)) {
      throw DisconnectException(client!);
    }

    switch (name) {
      case "ConnectionException":
        return ConnectionException(client!);
      case "ExpiredTokenException":
        return ExpiredTokenException(client!);
      case "InvalidArgumentException":
        return InvalidArgumentException(client!);
      case "UnauthorizedException":
        return UnauthorizedException(client!);
      case "ClientNotFoundException":
        return BackClientNotFoundException(client!);
      case "BusyNicknameException":
        return BusyNicknameException(client!);
      case "PermissionDeniedException":
        return PermissionDeniedException(client!);
      default:
        return this;
    }
  }

  @override
  String toString() => "Platform - $name: $msg";
}

class SuccessResult extends Result {
  final dynamic obj;
  SuccessResult(this.obj);
}
