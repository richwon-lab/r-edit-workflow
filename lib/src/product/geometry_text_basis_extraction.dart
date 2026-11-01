import 'package:meta/meta.dart';
import 'package:r_edit_workflow/src/product/area_geometry_text_basis.dart';
import 'package:r_edit_workflow/src/product/geometry_text_basis_errors.dart';
import 'package:r_edit_workflow/src/product/product_design_configuration.dart';
import 'package:r_edit_workflow/src/product/product_geometry_text_basis.dart';

/// 유효 구성의 대상 제품에서 형상·영역 입력 부분만 추출한다.
/// 제품 없음은 GeometryTextBasisException.unknownProduct, 빈 productId 인자 오용은 ArgumentError다.
/// 구성의 전체 참조 검증을 반복하지 않으며 원본 목록·원문을 변경/정렬하지 않는다.
@useResult
ProductGeometryTextBasis extractProductGeometryTextBasis({
  required ProductDesignConfiguration configuration,
  required String productId,
}) {
  checkBasisIdentifierArgument(productId, 'productId');
  final matches = configuration.products.where((p) => p.productId == productId);
  if (matches.isEmpty) {
    throw GeometryTextBasisException.unknownProduct(productId);
  }
  final product = matches.single;
  final geometry = configuration.appliedGeometries
      .singleWhere((g) => g.appliedGeometryId == product.appliedGeometryId)
      .geometry;
  final inputs = {for (final input in product.textInputs) input.areaId: input};
  return ProductGeometryTextBasis(
    productId: productId,
    coordinateSpace: geometry.coordinateSpace,
    outline: geometry.outline,
    cutouts: geometry.cutouts,
    areas: [
      for (final area in geometry.textAreas)
        AreaGeometryTextBasis(definition: area, input: inputs[area.areaId]!),
    ],
  );
}
