import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/geometry_builders.dart'
    show pointAtCoordinates, rectangularPath4By2, geometryError;

void main() {
  group('GeometryPath의 구간 연결', () {
    {
      final line = LineTo(end: pointAtCoordinates(1, 2));
      final arc = ArcTo(end: pointAtCoordinates(1, 2), bulge: 2);
      for (final (kind, segment) in [('선분', line), ('원호', arc)]) {
        test('$kind 시작점과 끝점이 같으면 거부하고 다른 시작점에서는 수락한다', () {
          expect(
            () => GeometryPath(
              start: pointAtCoordinates(1, 2),
              segments: [segment],
            ),
            geometryError(
              GeometryErrorCode.degenerateSegment,
              'segments[0].end',
            ),
          );
          expect(
            GeometryPath(
              start: pointAtCoordinates(0, 0),
              segments: [segment],
            ).segments.single,
            segment,
          );
        });
      }
    }

    {
      test('시작점을 첫 끝점으로 수정하면 퇴화 구간을 거부한다', () {
        final original = rectangularPath4By2();
        expect(
          () => original.copyWith(start: pointAtCoordinates(4, 0)),
          geometryError(GeometryErrorCode.degenerateSegment, 'segments[0].end'),
        );
      });
    }

    {
      test('구간 목록을 비우는 수정을 거부한다', () {
        final original = rectangularPath4By2();
        expect(
          () => original.copyWith(segments: []),
          geometryError(GeometryErrorCode.emptyPath, 'segments'),
        );
      });
    }

    {
      test('JSON 복원에서도 시작점과 끝점이 같은 구간을 거부한다', () {
        final line = LineTo(end: pointAtCoordinates(1, 2));
        expect(
          () => GeometryPath.fromJson({
            'start': pointAtCoordinates(1, 2).toJson(),
            'segments': [line.toJson()],
          }),
          geometryError(GeometryErrorCode.degenerateSegment, 'segments[0].end'),
        );
      });
    }

    {
      test('닫힘 플래그로 누락 구간을 자동 추가하지 않는다', () {
        final open = GeometryPath(
          start: pointAtCoordinates(0, 0),
          segments: [LineTo(end: pointAtCoordinates(2, 0))],
        );
        expect(
          () => GeometryPath.fromJson({...open.toJson(), 'isClosed': true}),
          geometryError(GeometryErrorCode.unexpectedField, 'isClosed'),
        );
      });
    }

    {
      test('단위 환산 후 겹쳐진 구간 끝점을 수치 표현 실패로 보고한다', () {
        final tinyPath = GeometryPath(
          start: pointAtCoordinates(double.minPositive * 25, 0),
          segments: [
            LineTo(end: pointAtCoordinates(double.minPositive * 26, 0)),
          ],
        );
        expect(
          () => tinyPath.converted(
            from: LengthUnit.millimeter,
            to: LengthUnit.inch,
          ),
          geometryError(
            GeometryErrorCode.numericRepresentationFailure,
            'segments[0].end',
          ),
        );
      });
    }

    {
      final json = rectangularPath4By2().toJson();
      for (final key in json.keys) {
        test('GeometryPath JSON에서 $key 누락을 보정하지 않는다', () {
          final missing = Map<String, Object?>.of(json)..remove(key);
          expect(
            () => GeometryPath.fromJson(missing),
            geometryError(GeometryErrorCode.missingField, key),
          );
        });
        test('GeometryPath JSON에서 $key=null을 거부한다', () {
          expect(
            () => GeometryPath.fromJson({...json, key: null}),
            geometryError(GeometryErrorCode.invalidType, key),
          );
        });
      }
      test('GeometryPath JSON의 최상위 목록을 거부한다', () {
        expect(
          () => GeometryPath.fromJson([]),
          geometryError(GeometryErrorCode.invalidType, r'$'),
        );
      });
      test('GeometryPath JSON의 알 수 없는 필드를 거부한다', () {
        expect(
          () => GeometryPath.fromJson({...json, 'extra': true}),
          geometryError(GeometryErrorCode.unexpectedField, 'extra'),
        );
      });
    }
  });
}
