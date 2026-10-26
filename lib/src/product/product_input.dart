import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:r_edit_workflow/src/product/product_design_errors.dart';
import 'package:r_edit_workflow/src/product/product_json.dart';
import 'package:r_edit_workflow/src/text_area_input.dart';

part 'product_input.freezed.dart';
part 'product_input.g.dart';

/// 제품별 원문·줄바꿈 입력과 적용 형상 참조다. 좌표·단위를 중복 소유하지 않는다.
/// 단독 값은 ID/문구 값과 불변 목록만 보장한다. 영역 ID 중복·참조·입력 누락은
/// ProductDesignConfiguration에서 함께 진단한다. 배치/제작/저장 판정은 없다.
@Freezed(
  fromJson: false,
  toJson: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
@JsonSerializable()
final class ProductInput with _$ProductInput {
  /// 빈 제품/적용 ID를 거부하고 문구 목록을 방어 복사한다. 제품별 입력 소유권은 독립적이다.
  /// 같은 areaId의 중복·도안 참조·입력 누락은 ProductDesignConfiguration에서 함께 검사한다.
  ProductInput({
    required this.productId,
    required this.appliedGeometryId,
    required List<TextAreaInput> textInputs,
  }) : textInputs = List.unmodifiable(textInputs) {
    checkProductIdentifier(
      productId,
      'productId',
      ProductDesignErrorCode.emptyProductId,
    );
    checkProductIdentifier(
      appliedGeometryId,
      'appliedGeometryId',
      ProductDesignErrorCode.emptyAppliedGeometryId,
    );
  }

  /// 소유 구성 안에서 유일해야 하는 제품 ID다.
  final String productId;

  /// 같은 구성의 적용 스냅샷 참조다. 이 값만으로 존재 여부를 알 수 없다.
  final String appliedGeometryId;

  /// 순서·원문·지정 줄을 그대로 보존한다. 영역 정의와의 대응은 구성에서 검사한다.
  @JsonKey(fromJson: _readTextInputs, toJson: _writeTextInputs)
  final List<TextAreaInput> textInputs;

  /// 제품/적용 ID와 순서 있는 입력을 복원한다. 제품 구조 오류는 전용 예외로,
  /// 문구 오류는 textInputs의 0 기반 위치와 원인 예외를 보존한 중첩 예외로 전달한다.
  factory ProductInput.fromJson(Object? json) {
    final object = readProductObject(json);
    checkProductString(object, 'productId');
    checkProductString(object, 'appliedGeometryId');
    requireProductField(object, 'textInputs');
    checkProductFields(object, const {
      'productId',
      'appliedGeometryId',
      'textInputs',
    });
    return _$ProductInputFromJson(object);
  }

  /// 제품 ID·적용 참조와 원문/줄 입력을 독립 JSON으로 내보낸다. 수량·좌표·결과는 추가하지 않는다.
  Map<String, Object?> toJson() => _$ProductInputToJson(this);
}

List<TextAreaInput> _readTextInputs(Object? json) {
  final values = readProductList(json, 'textInputs');
  return [
    for (var i = 0; i < values.length; i++)
      readProductChild(values[i], TextAreaInput.fromJson, 'textInputs[$i]'),
  ];
}

List<Map<String, Object?>> _writeTextInputs(List<TextAreaInput> values) => [
  for (final value in values) value.toJson(),
];
