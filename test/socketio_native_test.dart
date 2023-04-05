import 'package:flutter_test/flutter_test.dart';
import 'package:socketio_native/socketio_native.dart';
import 'package:socketio_native/socketio_native_platform_interface.dart';
import 'package:socketio_native/socketio_native_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSocketIoNativePlatform
    with MockPlatformInterfaceMixin
    implements SocketIoNativePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<void> setUri(String uri) {
    // TODO: implement setUri
    throw UnimplementedError();
  }

  @override
  Future<void> setOption(String event, data) {
    // TODO: implement setOption
    throw UnimplementedError();
  }

  @override
  Future<void> callSocketIoMethod(String event) {
    throw UnimplementedError();
  }

  @override
  Future callSocketIoMethodWithCallback(String method, data, Map<String, dynamic>? other) {
    // TODO: implement callSocketIoMethodWithCallback
    throw UnimplementedError();
  }

  
}

void main() {
  final SocketIoNativePlatform initialPlatform = SocketIoNativePlatform.instance;

  test('$MethodChannelSocketIoNative is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSocketIoNative>());
  });

  test('getPlatformVersion', () async {
    SocketIO socketIo = IO.create("https://realtimeio.sutchapp.com");
    MockSocketIoNativePlatform fakePlatform = MockSocketIoNativePlatform();
    SocketIoNativePlatform.instance = fakePlatform;

    // expect(await socketIo.init(), '42');
  });
}
