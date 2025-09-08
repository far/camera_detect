import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera_detect/domain/camera_objects_response.dart';
import 'providers/ws.dart';

const captureTimeoutMs = 300;

class CameraApp extends ConsumerStatefulWidget {
  const CameraApp({super.key, required this.camera});

  final CameraDescription camera;
  @override
  CameraAppState createState() => CameraAppState();
}

class CameraAppState extends ConsumerState<CameraApp>
    with WidgetsBindingObserver {
  late CameraController controller;
  late WebSocketConnection wsProvider;

  double screenH = 0;
  double screenW = 0;

  double previewH = 0;
  double previewW = 0;

  static final _labelBoxDecoration = BoxDecoration(
    border: Border.all(color: Color.fromRGBO(37, 213, 253, 1.0), width: 3.0),
  );

  static const _labelTextStyle = TextStyle(
    color: Color.fromRGBO(37, 213, 253, 1.0),
    fontSize: 12.0,
    fontWeight: FontWeight.bold,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = CameraController(
      widget.camera,
      ResolutionPreset.low,
      //ResolutionPreset.max,
      enableAudio: false,
    );
    controller
        .initialize()
        .then((_) {
          if (!mounted) {
            return;
          }
          debugPrint(
            "Start image capturing in ${captureTimeoutMs * 5 / 1000} seconds",
          );
          setState(() {});

          Future.delayed(
            Duration(milliseconds: captureTimeoutMs * 5),
            () async => decodeFrames(ref),
          );
        })
        .catchError((Object e) {
          if (e is CameraException) {
            switch (e.code) {
              case 'CameraAccessDenied':
                // Handle access errors here.
                break;
              default:
                // Handle other errors here.
                break;
            }
          }
        });
  }

  @override
  void dispose() {
    controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    setState(() {
      var tmp = MediaQuery.of(context).size;
      debugPrint('New screen size: $tmp');
      screenH = tmp.height;
      screenW = tmp.width;
    });
  }

  @override
  Widget build(BuildContext context) {
    wsProvider = ref.watch(webSocketConnectionProvider.notifier);

    var tmp = MediaQuery.of(context).size;
    screenH = tmp.height;
    screenW = tmp.width;

    if (!controller.value.isInitialized) {
      return Container();
    }

    tmp = controller.value.previewSize!;
    debugPrint('Preview size: $tmp');
    previewH = tmp.height;
    previewW = tmp.width;

    return CameraPreview(
      controller,
      child: Consumer(
        builder: (context, ref, child) {
          AsyncValue<CameraObjectsResponse> camObjects = ref.watch(
            webSocketMessagesProvider,
          );

          return camObjects.when(
            data: (camObjectsResp) => _bindBoxes(camObjectsResp),
            loading: () => SizedBox.shrink(),
            error: (e, st) {
              debugPrint(st.toString());
              return ErrorWidget(e.toString());
            },
          );
        },
      ),
    );
  }

  Future<void> decodeFrames(WidgetRef ref) async {
    Future.delayed(const Duration(milliseconds: captureTimeoutMs), () async {
      if (!controller.value.isTakingPicture) {
        debugPrint("Taking picture..");
        XFile img = await controller.takePicture();
        final imgBytes = await img.readAsBytes();
        wsProvider.sendMessageBytes(imgBytes);
      }
      await decodeFrames(ref);
    });
  }

  Widget _labelContainer(String labelText) {
    return Container(
      padding: EdgeInsets.only(top: 5.0, left: 5.0),
      decoration: _labelBoxDecoration,
      child: Text(labelText, style: _labelTextStyle),
    );
  }

  Widget _bindBoxes(CameraObjectsResponse camObjResp) {
    var scaleH = screenH / previewH;
    var scaleW = screenW / previewW;
    return Stack(
      children: camObjResp.objects.map((camObj) {
        return Positioned(
          left: camObj.box[0] * scaleW,
          top: camObj.box[1] * scaleH,
          width: (camObj.box[2] - camObj.box[0]) * scaleW,
          height: (camObj.box[3] - camObj.box[1]) * scaleH,
          child: _labelContainer(camObj.label),
        );
      }).toList(),
    );
  }
}
