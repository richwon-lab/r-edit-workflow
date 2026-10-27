import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:r_edit_workflow/src/design/design_errors.dart';
import 'package:r_edit_workflow/src/design/design_json.dart';
import 'package:r_edit_workflow/src/design/text_region.dart';
import 'package:r_edit_workflow/src/geometry/coordinate_space.dart';
import 'package:r_edit_workflow/src/geometry/geometry_errors.dart';

part 'text_area_definition.freezed.dart';
part 'text_area_definition.g.dart';

/// areaId로 원문 입력과 연결할 정의다. 문자열은 trim/정규화하지 않는다.
/// 값 생성 성공은 입력 존재·배치 가능·제작 가능 판정이 아니다.
@Freezed(
  fromJson: false,
  toJson: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
@JsonSerializable()
final class TextAreaDefinition with _$TextAreaDefinition {
  /// 빈 areaId만 거부한다. label은 빈 값/중복을 허용하며 보정하지 않는다.
  /// 영역 ID 중복과 실제 원문 연결은 소유 도안 및 입력 대조 API가 검사한다.
  TextAreaDefinition({
    required this.areaId,
    required this.label,
    required this.region,
  }) {
    // TextAreaInput과 같은 규약: 빈 문자열만 거부하고 공백 ID는 그대로 둔다.
    if (areaId.isEmpty) {
      throw DesignValidationException(
        DesignValidationIssue(
          code: DesignErrorCode.emptyAreaId,
          fieldPath: 'areaId',
          details: DesignIdentifierDetails(areaId),
        ),
      );
    }
  }

  /// 소유 도안 안 유일한 영역 ID다. 전역 유일성을 요구하지 않는다.
  final String areaId;

  /// 필수 표시 문자열이다. 빈 값·중복을 허용하며 ID 생성에 쓰지 않는다.
  final String label;

  /// 도안 단위를 따르는 배치 허용 영역의 정의다. 원문/줄 입력은 저장하지 않는다.
  @JsonKey(fromJson: _readTextRegion, toJson: _writeTextRegion)
  final TextRegion region;

  /// areaId·label 문자열과 region을 복원한다. 도안 구조/ID 오류와 region의 기하 오류를 구분해 전달한다.
  factory TextAreaDefinition.fromJson(Object? json) {
    final object = readDesignObject(json);
    readDesignString(object, 'areaId');
    readDesignString(object, 'label');
    requireDesignField(object, 'region');
    checkDesignFields(object, const {'areaId', 'label', 'region'});
    return _$TextAreaDefinitionFromJson(object);
  }

  /// 영역의 ID·표시 이름·실제 경계를 새 JSON으로 내보낸다. 원문 입력을 중복 저장하지 않는다.
  Map<String, Object?> toJson() => _$TextAreaDefinitionToJson(this);

  /// 영역의 전체 경계만 환산한다. areaId/label은 보존한다.
  @useResult
  TextAreaDefinition converted({
    required LengthUnit from,
    required LengthUnit to,
  }) {
    try {
      return TextAreaDefinition(
        areaId: areaId,
        label: label,
        region: region.converted(from: from, to: to),
      );
    } on GeometryValidationException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        error.prefixed('region', stackTrace: stackTrace),
        stackTrace,
      );
    }
  }
}

TextRegion _readTextRegion(Object? json) {
  try {
    return TextRegion.fromJson(json);
  } on DesignValidationException catch (error, stackTrace) {
    Error.throwWithStackTrace(
      error.prefixed('region', stackTrace: stackTrace),
      stackTrace,
    );
  } on GeometryValidationException catch (error, stackTrace) {
    Error.throwWithStackTrace(
      error.prefixed('region', stackTrace: stackTrace),
      stackTrace,
    );
  }
}

Map<String, Object?> _writeTextRegion(TextRegion region) => region.toJson();
