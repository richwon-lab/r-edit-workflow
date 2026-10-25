// AOT 검사 결과를 표준 출력하고 의도한 불변성 예외를 확인한다.
// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:r_edit_workflow/r_edit_workflow.dart';

/// assert 비활성 AOT에서 공개 API의 생성·수정·복원·환산 검증을 확인한다.
void main() {
  var assertions = false;
  assert(() {
    assertions = true;
    return true;
  }(), 'AOT 실행 모드 확인');
  if (assertions) {
    throw StateError('assert 비활성 실행이 필요합니다');
  }
  final start = Point2(x: 0, y: 0);
  final arc = ArcTo(end: Point2(x: 2, y: 0), bulge: -2);
  final segments = <PathSegment>[arc, LineTo(end: start)];
  final path = GeometryPath(start: start, segments: segments);
  final circle = CircleBoundary(center: start, radius: 1);
  final boundaries = <ClosedBoundary>[circle, PathBoundary(path: path)];
  final geometry = DrawingGeometry(
    coordinateSpace: DrawingCoordinateSpace(lengthUnit: LengthUnit.inch),
    paths: [path],
    boundaries: boundaries,
  );
  segments.clear();
  boundaries.clear();
  final json = geometry.toJson();
  final restored = DrawingGeometry.fromJson(jsonDecode(jsonEncode(json)));
  (json['boundaries'] as List).clear();
  if (restored != geometry || path.segments.length != 2) {
    throw StateError('왕복/방어 복사 실패');
  }
  final mm = geometry.convertedTo(LengthUnit.millimeter);
  if ((mm.paths.single.segments.first as ArcTo).bulge != -2 ||
      (mm.boundaries.first as CircleBoundary).radius != 25.4 ||
      geometry.coordinateSpace.lengthUnit != LengthUnit.inch) {
    throw StateError('단위/원래 값 보존 실패');
  }
  final failures = <(void Function(), GeometryErrorCode, String)>[
    (() => Point2(x: double.nan, y: 0), GeometryErrorCode.nonFiniteNumber, 'x'),
    (
      () => start.copyWith(y: double.infinity),
      GeometryErrorCode.nonFiniteNumber,
      'y',
    ),
    (
      () => circle.copyWith(radius: 0),
      GeometryErrorCode.nonPositiveRadius,
      'radius',
    ),
    (
      () => circle.copyWith.center(x: double.nan),
      GeometryErrorCode.nonFiniteNumber,
      'x',
    ),
    (() => arc.copyWith(bulge: 0), GeometryErrorCode.zeroArcBulge, 'bulge'),
    (
      () => GeometryPath(start: start, segments: []),
      GeometryErrorCode.emptyPath,
      'segments',
    ),
    (
      () => path.copyWith(start: arc.end),
      GeometryErrorCode.degenerateSegment,
      'segments[0].end',
    ),
    (
      () => path.copyWith(
        segments: [ArcTo(end: arc.end, bulge: double.minPositive)],
      ),
      GeometryErrorCode.numericRepresentationFailure,
      'segments[0]',
    ),
    (
      () => PathBoundary(
        path: GeometryPath(start: start, segments: [arc]),
      ),
      GeometryErrorCode.openBoundary,
      'path.segments[0].end',
    ),
    (
      () => ClosedBoundary.fromJson({
        'kind': 'path',
        'path': {
          'start': start.toJson(),
          'segments': [LineTo(end: start).toJson()],
        },
      }),
      GeometryErrorCode.degenerateSegment,
      'path.segments[0].end',
    ),
    (
      () => ClosedBoundary.fromJson({
        'kind': 'circle',
        'center': start.toJson(),
        'radius': 0,
      }),
      GeometryErrorCode.nonPositiveRadius,
      'radius',
    ),
    (
      () => PathSegment.fromJson({
        'kind': 'arc',
        'end': arc.end.toJson(),
        'bulge': 0,
      }),
      GeometryErrorCode.zeroArcBulge,
      'bulge',
    ),
    (
      () => DrawingCoordinateSpace.fromJson({'lengthUnit': 'pixel'}),
      GeometryErrorCode.unsupportedTag,
      'lengthUnit',
    ),
    (
      () => ClosedBoundary.fromJson({'kind': 'rectangle'}),
      GeometryErrorCode.unsupportedTag,
      'kind',
    ),
    (
      () => Point2(
        x: double.maxFinite,
        y: 0,
      ).converted(from: LengthUnit.inch, to: LengthUnit.millimeter),
      GeometryErrorCode.numericRepresentationFailure,
      'x',
    ),
    (
      () => Point2(
        x: double.minPositive,
        y: 0,
      ).converted(from: LengthUnit.millimeter, to: LengthUnit.inch),
      GeometryErrorCode.numericRepresentationFailure,
      'x',
    ),
  ];
  for (final (run, code, fieldPath) in failures) {
    var rejected = false;
    try {
      run();
    } on GeometryValidationException catch (e) {
      rejected =
          e.code == code &&
          e.fieldPath == fieldPath &&
          e.diagnostic.operation.isNotEmpty;
    }
    if (!rejected) {
      throw StateError('검증 실패: $code $fieldPath');
    }
  }
  print('기하 AOT: assert 비활성, 왕복·불변성·단위 환산과 오류 ${failures.length}건 통과');
}
