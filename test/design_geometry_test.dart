import 'dart:convert';

import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

Point2 p(double x, double y) => Point2(x: x, y: y);
CircleBoundary circle([double radius = 1]) =>
    CircleBoundary(center: p(2, 2), radius: radius);
PathBoundary polygon(List<Point2> vertices) => PathBoundary(
  path: GeometryPath(
    start: vertices.first,
    segments: [for (final end in vertices.skip(1)) LineTo(end: end)],
  ),
);
PathBoundary rectangle() =>
    polygon([p(0, 0), p(4, 0), p(4, 2), p(0, 2), p(0, 0)]);
PathBoundary slot() => PathBoundary(
  path: GeometryPath(
    start: p(1, 1),
    segments: [
      LineTo(end: p(3, 1)),
      ArcTo(end: p(3, 3), bulge: 1),
      LineTo(end: p(1, 3)),
      ArcTo(end: p(1, 1), bulge: 1),
    ],
  ),
);
TextAreaDefinition area(
  String id, {
  String label = '',
  ClosedBoundary? outer,
  List<ClosedBoundary>? exclusions,
}) => TextAreaDefinition(
  areaId: id,
  label: label,
  region: TextRegion(outer: outer ?? circle(10), exclusions: exclusions ?? []),
);
DesignGeometry design({
  List<CutoutDefinition>? cutouts,
  List<TextAreaDefinition>? areas,
}) => DesignGeometry(
  coordinateSpace: DrawingCoordinateSpace(lengthUnit: LengthUnit.inch),
  outline: polygon([
    p(-1, -1),
    p(8, -1),
    p(9, 3),
    p(6, 8),
    p(-1, 5),
    p(-1, -1),
  ]),
  cutouts: cutouts ?? [],
  textAreas: areas ?? [],
);
TextAreaInput input(
  String id, {
  String text = ' PUMP  A ',
  bool specified = false,
}) => TextAreaInput(
  areaId: id,
  sourceText: text,
  lineBreak: specified
      ? SpecifiedLineBreak([text])
      : const AutomaticLineBreak(),
);
Object? roundTrip(Object? json) => jsonDecode(jsonEncode(json));
Matcher designError(DesignErrorCode code, String path) => throwsA(
  isA<DesignValidationException>()
      .having((e) => e.code, 'code', code)
      .having((e) => e.fieldPath, 'path', path),
);

void main() {
  test('비정형 외곽과 원형·사각형·장공 구멍을 같은 경계 타입으로 구성하고 왕복한다', () {
    final cutouts = [
      CutoutDefinition(cutoutId: 'circle', boundary: circle()),
      CutoutDefinition(cutoutId: 'rectangle', boundary: rectangle()),
      CutoutDefinition(cutoutId: 'slot', boundary: slot()),
    ];
    final original = design(
      cutouts: cutouts,
      areas: [
        area('rect', outer: rectangle()),
        area('round', outer: circle(10), exclusions: [slot()]),
      ],
    );
    final restored = DesignGeometry.fromJson(roundTrip(original.toJson()));
    expect(restored, original);
    expect(restored.hashCode, original.hashCode);
    expect(restored.cutouts.map((c) => c.cutoutId), [
      'circle',
      'rectangle',
      'slot',
    ]);
    expect(restored.textAreas[1].region.exclusions.single, slot());
    expect(
      original.toJson().keys,
      unorderedEquals(['coordinateSpace', 'outline', 'cutouts', 'textAreas']),
    );
  });
  test('영역·홀 겹침과 영역 밖 제외 경계를 보정하지 않는다', () {
    final boundary = circle();
    final outside = CircleBoundary(center: p(-100, -100), radius: 2);
    final original = design(
      cutouts: [CutoutDefinition(cutoutId: 'h', boundary: boundary)],
      areas: [
        area('a', outer: boundary, exclusions: [outside]),
        area('b', outer: boundary),
      ],
    );
    expect(
      original.textAreas.first.region.outer,
      original.cutouts.single.boundary,
    );
    expect(original.textAreas.first.region.exclusions, [outside]);
    final without = original.copyWith(cutouts: []);
    expect(without.textAreas, original.textAreas);
    expect(without.textAreas.first.region.exclusions, [outside]);
  });
  test('빈/중복 label·공백 ID·Unicode 문자열은 있는 그대로 보존한다', () {
    for (final label in ['', '  본문 e\u0301 👩‍🔧  ']) {
      final original = design(
        cutouts: [CutoutDefinition(cutoutId: ' a ', boundary: circle())],
        areas: [
          area(' a ', label: label),
          area('b', label: label),
        ],
      );
      final restored = DesignGeometry.fromJson(roundTrip(original.toJson()));
      expect(restored.textAreas[0].label, label);
      expect(restored.textAreas[0].areaId, ' a ');
      expect(restored.cutouts.single.cutoutId, ' a ');
      expect(
        validateTextAreaInputs(
          design: original,
          inputs: [input('b'), input(' a ')],
        ),
        isEmpty,
      );
    }
  });
  test('각 소유 범위의 중복 ID는 생성·copyWith·JSON에서 거부한다', () {
    final h = CutoutDefinition(cutoutId: 'same', boundary: circle());
    final a = area('same');
    final original = design(cutouts: [h], areas: [a]);
    for (final run in <void Function()>[
      () => design(
        cutouts: [
          h,
          h.copyWith(boundary: slot()),
        ],
      ),
      () => original.copyWith(cutouts: [h, h]),
      () => DesignGeometry.fromJson({
        ...original.toJson(),
        'cutouts': [h.toJson(), h.toJson()],
      }),
    ]) {
      expect(
        run,
        designError(DesignErrorCode.duplicateCutoutId, 'cutouts[1].cutoutId'),
      );
    }
    for (final run in <void Function()>[
      () => design(
        areas: [
          a,
          a.copyWith(label: '다른 이름'),
        ],
      ),
      () => original.copyWith(textAreas: [a, a]),
      () => DesignGeometry.fromJson({
        ...original.toJson(),
        'textAreas': [a.toJson(), a.toJson()],
      }),
    ]) {
      expect(
        run,
        designError(DesignErrorCode.duplicateAreaId, 'textAreas[1].areaId'),
      );
    }
    try {
      original.copyWith(textAreas: [a, a]);
      fail('중복 허용');
    } on DesignValidationException catch (e) {
      final details = e.issue.details as DesignDuplicateDetails;
      expect(details.firstIndex, 0);
      expect(details.duplicateIndex, 1);
      expect(details.identifier, 'same');
      expect(
        e.toString(),
        allOf(
          contains('same'),
          contains('firstIndex=0'),
          contains(e.code.description),
        ),
      );
    }
  });
  test('빈 ID는 직접 생성·수정·중첩 JSON에서 거부하고 입력과 같은 규약을 사용한다', () {
    expect(
      () => CutoutDefinition(cutoutId: '', boundary: circle()),
      designError(DesignErrorCode.emptyCutoutId, 'cutoutId'),
    );
    expect(() => area(''), designError(DesignErrorCode.emptyAreaId, 'areaId'));
    expect(
      () => area('a').copyWith(areaId: ''),
      designError(DesignErrorCode.emptyAreaId, 'areaId'),
    );
    expect(
      () => CutoutDefinition(
        cutoutId: 'h',
        boundary: circle(),
      ).copyWith(cutoutId: ''),
      designError(DesignErrorCode.emptyCutoutId, 'cutoutId'),
    );
    expect(
      () => DesignGeometry.fromJson({
        ...design().toJson(),
        'textAreas': [
          {'areaId': '', 'label': '', 'region': area('a').region.toJson()},
        ],
      }),
      designError(DesignErrorCode.emptyAreaId, 'textAreas[0].areaId'),
    );
    expect(
      () => input(''),
      throwsA(
        isA<TextInputValidationException>().having(
          (e) => e.code,
          'code',
          TextInputErrorCode.emptyAreaId,
        ),
      ),
    );
    expect(
      validateTextAreaInputs(
        design: design(areas: [area('   ')]),
        inputs: [input('   ')],
      ),
      isEmpty,
    );
  });
  test('구성·영역 copyWith의 수정 전 값을 보존하고 중첩 목록도 방어 복사한다', () {
    final holes = [CutoutDefinition(cutoutId: 'h', boundary: circle())];
    final excluded = <ClosedBoundary>[slot()];
    final areas = [area('a', exclusions: excluded)];
    final original = design(cutouts: holes, areas: areas);
    holes.clear();
    excluded.clear();
    areas.clear();
    expect(original.cutouts, hasLength(1));
    expect(original.textAreas.single.region.exclusions, [slot()]);
    expect(() => original.cutouts.clear(), throwsUnsupportedError);
    expect(() => original.textAreas.clear(), throwsUnsupportedError);
    expect(
      () => original.textAreas.single.region.exclusions.clear(),
      throwsUnsupportedError,
    );
    final replacements = <ClosedBoundary>[rectangle()];
    final changed = original.textAreas.single.copyWith.region(
      exclusions: replacements,
    );
    replacements.clear();
    expect(changed.region.exclusions, [rectangle()]);
    expect(original.textAreas.single.region.exclusions, [slot()]);
    final nextAreas = [changed];
    final next = original.copyWith(textAreas: nextAreas);
    nextAreas.clear();
    expect(next.textAreas.single, changed);
    expect(original.textAreas.single.region.exclusions, [slot()]);
    expect(next.coordinateSpace, original.coordinateSpace);
  });
  test('반환 JSON과 복원에 사용한 목록/Map의 외부 변경으로 도안을 바꿀 수 없다', () {
    final original = design(
      cutouts: [CutoutDefinition(cutoutId: 'h', boundary: circle())],
      areas: [
        area('a', exclusions: [circle()]),
      ],
    );
    final json = original.toJson();
    final restored = DesignGeometry.fromJson(json);
    (json['coordinateSpace'] as Map)['lengthUnit'] = 'unknown';
    ((json['outline'] as Map)['path'] as Map)['start'] = {'x': 999, 'y': 999};
    final areas = json['textAreas'] as List;
    final first = areas.single as Map;
    first['label'] = 'changed';
    final region = first['region'] as Map;
    (region['outer'] as Map)['radius'] = 999;
    (region['exclusions'] as List).clear();
    areas.clear();
    final cutouts = json['cutouts'] as List;
    (cutouts.single as Map)['cutoutId'] = 'changed';
    cutouts.clear();
    expect(restored, original);
    expect(DesignGeometry.fromJson(roundTrip(original.toJson())), original);
  });
  test('단위 환산은 외곽·모든 구멍·영역 외부/제외 경계를 함께 바꾸고 식별 문자열을 보존한다', () {
    final original = design(
      cutouts: [
        CutoutDefinition(cutoutId: 'h1', boundary: circle()),
        CutoutDefinition(cutoutId: 'h2', boundary: rectangle()),
        CutoutDefinition(cutoutId: 'h3', boundary: slot()),
      ],
      areas: [
        area(
          'a',
          label: '  e\u0301  ',
          outer: rectangle(),
          exclusions: [circle(), slot()],
        ),
        area('b', outer: circle(10)),
      ],
    );
    final mm = original.convertedTo(LengthUnit.millimeter);
    expect(mm.coordinateSpace.lengthUnit, LengthUnit.millimeter);
    expect((mm.outline as PathBoundary).path.start, p(-25.4, -25.4));
    expect((mm.cutouts[0].boundary as CircleBoundary).center, p(50.8, 50.8));
    expect((mm.cutouts[0].boundary as CircleBoundary).radius, 25.4);
    expect(
      (mm.cutouts[1].boundary as PathBoundary).path.segments.first.end,
      p(101.6, 0),
    );
    final slotPath = (mm.cutouts[2].boundary as PathBoundary).path;
    expect(slotPath.start, p(25.4, 25.4));
    expect((slotPath.segments[1] as ArcTo).bulge, 1);
    expect(
      (mm.textAreas[0].region.outer as PathBoundary).path.segments[1].end,
      p(101.6, 50.8),
    );
    expect(
      (mm.textAreas[0].region.exclusions[0] as CircleBoundary).radius,
      25.4,
    );
    expect(
      (mm.textAreas[0].region.exclusions[1] as PathBoundary).path.start,
      p(25.4, 25.4),
    );
    expect((mm.textAreas[1].region.outer as CircleBoundary).radius, 254);
    expect(mm.cutouts.map((h) => h.cutoutId), ['h1', 'h2', 'h3']);
    expect(mm.textAreas[0].label, '  e\u0301  ');
    expect(mm.textAreas[0].areaId, 'a');
    expect(original.coordinateSpace.lengthUnit, LengthUnit.inch);
    expect((original.cutouts[0].boundary as CircleBoundary).radius, 1);
    expect(DesignGeometry.fromJson(roundTrip(mm.toJson())), mm);
  });
  test('환산 실패의 하위 기하 원인과 위치를 보존하고 원래 값은 유지한다', () {
    final huge = CircleBoundary(center: p(0, 0), radius: double.maxFinite);
    final original = design(
      areas: [
        area('a', exclusions: [huge]),
      ],
    );
    try {
      original.convertedTo(LengthUnit.millimeter);
      fail('수치 실패 누락');
    } on GeometryValidationException catch (e) {
      expect(e.fieldPath, 'textAreas[0].region.exclusions[0].radius');
      expect(e.code, GeometryErrorCode.numericRepresentationFailure);
      expect(e.diagnostic.operation, 'convertLength:inch->millimeter');
      expect(
        (e.diagnostic.details as GeometryNumberDetails).value,
        double.maxFinite,
      );
    }
    expect(original.textAreas.single.region.exclusions.single, huge);
  });
  test('입력 순서가 달라도 ID로 연결하고 원문·직접 지정 한 줄·공백을 보존한다', () {
    final current = design(areas: [area('a'), area('b')]);
    final first = input('b', text: '  PUMP e\u0301 👩‍🔧  ', specified: true);
    final second = input('a', text: '   ');
    final inputs = [first, second];
    expect(validateTextAreaInputs(design: current, inputs: inputs), isEmpty);
    expect(identical(inputs.first, first), isTrue);
    expect(inputs.map((i) => i.areaId), ['b', 'a']);
    expect((first.lineBreak as SpecifiedLineBreak).lines, [
      '  PUMP e\u0301 👩‍🔧  ',
    ]);
    expect(second.sourceText, '   ');
    expect(
      () => input('a', text: ''),
      throwsA(
        isA<TextInputValidationException>().having(
          (e) => e.code,
          'code',
          TextInputErrorCode.emptySourceText,
        ),
      ),
    );
  });
  test('중복 입력·정의 없는 입력·입력 누락을 독립 진단한다', () {
    final current = design(areas: [area('a'), area('b')]);
    final inputs = [input('a'), input('a', specified: true), input('unknown')];
    final issues = validateTextAreaInputs(design: current, inputs: inputs);
    expect(issues.map((i) => i.code), [
      DesignErrorCode.duplicateInputAreaId,
      DesignErrorCode.unknownInputAreaId,
      DesignErrorCode.missingAreaInput,
    ]);
    expect(issues.map((i) => i.fieldPath), [
      'inputs[1].areaId',
      'inputs[2].areaId',
      'textAreas[1].areaId',
    ]);
    final duplicate = issues[0].details as DesignDuplicateDetails;
    expect(duplicate.firstIndex, 0);
    expect(duplicate.duplicateIndex, 1);
    expect(
      (issues[1].details as DesignIdentifierDetails).identifier,
      'unknown',
    );
    expect((issues[2].details as DesignIdentifierDetails).identifier, 'b');
    expect(() => issues.clear(), throwsUnsupportedError);
    expect(inputs, hasLength(3));
    expect(
      issues[1].toString(),
      allOf(
        contains('unknown'),
        contains('inputs[2].areaId'),
        contains(DesignErrorCode.unknownInputAreaId.description),
      ),
    );
  });
  test('영역 없는 정의와 입력 0건은 표현하되 알 수 없는 입력과 누락은 숨기지 않는다', () {
    expect(validateTextAreaInputs(design: design(), inputs: []), isEmpty);
    expect(
      validateTextAreaInputs(
        design: design(),
        inputs: [input('x')],
      ).single.code,
      DesignErrorCode.unknownInputAreaId,
    );
    expect(
      validateTextAreaInputs(
        design: design(areas: [area('x')]),
        inputs: [],
      ).single.code,
      DesignErrorCode.missingAreaInput,
    );
    expect(
      DesignGeometry.fromJson(roundTrip(design().toJson())).textAreas,
      isEmpty,
    );
  });
  final cases = <(String, Map<String, Object?>, Object Function(Object?))>[
    ('도안', design().toJson(), DesignGeometry.fromJson),
    (
      '관통',
      CutoutDefinition(cutoutId: 'h', boundary: circle()).toJson(),
      CutoutDefinition.fromJson,
    ),
    ('영역', area('a').toJson(), TextAreaDefinition.fromJson),
    ('면', area('a').region.toJson(), TextRegion.fromJson),
  ];
  for (final (name, json, parse) in cases) {
    test('$name JSON 필수 필드/추가 필드/자체 객체 타입을 검사한다', () {
      for (final key in json.keys) {
        final missing = Map<String, Object?>.of(json)..remove(key);
        expect(
          () => parse(missing),
          designError(DesignErrorCode.missingField, key),
        );
      }
      expect(
        () => parse({...json, 'extra': true}),
        designError(DesignErrorCode.unexpectedField, 'extra'),
      );
      expect(() => parse([]), designError(DesignErrorCode.invalidType, r'$'));
    });
  }
  test('중첩 업무 오류의 ID·타입 상세와 하위 기하 진단을 잃지 않는다', () {
    try {
      TextAreaDefinition.fromJson({
        'areaId': 'a',
        'label': null,
        'region': area('a').region.toJson(),
      });
      fail('잘못된 타입 허용');
    } on DesignValidationException catch (e) {
      final details = e.issue.details as DesignTypeDetails;
      expect(details.expectedType, 'String');
      expect(details.actualType, 'Null');
      expect(
        identical(e.prefixed('textAreas[0]').issue.details, details),
        isTrue,
      );
    }
    expect(
      () => DesignGeometry.fromJson({...design().toJson(), 'cutouts': null}),
      designError(DesignErrorCode.invalidType, 'cutouts'),
    );
    expect(
      () => DesignGeometry.fromJson({...design().toJson(), 'textAreas': false}),
      designError(DesignErrorCode.invalidType, 'textAreas'),
    );
    final original = design(areas: [area('a')]);
    expect(
      () => DesignGeometry.fromJson({
        ...original.toJson(),
        'textAreas': [
          {'areaId': 'a', 'label': null, 'region': area('a').region.toJson()},
        ],
      }),
      designError(DesignErrorCode.invalidType, 'textAreas[0].label'),
    );
    expect(
      () => DesignGeometry.fromJson({
        ...original.toJson(),
        'textAreas': [
          {
            'areaId': 'a',
            'label': '',
            'region': {'outer': circle().toJson()},
          },
        ],
      }),
      designError(
        DesignErrorCode.missingField,
        'textAreas[0].region.exclusions',
      ),
    );
    try {
      DesignGeometry.fromJson({
        ...original.toJson(),
        'cutouts': [
          {
            'cutoutId': 'h',
            'boundary': {
              'kind': 'circle',
              'center': {'x': 0, 'y': 0},
              'radius': 0,
            },
          },
        ],
      });
      fail('기하 오류 허용');
    } on GeometryValidationException catch (e) {
      expect(e.code, GeometryErrorCode.nonPositiveRadius);
      expect(e.fieldPath, 'cutouts[0].boundary.radius');
      expect((e.diagnostic.details as GeometryNumberDetails).value, 0);
      expect(identical(e.prefixed('root').diagnostic, e.diagnostic), isTrue);
    }
  });
}
