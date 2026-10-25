import 'dart:math' as math;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'coordinate_space.dart';
import 'geometry_errors.dart';
import 'geometry_json.dart';
import 'path_segments.dart';
import 'point2.dart';
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
  GeometryPath({required this.start, required List<PathSegment> segments})
    : segments = List.unmodifiable(segments) {
    if (this.segments.isEmpty) {
      throw const GeometryValidationException(
        GeometryErrorCode.emptyPath,
        'segments',
        GeometryDiagnostic(operation: 'checkPathSegments'),
      );
    }
    var segmentStart = start;
    for (var i = 0; i < this.segments.length; i++) {
      final segment = this.segments[i];
      final diagnostic = GeometryDiagnostic(
        operation: 'checkSegment',
        startX: segmentStart.x,
        startY: segmentStart.y,
        endX: segment.end.x,
        endY: segment.end.y,
        bulge: segment is ArcTo ? segment.bulge : null,
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
  @JsonKey(fromJson: _readPathStart, toJson: writeGeometryPoint)
  final Point2 start;
  @JsonKey(fromJson: _readPathSegments, toJson: _writePathSegments)
  final List<PathSegment> segments;

  factory GeometryPath.fromJson(Object? json) {
    final object = readGeometryObject(json);
    requireGeometryField(object, 'start');
    requireGeometryField(object, 'segments');
    checkGeometryFields(object, const {'start', 'segments'});
    return _$GeometryPathFromJson(object);
  }
  Map<String, Object?> toJson() => _$GeometryPathToJson(this);

  /// 시작점과 모든 구간 끝점을 함께 환산하고 원호 bulge는 유지한다.
  /// 환산으로 좌표가 소실되거나 구간이 퇴화하면 정상 값으로 보정하지 않는다.
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
      } on GeometryValidationException catch (error) {
        throw error.prefixed('segments[$i].end');
      }
    }
    try {
      return GeometryPath(
        start: _convertPathStart(start, from, to),
        segments: converted,
      );
    } on GeometryValidationException catch (error) {
      if (error.code != GeometryErrorCode.degenerateSegment) rethrow;
      final cause = error.diagnostic;
      throw GeometryValidationException(
        GeometryErrorCode.numericRepresentationFailure,
        error.fieldPath,
        GeometryDiagnostic(
          operation: 'convertSegmentCollapse',
          startX: cause.startX,
          startY: cause.startY,
          endX: cause.endX,
          endY: cause.endY,
          bulge: cause.bulge,
        ),
      );
    }
  }
}

Point2 _convertPathStart(Point2 start, LengthUnit from, LengthUnit to) {
  try {
    return start.converted(from: from, to: to);
  } on GeometryValidationException catch (error) {
    throw error.prefixed('start');
  }
}

Point2 _readPathStart(Object? json) => readGeometryPoint(json, 'start');
List<PathSegment> _readPathSegments(Object? json) {
  if (json is! List) {
    throw const GeometryValidationException(
      GeometryErrorCode.invalidType,
      'segments',
      GeometryDiagnostic(operation: 'readPathSegments', expectedType: 'List'),
    );
  }
  final result = <PathSegment>[];
  for (var i = 0; i < json.length; i++) {
    try {
      result.add(PathSegment.fromJson(json[i]));
    } on GeometryValidationException catch (error) {
      throw error.prefixed('segments[$i]');
    }
  }
  return result;
}

List<Map<String, Object?>> _writePathSegments(List<PathSegment> segments) => [
  for (final segment in segments) segment.toJson(),
];

// 시작점이 있는 경로만 호출한다. bulge의 범위를 소비자 지원 범위로 제한하지 않는다.
void _checkArcRepresentation(Point2 start, ArcTo segment, int index) {
  final end = segment.end;
  final bulge = segment.bulge;
  Never reject(String operation, double value) =>
      throw GeometryValidationException(
        GeometryErrorCode.numericRepresentationFailure,
        'segments[$index]',
        GeometryDiagnostic(
          operation: operation,
          value: value,
          startX: start.x,
          startY: start.y,
          endX: end.x,
          endY: end.y,
          bulge: bulge,
        ),
      );
  // 큰 좌표 차이/제곱과 bulge 제곱의 불필요한 오버플로를 피한다.
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
  final radius = halfChord * (magnitude / 2 + 0.5 / magnitude);
  if (!radius.isFinite || radius <= 0) reject('deriveArcRadius', radius);
  final offset = halfChord * (0.5 / bulge - bulge / 2);
  if (!offset.isFinite) reject('deriveArcCenterOffset', offset);
  final centerX = start.x / 2 + end.x / 2 - (halfDy / halfChord) * offset;
  final centerY = start.y / 2 + end.y / 2 + (halfDx / halfChord) * offset;
  if (!centerX.isFinite) reject('deriveArcCenterX', centerX);
  if (!centerY.isFinite) reject('deriveArcCenterY', centerY);
}
