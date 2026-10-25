import 'package:freezed_annotation/freezed_annotation.dart';

import 'closed_boundary.dart';
import 'coordinate_space.dart';
import 'geometry_errors.dart';
import 'geometry_json.dart';
import 'geometry_path.dart';
part 'drawing_geometry.freezed.dart';
part 'drawing_geometry.g.dart';

/// 단위 문맥과 그 단위를 쓰는 경로/경계의 불변 묶음이다. 전체 도안 모델이 아니다.
/// 외곽·가공·텍스트 영역 같은 업무 역할이나 ID를 아직 부여하지 않는다.
/// 단위만 바꾸는 copyWith를 제공하지 않으며 [convertedTo]로 모든 길이를 환산한다.
@Freezed(
  fromJson: false,
  toJson: false,
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
@JsonSerializable()
final class DrawingGeometry with _$DrawingGeometry {
  DrawingGeometry({
    required this.coordinateSpace,
    required List<GeometryPath> paths,
    required List<ClosedBoundary> boundaries,
  }) : paths = List.unmodifiable(paths),
       boundaries = List.unmodifiable(boundaries);
  @JsonKey(fromJson: _readCoordinateSpace, toJson: _writeCoordinateSpace)
  final DrawingCoordinateSpace coordinateSpace;
  @JsonKey(fromJson: _readDrawingPaths, toJson: _writeDrawingPaths)
  final List<GeometryPath> paths;
  @JsonKey(fromJson: _readDrawingBoundaries, toJson: _writeDrawingBoundaries)
  final List<ClosedBoundary> boundaries;
  factory DrawingGeometry.fromJson(Object? json) {
    final object = readGeometryObject(json);
    for (final key in ['coordinateSpace', 'paths', 'boundaries']) {
      requireGeometryField(object, key);
    }
    checkGeometryFields(object, const {
      'coordinateSpace',
      'paths',
      'boundaries',
    });
    return _$DrawingGeometryFromJson(object);
  }
  Map<String, Object?> toJson() => _$DrawingGeometryToJson(this);

  /// 단위와 모든 길이를 함께 바꾸고 원호 bulge와 실형상의 의미를 유지한다.
  /// 표현할 수 없는 환산은 예외다. 화면·출력 배열·회전·반전은 수행하지 않는다.
  DrawingGeometry convertedTo(LengthUnit target) {
    final from = coordinateSpace.lengthUnit;
    final newPaths = <GeometryPath>[];
    final newBoundaries = <ClosedBoundary>[];
    for (var i = 0; i < paths.length; i++) {
      try {
        newPaths.add(paths[i].converted(from: from, to: target));
      } on GeometryValidationException catch (error) {
        throw error.prefixed('paths[$i]');
      }
    }
    for (var i = 0; i < boundaries.length; i++) {
      try {
        newBoundaries.add(boundaries[i].converted(from: from, to: target));
      } on GeometryValidationException catch (error) {
        throw error.prefixed('boundaries[$i]');
      }
    }
    return DrawingGeometry(
      coordinateSpace: DrawingCoordinateSpace(lengthUnit: target),
      paths: newPaths,
      boundaries: newBoundaries,
    );
  }
}

DrawingCoordinateSpace _readCoordinateSpace(Object? json) {
  try {
    return DrawingCoordinateSpace.fromJson(json);
  } on GeometryValidationException catch (error) {
    throw error.prefixed('coordinateSpace');
  }
}

Map<String, Object?> _writeCoordinateSpace(DrawingCoordinateSpace space) =>
    space.toJson();
List<GeometryPath> _readDrawingPaths(Object? json) {
  if (json is! List) {
    throw const GeometryValidationException(
      GeometryErrorCode.invalidType,
      'paths',
      GeometryDiagnostic(operation: 'readDrawingPaths', expectedType: 'List'),
    );
  }
  final result = <GeometryPath>[];
  for (var i = 0; i < json.length; i++) {
    try {
      result.add(GeometryPath.fromJson(json[i]));
    } on GeometryValidationException catch (error) {
      throw error.prefixed('paths[$i]');
    }
  }
  return result;
}

List<ClosedBoundary> _readDrawingBoundaries(Object? json) {
  if (json is! List) {
    throw const GeometryValidationException(
      GeometryErrorCode.invalidType,
      'boundaries',
      GeometryDiagnostic(
        operation: 'readDrawingBoundaries',
        expectedType: 'List',
      ),
    );
  }
  final result = <ClosedBoundary>[];
  for (var i = 0; i < json.length; i++) {
    try {
      result.add(ClosedBoundary.fromJson(json[i]));
    } on GeometryValidationException catch (error) {
      throw error.prefixed('boundaries[$i]');
    }
  }
  return result;
}

List<Map<String, Object?>> _writeDrawingPaths(List<GeometryPath> paths) => [
  for (final path in paths) path.toJson(),
];
List<Map<String, Object?>> _writeDrawingBoundaries(
  List<ClosedBoundary> boundaries,
) => [for (final boundary in boundaries) boundary.toJson()];
