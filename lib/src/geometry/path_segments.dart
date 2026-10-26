import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:r_edit_workflow/src/geometry/geometry_errors.dart';
import 'package:r_edit_workflow/src/geometry/geometry_json.dart';
import 'package:r_edit_workflow/src/geometry/point2.dart';
part 'path_segments.freezed.dart';
part 'path_segments.g.dart';

/// 시작점은 소유 경로가 정하는 구간이다. 모든 하위 타입은 이 library에 둔다.
sealed class PathSegment {
  /// 구간 합 타입의 기반 생성자다. 실제 시작점 의존 검증은 소유 경로에서 수행한다.
  const PathSegment();

  /// 도안 문맥 단위를 따르는 끝점이다. 시작점은 경로에서 결정된다.
  Point2 get end;

  /// kind와 끝점, 원호이면 bulge를 독립 JSON으로 내보낸다. 시작점은 소유 경로에서 결정된다.
  Map<String, Object?> toJson();

  /// line/arc 태그를 복원한다. 기하 구조·태그·값 오류를 구분하고 end의 하위 경로를 연결한다.
  factory PathSegment.fromJson(Object? json) {
    final object = readGeometryObject(json);
    final tag = readGeometryString(object, 'kind');
    switch (tag) {
      case 'line':
        requireGeometryField(object, 'end');
        checkGeometryFields(object, const {'kind', 'end'});
        return _$LineToFromJson(object);
      case 'arc':
        requireGeometryField(object, 'end');
        checkGeometryNumber(object, 'bulge');
        checkGeometryFields(object, const {'kind', 'end', 'bulge'});
        return _$ArcToFromJson(object);
      default:
        throw GeometryValidationException(
          GeometryErrorCode.unsupportedTag,
          'kind',
          GeometryDiagnostic(
            operation: 'readPathSegment',
            details: GeometryTagDetails(tag),
          ),
        );
    }
  }
}

/// 직전 끝점(첫 구간은 경로 시작점)에서 [end]로 가는 선분이다.
/// 좌표 단위는 도안 문맥을 따른다. 같은 시작/끝 검사는 경로가 맡는다.
@Freezed(
  fromJson: false,
  toJson: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
@JsonSerializable()
final class LineTo extends PathSegment with _$LineTo {
  /// 유효한 끝점을 보관한다. 시작점을 모르므로 같은 양끝점 여부는 GeometryPath가 검사한다.
  LineTo({required this.end});
  @override
  @JsonKey(fromJson: _readSegmentEnd, toJson: writeGeometryPoint)
  final Point2 end;
  @override
  Map<String, Object?> toJson() => {'kind': 'line', ..._$LineToToJson(this)};
}

/// 끝점과 무차원 bulge=tan(부호 있는 중심각/4)의 원호다.
/// 양수는 반시계, 음수는 시계이며 abs(bulge)>1도 허용한다.
/// 0/비유한 bulge만 여기서 거부한다. 시작점이 필요한 파생 검증은 경로 책임이다.
@Freezed(
  fromJson: false,
  toJson: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
@JsonSerializable()
final class ArcTo extends PathSegment with _$ArcTo {
  /// 비유한 bulge와 0을 거부한다. 같은 양끝점·반지름/중심·원호 위 극점 검사는 GeometryPath의 책임이다.
  ArcTo({required this.end, required this.bulge}) {
    checkFiniteGeometryNumber(bulge, 'bulge');
    if (bulge == 0) {
      throw GeometryValidationException(
        GeometryErrorCode.zeroArcBulge,
        'bulge',
        GeometryDiagnostic(
          operation: 'checkArcBulge',
          details: GeometryNumberDetails(bulge),
        ),
      );
    }
  }
  @override
  @JsonKey(fromJson: _readSegmentEnd, toJson: writeGeometryPoint)
  final Point2 end;

  /// 부호 있는 중심각의 1/4에 대한 tan 값이다. 무차원이며 부호/반원 초과 규약은 타입 설명을 따른다.
  final double bulge;
  @override
  Map<String, Object?> toJson() => {'kind': 'arc', ..._$ArcToToJson(this)};
}

Point2 _readSegmentEnd(Object? json) => readGeometryPoint(json, 'end');
