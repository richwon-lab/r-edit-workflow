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
  numericRepresentationFailure,
}

/// 오류 원인을 설명하는 명시적 수치/태그 정보다. 단위는 검사 대상 문맥을 따른다.
/// 임의 Map이나 소비자 엔진의 판정 정보를 운반하지 않는다.
final class GeometryDiagnostic {
  const GeometryDiagnostic({
    required this.operation,
    this.value,
    this.tag,
    this.expectedType,
    this.startX,
    this.startY,
    this.endX,
    this.endY,
    this.bulge,
  });
  final String operation;
  final double? value;
  final String? tag;
  final String? expectedType;
  final double? startX;
  final double? startY;
  final double? endX;
  final double? endY;
  final double? bulge;
}

/// [fieldPath]는 호출 모델의 필드 위치이며 문자 오프셋이 아니다.
/// [diagnostic]은 중첩 JSON 경로를 붙일 때도 그대로 보존한다.
final class GeometryValidationException implements Exception {
  const GeometryValidationException(this.code, this.fieldPath, this.diagnostic);
  final GeometryErrorCode code;
  final String fieldPath;
  final GeometryDiagnostic diagnostic;

  /// 하위 오류의 코드·원인을 보존하고 부모 JSON 위치만 연결한다.
  GeometryValidationException prefixed(String prefix) =>
      GeometryValidationException(
        code,
        fieldPath == r'$' ? prefix : '$prefix.$fieldPath',
        diagnostic,
      );

  @override
  String toString() =>
      'GeometryValidationException(${code.name}, $fieldPath, ${diagnostic.operation})';
}
