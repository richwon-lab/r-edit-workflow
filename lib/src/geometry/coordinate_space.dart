import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:r_edit_workflow/src/geometry/geometry_errors.dart';
import 'package:r_edit_workflow/src/geometry/geometry_json.dart';
part 'coordinate_space.freezed.dart';
part 'coordinate_space.g.dart';

/// 도안 문맥의 명시적 길이 단위다. 개별 좌표에 반복 저장하지 않는다.
enum LengthUnit { millimeter, inch }

/// 설계 기준점 (0,0), X 오른쪽/Y 위쪽인 좌표 문맥이다.
/// 원점은 외곽 왼쪽 아래로 제한하지 않는다. 문맥 단독 변경은 기하 환산이 아니다.
@Freezed(
  fromJson: false,
  toJson: false,
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
@JsonSerializable()
final class DrawingCoordinateSpace with _$DrawingCoordinateSpace {
  DrawingCoordinateSpace({required this.lengthUnit});
  final LengthUnit lengthUnit;
  factory DrawingCoordinateSpace.fromJson(Object? json) {
    final object = readGeometryObject(json);
    final tag = readGeometryString(object, 'lengthUnit');
    if (tag != 'millimeter' && tag != 'inch') {
      throw GeometryValidationException(
        GeometryErrorCode.unsupportedTag,
        'lengthUnit',
        GeometryDiagnostic(
          operation: 'readLengthUnit',
          details: GeometryTagDetails(tag),
        ),
      );
    }
    checkGeometryFields(object, const {'lengthUnit'});
    return _$DrawingCoordinateSpaceFromJson(object);
  }
  Map<String, Object?> toJson() => _$DrawingCoordinateSpaceToJson(this);
}

// 동일 실길이를 다른 문맥으로 환산한다. 태그만 바꾸거나 소실을 숨기지 않는다.
double convertGeometryLength(
  double value,
  LengthUnit from,
  LengthUnit to,
  String fieldPath,
) {
  final converted = from == to
      ? value
      : from == LengthUnit.inch
      ? value * 25.4
      : value / 25.4;
  if (!converted.isFinite || (value != 0 && converted == 0)) {
    throw GeometryValidationException(
      GeometryErrorCode.numericRepresentationFailure,
      fieldPath,
      GeometryDiagnostic(
        operation: 'convertLength:${from.name}->${to.name}',
        details: GeometryNumberDetails(value),
      ),
    );
  }
  return converted;
}
