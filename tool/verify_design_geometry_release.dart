// AOT 검사 결과를 표준 출력하고 의도한 불변성 예외를 확인한다.
// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:r_edit_workflow/r_edit_workflow.dart';

/// assert 비활성 AOT에서 도안 정의·입력 연결·전체 환산을 확인한다.
void main() {
  var assertions = false;
  assert(() {
    assertions = true;
    return true;
  }(), 'AOT 실행 모드 확인');
  if (assertions) {
    throw StateError('assert 비활성 실행이 필요합니다');
  }
  final boundary = CircleBoundary(center: Point2(x: 2, y: 2), radius: 1);
  final cutout = CutoutDefinition(cutoutId: 'h', boundary: boundary);
  final exclusions = <ClosedBoundary>[boundary];
  final area = TextAreaDefinition(
    areaId: ' a ',
    label: '',
    region: TextRegion(outer: boundary, exclusions: exclusions),
  );
  final cutouts = [cutout];
  final areas = [area];
  final design = DesignGeometry(
    coordinateSpace: DrawingCoordinateSpace(lengthUnit: LengthUnit.inch),
    outline: boundary,
    cutouts: cutouts,
    textAreas: areas,
  );
  exclusions.clear();
  cutouts.clear();
  areas.clear();
  final restored = DesignGeometry.fromJson(
    jsonDecode(jsonEncode(design.toJson())),
  );
  if (restored != design ||
      design.textAreas.single.region.exclusions.length != 1) {
    throw StateError('왕복/방어 복사 실패');
  }
  final json = restored.toJson();
  (json['textAreas'] as List).clear();
  if (restored.textAreas.length != 1) {
    throw StateError('반환 JSON 방어 실패');
  }
  final mm = design.convertedTo(LengthUnit.millimeter);
  if ((mm.outline as CircleBoundary).radius != 25.4 ||
      (mm.cutouts.single.boundary as CircleBoundary).center.x != 50.8 ||
      (mm.textAreas.single.region.exclusions.single as CircleBoundary).radius !=
          25.4 ||
      design.coordinateSpace.lengthUnit != LengthUnit.inch ||
      mm.textAreas.single.areaId != ' a ' ||
      mm.textAreas.single.label != '') {
    throw StateError('전체 환산/식별 문자열 보존 실패');
  }
  final input = TextAreaInput(
    areaId: ' a ',
    sourceText: ' PUMP e\u0301 ',
    lineBreak: SpecifiedLineBreak([' PUMP e\u0301 ']),
  );
  if (validateTextAreaInputs(design: design, inputs: [input]).isNotEmpty ||
      input.lineBreak is! SpecifiedLineBreak) {
    throw StateError('ID 연결/직접 지정 보존 실패');
  }
  final issues = validateTextAreaInputs(
    design: design.copyWith(
      textAreas: [
        area,
        area.copyWith(areaId: 'b'),
      ],
    ),
    inputs: [
      input,
      input,
      input.copyWith(areaId: 'unknown'),
    ],
  );
  final codes = issues.map((i) => i.code).toSet();
  if (!codes.containsAll([
    DesignErrorCode.duplicateInputAreaId,
    DesignErrorCode.unknownInputAreaId,
    DesignErrorCode.missingAreaInput,
  ])) {
    throw StateError('연결 진단 누락');
  }
  print(issues[0]);
  print(issues[1]);
  print(issues[2]);
  final failures = <(void Function(), DesignErrorCode, String)>[
    (
      () => cutout.copyWith(cutoutId: ''),
      DesignErrorCode.emptyCutoutId,
      'cutoutId',
    ),
    (() => area.copyWith(areaId: ''), DesignErrorCode.emptyAreaId, 'areaId'),
    (
      () => design.copyWith(cutouts: [cutout, cutout]),
      DesignErrorCode.duplicateCutoutId,
      'cutouts[1].cutoutId',
    ),
    (
      () => design.copyWith(textAreas: [area, area]),
      DesignErrorCode.duplicateAreaId,
      'textAreas[1].areaId',
    ),
    (
      () => DesignGeometry.fromJson({
        ...design.toJson(),
        'cutouts': [cutout.toJson(), cutout.toJson()],
      }),
      DesignErrorCode.duplicateCutoutId,
      'cutouts[1].cutoutId',
    ),
    (
      () => DesignGeometry.fromJson({
        ...design.toJson(),
        'textAreas': [area.toJson(), area.toJson()],
      }),
      DesignErrorCode.duplicateAreaId,
      'textAreas[1].areaId',
    ),
    (
      () => TextAreaDefinition.fromJson({...area.toJson(), 'label': null}),
      DesignErrorCode.invalidType,
      'label',
    ),
    (
      () => TextRegion.fromJson({'outer': boundary.toJson()}),
      DesignErrorCode.missingField,
      'exclusions',
    ),
  ];
  for (final (run, code, path) in failures) {
    var rejected = false;
    try {
      run();
    } on DesignValidationException catch (e) {
      rejected = e.code == code && e.fieldPath == path;
    }
    if (!rejected) {
      throw StateError('도안 런타임 검증 우회: $code $path');
    }
  }
  var geometryRejected = false;
  try {
    DesignGeometry.fromJson({
      ...design.toJson(),
      'textAreas': [
        {
          'areaId': 'a',
          'label': '',
          'region': {
            'outer': boundary.toJson(),
            'exclusions': [
              {
                'kind': 'circle',
                'center': {'x': 0, 'y': 0},
                'radius': 0,
              },
            ],
          },
        },
      ],
    });
  } on GeometryValidationException catch (e) {
    geometryRejected =
        e.code == GeometryErrorCode.nonPositiveRadius &&
        e.fieldPath == 'textAreas[0].region.exclusions[0].radius';
  }
  if (!geometryRejected) {
    throw StateError('하위 기하 진단 소실');
  }
  print(
    '도안 AOT: assert 비활성, 왕복·방어 복사·환산·연결, 정의 오류 ${failures.length}건·하위 기하 오류 1건 통과',
  );
}
