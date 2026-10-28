import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:r_edit_workflow/src/product/text_area_input_mapping.dart';

part 'product_geometry_change_summary.freezed.dart';

/// 준비 중 유일하게 해석된 제품별 변경의 투영이다.
/// 원문/전체 형상을 복제하지 않으며 배치 영향·반영 허가·로그 레코드가 아니다.
@Freezed(
  fromJson: false,
  toJson: false,
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
final class ProductGeometryChangeSummary with _$ProductGeometryChangeSummary {
  /// 해석 완료된 제품 요약만 방어 복사한다. Blocked에서는 일부/전부가 없을 수 있다.
  ProductGeometryChangeSummary({
    required List<ProductGeometryTargetSummary> products,
  }) : products = List.unmodifiable(products);

  /// 기준 제품 목록 순서의 요약이다. 실패 제품은 포함하지 않는다.
  final List<ProductGeometryTargetSummary> products;
}

/// 한 대상의 참조·영역 처리와 실제 스냅샷 변경 경로다. 원문 내용은 포함하지 않는다.
@Freezed(
  fromJson: false,
  toJson: false,
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
final class ProductGeometryTargetSummary with _$ProductGeometryTargetSummary {
  /// 각 목록은 방어 복사한다. ID/순서는 기준과 해석된 후보에서 얻은 값이다.
  ProductGeometryTargetSummary({
    required this.productId,
    required this.previousAppliedGeometryId,
    required this.proposedAppliedGeometryId,
    required List<String> retainedAreaIds,
    required List<TextAreaInputMapping> areaMappings,
    required List<String> newInputAreaIds,
    required List<String> removedInputAreaIds,
    required List<String> resultingInputAreaIds,
    required List<String> changedFieldPaths,
  }) : retainedAreaIds = List.unmodifiable(retainedAreaIds),
       areaMappings = List.unmodifiable(areaMappings),
       newInputAreaIds = List.unmodifiable(newInputAreaIds),
       removedInputAreaIds = List.unmodifiable(removedInputAreaIds),
       resultingInputAreaIds = List.unmodifiable(resultingInputAreaIds),
       changedFieldPaths = List.unmodifiable(changedFieldPaths);

  /// 기준 구성 소유의 제품 ID다.
  final String productId;

  /// 기준에서 참조한 적용 ID다.
  final String previousAppliedGeometryId;

  /// 제안/재사용 스냅샷의 적용 ID다.
  final String proposedAppliedGeometryId;

  /// 같은 업무 영역으로 유지한 ID다. 이전 입력의 상대 순서다.
  final List<String> retainedAreaIds;

  /// 실제 전달한 대응이며 이전 입력의 상대 순서다.
  final List<TextAreaInputMapping> areaMappings;

  /// 뒤에 붙인 신규 입력 ID이며 요청 순서다.
  final List<String> newInputAreaIds;

  /// 명시 제거한 ID이며 이전 입력의 상대 순서다.
  final List<String> removedInputAreaIds;

  /// 후보 제품 입력의 실제 영역 ID 순서다. 원문 자체를 담지 않는다.
  final List<String> resultingInputAreaIds;

  /// 스냅샷 기준의 내용 변경 경로다. 적용 ID 변경은 위 두 참조 필드로 구분한다.
  final List<String> changedFieldPaths;
}
