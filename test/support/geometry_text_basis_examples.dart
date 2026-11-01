import 'package:r_edit_workflow/r_edit_workflow.dart';

import 'product_examples.dart';

/// mm의 두 영역, 공유 도안 두 제품과 미사용 도안으로 실제 참조 구성을 준비한다.
ProductDesignConfiguration twoAreaBasisConfiguration({
  DesignGeometry? geometry,
  List<TextAreaInput>? inputs,
  String appliedId = 'g',
  DesignSourceReference? source,
  String otherText = 'OTHER',
}) {
  final actual = geometry ?? millimeterDesignWithAreaIds(['a', 'b']);
  return ProductDesignConfiguration(
    appliedGeometries: [
      AppliedDesignGeometry(
        appliedGeometryId: appliedId,
        geometry: actual,
        source: source,
      ),
      appliedMillimeterDesign('unused', []),
    ],
    products: [
      ProductInput(
        productId: 'target',
        appliedGeometryId: appliedId,
        textInputs:
            inputs ??
            [
              TextAreaInput(
                areaId: 'b',
                sourceText: 'PUMP PUMP',
                lineBreak: SpecifiedLineBreak(['PUMP ', 'PUMP']),
              ),
              TextAreaInput(
                areaId: 'a',
                sourceText: ' A e\u0301🙂  ',
                lineBreak: SpecifiedLineBreak([' A e\u0301🙂  ']),
              ),
            ],
      ),
      ProductInput(
        productId: 'other',
        appliedGeometryId: appliedId,
        textInputs: [
          automaticAreaText('a', otherText),
          automaticAreaText('b', ' '),
        ],
      ),
    ],
  );
}

/// 새 근거 생성 경계를 시험하기 위한 명시 필드 조립이다. 차이를 계산하지 않는다.
ProductGeometryTextBasis rebuildGeometryTextBasis(
  ProductGeometryTextBasis basis, {
  String? productId,
  DrawingCoordinateSpace? coordinateSpace,
  ClosedBoundary? outline,
  List<CutoutDefinition>? cutouts,
  List<AreaGeometryTextBasis>? areas,
}) => ProductGeometryTextBasis(
  productId: productId ?? basis.productId,
  coordinateSpace: coordinateSpace ?? basis.coordinateSpace,
  outline: outline ?? basis.outline,
  cutouts: cutouts ?? basis.cutouts,
  areas: areas ?? basis.areas,
);
