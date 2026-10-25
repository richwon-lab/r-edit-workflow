import 'dart:math' as math;

import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

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
(double, double) rotate(double x, double y, int turns) {
  for (var i = 0; i < turns; i++) {
    final previous = x;
    x = -y;
    y = previous;
  }
  return (x, y);
}

GeometryPath rotatedArc(
  double sx,
  double sy,
  double ex,
  double ey,
  double bulge,
  int turns,
  bool reverse,
) {
  final (ax, ay) = rotate(sx, sy, turns);
  final (bx, by) = rotate(ex, ey, turns);
  return reverse ? arc(bx, by, ax, ay, -bulge) : arc(ax, ay, bx, by, bulge);
}

const directions = [
  GeometryExtremumDirection.positiveX,
  GeometryExtremumDirection.positiveY,
  GeometryExtremumDirection.negativeX,
  GeometryExtremumDirection.negativeY,
];
void main() {
  test('극소 bulge의 유한 반지름·중심은 중간 역수 오버플로 없이 생성한다', () {
    for (final bulge in [1e-310, -1e-310]) {
      final value = arc(0, 0, 2e-300, 0, bulge);
      expect(value.segments, hasLength(1));
      expect((value.segments.single as ArcTo).bulge, bulge);
      expect(GeometryPath.fromJson(value.toJson()), value);
      expect(
        value.copyWith(
          segments: [ArcTo(end: Point2(x: 2e-300, y: 0), bulge: bulge)],
        ),
        value,
      );
    }
  });
  for (var turns = 0; turns < 4; turns++) {
    for (final reverse in [false, true]) {
      test('반원 초과의 실제 극점 검사: 회전$turns 역방향$reverse', () {
        try {
          rotatedArc(1e308, 0, 1e308, 1e308, 2, turns, reverse);
          fail('표현 불가 극점을 수락함');
        } on GeometryValidationException catch (e) {
          expect(e.code, GeometryErrorCode.numericRepresentationFailure);
          expect(e.fieldPath, 'segments[0]');
          expect(e.diagnostic.operation, 'deriveArcExtremum');
          final details = e.diagnostic.details as GeometryArcExtremumDetails;
          expect(details.extremum.direction, directions[turns]);
          expect(details.extremum.radius, closeTo(6.25e307, 1e293));
          expect(details.extremum.value.isInfinite, isTrue);
          expect(details.segment.bulge, reverse ? -2 : 2);
        }
      });
      test('짧은 원호 밖의 기반 원 극점은 거부하지 않는다: 회전$turns 역방향$reverse', () {
        final value = rotatedArc(
          1e308,
          1e308,
          0,
          0,
          math.sqrt(2) - 1,
          turns,
          reverse,
        );
        expect(value.segments, hasLength(1));
      });
      test('각도 0/2π 경계를 가로지르는 짧은 원호: 회전$turns 역방향$reverse', () {
        expect(
          () => rotatedArc(
            1.7e308,
            -0.5e308,
            1.7e308,
            0.5e308,
            0.5,
            turns,
            reverse,
          ),
          throwsA(
            isA<GeometryValidationException>().having(
              (e) => (e.diagnostic.details as GeometryArcExtremumDetails)
                  .extremum
                  .direction,
              '방향',
              directions[turns],
            ),
          ),
        );
      });
    }
  }
  test('같은 기반 원의 양쪽 반원을 구분한다', () {
    final original = arc(1e308, 0, 1e308, 1e308, 0.5);
    expect(
      () => original.copyWith(
        segments: [ArcTo(end: Point2(x: 1e308, y: 1e308), bulge: 2)],
      ),
      throwsA(
        isA<GeometryValidationException>().having(
          (e) => e.diagnostic.operation,
          '연산',
          'deriveArcExtremum',
        ),
      ),
    );
    expect(
      () => arc(1e308, -1e308, 1e308, 1e308, 1),
      throwsA(
        isA<GeometryValidationException>().having(
          (e) => e.diagnostic.operation,
          '연산',
          'deriveArcExtremum',
        ),
      ),
    );
    expect(arc(1e308, -1e308, 1e308, 1e308, -1).segments, hasLength(1));
    expect(arc(1e308, 1e308, 1e308, -1e308, 1).segments, hasLength(1));
  });
  test('실제 반지름·중심 오버플로는 계속 거부하고 연산을 구분한다', () {
    expect(
      () => arc(0, 0, 2, 0, double.minPositive),
      throwsA(
        isA<GeometryValidationException>().having(
          (e) => e.diagnostic.operation,
          '연산',
          'deriveArcRadius',
        ),
      ),
    );
    expect(
      () => arc(1.7e308, 0, 1.7e308, 1e308, -0.5),
      throwsA(
        isA<GeometryValidationException>().having(
          (e) => e.diagnostic.operation,
          '연산',
          'deriveArcCenterX',
        ),
      ),
    );
    try {
      arc(-1e308, 0, 1e308, 0, 2);
      fail('실제 극점 오버플로를 수락함');
    } on GeometryValidationException catch (e) {
      expect(e.diagnostic.operation, 'deriveArcExtremum');
      expect(
        (e.diagnostic.details as GeometryArcExtremumDetails).extremum.radius,
        closeTo(1.25e308, 1e294),
      );
    }
  });
  test('모든 코드에 한국어 기본 설명이 있고 타입 오류의 출력만으로 위치/원인을 읽는다', () {
    for (final code in GeometryErrorCode.values) {
      expect(code.description, contains(RegExp('[가-힣]')));
      final exception = GeometryValidationException(
        code,
        'sample',
        const GeometryDiagnostic(operation: 'test'),
      );
      expect(
        exception.toString(),
        allOf(
          contains(code.name),
          contains('sample'),
          contains(code.description),
        ),
      );
    }
    try {
      DrawingGeometry.fromJson({
        'coordinateSpace': {'lengthUnit': 'millimeter'},
        'paths': [],
        'boundaries': [
          {
            'kind': 'circle',
            'center': {'x': 'wrong', 'y': 0},
            'radius': 1,
          },
        ],
      });
      fail('타입 오류를 허용함');
    } on GeometryValidationException catch (e) {
      expect(e.code, GeometryErrorCode.invalidType);
      expect(e.fieldPath, 'boundaries[0].center.x');
      final details = e.diagnostic.details as GeometryTypeDetails;
      expect(details.expectedType, 'num');
      expect(details.actualType, 'String');
      expect(
        e.toString(),
        allOf(
          contains(e.fieldPath),
          contains(e.code.description),
          contains('expectedType=num'),
          contains('actualType=String'),
        ),
      );
      expect(
        identical(e.prefixed('document').diagnostic, e.diagnostic),
        isTrue,
      );
    }
  });
  test('목록/객체/null 타입 오류에도 실제 타입을 제공한다', () {
    for (final (run, expected, actual) in <(void Function(), String, String)>[
      (() => Point2.fromJson(true), 'object', 'bool'),
      (() => Point2.fromJson({'x': null, 'y': 0}), 'num', 'Null'),
      (
        () => DrawingCoordinateSpace.fromJson({'lengthUnit': 12}),
        'String',
        'int',
      ),
      (
        () => GeometryPath.fromJson({
          'start': {'x': 0, 'y': 0},
          'segments': true,
        }),
        'List',
        'bool',
      ),
      (
        () => DrawingGeometry.fromJson({
          'coordinateSpace': {'lengthUnit': 'inch'},
          'paths': 0,
          'boundaries': [],
        }),
        'List',
        'int',
      ),
      (
        () => DrawingGeometry.fromJson({
          'coordinateSpace': {'lengthUnit': 'inch'},
          'paths': [],
          'boundaries': false,
        }),
        'List',
        'bool',
      ),
    ]) {
      try {
        run();
        fail('타입 오류 허용');
      } on GeometryValidationException catch (e) {
        final details = e.diagnostic.details as GeometryTypeDetails;
        expect(details.expectedType, expected);
        expect(details.actualType, actual);
      }
    }
  });
  test('원 극점은 시작점 대신 실제 중심/반지름/실패 방향으로 출력한다', () {
    try {
      CircleBoundary(
        center: Point2(x: double.maxFinite, y: 3),
        radius: double.maxFinite,
      );
      fail('원 극점 실패 누락');
    } on GeometryValidationException catch (e) {
      final details = e.diagnostic.details as GeometryCircleExtremumDetails;
      expect(details.centerX, double.maxFinite);
      expect(details.centerY, 3);
      expect(details.radius, double.maxFinite);
      expect(details.direction, GeometryExtremumDirection.positiveX);
      expect(
        e.toString(),
        allOf(
          contains('center=('),
          contains('radius='),
          contains('positiveX'),
          contains('Infinity'),
        ),
      );
      expect(e.toString(), isNot(contains('start=')));
    }
  });
  test('중첩 원호 JSON의 코드·위치·진단은 복원/접두사 연결에서 보존된다', () {
    final json = {
      'coordinateSpace': {'lengthUnit': 'millimeter'},
      'paths': [],
      'boundaries': [
        {
          'kind': 'path',
          'path': {
            'start': {'x': 1e308, 'y': 0},
            'segments': [
              {
                'kind': 'arc',
                'end': {'x': 1e308, 'y': 1e308},
                'bulge': 2,
              },
            ],
          },
        },
      ],
    };
    try {
      DrawingGeometry.fromJson(json);
      fail('복원 오류 누락');
    } on GeometryValidationException catch (e) {
      expect(e.code, GeometryErrorCode.numericRepresentationFailure);
      expect(e.fieldPath, 'boundaries[0].path.segments[0]');
      final details = e.diagnostic.details as GeometryArcExtremumDetails;
      expect(details.segment.startX, 1e308);
      expect(details.segment.bulge, 2);
      expect(details.extremum.centerX, closeTo(1.375e308, 1e294));
      expect(details.extremum.direction, GeometryExtremumDirection.positiveX);
      expect(identical(e.prefixed('root').diagnostic.details, details), isTrue);
      expect(
        e.toString(),
        allOf(
          contains('bulge=2.0'),
          contains('deriveArcExtremum'),
          contains(e.fieldPath),
        ),
      );
    }
  });
}
