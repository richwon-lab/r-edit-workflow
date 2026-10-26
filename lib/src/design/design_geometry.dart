import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:r_edit_workflow/src/design/cutout_definition.dart';
import 'package:r_edit_workflow/src/design/design_errors.dart';
import 'package:r_edit_workflow/src/design/design_json.dart';
import 'package:r_edit_workflow/src/design/text_area_definition.dart';
import 'package:r_edit_workflow/src/geometry/closed_boundary.dart';
import 'package:r_edit_workflow/src/geometry/coordinate_space.dart';
import 'package:r_edit_workflow/src/geometry/geometry_errors.dart';

part 'design_geometry.freezed.dart';
part 'design_geometry.g.dart';

/// 단일 실제 외곽·관통 구멍·텍스트 영역을 소유하는 도안 구성이다.
/// 모든 하위 길이는 coordinateSpace를 따른다. 포함/간섭/제작 가능성은 검사하지 않는다.
@Freezed(
  fromJson: false,
  toJson: false,
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
@JsonSerializable()
final class DesignGeometry with _$DesignGeometry {
  /// 목록을 방어 복사하고 각각의 cutouts/textAreas 범위에서 ID 중복을 거부한다.
  /// 빈 목록은 허용하며 서로 다른 ID 종류는 같은 문자열이어도 충돌하지 않는다. 경계 관계는 타입 설명의 범위 밖이다.
  DesignGeometry({
    required this.coordinateSpace,
    required this.outline,
    required List<CutoutDefinition> cutouts,
    required List<TextAreaDefinition> textAreas,
  }) : cutouts = List.unmodifiable(cutouts),
       textAreas = List.unmodifiable(textAreas) {
    final cutoutIds = <String, int>{};
    for (var i = 0; i < this.cutouts.length; i++) {
      final first = cutoutIds[this.cutouts[i].cutoutId];
      if (first != null) {
        throw DesignValidationException(
          DesignValidationIssue(
            code: DesignErrorCode.duplicateCutoutId,
            fieldPath: 'cutouts[$i].cutoutId',
            details: DesignDuplicateDetails(
              identifier: this.cutouts[i].cutoutId,
              firstIndex: first,
              duplicateIndex: i,
            ),
          ),
        );
      }
      cutoutIds[this.cutouts[i].cutoutId] = i;
    }
    final areaIds = <String, int>{};
    for (var i = 0; i < this.textAreas.length; i++) {
      final first = areaIds[this.textAreas[i].areaId];
      if (first != null) {
        throw DesignValidationException(
          DesignValidationIssue(
            code: DesignErrorCode.duplicateAreaId,
            fieldPath: 'textAreas[$i].areaId',
            details: DesignDuplicateDetails(
              identifier: this.textAreas[i].areaId,
              firstIndex: first,
              duplicateIndex: i,
            ),
          ),
        );
      }
      areaIds[this.textAreas[i].areaId] = i;
    }
  }

  /// 도안의 유일한 길이 단위 선언이다. 하위 요소에 반복 저장하지 않는다.
  @JsonKey(fromJson: _readDesignSpace, toJson: _writeDesignSpace)
  final DrawingCoordinateSpace coordinateSpace;

  /// 실제 자재 외곽 경계 하나다. 장식/텍스트 영역과 구분한다.
  @JsonKey(fromJson: _readOutline, toJson: writeBoundary)
  final ClosedBoundary outline;

  /// 도안 안 cutoutId가 유일한 관통 제거 영역이다. 명시적 빈 목록도 가능하다.
  @JsonKey(fromJson: _readCutouts, toJson: _writeCutouts)
  final List<CutoutDefinition> cutouts;

  /// 도안 안 areaId가 유일한 정의다. 텍스트 없는 도안도 표현할 수 있다.
  @JsonKey(fromJson: _readTextAreas, toJson: _writeTextAreas)
  final List<TextAreaDefinition> textAreas;

  /// 문맥·외곽·관통 목록·영역 목록의 필수 구조와 소유 ID를 검사해 복원한다.
  /// 도안 오류는 DesignValidationException, 하위 기하 오류는 목록 인덱스/필드 경로와 원래 diagnostic을 보존해 전달한다.
  factory DesignGeometry.fromJson(Object? json) {
    final object = readDesignObject(json);
    for (final key in ['coordinateSpace', 'outline', 'cutouts', 'textAreas']) {
      requireDesignField(object, key);
    }
    checkDesignFields(object, const {
      'coordinateSpace',
      'outline',
      'cutouts',
      'textAreas',
    });
    return _$DesignGeometryFromJson(object);
  }

  /// 유일한 단위 문맥과 역할별 경계를 새 JSON으로 내보낸다. 입력 원문·계산/저장 판정은 포함하지 않는다.
  Map<String, Object?> toJson() => _$DesignGeometryToJson(this);

  /// 단위는 유지하고 구성요소만 교체해 소유 ID 검증을 다시 수행한다.
  /// 단위만 바꾸는 수정 경로를 막기 위해 이 메서드만 직접 작성했다.
  DesignGeometry copyWith({
    ClosedBoundary? outline,
    List<CutoutDefinition>? cutouts,
    List<TextAreaDefinition>? textAreas,
  }) => DesignGeometry(
    coordinateSpace: coordinateSpace,
    outline: outline ?? this.outline,
    cutouts: cutouts ?? this.cutouts,
    textAreas: textAreas ?? this.textAreas,
  );

  /// 외곽·모든 관통 경계·영역 외부/제외 경계와 문맥을 함께 환산한다.
  /// ID/label을 바꾸지 않으며 실패하면 기존 값을 보존한다. 회전/출력 배열은 없다.
  DesignGeometry convertedTo(LengthUnit target) {
    final from = coordinateSpace.lengthUnit;
    final convertedCutouts = <CutoutDefinition>[];
    final convertedAreas = <TextAreaDefinition>[];
    for (var i = 0; i < cutouts.length; i++) {
      try {
        convertedCutouts.add(cutouts[i].converted(from: from, to: target));
      } on GeometryValidationException catch (error) {
        throw error.prefixed('cutouts[$i]');
      }
    }
    for (var i = 0; i < textAreas.length; i++) {
      try {
        convertedAreas.add(textAreas[i].converted(from: from, to: target));
      } on GeometryValidationException catch (error) {
        throw error.prefixed('textAreas[$i]');
      }
    }
    return DesignGeometry(
      coordinateSpace: DrawingCoordinateSpace(lengthUnit: target),
      outline: _convertBoundary(outline, from, target, 'outline'),
      cutouts: convertedCutouts,
      textAreas: convertedAreas,
    );
  }
}

ClosedBoundary _readOutline(Object? json) => readBoundary(json, 'outline');

DrawingCoordinateSpace _readDesignSpace(Object? json) {
  try {
    return DrawingCoordinateSpace.fromJson(json);
  } on GeometryValidationException catch (error) {
    throw error.prefixed('coordinateSpace');
  }
}

Map<String, Object?> _writeDesignSpace(DrawingCoordinateSpace space) =>
    space.toJson();

List<CutoutDefinition> _readCutouts(Object? json) {
  final values = readDesignList(json, 'cutouts');
  final result = <CutoutDefinition>[];
  for (var i = 0; i < values.length; i++) {
    try {
      result.add(CutoutDefinition.fromJson(values[i]));
    } on DesignValidationException catch (error) {
      throw error.prefixed('cutouts[$i]');
    } on GeometryValidationException catch (error) {
      throw error.prefixed('cutouts[$i]');
    }
  }
  return result;
}

List<TextAreaDefinition> _readTextAreas(Object? json) {
  final values = readDesignList(json, 'textAreas');
  final result = <TextAreaDefinition>[];
  for (var i = 0; i < values.length; i++) {
    try {
      result.add(TextAreaDefinition.fromJson(values[i]));
    } on DesignValidationException catch (error) {
      throw error.prefixed('textAreas[$i]');
    } on GeometryValidationException catch (error) {
      throw error.prefixed('textAreas[$i]');
    }
  }
  return result;
}

List<Map<String, Object?>> _writeCutouts(List<CutoutDefinition> cutouts) => [
  for (final cutout in cutouts) cutout.toJson(),
];

List<Map<String, Object?>> _writeTextAreas(List<TextAreaDefinition> areas) => [
  for (final area in areas) area.toJson(),
];

ClosedBoundary _convertBoundary(
  ClosedBoundary boundary,
  LengthUnit from,
  LengthUnit to,
  String fieldPath,
) {
  try {
    return boundary.converted(from: from, to: to);
  } on GeometryValidationException catch (error) {
    throw error.prefixed(fieldPath);
  }
}
