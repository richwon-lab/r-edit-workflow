import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/design_builders.dart' show rectangularBoundary4By2;
import '../support/product_examples.dart' show millimeterDesignWithAreaIds;

void main() {
  group('공통 적용 ID의 전체 내용', () {
    test('서로 다른 객체로 생성한 동등한 스냅샷은 충돌하지 않는다', () {
      final a = _snapshot('g');
      final b = _snapshot('g');
      expect(identical(a, b), isFalse);
      expect(a, b);
      expect(
        validateAppliedGeometryIdConsistency(
          previous: _configuration([a]),
          next: _configuration([b]),
        ),
        isEmpty,
      );
    });

    final changes =
        <(String, DesignGeometry Function(DesignGeometry), List<String>)>[
          (
            '외곽 중심과 반지름',
            (g) => g.copyWith(
              outline: CircleBoundary(center: Point2(x: 1, y: 2), radius: 31),
            ),
            [
              'geometry.outline.center.x',
              'geometry.outline.center.y',
              'geometry.outline.radius',
            ],
          ),
          (
            '관통 경계',
            (g) => g.copyWith(
              cutouts: [
                g.cutouts[0].copyWith(boundary: _circle(2)),
                g.cutouts[1],
              ],
            ),
            ['geometry.cutouts[0].boundary.radius'],
          ),
          (
            '관통 식별자',
            (g) => g.copyWith(
              cutouts: [
                g.cutouts[0].copyWith(cutoutId: 'new-hole'),
                g.cutouts[1],
              ],
            ),
            ['geometry.cutouts[0].cutoutId'],
          ),
          (
            '영역 식별자',
            (g) => g.copyWith(
              textAreas: [
                g.textAreas[0].copyWith(areaId: 'heading'),
                g.textAreas[1],
              ],
            ),
            ['geometry.textAreas[0].areaId'],
          ),
          (
            '빈 표시 이름',
            (g) => g.copyWith(
              textAreas: [
                g.textAreas[0].copyWith(label: ' '),
                g.textAreas[1],
              ],
            ),
            ['geometry.textAreas[0].label'],
          ),
          (
            '영역 외부 경계',
            (g) => g.copyWith(
              textAreas: [
                g.textAreas[0].copyWith(
                  region: g.textAreas[0].region.copyWith(outer: _circle(11)),
                ),
                g.textAreas[1],
              ],
            ),
            ['geometry.textAreas[0].region.outer.radius'],
          ),
          (
            '명시 제외 경계',
            (g) => g.copyWith(
              textAreas: [
                g.textAreas[0].copyWith(
                  region: g.textAreas[0].region.copyWith(
                    exclusions: [_circle(3), _circle(2)],
                  ),
                ),
                g.textAreas[1],
              ],
            ),
            ['geometry.textAreas[0].region.exclusions[0].radius'],
          ),
          (
            '관통 순서',
            (g) => g.copyWith(cutouts: g.cutouts.reversed.toList()),
            ['geometry.cutouts[0].cutoutId', 'geometry.cutouts[1].cutoutId'],
          ),
          (
            '영역 순서',
            (g) => g.copyWith(textAreas: g.textAreas.reversed.toList()),
            ['geometry.textAreas[0].areaId', 'geometry.textAreas[1].areaId'],
          ),
          (
            '제외 경계 순서',
            (g) => g.copyWith(
              textAreas: [
                g.textAreas[0].copyWith(
                  region: g.textAreas[0].region.copyWith(
                    exclusions: [_circle(2), _circle(1)],
                  ),
                ),
                g.textAreas[1],
              ],
            ),
            [
              'geometry.textAreas[0].region.exclusions[0].radius',
              'geometry.textAreas[0].region.exclusions[1].radius',
            ],
          ),
          (
            '관통 추가',
            (g) => g.copyWith(
              cutouts: [
                ...g.cutouts,
                CutoutDefinition(cutoutId: 'new', boundary: _circle(1)),
              ],
            ),
            ['geometry.cutouts'],
          ),
          ('관통 삭제', (g) => g.copyWith(cutouts: []), ['geometry.cutouts']),
          (
            '영역 추가',
            (g) => g.copyWith(
              textAreas: [
                ...g.textAreas,
                g.textAreas[0].copyWith(areaId: 'new'),
              ],
            ),
            ['geometry.textAreas'],
          ),
          ('영역 삭제', (g) => g.copyWith(textAreas: []), ['geometry.textAreas']),
          (
            '제외 추가',
            (g) => g.copyWith(
              textAreas: [
                g.textAreas[0].copyWith(
                  region: g.textAreas[0].region.copyWith(
                    exclusions: [_circle(1), _circle(2), _circle(3)],
                  ),
                ),
                g.textAreas[1],
              ],
            ),
            ['geometry.textAreas[0].region.exclusions'],
          ),
          (
            '제외 삭제',
            (g) => g.copyWith(
              textAreas: [
                g.textAreas[0].copyWith(
                  region: g.textAreas[0].region.copyWith(exclusions: []),
                ),
                g.textAreas[1],
              ],
            ),
            ['geometry.textAreas[0].region.exclusions'],
          ),
          (
            '원에서 경로로 종류 변경',
            (g) => g.copyWith(outline: rectangularBoundary4By2()),
            ['geometry.outline'],
          ),
          (
            '허용오차로 지우면 안 되는 반지름 차이',
            (g) => g.copyWith(outline: _circle(30.000000000000004)),
            ['geometry.outline.radius'],
          ),
        ];
    for (final (condition, change, expected) in changes) {
      test('$condition 변경은 한 충돌에 정확한 필드 경로를 제공한다', () {
        final previous = _snapshot('g');
        final next = _snapshot('g', geometry: change(previous.geometry));
        _expectConflict(previous, next, expected);
      });
    }

    for (final (name, source, expected)
        in <(String, DesignSourceReference?, List<String>)>[
          ('출처 제거', null, ['source']),
          (
            '공용 원본 ID',
            DesignSourceReference(
              sourceDesignId: 'other',
              sourceRevision: 'r1',
            ),
            ['source.sourceDesignId'],
          ),
          (
            '출처 버전',
            DesignSourceReference(
              sourceDesignId: 'catalog',
              sourceRevision: 'r2',
            ),
            ['source.sourceRevision'],
          ),
          (
            '출처 버전 기록 제거',
            DesignSourceReference(sourceDesignId: 'catalog'),
            ['source.sourceRevision'],
          ),
        ]) {
      test('$name 변경도 같은 ID의 내용 충돌이다', () {
        _expectConflict(
          _snapshot('g'),
          _snapshot('g', source: source, withSource: source != null),
          expected,
        );
      });
    }
    test('출처 추가는 없던 하위 필드 대신 source를 가리킨다', () {
      _expectConflict(_snapshot('g', withSource: false), _snapshot('g'), [
        'source',
      ]);
    });
    test('실크기가 같은 전체 단위 환산도 같은 ID의 내용 충돌이다', () {
      final geometry = millimeterDesignWithAreaIds([]);
      _expectConflict(
        _snapshot('g', geometry: geometry),
        _snapshot('g', geometry: geometry.convertedTo(LengthUnit.inch)),
        ['geometry.coordinateSpace.lengthUnit', 'geometry.outline.radius'],
      );
    });
  });

  group('경로와 구간의 변경 위치', () {
    final previous = _snapshot(
      'g',
      geometry: _geometry().copyWith(outline: _triangle()),
    );
    for (final (name, boundary, expected)
        in <(String, ClosedBoundary, List<String>)>[
          (
            '시작점',
            PathBoundary(
              path: GeometryPath(
                start: Point2(x: -1, y: 0),
                segments: [
                  LineTo(end: Point2(x: 4, y: 0)),
                  LineTo(end: Point2(x: 4, y: 2)),
                  LineTo(end: Point2(x: -1, y: 0)),
                ],
              ),
            ),
            [
              'geometry.outline.path.start.x',
              'geometry.outline.path.segments[2].end.x',
            ],
          ),
          (
            '끝점',
            _triangle(firstX: 5),
            ['geometry.outline.path.segments[0].end.x'],
          ),
          (
            '선분에서 원호로',
            _triangle(bulge: 0.5),
            ['geometry.outline.path.segments[0]'],
          ),
          (
            '구간 추가',
            rectangularBoundary4By2(),
            ['geometry.outline.path.segments'],
          ),
          (
            '구간 순서',
            PathBoundary(
              path: GeometryPath(
                start: Point2(x: 0, y: 0),
                segments: [
                  LineTo(end: Point2(x: 4, y: 2)),
                  LineTo(end: Point2(x: 4, y: 0)),
                  LineTo(end: Point2(x: 0, y: 0)),
                ],
              ),
            ),
            [
              'geometry.outline.path.segments[0].end.y',
              'geometry.outline.path.segments[1].end.y',
            ],
          ),
          ('경로에서 원으로', _circle(30), ['geometry.outline']),
        ]) {
      test('$name 변경은 다음 구성에 존재하는 위치만 보고한다', () {
        _expectConflict(
          previous,
          _snapshot('g', geometry: _geometry().copyWith(outline: boundary)),
          expected,
        );
      });
    }
    test('같은 종류 원호의 bulge 변화는 bulge 필드를 보고한다', () {
      _expectConflict(
        _snapshot(
          'g',
          geometry: _geometry().copyWith(outline: _triangle(bulge: 0.5)),
        ),
        _snapshot(
          'g',
          geometry: _geometry().copyWith(outline: _triangle(bulge: 2)),
        ),
        ['geometry.outline.path.segments[0].bulge'],
      );
    });
  });

  test('관통·영역·제외 안의 경로 변경도 한 ID 진단으로 모은다', () {
    final oldRegion = TextRegion(outer: _triangle(), exclusions: [_triangle()]);
    final oldGeometry = _geometry().copyWith(
      cutouts: [CutoutDefinition(cutoutId: 'hole', boundary: _triangle())],
      textAreas: [
        TextAreaDefinition(areaId: 'title', label: '', region: oldRegion),
      ],
    );
    final nextGeometry = oldGeometry.copyWith(
      cutouts: [
        CutoutDefinition(cutoutId: 'hole', boundary: _triangle(firstX: 5)),
      ],
      textAreas: [
        TextAreaDefinition(
          areaId: 'title',
          label: '',
          region: TextRegion(
            outer: _triangle(firstX: 5),
            exclusions: [_triangle(firstX: 5)],
          ),
        ),
      ],
    );
    _expectConflict(
      _snapshot('g', geometry: oldGeometry),
      _snapshot('g', geometry: nextGeometry),
      [
        'geometry.cutouts[0].boundary.path.segments[0].end.x',
        'geometry.textAreas[0].region.outer.path.segments[0].end.x',
        'geometry.textAreas[0].region.exclusions[0].path.segments[0].end.x',
      ],
    );
  });

  test('빈 반환 목록도 호출자가 수정할 수 없다', () {
    final empty = _configuration([]);
    final conflicts = validateAppliedGeometryIdConsistency(
      previous: empty,
      next: empty,
    );
    expect(conflicts, isEmpty);
    expect(() => conflicts.clear(), throwsUnsupportedError);
  });
  group('ID 연결과 검사 범위', () {
    test('구성의 적용 목록 재정렬은 충돌이 아니며 입력을 정렬하지 않는다', () {
      final a = _snapshot('a');
      final b = _snapshot('b');
      final previous = _configuration([a, b]);
      final next = _configuration([b, a]);
      final previousJson = previous.toJson();
      final nextJson = next.toJson();
      expect(
        validateAppliedGeometryIdConsistency(previous: previous, next: next),
        isEmpty,
      );
      expect(previous.toJson(), previousJson);
      expect(next.toJson(), nextJson);
      expect(next.appliedGeometries.map((g) => g.appliedGeometryId), [
        'b',
        'a',
      ]);
    });
    for (final (name, previousIds, nextIds) in [
      ('새 ID 추가', ['a'], ['a', 'b']),
      ('ID 제거', ['a', 'b'], ['a']),
      ('공통 ID 없음', ['a'], ['b']),
      ('둘 다 빈 목록', <String>[], <String>[]),
    ]) {
      test('$name 자체는 충돌로 보지 않고 같은 내용도 자동 병합하지 않는다', () {
        final next = _configuration([for (final id in nextIds) _snapshot(id)]);
        expect(
          validateAppliedGeometryIdConsistency(
            previous: _configuration([
              for (final id in previousIds) _snapshot(id),
            ]),
            next: next,
          ),
          isEmpty,
        );
        expect(next.appliedGeometries.map((g) => g.appliedGeometryId), nextIds);
      });
    }
    test('제품 목록·원문·줄 방식만 달라도 검사 대상이 아니다', () {
      final applied = _snapshot(
        'g',
        geometry: millimeterDesignWithAreaIds(['title']),
      );
      ProductInput product(String id, String text, LineBreakInput lineBreak) =>
          ProductInput(
            productId: id,
            appliedGeometryId: 'g',
            textInputs: [
              TextAreaInput(
                areaId: 'title',
                sourceText: text,
                lineBreak: lineBreak,
              ),
            ],
          );
      final a = product('a', ' PUMP  A ', SpecifiedLineBreak([' PUMP  A ']));
      final b = product(
        'b',
        '밸브 e\u0301 😀',
        SpecifiedLineBreak(['밸브 ', 'e\u0301 😀']),
      );
      final previous = _configuration([applied], products: [a, b]);
      final next = _configuration(
        [applied],
        products: [b, product('a', 'NEW', const AutomaticLineBreak())],
      );
      expect(
        validateAppliedGeometryIdConsistency(previous: previous, next: next),
        isEmpty,
      );
      expect(previous.products[0].textInputs[0].sourceText, ' PUMP  A ');
    });
    test('독립 충돌마다 실제 이전/다음 선언 인덱스를 제공하고 두 구성은 각각 유효하다', () {
      final previous = _configuration([
        _snapshot('a'),
        _snapshot('b'),
        _snapshot('removed'),
      ]);
      final next = _configuration([
        _snapshot('new'),
        _snapshot('b', withSource: false),
        _snapshot('a', geometry: _geometry().copyWith(outline: _circle(31))),
      ]);
      expect(
        validateProductDesignConfiguration(
          appliedGeometries: previous.appliedGeometries,
          products: previous.products,
        ),
        isEmpty,
      );
      expect(
        validateProductDesignConfiguration(
          appliedGeometries: next.appliedGeometries,
          products: next.products,
        ),
        isEmpty,
      );
      final conflicts = validateAppliedGeometryIdConsistency(
        previous: previous,
        next: next,
      );
      expect(conflicts, hasLength(2));
      final byId = {
        for (final conflict in conflicts) conflict.appliedGeometryId: conflict,
      };
      final a = byId['a']!;
      final b = byId['b']!;
      expect(
        (a.previousIndex, a.nextIndex, a.fieldPath),
        (0, 2, 'next.appliedGeometries[2]'),
      );
      expect(a.changedFieldPaths, ['geometry.outline.radius']);
      expect(
        (b.previousIndex, b.nextIndex, b.fieldPath),
        (1, 1, 'next.appliedGeometries[1]'),
      );
      expect(b.changedFieldPaths, ['source']);
      expect(
        conflicts.map((c) => c.code),
        everyElement(AppliedGeometryIdConflictCode.snapshotContentConflict),
      );
      expect(() => conflicts.clear(), throwsUnsupportedError);
      expect(() => a.changedFieldPaths.add('source'), throwsUnsupportedError);
      expect(previous.appliedGeometries.first.geometry.outline, _circle(30));
    });
  });
}

CircleBoundary _circle(double radius) =>
    CircleBoundary(center: Point2(x: 0, y: 0), radius: radius);
DesignGeometry _geometry() {
  final region = TextRegion(
    outer: _circle(10),
    exclusions: [_circle(1), _circle(2)],
  );
  return DesignGeometry(
    coordinateSpace: DrawingCoordinateSpace(lengthUnit: LengthUnit.millimeter),
    outline: _circle(30),
    cutouts: [
      CutoutDefinition(cutoutId: 'hole-a', boundary: _circle(1)),
      CutoutDefinition(cutoutId: 'hole-b', boundary: _circle(1)),
    ],
    textAreas: [
      TextAreaDefinition(areaId: 'title', label: '', region: region),
      TextAreaDefinition(areaId: 'code', label: '', region: region),
    ],
  );
}

AppliedDesignGeometry _snapshot(
  String id, {
  DesignGeometry? geometry,
  DesignSourceReference? source,
  bool withSource = true,
}) => AppliedDesignGeometry(
  appliedGeometryId: id,
  geometry: geometry ?? _geometry(),
  source: withSource
      ? (source ??
            DesignSourceReference(
              sourceDesignId: 'catalog',
              sourceRevision: 'r1',
            ))
      : null,
);
ProductDesignConfiguration _configuration(
  List<AppliedDesignGeometry> values, {
  List<ProductInput> products = const [],
}) => ProductDesignConfiguration(appliedGeometries: values, products: products);
PathBoundary _triangle({double firstX = 4, double? bulge}) => PathBoundary(
  path: GeometryPath(
    start: Point2(x: 0, y: 0),
    segments: [
      if (bulge == null)
        LineTo(end: Point2(x: firstX, y: 0))
      else
        ArcTo(
          end: Point2(x: firstX, y: 0),
          bulge: bulge,
        ),
      LineTo(end: Point2(x: 4, y: 2)),
      LineTo(end: Point2(x: 0, y: 0)),
    ],
  ),
);
void _expectConflict(
  AppliedDesignGeometry previous,
  AppliedDesignGeometry next,
  List<String> expected,
) {
  final previousJson = previous.toJson();
  final nextJson = next.toJson();
  final conflicts = validateAppliedGeometryIdConsistency(
    previous: _configuration([previous]),
    next: _configuration([next]),
  );
  expect(conflicts, hasLength(1));
  final conflict = conflicts.single;
  expect(conflict.code, AppliedGeometryIdConflictCode.snapshotContentConflict);
  expect(conflict.appliedGeometryId, 'g');
  expect(conflict.previousIndex, 0);
  expect(conflict.nextIndex, 0);
  expect(conflict.fieldPath, 'next.appliedGeometries[0]');
  expect(conflict.changedFieldPaths, unorderedEquals(expected));
  expect(previous.toJson(), previousJson);
  expect(next.toJson(), nextJson);
}
