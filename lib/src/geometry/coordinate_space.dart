import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:r_edit_workflow/src/geometry/geometry_errors.dart';
import 'package:r_edit_workflow/src/geometry/geometry_json.dart';
part 'coordinate_space.freezed.dart';
part 'coordinate_space.g.dart';

/// 도안 문맥의 명시적 길이 단위다. 개별 좌표에 반복 저장하지 않는다.
enum LengthUnit {
  /// 1/1000 미터를 길이 1로 삼는다. 화면 픽셀 단위가 아니다.
  millimeter,

  /// 25.4 밀리미터를 길이 1로 삼는다. 환산은 전체 기하 길이에 적용한다.
  inch,
}

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
  /// 하위 기하가 따를 길이 단위를 명시한다. 이 객체만 바꿔도 기존 좌표가 환산되는 것은 아니다.
  DrawingCoordinateSpace({required this.lengthUnit});

  /// 하위 좌표·반지름의 공통 단위다. 전체 환산에는 소유 DrawingGeometry/DesignGeometry의 convertedTo를 사용한다.
  final LengthUnit lengthUnit;

  /// millimeter/inch 태그만 복원한다. 누락·잘못된 타입·미지원 태그·추가 필드는 기하 오류로 거부한다.
  factory DrawingCoordinateSpace.fromJson(Object? json) {
    final object = readGeometryObject(json);
    final tag = readGeometryString(object, 'lengthUnit');
    if (tag != 'millimeter' && tag != 'inch') {
      throw GeometryValidationException(
        GeometryErrorCode.unsupportedTag,
        'lengthUnit',
        GeometryDiagnostic(
          operation: 'readLengthUnit',
          details: GeometryTagDetails(
            tag,
            supportedValues: const ['millimeter', 'inch'],
          ),
        ),
      );
    }
    checkGeometryFields(object, const {'lengthUnit'});
    return _$DrawingCoordinateSpaceFromJson(object);
  }

  /// 명시적인 lengthUnit 태그만 내보낸다. 화면 축·원점 변환·좌표 환산을 수행하지 않는다.
  Map<String, Object?> toJson() => _$DrawingCoordinateSpaceToJson(this);
}

// 동일 실길이를 다른 문맥으로 환산한다. 태그만 바꾸거나 소실을 숨기지 않는다.
/// 내부 길이 환산 도우미다. 입력은 from, 출력은 to 단위이며 1 inch=25.4 mm를 사용한다.
/// 비유한 결과나 0이 아닌 값의 소실은 numericRepresentationFailure와 지정 fieldPath로 거부한다. 공개 export하지 않는다.
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
