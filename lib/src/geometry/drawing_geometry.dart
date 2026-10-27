import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:r_edit_workflow/src/geometry/closed_boundary.dart';
import 'package:r_edit_workflow/src/geometry/coordinate_space.dart';
import 'package:r_edit_workflow/src/geometry/geometry_errors.dart';
import 'package:r_edit_workflow/src/geometry/geometry_json.dart';
import 'package:r_edit_workflow/src/geometry/geometry_path.dart';

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
  /// 유효한 하위 경로·경계를 방어 복사하고 순서를 유지한다. 빈 목록을 허용하며 업무 ID/역할은 부여하지 않는다.
  DrawingGeometry({
    required this.coordinateSpace,
    required List<GeometryPath> paths,
    required List<ClosedBoundary> boundaries,
  }) : paths = List.unmodifiable(paths),
       boundaries = List.unmodifiable(boundaries);

  /// paths와 boundaries의 모든 길이에 적용하는 유일한 단위 문맥이다.
  @JsonKey(fromJson: _readCoordinateSpace, toJson: _writeCoordinateSpace)
  final DrawingCoordinateSpace coordinateSpace;

  /// 열리거나 닫힐 수 있는 경로 목록이다. 각 경로의 구간 조건만 검증된 값이며 순서를 보존한다.
  @JsonKey(fromJson: _readDrawingPaths, toJson: _writeDrawingPaths)
  final List<GeometryPath> paths;

  /// 원/닫힌 경로 목록이다. 외곽·홀·영역 같은 업무 역할이나 포함 관계는 부여하지 않는다.
  @JsonKey(fromJson: _readDrawingBoundaries, toJson: _writeDrawingBoundaries)
  final List<ClosedBoundary> boundaries;

  /// 문맥·경로·경계를 필수로 복원한다. 기하 오류는 paths/boundaries의 0 기반 위치를 연결해 전달한다.
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

  /// 문맥과 모든 경로·경계를 분리된 JSON으로 내보낸다. ID나 업무 역할을 추정하지 않는다.
  Map<String, Object?> toJson() => _$DrawingGeometryToJson(this);

  /// 단위와 모든 길이를 함께 바꾸고 원호 bulge와 실형상의 의미를 유지한다.
  /// 표현할 수 없는 환산은 예외다. 화면·출력 배열·회전·반전은 수행하지 않는다.
  @useResult
  DrawingGeometry convertedTo(LengthUnit target) {
    final from = coordinateSpace.lengthUnit;
    final newPaths = <GeometryPath>[];
    final newBoundaries = <ClosedBoundary>[];
    for (var i = 0; i < paths.length; i++) {
      try {
        newPaths.add(paths[i].converted(from: from, to: target));
      } on GeometryValidationException catch (error, stackTrace) {
        Error.throwWithStackTrace(
          error.prefixed('paths[$i]', stackTrace: stackTrace),
          stackTrace,
        );
      }
    }
    for (var i = 0; i < boundaries.length; i++) {
      try {
        newBoundaries.add(boundaries[i].converted(from: from, to: target));
      } on GeometryValidationException catch (error, stackTrace) {
        Error.throwWithStackTrace(
          error.prefixed('boundaries[$i]', stackTrace: stackTrace),
          stackTrace,
        );
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
  } on GeometryValidationException catch (error, stackTrace) {
    Error.throwWithStackTrace(
      error.prefixed('coordinateSpace', stackTrace: stackTrace),
      stackTrace,
    );
  }
}

Map<String, Object?> _writeCoordinateSpace(DrawingCoordinateSpace space) =>
    space.toJson();
List<GeometryPath> _readDrawingPaths(Object? json) {
  if (json is! List) {
    throw GeometryValidationException(
      GeometryErrorCode.invalidType,
      'paths',
      GeometryDiagnostic(
        operation: 'readDrawingPaths',
        details: GeometryTypeDetails(
          expectedType: 'List',
          actualType: json.runtimeType.toString(),
        ),
      ),
    );
  }
  final result = <GeometryPath>[];
  for (var i = 0; i < json.length; i++) {
    try {
      result.add(GeometryPath.fromJson(json[i]));
    } on GeometryValidationException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        error.prefixed('paths[$i]', stackTrace: stackTrace),
        stackTrace,
      );
    }
  }
  return result;
}

List<ClosedBoundary> _readDrawingBoundaries(Object? json) {
  if (json is! List) {
    throw GeometryValidationException(
      GeometryErrorCode.invalidType,
      'boundaries',
      GeometryDiagnostic(
        operation: 'readDrawingBoundaries',
        details: GeometryTypeDetails(
          expectedType: 'List',
          actualType: json.runtimeType.toString(),
        ),
      ),
    );
  }
  final result = <ClosedBoundary>[];
  for (var i = 0; i < json.length; i++) {
    try {
      result.add(ClosedBoundary.fromJson(json[i]));
    } on GeometryValidationException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        error.prefixed('boundaries[$i]', stackTrace: stackTrace),
        stackTrace,
      );
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
