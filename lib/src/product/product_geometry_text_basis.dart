import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:r_edit_workflow/src/design/cutout_definition.dart';
import 'package:r_edit_workflow/src/geometry/closed_boundary.dart';
import 'package:r_edit_workflow/src/geometry/coordinate_space.dart';
import 'package:r_edit_workflow/src/product/area_geometry_text_basis.dart';
import 'package:r_edit_workflow/src/product/geometry_text_basis_errors.dart';

part 'product_geometry_text_basis.freezed.dart';

/// 한 제품의 형상·문구 부분만 담는 불변 근거다. 완전한 배치 입력/현재성/저장 판정이 아니다.
/// 영역은 ID별 값으로 비교하고 관통/경계 내부의 순서는 유지한다.
@Freezed(
  copyWith: false,
  fromJson: false,
  toJson: false,
  toStringOverride: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
final class ProductGeometryTextBasis with _$ProductGeometryTextBasis {
  /// 제품 빈 ID·소유 관통/영역 ID 중복을 GeometryTextBasisException으로 거부한다.
  /// 목록은 방어 복사한다. 수정은 이 생성자를 통한 새 값으로만 하며 copyWith/JSON은 없다.
  ProductGeometryTextBasis({
    required this.productId,
    required this.coordinateSpace,
    required this.outline,
    required List<CutoutDefinition> cutouts,
    required List<AreaGeometryTextBasis> areas,
  }) : cutouts = List.unmodifiable(cutouts),
       areasById = _indexAreas(areas) {
    if (productId.isEmpty) throw GeometryTextBasisException.emptyProductId();
    final indices = <String, int>{};
    for (final (index, cutout) in this.cutouts.indexed) {
      final first = indices[cutout.cutoutId];
      if (first != null) {
        throw GeometryTextBasisException.duplicateCutout(
          cutoutId: cutout.cutoutId,
          firstIndex: first,
          duplicateIndex: index,
        );
      }
      indices[cutout.cutoutId] = index;
    }
  }

  /// 구성 안에서 대상으로 선택한 제품 ID다. 다른 제품과 암묵 비교하지 않는다.
  final String productId;

  /// 모든 하위 길이의 단위와 설계 기준점/X 오른쪽·Y 위쪽 문맥이다.
  final DrawingCoordinateSpace coordinateSpace;

  /// 실제 외곽이다. 특정 명판 종류나 화면/DXF 좌표로 제한하지 않는다.
  final ClosedBoundary outline;

  /// 순서까지 비교하는 관통 가공 경계 목록이다. 원형으로 제한하지 않는다.
  final List<CutoutDefinition> cutouts;

  /// 영역 ID를 키로 한 유일 정본이다. 맵 동등성은 삽입 순서에 무관하며 수정할 수 없다.
  final Map<String, AreaGeometryTextBasis> areasById;

  /// 전달 순서의 수정 불가 관찰 목록이다. 진단 인덱스는 이 목록 기준이며 정렬하지 않는다.
  List<AreaGeometryTextBasis> get areas => List.unmodifiable(areasById.values);
}

Map<String, AreaGeometryTextBasis> _indexAreas(
  List<AreaGeometryTextBasis> areas,
) {
  final result = <String, AreaGeometryTextBasis>{};
  final indices = <String, int>{};
  for (final (index, area) in areas.indexed) {
    final first = indices[area.areaId];
    if (first != null) {
      throw GeometryTextBasisException.duplicateArea(
        areaId: area.areaId,
        firstIndex: first,
        duplicateIndex: index,
      );
    }
    indices[area.areaId] = index;
    result[area.areaId] = area;
  }
  return Map.unmodifiable(result);
}
