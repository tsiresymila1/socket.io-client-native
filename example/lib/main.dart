import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:socketio_native/socketio_native.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final SocketIO socketIO;

  Logger log = Logger(printer: PrettyPrinter(methodCount: 1));

  @override
  void initState() {
    super.initState();
    initSocket();
  }

  initSocket() async {
    try {
      // Option option = Option();
      // option.setTransport([SocketIoTransport.polling, SocketIoTransport.websocket]);
      // option.setSecure(true);
      // option.setTimeout(60000);

      // option.setAuth({"api_key" : "20awCHxcod5NJ6Q8UFPuL7JjUHEdgm6BCT0oyZoo8Dl"});
      socketIO = IO.create("http://192.168.1.183:3000");

      await socketIO.init();
      socketIO.onConnect((p0) {
        debugPrint("Connected>>>>");
        log.w({"CONNECTED": p0});
        socketIO.emit("message", "Hello");
      });
      socketIO.onDisconnect((p0) => {
            log.w({"DISCONNECT": p0})
          });
      socketIO.onError((p0) => {
            log.e({"ERROR": p0})
          });
      socketIO.on("message", (p0) {
        log.w({"Message": p0});
        socketIO.emit("message_ack", "Ok", ack: (ok) {
          log.w({"MessageACK": ok});
        });
      });
      await socketIO.connect();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: const Center(
          child: Text('Running ...'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            socketIO.emit("message", "message");
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}