import 'dart:convert';

import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

Point2 p(double x, double y) => Point2(x: x, y: y);
GeometryPath polygon(List<Point2> points) => GeometryPath(
  start: points.first,
  segments: [for (final end in points.skip(1)) LineTo(end: end)],
);
GeometryPath rectangle() =>
    polygon([p(0, 0), p(4, 0), p(4, 2), p(0, 2), p(0, 0)]);
DrawingGeometry drawing({
  List<GeometryPath>? paths,
  List<ClosedBoundary>? boundaries,
  LengthUnit unit = LengthUnit.inch,
}) => DrawingGeometry(
  coordinateSpace: DrawingCoordinateSpace(lengthUnit: unit),
  paths: paths ?? [],
  boundaries: boundaries ?? [],
);
Object? roundTripJson(Object? json) => jsonDecode(jsonEncode(json));
Matcher rejects(GeometryErrorCode code, String path) => throwsA(
  isA<GeometryValidationException>()
      .having((e) => e.code, 'code', code)
      .having((e) => e.fieldPath, 'fieldPath', path),
);

void main() {
  test('직사각형과 새 비정형 다각형은 같은 선분 데이터로 닫힌 경계를 만든다', () {
    final irregular = polygon([
      p(-2, -1),
      p(3, -1),
      p(4, 1),
      p(1, 3),
      p(-2, 2),
      p(-2, -1),
    ]);
    for (final path in [rectangle(), irregular]) {
      final boundary = PathBoundary(path: path);
      final restored = ClosedBoundary.fromJson(
        roundTripJson(boundary.toJson()),
      );
      expect(restored, boundary);
      expect(restored.hashCode, boundary.hashCode);
      expect((restored as PathBoundary).path.segments.last.end, path.start);
      expect(path.toJson().containsKey('isClosed'), isFalse);
      expect(
        (path.toJson()['segments'] as List).every(
          (s) => (s as Map).containsKey('start'),
        ),
        isFalse,
      );
    }
  });
  test('독립 원은 중심과 반지름만 정본으로 보관하고 정수 JSON을 받는다', () {
    final circle = ClosedBoundary.fromJson(
      jsonDecode('{"kind":"circle","center":{"x":-2,"y":3.5},"radius":4}'),
    ) as CircleBoundary;
    expect(circle.radius, isA<double>());
    expect(circle.center, p(-2, 3.5));
    expect(circle.toJson().keys, unorderedEquals(['kind', 'center', 'radius']));
    expect(ClosedBoundary.fromJson(roundTripJson(circle.toJson())), circle);
    expect(circle.copyWith(radius: 5).radius, 5);
    expect(circle.radius, 4);
  });
  test('선분과 반원 구간을 잇는 장공은 시작점 중복 없이 왕복한다', () {
    final path = GeometryPath(
      start: p(10, 8),
      segments: [
        LineTo(end: p(20, 8)),
        ArcTo(end: p(20, 12), bulge: 1),
        LineTo(end: p(10, 12)),
        ArcTo(end: p(10, 8), bulge: 1),
      ],
    );
    expect(
      ClosedBoundary.fromJson(roundTripJson(PathBoundary(path: path).toJson())),
      PathBoundary(path: path),
    );
    expect(path.segments.whereType<ArcTo>(), hasLength(2));
  });
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
    test('원호의 양방향·반원 초과·큰 bulge를 보정하지 않는다: $bulge', () {
      final path = GeometryPath(
        start: p(0, 0),
        segments: [ArcTo(end: p(2, 0), bulge: bulge)],
      );
      final restored = GeometryPath.fromJson(roundTripJson(path.toJson()));
      expect(restored, path);
      expect((restored.segments.single as ArcTo).bulge, bulge);
    });
  }
  test('구간은 시작점과 무관한 값만, 경로는 퇴화 여부를 검사한다', () {
    final line = LineTo(end: p(1, 2));
    final arc = ArcTo(end: p(1, 2), bulge: 2);
    for (final segment in [line, arc]) {
      expect(
        () => GeometryPath(start: p(1, 2), segments: [segment]),
        rejects(GeometryErrorCode.degenerateSegment, 'segments[0].end'),
      );
      expect(
        GeometryPath(start: p(0, 0), segments: [segment]).segments.single,
        segment,
      );
    }
    final original = rectangle();
    expect(
      () => original.copyWith(start: p(4, 0)),
      rejects(GeometryErrorCode.degenerateSegment, 'segments[0].end'),
    );
    expect(
      () => original.copyWith(segments: []),
      rejects(GeometryErrorCode.emptyPath, 'segments'),
    );
    expect(
      () => GeometryPath.fromJson({
        'start': p(1, 2).toJson(),
        'segments': [line.toJson()],
      }),
      rejects(GeometryErrorCode.degenerateSegment, 'segments[0].end'),
    );
  });
  test('닫히지 않은 경로를 플래그로 고치거나 선분을 추가하지 않는다', () {
    final open = GeometryPath(
      start: p(0, 0),
      segments: [LineTo(end: p(2, 0))],
    );
    expect(
      () => PathBoundary(path: open),
      rejects(GeometryErrorCode.openBoundary, 'path.segments[0].end'),
    );
    final boundary = PathBoundary(path: rectangle());
    expect(
      () => boundary.copyWith(path: open),
      rejects(GeometryErrorCode.openBoundary, 'path.segments[0].end'),
    );
    expect(
      () => ClosedBoundary.fromJson({'kind': 'path', 'path': open.toJson()}),
      rejects(GeometryErrorCode.openBoundary, 'path.segments[0].end'),
    );
    expect(
      () => GeometryPath.fromJson({...open.toJson(), 'isClosed': true}),
      rejects(GeometryErrorCode.unexpectedField, 'isClosed'),
    );
  });
  test('원이 아닌 자유 구멍도 같은 경계 타입이며 자기 교차나 영면적은 아직 검사하지 않는다', () {
    final crossing = polygon([p(0, 0), p(2, 2), p(0, 2), p(2, 0), p(0, 0)]);
    expect(PathBoundary(path: crossing).path, crossing);
    final backtrack = polygon([p(0, 0), p(1, 0), p(0, 0)]);
    expect(PathBoundary(path: backtrack).path, backtrack);
  });
  test('단위 환산은 문맥·모든 좌표·반지름을 바꾸고 bulge를 보존한다', () {
    final arcPath = GeometryPath(
      start: p(-1, 0),
      segments: [ArcTo(end: p(1, 0), bulge: -2)],
    );
    final original = drawing(
      paths: [arcPath],
      boundaries: [
        PathBoundary(path: rectangle()),
        CircleBoundary(center: p(1, 0.5), radius: 0.25),
      ],
    );
    final mm = original.convertedTo(LengthUnit.millimeter);
    expect(mm.coordinateSpace.lengthUnit, LengthUnit.millimeter);
    expect(mm.paths.single.start, p(-25.4, 0));
    expect(mm.paths.single.segments.single.end, p(25.4, 0));
    expect((mm.paths.single.segments.single as ArcTo).bulge, -2);
    expect((mm.boundaries.last as CircleBoundary).center, p(25.4, 12.7));
    expect((mm.boundaries.last as CircleBoundary).radius, 6.35);
    expect(
      (mm.boundaries.first as PathBoundary).path.segments[1].end,
      p(101.6, 50.8),
    );
    expect(original.coordinateSpace.lengthUnit, LengthUnit.inch);
    expect(original.paths.single.start, p(-1, 0));
    expect(DrawingGeometry.fromJson(roundTripJson(mm.toJson())), mm);
    expect(mm.convertedTo(LengthUnit.millimeter), mm);
    expect(
      p(
        1.23456789012345,
        0,
      ).converted(from: LengthUnit.millimeter, to: LengthUnit.millimeter).x,
      1.23456789012345,
    );
  });
  test('입력 목록·공개 목록·반환 JSON의 모든 단계에서 모델을 바꿀 수 없다', () {
    final segments = <PathSegment>[LineTo(end: p(1, 0)), LineTo(end: p(0, 0))];
    final path = GeometryPath(start: p(0, 0), segments: segments);
    final paths = [path];
    final boundaries = <ClosedBoundary>[PathBoundary(path: path)];
    final original = drawing(paths: paths, boundaries: boundaries);
    segments.clear();
    paths.clear();
    boundaries.clear();
    expect(original.paths.single.segments, hasLength(2));
    expect(() => original.paths.clear(), throwsUnsupportedError);
    expect(() => original.boundaries.clear(), throwsUnsupportedError);
    expect(() => path.segments.clear(), throwsUnsupportedError);
    final replacement = <PathSegment>[LineTo(end: p(2, 0))];
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
      DrawingGeometry.fromJson(roundTripJson(original.toJson())),
      original,
    );
  });
  test('생성된 중첩 수정과 JSON 복원도 수학적 값 검증을 우회하지 않는다', () {
    final circle = CircleBoundary(center: p(1, 2), radius: 1);
    expect(
      () => circle.copyWith.center(x: double.nan),
      rejects(GeometryErrorCode.nonFiniteNumber, 'x'),
    );
    expect(
      () => circle.copyWith(radius: 0),
      rejects(GeometryErrorCode.nonPositiveRadius, 'radius'),
    );
    final arc = ArcTo(end: p(1, 0), bulge: 1);
    expect(
      () => arc.copyWith(bulge: 0),
      rejects(GeometryErrorCode.zeroArcBulge, 'bulge'),
    );
    expect(
      () => PathSegment.fromJson({
        'kind': 'arc',
        'end': p(1, 0).toJson(),
        'bulge': 0,
      }),
      rejects(GeometryErrorCode.zeroArcBulge, 'bulge'),
    );
    expect(
      () => ClosedBoundary.fromJson({
        'kind': 'circle',
        'center': p(1, 2).toJson(),
        'radius': -1,
      }),
      rejects(GeometryErrorCode.nonPositiveRadius, 'radius'),
    );
  });
  for (final value in [double.nan, double.infinity, double.negativeInfinity]) {
    test('비유한 좌표/반지름/bulge를 거부한다: $value', () {
      expect(
        () => Point2(x: value, y: 0),
        rejects(GeometryErrorCode.nonFiniteNumber, 'x'),
      );
      expect(
        () => p(0, 0).copyWith(y: value),
        rejects(GeometryErrorCode.nonFiniteNumber, 'y'),
      );
      expect(
        () => ArcTo(end: p(1, 0), bulge: value),
        rejects(GeometryErrorCode.nonFiniteNumber, 'bulge'),
      );
      expect(
        () => CircleBoundary(center: p(0, 0), radius: value),
        rejects(GeometryErrorCode.nonFiniteNumber, 'radius'),
      );
    });
  }
  test('파생 실패는 입력 수학 오류·소비자 미지원과 구분하고 원인 수치를 남긴다', () {
    final tinyPath = GeometryPath(
      start: p(double.minPositive * 25, 0),
      segments: [LineTo(end: p(double.minPositive * 26, 0))],
    );
    expect(
      () =>
          tinyPath.converted(from: LengthUnit.millimeter, to: LengthUnit.inch),
      rejects(
        GeometryErrorCode.numericRepresentationFailure,
        'segments[0].end',
      ),
    );
    final arc = ArcTo(end: p(2, 0), bulge: double.minPositive);
    try {
      GeometryPath(start: p(0, 0), segments: [arc]);
      fail('표현 불가 원호가 생성됨');
    } on GeometryValidationException catch (e) {
      expect(e.code, GeometryErrorCode.numericRepresentationFailure);
      expect(e.fieldPath, 'segments[0]');
      expect(e.diagnostic.operation, 'deriveArcRadius');
      expect(e.diagnostic.bulge, double.minPositive);
      expect(e.diagnostic.endX, 2);
    }
    expect(
      () => CircleBoundary(
        center: p(double.maxFinite, 0),
        radius: double.maxFinite,
      ),
      rejects(GeometryErrorCode.numericRepresentationFailure, 'radius'),
    );
    expect(
      () => drawing(
        boundaries: [CircleBoundary(center: p(1, 0), radius: double.maxFinite)],
      ).convertedTo(LengthUnit.millimeter),
      rejects(
        GeometryErrorCode.numericRepresentationFailure,
        'boundaries[0].radius',
      ),
    );
    expect(
      () => p(
        double.minPositive,
        0,
      ).converted(from: LengthUnit.millimeter, to: LengthUnit.inch),
      rejects(GeometryErrorCode.numericRepresentationFailure, 'x'),
    );
  });
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
      expect(e.diagnostic.startX, 0);
      expect(e.diagnostic.endX, 2);
      expect(e.diagnostic.bulge, double.minPositive);
    }
  });
  final parsers = <(String, Map<String, Object?>, Object Function(Object?))>[
    ('점', {'x': 1, 'y': 2}, Point2.fromJson),
    ('문맥', {'lengthUnit': 'inch'}, DrawingCoordinateSpace.fromJson),
    (
      '구간',
      {
        'kind': 'arc',
        'end': {'x': 1, 'y': 2},
        'bulge': 2,
      },
      PathSegment.fromJson,
    ),
    ('경로', rectangle().toJson(), GeometryPath.fromJson),
    (
      '원',
      CircleBoundary(center: p(0, 0), radius: 1).toJson(),
      ClosedBoundary.fromJson,
    ),
    ('묶음', drawing().toJson(), DrawingGeometry.fromJson),
  ];
  for (final (name, json, parse) in parsers) {
    test('$name 누락/null/최상위 타입/추가 필드가 조용히 보정되지 않는다', () {
      for (final key in json.keys) {
        final missing = Map<String, Object?>.of(json)..remove(key);
        expect(
          () => parse(missing),
          rejects(GeometryErrorCode.missingField, key),
        );
        expect(
          () => parse({...json, key: null}),
          rejects(GeometryErrorCode.invalidType, key),
        );
      }
      expect(() => parse([]), rejects(GeometryErrorCode.invalidType, r'$'));
      expect(
        () => parse({...json, 'extra': true}),
        rejects(GeometryErrorCode.unexpectedField, 'extra'),
      );
    });
  }
  test('미지원 태그는 원래 태그와 경로를 유지하고 어떤 형상으로도 대체하지 않는다', () {
    for (final tag in ['ellipse', 'rectangle', 'unknown']) {
      expect(
        () => PathSegment.fromJson({'kind': tag}),
        rejects(GeometryErrorCode.unsupportedTag, 'kind'),
      );
      expect(
        () => ClosedBoundary.fromJson({'kind': tag}),
        rejects(GeometryErrorCode.unsupportedTag, 'kind'),
      );
      expect(
        () => PathSegment.fromJson({
          'kind': tag,
          'end': {'x': 1, 'y': 2},
        }),
        rejects(GeometryErrorCode.unsupportedTag, 'kind'),
      );
    }
    try {
      DrawingGeometry.fromJson({
        'coordinateSpace': {'lengthUnit': 'pixel'},
        'paths': [],
        'boundaries': [],
      });
      fail('지원되지 않는 단위');
    } on GeometryValidationException catch (e) {
      expect(e.fieldPath, 'coordinateSpace.lengthUnit');
      expect(e.diagnostic.tag, 'pixel');
    }
  });
}
