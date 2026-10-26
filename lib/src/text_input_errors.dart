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

/// 문구 오류별 필수 상세의 합이다. 원문/전체 입력을 보관하지 않는다.
sealed class TextInputDetails {
  /// 하위 진단의 기반 생성자다.
  const TextInputDetails();
}

/// invalidType의 기대/실제 타입 이름이다.
final class TextInputTypeDetails extends TextInputDetails {
  /// 실제 값 대신 타입 이름만 보존한다.
  const TextInputTypeDetails({
    required this.expectedType,
    required this.actualType,
  });

  /// JSON/Dart 경계에서 요구한 타입 이름이다.
  final String expectedType;

  /// null은 Null, 그 밖에는 runtimeType 이름이다.
  final String actualType;
  @override
  String toString() => 'expectedType=$expectedType, actualType=$actualType';
}

/// 해석할 수 없는 줄바꿈 방식과 지원 범위다.
final class TextInputModeDetails extends TextInputDetails {
  /// 보정하지 않은 원래 mode 문자열을 기록한다.
  const TextInputModeDetails(this.actualValue);

  /// 실제 mode 값이다. 원문 문구와 구분한다.
  final String actualValue;

  /// 현재 해석 가능한 방식이며 수정 불가다.
  List<String> get supportedValues => const ['automatic', 'specified'];
  @override
  String toString() => 'mode=$actualValue, supported=$supportedValues';
}

/// CR/LF가 발견된 위치다. 원문 자체는 보관하지 않는다.
final class TextInputCharacterDetails extends TextInputDetails {
  /// 해당 문자열의 UTF-16 코드 단위 위치와 CR(13)/LF(10)를 기록한다.
  const TextInputCharacterDetails({
    required this.codeUnitIndex,
    required this.codeUnit,
  });

  /// 필드 문자열 안의 0 기반 UTF-16 위치다. 글자/문자소 오프셋 API는 아니다.
  final int codeUnitIndex;

  /// 발견한 CR 또는 LF의 코드 단위다.
  final int codeUnit;
  @override
  String toString() => 'codeUnitIndex=$codeUnitIndex, codeUnit=$codeUnit';
}

/// 원문과 지정 줄 연결이 다를 때의 최소 수량 정보다.
final class TextInputMismatchDetails extends TextInputDetails {
  /// 원문/연결의 UTF-16 길이와 지정 줄 수만 보존한다.
  const TextInputMismatchDetails({
    required this.sourceLength,
    required this.specifiedLength,
    required this.lineCount,
  });

  /// 원문의 UTF-16 코드 단위 길이다.
  final int sourceLength;

  /// 지정 줄을 순서대로 연결한 코드 단위 길이다.
  final int specifiedLength;

  /// 지정 줄 목록의 항목 수다.
  final int lineCount;
  @override
  String toString() =>
      'sourceLength=$sourceLength, specifiedLength=$specifiedLength, lineCount=$lineCount';
}

/// 입력 거부의 코드·상대 경로·형식 있는 상세다. UI 메시지/로그가 아니다.
///
/// TextAreaInput의 루트 타입 오류는 $, LineBreakInput은 lineBreak 접두를 쓴다.
/// 항목 위치는 0 기반이며 원문 전체는 보관하지 않는다.
/// 잘못된 코드/상세 조합은 호출 코드 결함인 ArgumentError로 거부한다.
final class TextInputValidationException implements Exception {
  /// 코드별 상세를 런타임 검사한다. assert 비활성 환경도 같다.
  TextInputValidationException(
    this.code,
    this.fieldPath, {
    this.details,
    this.cause,
    this.causeStackTrace,
    this.contextStackTrace,
  }) {
    final details = this.details;
    final valid = switch (code) {
      TextInputErrorCode.invalidType =>
        details is TextInputTypeDetails &&
            details.expectedType.isNotEmpty &&
            details.actualType.isNotEmpty,
      TextInputErrorCode.unknownLineBreakMode =>
        details is TextInputModeDetails &&
            !details.supportedValues.contains(details.actualValue),
      TextInputErrorCode.sourceContainsCrLf ||
      TextInputErrorCode.specifiedLineContainsCrLf =>
        details is TextInputCharacterDetails &&
            details.codeUnitIndex >= 0 &&
            (details.codeUnit == 10 || details.codeUnit == 13),
      TextInputErrorCode.specifiedLinesMismatchSourceText =>
        details is TextInputMismatchDetails &&
            details.sourceLength >= 0 &&
            details.specifiedLength >= 0 &&
            details.lineCount > 0,
      _ => details == null,
    };
    if (!valid || fieldPath.isEmpty) {
      throw ArgumentError('문구 오류 코드/상세/경로 조합이 잘못되었습니다.');
    }
  }

  /// 소비자가 기계적으로 판별하는 입력 거부 종류다.
  final TextInputErrorCode code;

  /// 입력 조각 기준 상대 필드/항목 위치다.
  final String fieldPath;

  /// 코드가 요구하는 작은 상세이며 원문/JSON은 담지 않는다.
  final TextInputDetails? details;

  /// 문맥 추가 전 원래 예외다.
  final Exception? cause;

  /// 원래 실패 위치의 스택이다.
  final StackTrace? causeStackTrace;

  /// 문맥을 추가한 코드 경계의 스택이다.
  final StackTrace? contextStackTrace;
  @override
  String toString() =>
      'TextInputValidationException(code=${code.name}, fieldPath=$fieldPath, 설명=${code.description}, details=$details)';
}
