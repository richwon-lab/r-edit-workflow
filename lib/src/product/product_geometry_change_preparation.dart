part of 'product_design_edit_session.dart';

/// 기준 값을 변경하지 않고 명시 대상·입력 대응을 검사해 전체 후보를 준비한다.
/// 정상 거부는 Blocked, 유효한 전체 값이 같으면 Unchanged, 다르면 Ready다.
/// 현재 상태 반영/세션 개정/과거 ID 재사용/배치·제작·저장 판정은 하지 않는다.
/// Error를 정상 거부로 바꾸거나 로깅하지 않는다. 모든 인덱스는 0 기반이다.
@useResult
ProductGeometryChangePreparation _prepareProductGeometryChange({
  required ProductDesignEditBasis basis,
  required ProductGeometryChangeRequest request,
}) {
  final baseline = basis.configuration;
  final issues = <ProductGeometryChangeIssue>[];
  final summaries = <ProductGeometryTargetSummary>[];
  final proposed = request.proposedGeometry;
  final snapshots = baseline.appliedGeometries.toList();
  final existingIndex = snapshots.indexWhere(
    (s) => s.appliedGeometryId == proposed.appliedGeometryId,
  );
  if (existingIndex >= 0 && snapshots[existingIndex] != proposed) {
    final changed = collectAppliedGeometryContentChanges(
      snapshots[existingIndex],
      proposed,
    );
    if (changed.isEmpty) throw StateError('값 비교와 스냅샷 변경 경로가 일치하지 않습니다.');
    issues.add(
      ProductGeometryChangeIssue(
        code: ProductGeometryChangeCode.snapshotContentConflict,
        fieldPath: 'request.proposedGeometry',
        details: ChangeSnapshotConflictDetails(
          appliedGeometryId: proposed.appliedGeometryId,
          baselineIndex: existingIndex,
          changedFieldPaths: changed,
        ),
      ),
    );
  } else if (existingIndex < 0) {
    snapshots.add(proposed);
  }
  if (request.targets.isEmpty) {
    issues.add(
      ProductGeometryChangeIssue(
        code: ProductGeometryChangeCode.emptyTargetSet,
        fieldPath: 'request.targets',
        details: const ChangeEmptyTargetsDetails(),
      ),
    );
  }
  var usableSource = true;
  if (request case ReviseAppliedGeometry(:final sourceAppliedGeometryId)) {
    if (sourceAppliedGeometryId.isEmpty) {
      usableSource = false;
      issues.add(
        ProductGeometryChangeIssue(
          code: ProductGeometryChangeCode.invalidChangeIdentifier,
          fieldPath: 'request.sourceAppliedGeometryId',
          details: ChangeIdentifierDetails(sourceAppliedGeometryId),
        ),
      );
    } else if (!baseline.appliedGeometries.any(
      (g) => g.appliedGeometryId == sourceAppliedGeometryId,
    )) {
      usableSource = false;
      issues.add(
        ProductGeometryChangeIssue(
          code: ProductGeometryChangeCode.unknownSourceAppliedGeometry,
          fieldPath: 'request.sourceAppliedGeometryId',
          details: ChangeSourceDetails(sourceAppliedGeometryId),
        ),
      );
    }
  }
  final targetIndices = <String, List<int>>{};
  for (final (index, target) in request.targets.indexed) {
    if (target.productId.isEmpty) {
      issues.add(
        ProductGeometryChangeIssue(
          code: ProductGeometryChangeCode.invalidChangeIdentifier,
          fieldPath: 'request.targets[$index].productId',
          details: ChangeIdentifierDetails(target.productId),
        ),
      );
    } else {
      targetIndices.putIfAbsent(target.productId, () => []).add(index);
    }
  }
  final productIndices = {
    for (final (index, product) in baseline.products.indexed)
      product.productId: index,
  };
  for (final entry in targetIndices.entries) {
    if (entry.value.length > 1) {
      issues.add(
        ProductGeometryChangeIssue(
          code: ProductGeometryChangeCode.duplicateTargetProduct,
          fieldPath: 'request.targets[${entry.value.last}].productId',
          details: ChangeDuplicateTargetsDetails(
            productId: entry.key,
            targetIndices: entry.value,
          ),
        ),
      );
    }
    if (!productIndices.containsKey(entry.key)) {
      for (final index in entry.value) {
        issues.add(
          ProductGeometryChangeIssue(
            code: ProductGeometryChangeCode.unknownTargetProduct,
            fieldPath: 'request.targets[$index].productId',
            details: ChangeTargetDetails(
              productId: entry.key,
              targetIndex: index,
            ),
          ),
        );
      }
    }
  }
  final products = <ProductInput>[];
  for (final (index, product) in baseline.products.indexed) {
    final targetMatches = targetIndices[product.productId];
    if (targetMatches == null || targetMatches.length != 1) {
      products.add(product);
      continue;
    }
    final targetIndex = targetMatches.single;
    if (request case ReviseAppliedGeometry(:final sourceAppliedGeometryId)) {
      if (!usableSource) {
        products.add(product);
        continue;
      }
      if (product.appliedGeometryId != sourceAppliedGeometryId) {
        issues.add(
          ProductGeometryChangeIssue(
            code: ProductGeometryChangeCode.unexpectedAppliedGeometry,
            fieldPath: 'baseline.products[$index].appliedGeometryId',
            details: ChangeAppliedReferenceDetails(
              productId: product.productId,
              productIndex: index,
              expectedAppliedGeometryId: sourceAppliedGeometryId,
              actualAppliedGeometryId: product.appliedGeometryId,
            ),
          ),
        );
        products.add(product);
        continue;
      }
    }
    final previous = baseline.appliedGeometries.singleWhere(
      (g) => g.appliedGeometryId == product.appliedGeometryId,
    );
    final preparation = prepareTargetTextInputs(
      product: product,
      productIndex: index,
      target: request.targets[targetIndex],
      targetIndex: targetIndex,
      previous: previous,
      proposed: proposed,
      revise: request is ReviseAppliedGeometry,
    );
    issues.addAll(preparation.issues);
    final inputs = preparation.inputs;
    if (inputs == null) {
      products.add(product);
    } else {
      products.add(
        product.copyWith(
          appliedGeometryId: proposed.appliedGeometryId,
          textInputs: inputs,
        ),
      );
      summaries.add(preparation.summary!);
    }
  }
  final summary = ProductGeometryChangeSummary(products: summaries);
  if (issues.isNotEmpty) {
    return BlockedProductGeometryChange._(basis, request, summary, issues);
  }
  final configurationIssues = validateProductDesignConfiguration(
    appliedGeometries: snapshots,
    products: products,
  );
  if (configurationIssues.isNotEmpty) {
    return BlockedProductGeometryChange._(basis, request, summary, [
      for (final cause in configurationIssues)
        ProductGeometryChangeIssue(
          code: ProductGeometryChangeCode.candidateConfigurationInvalid,
          fieldPath: 'candidate.${cause.fieldPath}',
          details: ChangeConfigurationDetails(cause),
        ),
    ]);
  }
  // 유효하지 않은 중간 구성은 만들지 않는다. 전체 목록 검증 이후 생성자는 같은 계약을 재검사한다.
  final candidate = ProductDesignConfiguration(
    appliedGeometries: snapshots,
    products: products,
  );
  if (candidate == baseline) {
    return UnchangedProductGeometryChange._(basis, request, summary);
  }
  return ReadyProductGeometryChange._(basis, request, summary, candidate);
}
