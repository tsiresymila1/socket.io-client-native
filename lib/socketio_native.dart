import 'package:logger/logger.dart';
import 'package:socketio_native/socketio_native_event_channel.dart';
import 'socketio_native_platform_interface.dart';

enum SocketIoTransport {
  websocket,
  polling,
}

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
    "Option[setTransport]": [SocketIoTransport.polling.name,SocketIoTransport.websocket.name]
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
    _options["Option[setReconnectionDelay]"] = delay;
  }

  setReconnectionDelayMax(double delay) {
    _options["Option[setReconnectionDelayMax]"] = delay;
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

  setTimeout(int timeout) {
    _options["Option[setTimeout]"] = timeout;
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

  setAuth(Map<String, String> auth) {
    _options["Option[setAuth]"] = auth;
  }

  Map<String, dynamic> build() {
    return _options;
  }
}

class IO {
  static create(String uri, {Option? option}) {
    return SocketIO(uri: uri, option: option);
  }
}

class SocketIO {
  final String uri;
  late final Option option;
  late Logger log;
  Map<String, EventChannelSocketIoNative> channels = {};

  SocketIO({required this.uri, Option? option}) {
    this.option = option ?? Option();
    log = Logger(
        printer: PrettyPrinter(
      methodCount: 1,
      stackTraceBeginIndex: 1,
      errorMethodCount: 1,
    ));
  }

  init() async {
    channels = {};
    await SocketIoNativePlatform.instance.setUri(uri);
    for (MapEntry<String, dynamic> opt in option.build().entries) {
      await SocketIoNativePlatform.instance.setOption(opt.key, opt.value);
    }
    await SocketIoNativePlatform.instance.callSocketIoMethod("SocketIO[init]");
    // await SocketIoNativePlatform.instance
    //     .callSocketIoMethod("SocketIO[connect]");
  }

  reconnect() async {
    await SocketIoNativePlatform.instance
        .callSocketIoMethod("SocketIO[connect]");
  }
  connect() async {
    await SocketIoNativePlatform.instance
        .callSocketIoMethod("SocketIO[connect]");
  }

  disconnect() async {
    await SocketIoNativePlatform.instance
        .callSocketIoMethod("SocketIO[disconnect]");
  }

  send(dynamic data) async {
    await SocketIoNativePlatform.instance
        .callSocketIoMethodWithCallback("SocketIO[send]", [data], null);
  }

  emit(String event, dynamic data, {Function(dynamic)? ack}) async {
    SocketIoNativePlatform.instance.callSocketIoMethodWithCallback(
        "SocketIO[emit]", [data], {"event": event}).then((value) {
      if (ack != null) {
        ack.call(value);
      }
    }).onError((error, stackTrace) {
      log.e({"ERROR": error});
    });
  }

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

  off(String event) async {
    await SocketIoNativePlatform.instance
        .callSocketIoMethodWithCallback("SocketIO[off]", event, null);
  }

  offAny() async {
    await SocketIoNativePlatform.instance
        .callSocketIoMethod("SocketIO[offAll]");
  }

  on(String event, Function(dynamic) callback) {
    _createListener("SocketIO[on]", event,callback);
  }

  once(String event, Function(dynamic) callback) {
    _createListener("SocketIO[once]", event,callback);
  }

  onConnect(Function(dynamic) callback) {
    _createListener("SocketIO[onConnect]", "connect",callback);
  }

  onError(Function(dynamic) callback) {
    _createListener("SocketIO[onError]", "connect_error",callback);
  }

  onDisconnect(Function(dynamic) callback) {
    _createListener("SocketIO[onDisconnect]", "disconnect",callback);
  }

  onAny(Function(dynamic) callback) {
    SocketIoNativePlatform.instance
        .callSocketIoMethod("SocketIO[onAny]")
        .then((value) {
      EventChannelSocketIoNative(null)
          .eventChannel
          .receiveBroadcastStream()
          .listen((data) {
        callback(data);
      }, onError: (error) {
        log.e({"ERROR": error});
      }, onDone: () {
        log.w("DONNE");
      });
    });
  }

  _createListener(String method, String event,Function(dynamic) callback) {
    if (channels.keys.contains("event")) {
      return;
    }
    SocketIoNativePlatform.instance
        .callSocketIoMethodWithCallback(method, event, null)
        .then((value) {
      EventChannelSocketIoNative chl = EventChannelSocketIoNative(event);
      channels[event] = chl;
      chl.eventChannel.receiveBroadcastStream().listen((data) {
        callback(data);
      }, onError: (error) {
        log.e({"ERROR": error});
      }, onDone: () {
        log.w("DONNE");
      });
    });
  }
}
