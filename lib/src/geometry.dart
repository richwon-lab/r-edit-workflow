import 'package:freezed_annotation/freezed_annotation.dart';

part 'geometry.freezed.dart';
part 'geometry.g.dart';

/// 형상 값·JSON 구조가 유효하지 않은 원인이다. 배치 판정은 포함하지 않는다.
enum GeometryErrorCode {
  missingField,
  invalidType,
  unexpectedField,
  emptyHoleId,
  emptyAreaId,
  nonFiniteNumber,
  nonPositiveDimension,
  nonFiniteBoundary,
  duplicateHoleId,
}

/// [fieldPath]는 호출한 모델 기준 필드/목록 위치다. 문자 위치가 아니다.
final class GeometryValidationException implements Exception {
  const GeometryValidationException(this.code, this.fieldPath);
  final GeometryErrorCode code;
  final String fieldPath;

  @override
  String toString() => 'GeometryValidationException(${code.name}, $fieldPath)';
}

/// 왼쪽 아래 (0,0), 오른쪽 +X·위쪽 +Y인 직사각 명판의 mm 형상이다.
///
/// 홀 ID 중복과 값 자체만 검사한다. 홀의 명판 포함·간섭·제작 가능성은 검사하지 않는다.
@Freezed(
  fromJson: false,
  toJson: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
@JsonSerializable()
final class RectangularPlateGeometry with _$RectangularPlateGeometry {
  RectangularPlateGeometry({
    required this.widthMm,
    required this.heightMm,
    required List<CircularHole> holes,
  }) : holes = List.unmodifiable(holes) {
    _positive(widthMm, 'widthMm');
    _positive(heightMm, 'heightMm');
    final ids = <String>{};
    for (var i = 0; i < this.holes.length; i++) {
      if (!ids.add(this.holes[i].holeId)) {
        throw GeometryValidationException(
          GeometryErrorCode.duplicateHoleId,
          'holes[$i].holeId',
        );
      }
    }
  }

  /// 폭·높이는 mm이며 유한한 양수다.
  final double widthMm;
  final double heightMm;

  /// 명시적 빈 목록은 홀 없음이다. 입력 목록과 분리하여 보관한다.
  @JsonKey(fromJson: _holesFromJson, toJson: _holesToJson)
  final List<CircularHole> holes;

  factory RectangularPlateGeometry.fromJson(Object? json) {
    final object = _geometryObject(json);
    _numberField(object, 'widthMm');
    _numberField(object, 'heightMm');
    _geometryRequired(object, 'holes');
    _geometryFields(object, const {'widthMm', 'heightMm', 'holes'});
    return _$RectangularPlateGeometryFromJson(object);
  }
  Map<String, Object?> toJson() => _$RectangularPlateGeometryToJson(this);
}

/// 명판 좌표계의 중심과 지름을 mm로 표현한 원형 홀이다.
/// 음수 중심도 표현한다. 외곽 포함과 다른 형상과의 관계는 별도 책임이다.
@Freezed(
  fromJson: false,
  toJson: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
@JsonSerializable()
final class CircularHole with _$CircularHole {
  CircularHole({
    required this.holeId,
    required this.centerXMm,
    required this.centerYMm,
    required this.diameterMm,
  }) {
    if (holeId.isEmpty) {
      throw const GeometryValidationException(
        GeometryErrorCode.emptyHoleId,
        'holeId',
      );
    }
    _finite(centerXMm, 'centerXMm');
    _finite(centerYMm, 'centerYMm');
    _positive(diameterMm, 'diameterMm');
    final radius = diameterMm / 2;
    _boundary(centerXMm - radius, 'centerXMm');
    _boundary(centerXMm + radius, 'centerXMm');
    _boundary(centerYMm - radius, 'centerYMm');
    _boundary(centerYMm + radius, 'centerYMm');
  }

  /// 표시 이름·좌표·목록 순서와 독립된 ID다. 문자열을 보정하지 않는다.
  final String holeId;
  final double centerXMm;
  final double centerYMm;
  final double diameterMm;

  factory CircularHole.fromJson(Object? json) {
    final object = _geometryObject(json);
    _geometryString(object, 'holeId');
    _numberField(object, 'centerXMm');
    _numberField(object, 'centerYMm');
    _numberField(object, 'diameterMm');
    _geometryFields(object, const {
      'holeId',
      'centerXMm',
      'centerYMm',
      'diameterMm',
    });
    return _$CircularHoleFromJson(object);
  }
  Map<String, Object?> toJson() => _$CircularHoleToJson(this);
}

/// 명판 좌표의 왼쪽 아래와 폭·높이(mm)로 표현한 축 평행 텍스트 영역이다.
/// 화면 좌표가 아니며 명판 포함·영역 중첩·글자 충돌은 검사하지 않는다.
@Freezed(
  fromJson: false,
  toJson: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
@JsonSerializable()
final class TextAreaBounds with _$TextAreaBounds {
  TextAreaBounds({
    required this.xMm,
    required this.yMm,
    required this.widthMm,
    required this.heightMm,
  }) {
    _finite(xMm, 'xMm');
    _finite(yMm, 'yMm');
    _positive(widthMm, 'widthMm');
    _positive(heightMm, 'heightMm');
    _boundary(xMm + widthMm, 'xMm');
    _boundary(yMm + heightMm, 'yMm');
  }
  final double xMm;
  final double yMm;
  final double widthMm;
  final double heightMm;

  factory TextAreaBounds.fromJson(Object? json) {
    final object = _geometryObject(json);
    for (final key in const ['xMm', 'yMm', 'widthMm', 'heightMm']) {
      _numberField(object, key);
    }
    _geometryFields(object, const {'xMm', 'yMm', 'widthMm', 'heightMm'});
    return _$TextAreaBoundsFromJson(object);
  }
  Map<String, Object?> toJson() => _$TextAreaBoundsToJson(this);
}

/// 도안이 소유할 영역 정의다. 문구·줄바꿈은 TextAreaInput의 별도 책임이다.
/// 다른 영역의 ID 중복·참조 존재·홀과의 관계는 이 값에서 검사하지 않는다.
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
    required this.bounds,
  }) {
    if (areaId.isEmpty) {
      throw const GeometryValidationException(
        GeometryErrorCode.emptyAreaId,
        'areaId',
      );
    }
  }
  final String areaId;

  /// 필수 표시 문자열이며 빈 문자열도 허용한다. trim/정규화를 하지 않는다.
  final String label;
  @JsonKey(fromJson: _boundsFromJson, toJson: _boundsToJson)
  final TextAreaBounds bounds;

  factory TextAreaDefinition.fromJson(Object? json) {
    final object = _geometryObject(json);
    _geometryString(object, 'areaId');
    _geometryString(object, 'label');
    _geometryRequired(object, 'bounds');
    _geometryFields(object, const {'areaId', 'label', 'bounds'});
    return _$TextAreaDefinitionFromJson(object);
  }
  Map<String, Object?> toJson() => _$TextAreaDefinitionToJson(this);
}

void _finite(double value, String fieldPath) {
  if (!value.isFinite) {
    throw GeometryValidationException(
      GeometryErrorCode.nonFiniteNumber,
      fieldPath,
    );
  }
}

void _positive(double value, String fieldPath) {
  _finite(value, fieldPath);
  if (value <= 0) {
    throw GeometryValidationException(
      GeometryErrorCode.nonPositiveDimension,
      fieldPath,
    );
  }
}

void _boundary(double value, String fieldPath) {
  if (!value.isFinite) {
    throw GeometryValidationException(
      GeometryErrorCode.nonFiniteBoundary,
      fieldPath,
    );
  }
}

Map<String, Object?> _geometryObject(Object? value) {
  if (value is! Map<String, Object?>) {
    throw const GeometryValidationException(
      GeometryErrorCode.invalidType,
      r'$',
    );
  }
  return value;
}

Object? _geometryRequired(Map<String, Object?> object, String key) {
  if (!object.containsKey(key)) {
    throw GeometryValidationException(GeometryErrorCode.missingField, key);
  }
  return object[key];
}

void _geometryString(Map<String, Object?> object, String key) {
  if (_geometryRequired(object, key) is! String) {
    throw GeometryValidationException(GeometryErrorCode.invalidType, key);
  }
}

void _numberField(Map<String, Object?> object, String key) {
  if (_geometryRequired(object, key) is! num) {
    throw GeometryValidationException(GeometryErrorCode.invalidType, key);
  }
}

void _geometryFields(Map<String, Object?> object, Set<String> allowed) {
  for (final key in object.keys) {
    if (!allowed.contains(key)) {
      throw GeometryValidationException(GeometryErrorCode.unexpectedField, key);
    }
  }
}

List<CircularHole> _holesFromJson(Object? json) {
  if (json is! List) {
    throw const GeometryValidationException(
      GeometryErrorCode.invalidType,
      'holes',
    );
  }
  final holes = <CircularHole>[];
  for (var i = 0; i < json.length; i++) {
    try {
      holes.add(CircularHole.fromJson(json[i]));
    } on GeometryValidationException catch (error) {
      final suffix = error.fieldPath == r'$' ? '' : '.${error.fieldPath}';
      throw GeometryValidationException(error.code, 'holes[$i]$suffix');
    }
  }
  return holes;
}

List<Map<String, Object?>> _holesToJson(List<CircularHole> holes) => [
  for (final hole in holes) hole.toJson(),
];
TextAreaBounds _boundsFromJson(Object? json) {
  try {
    return TextAreaBounds.fromJson(json);
  } on GeometryValidationException catch (error) {
    final suffix = error.fieldPath == r'$' ? '' : '.${error.fieldPath}';
    throw GeometryValidationException(error.code, 'bounds$suffix');
  }
}

Map<String, Object?> _boundsToJson(TextAreaBounds bounds) => bounds.toJson();
