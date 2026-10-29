import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:r_edit_workflow/src/product/product_design_edit_validation.dart';
import 'package:test/test.dart';

import '../support/product_examples.dart';
import '../support/product_geometry_changes.dart';

void main() {
  late ProductDesignConfiguration baseline;
  late ProductDesignConfiguration different;
  late ProductDesignEditSession session;
  late ProductDesignEditBasis basis;
  setUp(() {
    baseline = twoProductsSharingTitleGeometry();
    different = baseline.copyWith(
      products: [
        baseline.products.first.copyWith(
          textInputs: [automaticAreaText('title', 'CHANGED')],
        ),
        baseline.products.last,
      ],
    );
    session = ProductDesignEditSession.open(configuration: baseline);
    basis = session
        .prepareGeometryChange(
          ReviseAppliedGeometry(
            sourceAppliedGeometryId: 'old',
            proposedGeometry: appliedMillimeterDesign('next', ['title']),
            targets: [targetPreservingAreas('p1')],
          ),
        )
        .basis;
  });
  for (final pair in [(0, false), (1, false), (0, true), (1, true)]) {
    test('같은 세션 개정 ${pair.$1}·내용 변경 ${pair.$2}를 독립 대조한다', () {
      final configuration = pair.$2
          ? different
          : ProductDesignConfiguration.fromJson(baseline.toJson());
      final issues = validateProductDesignEditBasis(
        currentSessionId: session.state.sessionId,
        currentRevision: pair.$1,
        isClosed: false,
        currentConfiguration: configuration,
        basis: basis,
      );
      expect(
        issues.map((i) => i.code),
        unorderedEquals([
          if (pair.$1 != 0)
            ProductGeometryChangeApplicationCode.staleEditRevision,
          if (pair.$2)
            ProductGeometryChangeApplicationCode.baselineConfigurationMismatch,
        ]),
      );
      if (pair.$2) {
        final issue = issues.singleWhere(
          (i) =>
              i.code ==
              ProductGeometryChangeApplicationCode
                  .baselineConfigurationMismatch,
        );
        final detail = issue.details as EditBaselineMismatchDetails;
        expect(issue.fieldPath, 'prepared.basis.configuration');
        expect(detail.expectedPath, 'current.configuration');
        expect(detail.actualPath, 'prepared.basis.configuration');
        expect(detail.currentRevision, pair.$1);
        expect(detail.preparedRevision, 0);
        expect(issue.toString(), isNot(contains('CHANGED')));
      }
      expect(() => issues.clear(), throwsUnsupportedError);
    });
  }
  test('닫힘은 다른 토큰·개정·내용에 종속 진단을 추가하지 않는다', () {
    final other = ProductDesignEditSession.open(configuration: different);
    final issues = validateProductDesignEditBasis(
      currentSessionId: other.state.sessionId,
      currentRevision: 5,
      isClosed: true,
      currentConfiguration: different,
      basis: basis,
    );
    expect(
      issues.single.code,
      ProductGeometryChangeApplicationCode.closedEditSession,
    );
  });
  test('다른 세션이면 개정과 내용을 비교하지 않는다', () {
    final other = ProductDesignEditSession.open(configuration: different);
    final issues = validateProductDesignEditBasis(
      currentSessionId: other.state.sessionId,
      currentRevision: 5,
      isClosed: false,
      currentConfiguration: different,
      basis: basis,
    );
    expect(
      issues.single.code,
      ProductGeometryChangeApplicationCode.differentEditSession,
    );
  });
  test('실행 int 마지막 증가를 허용하고 표현 불가 증가는 채택 전에 중단한다', () {
    const last = 0x7fffffffffffffff;
    final lastCommit = prepareProductDesignEditCommit(
      revision: last - 1,
      candidate: different,
    );
    expect(lastCommit.revision, last);
    expect(lastCommit.configuration, same(different));
    var current = (revision: last, configuration: baseline);
    expect(
      () => current = prepareProductDesignEditCommit(
        revision: current.revision,
        candidate: different,
      ),
      throwsStateError,
    );
    expect(current.revision, last);
    expect(current.configuration, same(baseline));
  });
  test('내부 검사 인자의 음수 개정은 정상 거부 진단으로 숨기지 않는다', () {
    expect(
      () => prepareProductDesignEditCommit(revision: -1, candidate: different),
      throwsA(
        isA<ArgumentError>()
            .having((e) => e.name, '인자', 'revision')
            .having((e) => e.invalidValue, '값', -1),
      ),
    );
    expect(
      () => validateProductDesignEditBasis(
        currentSessionId: session.state.sessionId,
        currentRevision: -1,
        isClosed: false,
        currentConfiguration: baseline,
        basis: basis,
      ),
      throwsA(
        isA<ArgumentError>().having((e) => e.name, '인자', 'currentRevision'),
      ),
    );
  });
}
