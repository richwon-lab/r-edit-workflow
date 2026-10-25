import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/geometry_builders.dart'
    show
        pointAtCoordinates,
        rectangularPath4By2,
        inchDrawingGeometry,
        geometryError,
        jsonThroughString;

void main() {
  group('DrawingGeometry의 단위 환산과 불변성', () {
    {
      test('inch에서 millimeter로 모든 길이를 환산하고 원본과 bulge를 보존한다', () {
        final arcPath = GeometryPath(
          start: pointAtCoordinates(-1, 0),
          segments: [ArcTo(end: pointAtCoordinates(1, 0), bulge: -2)],
        );
        final original = inchDrawingGeometry(
          paths: [arcPath],
          boundaries: [
            PathBoundary(path: rectangularPath4By2()),
            CircleBoundary(center: pointAtCoordinates(1, 0.5), radius: 0.25),
          ],
        );
        final mm = original.convertedTo(LengthUnit.millimeter);
        expect(mm.coordinateSpace.lengthUnit, LengthUnit.millimeter);
        expect(mm.paths.single.start, pointAtCoordinates(-25.4, 0));
        expect(
          mm.paths.single.segments.single.end,
          pointAtCoordinates(25.4, 0),
        );
        expect((mm.paths.single.segments.single as ArcTo).bulge, -2);
        expect(
          (mm.boundaries.last as CircleBoundary).center,
          pointAtCoordinates(25.4, 12.7),
        );
        expect((mm.boundaries.last as CircleBoundary).radius, 6.35);
        expect(
          (mm.boundaries.first as PathBoundary).path.segments[1].end,
          pointAtCoordinates(101.6, 50.8),
        );
        expect(original.coordinateSpace.lengthUnit, LengthUnit.inch);
        expect(original.paths.single.start, pointAtCoordinates(-1, 0));
        expect(DrawingGeometry.fromJson(jsonThroughString(mm.toJson())), mm);
        expect(mm.convertedTo(LengthUnit.millimeter), mm);
      });
    }

    {
      test('입력 목록·공개 목록·반환 JSON의 모든 단계에서 모델을 바꿀 수 없다', () {
        final segments = <PathSegment>[
          LineTo(end: pointAtCoordinates(1, 0)),
          LineTo(end: pointAtCoordinates(0, 0)),
        ];
        final path = GeometryPath(
          start: pointAtCoordinates(0, 0),
          segments: segments,
        );
        final paths = [path];
        final boundaries = <ClosedBoundary>[PathBoundary(path: path)];
        final original = inchDrawingGeometry(
          paths: paths,
          boundaries: boundaries,
        );
        segments.clear();
        paths.clear();
        boundaries.clear();
        expect(original.paths.single.segments, hasLength(2));
        expect(() => original.paths.clear(), throwsUnsupportedError);
        expect(() => original.boundaries.clear(), throwsUnsupportedError);
        expect(() => path.segments.clear(), throwsUnsupportedError);
        final replacement = <PathSegment>[
          LineTo(end: pointAtCoordinates(2, 0)),
        ];
        final changed = path.copyWith(segments: replacement);
        replacement.clear();
        expect(changed.segments, hasLength(1));
        expect(path.segments, hasLength(2));
        final json = original.toJson();
        final restored = DrawingGeometry.fromJson(json);
        final outputPaths = json['paths'] as List;
        final first = outputPaths.first as Map;
        (first['start'] as Map)['x'] = 999;
        ((first['segments'] as List).first as Map)['kind'] = 'unknown';
        outputPaths.clear();
        (json['boundaries'] as List).clear();
        (json['coordinateSpace'] as Map)['lengthUnit'] = 'unknown';
        expect(restored, original);
        expect(
          DrawingGeometry.fromJson(jsonThroughString(original.toJson())),
          original,
        );
      });
    }

    {
      test('묶음 환산 실패에 경계 목록 위치를 붙인다', () {
        expect(
          () => inchDrawingGeometry(
            boundaries: [
              CircleBoundary(
                center: pointAtCoordinates(1, 0),
                radius: double.maxFinite,
              ),
            ],
          ).convertedTo(LengthUnit.millimeter),
          geometryError(
            GeometryErrorCode.numericRepresentationFailure,
            'boundaries[0].radius',
          ),
        );
      });
    }

    {
      final json = inchDrawingGeometry().toJson();
      for (final key in json.keys) {
        test('DrawingGeometry JSON에서 $key 누락을 보정하지 않는다', () {
          final missing = Map<String, Object?>.of(json)..remove(key);
          expect(
            () => DrawingGeometry.fromJson(missing),
            geometryError(GeometryErrorCode.missingField, key),
          );
        });
        test('DrawingGeometry JSON에서 $key=null을 거부한다', () {
          expect(
            () => DrawingGeometry.fromJson({...json, key: null}),
            geometryError(GeometryErrorCode.invalidType, key),
          );
        });
      }
      test('DrawingGeometry JSON의 최상위 목록을 거부한다', () {
        expect(
          () => DrawingGeometry.fromJson([]),
          geometryError(GeometryErrorCode.invalidType, r'$'),
        );
      });
      test('DrawingGeometry JSON의 알 수 없는 필드를 거부한다', () {
        expect(
          () => DrawingGeometry.fromJson({...json, 'extra': true}),
          geometryError(GeometryErrorCode.unexpectedField, 'extra'),
        );
      });
    }
  });
}
