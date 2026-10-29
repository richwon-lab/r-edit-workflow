import 'dart:io';

import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:r_edit_workflow/src/product/product_design_edit_validation.dart';

/// assert 비활성에서 세션 반영·수명·전체 A 복원·개정 한계·진단 방어를 확인한다.
void main() {
  var enabled = false;
  assert(enabled = true, 'assert 상태');
  if (enabled) throw StateError('assert 비활성 AOT가 필요합니다.');
  final geometry = DesignGeometry(
    coordinateSpace: DrawingCoordinateSpace(lengthUnit: LengthUnit.millimeter),
    outline: CircleBoundary(center: Point2(x: 0, y: 0), radius: 20),
    cutouts: [],
    textAreas: [],
  );
  final old = AppliedDesignGeometry(
    appliedGeometryId: 'old',
    geometry: geometry,
  );
  final alternate = AppliedDesignGeometry(
    appliedGeometryId: 'alternate',
    geometry: geometry,
  );
  final initial = ProductDesignConfiguration(
    appliedGeometries: [old, alternate],
    products: [
      ProductInput(productId: 'p', appliedGeometryId: 'old', textInputs: []),
    ],
  );
  final session = ProductDesignEditSession.open(configuration: initial);
  ProductGeometryTarget target() => ProductGeometryTarget(
    productId: 'p',
    areaMappings: [],
    newTextInputs: [],
    removedInputAreaIds: [],
  );
  final request = ReviseAppliedGeometry(
    sourceAppliedGeometryId: 'old',
    proposedGeometry: alternate,
    targets: [target()],
  );
  final stale =
      session.prepareGeometryChange(request) as ReadyProductGeometryChange;
  final current =
      session.prepareGeometryChange(request) as ReadyProductGeometryChange;
  final originalState = session.state;
  final accepted = session.applyPreparedGeometryChange(
    current,
  ) as AppliedProductGeometryChange;
  if (accepted.configuration.products.single.appliedGeometryId != 'alternate' ||
      accepted.state.revision != 1 ||
      originalState.revision != 0) {
    throw StateError('원자적 반영/관찰 불변 실패');
  }
  final back = session.prepareGeometryChange(
    ReviseAppliedGeometry(
      sourceAppliedGeometryId: 'alternate',
      proposedGeometry: old,
      targets: [target()],
    ),
  ) as ReadyProductGeometryChange;
  final restored =
      session.applyPreparedGeometryChange(back) as AppliedProductGeometryChange;
  if (restored.configuration != initial || restored.state.revision != 2) {
    throw StateError('실제 전체 A 복원 실패');
  }
  final rejected = session.applyPreparedGeometryChange(
    stale,
  ) as RejectedProductGeometryChange;
  if (rejected.issues.single.code !=
          ProductGeometryChangeApplicationCode.staleEditRevision ||
      session.state != restored.state) {
    throw StateError('A→B→A 개정 거부 실패');
  }
  final mismatch = validateProductDesignEditBasis(
    currentSessionId: session.state.sessionId,
    currentRevision: 0,
    isClosed: false,
    currentConfiguration: accepted.configuration,
    basis: stale.basis,
  );
  if (mismatch.single.code !=
      ProductGeometryChangeApplicationCode.baselineConfigurationMismatch) {
    throw StateError('전체 내용 독립 방어 실패');
  }
  const last = 0x7fffffffffffffff;
  var committed = (revision: last, configuration: initial);
  var overflowRejected = false;
  try {
    committed = prepareProductDesignEditCommit(
      revision: committed.revision,
      candidate: accepted.configuration,
    );
    // 개정 표현 한계의 의도한 Error를 AOT에서 검증한다. 운영 반영은 Error를 잡지 않는다.
    // ignore: avoid_catching_errors
  } on StateError {
    overflowRejected = true;
  }
  if (!overflowRejected ||
      committed.revision != last ||
      committed.configuration != initial) {
    throw StateError('개정 한계 부분 반영');
  }
  var invalidRejected = false;
  try {
    EditRevisionMismatchDetails(
      sessionId: session.state.sessionId,
      expectedRevision: -1,
      actualRevision: 0,
    );
    // 의도한 진단 API 오용의 런타임 방어만 확인한다.
    // ignore: avoid_catching_errors
  } on ArgumentError catch (error) {
    invalidRejected =
        error.name == 'expectedRevision' &&
        error.invalidValue == -1 &&
        error.message != null;
  }
  if (!invalidRejected) throw StateError('필수 진단 런타임 방어 실패');
  session.close();
  session.close();
  if ((session.applyPreparedGeometryChange(
        stale,
      ) as RejectedProductGeometryChange).issues.single.code !=
      ProductGeometryChangeApplicationCode.closedEditSession) {
    throw StateError('닫힘 거부 실패');
  }
  final reopened = ProductDesignEditSession.open(configuration: initial);
  if ((reopened.applyPreparedGeometryChange(
        stale,
      ) as RejectedProductGeometryChange).issues.single.code !=
      ProductGeometryChangeApplicationCode.differentEditSession) {
    throw StateError('재열기 토큰 거부 실패');
  }
  stdout.writeln('편집 세션 AOT: 반영·실제 A 복원·수명·개정 한계·내용/진단 런타임 방어 확인');
}
