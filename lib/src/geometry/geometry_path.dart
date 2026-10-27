import 'dart:math' as math;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:r_edit_workflow/src/geometry/coordinate_space.dart';
import 'package:r_edit_workflow/src/geometry/geometry_errors.dart';
import 'package:r_edit_workflow/src/geometry/geometry_json.dart';
import 'package:r_edit_workflow/src/geometry/path_segments.dart';
import 'package:r_edit_workflow/src/geometry/point2.dart';

part 'geometry_path.freezed.dart';
part 'geometry_path.g.dart';

/// 시작점 하나와 순서 있는 구간을 가진 경로다. 모든 좌표는 도안 문맥 단위다.
/// 생성·copyWith·JSON에서 퇴화 구간과 원호 파생 수치 실패를 거부한다.
/// 닫힘·자기 교차·면적·포함·간섭은 이 값의 보장이 아니다.
@Freezed(
  fromJson: false,
  toJson: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
@JsonSerializable()
final class GeometryPath with _$GeometryPath {
  /// 구간을 방어 복사하고 빈 목록·같은 양끝점·원호 파생 수치의 표현 불가를 거부한다.
  /// 구간 시작점은 첫 start 또는 직전 end다. 검사 범위와 단위는 타입 설명을 따른다.
  GeometryPath({required this.start, required List<PathSegment> segments})
    : segments = List.unmodifiable(segments) {
    if (this.segments.isEmpty) {
      throw GeometryValidationException(
        GeometryErrorCode.emptyPath,
        'segments',
        const GeometryDiagnostic(operation: 'checkPathSegments'),
      );
    }
    var segmentStart = start;
    for (var i = 0; i < this.segments.length; i++) {
      final segment = this.segments[i];
      final diagnostic = GeometryDiagnostic(
        operation: 'checkSegment',
        details: GeometrySegmentDetails(
          startX: segmentStart.x,
          startY: segmentStart.y,
          endX: segment.end.x,
          endY: segment.end.y,
          bulge: segment is ArcTo ? segment.bulge : null,
        ),
      );
      if (segmentStart == segment.end) {
        throw GeometryValidationException(
          GeometryErrorCode.degenerateSegment,
          'segments[$i].end',
          diagnostic,
        );
      }
      if (segment is ArcTo) {
        _checkArcRepresentation(segmentStart, segment, i);
      }
      segmentStart = segment.end;
    }
  }

  /// 첫 구간의 시작점이다. 이후 시작점은 직전 구간 끝점이므로 중복 저장하지 않는다.
  @JsonKey(fromJson: _readPathStart, toJson: writeGeometryPoint)
  final Point2 start;

  /// 순서 있는 수정 불가 구간 목록이다. 오류의 `segments[i]`는 이 목록의 0 기반 위치다.
  @JsonKey(fromJson: _readPathSegments, toJson: _writePathSegments)
  final List<PathSegment> segments;

  /// start와 segments를 복원해 생성자 조건을 검사한다. 하위 오류는 start 또는 `segments[i]` 경로와 진단을 보존한다.
  factory GeometryPath.fromJson(Object? json) {
    final object = readGeometryObject(json);
    requireGeometryField(object, 'start');
    requireGeometryField(object, 'segments');
    checkGeometryFields(object, const {'start', 'segments'});
    return _$GeometryPathFromJson(object);
  }

  /// 시작점 하나와 순서 있는 구간을 새 JSON으로 내보낸다. 암묵적 닫힘 구간이나 수치 보정은 추가하지 않는다.
  Map<String, Object?> toJson() => _$GeometryPathToJson(this);

  /// 시작점과 모든 구간 끝점을 함께 환산하고 원호 bulge는 유지한다.
  /// 환산으로 좌표가 소실되거나 구간이 퇴화하면 정상 값으로 보정하지 않는다.
  @useResult
  GeometryPath converted({required LengthUnit from, required LengthUnit to}) {
    final converted = <PathSegment>[];
    for (var i = 0; i < segments.length; i++) {
      try {
        final segment = segments[i];
        final end = segment.end.converted(from: from, to: to);
        converted.add(switch (segment) {
          LineTo() => LineTo(end: end),
          ArcTo(:final bulge) => ArcTo(end: end, bulge: bulge),
        });
      } on GeometryValidationException catch (error, stackTrace) {
        Error.throwWithStackTrace(
          error.prefixed('segments[$i].end', stackTrace: stackTrace),
          stackTrace,
        );
      }
    }
    try {
      return GeometryPath(
        start: _convertPathStart(start, from, to),
        segments: converted,
      );
    } on GeometryValidationException catch (error, stackTrace) {
      if (error.code != GeometryErrorCode.degenerateSegment) rethrow;
      final cause = error.diagnostic;
      Error.throwWithStackTrace(
        GeometryValidationException(
          GeometryErrorCode.numericRepresentationFailure,
          error.fieldPath,
          GeometryDiagnostic(
            operation: 'convertSegmentCollapse',
            details: cause.details,
          ),
          cause: error,
          causeStackTrace: stackTrace,
          contextStackTrace: StackTrace.current,
        ),
        stackTrace,
      );
    }
  }
}

Point2 _convertPathStart(Point2 start, LengthUnit from, LengthUnit to) {
  try {
    return start.converted(from: from, to: to);
  } on GeometryValidationException catch (error, stackTrace) {
    Error.throwWithStackTrace(
      error.prefixed('start', stackTrace: stackTrace),
      stackTrace,
    );
  }
}

Point2 _readPathStart(Object? json) => readGeometryPoint(json, 'start');
List<PathSegment> _readPathSegments(Object? json) {
  if (json is! List) {
    throw GeometryValidationException(
      GeometryErrorCode.invalidType,
      'segments',
      GeometryDiagnostic(
        operation: 'readPathSegments',
        details: GeometryTypeDetails(
          expectedType: 'List',
          actualType: json.runtimeType.toString(),
        ),
      ),
    );
  }
  final result = <PathSegment>[];
  for (var i = 0; i < json.length; i++) {
    try {
      result.add(PathSegment.fromJson(json[i]));
    } on GeometryValidationException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        error.prefixed('segments[$i]', stackTrace: stackTrace),
        stackTrace,
      );
    }
  }
  return result;
}

List<Map<String, Object?>> _writePathSegments(List<PathSegment> segments) => [
  for (final segment in segments) segment.toJson(),
];

// 시작점이 있는 경로만 검사한다. 소비자의 지원 범위나 제작 공차를 적용하지 않는다.
void _checkArcRepresentation(Point2 start, ArcTo segment, int index) {
  final end = segment.end;
  final bulge = segment.bulge;
  final segmentDetails = GeometrySegmentDetails(
    startX: start.x,
    startY: start.y,
    endX: end.x,
    endY: end.y,
    bulge: bulge,
  );
  Never reject(String operation, double value) =>
      throw GeometryValidationException(
        GeometryErrorCode.numericRepresentationFailure,
        'segments[$index]',
        GeometryDiagnostic(
          operation: operation,
          details: GeometryArcCalculationDetails(
            segment: segmentDetails,
            value: value,
          ),
        ),
      );
  final halfDx = end.x / 2 - start.x / 2;
  final halfDy = end.y / 2 - start.y / 2;
  final scale = math.max(halfDx.abs(), halfDy.abs());
  if (scale == 0) reject('deriveHalfChord', scale);
  final halfChord =
      scale *
      math.sqrt(math.pow(halfDx / scale, 2) + math.pow(halfDy / scale, 2));
  if (!halfChord.isFinite || halfChord <= 0) {
    reject('deriveHalfChord', halfChord);
  }
  final magnitude = bulge.abs();
  double radius;
  double unsignedOffset;
  if (magnitude >= 0.5 && magnitude <= 2) {
    // 1 부근에서는 양쪽 반항의 개별 언더플로와 불필요한 상쇄를 피한다.
    radius = halfChord * (magnitude / 2 + 0.5 / magnitude);
    unsignedOffset = halfChord * ((1 / magnitude - magnitude) / 2);
  } else {
    // 역수를 먼저 만들지 않고 현 길이와 곱/몫을 결합한다.
    final largeTerm = _halfProduct(halfChord, magnitude);
    final smallTerm = _halfQuotient(halfChord, magnitude);
    radius = largeTerm + smallTerm;
    unsignedOffset = smallTerm - largeTerm;
  }
  if (!radius.isFinite || radius <= 0) reject('deriveArcRadius', radius);
  final offset = bulge > 0 ? unsignedOffset : -unsignedOffset;
  if (!offset.isFinite) reject('deriveArcCenterOffset', offset);
  final normalX = -halfDy / halfChord;
  final normalY = halfDx / halfChord;
  final centerX = start.x / 2 + end.x / 2 + normalX * offset;
  final centerY = start.y / 2 + end.y / 2 + normalY * offset;
  if (!centerX.isFinite) reject('deriveArcCenterX', centerX);
  if (!centerY.isFinite) reject('deriveArcCenterY', centerY);

  // 원호는 양수 bulge면 유향 현의 오른쪽, 음수면 왼쪽 원주다.
  // 원 중심의 현으로부터 거리/radius와 단위 법선으로 극점 포함을 판정한다.
  // 각도 차/2π 래핑과 거대한 실제 극점 좌표를 먼저 만들 필요가 없다.
  final relativeOffset = offset / radius;
  for (final direction in GeometryExtremumDirection.values) {
    final normalProjection = switch (direction) {
      GeometryExtremumDirection.positiveX => normalX,
      GeometryExtremumDirection.negativeX => -normalX,
      GeometryExtremumDirection.positiveY => normalY,
      GeometryExtremumDirection.negativeY => -normalY,
    };
    final side = relativeOffset + normalProjection;
    final onArc = bulge > 0 ? side <= 0 : side >= 0;
    if (!onArc) continue;
    final value = switch (direction) {
      GeometryExtremumDirection.positiveX => centerX + radius,
      GeometryExtremumDirection.negativeX => centerX - radius,
      GeometryExtremumDirection.positiveY => centerY + radius,
      GeometryExtremumDirection.negativeY => centerY - radius,
    };
    if (!value.isFinite) {
      throw GeometryValidationException(
        GeometryErrorCode.numericRepresentationFailure,
        'segments[$index]',
        GeometryDiagnostic(
          operation: 'deriveArcExtremum',
          details: GeometryArcExtremumDetails(
            segment: segmentDetails,
            extremum: GeometryCircleExtremumDetails(
              centerX: centerX,
              centerY: centerY,
              radius: radius,
              direction: direction,
              value: value,
            ),
          ),
        ),
      );
    }
  }
}

// a*b/2: 먼저 큰 인자를 반으로 해 중간 곱 오버플로를 피한다.
double _halfProduct(double a, double b) => a >= b ? (a / 2) * b : a * (b / 2);

// a/(2*b): a가 최소 비정규 수인 경우에도 a/2의 선행 소실을 피한다.
double _halfQuotient(double a, double b) {
  final half = a / 2;
  if (half != 0) return half / b;
  if (b <= double.maxFinite / 2) return a / (b * 2);
  return (a / b) / 2;
}
