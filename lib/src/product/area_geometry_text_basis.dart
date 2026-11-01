import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:r_edit_workflow/src/design/text_area_definition.dart';
import 'package:r_edit_workflow/src/design/text_region.dart';
import 'package:r_edit_workflow/src/product/geometry_text_basis_errors.dart';
import 'package:r_edit_workflow/src/text_area_input.dart';

part 'area_geometry_text_basis.freezed.dart';

/// 같은 areaId로 결합한 영역 형상과 원문 입력이다. 표시명·규칙·결과는 포함하지 않는다.
@Freezed(
  copyWith: false,
  fromJson: false,
  toJson: false,
  toStringOverride: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
final class AreaGeometryTextBasis with _$AreaGeometryTextBasis {
  /// 정의/입력 ID가 다르면 GeometryTextBasisException으로 거부한다.
  /// 불변 하위 값은 공유하며 문자 경계 검사·정규화·추가 입력 제한을 하지 않는다.
  AreaGeometryTextBasis({
    required TextAreaDefinition definition,
    required this.input,
  }) : region = definition.region {
    if (definition.areaId != input.areaId) {
      throw GeometryTextBasisException.areaInputMismatch(
        definitionAreaId: definition.areaId,
        inputAreaId: input.areaId,
      );
    }
  }

  /// 이 영역의 경계/제외 경계다. 길이는 소유 제품 근거의 좌표 문맥을 따른다.
  final TextRegion region;

  /// 원문·방식·지정 줄을 그대로 보존한 기존 불변 값이다.
  final TextAreaInput input;

  /// 입력에서 파생한 영역 ID다. 중복 ID 정본을 저장하지 않는다.
  String get areaId => input.areaId;
}
