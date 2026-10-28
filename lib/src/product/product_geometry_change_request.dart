import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:r_edit_workflow/src/design/applied_design_geometry.dart';
import 'package:r_edit_workflow/src/product/product_geometry_target.dart';

part 'product_geometry_change_request.freezed.dart';

/// 고정 제품 목록에 적용할 형상 변경 의도다. JSON 저장/현재 상태 반영 API가 아니다.
sealed class ProductGeometryChangeRequest {
  /// 하위 의도만 생성하며 부분 수정과 다른 도안 교체를 타입으로 구분한다.
  const ProductGeometryChangeRequest();

  /// ID·실제 내용·선택 출처를 함께 가진 불변 제안이다.
  AppliedDesignGeometry get proposedGeometry;

  /// 같은 도안을 사용하는 비대상/미래 제품은 포함하지 않는 명시 요청 목록이다.
  List<ProductGeometryTarget> get targets;
}

/// 같은 업무 영역 ID를 유지한다는 호출자의 선언을 가진 부분 수정이다.
/// 유지 영역의 입력을 대응/제거/신규 공급으로 덮어쓸 수 없다.
@Freezed(
  fromJson: false,
  toJson: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
final class ReviseAppliedGeometry extends ProductGeometryChangeRequest
    with _$ReviseAppliedGeometry {
  /// 대상 목록을 방어 복사한다. 빈/없는/중복 대상과 source 불일치는 준비 진단이다.
  ReviseAppliedGeometry({
    required this.sourceAppliedGeometryId,
    required this.proposedGeometry,
    required List<ProductGeometryTarget> targets,
  }) : targets = List.unmodifiable(targets);

  /// 모든 대상이 기준에서 참조해야 하는 적용 ID다.
  final String sourceAppliedGeometryId;
  @override
  final AppliedDesignGeometry proposedGeometry;
  @override
  final List<ProductGeometryTarget> targets;
}

/// 다른 도안으로의 교체다. 같은 areaId 문자열에도 자동 유지는 없다.
@Freezed(
  fromJson: false,
  toJson: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
final class ReplaceAppliedGeometry extends ProductGeometryChangeRequest
    with _$ReplaceAppliedGeometry {
  /// 이전 적용 ID가 서로 다른 제품도 선택할 수 있으며 모든 입력의 처리는 명시해야 한다.
  ReplaceAppliedGeometry({
    required this.proposedGeometry,
    required List<ProductGeometryTarget> targets,
  }) : targets = List.unmodifiable(targets);

  @override
  final AppliedDesignGeometry proposedGeometry;
  @override
  final List<ProductGeometryTarget> targets;
}
