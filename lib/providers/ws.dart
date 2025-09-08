import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../domain/camera_objects_response.dart';

part 'ws.g.dart';

@riverpod
class WebSocketConnection extends _$WebSocketConnection {
  late WebSocketChannel _channel;
  final _messageController = StreamController<String>();
  bool _isReady = false;
  bool get isReady => _isReady;
  Stream<String> get messages => _messageController.stream;

  @override
  void build() {
    print("Connecting websocket...");
    _isReady = false;
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:8000/object-detection'),
    );
    _channel.ready.then((_) => _isReady = true);
    _channel.stream.listen(
      (data) {
        _messageController.add(data as String);
      },
      onError: (error) {
        _isReady = false;
        _messageController.addError(error);
      },
      onDone: () => _messageController.close(),
    );
    ref.onDispose(() {
      _isReady = false;
      _channel.sink.close();
      _messageController.close();
    });
  }

  void sendMessageBytes(Uint8List msgBytes) {
    if (_isReady) _channel.sink.add(msgBytes);
  }

  void sendMessage(String message) {
    if (_isReady) _channel.sink.add(message);
  }
}

class JsonToCameraObjRespTransformer
    extends StreamTransformerBase<String, CameraObjectsResponse> {
  @override
  Stream<CameraObjectsResponse> bind(Stream<String> stream) {
    return stream.transform(
      StreamTransformer<String, CameraObjectsResponse>.fromHandlers(
        handleData: (jsonString, sink) {
          try {
            final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

            final CameraObjectsResponse model = CameraObjectsResponse.fromJson(
              jsonMap,
            );
            sink.add(model);
          } catch (e) {
            sink.addError(e); // Handle parsing errors
          }
        },
        handleError: (error, stackTrace, sink) {
          sink.addError(error, stackTrace);
        },
        handleDone: (sink) {
          sink.close();
        },
      ),
    );
  }
}

@riverpod
Stream<CameraObjectsResponse> webSocketMessages(Ref ref) {
  final webSocketNotifier = ref.watch(webSocketConnectionProvider.notifier);
  return webSocketNotifier.messages.transform(JsonToCameraObjRespTransformer());
}
