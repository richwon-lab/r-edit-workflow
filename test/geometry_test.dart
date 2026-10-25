import 'dart:convert';

import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

CircularHole hole({
  String id = 'h',
  double x = 10,
  double y = 10,
  double diameter = 4,
}) =>
    CircularHole(holeId: id, centerXMm: x, centerYMm: y, diameterMm: diameter);
TextAreaBounds bounds() =>
    TextAreaBounds(xMm: 5, yMm: 5, widthMm: 110, heightMm: 50);
Map<String, Object?> decoded(Object value) =>
    jsonDecode(jsonEncode(value)) as Map<String, Object?>;
Matcher invalid(GeometryErrorCode code, String path) => throwsA(
  isA<GeometryValidationException>()
      .having((e) => e.code, 'code', code)
      .having((e) => e.fieldPath, 'fieldPath', path),
);

void main() {
  test('홀 없는 판과 3열 2행 홀은 실제 좌표와 순서를 왕복한다', () {
    final holes = [
      for (final y in [15.0, 45.0])
        for (final x in [20.0, 60.0, 100.0]) hole(id: '$x:$y', x: x, y: y),
    ];
    for (final list in [<CircularHole>[], holes]) {
      final plate = RectangularPlateGeometry(
        widthMm: 120,
        heightMm: 60,
        holes: list,
      );
      final restored = RectangularPlateGeometry.fromJson(
        decoded(plate.toJson()),
      );
      expect(restored, plate);
      expect(restored.holes, list);
      expect(restored.hashCode, plate.hashCode);
    }
    expect(holes.map((h) => h.centerXMm), [20, 60, 100, 20, 60, 100]);
  });

  test('정수와 소수 JSON은 double로 변환하고 값과 표시 문자열을 보정하지 않는다', () {
    final value = CircularHole.fromJson(
      jsonDecode(
        '{"holeId":" h ","centerXMm":-2,"centerYMm":1.23456789012345,"diameterMm":4}',
      ),
    );
    expect(value.centerXMm, isA<double>());
    expect(value.centerYMm, 1.23456789012345);
    expect(CircularHole.fromJson(decoded(value.toJson())), value);
    final rectangle = TextAreaBounds.fromJson({
      'xMm': -1,
      'yMm': 2.25,
      'widthMm': 12,
      'heightMm': 3.5,
    });
    for (final label in ['', '  본문 e\u0301 👩‍🔧  ']) {
      final area = TextAreaDefinition(
        areaId: ' a ',
        label: label,
        bounds: rectangle,
      );
      final restored = TextAreaDefinition.fromJson(decoded(area.toJson()));
      expect(restored, area);
      expect(restored.label, label);
      expect(restored.areaId, ' a ');
    }
  });

  test('전달 목록과 반환 JSON을 바꾸어도 원래 판과 홀은 유지된다', () {
    final list = [hole()];
    final plate = RectangularPlateGeometry(
      widthMm: 36,
      heightMm: 36,
      holes: list,
    );
    list.clear();
    expect(plate.holes.single.holeId, 'h');
    expect(() => plate.holes.clear(), throwsUnsupportedError);
    final json = plate.toJson();
    final output = json['holes'] as List;
    (output.single as Map)['holeId'] = 'changed';
    output.clear();
    json['widthMm'] = 999;
    expect(plate.holes.single.holeId, 'h');
    expect(plate.widthMm, 36);
    final incoming = plate.toJson();
    final restored = RectangularPlateGeometry.fromJson(incoming);
    (incoming['holes'] as List).clear();
    expect(restored, plate);
    final area = TextAreaDefinition(areaId: 'a', label: '', bounds: bounds());
    final areaJson = area.toJson();
    (areaJson['bounds'] as Map)['widthMm'] = 0;
    expect(area.bounds.widthMm, 110);
  });

  test('copyWith는 검증하고 목록을 복사하며 치수 변경으로 홀을 확대하지 않는다', () {
    final original = RectangularPlateGeometry(
      widthMm: 36,
      heightMm: 36,
      holes: [hole()],
    );
    final changed = original.copyWith(widthMm: 40);
    expect(changed.holes, original.holes);
    expect(original.widthMm, 36);
    final incoming = [hole(id: 'new')];
    final next = changed.copyWith(holes: incoming);
    incoming.clear();
    expect(next.holes.single.holeId, 'new');
    expect(original.holes.single.holeId, 'h');
    expect(
      () => original.copyWith(heightMm: 0),
      invalid(GeometryErrorCode.nonPositiveDimension, 'heightMm'),
    );
    final area = TextAreaDefinition(areaId: 'a', label: '', bounds: bounds());
    final moved = area.copyWith(bounds: area.bounds.copyWith(xMm: -100));
    final chained = area.copyWith.bounds(widthMm: 120);
    expect(chained.bounds.widthMm, 120);
    expect(area.bounds.widthMm, 110);
    expect(
      () => area.copyWith.bounds(widthMm: 0),
      invalid(GeometryErrorCode.nonPositiveDimension, 'widthMm'),
    );
    expect(moved.areaId, 'a');
    expect(area.bounds.xMm, 5);
    expect(
      () => area.copyWith(areaId: ''),
      invalid(GeometryErrorCode.emptyAreaId, 'areaId'),
    );
    expect(
      () => hole().copyWith(holeId: ''),
      invalid(GeometryErrorCode.emptyHoleId, 'holeId'),
    );
  });

  test('소유한 목록의 홀 ID 중복은 생성·수정·복원에서 거부한다', () {
    final plate = RectangularPlateGeometry(
      widthMm: 36,
      heightMm: 36,
      holes: [hole()],
    );
    for (final run in <void Function()>[
      () => RectangularPlateGeometry(
        widthMm: 36,
        heightMm: 36,
        holes: [hole(), hole(x: 20)],
      ),
      () => plate.copyWith(holes: [hole(), hole()]),
      () => RectangularPlateGeometry.fromJson({
        'widthMm': 36,
        'heightMm': 36,
        'holes': [hole().toJson(), hole().toJson()],
      }),
    ]) {
      expect(
        run,
        invalid(GeometryErrorCode.duplicateHoleId, 'holes[1].holeId'),
      );
    }
    expect(plate.holes, hasLength(1));
  });

  final cases = <(String, Map<String, Object?>, Object Function(Object?))>[
    (
      '판',
      {'widthMm': 36, 'heightMm': 36, 'holes': []},
      RectangularPlateGeometry.fromJson,
    ),
    (
      '홀',
      {'holeId': 'h', 'centerXMm': 10, 'centerYMm': 10, 'diameterMm': 4},
      CircularHole.fromJson,
    ),
    (
      '영역 경계',
      {'xMm': 1, 'yMm': 2, 'widthMm': 3, 'heightMm': 4},
      TextAreaBounds.fromJson,
    ),
    (
      '영역 정의',
      {'areaId': 'a', 'label': '', 'bounds': bounds().toJson()},
      TextAreaDefinition.fromJson,
    ),
  ];
  for (final (name, json, parse) in cases) {
    test('$name 필수 누락·잘못된 타입·추가 필드·최상위 타입을 구분한다', () {
      for (final key in json.keys) {
        final missing = Map<String, Object?>.of(json)..remove(key);
        expect(
          () => parse(missing),
          invalid(GeometryErrorCode.missingField, key),
        );
        for (final value in [null, true, 'wrong', 1, <String, Object?>{}]) {
          if (json[key] is num && value is num ||
              json[key] is String && value is String ||
              json[key] is Map && value is Map) {
            continue;
          }
          expect(
            () => parse({...json, key: value}),
            invalid(GeometryErrorCode.invalidType, key),
          );
        }
      }
      expect(
        () => parse({...json, 'kind': 'unknown'}),
        invalid(GeometryErrorCode.unexpectedField, 'kind'),
      );
      expect(() => parse([]), invalid(GeometryErrorCode.invalidType, r'$'));
    });
    for (final key in json.keys.where((key) => json[key] is num)) {
      test('$name $key 비유한 숫자는 JSON 경계에서 보정하지 않는다', () {
        for (final value in [
          double.nan,
          double.infinity,
          double.negativeInfinity,
        ]) {
          expect(
            () => parse({...json, key: value}),
            invalid(GeometryErrorCode.nonFiniteNumber, key),
          );
        }
      });
    }
  }

  test('직접 생성·copyWith도 모든 수치의 유한성과 양수 치수를 검사한다', () {
    for (final value in [
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      for (final (run, path) in <(void Function(), String)>[
        (
          () =>
              RectangularPlateGeometry(widthMm: value, heightMm: 1, holes: []),
          'widthMm',
        ),
        (
          () =>
              RectangularPlateGeometry(widthMm: 1, heightMm: value, holes: []),
          'heightMm',
        ),
        (() => hole(x: value), 'centerXMm'),
        (() => hole(y: value), 'centerYMm'),
        (() => hole(diameter: value), 'diameterMm'),
        (() => bounds().copyWith(xMm: value), 'xMm'),
        (() => bounds().copyWith(yMm: value), 'yMm'),
        (() => bounds().copyWith(widthMm: value), 'widthMm'),
        (() => bounds().copyWith(heightMm: value), 'heightMm'),
      ]) {
        expect(run, invalid(GeometryErrorCode.nonFiniteNumber, path));
      }
    }
    for (final value in [0.0, -0.0, -1.0]) {
      expect(
        () => hole(diameter: value),
        invalid(GeometryErrorCode.nonPositiveDimension, 'diameterMm'),
      );
      expect(
        () => bounds().copyWith(widthMm: value),
        invalid(GeometryErrorCode.nonPositiveDimension, 'widthMm'),
      );
      expect(
        () => bounds().copyWith(heightMm: value),
        invalid(GeometryErrorCode.nonPositiveDimension, 'heightMm'),
      );
      expect(
        () => RectangularPlateGeometry(widthMm: value, heightMm: 1, holes: []),
        invalid(GeometryErrorCode.nonPositiveDimension, 'widthMm'),
      );
      expect(
        () => RectangularPlateGeometry(widthMm: 1, heightMm: value, holes: []),
        invalid(GeometryErrorCode.nonPositiveDimension, 'heightMm'),
      );
    }
  });

  test('유한한 입력의 파생 끝점 오버플로도 거부한다', () {
    final max = double.maxFinite;
    for (final (run, path) in <(void Function(), String)>[
      (
        () => TextAreaBounds(xMm: max, yMm: 0, widthMm: max, heightMm: 1),
        'xMm',
      ),
      (() => bounds().copyWith(yMm: max, heightMm: max), 'yMm'),
      (() => hole(x: max, diameter: max), 'centerXMm'),
      (() => hole(x: -max, diameter: max), 'centerXMm'),
      (() => hole(y: max, diameter: max), 'centerYMm'),
      (() => hole(y: -max, diameter: max), 'centerYMm'),
    ]) {
      expect(run, invalid(GeometryErrorCode.nonFiniteBoundary, path));
    }
  });

  test('중첩 JSON은 하위 필드·목록 위치와 업무 오류를 전달한다', () {
    expect(
      () => RectangularPlateGeometry.fromJson({
        'widthMm': 36,
        'heightMm': 36,
        'holes': [
          hole().toJson(),
          {'holeId': 'other', 'centerXMm': 1, 'centerYMm': 2, 'diameterMm': 0},
        ],
      }),
      invalid(GeometryErrorCode.nonPositiveDimension, 'holes[1].diameterMm'),
    );
    expect(
      () => RectangularPlateGeometry.fromJson({
        'widthMm': 36,
        'heightMm': 36,
        'holes': [null],
      }),
      invalid(GeometryErrorCode.invalidType, 'holes[0]'),
    );
    expect(
      () => TextAreaDefinition.fromJson({
        'areaId': 'a',
        'label': '',
        'bounds': {'xMm': 1, 'yMm': 2, 'heightMm': 4},
      }),
      invalid(GeometryErrorCode.missingField, 'bounds.widthMm'),
    );
    expect(
      () => TextAreaDefinition.fromJson({
        'areaId': '',
        'label': '',
        'bounds': bounds().toJson(),
      }),
      invalid(GeometryErrorCode.emptyAreaId, 'areaId'),
    );
    expect(
      () => CircularHole.fromJson({...hole().toJson(), 'holeId': ''}),
      invalid(GeometryErrorCode.emptyHoleId, 'holeId'),
    );
  });

  test('형상 관계는 검사하지 않아 외부 홀·동일 위치 홀·겹치는 영역을 정의할 수 있다', () {
    final plate = RectangularPlateGeometry(
      widthMm: 10,
      heightMm: 10,
      holes: [
        hole(id: 'one', x: -100),
        hole(id: 'two', x: -100),
      ],
    );
    final first = TextAreaDefinition(areaId: 'a', label: '', bounds: bounds());
    final second = TextAreaDefinition(
      areaId: 'b',
      label: '',
      bounds: first.bounds,
    );
    expect(plate.holes, hasLength(2));
    expect(first.bounds, second.bounds);
    final overlapping = TextAreaDefinition(
      areaId: 'c',
      label: '',
      bounds: TextAreaBounds(xMm: -110, yMm: 0, widthMm: 20, heightMm: 20),
    );
    expect(overlapping.bounds.xMm, -110);
  });
}
