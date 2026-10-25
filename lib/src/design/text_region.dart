import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:r_edit_workflow/src/design/design_json.dart';
import 'package:r_edit_workflow/src/geometry/closed_boundary.dart';
import 'package:r_edit_workflow/src/geometry/coordinate_space.dart';
import 'package:r_edit_workflow/src/geometry/geometry_errors.dart';

part 'text_region.freezed.dart';
part 'text_region.g.dart';

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
  @JsonKey(fromJson: _readRegionOuter, toJson: writeBoundary)
  final ClosedBoundary outer;

  /// 명시적으로 지정된 제외 경계다. 빈 목록은 제외 없음이며 필드 누락과 다르다.
  @JsonKey(fromJson: _readExclusions, toJson: _writeBoundaries)
  final List<ClosedBoundary> exclusions;
  factory TextRegion.fromJson(Object? json) {
    final object = readDesignObject(json);
    requireDesignField(object, 'outer');
    requireDesignField(object, 'exclusions');
    checkDesignFields(object, const {'outer', 'exclusions'});
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

ClosedBoundary _readRegionOuter(Object? json) => readBoundary(json, 'outer');

List<ClosedBoundary> _readExclusions(Object? json) {
  final values = readDesignList(json, 'exclusions');
  return [
    for (var i = 0; i < values.length; i++)
      readBoundary(values[i], 'exclusions[$i]'),
  ];
}

List<Map<String, Object?>> _writeBoundaries(List<ClosedBoundary> boundaries) =>
    [for (final boundary in boundaries) boundary.toJson()];

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
