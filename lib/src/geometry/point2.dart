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
  /// 문맥 단위 x/y가 유한한지 검사한다. NaN/무한대는 GeometryValidationException이며 음수·0은 허용한다.
  Point2({required this.x, required this.y}) {
    checkFiniteGeometryNumber(x, 'x');
    checkFiniteGeometryNumber(y, 'y');
  }

  /// 도안 기준점에서 오른쪽으로 잰 문맥 단위 좌표다.
  final double x;

  /// 도안 기준점에서 위쪽으로 잰 문맥 단위 좌표다.
  final double y;

  /// 필수 x/y의 정수·소수 JSON 수치를 double로 복원하고 생성자 검증을 적용한다.
  /// 누락·타입·추가 필드·비유한 수치는 기하 오류로 구분한다. 단위 태그는 점 안에 없다.
  factory Point2.fromJson(Object? json) {
    final object = readGeometryObject(json);
    checkGeometryNumber(object, 'x');
    checkGeometryNumber(object, 'y');
    checkGeometryFields(object, const {'x', 'y'});
    return _$Point2FromJson(object);
  }

  /// x/y를 double 값으로 내보낸다. 반올림하거나 화면 픽셀·출력 좌표로 변환하지 않는다.
  Map<String, Object?> toJson() => _$Point2ToJson(this);

  /// 명시한 원본/대상 단위로 두 좌표를 함께 환산한다. 반올림·회전은 하지 않는다.
  @useResult
  Point2 converted({required LengthUnit from, required LengthUnit to}) =>
      Point2(
        x: convertGeometryLength(x, from, to, 'x'),
        y: convertGeometryLength(y, from, to, 'y'),
      );
}

/// 내부 변환 도우미다. 점 복원 오류의 진단을 보존하고 지정한 부모 fieldPath를 연결한다. 공개 export가 아니다.
Point2 readGeometryPoint(Object? json, String fieldPath) {
  try {
    return Point2.fromJson(json);
  } on GeometryValidationException catch (error, stackTrace) {
    Error.throwWithStackTrace(
      error.prefixed(fieldPath, stackTrace: stackTrace),
      stackTrace,
    );
  }
}

/// 내부 JSON 필드 변환용이다. 점의 문맥 단위 수치를 보정 없이 내보내며 공개 export하지 않는다.
Map<String, Object?> writeGeometryPoint(Point2 point) => point.toJson();
