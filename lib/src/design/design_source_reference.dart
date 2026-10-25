import 'package:freezed_annotation/freezed_annotation.dart';

import '../product/product_design_errors.dart';
import '../product/product_json.dart';

part 'design_source_reference.freezed.dart';
part 'design_source_reference.g.dart';

/// 공용 원본의 출처 기록이다. 실제 형상을 재조회하는 연결이 아니다.
/// ID·버전을 trim/정규화하지 않고 빈 문자열만 거부한다.
@Freezed(
  fromJson: false,
  toJson: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
@JsonSerializable()
final class DesignSourceReference with _$DesignSourceReference {
  DesignSourceReference({required this.sourceDesignId, this.sourceRevision}) {
    checkProductIdentifier(
      sourceDesignId,
      'sourceDesignId',
      ProductDesignErrorCode.emptySourceDesignId,
    );
    if (sourceRevision case final revision?) {
      checkProductIdentifier(
        revision,
        'sourceRevision',
        ProductDesignErrorCode.emptySourceRevision,
      );
    }
  }

  /// 공용 자료 범위의 식별자다. 작업 내부 적용 ID와 별개다.
  final String sourceDesignId;

  /// 실제 알려진 버전의 불투명 문자열이다. 생략/null은 기록 없음이다.
  /// 버전 체계·최신성은 검사하지 않고 임의 버전으로 보정하지 않는다.
  @JsonKey(includeIfNull: false)
  final String? sourceRevision;
  factory DesignSourceReference.fromJson(Object? json) {
    final object = readProductObject(json);
    checkProductString(object, 'sourceDesignId');
    checkProductString(object, 'sourceRevision', optional: true);
    checkProductFields(object, const {'sourceDesignId', 'sourceRevision'});
    return _$DesignSourceReferenceFromJson(object);
  }
  Map<String, Object?> toJson() => _$DesignSourceReferenceToJson(this);
}
