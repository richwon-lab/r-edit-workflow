import 'dart:convert';

import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/geometry_builders.dart'
    show
        pointAtCoordinates,
        linePathThroughVertices,
        rectangularPath4By2,
        geometryError,
        jsonThroughString;

void main() {
  group('ClosedBoundary의 명시적 경계', () {
    {
      final irregular = linePathThroughVertices([
        pointAtCoordinates(-2, -1),
        pointAtCoordinates(3, -1),
        pointAtCoordinates(4, 1),
        pointAtCoordinates(1, 3),
        pointAtCoordinates(-2, 2),
        pointAtCoordinates(-2, -1),
      ]);
      for (final (shape, path) in [
        ('직사각형', rectangularPath4By2()),
        ('비정형 다각형', irregular),
      ]) {
        test('$shape 경로의 모든 구간은 시작점을 중복 저장하지 않고 명시적으로 닫힌다', () {
          final boundary = PathBoundary(path: path);
          final restored = ClosedBoundary.fromJson(
            jsonThroughString(boundary.toJson()),
          );
          expect(restored, boundary);
          expect(restored.hashCode, boundary.hashCode);
          expect((restored as PathBoundary).path.segments.last.end, path.start);
          expect(path.toJson().containsKey('isClosed'), isFalse);
          expect(
            (path.toJson()['segments'] as List).every(
              (s) => !(s as Map).containsKey('start'),
            ),
            isTrue,
          );
        });
      }
    }

    {
      test('독립 원은 중심과 반지름만 정본으로 보관하고 정수 JSON을 받는다', () {
        final circle = ClosedBoundary.fromJson(
          jsonDecode('{"kind":"circle","center":{"x":-2,"y":3.5},"radius":4}'),
        ) as CircleBoundary;
        expect(circle.radius, isA<double>());
        expect(circle.center, pointAtCoordinates(-2, 3.5));
        expect(
          circle.toJson().keys,
          unorderedEquals(['kind', 'center', 'radius']),
        );
        expect(
          ClosedBoundary.fromJson(jsonThroughString(circle.toJson())),
          circle,
        );
        expect(circle.copyWith(radius: 5).radius, 5);
        expect(circle.radius, 4);
      });
    }

    {
      test('선분과 반원 구간을 잇는 장공은 시작점 중복 없이 왕복한다', () {
        final path = GeometryPath(
          start: pointAtCoordinates(10, 8),
          segments: [
            LineTo(end: pointAtCoordinates(20, 8)),
            ArcTo(end: pointAtCoordinates(20, 12), bulge: 1),
            LineTo(end: pointAtCoordinates(10, 12)),
            ArcTo(end: pointAtCoordinates(10, 8), bulge: 1),
          ],
        );
        expect(
          ClosedBoundary.fromJson(
            jsonThroughString(PathBoundary(path: path).toJson()),
          ),
          PathBoundary(path: path),
        );
        expect(path.segments.whereType<ArcTo>(), hasLength(2));
      });
    }

    {
      test('열린 경로를 닫힌 경계로 생성하면 거부한다', () {
        final open = GeometryPath(
          start: pointAtCoordinates(0, 0),
          segments: [LineTo(end: pointAtCoordinates(2, 0))],
        );
        expect(
          () => PathBoundary(path: open),
          geometryError(GeometryErrorCode.openBoundary, 'path.segments[0].end'),
        );
      });
    }

    {
      test('열린 경로로 경계를 수정하면 거부한다', () {
        final open = GeometryPath(
          start: pointAtCoordinates(0, 0),
          segments: [LineTo(end: pointAtCoordinates(2, 0))],
        );
        final boundary = PathBoundary(path: rectangularPath4By2());
        expect(
          () => boundary.copyWith(path: open),
          geometryError(GeometryErrorCode.openBoundary, 'path.segments[0].end'),
        );
      });
    }

    {
      test('열린 경계 JSON을 복원하면 거부한다', () {
        final open = GeometryPath(
          start: pointAtCoordinates(0, 0),
          segments: [LineTo(end: pointAtCoordinates(2, 0))],
        );
        expect(
          () =>
              ClosedBoundary.fromJson({'kind': 'path', 'path': open.toJson()}),
          geometryError(GeometryErrorCode.openBoundary, 'path.segments[0].end'),
        );
      });
    }

    {
      test('자기 교차 경로는 값 생성 단계에서 보정하지 않는다', () {
        final crossing = linePathThroughVertices([
          pointAtCoordinates(0, 0),
          pointAtCoordinates(2, 2),
          pointAtCoordinates(0, 2),
          pointAtCoordinates(2, 0),
          pointAtCoordinates(0, 0),
        ]);
        expect(PathBoundary(path: crossing).path, crossing);
      });
    }

    {
      test('왕복 선분 경로의 면적을 값 생성 단계에서 판정하지 않는다', () {
        final backtrack = linePathThroughVertices([
          pointAtCoordinates(0, 0),
          pointAtCoordinates(1, 0),
          pointAtCoordinates(0, 0),
        ]);
        expect(PathBoundary(path: backtrack).path, backtrack);
      });
    }

    {
      test('중심의 X를 비유한 값으로 수정하면 거부한다', () {
        final circle = CircleBoundary(
          center: pointAtCoordinates(1, 2),
          radius: 1,
        );
        expect(
          () => circle.copyWith.center(x: double.nan),
          geometryError(GeometryErrorCode.nonFiniteNumber, 'x'),
        );
      });
    }

    {
      test('반지름을 0으로 수정하면 거부한다', () {
        final circle = CircleBoundary(
          center: pointAtCoordinates(1, 2),
          radius: 1,
        );
        expect(
          () => circle.copyWith(radius: 0),
          geometryError(GeometryErrorCode.nonPositiveRadius, 'radius'),
        );
      });
    }

    {
      test('음수 반지름 JSON을 거부한다', () {
        expect(
          () => ClosedBoundary.fromJson({
            'kind': 'circle',
            'center': pointAtCoordinates(1, 2).toJson(),
            'radius': -1,
          }),
          geometryError(GeometryErrorCode.nonPositiveRadius, 'radius'),
        );
      });
    }

    {
      for (final value in [
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        test('원 반지름에서 비유한 값 $value를 거부한다', () {
          expect(
            () =>
                CircleBoundary(center: pointAtCoordinates(0, 0), radius: value),
            geometryError(GeometryErrorCode.nonFiniteNumber, 'radius'),
          );
        });
      }
    }

    {
      test('원의 극점이 범위를 넘으면 수치 표현 실패로 보고한다', () {
        expect(
          () => CircleBoundary(
            center: pointAtCoordinates(double.maxFinite, 0),
            radius: double.maxFinite,
          ),
          geometryError(
            GeometryErrorCode.numericRepresentationFailure,
            'radius',
          ),
        );
      });
    }

    {
      final json = CircleBoundary(
        center: pointAtCoordinates(0, 0),
        radius: 1,
      ).toJson();
      for (final key in json.keys) {
        test('CircleBoundary JSON에서 $key 누락을 보정하지 않는다', () {
          final missing = Map<String, Object?>.of(json)..remove(key);
          expect(
            () => ClosedBoundary.fromJson(missing),
            geometryError(GeometryErrorCode.missingField, key),
          );
        });
        test('CircleBoundary JSON에서 $key=null을 거부한다', () {
          expect(
            () => ClosedBoundary.fromJson({...json, key: null}),
            geometryError(GeometryErrorCode.invalidType, key),
          );
        });
      }
      test('CircleBoundary JSON의 최상위 목록을 거부한다', () {
        expect(
          () => ClosedBoundary.fromJson([]),
          geometryError(GeometryErrorCode.invalidType, r'$'),
        );
      });
      test('CircleBoundary JSON의 알 수 없는 필드를 거부한다', () {
        expect(
          () => ClosedBoundary.fromJson({...json, 'extra': true}),
          geometryError(GeometryErrorCode.unexpectedField, 'extra'),
        );
      });
    }

    {
      for (final tag in ['ellipse', 'rectangle', 'unknown']) {
        test('닫힌 경계의 미지원 태그 $tag를 대체하지 않는다', () {
          expect(
            () => ClosedBoundary.fromJson({'kind': tag}),
            geometryError(GeometryErrorCode.unsupportedTag, 'kind'),
          );
        });
      }
    }
  });
}
