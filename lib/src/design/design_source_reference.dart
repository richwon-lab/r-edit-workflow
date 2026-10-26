import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:r_edit_workflow/src/product/product_design_errors.dart';
import 'package:r_edit_workflow/src/product/product_json.dart';

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
  /// 빈 공용 ID 또는 지정된 빈 버전을 거부한다. sourceRevision 생략은 미상이며 latest로 채우지 않는다.
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

  /// 출처 ID와 알려진 버전만 복원한다. sourceRevision의 생략/null을 허용하되 다른 타입·빈 문자열은 제품 값 오류다.
  factory DesignSourceReference.fromJson(Object? json) {
    final object = readProductObject(json);
    checkProductString(object, 'sourceDesignId');
    checkProductString(object, 'sourceRevision', optional: true);
    checkProductFields(object, const {'sourceDesignId', 'sourceRevision'});
    return _$DesignSourceReferenceFromJson(object);
  }

  /// 출처 기록을 내보내며 미상 버전은 생략한다. 실제 원본 조회나 버전 최신성 검사는 수행하지 않는다.
  Map<String, Object?> toJson() => _$DesignSourceReferenceToJson(this);
}
