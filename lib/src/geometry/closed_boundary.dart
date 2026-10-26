import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:r_edit_workflow/src/geometry/coordinate_space.dart';
import 'package:r_edit_workflow/src/geometry/geometry_errors.dart';
import 'package:r_edit_workflow/src/geometry/geometry_json.dart';
import 'package:r_edit_workflow/src/geometry/geometry_path.dart';
import 'package:r_edit_workflow/src/geometry/point2.dart';
part 'closed_boundary.freezed.dart';
part 'closed_boundary.g.dart';

/// 원 또는 명시적으로 닫힌 경로다. 업무 역할(외곽/홀/영역/장식)은 부여하지 않는다.
/// 생성 성공은 단순 면·유효 재료 영역·제작 가능성을 보장하지 않는다.
sealed class ClosedBoundary {
  /// 닫힌 경계 합 타입의 기반 생성자다. 외곽·관통·텍스트 같은 업무 역할은 소유 모델이 정한다.
  const ClosedBoundary();

  /// circle 또는 path 정본을 독립 JSON으로 내보낸다. 기하에 업무 역할·단위 태그를 중복 추가하지 않는다.
  Map<String, Object?> toJson();

  /// from 단위의 모든 길이를 to로 환산하고 수치 조건을 다시 검사한다.
  /// 변환 실패는 GeometryValidationException이며 반올림·회전·미지원 형상 대체를 수행하지 않는다.
  ClosedBoundary converted({required LengthUnit from, required LengthUnit to});

  /// circle/path 태그와 필수 구조를 복원하고 실제 생성자 검증을 적용한다.
  /// 미지원 태그는 unsupportedTag이며 하위 값의 경로·수치 진단을 보존한다.
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
  /// 유한한 양수 반지름과 네 극점 좌표의 표현 가능성을 검사한다. 단위와 보장 한계는 타입 설명을 따른다.
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

  /// 도안 기준점에 대한 문맥 단위의 원 중심이다. 구간 시작점과 구분한다.
  @JsonKey(fromJson: _readCircleCenter, toJson: writeGeometryPoint)
  final Point2 center;

  /// 도안 문맥 길이 단위의 유한한 양수 반지름이다. 지름이 아니며 임의 반올림하지 않는다.
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
  /// 마지막 end와 start가 정확히 같은지 검사하고 다르면 openBoundary로 거부한다.
  /// 가까운 점을 합치거나 자동 닫힘 선분을 추가하지 않는다.
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

  /// 명시적으로 닫힌 경로다. 폐곡선의 방향·면적·자기 교차·재료 유효성은 보장하지 않는다.
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
