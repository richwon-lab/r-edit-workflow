/// 영역 입력의 JSON 구조와 값 조건을 구분하는 코드다.
///
/// 값 검증은 배치·제작·저장 가능 판정이 아니다. 빈 원문·빈 지정 줄·CR/LF의
/// 거부는 현재 입력 모델의 지원 제한이며 전체 제품 정책으로 확정한 것이 아니다.
enum TextInputErrorCode {
  /// 디코딩된 객체에 필수 키가 없다. 키가 있고 null인 경우는 invalidType이다.
  missingField,

  /// JSON 객체·문자열·지정 줄 목록/항목의 타입이 다르거나 null이다.
  /// 문자열 mode의 값 자체가 미지원인 unknownLineBreakMode와 구분한다.
  invalidType,

  /// mode가 문자열이지만 automatic/specified 어느 값도 아니다.
  /// 기본값으로 보정하지 않으며, 방식 누락/타입 오류는 각각 별도 코드다.
  unknownLineBreakMode,

  /// 객체에 허용되지 않은 키가 있다. automatic 방식의 lines도 해당한다.
  unexpectedField,

  /// areaId가 길이 0인 문자열이다. 공백만 있는 ID는 trim하지 않아 해당하지 않는다.
  emptyAreaId,

  /// sourceText가 길이 0이다. 공백만 있는 원문은 해당하지 않는다.
  emptySourceText,

  /// specified 방식의 줄 목록이 비었다. 목록 타입 오류·빈 줄 항목과 구분한다.
  emptySpecifiedLines,

  /// 지정 줄 중 길이 0인 항목이 있다. fieldPath의 0 기반 위치로 식별한다.
  emptySpecifiedLine,

  /// 원문에 CR 또는 LF 코드 단위가 있다. 제거하거나 줄 목록으로 해석하지 않는다.
  sourceContainsCrLf,

  /// 지정 줄 항목에 CR 또는 LF가 있다. 빈 항목 거부와 구분한다.
  specifiedLineContainsCrLf,

  /// 지정 줄을 순서대로 연결한 문자열이 원문과 정확히 같지 않다.
  /// 공백·기호·대소문자·Unicode 표현 차이도 보정하지 않는다.
  specifiedLinesMismatchSourceText;

  /// 개발자용 기본 원인 설명이다. 사용자 화면의 확정 문구·다국어 계약이 아니다.
  String get description => switch (this) {
    missingField => '필수 문구 입력 필드가 없습니다.',
    invalidType => '문구 입력의 JSON 값 타입이 기대 타입과 다릅니다.',
    unknownLineBreakMode => '줄바꿈 방식은 automatic 또는 specified여야 합니다.',
    unexpectedField => '이 문구 입력 방식에서 허용하지 않는 필드입니다.',
    emptyAreaId => '영역 ID는 빈 문자열일 수 없습니다.',
    emptySourceText => '현재 입력 모델은 빈 원문을 지원하지 않습니다.',
    emptySpecifiedLines => '직접 지정 줄은 하나 이상 필요합니다.',
    emptySpecifiedLine => '현재 입력 모델은 빈 지정 줄을 지원하지 않습니다.',
    sourceContainsCrLf => '현재 입력 모델은 원문 안의 CR/LF를 지원하지 않습니다.',
    specifiedLineContainsCrLf => '현재 입력 모델은 지정 줄 안의 CR/LF를 지원하지 않습니다.',
    specifiedLinesMismatchSourceText => '지정 줄을 순서대로 연결한 내용이 원문과 다릅니다.',
  };
}

/// 문구 입력의 구조·값 검증 실패다. 첫 오류를 전달하며 복수 오류 순서는 계약이 아니다.
///
/// [fieldPath]는 입력 조각 기준이다. TextAreaInput 객체 자체의 타입 오류는 $이며,
/// LineBreakInput 단독 복원도 lineBreak 접두 경로를 사용한다. 줄 항목은 lineBreak.lines[0]처럼
/// 0 기반 목록 인덱스를 쓴다. 문자 오프셋이나 도안 좌표가 아니다.
/// 상위 제품 복원은 이 예외를 원인 객체로 보존하고 상위 경로를 별도로 제공한다.
/// 원문을 예외 출력에 덤프하지 않으며 사용자 화면용 메시지 모델도 아니다.
final class TextInputValidationException implements Exception {
  /// 호출 경계의 [code]와 상대 [fieldPath]를 보존한다. 입력값을 재검증하지 않는다.
  const TextInputValidationException(this.code, this.fieldPath);

  /// 누락·타입·지원 제한·원문/지정 줄 불일치를 구분하는 기계 판별 값이다.
  final TextInputErrorCode code;

  /// 실패한 입력 조각의 필드 또는 지정 줄 위치다. 기준은 타입 설명을 따른다.
  final String fieldPath;

  @override
  String toString() =>
      'TextInputValidationException(code=${code.name}, fieldPath=$fieldPath, 설명=${code.description})';
}
