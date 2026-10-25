import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/geometry_builders.dart'
    show geometryError, pointAtCoordinates;

void main() {
  group('PathSegment의 선분·원호 입력', () {
    {
      test('원호 bulge를 0으로 수정하면 거부한다', () {
        final arc = ArcTo(end: pointAtCoordinates(1, 0), bulge: 1);
        expect(
          () => arc.copyWith(bulge: 0),
          geometryError(GeometryErrorCode.zeroArcBulge, 'bulge'),
        );
      });
    }

    {
      test('bulge가 0인 원호 JSON은 선분으로 보정하지 않는다', () {
        expect(
          () => PathSegment.fromJson({
            'kind': 'arc',
            'end': pointAtCoordinates(1, 0).toJson(),
            'bulge': 0,
          }),
          geometryError(GeometryErrorCode.zeroArcBulge, 'bulge'),
        );
      });
    }

    {
      for (final value in [
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        test('원호 bulge에서 비유한 값 $value를 거부한다', () {
          expect(
            () => ArcTo(end: pointAtCoordinates(1, 0), bulge: value),
            geometryError(GeometryErrorCode.nonFiniteNumber, 'bulge'),
          );
        });
      }
    }

    {
      final json = {
        'kind': 'arc',
        'end': {'x': 1, 'y': 2},
        'bulge': 2,
      };
      for (final key in json.keys) {
        test('PathSegment JSON에서 $key 누락을 보정하지 않는다', () {
          final missing = Map<String, Object?>.of(json)..remove(key);
          expect(
            () => PathSegment.fromJson(missing),
            geometryError(GeometryErrorCode.missingField, key),
          );
        });
        test('PathSegment JSON에서 $key=null을 거부한다', () {
          expect(
            () => PathSegment.fromJson({...json, key: null}),
            geometryError(GeometryErrorCode.invalidType, key),
          );
        });
      }
      test('PathSegment JSON의 최상위 목록을 거부한다', () {
        expect(
          () => PathSegment.fromJson([]),
          geometryError(GeometryErrorCode.invalidType, r'$'),
        );
      });
      test('PathSegment JSON의 알 수 없는 필드를 거부한다', () {
        expect(
          () => PathSegment.fromJson({...json, 'extra': true}),
          geometryError(GeometryErrorCode.unexpectedField, 'extra'),
        );
      });
    }

    {
      for (final tag in ['ellipse', 'rectangle', 'unknown']) {
        test('구간 필수값 없는 미지원 태그 $tag를 대체하지 않는다', () {
          expect(
            () => PathSegment.fromJson({'kind': tag}),
            geometryError(GeometryErrorCode.unsupportedTag, 'kind'),
          );
        });
      }
    }

    {
      for (final tag in ['ellipse', 'rectangle', 'unknown']) {
        test('끝점이 있는 구간의 미지원 태그 $tag를 대체하지 않는다', () {
          expect(
            () => PathSegment.fromJson({
              'kind': tag,
              'end': {'x': 1, 'y': 2},
            }),
            geometryError(GeometryErrorCode.unsupportedTag, 'kind'),
          );
        });
      }
    }
  });
}
