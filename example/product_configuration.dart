import 'dart:convert';
import 'dart:io';

import 'package:r_edit_workflow/r_edit_workflow.dart';

/// 소비자가 생성기 없이 실제 값·참조를 구성하는 예다. 저장/배치 결과 예제가 아니다.
void main() {
  final boundary = CircleBoundary(center: Point2(x: 0, y: 0), radius: 20);
  final geometry = DesignGeometry(
    coordinateSpace: DrawingCoordinateSpace(lengthUnit: LengthUnit.millimeter),
    outline: boundary,
    cutouts: [],
    textAreas: [
      TextAreaDefinition(
        areaId: 'title',
        label: '',
        region: TextRegion(outer: boundary, exclusions: []),
      ),
    ],
  );
  final applied = AppliedDesignGeometry(
    appliedGeometryId: 'geometry-1',
    geometry: geometry,
  );
  final configuration = ProductDesignConfiguration(
    appliedGeometries: [applied],
    products: [
      ProductInput(
        productId: 'product-1',
        appliedGeometryId: applied.appliedGeometryId,
        textInputs: [
          TextAreaInput(
            areaId: 'title',
            sourceText: ' PUMP A ',
            lineBreak: SpecifiedLineBreak([' PUMP A ']),
          ),
        ],
      ),
    ],
  );
  final restored = ProductDesignConfiguration.fromJson(
    jsonDecode(jsonEncode(configuration.toJson())),
  );
  if (restored != configuration) {
    throw StateError('소비자 JSON 왕복 불일치');
  }
  stdout.writeln('제품 참조와 지정 한 줄 보존 확인');
}
