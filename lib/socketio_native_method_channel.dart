import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'socketio_native_platform_interface.dart';

/// An implementation of [SocketIONativePlatform] that uses method channels.
class MethodChannelSocketIoNative extends SocketIoNativePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('socketio_native');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<dynamic> setUri(String uri) async {
    return await methodChannel.invokeMethod<dynamic>("SocketIO[setUri]", {"data" : uri});
  }

  @override
  Future<dynamic> setOption(String method, data) async {
    return await methodChannel.invokeMethod<dynamic>(method, {"data" : data});
  }

  @override
  Future<dynamic> callSocketIoMethod(String method) async {
    return await methodChannel.invokeMethod<dynamic>(method);
  }

  @override
  Future<dynamic> callSocketIoMethodWithCallback(String method, dynamic data, Map<String, dynamic> ? other) async {
    return await methodChannel.invokeMethod<dynamic>(method, {"data" : data, ...(other ?? {})});
  }
}
