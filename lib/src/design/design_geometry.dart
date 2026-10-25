import 'package:freezed_annotation/freezed_annotation.dart';

import '../geometry/closed_boundary.dart';
import '../geometry/coordinate_space.dart';
import '../geometry/geometry_errors.dart';
import 'design_errors.dart';
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
  @JsonKey(fromJson: _readOutline, toJson: _writeBoundary)
  final ClosedBoundary outline;

  /// 도안 안 cutoutId가 유일한 관통 제거 영역이다. 명시적 빈 목록도 가능하다.
  @JsonKey(fromJson: _readCutouts, toJson: _writeCutouts)
  final List<CutoutDefinition> cutouts;

  /// 도안 안 areaId가 유일한 정의다. 텍스트 없는 도안도 표현할 수 있다.
  @JsonKey(fromJson: _readTextAreas, toJson: _writeTextAreas)
  final List<TextAreaDefinition> textAreas;

  factory DesignGeometry.fromJson(Object? json) {
    final object = _readDesignObject(json);
    for (final key in ['coordinateSpace', 'outline', 'cutouts', 'textAreas']) {
      _requireDesignField(object, key);
    }
    _checkDesignFields(object, const {
      'coordinateSpace',
      'outline',
      'cutouts',
      'textAreas',
    });
    return _$DesignGeometryFromJson(object);
  }
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
  @JsonKey(fromJson: _readCutoutBoundary, toJson: _writeBoundary)
  final ClosedBoundary boundary;
  factory CutoutDefinition.fromJson(Object? json) {
    final object = _readDesignObject(json);
    _readDesignString(object, 'cutoutId');
    _requireDesignField(object, 'boundary');
    _checkDesignFields(object, const {'cutoutId', 'boundary'});
    return _$CutoutDefinitionFromJson(object);
  }
  Map<String, Object?> toJson() => _$CutoutDefinitionToJson(this);

  /// 문맥 단위를 명시해 경계만 환산하고 안정 ID는 보존한다.
  CutoutDefinition converted({
    required LengthUnit from,
    required LengthUnit to,
  }) => CutoutDefinition(
    cutoutId: cutoutId,
    boundary: _convertBoundary(boundary, from, to, 'boundary'),
  );
}

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
  factory TextAreaDefinition.fromJson(Object? json) {
    final object = _readDesignObject(json);
    _readDesignString(object, 'areaId');
    _readDesignString(object, 'label');
    _requireDesignField(object, 'region');
    _checkDesignFields(object, const {'areaId', 'label', 'region'});
    return _$TextAreaDefinitionFromJson(object);
  }
  Map<String, Object?> toJson() => _$TextAreaDefinitionToJson(this);

  /// 영역의 전체 경계만 환산한다. areaId/label은 보존한다.
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
    } on GeometryValidationException catch (error) {
      throw error.prefixed('region');
    }
  }
}

/// 도안 문맥 단위의 외부 경계와 명시적 제외 경계다. 구멍에서 자동 생성하지 않는다.
/// 면적/포함/간섭/자기 교차를 검사하지 않아 생성 성공은 유효 면 판정이 아니다.
@Freezed(
  fromJson: false,
  toJson: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
@JsonSerializable()
final class TextRegion with _$TextRegion {
  TextRegion({required this.outer, required List<ClosedBoundary> exclusions})
    : exclusions = List.unmodifiable(exclusions);

  /// 텍스트 배치를 허용할 바깥 경계다. 자재 절단 경계로 해석하지 않는다.
  @JsonKey(fromJson: _readRegionOuter, toJson: _writeBoundary)
  final ClosedBoundary outer;

  /// 명시적으로 지정된 제외 경계다. 빈 목록은 제외 없음이며 필드 누락과 다르다.
  @JsonKey(fromJson: _readExclusions, toJson: _writeBoundaries)
  final List<ClosedBoundary> exclusions;
  factory TextRegion.fromJson(Object? json) {
    final object = _readDesignObject(json);
    _requireDesignField(object, 'outer');
    _requireDesignField(object, 'exclusions');
    _checkDesignFields(object, const {'outer', 'exclusions'});
    return _$TextRegionFromJson(object);
  }
  Map<String, Object?> toJson() => _$TextRegionToJson(this);

  /// 외부/제외 경계를 함께 환산하며 관계를 자동 보정하거나 분할하지 않는다.
  TextRegion converted({required LengthUnit from, required LengthUnit to}) =>
      TextRegion(
        outer: _convertBoundary(outer, from, to, 'outer'),
        exclusions: [
          for (var i = 0; i < exclusions.length; i++)
            _convertBoundary(exclusions[i], from, to, 'exclusions[$i]'),
        ],
      );
}

Map<String, Object?> _readDesignObject(Object? json) {
  if (json is! Map<String, Object?>) {
    throw DesignValidationException(
      DesignValidationIssue(
        code: DesignErrorCode.invalidType,
        fieldPath: r'$',
        details: DesignTypeDetails(
          expectedType: 'object',
          actualType: json.runtimeType.toString(),
        ),
      ),
    );
  }
  return json;
}

Object? _requireDesignField(Map<String, Object?> object, String key) {
  if (!object.containsKey(key)) {
    throw DesignValidationException(
      DesignValidationIssue(code: DesignErrorCode.missingField, fieldPath: key),
    );
  }
  return object[key];
}

void _readDesignString(Map<String, Object?> object, String key) {
  final value = _requireDesignField(object, key);
  if (value is! String) {
    throw DesignValidationException(
      DesignValidationIssue(
        code: DesignErrorCode.invalidType,
        fieldPath: key,
        details: DesignTypeDetails(
          expectedType: 'String',
          actualType: value.runtimeType.toString(),
        ),
      ),
    );
  }
}

void _checkDesignFields(Map<String, Object?> object, Set<String> allowed) {
  for (final key in object.keys) {
    if (!allowed.contains(key)) {
      throw DesignValidationException(
        DesignValidationIssue(
          code: DesignErrorCode.unexpectedField,
          fieldPath: key,
        ),
      );
    }
  }
}

List _readDesignList(Object? json, String fieldPath) {
  if (json is! List) {
    throw DesignValidationException(
      DesignValidationIssue(
        code: DesignErrorCode.invalidType,
        fieldPath: fieldPath,
        details: DesignTypeDetails(
          expectedType: 'List',
          actualType: json.runtimeType.toString(),
        ),
      ),
    );
  }
  return json;
}

ClosedBoundary _readBoundary(Object? json, String fieldPath) {
  try {
    return ClosedBoundary.fromJson(json);
  } on GeometryValidationException catch (error) {
    throw error.prefixed(fieldPath);
  }
}

ClosedBoundary _readOutline(Object? json) => _readBoundary(json, 'outline');
ClosedBoundary _readCutoutBoundary(Object? json) =>
    _readBoundary(json, 'boundary');
ClosedBoundary _readRegionOuter(Object? json) => _readBoundary(json, 'outer');
Map<String, Object?> _writeBoundary(ClosedBoundary boundary) =>
    boundary.toJson();
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
  final values = _readDesignList(json, 'cutouts');
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
  final values = _readDesignList(json, 'textAreas');
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

TextRegion _readTextRegion(Object? json) {
  try {
    return TextRegion.fromJson(json);
  } on DesignValidationException catch (error) {
    throw error.prefixed('region');
  } on GeometryValidationException catch (error) {
    throw error.prefixed('region');
  }
}

Map<String, Object?> _writeTextRegion(TextRegion region) => region.toJson();
List<ClosedBoundary> _readExclusions(Object? json) {
  final values = _readDesignList(json, 'exclusions');
  return [
    for (var i = 0; i < values.length; i++)
      _readBoundary(values[i], 'exclusions[$i]'),
  ];
}

List<Map<String, Object?>> _writeBoundaries(List<ClosedBoundary> boundaries) =>
    [for (final boundary in boundaries) boundary.toJson()];
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
