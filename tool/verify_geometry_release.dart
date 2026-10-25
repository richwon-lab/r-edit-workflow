import 'dart:convert';

import 'package:r_edit_workflow/r_edit_workflow.dart';

/// assert 비활성 실행에서도 형상 값의 생성·수정·복원을 검증한다.
void main() {
  var assertions = false;
  assert(() {
    assertions = true;
    return true;
  }());
  if (assertions) throw StateError('assert 비활성 실행이 필요합니다');
  final hole = CircularHole(
    holeId: 'h',
    centerXMm: 10,
    centerYMm: 10,
    diameterMm: 4,
  );
  final incoming = [hole];
  final plate = RectangularPlateGeometry(
    widthMm: 36,
    heightMm: 36,
    holes: incoming,
  );
  incoming.clear();
  final wider = plate.copyWith(widthMm: 40);
  if (wider.holes.single != hole || wider.widthMm != 40) {
    throw StateError('치수 변경으로 홀 변경');
  }
  final json = plate.toJson();
  final restored = RectangularPlateGeometry.fromJson(
    jsonDecode(jsonEncode(json)),
  );
  ((json['holes'] as List).single as Map)['diameterMm'] = 999;
  if (restored != plate || plate.holes.single != hole || plate.widthMm != 36) {
    throw StateError('방어 복사/왕복 실패');
  }
  final bounds = TextAreaBounds(
    xMm: -1.23456789012345,
    yMm: 0,
    widthMm: 40,
    heightMm: 30,
  );
  final area = TextAreaDefinition(areaId: ' a ', label: '', bounds: bounds);
  final moved = area.copyWith(bounds: bounds.copyWith(xMm: -100));
  if (TextAreaDefinition.fromJson(jsonDecode(jsonEncode(area.toJson()))) !=
          area ||
      moved.areaId != ' a ' ||
      area.bounds.xMm != -1.23456789012345) {
    throw StateError('영역 보존 실패');
  }
  final failures = <(void Function(), GeometryErrorCode, String)>[
    (() => hole.copyWith(holeId: ''), GeometryErrorCode.emptyHoleId, 'holeId'),
    (() => area.copyWith(areaId: ''), GeometryErrorCode.emptyAreaId, 'areaId'),
    (
      () => plate.copyWith(widthMm: 0),
      GeometryErrorCode.nonPositiveDimension,
      'widthMm',
    ),
    (
      () => area.copyWith.bounds(heightMm: -1),
      GeometryErrorCode.nonPositiveDimension,
      'heightMm',
    ),
    (
      () => hole.copyWith(diameterMm: 0),
      GeometryErrorCode.nonPositiveDimension,
      'diameterMm',
    ),
    (
      () => hole.copyWith(centerXMm: double.nan),
      GeometryErrorCode.nonFiniteNumber,
      'centerXMm',
    ),
    (
      () => bounds.copyWith(yMm: double.infinity),
      GeometryErrorCode.nonFiniteNumber,
      'yMm',
    ),
    (
      () => plate.copyWith(heightMm: double.negativeInfinity),
      GeometryErrorCode.nonFiniteNumber,
      'heightMm',
    ),
    (
      () => bounds.copyWith(xMm: double.maxFinite, widthMm: double.maxFinite),
      GeometryErrorCode.nonFiniteBoundary,
      'xMm',
    ),
    (
      () => hole.copyWith(
        centerYMm: -double.maxFinite,
        diameterMm: double.maxFinite,
      ),
      GeometryErrorCode.nonFiniteBoundary,
      'centerYMm',
    ),
    (
      () => plate.copyWith(holes: [hole, hole.copyWith(centerXMm: 20)]),
      GeometryErrorCode.duplicateHoleId,
      'holes[1].holeId',
    ),
    (
      () => RectangularPlateGeometry.fromJson({
        'widthMm': 1,
        'heightMm': 1,
        'holes': [hole.toJson(), hole.toJson()],
      }),
      GeometryErrorCode.duplicateHoleId,
      'holes[1].holeId',
    ),
    (
      () => CircularHole.fromJson({...hole.toJson(), 'diameterMm': 0}),
      GeometryErrorCode.nonPositiveDimension,
      'diameterMm',
    ),
    (
      () => TextAreaDefinition.fromJson({
        ...area.toJson(),
        'bounds': {...bounds.toJson(), 'widthMm': 0},
      }),
      GeometryErrorCode.nonPositiveDimension,
      'bounds.widthMm',
    ),
    (
      () => RectangularPlateGeometry.fromJson({
        'widthMm': 1,
        'heightMm': 1,
        'holes': [null],
      }),
      GeometryErrorCode.invalidType,
      'holes[0]',
    ),
    (
      () => TextAreaDefinition.fromJson({
        'areaId': 'a',
        'bounds': bounds.toJson(),
      }),
      GeometryErrorCode.missingField,
      'label',
    ),
    (
      () => CircularHole.fromJson({...hole.toJson(), 'kind': 'circle'}),
      GeometryErrorCode.unexpectedField,
      'kind',
    ),
  ];
  for (final (run, code, path) in failures) {
    var rejected = false;
    try {
      run();
    } on GeometryValidationException catch (e) {
      rejected = e.code == code && e.fieldPath == path;
    }
    if (!rejected) throw StateError('검증 실패: $code $path');
  }
  print('형상 AOT: assert 비활성, 정상 왕복·교체·방어 복사와 오류 ${failures.length}건 통과');
}
