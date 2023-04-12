package com.socketio.socketio.socketio_native;

import android.annotation.SuppressLint;
import android.content.Context;
import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import java.net.URI;
import java.security.NoSuchAlgorithmException;
import java.security.cert.X509Certificate;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.SSLContext;
import javax.net.ssl.X509TrustManager;

import io.flutter.Log;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.socket.client.AckWithTimeout;
import io.socket.client.Socket;
import io.socket.client.SocketOptionBuilder;
import io.socket.client.IO;
import okhttp3.OkHttpClient;

/**
 * SocketIONativePlugin
 */
public class SocketioNativePlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private MethodChannel channel;


    Socket socketIo;
    URI socketUri;
    private Context context;
    SocketOptionBuilder options = IO.Options.builder();
    OkHttpClient.Builder okHttpClientBuilder = new OkHttpClient.Builder();
    SSLContext sslContext;
    Boolean autoConnect = true;
    Boolean isSecure = false;
    private Handler handler;
    private FlutterPluginBinding flutterPluginBinding;
    private Map<String, EventChannel> events = new HashMap<>();


    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding){
        this.flutterPluginBinding = flutterPluginBinding;
        this.context = flutterPluginBinding.getApplicationContext();
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "socketio_native");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {

        Log.e("METHOD", call.method);
        Object arg = call.arguments();
        Log.e("ARGUMENT", arg == null ? "No args" : arg.toString());
        switch(call.method) {
//      Object arg = call.arguments();
//      Log.e("ARGUMENT",  arg == null ? "No args" : arg.toString());
            // Options
            case "Option[setForceNew]":
                options.setForceNew((boolean) call.argument("data"));
                result.success(true);
                break;
            case "Option[setSecure]":
                boolean isSecure = (boolean) call.argument("data");
                this.isSecure = isSecure;
                options.setSecure(isSecure);
                result.success(true);
                break;
            case "Option[setReconnection]":
                options.setReconnection((boolean) call.argument("data"));
                result.success(true);
                break;

            case "Option[setReconnectionDelay]":
                options.setReconnectionDelay((int) call.argument("data"));
                result.success(true);
                break;
            case "Option[setReconnectionDelayMax]":
                options.setReconnectionDelayMax((int) call.argument("data"));
                result.success(true);
                break;
            case "Option[setReconnectionAttempts]":
                options.setReconnectionAttempts((int) call.argument("data"));
                result.success(true);
                break;
            case "Option[setMultiplex]":
                options.setMultiplex((boolean) call.argument("data"));
                result.success(true);
                break;
            case "Option[setUpgrade]":
                options.setUpgrade((boolean) call.argument("data"));
                result.success(true);
                break;
            case "Option[setRememberUpgrade]":
                options.setRememberUpgrade((boolean) call.argument("data"));
                result.success(true);
                break;
            case "Option[setRandomizationFactor]":
                options.setRandomizationFactor((double) call.argument("data"));
                result.success(true);
                break;
            case "Option[setTimeout]":
                options.setTimeout((int) call.argument("data"));
                result.success(true);
                break;
            case "Option[disableAutoConnect]":
                autoConnect = false;
                result.success(true);
                break;
            case "Option[setTransport]":
                ArrayList<String> transports = (ArrayList<String>) call.argument("data");
                assert transports != null;
                options.setTransports((String[]) transports.toArray(new String[0]));
                result.success(true);
                break;
            case "Option[setPath]":
                String path = (String) call.argument("data");
                options.setPath(path);
                result.success(true);
                break;

            case "Option[setQuery]":
                String query = (String) call.argument("data");
                options.setQuery(query);
                result.success(true);
                break;
            case "Option[setExtraHeaders]":
                Map<String, List<String>> extraHeaders = (Map<String, List<String>>) call.argument("data");
                options.setExtraHeaders(extraHeaders);
                result.success(true);
                break;
            case "Option[setAuth]":
                Map<String, String> auth = (Map<String, String>) call.argument("data");
                options.setAuth(auth);
                result.success(true);
                break;
            case "SocketIO[setUri]":
                String uri = call.argument("data");
                socketUri = URI.create(uri);
                result.success(true);
                break;
            // SOCKET IO
            case "SocketIO[init]":
                try {
                    this.onInit();
                } catch (NoSuchAlgorithmException e) {
                    result.error("INIT ERROR", e.getClass().getName(), e.getMessage());
                }
                result.success(true);
                break;
            case "SocketIO[connect]":
                if (socketIo.connected()) {
                    socketIo.disconnect().connect();
                } else {
                    socketIo.connect();
                }
                result.success(true);
                break;
            case "SocketIO[disconnect]":
                socketIo.disconnect();
                socketIo.close();
                result.success(true);
                break;
            case "SocketIO[emit]":
                String event = call.argument("event");
                @Nullable ArrayList<Object> data = call.argument("data");
                assert data != null;
                socketIo.emit(event, data.toArray(), args -> {
                    Log.e("EMIT>>>", Arrays.toString(args));
                    result.success(args[0].toString());
                });
                break;
            case "SocketIO[emitTimeout]":
                String eventTimeout = call.argument("event");
                @Nullable Object[] dataTimeOut = call.argument("data");
                int timeout = (int) call.argument("timeout");
                socketIo.emit(eventTimeout, dataTimeOut, new AckWithTimeout(timeout) {
                    @Override
                    public void onSuccess(Object... args) {
                        result.success(args[0].toString());
                    }
                    @Override
                    public void onTimeout() {
                        result.error("TIMEOUT", "Timeout data", "Emit data timed out ");
                    }
                });
                break;
            case "SocketIO[send]":
                @Nullable Object[] sendData = call.argument("data");
                socketIo.send(sendData);
                break;
            case "SocketIO[off]":
                String eventOff = call.argument("data");
                socketIo.off(eventOff);
                break;
            case "SocketIO[offAll]":
                socketIo.offAnyIncoming();
                break;
            // List on event
            case "SocketIO[onConnect]":
                this.createEventChannel("connect");
                result.success(true);
                break;
            case "SocketIO[onDisconnect]":
                this.createEventChannel("disconnect");
                result.success(true);
                break;
            case "SocketIO[onError]":
                this.createEventChannel("connect_error");
                result.success(true);
                break;
            case "SocketIO[on]":
                String eventOn = call.argument("data");
                this.createEventChannel(eventOn);
                result.success(true);
                break;
            case "SocketIO[once]":
                String eventOnce = call.argument("data");
                this.createOnceEventChannel(eventOnce);
                result.success(true);
                break;
            case "SocketIO[onAny]":
                this.createOnAnyEventChannel();
                result.success(true);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    public void onInit() throws NoSuchAlgorithmException {

        IO.Options op = options.build();
        HostnameVerifier hostnameVerifier = (hostname, sslSession) -> {
            Log.e("HOSTNAME",socketUri.toString() + " verified ............... ok");
            return true;
        };
        @SuppressLint("CustomX509TrustManager")
        X509TrustManager trustManager = new X509TrustManager() {
            @SuppressLint("TrustAllX509TrustManager")
            @Override
            public void checkClientTrusted(X509Certificate[] chain, String authType) {

            }

            public X509Certificate[] getAcceptedIssuers() {
                return new X509Certificate[]{};
            }

            @SuppressLint("TrustAllX509TrustManager")
            @Override
            public void checkServerTrusted(X509Certificate[] arg0, String arg1) {
                // not implemented
            }
        };
        okHttpClientBuilder
                .hostnameVerifier(hostnameVerifier)
                //.sslSocketFactory(SSLContext.getInstance("TLS").init().getSocketFactory(), trustManager)
                .readTimeout(1, TimeUnit.MINUTES);
        OkHttpClient okHttpClient = okHttpClientBuilder.build();
        op.callFactory = okHttpClient;
        op.webSocketFactory = okHttpClient;

        socketIo = IO.socket(socketUri, op);
        if (autoConnect) {
            socketIo.connect();
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        for (EventChannel e : this.events.values()) {
            e.setStreamHandler(null);
        }
        this.events = new HashMap<>();
    }

    public void createEventChannel(String channel) {
        if (this.events.containsKey(channel)) {
            return;
        }
        EventChannel eventChannel = new EventChannel(this.flutterPluginBinding.getBinaryMessenger(), "socketio_native/eventChannel/" + channel);
        this.events.put(channel, eventChannel);
        eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            EventChannel.EventSink sink;

            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                sink = events;
                if (socketIo != null) {
                    socketIo.on(channel, args -> {
                        Log.e(channel.toUpperCase(), Arrays.toString(args));
                        HashMap<String,Object> hasMap = new HashMap<>();
                        hasMap.put("id", socketIo.id());
                        hasMap.put("connected", socketIo.connected());
                        hasMap.put("active", socketIo.isActive());
                        if (channel.equals("connect_error")) {
                            ArrayList<String> error = new ArrayList<>();
                            for(Object o : args){
                                error.add(o.toString());
                            }
                            hasMap.put("data", error );
                        }
                        else if(!channel.equals("connect") && !channel.equals("disconnect")){
                            hasMap.put("data", args[0]);
                        }
                        Runnable runnable = () -> events.success(hasMap);
                        new Handler(Looper.getMainLooper()).post(runnable);
                    });
                } else {
                    Log.e("SOCKET ERROR", "Socket not initialized");
                }

            }

            @Override
            public void onCancel(Object arguments) {
                eventChannel.setStreamHandler(null);
                if (sink != null) {
                    sink.endOfStream();
                }
            }
        });

    }

    public void createOnceEventChannel(String channel) {
        if (this.events.containsKey(channel)) {
            return;
        }
        EventChannel eventChannel = new EventChannel(this.flutterPluginBinding.getBinaryMessenger(), "socketio_native/eventChannel/" + channel);
        this.events.put(channel, eventChannel);
        eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            EventChannel.EventSink sink;

            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                sink = events;
                if (socketIo != null) {
                    socketIo.once(channel, args -> {
                        Log.e(channel.toUpperCase(), Arrays.toString(args));
                        HashMap<String, Object> hasMap = new HashMap<>();
                        hasMap.put("id", socketIo.id());
                        hasMap.put("connected", socketIo.connected());
                        hasMap.put("active", socketIo.isActive());
                        if (channel.equals("connect_error")) {
                            hasMap.put("data", Arrays.toString(args));
                        }
                        else if(!channel.equals("connect") && !channel.equals("disconnect")){
                            hasMap.put("data", args);
                        }
                        Runnable runnable = () -> events.success(hasMap);
                        new Handler(Looper.getMainLooper()).post(runnable);
                    });
                } else {
                    Log.e("SOCKET ERROR", "Socket not initialized");
                }

            }

            @Override
            public void onCancel(Object arguments) {
                eventChannel.setStreamHandler(null);
                if (sink != null) {
                    sink.endOfStream();
                }
            }
        });

    }

    public void createOnAnyEventChannel() {
        if (this.events.containsKey("__any__")) {
            return;
        }
        EventChannel eventChannel = new EventChannel(this.flutterPluginBinding.getBinaryMessenger(), "socketio_native/eventChannel");
        this.events.put("__any__", eventChannel);
        eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            EventChannel.EventSink sink;

            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                sink = events;
                if (socketIo != null) {
                    socketIo.onAnyIncoming(args -> {
                        Log.e("ANY_EVENT", Arrays.toString(args));
                        HashMap<String, Object> hasMap = new HashMap<>();
                        hasMap.put("id", socketIo.id());
                        hasMap.put("connected", socketIo.connected());
                        hasMap.put("active", socketIo.isActive());
                        hasMap.put("data", args);
                        Runnable runnable = () -> events.success(hasMap);
                        new Handler(Looper.getMainLooper()).post(runnable);
                    });
                } else {
                    Log.e("SOCKET ERROR", "Socket not initialized");
                }
            }

            @Override
            public void onCancel(Object arguments) {
                eventChannel.setStreamHandler(null);
                if (sink != null) {
                    sink.endOfStream();
                }
            }
        });

    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        Log.e("ATTACHED", "onAttachedToActivity");
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        for (EventChannel e : this.events.values()) {
            e.setStreamHandler(null);
        }
        this.events = new HashMap<>();
        Log.e("DETACHED", "onDetachedFromActivityForConfigChanges");
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        Log.e("REATTACHED", "REATTACHED");
    }

    @Override
    public void onDetachedFromActivity() {
        for (EventChannel e : this.events.values()) {
            e.setStreamHandler(null);
        }
        this.events = new HashMap<>();
        Log.e("DETACHED", "onDetachedFromActivity");
    }
}
