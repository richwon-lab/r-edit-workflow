import 'dart:math' as math;

import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/geometry_builders.dart'
    show pointAtCoordinates, jsonThroughString;

GeometryPath singleArcPath(
  double sx,
  double sy,
  double ex,
  double ey,
  double bulge,
) => GeometryPath(
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
  return reverse
      ? singleArcPath(bx, by, ax, ay, -bulge)
      : singleArcPath(ax, ay, bx, by, bulge);
}

const directions = [
  GeometryExtremumDirection.positiveX,
  GeometryExtremumDirection.positiveY,
  GeometryExtremumDirection.negativeX,
  GeometryExtremumDirection.negativeY,
];

void main() {
  group('GeometryPath 원호의 수치 표현', () {
    {
      for (final bulge in [
        2.0,
        -2.0,
        1.0,
        -1.0,
        0.5,
        -0.5,
        1e200,
        -1e200,
        1e-200,
        -1e-200,
      ]) {
        test('bulge=$bulge 원호를 보정 없이 보존한다', () {
          final path = GeometryPath(
            start: pointAtCoordinates(0, 0),
            segments: [ArcTo(end: pointAtCoordinates(2, 0), bulge: bulge)],
          );
          final restored = GeometryPath.fromJson(
            jsonThroughString(path.toJson()),
          );
          expect(restored, path);
          expect((restored.segments.single as ArcTo).bulge, bulge);
        });
      }
    }

    {
      for (final bulge in [1e-310, -1e-310]) {
        test('bulge=$bulge 극소 원호의 유한 반지름·중심을 중간 오버플로 없이 생성·수정·복원한다', () {
          final value = singleArcPath(0, 0, 2e-300, 0, bulge);
          expect(value.segments, hasLength(1));
          expect((value.segments.single as ArcTo).bulge, bulge);
          expect(GeometryPath.fromJson(value.toJson()), value);
          expect(
            value.copyWith(
              segments: [ArcTo(end: Point2(x: 2e-300, y: 0), bulge: bulge)],
            ),
            value,
          );
        });
      }
    }

    {
      for (var turns = 0; turns < 4; turns++) {
        for (final reverse in [false, true]) {
          test(
            '반원 초과의 실제 극점 검사: 회전 ${turns * 90}도 ${reverse ? '시계' : '반시계'}',
            () {
              try {
                rotatedArc(1e308, 0, 1e308, 1e308, 2, turns, reverse);
                fail('표현 불가 극점을 수락함');
              } on GeometryValidationException catch (e) {
                expect(e.code, GeometryErrorCode.numericRepresentationFailure);
                expect(e.fieldPath, 'segments[0]');
                expect(e.diagnostic.operation, 'deriveArcExtremum');
                final details =
                    e.diagnostic.details as GeometryArcExtremumDetails;
                expect(details.extremum.direction, directions[turns]);
                expect(details.extremum.radius, closeTo(6.25e307, 1e293));
                expect(details.extremum.value.isInfinite, isTrue);
                expect(details.segment.bulge, reverse ? -2 : 2);
              }
            },
          );
          test(
            '짧은 원호 밖의 기반 원 극점은 거부하지 않는다: 회전 ${turns * 90}도 ${reverse ? '시계' : '반시계'}',
            () {
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
            },
          );
          test(
            '각도 0/2π 경계를 가로지르는 짧은 원호의 극점 범위 초과를 거부한다: 회전 ${turns * 90}도 ${reverse ? '시계' : '반시계'}',
            () {
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
            },
          );
        }
      }
    }

    {
      test('짧은 원호를 긴 원호로 수정하면 새로 지나는 범위 초과 극점을 거부한다', () {
        final original = singleArcPath(1e308, 0, 1e308, 1e308, 0.5);
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
      });
    }

    {
      test('반시계 반원이 범위 초과 오른쪽 극점을 지나면 거부한다', () {
        expect(
          () => singleArcPath(1e308, -1e308, 1e308, 1e308, 1),
          throwsA(
            isA<GeometryValidationException>().having(
              (e) => e.diagnostic.operation,
              '연산',
              'deriveArcExtremum',
            ),
          ),
        );
      });
    }

    {
      test('시계 반원이 범위 초과 오른쪽 극점을 지나지 않으면 수락한다', () {
        expect(
          singleArcPath(1e308, -1e308, 1e308, 1e308, -1).segments,
          hasLength(1),
        );
      });
    }

    {
      test('끝점을 뒤집은 반시계 반원이 범위 초과 극점을 피하면 수락한다', () {
        expect(
          singleArcPath(1e308, 1e308, 1e308, -1e308, 1).segments,
          hasLength(1),
        );
      });
    }

    {
      test('실제 반지름 오버플로를 반지름 연산 실패로 진단한다', () {
        expect(
          () => singleArcPath(0, 0, 2, 0, double.minPositive),
          throwsA(
            isA<GeometryValidationException>().having(
              (e) => e.diagnostic.operation,
              '연산',
              'deriveArcRadius',
            ),
          ),
        );
      });
    }

    {
      test('실제 중심 X 오버플로를 중심 연산 실패로 진단한다', () {
        expect(
          () => singleArcPath(1.7e308, 0, 1.7e308, 1e308, -0.5),
          throwsA(
            isA<GeometryValidationException>().having(
              (e) => e.diagnostic.operation,
              '연산',
              'deriveArcCenterX',
            ),
          ),
        );
      });
    }

    {
      test('유한 반지름이어도 실제 극점이 범위를 넘으면 거부한다', () {
        try {
          singleArcPath(-1e308, 0, 1e308, 0, 2);
          fail('실제 극점 오버플로를 수락함');
        } on GeometryValidationException catch (e) {
          expect(e.diagnostic.operation, 'deriveArcExtremum');
          expect(
            (e.diagnostic.details as GeometryArcExtremumDetails)
                .extremum
                .radius,
            closeTo(1.25e308, 1e294),
          );
        }
      });
    }
  });
}
