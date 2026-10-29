import 'package:r_edit_workflow/src/product/product_design_edit_session.dart';

/// 준비 요청의 거부와 구분되는 최종 반영 기준 거부다.
enum ProductGeometryChangeApplicationCode {
  /// current.isClosed가 true다. 현재/준비 토큰 상세로 닫힌 수명을 확인하고 활성 작업을 다시 선택한다.
  closedEditSession,

  /// prepared.basis.sessionId가 현재 토큰과 다르다. 기대/실제 토큰으로 다른 작업/재열기를 구분하고 재준비한다.
  differentEditSession,

  /// 같은 활성 세션의 prepared.basis.revision이 다르다. 기대/실제 개정을 보고 새 기준으로 다시 준비한다.
  staleEditRevision,

  /// 같은 활성 세션의 prepared.basis.configuration 전체 값이 다르다. 두 비교 위치와 개정을 보고 채택을 중단한다.
  baselineConfigurationMismatch;

  /// 개발자용 원인 설명이다. UI 확정 문구나 로그 출력 정책이 아니다.
  String get description => switch (this) {
    closedEditSession => '닫힌 편집 세션에는 준비한 변경을 반영할 수 없습니다.',
    differentEditSession => '준비 결과가 다른 편집 세션에서 만들어졌습니다.',
    staleEditRevision => '준비 이후 수락된 편집이 있습니다. 현재 기준으로 다시 준비해야 합니다.',
    baselineConfigurationMismatch => '준비 당시 전체 구성과 현재 구성이 일치하지 않습니다.',
  };
}

/// 원문/전체 구성을 담지 않는 반영 전용 상세다.
sealed class ProductGeometryChangeApplicationDetails {
  const ProductGeometryChangeApplicationDetails._();
}

/// 닫힘 거부의 두 수명 문맥이다. 토큰이 같을 필요는 없다.
final class ClosedEditSessionDetails
    extends ProductGeometryChangeApplicationDetails {
  /// 발급된 불변 토큰 두 개만 기록한다. 닫힘 사실은 고정 getter로 표현한다.
  const ClosedEditSessionDetails({
    required this.currentSessionId,
    required this.preparedSessionId,
  }) : super._();

  /// 닫힌 소유자의 토큰이다.
  final ProductDesignEditSessionId currentSessionId;

  /// 전달받은 준비의 토큰이다.
  final ProductDesignEditSessionId preparedSessionId;

  /// 이 코드가 나타내는 현재 수명 상태다.
  bool get isClosed => true;
  @override
  String toString() => 'isClosed=true';
}

/// 다른 세션의 기대/실제 토큰이다. 개정/구성을 무의미하게 비교하지 않는다.
final class EditSessionMismatchDetails
    extends ProductGeometryChangeApplicationDetails {
  /// 같은 토큰을 세션 불일치로 표시하는 오용은 ArgumentError.value로 거부한다.
  EditSessionMismatchDetails({
    required this.expectedSessionId,
    required this.actualSessionId,
  }) : super._() {
    if (identical(expectedSessionId, actualSessionId)) {
      throw ArgumentError.value(
        actualSessionId,
        'actualSessionId',
        '기대 세션과 다른 발급 토큰이 필요합니다.',
      );
    }
  }

  /// 현재 소유자가 기대하는 수명이다.
  final ProductDesignEditSessionId expectedSessionId;

  /// 준비 결과가 실제 소유한 수명이다.
  final ProductDesignEditSessionId actualSessionId;
  @override
  String toString() => '세션 토큰 불일치';
}

/// 같은 세션의 서로 다른 실행 개정이다.
final class EditRevisionMismatchDetails
    extends ProductGeometryChangeApplicationDetails {
  /// 두 개정은 0 이상이며 서로 달라야 한다. 미래 개정도 불일치로 거부한다.
  EditRevisionMismatchDetails({
    required this.sessionId,
    required this.expectedRevision,
    required this.actualRevision,
  }) : super._() {
    _checkRevision(expectedRevision, 'expectedRevision');
    _checkRevision(actualRevision, 'actualRevision');
    if (expectedRevision == actualRevision) {
      throw ArgumentError.value(
        actualRevision,
        'actualRevision',
        '기대 개정과 다른 값이 필요합니다.',
      );
    }
  }

  /// 공통 편집 수명이다.
  final ProductDesignEditSessionId sessionId;

  /// 현재 정본 개정이다.
  final int expectedRevision;

  /// 준비에 캡처한 개정이다.
  final int actualRevision;
  @override
  String toString() =>
      'expectedRevision=$expectedRevision, actualRevision=$actualRevision';
}

/// 구성 불일치의 비교 문맥이다. 원문·전체 구성·해시를 복제하지 않는다.
final class EditBaselineMismatchDetails
    extends ProductGeometryChangeApplicationDetails {
  /// 개정의 값 검증만 수행한다. 실제 구성 차이는 내부 전체 값 검사에서 판정한다.
  EditBaselineMismatchDetails({
    required this.sessionId,
    required this.currentRevision,
    required this.preparedRevision,
  }) : super._() {
    _checkRevision(currentRevision, 'currentRevision');
    _checkRevision(preparedRevision, 'preparedRevision');
  }

  /// 같은 편집 수명이다.
  final ProductDesignEditSessionId sessionId;

  /// 현재 정본의 실행 개정이다.
  final int currentRevision;

  /// 준비 당시 실행 개정이다. 같아도 내용 방어 검사는 필요하다.
  final int preparedRevision;

  /// 기대 값이 있는 실제 비교 위치다. 구성 자체는 진단에 포함하지 않는다.
  String get expectedPath => 'current.configuration';

  /// 준비에 실제 사용한 값의 위치다.
  String get actualPath => 'prepared.basis.configuration';
  @override
  String toString() =>
      'currentRevision=$currentRevision, preparedRevision=$preparedRevision, expectedPath=$expectedPath, actualPath=$actualPath';
}

/// 최종 반영 거부 한 건이다. 메시지 파싱 없이 코드·위치·구체 상세로 처리한다.
final class ProductGeometryChangeApplicationIssue {
  /// 코드/상세 조합과 코드별 실제 위치를 런타임 검사한다. 오용은 ArgumentError.value다.
  ProductGeometryChangeApplicationIssue({
    required this.code,
    required this.fieldPath,
    required this.details,
  }) {
    final valid = switch (code) {
      ProductGeometryChangeApplicationCode.closedEditSession =>
        details is ClosedEditSessionDetails,
      ProductGeometryChangeApplicationCode.differentEditSession =>
        details is EditSessionMismatchDetails,
      ProductGeometryChangeApplicationCode.staleEditRevision =>
        details is EditRevisionMismatchDetails,
      ProductGeometryChangeApplicationCode.baselineConfigurationMismatch =>
        details is EditBaselineMismatchDetails,
    };
    if (!valid) {
      throw ArgumentError.value(
        details.runtimeType,
        'details',
        '반영 코드에 맞는 필수 상세가 필요합니다.',
      );
    }
    final expected = switch (code) {
      ProductGeometryChangeApplicationCode.closedEditSession =>
        'current.isClosed',
      ProductGeometryChangeApplicationCode.differentEditSession =>
        'prepared.basis.sessionId',
      ProductGeometryChangeApplicationCode.staleEditRevision =>
        'prepared.basis.revision',
      ProductGeometryChangeApplicationCode.baselineConfigurationMismatch =>
        'prepared.basis.configuration',
    };
    if (fieldPath != expected) {
      throw ArgumentError.value(
        fieldPath,
        'fieldPath',
        '이 코드의 실제 위치는 $expected 입니다.',
      );
    }
  }

  /// 수명/개정/내용 중 거부한 기준이다.
  final ProductGeometryChangeApplicationCode code;

  /// 현재 관찰값 또는 준비 기준의 실제 위치다.
  final String fieldPath;

  /// 해당 코드가 요구하는 작은 상세다.
  final ProductGeometryChangeApplicationDetails details;
  @override
  String toString() =>
      'ProductGeometryChangeApplicationIssue(code=${code.name}, fieldPath=$fieldPath, 설명=${code.description}, $details)';
}

void _checkRevision(int value, String name) {
  if (value < 0) throw ArgumentError.value(value, name, '개정은 0 이상이어야 합니다.');
}
