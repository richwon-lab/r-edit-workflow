import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:r_edit_workflow/src/design/design_errors.dart';
import 'package:r_edit_workflow/src/design/design_json.dart';
import 'package:r_edit_workflow/src/geometry/closed_boundary.dart';
import 'package:r_edit_workflow/src/geometry/coordinate_space.dart';
import 'package:r_edit_workflow/src/geometry/geometry_errors.dart';

part 'cutout_definition.freezed.dart';
part 'cutout_definition.g.dart';

/// 안정 ID와 실제 닫힌 경계를 가진 관통 제거 영역이다. 형상·가공 설비를 제한하지 않는다.
/// 경계 수치 조건만 따르며 외곽 안 포함·간섭·면적은 검사하지 않는다.
@Freezed(
  fromJson: false,
  toJson: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
@JsonSerializable()
final class CutoutDefinition with _$CutoutDefinition {
  /// 빈 cutoutId를 거부하고 경계를 보정 없이 보관한다. ID 중복은 소유 DesignGeometry에서 검사한다.
  CutoutDefinition({required this.cutoutId, required this.boundary}) {
    if (cutoutId.isEmpty) {
      throw DesignValidationException(
        DesignValidationIssue(
          code: DesignErrorCode.emptyCutoutId,
          fieldPath: 'cutoutId',
          details: DesignIdentifierDetails(cutoutId),
        ),
      );
    }
  }

  /// 표시 이름·좌표에서 만들지 않는 관통 구멍 ID다. 빈 값만 거부하고 보정하지 않는다.
  final String cutoutId;

  /// 제거되는 내부 영역의 실제 경계다. 원형/사각형/장공 모두 같은 타입이다.
  @JsonKey(fromJson: _readCutoutBoundary, toJson: writeBoundary)
  final ClosedBoundary boundary;

  /// cutoutId와 boundary를 복원한다. 도안 구조/ID 오류와 하위 기하 오류를 구분해 전달한다.
  /// 경계 실패 경로에는 boundary를 붙이며 수치 진단은 유지한다.
  factory CutoutDefinition.fromJson(Object? json) {
    final object = readDesignObject(json);
    readDesignString(object, 'cutoutId');
    requireDesignField(object, 'boundary');
    checkDesignFields(object, const {'cutoutId', 'boundary'});
    return _$CutoutDefinitionFromJson(object);
  }

  /// 관통 ID와 실제 경계를 새 JSON 값으로 내보낸다. 설비·가공 순서·포함 여부는 추가하지 않는다.
  Map<String, Object?> toJson() => _$CutoutDefinitionToJson(this);

  /// 문맥 단위를 명시해 경계만 환산하고 안정 ID는 보존한다.
  @useResult
  CutoutDefinition converted({
    required LengthUnit from,
    required LengthUnit to,
  }) => CutoutDefinition(
    cutoutId: cutoutId,
    boundary: _convertBoundary(boundary, from, to, 'boundary'),
  );
}

ClosedBoundary _readCutoutBoundary(Object? json) =>
    readBoundary(json, 'boundary');

ClosedBoundary _convertBoundary(
  ClosedBoundary boundary,
  LengthUnit from,
  LengthUnit to,
  String fieldPath,
) {
  try {
    return boundary.converted(from: from, to: to);
  } on GeometryValidationException catch (error, stackTrace) {
    Error.throwWithStackTrace(
      error.prefixed(fieldPath, stackTrace: stackTrace),
      stackTrace,
    );
  }
}
