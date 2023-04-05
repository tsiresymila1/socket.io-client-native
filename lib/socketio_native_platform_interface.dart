import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'socketio_native_method_channel.dart';

abstract class SocketIoNativePlatform extends PlatformInterface {
  /// Constructs a SocketIoNativePlatform.
  SocketIoNativePlatform() : super(token: _token);

  static final Object _token = Object();

  static SocketIoNativePlatform _instance = MethodChannelSocketIoNative();

  /// The default instance of [SocketIoNativePlatform] to use.
  ///
  /// Defaults to [MethodChannelSocketIONative].
  static SocketIoNativePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SocketIoNativePlatform] when
  /// they register themselves.
  static set instance(SocketIoNativePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
  Future<void> setUri(String uri){
    throw UnimplementedError('setUri() has not been implemented.');
  }
  Future<void> setOption(String event,dynamic data){
    throw UnimplementedError('setOption() has not been implemented.');
  }
  Future<void> callSocketIoMethod(String event){
    throw UnimplementedError('setOption() has not been implemented.');
  }
  Future<dynamic> callSocketIoMethodWithCallback(String method, dynamic data, Map<String, dynamic> ? other) {
    throw UnimplementedError('setOption() has not been implemented.');
  }
}
