import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:r_edit_workflow/src/product/text_area_input_mapping.dart';
import 'package:r_edit_workflow/src/text_area_input.dart';

part 'product_geometry_target.freezed.dart';

/// 한 제품에 대한 입력 전달·신규 공급·개별 제거의 불변 요청이다.
/// 미완료/충돌 선택도 보존하며 준비 함수가 정상 거부 진단으로 반환한다.
@Freezed(
  fromJson: false,
  toJson: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
final class ProductGeometryTarget with _$ProductGeometryTarget {
  /// 세 목록을 모두 명시하고 방어 복사한다. 빈 ID를 보정하거나 입력을 자동 생성하지 않는다.
  ProductGeometryTarget({
    required this.productId,
    required List<TextAreaInputMapping> areaMappings,
    required List<TextAreaInput> newTextInputs,
    required List<String> removedInputAreaIds,
  }) : areaMappings = List.unmodifiable(areaMappings),
       newTextInputs = List.unmodifiable(newTextInputs),
       removedInputAreaIds = List.unmodifiable(removedInputAreaIds);

  /// 기준 구성에서 명시적으로 선택한 제품 ID다. 빈 값은 준비 시 진단한다.
  final String productId;

  /// 일대일 전달 요청 순서다. 실제 이전 입력 순서를 재정렬하는 기준은 아니다.
  final List<TextAreaInputMapping> areaMappings;

  /// 유지/전달 입력 뒤에 이 순서대로 붙이는 유효 문구 값이다.
  final List<TextAreaInput> newTextInputs;

  /// 폐기할 이전 입력의 영역 ID를 개별 지정한다. 포괄 제거가 아니다.
  final List<String> removedInputAreaIds;
}
