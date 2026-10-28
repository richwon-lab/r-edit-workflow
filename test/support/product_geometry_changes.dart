import 'package:r_edit_workflow/r_edit_workflow.dart';

import 'product_examples.dart';

/// mm의 title 영역 적용 형상을 공유하되 원문을 독립 소유하는 두 제품이다.
ProductDesignConfiguration twoProductsSharingTitleGeometry() {
  final geometry = appliedMillimeterDesign('old', ['title']);
  return ProductDesignConfiguration(
    appliedGeometries: [geometry],
    products: [
      ProductInput(
        productId: 'p1',
        appliedGeometryId: 'old',
        textInputs: [automaticAreaText('title', 'FIRST')],
      ),
      ProductInput(
        productId: 'p2',
        appliedGeometryId: 'old',
        textInputs: [automaticAreaText('title', 'SECOND')],
      ),
    ],
  );
}

/// 유지 영역만 가진 부분 수정에서 별도 대응/신규/제거 선택이 없는 요청이다.
ProductGeometryTarget targetPreservingAreas(String productId) =>
    ProductGeometryTarget(
      productId: productId,
      areaMappings: [],
      newTextInputs: [],
      removedInputAreaIds: [],
    );
