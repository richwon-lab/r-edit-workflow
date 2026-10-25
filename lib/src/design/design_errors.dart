/// 도안 정의/참조 오류다. 기하 수치 오류·배치/제작 판정은 포함하지 않는다.
enum DesignErrorCode {
  /// 필수 JSON 필드가 없다. null 타입 오류와 구분한다.
  missingField,

  /// 필드 타입이 다르다. 기대/실제 타입을 상세에 제공한다.
  invalidType,

  /// 허용하지 않는 추가 JSON 필드다. 내용을 조용히 버리지 않는다.
  unexpectedField,

  /// cutoutId가 빈 문자열이다. 공백을 trim하지 않는다.
  emptyCutoutId,

  /// areaId가 빈 문자열이다. TextAreaInput과 같은 허용 규약이다.
  emptyAreaId,

  /// 한 DesignGeometry의 cutouts 안에서 같은 ID가 반복된다.
  duplicateCutoutId,

  /// 한 DesignGeometry의 textAreas 안에서 같은 ID가 반복된다.
  duplicateAreaId,

  /// 입력 목록에서 같은 areaId가 반복된다. 정의의 중복과 구분한다.
  duplicateInputAreaId,

  /// 입력 areaId가 현재 도안의 정의에 없다.
  unknownInputAreaId,

  /// 도안의 정의에 대응하는 입력이 하나도 없다. 빈 원문으로 보정하지 않는다.
  missingAreaInput;

  /// 개발자용 한국어 설명이다. 사용자 화면/다국어 계약이 아니다.
  String get description => switch (this) {
    missingField => '필수 도안 필드가 없습니다.',
    invalidType => '도안 필드의 값 타입이 기대 타입과 다릅니다.',
    unexpectedField => '허용하지 않는 도안 필드입니다.',
    emptyCutoutId => '관통 구멍 ID는 빈 문자열일 수 없습니다.',
    emptyAreaId => '텍스트 영역 ID는 빈 문자열일 수 없습니다.',
    duplicateCutoutId => '관통 구멍 ID가 도안 안에서 중복됩니다.',
    duplicateAreaId => '텍스트 영역 ID가 도안 안에서 중복됩니다.',
    duplicateInputAreaId => '입력 목록의 영역 ID가 중복됩니다.',
    unknownInputAreaId => '입력에 연결할 도안 영역이 없습니다.',
    missingAreaInput => '도안 영역에 대응하는 입력이 없습니다.',
  };
}

/// 정의/연결 오류에 필요한 도안 전용 상세다. 기하 진단을 대체하지 않는다.
sealed class DesignIssueDetails {
  const DesignIssueDetails();
}

/// 원래 식별 문자열이다. 표시 이름이나 좌표에서 추정한 값이 아니다.
final class DesignIdentifierDetails extends DesignIssueDetails {
  const DesignIdentifierDetails(this.identifier);

  /// trim/정규화하지 않은 cutoutId 또는 areaId다.
  final String identifier;
  @override
  String toString() => 'id="$identifier"';
}

/// 같은 소유 목록에서 중복된 ID의 두 위치다.
final class DesignDuplicateDetails extends DesignIssueDetails {
  const DesignDuplicateDetails({
    required this.identifier,
    required this.firstIndex,
    required this.duplicateIndex,
  });

  /// 중복된 원래 ID다.
  final String identifier;

  /// 같은 목록에서 처음 등장한 0 기반 인덱스다.
  final int firstIndex;

  /// 같은 목록에서 다시 등장한 0 기반 인덱스다.
  final int duplicateIndex;
  @override
  String toString() =>
      'id="$identifier", firstIndex=$firstIndex, duplicateIndex=$duplicateIndex';
}

/// JSON 경계의 기대/실제 타입이며 기하 길이 단위와 무관하다.
final class DesignTypeDetails extends DesignIssueDetails {
  const DesignTypeDetails({
    required this.expectedType,
    required this.actualType,
  });

  /// 요구하는 Dart/JSON 타입 이름이다.
  final String expectedType;

  /// 실제 runtimeType 이름이다. null은 Null이다.
  final String actualType;
  @override
  String toString() => 'expectedType=$expectedType, actualType=$actualType';
}

/// 정의 구성 또는 입력 연결의 실패다. 성공/배치 완료 상태를 저장하지 않는다.
final class DesignValidationIssue {
  const DesignValidationIssue({
    required this.code,
    required this.fieldPath,
    this.details,
  });

  /// 정의 오류와 입력 참조 오류를 구분하는 코드다.
  final DesignErrorCode code;

  /// 도안 또는 inputs 목록 기준의 필드 경로다. 목록 위치는 문자 오프셋이 아니다.
  final String fieldPath;

  /// 오류 원인에 필요한 식별자/중복 위치/타입 정보다.
  final DesignIssueDetails? details;

  /// 원래 상세 객체/코드를 유지하고 중첩 위치만 붙인다.
  DesignValidationIssue prefixed(String prefix) => DesignValidationIssue(
    code: code,
    fieldPath: fieldPath == r'$' ? prefix : '$prefix.$fieldPath',
    details: details,
  );
  @override
  String toString() =>
      '${code.name}, fieldPath=$fieldPath, 설명=${code.description}${details == null ? '' : ', $details'}';
}

/// 도안 값 구성의 검증 실패를 전달한다. 연결 API는 별도로 issue 목록을 반환한다.
final class DesignValidationException implements Exception {
  const DesignValidationException(this.issue);

  /// 원인 코드·필드 경로·명시적 상세다.
  final DesignValidationIssue issue;

  /// 기계 판별용 코드다.
  DesignErrorCode get code => issue.code;

  /// 실패한 필드/목록 위치다.
  String get fieldPath => issue.fieldPath;

  /// 기존 원인 정보를 보존하고 부모 위치를 연결한다.
  DesignValidationException prefixed(String prefix) =>
      DesignValidationException(issue.prefixed(prefix));
  @override
  String toString() => 'DesignValidationException($issue)';
}
