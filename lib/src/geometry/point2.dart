import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:r_edit_workflow/src/geometry/coordinate_space.dart';
import 'package:r_edit_workflow/src/geometry/geometry_errors.dart';
import 'package:r_edit_workflow/src/geometry/geometry_json.dart';
part 'point2.freezed.dart';
part 'point2.g.dart';

/// 도안 문맥 단위를 따르는 유한 2D 좌표다. 음수도 허용하며 화면 픽셀이 아니다.
/// 생성·copyWith·복원은 nonFiniteNumber를 거부한다. 다른 형상 관계는 검사하지 않는다.
@Freezed(
  fromJson: false,
  toJson: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
@JsonSerializable()
final class Point2 with _$Point2 {
  Point2({required this.x, required this.y}) {
    checkFiniteGeometryNumber(x, 'x');
    checkFiniteGeometryNumber(y, 'y');
  }

  /// 도안 기준점에서 오른쪽으로 잰 문맥 단위 좌표다.
  final double x;

  /// 도안 기준점에서 위쪽으로 잰 문맥 단위 좌표다.
  final double y;
  factory Point2.fromJson(Object? json) {
    final object = readGeometryObject(json);
    checkGeometryNumber(object, 'x');
    checkGeometryNumber(object, 'y');
    checkGeometryFields(object, const {'x', 'y'});
    return _$Point2FromJson(object);
  }
  Map<String, Object?> toJson() => _$Point2ToJson(this);

  /// 명시한 원본/대상 단위로 두 좌표를 함께 환산한다. 반올림·회전은 하지 않는다.
  Point2 converted({required LengthUnit from, required LengthUnit to}) =>
      Point2(
        x: convertGeometryLength(x, from, to, 'x'),
        y: convertGeometryLength(y, from, to, 'y'),
      );
}

Point2 readGeometryPoint(Object? json, String fieldPath) {
  try {
    return Point2.fromJson(json);
  } on GeometryValidationException catch (error) {
    throw error.prefixed(fieldPath);
  }
}

Map<String, Object?> writeGeometryPoint(Point2 point) => point.toJson();
