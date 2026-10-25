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
  const ProductDesignIssueDetails();
}

/// 원래 식별 문자열이다. 위치나 이름으로 추정하지 않는다.
final class ProductDesignIdentifierDetails extends ProductDesignIssueDetails {
  const ProductDesignIdentifierDetails(this.identifier);
  final String identifier;
  @override
  String toString() => 'id="$identifier"';
}

/// 같은 소유 목록의 ID 중복 두 위치다.
final class ProductDesignDuplicateDetails extends ProductDesignIssueDetails {
  const ProductDesignDuplicateDetails({
    required this.identifier,
    required this.firstIndex,
    required this.duplicateIndex,
  });
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
  ProductDesignReferenceDetails({
    required this.productId,
    required this.appliedGeometryId,
    List<int> matchingIndices = const [],
  }) : matchingIndices = List.unmodifiable(matchingIndices);
  final String productId;
  final String appliedGeometryId;

  /// 적용 목록에서 해당 ID가 선언된 0 기반 위치. 없는 참조면 빈 목록이다.
  final List<int> matchingIndices;
  @override
  String toString() =>
      'productId=$productId, appliedGeometryId=$appliedGeometryId, matchingIndices=$matchingIndices';
}

/// 관련 제품과 기존 영역 issue를 연결한다. 원래 issue를 재작성하지 않는다.
final class ProductDesignAreaDetails extends ProductDesignIssueDetails {
  const ProductDesignAreaDetails({
    required this.productId,
    required this.appliedGeometryId,
    required this.cause,
  });
  final String productId;
  final String appliedGeometryId;

  /// 원래 DesignErrorCode·하위 경로·상세가 보존된다.
  final DesignValidationIssue cause;
  @override
  String toString() =>
      'productId=$productId, appliedGeometryId=$appliedGeometryId, cause=($cause)';
}

/// JSON 경계의 기대·실제 타입이다. 기하 길이 단위와 무관하다.
final class ProductDesignTypeDetails extends ProductDesignIssueDetails {
  const ProductDesignTypeDetails({
    required this.expectedType,
    required this.actualType,
  });
  final String expectedType;
  final String actualType;
  @override
  String toString() => 'expectedType=$expectedType, actualType=$actualType';
}

/// 제품 값 또는 참조 구성의 한 오류다. 순서로 종류를 판별하지 않는다.
final class ProductDesignIssue {
  const ProductDesignIssue({
    required this.code,
    required this.fieldPath,
    this.details,
  });
  final ProductDesignErrorCode code;

  /// 구성 기준 JSON 필드/0 기반 목록 위치다. 문자 오프셋이 아니다.
  final String fieldPath;
  final ProductDesignIssueDetails? details;
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
  ProductDesignValidationException(List<ProductDesignIssue> issues)
    : issues = List.unmodifiable(issues);

  /// 수정 불가 진단 목록이며 순서는 계약이 아니다.
  final List<ProductDesignIssue> issues;
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
  const ProductDesignNestedException({
    required this.fieldPath,
    required this.cause,
  });
  final String fieldPath;

  /// 원래 Geometry/Design/TextInput 예외 객체다. 타입과 진단을 보존한다.
  final Exception cause;
  ProductDesignNestedException prefixed(String prefix) =>
      ProductDesignNestedException(
        fieldPath: '$prefix.$fieldPath',
        cause: cause,
      );
  @override
  String toString() =>
      'ProductDesignNestedException(fieldPath=$fieldPath, 설명=제품 구성의 중첩 값 복원에 실패했습니다., cause=$cause)';
}
