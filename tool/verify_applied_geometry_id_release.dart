import 'dart:io';

import 'package:r_edit_workflow/r_edit_workflow.dart';

/// assert 비활성 실행에서 ID 연결·내용 비교·진단 방어를 확인한다.
void main() {
  var assertionsEnabled = false;
  assert(assertionsEnabled = true, 'assert 상태 확인');
  if (assertionsEnabled) throw StateError('AOT 검사는 assert 비활성 조건이 필요합니다.');
  DesignGeometry geometry(double radius) => DesignGeometry(
    coordinateSpace: DrawingCoordinateSpace(lengthUnit: LengthUnit.millimeter),
    outline: CircleBoundary(center: Point2(x: 0, y: 0), radius: radius),
    cutouts: [],
    textAreas: [],
  );
  AppliedDesignGeometry snapshot(String id, double radius) =>
      AppliedDesignGeometry(appliedGeometryId: id, geometry: geometry(radius));
  final previous = ProductDesignConfiguration(
    appliedGeometries: [snapshot('a', 30), snapshot('b', 10)],
    products: [],
  );
  final next = ProductDesignConfiguration(
    appliedGeometries: [snapshot('b', 11), snapshot('a', 31)],
    products: [],
  );
  final conflicts = validateAppliedGeometryIdConsistency(
    previous: previous,
    next: next,
  );
  if (conflicts.length != 2) throw StateError('독립 충돌 수집 실패');
  final a = conflicts.singleWhere((c) => c.appliedGeometryId == 'a');
  if (a.previousIndex != 0 ||
      a.nextIndex != 1 ||
      a.fieldPath != 'next.appliedGeometries[1]' ||
      a.changedFieldPaths.single != 'geometry.outline.radius' ||
      a.code != AppliedGeometryIdConflictCode.snapshotContentConflict) {
    throw StateError('ID 연결/필드 경로 실패');
  }
  var rejected = false;
  try {
    AppliedGeometryIdConflict(
      appliedGeometryId: 'g',
      previousIndex: -1,
      nextIndex: 0,
      changedFieldPaths: ['source'],
    );
    // 진단 API 오용의 런타임 거부를 검사한다. 일반 충돌을 catch하지 않는다.
    // ignore: avoid_catching_errors
  } on ArgumentError {
    rejected = true;
  }
  if (!rejected) throw StateError('assert 없이 진단 검증이 동작하지 않음');
  var immutable = false;
  try {
    a.changedFieldPaths.clear();
    // 수정 불가 공개 목록의 방어를 assert 없이 검사한다.
    // ignore: avoid_catching_errors
  } on UnsupportedError {
    immutable = true;
  }
  if (!immutable) throw StateError('진단 목록이 외부에서 수정됨');
  stdout.writeln('적용 ID AOT: 독립 충돌·이전/다음 위치·내용 경로·진단 런타임 검증·목록 방어 확인');
}
