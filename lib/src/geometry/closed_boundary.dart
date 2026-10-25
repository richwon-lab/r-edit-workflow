import 'package:freezed_annotation/freezed_annotation.dart';

import 'coordinate_space.dart';
import 'geometry_errors.dart';
import 'geometry_json.dart';
import 'geometry_path.dart';
import 'point2.dart';
part 'closed_boundary.freezed.dart';
part 'closed_boundary.g.dart';

/// 원 또는 명시적으로 닫힌 경로다. 업무 역할(외곽/홀/영역/장식)은 부여하지 않는다.
/// 생성 성공은 단순 면·유효 재료 영역·제작 가능성을 보장하지 않는다.
sealed class ClosedBoundary {
  const ClosedBoundary();
  Map<String, Object?> toJson();
  ClosedBoundary converted({required LengthUnit from, required LengthUnit to});
  factory ClosedBoundary.fromJson(Object? json) {
    final object = readGeometryObject(json);
    final kind = readGeometryString(object, 'kind');
    switch (kind) {
      case 'circle':
        requireGeometryField(object, 'center');
        checkGeometryNumber(object, 'radius');
        checkGeometryFields(object, const {'kind', 'center', 'radius'});
        return _$CircleBoundaryFromJson(object);
      case 'path':
        requireGeometryField(object, 'path');
        checkGeometryFields(object, const {'kind', 'path'});
        return _$PathBoundaryFromJson(object);
      default:
        throw GeometryValidationException(
          GeometryErrorCode.unsupportedTag,
          'kind',
          GeometryDiagnostic(
            operation: 'readClosedBoundary',
            details: GeometryTagDetails(kind),
          ),
        );
    }
  }
}

/// 중심과 양수 반지름을 유일 정본으로 가진 원 경계다. 단위는 도안 문맥을 따른다.
/// 원호 분해 결과를 중복 저장하지 않는다. 파생 극점의 비유한 수치도 거부한다.
@Freezed(
  fromJson: false,
  toJson: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
@JsonSerializable()
final class CircleBoundary extends ClosedBoundary with _$CircleBoundary {
  CircleBoundary({required this.center, required this.radius}) {
    checkFiniteGeometryNumber(radius, 'radius');
    if (radius <= 0) {
      throw GeometryValidationException(
        GeometryErrorCode.nonPositiveRadius,
        'radius',
        GeometryDiagnostic(
          operation: 'checkCircleRadius',
          details: GeometryNumberDetails(radius),
        ),
      );
    }
    for (final direction in GeometryExtremumDirection.values) {
      final value = switch (direction) {
        GeometryExtremumDirection.positiveX => center.x + radius,
        GeometryExtremumDirection.negativeX => center.x - radius,
        GeometryExtremumDirection.positiveY => center.y + radius,
        GeometryExtremumDirection.negativeY => center.y - radius,
      };
      if (!value.isFinite) {
        throw GeometryValidationException(
          GeometryErrorCode.numericRepresentationFailure,
          'radius',
          GeometryDiagnostic(
            operation: 'deriveCircleExtent',
            details: GeometryCircleExtremumDetails(
              centerX: center.x,
              centerY: center.y,
              radius: radius,
              direction: direction,
              value: value,
            ),
          ),
        );
      }
    }
  }
  @JsonKey(fromJson: _readCircleCenter, toJson: writeGeometryPoint)
  final Point2 center;
  final double radius;
  @override
  Map<String, Object?> toJson() => {
    'kind': 'circle',
    ..._$CircleBoundaryToJson(this),
  };
  @override
  CircleBoundary converted({required LengthUnit from, required LengthUnit to}) {
    Point2 convertedCenter;
    try {
      convertedCenter = center.converted(from: from, to: to);
    } on GeometryValidationException catch (error) {
      throw error.prefixed('center');
    }
    return CircleBoundary(
      center: convertedCenter,
      radius: convertGeometryLength(radius, from, to, 'radius'),
    );
  }
}

/// 마지막 구간이 시작점으로 정확히 돌아온 경로 경계다.
/// 닫힘 플래그·자동 선분·근접 점 보정은 없으며 면적/자기 교차는 검사하지 않는다.
@Freezed(
  fromJson: false,
  toJson: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
@JsonSerializable()
final class PathBoundary extends ClosedBoundary with _$PathBoundary {
  PathBoundary({required this.path}) {
    if (path.segments.last.end != path.start) {
      final end = path.segments.last.end;
      throw GeometryValidationException(
        GeometryErrorCode.openBoundary,
        'path.segments[${path.segments.length - 1}].end',
        GeometryDiagnostic(
          operation: 'checkBoundaryClosure',
          details: GeometrySegmentDetails(
            startX: path.start.x,
            startY: path.start.y,
            endX: end.x,
            endY: end.y,
          ),
        ),
      );
    }
  }
  @JsonKey(fromJson: _readBoundaryPath, toJson: _writeBoundaryPath)
  final GeometryPath path;
  @override
  Map<String, Object?> toJson() => {
    'kind': 'path',
    ..._$PathBoundaryToJson(this),
  };
  @override
  PathBoundary converted({required LengthUnit from, required LengthUnit to}) {
    try {
      return PathBoundary(
        path: path.converted(from: from, to: to),
      );
    } on GeometryValidationException catch (error) {
      throw error.prefixed('path');
    }
  }
}

Point2 _readCircleCenter(Object? json) => readGeometryPoint(json, 'center');
GeometryPath _readBoundaryPath(Object? json) {
  try {
    return GeometryPath.fromJson(json);
  } on GeometryValidationException catch (error) {
    throw error.prefixed('path');
  }
}

Map<String, Object?> _writeBoundaryPath(GeometryPath path) => path.toJson();
