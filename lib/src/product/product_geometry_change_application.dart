part of 'product_design_edit_session.dart';

/// 최종 반영의 구조화된 결과다. 외부 생성/수정/JSON은 제공하지 않는다.
sealed class ProductGeometryChangeApplication {
  ProductGeometryChangeApplication._(this.state);

  /// 해당 호출이 확정하거나 그대로 보존한 상태다. 이후 최신 정본을 덮어쓰는 입력이 아니다.
  final ProductDesignEditState state;
}

/// 검토한 후보를 그대로 채택한 성공이다. 구성은 확정 state에서 파생한다.
final class AppliedProductGeometryChange
    extends ProductGeometryChangeApplication {
  AppliedProductGeometryChange._(super.state, this.summary) : super._();

  /// 실제 확정한 전체 구성이다. 요약만으로 성공을 판단하지 않는다.
  ProductDesignConfiguration get configuration => state.configuration;

  /// 준비 당시 검토한 불변 요약이다. 반영 때 다시 계산하지 않는다.
  final ProductGeometryChangeSummary summary;
}

/// 정상적인 수명/기준 거부다. 어떤 부분 구성도 반영하지 않는다.
final class RejectedProductGeometryChange
    extends ProductGeometryChangeApplication {
  RejectedProductGeometryChange._(
    super.state,
    List<ProductGeometryChangeApplicationIssue> issues,
  ) : issues = List.unmodifiable(issues),
      super._() {
    if (this.issues.isEmpty) throw StateError('반영 거부에는 진단이 필요합니다.');
  }

  /// 원문/전체 구성을 복제하지 않는 수정 불가 진단 목록이다. 순서는 계약이 아니다.
  final List<ProductGeometryChangeApplicationIssue> issues;
}
