/// 기하 정의 오류다. 소비자의 계산/출력 미지원 판정은 이 목록과 별도다.
enum GeometryErrorCode {
  /// 필수 필드 없음. 값이 null인 타입 오류와 구분한다.
  missingField,

  /// JSON 값의 타입 불일치. 수학적 값의 잘못과 구분한다.
  invalidType,

  /// 허용하지 않은 필드. 모르는 kind 태그는 unsupportedTag다.
  unexpectedField,

  /// 알려지지 않은 단위/기하 종류. 다른 형상으로 보정하지 않는다.
  unsupportedTag,

  /// 좌표·반지름·bulge가 NaN/무한대다. 파생 연산 실패와 구분한다.
  nonFiniteNumber,

  /// 원 반지름이 0 이하인 수학적으로 잘못된 값이다.
  nonPositiveRadius,

  /// 원호 bulge가 0이다. 반원 초과나 음수 bulge는 오류가 아니다.
  zeroArcBulge,

  /// 경로 구간 목록이 비었다. 닫힘 실패와 구분한다.
  emptyPath,

  /// 경로가 해석한 구간 시작과 끝이 정확히 같다.
  degenerateSegment,

  /// 닫힌 경로의 마지막 끝점이 시작점과 다르다. 자동 연결하지 않는다.
  openBoundary,

  /// 유한 입력의 파생 값/환산이 double로 표현되지 않거나 0으로 소실된다.
  /// 환산 정밀도 소실로 서로 다른 구간 끝점이 같아진 경우도 포함한다.
  numericRepresentationFailure,
}

/// 오류 코드의 개발자용 한국어 기본 설명이다. 사용자 UI 번역 계약이 아니다.
extension GeometryErrorExplanation on GeometryErrorCode {
  /// 입력 오류와 수치 표현 실패를 구분하는 개발자 설명이다. 진단 값·연산은 예외의 diagnostic에서 조회한다.
  String get description => switch (this) {
    GeometryErrorCode.missingField => '필수 필드가 없습니다.',
    GeometryErrorCode.invalidType => '필드의 값 타입이 기대 타입과 다릅니다.',
    GeometryErrorCode.unexpectedField => '허용하지 않는 필드가 있습니다.',
    GeometryErrorCode.unsupportedTag => '지원하지 않는 기하 종류 또는 단위 태그입니다.',
    GeometryErrorCode.nonFiniteNumber => '입력 수치가 유한한 값이 아닙니다.',
    GeometryErrorCode.nonPositiveRadius => '원의 반지름은 0보다 커야 합니다.',
    GeometryErrorCode.zeroArcBulge => '원호의 bulge는 0일 수 없습니다.',
    GeometryErrorCode.emptyPath => '경로에는 구간이 하나 이상 필요합니다.',
    GeometryErrorCode.degenerateSegment => '구간의 시작점과 끝점이 같습니다.',
    GeometryErrorCode.openBoundary => '마지막 끝점이 시작점으로 돌아오지 않아 경계가 닫히지 않았습니다.',
    GeometryErrorCode.numericRepresentationFailure =>
      '파생 계산 또는 단위 환산 결과를 double로 표현할 수 없습니다.',
  };
}

/// 현재 기하 오류에 필요한 작은 상세 유형의 합이다. 범용 오류 자료가 아니다.
sealed class GeometryDiagnosticDetails {
  /// 기하 오류별로 필요한 상세 유형을 제한한다. 길이 단위는 상세를 만든 도안 문맥에서 해석한다.
  const GeometryDiagnosticDetails();
}

/// JSON 타입 불일치의 기대/실제 타입이다. 값이나 길이 단위가 아니다.
final class GeometryTypeDetails extends GeometryDiagnosticDetails {
  /// JSON 경계가 요구한 타입과 실제 runtimeType을 기록한다. 입력값은 재검증하거나 덤프하지 않는다.
  const GeometryTypeDetails({
    required this.expectedType,
    required this.actualType,
  });

  /// 변환 경계에서 요구하는 타입 이름이다.
  final String expectedType;

  /// null은 Null, 그 밖에는 실제 Dart runtimeType 이름이다.
  final String actualType;
  @override
  String toString() => 'expectedType=$expectedType, actualType=$actualType';
}

/// 단일 수치의 원인 값이다. 길이는 해당 도안 문맥 단위, bulge는 무차원이다.
final class GeometryNumberDetails extends GeometryDiagnosticDetails {
  /// 실패 입력/환산 전 수치를 기록한다. 길이 또는 무차원의 구분은 타입과 operation 설명을 따른다.
  const GeometryNumberDetails(this.value);

  /// 실패한 입력 또는 환산 전 수치다. 연산 의미는 diagnostic.operation을 따른다.
  final double value;
  @override
  String toString() => 'value=$value';
}

/// 해석하지 못한 기하 종류/단위 태그다.
final class GeometryTagDetails extends GeometryDiagnosticDetails {
  /// 해석하지 못한 단위/종류 문자열을 보정 없이 기록한다. 지원 태그를 새로 정의하지 않는다.
  GeometryTagDetails(this.tag, {required List<String> supportedValues})
    : supportedValues = List.unmodifiable(supportedValues);

  /// 보정하지 않은 원래 문자열이며 수치 단위가 아니다.
  final String tag;

  /// 현재 경계에서 지원하는 태그 목록이다.
  final List<String> supportedValues;
  @override
  String toString() => 'tag=$tag, supported=$supportedValues';
}

/// 도안 문맥 단위의 구간 양끝점이다. 원 중심을 이 필드로 표현하지 않는다.
final class GeometrySegmentDetails extends GeometryDiagnosticDetails {
  /// 해석된 양끝 좌표와 선택적 원호 bulge를 기록한다. 동일 끝점/닫힘 조건 자체를 검사하지 않는다.
  const GeometrySegmentDetails({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    this.bulge,
  });

  /// 검사한 구간 시작점의 문맥 단위 X 좌표다.
  final double startX;

  /// 검사한 구간 시작점의 문맥 단위 Y 좌표다.
  final double startY;

  /// 검사한 구간 끝점의 문맥 단위 X 좌표다.
  final double endX;

  /// 검사한 구간 끝점의 문맥 단위 Y 좌표다.
  final double endY;

  /// 원호인 경우의 무차원 bulge다. 선분/닫힘 검사에서는 없을 수 있다.
  final double? bulge;
  @override
  String toString() =>
      'start=($startX, $startY), end=($endX, $endY)${bulge == null ? '' : ', bulge=$bulge'}';
}

/// 원호 파생 계산 실패의 입력 구간과 실패 수치다.
final class GeometryArcCalculationDetails extends GeometryDiagnosticDetails {
  /// 실패 원호 입력과 파생 수치를 연결한다. value의 의미와 단위는 실제 operation을 따른다.
  const GeometryArcCalculationDetails({
    required this.segment,
    required this.value,
  });

  /// 원래 끝점(문맥 길이)과 bulge(무차원)다.
  final GeometrySegmentDetails segment;

  /// operation이 가리키는 반현/반지름/중심 등의 파생 수치(문맥 길이)다.
  final double value;
  @override
  String toString() => '$segment, value=$value';
}

/// 설계 좌표계에서 원의 네 극점 방향이다. 회전/가공 방향이 아니다.
enum GeometryExtremumDirection {
  /// 중심에서 오른쪽 극점이다. 실패 value는 centerX+radius다.
  positiveX,

  /// 중심에서 왼쪽 극점이다. 실패 value는 centerX-radius다.
  negativeX,

  /// 중심에서 위쪽 극점이다. 실패 value는 centerY+radius다.
  positiveY,

  /// 중심에서 아래쪽 극점이다. 실패 value는 centerY-radius다.
  negativeY,
}

/// 원 중심·반지름과 특정 극점 계산 결과다. 길이는 검사 대상 도안 문맥을 따른다.
final class GeometryCircleExtremumDetails extends GeometryDiagnosticDetails {
  /// 원의 중심·반지름·실패 극점 방향과 그 축의 계산값을 보존한다. 구간 시작점으로 오해하지 않는다.
  const GeometryCircleExtremumDetails({
    required this.centerX,
    required this.centerY,
    required this.radius,
    required this.direction,
    required this.value,
  });

  /// 파생 또는 정본 원 중심의 문맥 단위 X 좌표다.
  final double centerX;

  /// 파생 또는 정본 원 중심의 문맥 단위 Y 좌표다.
  final double centerY;

  /// 파생 또는 정본 반지름(문맥 길이)이다.
  final double radius;

  /// 실패한 극점의 축/부호다. 양의 X는 오른쪽이다.
  final GeometryExtremumDirection direction;

  /// 해당 축에서 계산한 극점 좌표(문맥 길이)다.
  final double value;
  @override
  String toString() =>
      'center=($centerX, $centerY), radius=$radius, direction=${direction.name}, value=$value';
}

/// 원호 위 극점의 오류다. 원호 입력과 그 기반 원/실패 방향을 함께 보존한다.
final class GeometryArcExtremumDetails extends GeometryDiagnosticDetails {
  /// 실제 원호 구간과 그 위에 포함되는 실패 극점의 상세를 연결한다. 원 전체의 미포함 극점 오류가 아니다.
  const GeometryArcExtremumDetails({
    required this.segment,
    required this.extremum,
  });

  /// 해당 원호의 원래 양끝점/무차원 bulge다.
  final GeometrySegmentDetails segment;

  /// 실제 원호에 포함되는 극점의 중심·반지름·방향·계산 결과다.
  final GeometryCircleExtremumDetails extremum;
  @override
  String toString() => '$segment, $extremum';
}

/// 오류를 만든 연산과 해당 오류에만 필요한 구조화 상세다.
final class GeometryDiagnostic {
  /// 실패 연산과 그 오류에 필요한 상세만 기록한다. 필드 경로는 이 진단이 아닌 상위 예외가 소유한다.
  const GeometryDiagnostic({required this.operation, this.details});

  /// 실패 연산의 개발자용 이름이다. convertLength 등은 원본/대상 단위도 표시한다.
  final String operation;

  /// 타입/수치/구간/극점 중 해당 원인이다. 추가 수치가 없는 구조 오류는 null이다.
  /// 길이값은 해당 도안 문맥 단위이며 bulge만 무차원이다.
  final GeometryDiagnosticDetails? details;
  @override
  String toString() =>
      'operation=$operation${details == null ? '' : ', $details'}';
}

/// [fieldPath]는 모델/JSON 필드 위치다. [diagnostic]은 중첩 시 원형을 보존한다.
final class GeometryValidationException implements Exception {
  /// 기하 오류 코드·모델 상대 경로·진단 객체를 보존한다. 생성 자체가 형상 검사를 다시 수행하지 않는다.
  GeometryValidationException(
    this.code,
    this.fieldPath,
    this.diagnostic, {
    this.cause,
    this.causeStackTrace,
    this.contextStackTrace,
  }) {
    final details = diagnostic.details;
    final valid = switch (code) {
      GeometryErrorCode.invalidType =>
        details is GeometryTypeDetails &&
            details.expectedType.isNotEmpty &&
            details.actualType.isNotEmpty,
      GeometryErrorCode.unsupportedTag =>
        details is GeometryTagDetails &&
            details.supportedValues.isNotEmpty &&
            !details.supportedValues.contains(details.tag),
      GeometryErrorCode.nonFiniteNumber ||
      GeometryErrorCode.nonPositiveRadius ||
      GeometryErrorCode.zeroArcBulge => details is GeometryNumberDetails,
      GeometryErrorCode.degenerateSegment ||
      GeometryErrorCode.openBoundary => details is GeometrySegmentDetails,
      GeometryErrorCode.numericRepresentationFailure =>
        details is GeometryNumberDetails ||
            details is GeometryArcCalculationDetails ||
            details is GeometryArcExtremumDetails ||
            details is GeometryCircleExtremumDetails ||
            details is GeometrySegmentDetails,
      _ => details == null,
    };
    if (!valid || fieldPath.isEmpty || diagnostic.operation.isEmpty) {
      throw ArgumentError('기하 오류 코드/진단/경로 조합이 잘못되었습니다.');
    }
  }

  /// 원래 실패 객체다. 접두 추가 시 최초 원인을 유지한다.
  final Exception? cause;

  /// 최초 실패 위치의 스택이다.
  final StackTrace? causeStackTrace;

  /// 마지막 문맥 추가 경계의 스택이다.
  final StackTrace? contextStackTrace;

  /// 기계적으로 판별하는 실패 코드다.
  final GeometryErrorCode code;

  /// 호출한 값 모델 기준 필드 위치다. JSON 중첩에서는 부모 위치가 붙는다.
  final String fieldPath;

  /// 실제 원인 연산과 명시적 상세다. 사용자 화면용 메시지 모델이 아니다.
  final GeometryDiagnostic diagnostic;

  /// 코드와 상세 객체를 그대로 두고 부모 필드 위치만 연결한다.
  GeometryValidationException prefixed(
    String prefix, {
    StackTrace? stackTrace,
  }) => GeometryValidationException(
    code,
    fieldPath == r'$' ? prefix : '$prefix.$fieldPath',
    diagnostic,
    cause: cause ?? this,
    causeStackTrace: causeStackTrace ?? stackTrace,
    contextStackTrace: StackTrace.current,
  );
  @override
  String toString() =>
      'GeometryValidationException(code=${code.name}, fieldPath=$fieldPath, 설명=${code.description}, $diagnostic)';
}
