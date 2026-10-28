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
  // 소비자는 오류 문자열 대신 공개 타입/필드를 처리한다. 입력 거부를 로깅하지 않는다.
  try {
    TextAreaInput.fromJson({
      'areaId': 'title',
      'sourceText': 123,
      'lineBreak': {'mode': 'automatic'},
    });
    throw StateError('잘못된 타입 허용');
  } on TextInputValidationException catch (error) {
    if (error.details case TextInputTypeDetails(
      :final expectedType,
      :final actualType,
    )) {
      if (expectedType != 'String' ||
          actualType != 'int' ||
          error.fieldPath != 'sourceText') {
        throw StateError('공개 타입 진단 불일치');
      }
    } else {
      throw StateError('필수 타입 상세 누락');
    }
  }
  final changed = ProductDesignConfiguration(
    appliedGeometries: [
      AppliedDesignGeometry(
        appliedGeometryId: applied.appliedGeometryId,
        geometry: geometry.copyWith(
          outline: CircleBoundary(center: Point2(x: 0, y: 0), radius: 21),
        ),
      ),
    ],
    products: configuration.products,
  );
  final conflicts = validateAppliedGeometryIdConsistency(
    previous: configuration,
    next: changed,
  );
  if (conflicts.length != 1 ||
      conflicts.single.code !=
          AppliedGeometryIdConflictCode.snapshotContentConflict ||
      conflicts.single.changedFieldPaths.single != 'geometry.outline.radius') {
    throw StateError('소비자 공통 ID 내용 비교 실패');
  }
  final prepared = prepareProductGeometryChange(
    baseline: configuration,
    request: ReviseAppliedGeometry(
      sourceAppliedGeometryId: applied.appliedGeometryId,
      proposedGeometry: AppliedDesignGeometry(
        appliedGeometryId: 'geometry-2',
        geometry: geometry.copyWith(
          outline: CircleBoundary(center: Point2(x: 0, y: 0), radius: 21),
        ),
      ),
      targets: [
        ProductGeometryTarget(
          productId: 'product-1',
          areaMappings: [],
          newTextInputs: [],
          removedInputAreaIds: [],
        ),
      ],
    ),
  );
  switch (prepared) {
    case ReadyProductGeometryChange(:final summary):
      if (summary.products.single.retainedAreaIds.single != 'title' ||
          summary.products.single.proposedAppliedGeometryId != 'geometry-2') {
        throw StateError('소비자 준비 요약 불일치');
      }
    case BlockedProductGeometryChange():
      throw StateError('유효한 소비자 변경 요청이 거부됨');
    case UnchangedProductGeometryChange():
      throw StateError('새 ID 변경을 무변경으로 처리함');
  }
  // 후보는 공개되지 않으며 준비가 기준 값을 반영/교체하지 않는다.
  if (configuration.products.single.appliedGeometryId != 'geometry-1') {
    throw StateError('준비가 기준을 변경함');
  }
  stdout.writeln('제품 참조·지정 한 줄·구조화 진단·공통 ID 비교·도안 변경 준비 확인');
}
