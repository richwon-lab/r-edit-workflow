import 'package:freezed_annotation/freezed_annotation.dart';

import '../design/applied_design_geometry.dart';
import 'product_design_errors.dart';
import 'product_design_validation.dart';
import 'product_input.dart';
import 'product_json.dart';

part 'product_design_configuration.freezed.dart';
part 'product_design_configuration.g.dart';

/// 적용 형상과 제품 입력을 함께 소유하는 유효 참조 구성이다.
/// 공개 생성·수정·JSON 복원은 객체 생성 전에 같은 검증 함수를 사용한다.
/// 빈 목록·미사용 형상은 허용한다. 완전한 제작 도안/작업 파일은 아니다.
/// 변경 전후 같은 ID 내용 비교·안전한 변경 명령·배치/저장 판정은 범위 밖이다.
@Freezed(
  fromJson: false,
  toJson: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
@JsonSerializable()
final class ProductDesignConfiguration with _$ProductDesignConfiguration {
  ProductDesignConfiguration({
    required List<AppliedDesignGeometry> appliedGeometries,
    required List<ProductInput> products,
  }) : this._(_prepareConfiguration(appliedGeometries, products));

  ProductDesignConfiguration._(
    (List<AppliedDesignGeometry>, List<ProductInput>) prepared,
  ) : appliedGeometries = prepared.$1,
      products = prepared.$2;

  /// 적용 ID의 소유 목록이다. 제품 ID와 별도 이름 공간이며 순서를 보존한다.
  @JsonKey(fromJson: _readAppliedGeometries, toJson: _writeAppliedGeometries)
  final List<AppliedDesignGeometry> appliedGeometries;

  /// 독립 원문·줄바꿈 입력을 가진 제품 목록이다. 순서·입력을 보정하지 않는다.
  @JsonKey(fromJson: _readProducts, toJson: _writeProducts)
  final List<ProductInput> products;
  factory ProductDesignConfiguration.fromJson(Object? json) {
    final object = readProductObject(json);
    requireProductField(object, 'appliedGeometries');
    requireProductField(object, 'products');
    checkProductFields(object, const {'appliedGeometries', 'products'});
    return _$ProductDesignConfigurationFromJson(object);
  }
  Map<String, Object?> toJson() => _$ProductDesignConfigurationToJson(this);
}

(List<AppliedDesignGeometry>, List<ProductInput>) _prepareConfiguration(
  List<AppliedDesignGeometry> appliedGeometries,
  List<ProductInput> products,
) {
  final appliedCopy = List<AppliedDesignGeometry>.unmodifiable(
    appliedGeometries,
  );
  final productCopy = List<ProductInput>.unmodifiable(products);
  final issues = validateProductDesignConfiguration(
    appliedGeometries: appliedCopy,
    products: productCopy,
  );
  if (issues.isNotEmpty) throw ProductDesignValidationException(issues);
  return (appliedCopy, productCopy);
}

List<AppliedDesignGeometry> _readAppliedGeometries(Object? json) {
  final values = readProductList(json, 'appliedGeometries');
  return [
    for (var i = 0; i < values.length; i++)
      readProductChild(
        values[i],
        AppliedDesignGeometry.fromJson,
        'appliedGeometries[$i]',
      ),
  ];
}

List<ProductInput> _readProducts(Object? json) {
  final values = readProductList(json, 'products');
  return [
    for (var i = 0; i < values.length; i++)
      readProductChild(values[i], ProductInput.fromJson, 'products[$i]'),
  ];
}

List<Map<String, Object?>> _writeAppliedGeometries(
  List<AppliedDesignGeometry> values,
) => [for (final value in values) value.toJson()];
List<Map<String, Object?>> _writeProducts(List<ProductInput> values) => [
  for (final value in values) value.toJson(),
];
