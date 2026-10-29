import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/product_examples.dart';
import '../support/product_geometry_changes.dart';

void main() {
  late ProductDesignConfiguration baseline;
  late ProductDesignEditSession session;
  setUp(() {
    baseline = twoProductsSharingTitleGeometry();
    session = ProductDesignEditSession.open(configuration: baseline);
  });
  ReadyProductGeometryChange ready(String id) => session.prepareGeometryChange(
    ReviseAppliedGeometry(
      sourceAppliedGeometryId: 'old',
      proposedGeometry: appliedMillimeterDesign(id, ['title']),
      targets: [targetPreservingAreas('p1')],
    ),
  ) as ReadyProductGeometryChange;
  test('같은 구성으로 열어도 매 수명마다 다른 토큰과 개정 0을 발급한다', () {
    final other = ProductDesignEditSession.open(configuration: baseline);
    expect(session.state.sessionId, isNot(other.state.sessionId));
    expect(identical(session.state.sessionId, other.state.sessionId), isFalse);
    expect(session.state.revision, 0);
    expect(session.state.isClosed, isFalse);
    expect(session.state.configuration, same(baseline));
  });
  test('준비는 한 상태의 기준을 연결하고 Blocked·Unchanged·폐기 모두 정본을 보존한다', () {
    final before = session.state;
    final prepared = ready('new');
    final blocked = session.prepareGeometryChange(
      ReplaceAppliedGeometry(
        proposedGeometry: baseline.appliedGeometries.single,
        targets: [],
      ),
    );
    final unchanged = session.prepareGeometryChange(
      ReviseAppliedGeometry(
        sourceAppliedGeometryId: 'old',
        proposedGeometry: baseline.appliedGeometries.single,
        targets: [targetPreservingAreas('p1')],
      ),
    );
    expect(blocked, isA<BlockedProductGeometryChange>());
    expect(unchanged, isA<UnchangedProductGeometryChange>());
    for (final result in [prepared, blocked, unchanged]) {
      expect(result.basis.sessionId, same(before.sessionId));
      expect(result.basis.revision, 0);
      expect(result.baseline, same(result.basis.configuration));
      expect(result.baseline, same(baseline));
    }
    expect(session.state, same(before));
  });
  test('수락 후 개정만 증가하고 과거 관찰값·기준은 변경되지 않는다', () {
    final before = session.state;
    final prepared = ready('new');
    final result = session.applyPreparedGeometryChange(
      prepared,
    ) as AppliedProductGeometryChange;
    expect(result.state, same(session.state));
    expect(result.configuration, same(session.state.configuration));
    expect(result.summary, same(prepared.summary));
    expect(session.state.revision, 1);
    expect(session.state.sessionId, same(before.sessionId));
    expect(before.revision, 0);
    expect(before.configuration, same(baseline));
    expect(prepared.basis.revision, 0);
    session.close();
    expect(result.state.isClosed, isFalse);
    expect(session.state.isClosed, isTrue);
    expect(session.state.revision, 1);
    expect(session.state.configuration, same(result.configuration));
  });
  test('실제 전체 A→B→A 복원 뒤 최초 Ready는 개정 차이만으로 거부한다', () {
    baseline = baseline.copyWith(
      appliedGeometries: [
        ...baseline.appliedGeometries,
        appliedMillimeterDesign('alternate', ['title']),
      ],
    );
    session = ProductDesignEditSession.open(configuration: baseline);
    final oldReady = ready('alternate');
    final competing = ready('alternate');
    final first = session.applyPreparedGeometryChange(competing);
    expect(first, isA<AppliedProductGeometryChange>());
    final back = session.prepareGeometryChange(
      ReviseAppliedGeometry(
        sourceAppliedGeometryId: 'alternate',
        proposedGeometry: baseline.appliedGeometries.first,
        targets: [targetPreservingAreas('p1')],
      ),
    ) as ReadyProductGeometryChange;
    final restored = session.applyPreparedGeometryChange(
      back,
    ) as AppliedProductGeometryChange;
    expect(restored.configuration, baseline, reason: '스냅샷과 순서를 포함한 실제 전체 A 복원');
    expect(session.state.revision, 2);
    final rejected = session.applyPreparedGeometryChange(
      oldReady,
    ) as RejectedProductGeometryChange;
    expect(
      rejected.issues.single.code,
      ProductGeometryChangeApplicationCode.staleEditRevision,
    );
    final detail =
        rejected.issues.single.details as EditRevisionMismatchDetails;
    expect(detail.expectedRevision, 2);
    expect(detail.actualRevision, 0);
    expect(session.state, same(restored.state));
  });
  test('같은 기준의 두 요청은 하나만 수락하며 동일 Ready도 다시 수락하지 않는다', () {
    final p = ready('p');
    final q = ready('q');
    final applied =
        session.applyPreparedGeometryChange(p) as AppliedProductGeometryChange;
    for (final attempt in [q, p]) {
      final rejected = session.applyPreparedGeometryChange(
        attempt,
      ) as RejectedProductGeometryChange;
      expect(
        rejected.issues.map((i) => i.code),
        unorderedEquals([
          ProductGeometryChangeApplicationCode.staleEditRevision,
          ProductGeometryChangeApplicationCode.baselineConfigurationMismatch,
        ]),
      );
      expect(rejected.state, same(applied.state));
      expect(session.state, same(applied.state));
      expect(() => rejected.issues.clear(), throwsUnsupportedError);
    }
  });
  test('닫힌 객체는 새 준비를 금지하고 지연 반영은 닫힘 진단만 반환한다', () {
    final prepared = ready('next');
    final before = session.state;
    session.close();
    final closed = session.state;
    session.close();
    expect(session.state, same(closed));
    expect(before.isClosed, isFalse);
    expect(closed.configuration, same(before.configuration));
    expect(closed.revision, 0);
    expect(
      () => session.prepareGeometryChange(prepared.request),
      throwsStateError,
    );
    final rejected = session.applyPreparedGeometryChange(
      prepared,
    ) as RejectedProductGeometryChange;
    expect(
      rejected.issues.single.code,
      ProductGeometryChangeApplicationCode.closedEditSession,
    );
    expect(rejected.issues.single.fieldPath, 'current.isClosed');
    final reopened = ProductDesignEditSession.open(
      configuration: closed.configuration,
    );
    final foreign = reopened.applyPreparedGeometryChange(
      prepared,
    ) as RejectedProductGeometryChange;
    expect(
      foreign.issues.single.code,
      ProductGeometryChangeApplicationCode.differentEditSession,
    );
    expect(reopened.state.revision, 0);
  });
  test('독립 세션의 수락과 교차 거부는 다른 세션의 개정·준비를 변경하지 않는다', () {
    final other = ProductDesignEditSession.open(configuration: baseline);
    final otherBefore = other.state;
    final a = ready('a');
    final b =
        other.prepareGeometryChange(a.request) as ReadyProductGeometryChange;
    final cross =
        other.applyPreparedGeometryChange(a) as RejectedProductGeometryChange;
    expect(
      cross.issues.single.code,
      ProductGeometryChangeApplicationCode.differentEditSession,
    );
    final details = cross.issues.single.details as EditSessionMismatchDetails;
    expect(details.expectedSessionId, same(other.state.sessionId));
    expect(details.actualSessionId, same(session.state.sessionId));
    final accepted = session.applyPreparedGeometryChange(a);
    expect(accepted, isA<AppliedProductGeometryChange>());
    expect(other.state, same(otherBefore));
    expect(
      other.applyPreparedGeometryChange(b),
      isA<AppliedProductGeometryChange>(),
    );
    expect(other.state.revision, 1);
    expect(session.state.revision, 1);
  });
  test('입력 값 생성 실패는 세션의 구성과 개정을 바꾸지 않는다', () {
    final before = session.state;
    expect(
      () => TextAreaInput(
        areaId: 'title',
        sourceText: '',
        lineBreak: const AutomaticLineBreak(),
      ),
      throwsA(isA<TextInputValidationException>()),
    );
    expect(session.state, same(before));
  });
}
