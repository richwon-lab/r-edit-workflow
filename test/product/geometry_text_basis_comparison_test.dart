import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/geometry_text_basis_examples.dart';

void main() {
  late ProductGeometryTextBasis basis;
  setUp(
    () => basis = extractProductGeometryTextBasis(
      configuration: twoAreaBasisConfiguration(),
      productId: 'target',
    ),
  );

  AreaGeometryTextBasis changedArea({
    TextAreaInput? input,
    TextRegion? region,
  }) => AreaGeometryTextBasis(
    definition: TextAreaDefinition(
      areaId: 'a',
      label: '',
      region: region ?? basis.areas.first.region,
    ),
    input: input ?? basis.areas.first.input,
  );
  List<(GeometryTextBasisDifferenceCode, String?, String?, String?)> locations(
    List<GeometryTextBasisDifference> differences,
  ) => [
    for (final d in differences)
      (
        d.code,
        d.position.previousFieldPath,
        d.position.nextFieldPath,
        d.areaId,
      ),
  ];

  test('다른 제품이면 제품 불일치만 반환하고 형상 차이를 같은 제품으로 해석하지 않는다', () {
    final result = compareProductGeometryTextBasis(
      previous: basis,
      next: rebuildGeometryTextBasis(
        basis,
        productId: 'other',
        outline: CircleBoundary(center: Point2(x: 0, y: 0), radius: 40),
      ),
    );
    expect(locations(result), [
      (
        GeometryTextBasisDifferenceCode.productMismatch,
        'productId',
        'productId',
        null,
      ),
    ]);
    expect(result.single.previousProductId, 'target');
    expect(result.single.nextProductId, 'other');
  });

  final cases =
      <
        (
          String,
          ProductGeometryTextBasis Function(ProductGeometryTextBasis),
          String,
        )
      >[
        (
          '길이 단위',
          (b) => rebuildGeometryTextBasis(
            b,
            coordinateSpace: DrawingCoordinateSpace(
              lengthUnit: LengthUnit.inch,
            ),
          ),
          'coordinateSpace.lengthUnit',
        ),
        (
          '외곽 미세 수치',
          (b) => rebuildGeometryTextBasis(
            b,
            outline: CircleBoundary(
              center: Point2(x: 0, y: 0),
              radius: 30.000000000001,
            ),
          ),
          'outline.radius',
        ),
      ];
  for (final (name, change, path) in cases) {
    test('$name 변경은 환산·반올림하지 않고 실제 필드 차이로 반환한다', () {
      expect(
        locations(
          compareProductGeometryTextBasis(previous: basis, next: change(basis)),
        ),
        [(GeometryTextBasisDifferenceCode.valueChanged, path, path, null)],
      );
    });
  }

  test('영역 기하 변경은 재정렬 후에도 같은 영역의 이전/다음 실제 위치를 가리킨다', () {
    final updated = changedArea(
      region: TextRegion(
        outer: CircleBoundary(center: Point2(x: 0, y: 0), radius: 11),
        exclusions: [],
      ),
    );
    final next = rebuildGeometryTextBasis(
      basis,
      areas: [basis.areas[1], updated],
    );
    expect(
      locations(compareProductGeometryTextBasis(previous: basis, next: next)),
      [
        (
          GeometryTextBasisDifferenceCode.valueChanged,
          'areas[0].region.outer.radius',
          'areas[1].region.outer.radius',
          'a',
        ),
      ],
    );
  });

  test('원문 변경을 실제 문구 필드로 구분하며 진단 문자열에 원문을 담지 않는다', () {
    final input = TextAreaInput(
      areaId: 'a',
      sourceText: 'PRIVATE NEW TEXT',
      lineBreak: SpecifiedLineBreak(['PRIVATE NEW TEXT']),
    );
    final result = compareProductGeometryTextBasis(
      previous: basis,
      next: rebuildGeometryTextBasis(
        basis,
        areas: [
          changedArea(input: input),
          basis.areas[1],
        ],
      ),
    );
    expect(
      locations(result),
      unorderedEquals([
        (
          GeometryTextBasisDifferenceCode.valueChanged,
          'areas[0].input.sourceText',
          'areas[0].input.sourceText',
          'a',
        ),
        (
          GeometryTextBasisDifferenceCode.valueChanged,
          'areas[0].input.lineBreak.lines',
          'areas[0].input.lineBreak.lines',
          'a',
        ),
      ]),
    );
    expect(result.join(), isNot(contains('PRIVATE NEW TEXT')));
    expect(result.join(), isNot(contains('PUMP')));
  });

  test('직접 지정 한 줄과 자동 방식은 요소 전체의 종류 변경으로 구분한다', () {
    final input = basis.areas[0].input.copyWith(
      lineBreak: const AutomaticLineBreak(),
    );
    final result = compareProductGeometryTextBasis(
      previous: basis,
      next: rebuildGeometryTextBasis(
        basis,
        areas: [
          changedArea(input: input),
          basis.areas[1],
        ],
      ),
    );
    expect(locations(result), [
      (
        GeometryTextBasisDifferenceCode.kindChanged,
        'areas[0].input.lineBreak',
        'areas[0].input.lineBreak',
        'a',
      ),
    ]);
    final kinds = result.single.position as ChangedBasisKinds;
    expect(kinds.previousKind, GeometryTextBasisKind.specifiedLineBreak);
    expect(kinds.nextKind, GeometryTextBasisKind.automaticLineBreak);
  });

  test('같은 원문의 직접 지정 줄 구성 변경만도 감지한다', () {
    final input = basis.areas[0].input.copyWith(
      lineBreak: SpecifiedLineBreak([' A ', 'e\u0301🙂  ']),
    );
    expect(
      locations(
        compareProductGeometryTextBasis(
          previous: basis,
          next: rebuildGeometryTextBasis(
            basis,
            areas: [
              changedArea(input: input),
              basis.areas[1],
            ],
          ),
        ),
      ),
      [
        (
          GeometryTextBasisDifferenceCode.valueChanged,
          'areas[0].input.lineBreak.lines',
          'areas[0].input.lineBreak.lines',
          'a',
        ),
      ],
    );
  });

  test('영역 추가·삭제는 한쪽에 존재하는 항목 전체 위치만 제공한다', () {
    final added = AreaGeometryTextBasis(
      definition: TextAreaDefinition(
        areaId: 'c',
        label: '',
        region: basis.areas[0].region,
      ),
      input: TextAreaInput(
        areaId: 'c',
        sourceText: 'c',
        lineBreak: const AutomaticLineBreak(),
      ),
    );
    final result = compareProductGeometryTextBasis(
      previous: basis,
      next: rebuildGeometryTextBasis(basis, areas: [added, basis.areas[1]]),
    );
    expect(
      locations(result),
      unorderedEquals([
        (GeometryTextBasisDifferenceCode.elementRemoved, 'areas[0]', null, 'a'),
        (GeometryTextBasisDifferenceCode.elementAdded, null, 'areas[0]', 'c'),
      ]),
    );
    expect(() => result.clear(), throwsUnsupportedError);
    expect(basis.areas.map((a) => a.areaId), ['a', 'b']);
  });

  test('원/경로 종류 변경은 존재하지 않는 중심·반지름 하위 위치를 보고하지 않는다', () {
    final path = GeometryPath(
      start: Point2(x: 0, y: 0),
      segments: [
        LineTo(end: Point2(x: 2, y: 0)),
        LineTo(end: Point2(x: 2, y: 2)),
        LineTo(end: Point2(x: 0, y: 0)),
      ],
    );
    final result = compareProductGeometryTextBasis(
      previous: basis,
      next: rebuildGeometryTextBasis(basis, outline: PathBoundary(path: path)),
    );
    expect(locations(result), [
      (GeometryTextBasisDifferenceCode.kindChanged, 'outline', 'outline', null),
    ]);
    expect(
      (result.single.position as ChangedBasisKinds).nextKind,
      GeometryTextBasisKind.pathBoundary,
    );
  });

  test('경로 구간 순서와 선분/원호 종류를 보존해 비교한다', () {
    final start = Point2(x: 0, y: 0);
    final end1 = Point2(x: 2, y: 0);
    final end2 = Point2(x: 2, y: 2);
    final previous = rebuildGeometryTextBasis(
      basis,
      outline: PathBoundary(
        path: GeometryPath(
          start: start,
          segments: [
            LineTo(end: end1),
            LineTo(end: end2),
            LineTo(end: start),
          ],
        ),
      ),
    );
    final reordered = rebuildGeometryTextBasis(
      basis,
      outline: PathBoundary(
        path: GeometryPath(
          start: start,
          segments: [
            LineTo(end: end2),
            LineTo(end: end1),
            LineTo(end: start),
          ],
        ),
      ),
    );
    expect(
      locations(
        compareProductGeometryTextBasis(previous: previous, next: reordered),
      ),
      unorderedEquals([
        (
          GeometryTextBasisDifferenceCode.valueChanged,
          'outline.path.segments[0].end.y',
          'outline.path.segments[0].end.y',
          null,
        ),
        (
          GeometryTextBasisDifferenceCode.valueChanged,
          'outline.path.segments[1].end.y',
          'outline.path.segments[1].end.y',
          null,
        ),
      ]),
    );
    final arc = rebuildGeometryTextBasis(
      basis,
      outline: PathBoundary(
        path: GeometryPath(
          start: start,
          segments: [
            ArcTo(end: end1, bulge: 1),
            LineTo(end: end2),
            LineTo(end: start),
          ],
        ),
      ),
    );
    expect(
      locations(compareProductGeometryTextBasis(previous: previous, next: arc)),
      [
        (
          GeometryTextBasisDifferenceCode.kindChanged,
          'outline.path.segments[0]',
          'outline.path.segments[0]',
          null,
        ),
      ],
    );
  });

  test('관통 경계의 내용·순서·추가/삭제를 실제 인덱스로 구분한다', () {
    final a = CutoutDefinition(
      cutoutId: 'x',
      boundary: CircleBoundary(center: Point2(x: 0, y: 0), radius: 1),
    );
    final b = CutoutDefinition(
      cutoutId: 'y',
      boundary: CircleBoundary(center: Point2(x: 0, y: 0), radius: 1),
    );
    final previous = rebuildGeometryTextBasis(basis, cutouts: [a, b]);
    expect(
      locations(
        compareProductGeometryTextBasis(
          previous: previous,
          next: rebuildGeometryTextBasis(basis, cutouts: [b, a]),
        ),
      ),
      unorderedEquals([
        (
          GeometryTextBasisDifferenceCode.valueChanged,
          'cutouts[0].cutoutId',
          'cutouts[0].cutoutId',
          null,
        ),
        (
          GeometryTextBasisDifferenceCode.valueChanged,
          'cutouts[1].cutoutId',
          'cutouts[1].cutoutId',
          null,
        ),
      ]),
    );
    expect(
      locations(
        compareProductGeometryTextBasis(
          previous: previous,
          next: rebuildGeometryTextBasis(basis, cutouts: [a]),
        ),
      ),
      [
        (
          GeometryTextBasisDifferenceCode.elementRemoved,
          'cutouts[1]',
          null,
          null,
        ),
      ],
    );
    expect(
      locations(
        compareProductGeometryTextBasis(previous: basis, next: previous),
      ),
      [
        (
          GeometryTextBasisDifferenceCode.elementAdded,
          null,
          'cutouts[0]',
          null,
        ),
        (
          GeometryTextBasisDifferenceCode.elementAdded,
          null,
          'cutouts[1]',
          null,
        ),
      ],
    );
    expect(
      locations(
        compareProductGeometryTextBasis(
          previous: previous,
          next: rebuildGeometryTextBasis(
            basis,
            cutouts: [
              a,
              CutoutDefinition(
                cutoutId: 'y',
                boundary: CircleBoundary(center: Point2(x: 0, y: 0), radius: 2),
              ),
            ],
          ),
        ),
      ),
      [
        (
          GeometryTextBasisDifferenceCode.valueChanged,
          'cutouts[1].boundary.radius',
          'cutouts[1].boundary.radius',
          null,
        ),
      ],
    );
  });

  test('제외 경계는 순서와 추가·삭제를 무시하지 않는다', () {
    final a = CircleBoundary(center: Point2(x: 0, y: 0), radius: 1);
    final b = CircleBoundary(center: Point2(x: 0, y: 0), radius: 2);
    ProductGeometryTextBasis withExclusions(List<ClosedBoundary> exclusions) =>
        rebuildGeometryTextBasis(
          basis,
          areas: [
            changedArea(
              region: TextRegion(
                outer: basis.areas[0].region.outer,
                exclusions: exclusions,
              ),
            ),
            basis.areas[1],
          ],
        );
    expect(
      locations(
        compareProductGeometryTextBasis(
          previous: withExclusions([a, b]),
          next: withExclusions([b, a]),
        ),
      ),
      unorderedEquals([
        (
          GeometryTextBasisDifferenceCode.valueChanged,
          'areas[0].region.exclusions[0].radius',
          'areas[0].region.exclusions[0].radius',
          'a',
        ),
        (
          GeometryTextBasisDifferenceCode.valueChanged,
          'areas[0].region.exclusions[1].radius',
          'areas[0].region.exclusions[1].radius',
          'a',
        ),
      ]),
    );
    expect(
      locations(
        compareProductGeometryTextBasis(
          previous: withExclusions([a]),
          next: withExclusions([a, b]),
        ),
      ),
      [
        (
          GeometryTextBasisDifferenceCode.elementAdded,
          null,
          'areas[0].region.exclusions[1]',
          'a',
        ),
      ],
    );
  });
}
