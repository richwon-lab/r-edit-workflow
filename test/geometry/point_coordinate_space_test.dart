import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/geometry_builders.dart'
    show pointAtCoordinates, geometryError;

void main() {
  group('Point2와 DrawingCoordinateSpace', () {
    {
      test('동일 단위 환산은 정밀도를 임의 반올림하지 않는다', () {
        expect(
          pointAtCoordinates(
            1.23456789012345,
            0,
          ).converted(from: LengthUnit.millimeter, to: LengthUnit.millimeter).x,
          1.23456789012345,
        );
      });
    }

    {
      for (final value in [
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        test('점 X 생성에서 비유한 값 $value를 거부한다', () {
          expect(
            () => Point2(x: value, y: 0),
            geometryError(GeometryErrorCode.nonFiniteNumber, 'x'),
          );
        });
      }
    }

    {
      for (final value in [
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        test('점 Y 수정에서 비유한 값 $value를 거부한다', () {
          expect(
            () => pointAtCoordinates(0, 0).copyWith(y: value),
            geometryError(GeometryErrorCode.nonFiniteNumber, 'y'),
          );
        });
      }
    }

    {
      test('단위 환산으로 0이 되는 유효 길이를 거부한다', () {
        expect(
          () => pointAtCoordinates(
            double.minPositive,
            0,
          ).converted(from: LengthUnit.millimeter, to: LengthUnit.inch),
          geometryError(GeometryErrorCode.numericRepresentationFailure, 'x'),
        );
      });
    }

    {
      final json = {'x': 1, 'y': 2};
      for (final key in json.keys) {
        test('Point2 JSON에서 $key 누락을 보정하지 않는다', () {
          final missing = Map<String, Object?>.of(json)..remove(key);
          expect(
            () => Point2.fromJson(missing),
            geometryError(GeometryErrorCode.missingField, key),
          );
        });
        test('Point2 JSON에서 $key=null을 거부한다', () {
          expect(
            () => Point2.fromJson({...json, key: null}),
            geometryError(GeometryErrorCode.invalidType, key),
          );
        });
      }
      test('Point2 JSON의 최상위 목록을 거부한다', () {
        expect(
          () => Point2.fromJson([]),
          geometryError(GeometryErrorCode.invalidType, r'$'),
        );
      });
      test('Point2 JSON의 알 수 없는 필드를 거부한다', () {
        expect(
          () => Point2.fromJson({...json, 'extra': true}),
          geometryError(GeometryErrorCode.unexpectedField, 'extra'),
        );
      });
    }

    {
      final json = {'lengthUnit': 'inch'};
      for (final key in json.keys) {
        test('DrawingCoordinateSpace JSON에서 $key 누락을 보정하지 않는다', () {
          final missing = Map<String, Object?>.of(json)..remove(key);
          expect(
            () => DrawingCoordinateSpace.fromJson(missing),
            geometryError(GeometryErrorCode.missingField, key),
          );
        });
        test('DrawingCoordinateSpace JSON에서 $key=null을 거부한다', () {
          expect(
            () => DrawingCoordinateSpace.fromJson({...json, key: null}),
            geometryError(GeometryErrorCode.invalidType, key),
          );
        });
      }
      test('DrawingCoordinateSpace JSON의 최상위 목록을 거부한다', () {
        expect(
          () => DrawingCoordinateSpace.fromJson([]),
          geometryError(GeometryErrorCode.invalidType, r'$'),
        );
      });
      test('DrawingCoordinateSpace JSON의 알 수 없는 필드를 거부한다', () {
        expect(
          () => DrawingCoordinateSpace.fromJson({...json, 'extra': true}),
          geometryError(GeometryErrorCode.unexpectedField, 'extra'),
        );
      });
    }

    {
      test('pixel 단위를 거부하고 원래 태그와 문맥 경로를 보존한다', () {
        try {
          DrawingGeometry.fromJson({
            'coordinateSpace': {'lengthUnit': 'pixel'},
            'paths': [],
            'boundaries': [],
          });
          fail('지원되지 않는 단위');
        } on GeometryValidationException catch (e) {
          expect(e.fieldPath, 'coordinateSpace.lengthUnit');
          expect((e.diagnostic.details as GeometryTagDetails).tag, 'pixel');
        }
      });
    }
  });
}
