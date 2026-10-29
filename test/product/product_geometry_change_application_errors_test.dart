import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/product_geometry_changes.dart';

void main() {
  late ProductDesignEditSessionId token;
  late ProductDesignEditSessionId other;
  setUp(() {
    final configuration = twoProductsSharingTitleGeometry();
    token = ProductDesignEditSession.open(configuration: configuration)
        .state
        .sessionId;
    other = ProductDesignEditSession.open(configuration: configuration)
        .state
        .sessionId;
  });
  Matcher argument(String name, Object value) => throwsA(
    isA<ArgumentError>()
        .having((e) => e.name, '인자', name)
        .having((e) => e.invalidValue, '문제 값', value)
        .having(
          (e) => e.message,
          '조건 설명',
          isA<String>().having((s) => s.isNotEmpty, '설명 있음', isTrue),
        ),
  );
  test('세션 불일치 상세는 같은 발급 토큰을 거부한다', () {
    expect(
      () => EditSessionMismatchDetails(
        expectedSessionId: token,
        actualSessionId: token,
      ),
      argument('actualSessionId', token),
    );
    final detail = EditSessionMismatchDetails(
      expectedSessionId: token,
      actualSessionId: other,
    );
    expect(detail.expectedSessionId, same(token));
    expect(detail.actualSessionId, same(other));
  });
  for (final field in [
    'expectedRevision',
    'actualRevision',
    'currentRevision',
    'preparedRevision',
  ]) {
    test('$field 음수 상세는 문제 인자와 값으로 거부한다', () {
      expect(
        () => switch (field) {
          'expectedRevision' => EditRevisionMismatchDetails(
            sessionId: token,
            expectedRevision: -1,
            actualRevision: 0,
          ),
          'actualRevision' => EditRevisionMismatchDetails(
            sessionId: token,
            expectedRevision: 0,
            actualRevision: -1,
          ),
          'currentRevision' => EditBaselineMismatchDetails(
            sessionId: token,
            currentRevision: -1,
            preparedRevision: 0,
          ),
          _ => EditBaselineMismatchDetails(
            sessionId: token,
            currentRevision: 0,
            preparedRevision: -1,
          ),
        },
        argument(field, -1),
      );
    });
  }
  test('개정 불일치 상세는 같은 개정 값을 거부한다', () {
    expect(
      () => EditRevisionMismatchDetails(
        sessionId: token,
        expectedRevision: 3,
        actualRevision: 3,
      ),
      argument('actualRevision', 3),
    );
  });
  test('반영 코드와 상세 타입이 다르면 runtimeType과 조건으로 거부한다', () {
    final details = ClosedEditSessionDetails(
      currentSessionId: token,
      preparedSessionId: other,
    );
    expect(
      () => ProductGeometryChangeApplicationIssue(
        code: ProductGeometryChangeApplicationCode.staleEditRevision,
        fieldPath: 'prepared.basis.revision',
        details: details,
      ),
      argument('details', details.runtimeType),
    );
  });
  test('실제 위치가 아닌 경로는 코드별 정확한 경로로 거부한다', () {
    expect(
      () => ProductGeometryChangeApplicationIssue(
        code: ProductGeometryChangeApplicationCode.closedEditSession,
        fieldPath: 'request.closed',
        details: ClosedEditSessionDetails(
          currentSessionId: token,
          preparedSessionId: token,
        ),
      ),
      argument('fieldPath', 'request.closed'),
    );
  });
  test('출력은 코드·위치·설명·개정을 제공하며 전체 구성은 상세에 없다', () {
    final detail = EditRevisionMismatchDetails(
      sessionId: token,
      expectedRevision: 2,
      actualRevision: 0,
    );
    final issue = ProductGeometryChangeApplicationIssue(
      code: ProductGeometryChangeApplicationCode.staleEditRevision,
      fieldPath: 'prepared.basis.revision',
      details: detail,
    );
    expect(issue.details, same(detail));
    expect(issue.toString(), contains('staleEditRevision'));
    expect(issue.toString(), contains('prepared.basis.revision'));
    expect(issue.toString(), contains('expectedRevision=2'));
    expect(issue.toString(), contains('actualRevision=0'));
    expect(issue.toString(), contains(issue.code.description));
  });
}
