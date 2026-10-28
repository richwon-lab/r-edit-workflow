part of 'product_geometry_change_preparation.dart';

/// 특정 불변 baseline에 대한 준비 결과다. 최신 상태의 반영 허가나 저장 결과가 아니다.
/// 세 구체 결과는 준비 함수만 생성하며 임의 생성/copyWith/JSON 복원은 제공하지 않는다.
sealed class ProductGeometryChangePreparation {
  ProductGeometryChangePreparation._(this.baseline, this.request, this.summary);

  /// 준비 시 캡처한 유효 구성이다. 취소/거부/준비로 변경되지 않는다.
  final ProductDesignConfiguration baseline;

  /// 미완료 선택도 보존하는 원래 불변 요청이다.
  final ProductGeometryChangeRequest request;

  /// 해석 완료된 제품들의 순서 보존 요약이다. Blocked에서는 부분적이다.
  final ProductGeometryChangeSummary summary;

  /// 요청에 명시된 ID의 수정 불가 집합 뷰다. 자동 공유 대상 확장이 아니다.
  Set<String> get targetProductIds =>
      Set.unmodifiable(request.targets.map((t) => t.productId));
}

/// 전체 유효 변경 후보를 비공개로 보관한다. 현재 상태를 자동 교체하지 않는다.
/// 최종 반영 API는 아직 없으며 이 결과를 최신 상태에도 반영 가능하다고 해석하지 않는다.
final class ReadyProductGeometryChange
    extends ProductGeometryChangePreparation {
  ReadyProductGeometryChange._(
    super.baseline,
    super.request,
    super.summary,
    this._candidate,
  ) : super._() {
    if (_candidate == baseline) throw StateError('변경 없는 후보는 Ready일 수 없습니다.');
  }
  // 같은 library의 후속 명시 반영 경계만 접근할 후보다. 공개 getter를 제공하지 않는다.
  final ProductDesignConfiguration _candidate;
}

/// 독립 거부 진단을 모은 미완료 요청이다. 부분 성공 구성은 반환하지 않는다.
final class BlockedProductGeometryChange
    extends ProductGeometryChangePreparation {
  BlockedProductGeometryChange._(
    super.baseline,
    super.request,
    super.summary,
    List<ProductGeometryChangeIssue> issues,
  ) : issues = List.unmodifiable(issues),
      super._() {
    if (this.issues.isEmpty) throw StateError('Blocked에는 거부 근거가 필요합니다.');
  }

  /// 정상 거부의 수정 불가 목록이다. 순서는 계약이 아니다.
  final List<ProductGeometryChangeIssue> issues;
}

/// 모든 선택이 유효하나 전체 후보 값이 기준과 같은 결과다.
/// 미완료 대응의 대체 성공이 아니며 현재 구성을 기준으로 되돌리는 동작도 아니다.
final class UnchangedProductGeometryChange
    extends ProductGeometryChangePreparation {
  UnchangedProductGeometryChange._(super.baseline, super.request, super.summary)
    : super._();
}
