import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:r_edit_workflow/src/design/design_geometry.dart';
import 'package:r_edit_workflow/src/design/design_source_reference.dart';
import 'package:r_edit_workflow/src/product/product_design_errors.dart';
import 'package:r_edit_workflow/src/product/product_json.dart';

part 'applied_design_geometry.freezed.dart';
part 'applied_design_geometry.g.dart';

/// 작업 구성 안에서 공유할 적용 형상·영역의 불변 스냅샷이다.
/// 전체 제작 조건을 가진 AppliedDesign이 아니다. 단위는 geometry가 소유한다.
/// 과거 같은 ID의 내용 불변은 이 단독 값이 아닌 후속 변경 경계의 책임이다.
@Freezed(
  fromJson: false,
  toJson: false,
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
@JsonSerializable()
final class AppliedDesignGeometry with _$AppliedDesignGeometry {
  AppliedDesignGeometry({
    required this.appliedGeometryId,
    required this.geometry,
    this.source,
  }) {
    checkProductIdentifier(
      appliedGeometryId,
      'appliedGeometryId',
      ProductDesignErrorCode.emptyAppliedGeometryId,
    );
  }

  /// 소유 구성 안의 적용 형상 ID다. 공용 원본 ID와 별개다.
  final String appliedGeometryId;

  /// 공용 원본 없이 해석하는 실제 내용이다. 불변 값 공유를 허용한다.
  @JsonKey(fromJson: _readGeometry, toJson: _writeGeometry)
  final DesignGeometry geometry;

  /// 선택적 출처 기록이다. 생략/null은 기록 없음, 출력에서는 생략한다.
  @JsonKey(fromJson: _readSource, toJson: _writeSource, includeIfNull: false)
  final DesignSourceReference? source;
  factory AppliedDesignGeometry.fromJson(Object? json) {
    final object = readProductObject(json);
    checkProductString(object, 'appliedGeometryId');
    requireProductField(object, 'geometry');
    checkProductFields(object, const {
      'appliedGeometryId',
      'geometry',
      'source',
    });
    return _$AppliedDesignGeometryFromJson(object);
  }
  Map<String, Object?> toJson() => _$AppliedDesignGeometryToJson(this);
}

DesignGeometry _readGeometry(Object? json) =>
    readProductChild(json, DesignGeometry.fromJson, 'geometry');
Map<String, Object?> _writeGeometry(DesignGeometry value) => value.toJson();
DesignSourceReference? _readSource(Object? json) => json == null
    ? null
    : readProductChild(json, DesignSourceReference.fromJson, 'source');
Map<String, Object?>? _writeSource(DesignSourceReference? value) =>
    value?.toJson();
