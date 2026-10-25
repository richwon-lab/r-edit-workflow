import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/geometry_builders.dart' show pointAtCoordinates;

void main() {
  group('GeometryValidationException의 원인과 위치', () {
    {
      test('표현 불가 원호 반지름의 연산과 끝점·bulge를 진단한다', () {
        final arc = ArcTo(
          end: pointAtCoordinates(2, 0),
          bulge: double.minPositive,
        );
        try {
          GeometryPath(start: pointAtCoordinates(0, 0), segments: [arc]);
          fail('표현 불가 원호가 생성됨');
        } on GeometryValidationException catch (e) {
          expect(e.code, GeometryErrorCode.numericRepresentationFailure);
          expect(e.fieldPath, 'segments[0]');
          expect(e.diagnostic.operation, 'deriveArcRadius');
          expect(
            (e.diagnostic.details as GeometryArcCalculationDetails)
                .segment
                .bulge,
            double.minPositive,
          );
          expect(
            (e.diagnostic.details as GeometryArcCalculationDetails)
                .segment
                .endX,
            2,
          );
        }
      });
    }

    {
      test('중첩 복원은 파생 오류 진단과 부모 경로를 보존한다', () {
        final json = {
          'coordinateSpace': {'lengthUnit': 'millimeter'},
          'paths': [],
          'boundaries': [
            {
              'kind': 'path',
              'path': {
                'start': {'x': 0, 'y': 0},
                'segments': [
                  {
                    'kind': 'arc',
                    'end': {'x': 2, 'y': 0},
                    'bulge': double.minPositive,
                  },
                  {
                    'kind': 'line',
                    'end': {'x': 0, 'y': 0},
                  },
                ],
              },
            },
          ],
        };
        try {
          DrawingGeometry.fromJson(json);
          fail('복원 성공');
        } on GeometryValidationException catch (e) {
          expect(e.fieldPath, 'boundaries[0].path.segments[0]');
          expect(e.code, GeometryErrorCode.numericRepresentationFailure);
          expect(
            (e.diagnostic.details as GeometryArcCalculationDetails)
                .segment
                .startX,
            0,
          );
          expect(
            (e.diagnostic.details as GeometryArcCalculationDetails)
                .segment
                .endX,
            2,
          );
          expect(
            (e.diagnostic.details as GeometryArcCalculationDetails)
                .segment
                .bulge,
            double.minPositive,
          );
        }
      });
    }

    {
      for (final code in GeometryErrorCode.values) {
        test('$code 예외 출력은 한국어 설명·코드·위치를 제공한다', () {
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
        });
      }
    }

    {
      test('문자열 X 좌표의 기대·실제 타입과 중첩 위치를 출력하고 접두사 연결에서도 진단을 보존한다', () {
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
    }

    {
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
        test('기대 타입 $expected·실제 타입 $actual의 오류를 진단한다', () {
          try {
            run();
            fail('타입 오류 허용');
          } on GeometryValidationException catch (e) {
            final details = e.diagnostic.details as GeometryTypeDetails;
            expect(details.expectedType, expected);
            expect(details.actualType, actual);
          }
        });
      }
    }

    {
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
    }

    {
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
          expect(
            details.extremum.direction,
            GeometryExtremumDirection.positiveX,
          );
          expect(
            identical(e.prefixed('root').diagnostic.details, details),
            isTrue,
          );
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
  });
}
