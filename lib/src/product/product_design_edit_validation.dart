import 'package:meta/meta.dart';
import 'package:r_edit_workflow/src/product/product_design_configuration.dart';
import 'package:r_edit_workflow/src/product/product_design_edit_session.dart';
import 'package:r_edit_workflow/src/product/product_geometry_change_application_errors.dart';

/// 내부 최신 상태의 수명/개정/전체 기준을 검사한다. 정본 설치 API가 아니다.
/// 정상 공개 경로로 만들 수 없는 같은 개정/다른 내용도 이 책임에서 시험한다.
@internal
@useResult
List<ProductGeometryChangeApplicationIssue> validateProductDesignEditBasis({
  required ProductDesignEditSessionId currentSessionId,
  required int currentRevision,
  required bool isClosed,
  required ProductDesignConfiguration currentConfiguration,
  required ProductDesignEditBasis basis,
}) {
  if (currentRevision < 0) {
    throw ArgumentError.value(
      currentRevision,
      'currentRevision',
      '개정은 0 이상이어야 합니다.',
    );
  }
  if (isClosed) {
    return List.unmodifiable([
      ProductGeometryChangeApplicationIssue(
        code: ProductGeometryChangeApplicationCode.closedEditSession,
        fieldPath: 'current.isClosed',
        details: ClosedEditSessionDetails(
          currentSessionId: currentSessionId,
          preparedSessionId: basis.sessionId,
        ),
      ),
    ]);
  }
  if (!identical(currentSessionId, basis.sessionId)) {
    return List.unmodifiable([
      ProductGeometryChangeApplicationIssue(
        code: ProductGeometryChangeApplicationCode.differentEditSession,
        fieldPath: 'prepared.basis.sessionId',
        details: EditSessionMismatchDetails(
          expectedSessionId: currentSessionId,
          actualSessionId: basis.sessionId,
        ),
      ),
    ]);
  }
  final issues = <ProductGeometryChangeApplicationIssue>[];
  if (currentRevision != basis.revision) {
    issues.add(
      ProductGeometryChangeApplicationIssue(
        code: ProductGeometryChangeApplicationCode.staleEditRevision,
        fieldPath: 'prepared.basis.revision',
        details: EditRevisionMismatchDetails(
          sessionId: currentSessionId,
          expectedRevision: currentRevision,
          actualRevision: basis.revision,
        ),
      ),
    );
  }
  if (currentConfiguration != basis.configuration) {
    issues.add(
      ProductGeometryChangeApplicationIssue(
        code:
            ProductGeometryChangeApplicationCode.baselineConfigurationMismatch,
        fieldPath: 'prepared.basis.configuration',
        details: EditBaselineMismatchDetails(
          sessionId: currentSessionId,
          currentRevision: currentRevision,
          preparedRevision: basis.revision,
        ),
      ),
    );
  }
  return List.unmodifiable(issues);
}

/// 내부 채택 자료를 부작용 없이 준비한다. 실패하면 호출자는 아직 상태를 교체하지 않는다.
/// 임의 편집 횟수 상한 대신 실행 int의 증가 결과가 실제로 커졌는지 검사한다.
@internal
@useResult
({int revision, ProductDesignConfiguration configuration})
prepareProductDesignEditCommit({
  required int revision,
  required ProductDesignConfiguration candidate,
}) {
  if (revision < 0) {
    throw ArgumentError.value(revision, 'revision', '개정은 0 이상이어야 합니다.');
  }
  final next = revision + 1;
  if (next <= revision) {
    throw StateError('다음 편집 개정을 int로 표현할 수 없습니다. 상태는 채택하지 않았습니다.');
  }
  return (revision: next, configuration: candidate);
}
