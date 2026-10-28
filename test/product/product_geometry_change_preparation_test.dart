import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/product_examples.dart';
import '../support/product_geometry_changes.dart';

void main() {
  late ProductDesignConfiguration baseline;
  setUp(() => baseline = twoProductsSharingTitleGeometry());
  ReviseAppliedGeometry revise({
    String id = 'next',
    List<ProductGeometryTarget>? targets,
  }) => ReviseAppliedGeometry(
    sourceAppliedGeometryId: 'old',
    proposedGeometry: appliedMillimeterDesign(id, ['title']),
    targets: targets ?? [targetPreservingAreas('p1')],
  );
  test('공유 도안의 한 제품만 준비하며 비대상과 기준 값은 보존한다', () {
    final before = baseline.toJson();
    final request = revise();
    final result = prepareProductGeometryChange(
      baseline: baseline,
      request: request,
    ) as ReadyProductGeometryChange;
    expect(result.baseline, same(baseline));
    expect(result.request, same(request));
    expect(result.targetProductIds, {'p1'});
    final summary = result.summary.products.single;
    expect(summary.productId, 'p1');
    expect(summary.previousAppliedGeometryId, 'old');
    expect(summary.proposedAppliedGeometryId, 'next');
    expect(summary.retainedAreaIds, ['title']);
    expect(summary.changedFieldPaths, isEmpty);
    expect(baseline.products[1].textInputs.single.sourceText, 'SECOND');
    expect(baseline.toJson(), before);
    expect(() => result.targetProductIds.add('p2'), throwsUnsupportedError);
  });
  test('명시 복수 대상은 제안 ID 하나를 공유하고 기준 제품 순서로 요약한다', () {
    final result = prepareProductGeometryChange(
      baseline: baseline,
      request: revise(
        targets: [targetPreservingAreas('p2'), targetPreservingAreas('p1')],
      ),
    ) as ReadyProductGeometryChange;
    expect(result.summary.products.map((s) => s.productId), ['p1', 'p2']);
    expect(result.summary.products.map((s) => s.proposedAppliedGeometryId), [
      'next',
      'next',
    ]);
    expect(baseline.appliedGeometries.map((g) => g.appliedGeometryId), ['old']);
  });
  test('같은 기존 ID와 동등한 내용은 유효 무변경으로 준비한다', () {
    final result = prepareProductGeometryChange(
      baseline: baseline,
      request: revise(id: 'old'),
    );
    expect(result, isA<UnchangedProductGeometryChange>());
    expect(result.summary.products.single.proposedAppliedGeometryId, 'old');
  });
  test('동일한 내용에도 새 ID를 명시하면 참조 변경을 존중한다', () {
    expect(
      prepareProductGeometryChange(baseline: baseline, request: revise()),
      isA<ReadyProductGeometryChange>(),
    );
  });
  test('미사용 기존 제안 스냅샷을 내용이 같을 때 재사용한다', () {
    baseline = baseline.copyWith(
      appliedGeometries: [
        ...baseline.appliedGeometries,
        appliedMillimeterDesign('next', ['title']),
      ],
    );
    final result = prepareProductGeometryChange(
      baseline: baseline,
      request: revise(),
    );
    expect(result, isA<ReadyProductGeometryChange>());
    expect(result.baseline.appliedGeometries.length, 2);
  });
  test('같은 ID의 다른 내용은 기준 위치와 실제 변경 경로로 거부한다', () {
    final old = baseline.appliedGeometries.single;
    final proposed = AppliedDesignGeometry(
      appliedGeometryId: 'old',
      geometry: old.geometry.copyWith(
        outline: CircleBoundary(center: Point2(x: 0, y: 0), radius: 31),
      ),
    );
    final result = prepareProductGeometryChange(
      baseline: baseline,
      request: ReviseAppliedGeometry(
        sourceAppliedGeometryId: 'old',
        proposedGeometry: proposed,
        targets: [targetPreservingAreas('p1')],
      ),
    ) as BlockedProductGeometryChange;
    final issue = result.issues.single;
    expect(issue.code, ProductGeometryChangeCode.snapshotContentConflict);
    expect(issue.fieldPath, 'request.proposedGeometry');
    final details = issue.details as ChangeSnapshotConflictDetails;
    expect(details.appliedGeometryId, 'old');
    expect(details.baselineIndex, 0);
    expect(details.changedFieldPaths, ['geometry.outline.radius']);
  });
  test('빈 대상은 내용이 같아도 무변경이 아니라 정상 거부다', () {
    final result = prepareProductGeometryChange(
      baseline: baseline,
      request: revise(id: 'old', targets: []),
    ) as BlockedProductGeometryChange;
    expect(result.issues.single.code, ProductGeometryChangeCode.emptyTargetSet);
    expect(result.issues.single.fieldPath, 'request.targets');
  });
  test('중복 대상은 어느 대응도 선택하지 않으며 없는 제품을 독립 보고한다', () {
    final result = prepareProductGeometryChange(
      baseline: baseline,
      request: revise(
        targets: [
          targetPreservingAreas('p1'),
          targetPreservingAreas('p1'),
          targetPreservingAreas('absent'),
        ],
      ),
    ) as BlockedProductGeometryChange;
    expect(
      result.issues.map((i) => i.code),
      unorderedEquals([
        ProductGeometryChangeCode.duplicateTargetProduct,
        ProductGeometryChangeCode.unknownTargetProduct,
      ]),
    );
    expect(result.summary.products, isEmpty);
    final duplicate =
        result.issues
                .singleWhere(
                  (i) =>
                      i.code ==
                      ProductGeometryChangeCode.duplicateTargetProduct,
                )
                .details
            as ChangeDuplicateTargetsDetails;
    expect(duplicate.targetIndices, [0, 1]);
  });
  test('없는 부분 수정 기준은 종속 영역 누락으로 오진하지 않는다', () {
    final result = prepareProductGeometryChange(
      baseline: baseline,
      request: ReviseAppliedGeometry(
        sourceAppliedGeometryId: 'absent',
        proposedGeometry: appliedMillimeterDesign('next', ['new']),
        targets: [targetPreservingAreas('p1')],
      ),
    ) as BlockedProductGeometryChange;
    expect(
      result.issues.single.code,
      ProductGeometryChangeCode.unknownSourceAppliedGeometry,
    );
  });
  test('부분 수정 대상의 실제 참조가 다르면 기대와 실제를 구분한다', () {
    baseline = baseline.copyWith(
      appliedGeometries: [
        ...baseline.appliedGeometries,
        appliedMillimeterDesign('other', ['title']),
      ],
      products: [
        baseline.products.first,
        baseline.products.last.copyWith(appliedGeometryId: 'other'),
      ],
    );
    final result = prepareProductGeometryChange(
      baseline: baseline,
      request: revise(targets: [targetPreservingAreas('p2')]),
    ) as BlockedProductGeometryChange;
    expect(
      result.issues.single.fieldPath,
      'baseline.products[1].appliedGeometryId',
    );
    final details =
        result.issues.single.details as ChangeAppliedReferenceDetails;
    expect(details.expectedAppliedGeometryId, 'old');
    expect(details.actualAppliedGeometryId, 'other');
  });
  test('교체 대상들의 이전 적용 ID가 달라도 명시 대응으로 준비한다', () {
    baseline = baseline.copyWith(
      appliedGeometries: [
        ...baseline.appliedGeometries,
        appliedMillimeterDesign('other', ['title']),
      ],
      products: [
        baseline.products.first,
        baseline.products.last.copyWith(appliedGeometryId: 'other'),
      ],
    );
    final result = prepareProductGeometryChange(
      baseline: baseline,
      request: ReplaceAppliedGeometry(
        proposedGeometry: appliedMillimeterDesign('next', ['heading']),
        targets: [
          for (final id in ['p1', 'p2'])
            ProductGeometryTarget(
              productId: id,
              areaMappings: [
                const TextAreaInputMapping(
                  fromAreaId: 'title',
                  toAreaId: 'heading',
                ),
              ],
              newTextInputs: [],
              removedInputAreaIds: [],
            ),
        ],
      ),
    );
    expect(result, isA<ReadyProductGeometryChange>());
    expect(result.summary.products.map((s) => s.previousAppliedGeometryId), [
      'old',
      'other',
    ]);
  });
  test('한 제품의 모호함과 다른 제품의 미완료 선택을 함께 수집한다', () {
    final request = ReplaceAppliedGeometry(
      proposedGeometry: appliedMillimeterDesign('next', ['title']),
      targets: [
        ProductGeometryTarget(
          productId: 'p1',
          areaMappings: [
            const TextAreaInputMapping(fromAreaId: 'title', toAreaId: 'title'),
            const TextAreaInputMapping(fromAreaId: 'title', toAreaId: 'title'),
          ],
          newTextInputs: [],
          removedInputAreaIds: [],
        ),
        targetPreservingAreas('p2'),
      ],
    );
    final result = prepareProductGeometryChange(
      baseline: baseline,
      request: request,
    ) as BlockedProductGeometryChange;
    expect(
      result.issues
          .where((i) => i.details is ChangeAreaInputDetails)
          .map((i) => (i.details as ChangeAreaInputDetails).productId),
      ['p2'],
    );
    expect(
      result.issues.map((i) => i.code),
      containsAll([
        ProductGeometryChangeCode.duplicateSourceMapping,
        ProductGeometryChangeCode.duplicateTargetMapping,
        ProductGeometryChangeCode.unresolvedSourceInput,
      ]),
    );
    expect(baseline.products.map((p) => p.appliedGeometryId), ['old', 'old']);
  });
  test('반복 준비·거부와 요약 외부 변경은 기준/요청에 영향을 주지 않는다', () {
    final request = revise();
    final before = baseline.toJson();
    final a = prepareProductGeometryChange(
      baseline: baseline,
      request: request,
    );
    final b = prepareProductGeometryChange(
      baseline: baseline,
      request: request,
    );
    expect(a.summary, b.summary);
    expect(() => a.summary.products.clear(), throwsUnsupportedError);
    expect(
      () => a.summary.products.single.retainedAreaIds.clear(),
      throwsUnsupportedError,
    );
    expect(
      () => a.summary.products.single.resultingInputAreaIds.clear(),
      throwsUnsupportedError,
    );
    final blocked = prepareProductGeometryChange(
      baseline: baseline,
      request: revise(targets: []),
    ) as BlockedProductGeometryChange;
    expect(() => blocked.issues.clear(), throwsUnsupportedError);
    expect(baseline.toJson(), before);
    expect(request.targets.single.productId, 'p1');
  });
}
