import 'package:r_edit_workflow/src/design/applied_design_geometry.dart';
import 'package:r_edit_workflow/src/design/design_errors.dart';
import 'package:r_edit_workflow/src/design/text_area_input_validation.dart';
import 'package:r_edit_workflow/src/product/product_design_errors.dart';
import 'package:r_edit_workflow/src/product/product_input.dart';

/// 전달 목록의 소유 ID·참조·영역 입력을 검사하고 수정 불가 issue를 반환한다.
/// 입력 순서를 바꾸지 않으며 오류 순서는 계약이 아니다.
/// 없는/모호한 참조에서는 영역 대조를 생략하되 입력 중복은 독립 검사한다.
/// 성공은 현재 참조 정합성만 뜻한다. 과거 ID 불변·배치·제작·저장은 보장하지 않는다.
/// 적용 ID와 제품 ID는 각각의 소유 목록에서 유일해야 하며 서로 별도 이름 공간이다.
/// 제품 입력 오류는 `products[i].textInputs[j]`, 누락 정의는 `appliedGeometries[k].geometry.textAreas[j]`를 가리킨다.
/// 모든 인덱스는 전달 목록의 0 기반 위치다. 하위 issue의 원래 코드·경로·상세도 함께 보존한다.
List<ProductDesignIssue> validateProductDesignConfiguration({
  required List<AppliedDesignGeometry> appliedGeometries,
  required List<ProductInput> products,
}) {
  final issues = <ProductDesignIssue>[];
  final appliedIndices = <String, List<int>>{};
  for (var i = 0; i < appliedGeometries.length; i++) {
    final id = appliedGeometries[i].appliedGeometryId;
    final matches = appliedIndices.putIfAbsent(id, () => []);
    if (matches.isNotEmpty) {
      issues.add(
        ProductDesignIssue(
          code: ProductDesignErrorCode.duplicateAppliedGeometryId,
          fieldPath: 'appliedGeometries[$i].appliedGeometryId',
          details: ProductDesignDuplicateDetails(
            identifier: id,
            firstIndex: matches.first,
            duplicateIndex: i,
          ),
        ),
      );
    }
    matches.add(i);
  }
  final productIndices = <String, int>{};
  for (var i = 0; i < products.length; i++) {
    final product = products[i];
    final first = productIndices[product.productId];
    if (first != null) {
      issues.add(
        ProductDesignIssue(
          code: ProductDesignErrorCode.duplicateProductId,
          fieldPath: 'products[$i].productId',
          details: ProductDesignDuplicateDetails(
            identifier: product.productId,
            firstIndex: first,
            duplicateIndex: i,
          ),
        ),
      );
    } else {
      productIndices[product.productId] = i;
    }
    final matches = appliedIndices[product.appliedGeometryId] ?? const <int>[];
    if (matches.length != 1) {
      issues.add(
        ProductDesignIssue(
          code: matches.isEmpty
              ? ProductDesignErrorCode.unknownAppliedGeometryId
              : ProductDesignErrorCode.ambiguousAppliedGeometryId,
          fieldPath: 'products[$i].appliedGeometryId',
          details: ProductDesignReferenceDetails(
            productId: product.productId,
            appliedGeometryId: product.appliedGeometryId,
            matchingIndices: matches,
          ),
        ),
      );
      // 참조 해석과 무관한 중복만 확인한다. 가짜 영역 정의를 만들지 않는다.
      for (final cause in _duplicateInputs(product)) {
        issues.add(_areaIssue(product, i, null, cause));
      }
      continue;
    }
    final appliedIndex = matches.single;
    final areaIssues = validateTextAreaInputs(
      design: appliedGeometries[appliedIndex].geometry,
      inputs: product.textInputs,
    );
    for (final cause in areaIssues) {
      issues.add(_areaIssue(product, i, appliedIndex, cause));
    }
  }
  return List.unmodifiable(issues);
}

Iterable<DesignValidationIssue> _duplicateInputs(ProductInput product) sync* {
  final firstIndices = <String, int>{};
  for (var i = 0; i < product.textInputs.length; i++) {
    final id = product.textInputs[i].areaId;
    final first = firstIndices[id];
    if (first != null) {
      yield DesignValidationIssue(
        code: DesignErrorCode.duplicateInputAreaId,
        fieldPath: 'inputs[$i].areaId',
        details: DesignDuplicateDetails(
          identifier: id,
          firstIndex: first,
          duplicateIndex: i,
        ),
      );
    } else {
      firstIndices[id] = i;
    }
  }
}

ProductDesignIssue _areaIssue(
  ProductInput product,
  int productIndex,
  int? appliedIndex,
  DesignValidationIssue cause,
) {
  // 하위 API의 필드 경로 규약을 명시적으로 상위 소유 위치에 연결한다.
  // 예외 출력 문자열을 분석하지 않으며 원래 issue는 그대로 유지한다.
  final path = cause.code == DesignErrorCode.missingAreaInput
      ? 'appliedGeometries[$appliedIndex].geometry.${cause.fieldPath}'
      : 'products[$productIndex].textInputs${cause.fieldPath.substring('inputs'.length)}';
  return ProductDesignIssue(
    code: ProductDesignErrorCode.textAreaInputMismatch,
    fieldPath: path,
    details: ProductDesignAreaDetails(
      productId: product.productId,
      appliedGeometryId: product.appliedGeometryId,
      cause: cause,
    ),
  );
}
