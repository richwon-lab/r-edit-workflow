import 'dart:io';

import 'package:r_edit_workflow/r_edit_workflow.dart';

/// assert 비활성에서 준비 결과·진단 필수 상세·방어 복사가 동작하는지 확인한다.
void main() {
  var assertionsEnabled = false;
  assert(assertionsEnabled = true, 'assert 상태');
  if (assertionsEnabled) throw StateError('assert 비활성 AOT가 필요합니다.');
  final geometry = DesignGeometry(
    coordinateSpace: DrawingCoordinateSpace(lengthUnit: LengthUnit.millimeter),
    outline: CircleBoundary(center: Point2(x: 0, y: 0), radius: 20),
    cutouts: [],
    textAreas: [],
  );
  final baseline = ProductDesignConfiguration(
    appliedGeometries: [
      AppliedDesignGeometry(appliedGeometryId: 'old', geometry: geometry),
    ],
    products: [
      ProductInput(productId: 'p', appliedGeometryId: 'old', textInputs: []),
    ],
  );
  final targets = [
    ProductGeometryTarget(
      productId: 'p',
      areaMappings: [],
      newTextInputs: [],
      removedInputAreaIds: [],
    ),
  ];
  final request = ReviseAppliedGeometry(
    sourceAppliedGeometryId: 'old',
    proposedGeometry: AppliedDesignGeometry(
      appliedGeometryId: 'next',
      geometry: geometry,
    ),
    targets: targets,
  );
  targets.clear();
  final prepared = ProductDesignEditSession.open(configuration: baseline)
      .prepareGeometryChange(request);
  if (prepared is! ReadyProductGeometryChange ||
      prepared.summary.products.single.proposedAppliedGeometryId != 'next' ||
      baseline.products.single.appliedGeometryId != 'old' ||
      request.targets.length != 1) {
    throw StateError('순수 준비/목록 방어 실패');
  }
  final blocked = ProductDesignEditSession.open(configuration: baseline)
      .prepareGeometryChange(request.copyWith(targets: []));
  if (blocked is! BlockedProductGeometryChange ||
      blocked.issues.single.code != ProductGeometryChangeCode.emptyTargetSet) {
    throw StateError('정상 요청 거부 실패');
  }
  void rejectArgument(String name, void Function() action) {
    try {
      action();
      // 진단 API 오용만 검사하며 업무 함수의 Error를 Blocked로 숨기지 않는다.
      // ignore: avoid_catching_errors
    } on ArgumentError catch (error) {
      if (error.name != name || error.message == null) {
        throw StateError('인자 진단 누락');
      }
      return;
    }
    throw StateError('런타임 진단 방어가 우회되었습니다: $name');
  }

  rejectArgument('identifier', () => ChangeIdentifierDetails('not-empty'));
  rejectArgument(
    'targetIndex',
    () => ChangeTargetDetails(productId: 'p', targetIndex: -1),
  );
  rejectArgument(
    'productId',
    () => ChangeTargetDetails(productId: '', targetIndex: 0),
  );
  rejectArgument(
    'targetIndices',
    () => ChangeDuplicateTargetsDetails(productId: 'p', targetIndices: [0]),
  );
  rejectArgument(
    'actualAppliedGeometryId',
    () => ChangeAppliedReferenceDetails(
      productId: 'p',
      productIndex: 0,
      expectedAppliedGeometryId: 'g',
      actualAppliedGeometryId: 'g',
    ),
  );
  rejectArgument(
    'selectionPaths',
    () => ChangeAreaSelectionDetails(
      productId: 'p',
      previousAppliedGeometryId: 'old',
      proposedAppliedGeometryId: 'new',
      areaId: 'a',
      side: ChangeAreaSide.source,
      selectionPaths: [],
    ),
  );
  rejectArgument(
    'fieldPath',
    () => ProductGeometryChangeIssue(
      code: ProductGeometryChangeCode.emptyTargetSet,
      fieldPath: 'request.targets[-1]',
      details: const ChangeEmptyTargetsDetails(),
    ),
  );
  rejectArgument(
    'details',
    () => ProductGeometryChangeIssue(
      code: ProductGeometryChangeCode.unknownTargetProduct,
      fieldPath: 'request.targets[0].productId',
      details: const ChangeEmptyTargetsDetails(),
    ),
  );
  rejectArgument(
    'changedFieldPaths[0]',
    () => ChangeSnapshotConflictDetails(
      appliedGeometryId: 'g',
      baselineIndex: 0,
      changedFieldPaths: ['geometry.unknown'],
    ),
  );
  final paths = ['request.targets[0].areaMappings[0].fromAreaId'];
  final details = ChangeAreaSelectionDetails(
    productId: 'p',
    previousAppliedGeometryId: 'old',
    proposedAppliedGeometryId: 'new',
    areaId: 'a',
    side: ChangeAreaSide.source,
    selectionPaths: paths,
  );
  paths.clear();
  if (details.selectionPaths.length != 1) throw StateError('진단 방어 복사 실패');
  stdout.writeln('변경 준비 AOT: 순수 Ready/Blocked·요청 목록·필수 진단 런타임 방어 확인');
}
