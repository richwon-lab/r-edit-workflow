import 'package:meta/meta.dart';
import 'package:r_edit_workflow/src/product/applied_geometry_id_consistency.dart';
import 'package:r_edit_workflow/src/product/product_design_configuration.dart';
import 'package:r_edit_workflow/src/product/product_design_edit_validation.dart';
import 'package:r_edit_workflow/src/product/product_design_validation.dart';
import 'package:r_edit_workflow/src/product/product_geometry_change_application_errors.dart';
import 'package:r_edit_workflow/src/product/product_geometry_change_errors.dart';
import 'package:r_edit_workflow/src/product/product_geometry_change_request.dart';
import 'package:r_edit_workflow/src/product/product_geometry_change_summary.dart';
import 'package:r_edit_workflow/src/product/product_input.dart';
import 'package:r_edit_workflow/src/product/text_area_input_change_preparation.dart';

part 'product_design_edit_state.dart';
part 'product_geometry_change_preparation.dart';
part 'product_geometry_change_result.dart';
part 'product_geometry_change_application.dart';

/// 한 isolate의 편집 수명에서 현재 구성과 개정의 단일 정본을 소유한다.
/// 앱은 객체의 수명만 연결한다. 파일/세션 전송·저장·동기화·실행 취소는 지원하지 않는다.
/// 소유 객체에는 값 비교·copyWith·JSON·임의 상태 설치 경로를 제공하지 않는다.
final class ProductDesignEditSession {
  ProductDesignEditSession._(this._state);

  /// 유효 구성과 새 발급 인스턴스 토큰으로 개정 0의 활성 세션을 연다.
  /// 같은 구성/파일이어도 새 수명이다. 기존 토큰·개정은 입력받지 않는다.
  factory ProductDesignEditSession.open({
    required ProductDesignConfiguration configuration,
  }) => ProductDesignEditSession._(
    ProductDesignEditState._(
      configuration: configuration,
      sessionId: ProductDesignEditSessionId._(),
      revision: 0,
      isClosed: false,
    ),
  );

  ProductDesignEditState _state;

  /// 유일 정본의 불변 관찰값이다. 이전에 반환한 값은 나중에도 변경되지 않는다.
  ProductDesignEditState get state => _state;

  /// 한 현재 상태에서 기준을 캡처해 기존 순수 대응 계산을 실행한다.
  /// 준비는 개정을 증가시키지 않는다. 닫힌 수명의 새 준비는 StateError다.
  @useResult
  ProductGeometryChangePreparation prepareGeometryChange(
    ProductGeometryChangeRequest request,
  ) {
    final current = _state;
    if (current.isClosed) throw StateError('닫힌 편집 세션에서는 새 변경을 준비할 수 없습니다.');
    final basis = ProductDesignEditBasis._(current);
    return _prepareProductGeometryChange(basis: basis, request: request);
  }

  /// 최신 내부 정본과 수명·개정·전체 기준을 검사한 뒤 후보 그대로 한 번 교체한다.
  /// 정상 기준 거부는 Rejected이며 실패 시 구성/개정은 유지한다.
  /// await·외부 콜백·재계산·로그가 없는 동기 경계다. Ready만 입력받는다.
  @useResult
  ProductGeometryChangeApplication applyPreparedGeometryChange(
    ReadyProductGeometryChange prepared,
  ) {
    final current = _state;
    final issues = validateProductDesignEditBasis(
      currentSessionId: current.sessionId,
      currentRevision: current.revision,
      isClosed: current.isClosed,
      currentConfiguration: current.configuration,
      basis: prepared.basis,
    );
    if (issues.isNotEmpty) {
      return RejectedProductGeometryChange._(current, issues);
    }
    final commit = prepareProductDesignEditCommit(
      revision: current.revision,
      candidate: prepared._candidate,
    );
    final next = ProductDesignEditState._(
      configuration: commit.configuration,
      sessionId: current.sessionId,
      revision: commit.revision,
      isClosed: false,
    );
    final result = AppliedProductGeometryChange._(next, prepared.summary);
    _state = next;
    return result;
  }

  /// 구성/개정을 보존하고 수명만 닫는다. 반복 호출은 상태를 다시 만들지 않는다.
  /// 닫힌 인스턴스를 다시 여는 API는 없으며 남은 Ready의 apply도 정상 거부한다.
  void close() {
    final current = _state;
    if (current.isClosed) return;
    _state = ProductDesignEditState._(
      configuration: current.configuration,
      sessionId: current.sessionId,
      revision: current.revision,
      isClosed: true,
    );
  }
}
