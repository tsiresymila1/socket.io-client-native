import 'dart:async';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:socketio_native/socketio_native_event_channel.dart';
import 'socketio_native_platform_interface.dart';

// SocketIo transport
enum SocketIoTransport {
  websocket,
  polling,
}

/*

Initialized Option
 */
class Option {
  final Map<String, dynamic> _options = {
    "Option[setForceNew]": false,
    "Option[setMultiplex]": true,
    "Option[setUpgrade]": true,
    "Option[setRememberUpgrade]": false,
    "Option[setPath]": "/socket.io/",
    "Option[setQuery]": null,
    "Option[setExtraHeaders]": null,
    "Option[setReconnection]": true,
    "Option[setReconnectionDelay]": 1000,
    "Option[setReconnectionDelayMax]": 5000,
    "Option[setRandomizationFactor]": 0.5,
    "Option[setTimeout]": 20000,
    "Option[setTransport]": [
      SocketIoTransport.polling.name,
      SocketIoTransport.websocket.name
    ]
  };

  setForceNew(bool isForceNew) {
    _options["Option[setForceNew]"] = isForceNew;
  }

  setSecure(bool isSecure) {
    _options["Option[setSecure]"] = isSecure;
  }

  setReconnection(bool reconnect) {
    _options["Option[setReconnection]"] = reconnect;
  }

  setReconnectionDelay(double delay) {
    _options["Option[setReconnectionDelay]"] = double.tryParse(delay.toString());
  }

  setReconnectionDelayMax(double delay) {
    _options["Option[setReconnectionDelayMax]"] = double.tryParse(delay.toString());
  }

  setReconnectionAttempts(int attempts) {
    _options["Option[setReconnectionDelayMax]"] = attempts;
  }

  setMultiplex(bool isMultiplex) {
    _options["Option[setMultiplex]"] = isMultiplex;
  }

  setUpgrade(bool upgrade) {
    _options["Option[setUpgrade]"] = upgrade;
  }

  setRememberUpgrade(bool upgrade) {
    _options["Option[setRememberUpgrade]"] = upgrade;
  }

  setRandomizationFactor(double factor) {
    _options["Option[setRandomizationFactor]"] = factor;
  }

  setTimeout(double timeout) {
    _options["Option[setTimeout]"] = double.tryParse(timeout.toString());
  }

  disableAutoConnect() {
    _options["Option[disableAutoConnect]"] = true;
  }

  setTransport(List<SocketIoTransport> transports) {
    _options["Option[setTransport]"] = transports.map((e) => e.name).toList();
    toString();
  }

  setPath(String path) {
    _options["Option[setPath]"] = path;
  }

  setQuery(String query) {
    _options["Option[setQuery]"] = query;
  }

  setExtraHeaders(Map<String, List<String>> extras) {
    _options["Option[setExtraHeaders]"] = extras;
  }

  setAuth(Map<String, dynamic> auth) {
    _options["Option[setAuth]"] = auth;
  }

  // To Map data
  Map<String, dynamic> build() {
    return _options;
  }
}

class IO {
  static Future<SocketIO> create(String uri, {Option? option}) async {
    SocketIO io =  SocketIO(uri: uri, option: option);
    await io.init();
    return io;
  }
}

// SocketIo class
class SocketIO {
  final String uri;
  late final Option option;
  late Logger log;
  bool? connected;
  String? id;
  bool active = false;

  Map<String, StreamSubscription<dynamic>> channels = {};

  SocketIO({required this.uri, Option? option}) {
    this.option = option ?? Option();
    log = Logger(
        printer: PrettyPrinter(
      methodCount: 1,
      stackTraceBeginIndex: 1,
      errorMethodCount: 1,
    ));
  }

  // init socket
  init() async {
    channels = {};
    await SocketIoNativePlatform.instance.setUri(uri);
    for (MapEntry<String, dynamic> opt in option.build().entries) {
      await SocketIoNativePlatform.instance.setOption(opt.key, opt.value);
    }
    await SocketIoNativePlatform.instance.callSocketIoMethod("SocketIO[init]");
  }

  // reconnect socket manually
  reconnect() async {
    await SocketIoNativePlatform.instance
        .callSocketIoMethod("SocketIO[connect]");
  }

  // connect from socket manually
  connect() async {
    return await SocketIoNativePlatform.instance
        .callSocketIoMethod("SocketIO[connect]");
  }
  // disconnect from socket
  disconnect() async {
    return await SocketIoNativePlatform.instance
        .callSocketIoMethod("SocketIO[disconnect]");
  }
  // send data
  send(dynamic data) async {
    await SocketIoNativePlatform.instance
        .callSocketIoMethodWithCallback("SocketIO[send]", [data], null);
  }

  // emit data
  emit(String event, dynamic data, {Function(dynamic)? ack}) async {
    SocketIoNativePlatform.instance.callSocketIoMethodWithCallback(
        "SocketIO[emit]", [data], {"event": event}).then((value) {
      if (ack != null) {
        try{
          var data = jsonDecode(value.toString());
          ack.call(data);
        }catch(e){
          ack.call(value);
        }
      }
    }).onError((error, stackTrace) {
      log.e({"ERROR": error});
    });
  }

  // emit with timeout
  emitWithTimeout(String event, dynamic data, int timeout,
      {Function(dynamic)? ack}) async {
    try {
      SocketIoNativePlatform.instance.callSocketIoMethodWithCallback(
          "SocketIO[emitTimeout]",
          [data],
          {"event": event, "timeout": timeout}).then((value) {
        if (ack != null) {
          ack.call(value);
        }
      });
    } catch (e) {
      throw Exception("Timeout exception");
    }
  }

  // clear event listener
  off(String event) async {
    await SocketIoNativePlatform.instance
        .callSocketIoMethodWithCallback("SocketIO[off]", event, null);
  }

  // clear all event listener
  offAny() async {
    await SocketIoNativePlatform.instance
        .callSocketIoMethod("SocketIO[offAll]");
  }

  // listen on event
  on(String event, Function(dynamic) callback) {
    _createListener("SocketIO[on]", event, callback);
  }

  // listen single
  once(String event, Function(dynamic) callback) {
    _createListener("SocketIO[once]", event, callback);
  }

  // listen on connected
  onConnect(Function(dynamic) callback) {
    _createListener("SocketIO[onConnect]", "connect", (data) {
      connected = data["connected"] ?? false;
      id = data["id"];
      active = data["active"];
      callback(this);
    });
  }

  // listen error from socket
  onError(Function(dynamic) callback) {
    _createListener("SocketIO[onError]", "connect_error", callback);
  }

  // listen when socket disconnected
  onDisconnect(Function(dynamic) callback) {
    _createListener("SocketIO[onDisconnect]", "disconnect", (data) {
      connected = data["connected"];
      id = data["id"];
      active = data["active"];
      callback(this);
    });
  }

  // listen for any events
  onAny(Function(dynamic) callback) {
    SocketIoNativePlatform.instance
        .callSocketIoMethod("SocketIO[onAny]")
        .then((value) {
      EventChannelSocketIoNative(null)
          .eventChannel
          .receiveBroadcastStream()
          .listen((data) {
        try{
          var value = jsonDecode(data);
          callback(value);
        }catch(e){
          callback(data);
        }
      }, onError: (error) {
        log.e({"ERROR": error});
      }, onDone: () {
        log.w("DONNE");
      });
    });
  }

  // close socket
  close() {
    disconnect();
    for (var ch in channels.values) {
      ch.cancel();
    }
  }

  // private create listener
  _createListener(String method, String event, Function(dynamic) callback) {
    if (channels.keys.contains(event)) {
      channels[event]?.cancel();
    }
    SocketIoNativePlatform.instance
        .callSocketIoMethodWithCallback(method, event, null)
        .then((value) {
      EventChannelSocketIoNative chl = EventChannelSocketIoNative(event);
      StreamSubscription<dynamic> stream =
          chl.eventChannel.receiveBroadcastStream().listen((data) {
            try{
              var value = jsonDecode(data);
              callback(value);
            }catch(e){
              callback(data);
            }
      }, onError: (error) {
        log.e({"ERROR": error});
      }, onDone: () {
        log.w("DONNE");
      },cancelOnError: true);
      channels[event] = stream;

    });
  }
}
