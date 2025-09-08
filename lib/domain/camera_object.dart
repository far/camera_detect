import 'package:freezed_annotation/freezed_annotation.dart';

part 'camera_object.freezed.dart';
part 'camera_object.g.dart';

@freezed
abstract class CameraObject with _$CameraObject {
  const factory CameraObject({
    required List<double> box,
    required String label,
  }) = _CameraObject;

  factory CameraObject.fromJson(Map<String, dynamic> json) =>
      _$CameraObjectFromJson(json);
}
