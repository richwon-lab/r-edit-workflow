import 'package:meta/meta.dart';
import 'package:r_edit_workflow/src/design/applied_design_geometry.dart';
import 'package:r_edit_workflow/src/design/design_errors.dart';
import 'package:r_edit_workflow/src/design/text_area_input_validation.dart';
import 'package:r_edit_workflow/src/product/applied_geometry_id_consistency.dart';
import 'package:r_edit_workflow/src/product/product_geometry_change_errors.dart';
import 'package:r_edit_workflow/src/product/product_geometry_change_summary.dart';
import 'package:r_edit_workflow/src/product/product_geometry_target.dart';
import 'package:r_edit_workflow/src/product/product_input.dart';
import 'package:r_edit_workflow/src/product/text_area_input_mapping.dart';
import 'package:r_edit_workflow/src/text_area_input.dart';

enum _SelectionKind { retained, mapping, newInput, removed }

typedef _Selection = ({String path, _SelectionKind kind});

/// 준비 내부에서 한 제품의 선택을 검사한다. 불완전 후보 객체를 만들지 않는다.
/// 부분 입력 대조의 종속 누락은 억제하되 독립 신규 입력/미대응 오류는 수집한다.
@internal
({
  List<TextAreaInput>? inputs,
  List<ProductGeometryChangeIssue> issues,
  ProductGeometryTargetSummary? summary,
})
prepareTargetTextInputs({
  required ProductInput product,
  required int productIndex,
  required ProductGeometryTarget target,
  required int targetIndex,
  required AppliedDesignGeometry previous,
  required AppliedDesignGeometry proposed,
  required bool revise,
}) {
  final issues = <ProductGeometryChangeIssue>[];
  final prefix = 'request.targets[$targetIndex]';
  final oldIds = previous.geometry.textAreas.map((area) => area.areaId).toSet();
  final newIds = proposed.geometry.textAreas.map((area) => area.areaId).toSet();
  final retained = revise ? oldIds.intersection(newIds) : <String>{};
  final sourceSelections = <String, List<_Selection>>{};
  final targetSelections = <String, List<_Selection>>{};
  void select(
    Map<String, List<_Selection>> choices,
    String id,
    String path,
    _SelectionKind kind,
  ) {
    choices.putIfAbsent(id, () => []).add((path: path, kind: kind));
  }

  ChangeAreaSelectionDetails detail(
    String id,
    ChangeAreaSide side,
    List<String> paths,
  ) => ChangeAreaSelectionDetails(
    productId: product.productId,
    previousAppliedGeometryId: previous.appliedGeometryId,
    proposedAppliedGeometryId: proposed.appliedGeometryId,
    areaId: id,
    side: side,
    selectionPaths: paths,
  );
  void areaIssue(
    ProductGeometryChangeCode code,
    String id,
    ChangeAreaSide side,
    List<String> paths,
  ) {
    issues.add(
      ProductGeometryChangeIssue(
        code: code,
        fieldPath: paths.last,
        details: detail(id, side, paths),
      ),
    );
  }

  bool validId(String id, String path) {
    if (id.isNotEmpty) return true;
    issues.add(
      ProductGeometryChangeIssue(
        code: ProductGeometryChangeCode.invalidChangeIdentifier,
        fieldPath: path,
        details: ChangeIdentifierDetails(id),
      ),
    );
    return false;
  }

  void wrapAreaIssue(DesignValidationIssue cause, String path) {
    issues.add(
      ProductGeometryChangeIssue(
        code: ProductGeometryChangeCode.areaInputMismatch,
        fieldPath: path,
        details: ChangeAreaInputDetails(
          productId: product.productId,
          previousAppliedGeometryId: previous.appliedGeometryId,
          proposedAppliedGeometryId: proposed.appliedGeometryId,
          cause: cause,
        ),
      ),
    );
  }

  for (final (index, input) in product.textInputs.indexed) {
    if (retained.contains(input.areaId)) {
      final path = 'baseline.products[$productIndex].textInputs[$index].areaId';
      select(sourceSelections, input.areaId, path, _SelectionKind.retained);
      select(targetSelections, input.areaId, path, _SelectionKind.retained);
    }
  }
  for (final (index, mapping) in target.areaMappings.indexed) {
    final sourcePath = '$prefix.areaMappings[$index].fromAreaId';
    final targetPath = '$prefix.areaMappings[$index].toAreaId';
    if (validId(mapping.fromAreaId, sourcePath)) {
      select(
        sourceSelections,
        mapping.fromAreaId,
        sourcePath,
        _SelectionKind.mapping,
      );
      if (!oldIds.contains(mapping.fromAreaId)) {
        areaIssue(
          ProductGeometryChangeCode.unknownSourceArea,
          mapping.fromAreaId,
          ChangeAreaSide.source,
          [sourcePath],
        );
      }
    }
    if (validId(mapping.toAreaId, targetPath)) {
      // 유일한 공급이 성립하지 않아도 이 영역의 대응 의도는 알려져 있다.
      // 같은 모호함을 missingAreaInput으로 다시 보고하지 않는다.
      select(
        targetSelections,
        mapping.toAreaId,
        targetPath,
        _SelectionKind.mapping,
      );
      if (!newIds.contains(mapping.toAreaId)) {
        areaIssue(
          ProductGeometryChangeCode.unknownTargetArea,
          mapping.toAreaId,
          ChangeAreaSide.target,
          [targetPath],
        );
      }
    }
  }
  for (final (index, id) in target.removedInputAreaIds.indexed) {
    final path = '$prefix.removedInputAreaIds[$index]';
    if (!validId(id, path)) continue;
    select(sourceSelections, id, path, _SelectionKind.removed);
    if (!oldIds.contains(id)) {
      areaIssue(
        ProductGeometryChangeCode.unknownSourceArea,
        id,
        ChangeAreaSide.source,
        [path],
      );
    }
  }
  for (final (index, input) in target.newTextInputs.indexed) {
    select(
      targetSelections,
      input.areaId,
      '$prefix.newTextInputs[$index].areaId',
      _SelectionKind.newInput,
    );
  }
  // 신규 값의 미정의/중복은 기존 연결 검사의 코드와 상세를 보존한다.
  for (final cause in validateTextAreaInputs(
    design: proposed.geometry,
    inputs: target.newTextInputs,
  )) {
    if (cause.code == DesignErrorCode.missingAreaInput) continue;
    wrapAreaIssue(
      cause,
      '$prefix.newTextInputs${cause.fieldPath.substring('inputs'.length)}',
    );
  }
  void checkConflicts(
    Map<String, List<_Selection>> selections,
    ChangeAreaSide side,
  ) {
    for (final entry in selections.entries) {
      final choices = entry.value;
      if (choices.length < 2) continue;
      if (side == ChangeAreaSide.target &&
          choices.every((c) => c.kind == _SelectionKind.newInput)) {
        continue;
      }
      final mappingsOnly = choices.every(
        (c) => c.kind == _SelectionKind.mapping,
      );
      final code = mappingsOnly
          ? (side == ChangeAreaSide.source
                ? ProductGeometryChangeCode.duplicateSourceMapping
                : ProductGeometryChangeCode.duplicateTargetMapping)
          : ProductGeometryChangeCode.conflictingInputDisposition;
      areaIssue(code, entry.key, side, choices.map((c) => c.path).toList());
    }
  }

  checkConflicts(sourceSelections, ChangeAreaSide.source);
  checkConflicts(targetSelections, ChangeAreaSide.target);
  final inputs = <TextAreaInput>[];
  final kept = <String>[];
  final mapped = <TextAreaInputMapping>[];
  final removed = <String>[];
  for (final (index, input) in product.textInputs.indexed) {
    final choices = sourceSelections[input.areaId] ?? const <_Selection>[];
    if (choices.isEmpty) {
      areaIssue(
        ProductGeometryChangeCode.unresolvedSourceInput,
        input.areaId,
        ChangeAreaSide.source,
        ['baseline.products[$productIndex].textInputs[$index].areaId'],
      );
      continue;
    }
    if (choices.length != 1) continue;
    switch (choices.single.kind) {
      case _SelectionKind.retained:
        if (targetSelections[input.areaId]!.length == 1) {
          inputs.add(input);
          kept.add(input.areaId);
        }
      case _SelectionKind.mapping:
        final mapping = target.areaMappings.singleWhere(
          (m) => m.fromAreaId == input.areaId,
        );
        if (newIds.contains(mapping.toAreaId) &&
            targetSelections[mapping.toAreaId]!.length == 1) {
          inputs.add(input.copyWith(areaId: mapping.toAreaId));
          mapped.add(mapping);
        }
      case _SelectionKind.removed:
        removed.add(input.areaId);
      case _SelectionKind.newInput:
        throw StateError('신규 공급은 이전 입력의 처리 선택일 수 없습니다.');
    }
  }
  final added = <String>[];
  for (final input in target.newTextInputs) {
    if (newIds.contains(input.areaId) &&
        targetSelections[input.areaId]!.length == 1) {
      inputs.add(input);
      added.add(input.areaId);
    }
  }
  for (final cause in validateTextAreaInputs(
    design: proposed.geometry,
    inputs: inputs,
  )) {
    if (cause.code != DesignErrorCode.missingAreaInput) {
      throw StateError('선택 검사와 입력 투영이 일치하지 않습니다.');
    }
    final id = (cause.details! as DesignIdentifierDetails).identifier;
    if (targetSelections.containsKey(id)) continue;
    wrapAreaIssue(
      cause,
      'request.proposedGeometry.geometry.${cause.fieldPath}',
    );
  }
  if (issues.isNotEmpty) {
    return (inputs: null, issues: List.unmodifiable(issues), summary: null);
  }
  return (
    inputs: List.unmodifiable(inputs),
    issues: const [],
    summary: ProductGeometryTargetSummary(
      productId: product.productId,
      previousAppliedGeometryId: previous.appliedGeometryId,
      proposedAppliedGeometryId: proposed.appliedGeometryId,
      retainedAreaIds: kept,
      areaMappings: mapped,
      newInputAreaIds: added,
      removedInputAreaIds: removed,
      resultingInputAreaIds: inputs.map((input) => input.areaId).toList(),
      changedFieldPaths: collectAppliedGeometryContentChanges(
        previous,
        proposed,
      ),
    ),
  );
}
