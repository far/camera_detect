import 'package:freezed_annotation/freezed_annotation.dart';
import 'camera_object.dart';

part 'camera_objects_response.freezed.dart';
part 'camera_objects_response.g.dart';

@freezed
abstract class CameraObjectsResponse with _$CameraObjectsResponse {
  const factory CameraObjectsResponse({required List<CameraObject> objects}) =
      _CameraObjectsResponse;

  factory CameraObjectsResponse.fromJson(Map<String, dynamic> json) =>
      _$CameraObjectsResponseFromJson(json);
}
