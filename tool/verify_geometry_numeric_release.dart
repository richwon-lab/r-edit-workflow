// AOT 검사 결과를 표준 출력하고 의도한 불변성 예외를 확인한다.
// ignore_for_file: avoid_print

import 'dart:math' as math;

import 'package:r_edit_workflow/r_edit_workflow.dart';

GeometryPath arc(double sx, double sy, double ex, double ey, double bulge) =>
    GeometryPath(
      start: Point2(x: sx, y: sy),
      segments: [
        ArcTo(
          end: Point2(x: ex, y: ey),
          bulge: bulge,
        ),
      ],
    );

/// assert 비활성 상태에서 원호 수치 회귀와 실제 진단 출력을 확인한다.
void main() {
  var assertions = false;
  assert(() {
    assertions = true;
    return true;
  }(), 'AOT 실행 모드 확인');
  if (assertions) {
    throw StateError('assert 비활성 실행이 필요합니다');
  }
  for (final b in [1e-310, -1e-310]) {
    arc(0, 0, 2e-300, 0, b);
  }
  arc(1e308, 1e308, 0, 0, math.sqrt(2) - 1);
  arc(0, 0, 1e308, 1e308, -(math.sqrt(2) - 1));
  arc(1e308, -1e308, 1e308, 1e308, -1);
  final failures = <(void Function(), String, GeometryErrorCode, String)>[
    (
      () => arc(1e308, 0, 1e308, 1e308, 2),
      'segments[0]',
      GeometryErrorCode.numericRepresentationFailure,
      'deriveArcExtremum',
    ),
    (
      () => arc(-1e308, 0, -1e308, 1e308, -2),
      'segments[0]',
      GeometryErrorCode.numericRepresentationFailure,
      'deriveArcExtremum',
    ),
    (
      () => arc(1.7e308, -0.5e308, 1.7e308, 0.5e308, 0.5),
      'segments[0]',
      GeometryErrorCode.numericRepresentationFailure,
      'deriveArcExtremum',
    ),
    (
      () => arc(0, 0, 2, 0, double.minPositive),
      'segments[0]',
      GeometryErrorCode.numericRepresentationFailure,
      'deriveArcRadius',
    ),
    (
      () => arc(1.7e308, 0, 1.7e308, 1e308, -0.5),
      'segments[0]',
      GeometryErrorCode.numericRepresentationFailure,
      'deriveArcCenterX',
    ),
    (
      () => CircleBoundary(
        center: Point2(x: double.maxFinite, y: 3),
        radius: double.maxFinite,
      ),
      'radius',
      GeometryErrorCode.numericRepresentationFailure,
      'deriveCircleExtent',
    ),
    (
      () => DrawingGeometry.fromJson({
        'coordinateSpace': {'lengthUnit': 'millimeter'},
        'paths': <Object?>[],
        'boundaries': [
          {
            'kind': 'circle',
            'center': {'x': 'wrong', 'y': 0},
            'radius': 1,
          },
        ],
      }),
      'boundaries[0].center.x',
      GeometryErrorCode.invalidType,
      'readNumber',
    ),
  ];
  for (var i = 0; i < failures.length; i++) {
    final (run, path, code, operation) = failures[i];
    var rejected = false;
    try {
      run();
    } on GeometryValidationException catch (e) {
      rejected =
          e.fieldPath == path &&
          e.code == code &&
          e.diagnostic.operation == operation &&
          identical(e.prefixed('root').diagnostic, e.diagnostic);
      if (i == 0 || i == 5 || i == 6) {
        print(e);
      }
      if (i == 6) {
        final details = e.diagnostic.details as GeometryTypeDetails;
        rejected =
            rejected &&
            details.expectedType == 'num' &&
            details.actualType == 'String';
      }
    }
    if (!rejected) {
      throw StateError('회귀 실패: $code $path $operation');
    }
  }
  print('수치/진단 AOT: assert 비활성, 정상 원호 5건·오류 ${failures.length}건 통과');
}
