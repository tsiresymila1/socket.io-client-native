import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class EventChannelSocketIoNative extends PlatformInterface {
  late final EventChannel eventChannel;

  EventChannelSocketIoNative(String? event) : super(token: _token) {
    if (event != null) {
      eventChannel = EventChannel("socketio_native/eventChannel/$event");
    } else {
      eventChannel = const EventChannel("socketio_native/eventChannel");
    }
  }

  static final Object _token = Object();
}
