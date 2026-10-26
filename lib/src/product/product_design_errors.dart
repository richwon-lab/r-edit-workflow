import 'package:r_edit_workflow/src/design/design_errors.dart';

/// 제품 값·JSON·참조의 오류다. 기하·문구 판정 코드를 대신하지 않는다.
enum ProductDesignErrorCode {
  /// 필수 JSON 필드가 없다. 명시적 null의 타입 오류와 구분한다.
  missingField,

  /// 기대 타입과 실제 타입이 다르다.
  invalidType,

  /// 지원하지 않는 추가 필드다. 조용히 버리지 않는다.
  unexpectedField,

  /// productId가 빈 문자열이다. 공백은 정규화하지 않는다.
  emptyProductId,

  /// appliedGeometryId가 빈 문자열이다. 참조 없음과 별개다.
  emptyAppliedGeometryId,

  /// 출처를 지정했지만 sourceDesignId가 빈 문자열이다.
  emptySourceDesignId,

  /// 지정된 sourceRevision이 빈 문자열이다. null/생략과 구분한다.
  emptySourceRevision,

  /// 적용 목록에 같은 ID가 반복된다. 내용이 같아도 오류다.
  duplicateAppliedGeometryId,

  /// 제품 목록에 같은 productId가 반복된다.
  duplicateProductId,

  /// 제품이 참조하는 적용 ID가 목록에 없다.
  unknownAppliedGeometryId,

  /// 같은 적용 ID가 여러 개여서 제품의 참조를 유일하게 해석할 수 없다.
  ambiguousAppliedGeometryId,

  /// 제품 영역 입력의 하위 issue다. 원래 코드·경로·상세를 보존한다.
  textAreaInputMismatch;

  /// 개발자용 한국어 설명이며 사용자 화면 문구 계약은 아니다.
  String get description => switch (this) {
    missingField => '필수 제품 구성 필드가 없습니다.',
    invalidType => '제품 구성 필드의 타입이 기대 타입과 다릅니다.',
    unexpectedField => '허용하지 않는 제품 구성 필드입니다.',
    emptyProductId => '제품 ID는 빈 문자열일 수 없습니다.',
    emptyAppliedGeometryId => '적용 형상 ID는 빈 문자열일 수 없습니다.',
    emptySourceDesignId => '공용 원본 ID는 빈 문자열일 수 없습니다.',
    emptySourceRevision => '지정한 원본 버전은 빈 문자열일 수 없습니다.',
    duplicateAppliedGeometryId => '적용 형상 ID가 소유 목록에서 중복됩니다.',
    duplicateProductId => '제품 ID가 소유 목록에서 중복됩니다.',
    unknownAppliedGeometryId => '제품이 참조하는 적용 형상이 없습니다.',
    ambiguousAppliedGeometryId => '제품의 적용 형상 참조가 중복되어 모호합니다.',
    textAreaInputMismatch => '제품 입력이 적용 형상의 영역 정의와 대응하지 않습니다.',
  };
}

/// 제품 구성 오류별로 필요한 작은 상세 타입의 합이다.
sealed class ProductDesignIssueDetails {
  /// 제품 진단 상세의 허용 유형을 제한한다. 업무 값이나 성공 상태를 생성하지 않는다.
  const ProductDesignIssueDetails();
}

/// 원래 식별 문자열이다. 위치나 이름으로 추정하지 않는다.
final class ProductDesignIdentifierDetails extends ProductDesignIssueDetails {
  /// 실패 경계의 원래 ID를 기록한다. 표시 이름이나 위치에서 새 ID를 만들지 않는다.
  const ProductDesignIdentifierDetails(this.identifier);

  /// 오류가 가리키는 원래 제품·적용·출처 ID 또는 버전 문자열이다. 보정하지 않는다.
  final String identifier;
  @override
  String toString() => 'id="$identifier"';
}

/// 같은 소유 목록의 ID 중복 두 위치다.
final class ProductDesignDuplicateDetails extends ProductDesignIssueDetails {
  /// 동일 소유 목록의 첫/중복 위치와 원래 ID를 기록한다. 두 종류 ID 간 충돌을 뜻하지 않는다.
  const ProductDesignDuplicateDetails({
    required this.identifier,
    required this.firstIndex,
    required this.duplicateIndex,
  });

  /// 소유 products 또는 appliedGeometries 목록에서 중복된 원래 ID다. 출처 버전 중복 검사가 아니다.
  final String identifier;

  /// 같은 목록의 0 기반 첫 위치다.
  final int firstIndex;

  /// 같은 목록의 0 기반 중복 위치다.
  final int duplicateIndex;
  @override
  String toString() =>
      'id="$identifier", firstIndex=$firstIndex, duplicateIndex=$duplicateIndex';
}

/// 없는 참조 또는 모호한 참조의 제품·적용 ID다.
final class ProductDesignReferenceDetails extends ProductDesignIssueDetails {
  /// 제품이 시도한 참조와 일치한 적용 목록 위치를 방어 복사한다. 없는 참조는 빈 위치 목록이다.
  ProductDesignReferenceDetails({
    required this.productId,
    required this.appliedGeometryId,
    List<int> matchingIndices = const [],
  }) : matchingIndices = List.unmodifiable(matchingIndices);

  /// 이 참조/영역 진단에 연결된 제품의 ID다. products 위치와 별개이며 표시 문구가 아니다.
  final String productId;

  /// 해당 제품이 사용하려 한 적용 형상 ID다. 공용 sourceDesignId와 구분한다.
  final String appliedGeometryId;

  /// 적용 목록에서 해당 ID가 선언된 0 기반 위치. 없는 참조면 빈 목록이다.
  final List<int> matchingIndices;
  @override
  String toString() =>
      'productId=$productId, appliedGeometryId=$appliedGeometryId, matchingIndices=$matchingIndices';
}

/// 관련 제품과 기존 영역 issue를 연결한다. 원래 issue를 재작성하지 않는다.
final class ProductDesignAreaDetails extends ProductDesignIssueDetails {
  /// 관련 두 ID와 하위 영역 issue를 연결한다. cause 객체의 코드·원래 경로·상세는 재작성하지 않는다.
  const ProductDesignAreaDetails({
    required this.productId,
    required this.appliedGeometryId,
    required this.cause,
  });

  /// 이 참조/영역 진단에 연결된 제품의 ID다. products 위치와 별개이며 표시 문구가 아니다.
  final String productId;

  /// 해당 제품이 사용하려 한 적용 형상 ID다. 공용 sourceDesignId와 구분한다.
  final String appliedGeometryId;

  /// 원래 DesignErrorCode·하위 경로·상세가 보존된다.
  final DesignValidationIssue cause;
  @override
  String toString() =>
      'productId=$productId, appliedGeometryId=$appliedGeometryId, cause=($cause)';
}

/// JSON 경계의 기대·실제 타입이다. 기하 길이 단위와 무관하다.
final class ProductDesignTypeDetails extends ProductDesignIssueDetails {
  /// 제품 JSON 경계의 타입 차이를 기록한다. 길이 단위나 문자 오프셋을 나타내지 않는다.
  const ProductDesignTypeDetails({
    required this.expectedType,
    required this.actualType,
  });

  /// 해당 필드가 요구하는 JSON/Dart 타입 이름이다. 선택 필드의 null 허용 여부는 복원 API 규약을 따른다.
  final String expectedType;

  /// 실제 값의 runtimeType 이름이다. null의 타입은 Null이며 원문 내용은 담지 않는다.
  final String actualType;
  @override
  String toString() => 'expectedType=$expectedType, actualType=$actualType';
}

/// 제품 값 또는 참조 구성의 한 오류다. 순서로 종류를 판별하지 않는다.
final class ProductDesignIssue {
  /// 독립 오류 하나의 코드·소유 경로·상세를 보존한다. 생성 자체가 참조 검사 실행은 아니다.
  const ProductDesignIssue({
    required this.code,
    required this.fieldPath,
    this.details,
  });

  /// 값 구조/ID/참조/하위 영역 대응 중 실패 종류를 기계적으로 구분한다.
  final ProductDesignErrorCode code;

  /// 구성 기준 JSON 필드/0 기반 목록 위치다. 문자 오프셋이 아니다.
  /// 중첩 복원/참조 검사 경계 기준 필드 경로다. 목록 위치는 0 기반이며 문자 오프셋이 아니다.
  final String fieldPath;

  /// 관련 ID·목록 위치·타입 또는 원래 영역 issue다. 추가 상세가 없는 오류는 null이다.
  final ProductDesignIssueDetails? details;

  /// 루트 $는 prefix로 바꾸고 그 밖의 상대 경로에 부모 위치를 붙인다. 코드와 details 객체는 유지한다.
  ProductDesignIssue prefixed(String prefix) => ProductDesignIssue(
    code: code,
    fieldPath: fieldPath == r'$' ? prefix : '$prefix.$fieldPath',
    details: details,
  );
  @override
  String toString() =>
      '${code.name}, fieldPath=$fieldPath, 설명=${code.description}${details == null ? '' : ', $details'}';
}

/// 값 실패는 한 issue, 구성 실패는 독립 issue 전체를 전달한다.
final class ProductDesignValidationException implements Exception {
  /// issue 목록을 방어 복사한다. 단독 값 오류와 구성의 독립 복수 오류를 같은 목록 형식으로 전달한다.
  ProductDesignValidationException(List<ProductDesignIssue> issues)
    : issues = List.unmodifiable(issues);

  /// 수정 불가 진단 목록이며 순서는 계약이 아니다.
  final List<ProductDesignIssue> issues;

  /// 각 issue의 부모 경로만 추가한다. 원래 코드·상세 객체와 순서를 보존하며 새 업무 검사는 하지 않는다.
  ProductDesignValidationException prefixed(String prefix) =>
      ProductDesignValidationException([
        for (final issue in issues) issue.prefixed(prefix),
      ]);
  @override
  String toString() =>
      'ProductDesignValidationException:\n${issues.join('\n')}';
}

/// 중첩 복원의 상위 위치와 원래 하위 예외를 함께 제공한다.
/// cause의 기하 diagnostic·문구 code/fieldPath를 문자열 분석 없이 확인할 수 있다.
final class ProductDesignNestedException implements Exception {
  /// 상위 복원 경로와 원래 하위 예외를 함께 보관한다. cause를 문자열이나 다른 오류 타입으로 변환하지 않는다.
  const ProductDesignNestedException({
    required this.fieldPath,
    required this.cause,
  });

  /// 중첩 복원/참조 검사 경계 기준 필드 경로다. 목록 위치는 0 기반이며 문자 오프셋이 아니다.
  final String fieldPath;

  /// 원래 Geometry/Design/TextInput 예외 객체다. 타입과 진단을 보존한다.
  final Exception cause;

  /// 상위 소유 위치를 연결하고 cause 객체를 그대로 유지한다. 원래 원인의 상대 fieldPath는 cause에서 조회한다.
  ProductDesignNestedException prefixed(String prefix) =>
      ProductDesignNestedException(
        fieldPath: '$prefix.$fieldPath',
        cause: cause,
      );
  @override
  String toString() =>
      'ProductDesignNestedException(fieldPath=$fieldPath, 설명=제품 구성의 중첩 값 복원에 실패했습니다., cause=$cause)';
}
