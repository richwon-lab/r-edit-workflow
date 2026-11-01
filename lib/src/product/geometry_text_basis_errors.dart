import 'package:meta/meta.dart';

/// 형상·문구 근거 생성/추출의 실패 사유다. 배치·저장 판정 코드가 아니다.
enum GeometryTextBasisErrorCode {
  /// 직접 생성한 근거의 제품 ID가 비었다. 명시 ID를 제공한다.
  emptyProductId,

  /// 유효 구성에 요청 제품이 없다. 최신 제품 목록에서 대상을 선택한다.
  unknownProduct,

  /// 영역 정의와 입력의 areaId가 다르다. 같은 ID끼리 결합한다.
  areaInputMismatch,

  /// 한 근거의 영역 ID가 중복됐다. 두 위치를 확인해 하나로 결정한다.
  duplicateAreaId,

  /// 한 근거의 관통 경계 ID가 중복됐다. 소유 목록을 수정한다.
  duplicateCutoutId;

  /// 개발자용 기본 설명이며 사용자 화면의 확정 문구가 아니다.
  String get description => switch (this) {
    emptyProductId => '제품 ID는 빈 문자열일 수 없습니다.',
    unknownProduct => '구성에 대상 제품이 없습니다.',
    areaInputMismatch => '영역 정의와 문구 입력의 ID가 다릅니다.',
    duplicateAreaId => '근거 안의 영역 ID가 중복됩니다.',
    duplicateCutoutId => '근거 안의 관통 경계 ID가 중복됩니다.',
  };
}

/// 원문·형상 전체를 복제하지 않는 근거 실패의 구체 상세다.
sealed class GeometryTextBasisErrorDetails {
  const GeometryTextBasisErrorDetails._();
}

/// 문제가 된 식별자다. 빈 ID 실패에서는 빈 문자열 자체를 보존한다.
final class BasisIdentifierDetails extends GeometryTextBasisErrorDetails {
  /// 표기를 정규화하지 않고 보관한다.
  const BasisIdentifierDetails(this.identifier) : super._();

  /// 제품/영역/관통 식별 문자열이며 원문이 아니다.
  final String identifier;
}

/// 잘못 결합한 정의/입력의 식별 정보를 구분한다.
final class BasisAreaInputDetails extends GeometryTextBasisErrorDetails {
  /// 비어 있지 않고 서로 다른 ID만 허용한다. 오용은 ArgumentError다.
  BasisAreaInputDetails({
    required this.definitionAreaId,
    required this.inputAreaId,
  }) : super._() {
    checkBasisIdentifierArgument(definitionAreaId, 'definitionAreaId');
    checkBasisIdentifierArgument(inputAreaId, 'inputAreaId');
    if (definitionAreaId == inputAreaId) {
      throw ArgumentError.value(
        inputAreaId,
        'inputAreaId',
        '불일치 상세의 두 ID는 달라야 합니다.',
      );
    }
  }

  /// 영역 정의가 소유한 ID다.
  final String definitionAreaId;

  /// 문구 입력이 참조하는 ID다.
  final String inputAreaId;
}

/// 소유 목록의 중복 ID와 두 실제 0 기반 위치다.
final class BasisDuplicateDetails extends GeometryTextBasisErrorDetails {
  /// ID는 비지 않아야 하며 0 ≤ firstIndex < duplicateIndex여야 한다.
  BasisDuplicateDetails({
    required this.identifier,
    required this.firstIndex,
    required this.duplicateIndex,
  }) : super._() {
    checkBasisIdentifierArgument(identifier, 'identifier');
    if (firstIndex < 0) {
      throw ArgumentError.value(firstIndex, 'firstIndex', '첫 위치는 0 이상이어야 합니다.');
    }
    if (duplicateIndex <= firstIndex) {
      throw ArgumentError.value(
        duplicateIndex,
        'duplicateIndex',
        '중복 위치는 첫 위치보다 커야 합니다.',
      );
    }
  }

  /// 영역/관통 목록 안에서 중복된 ID다.
  final String identifier;

  /// 최초 선언의 0 기반 인덱스다.
  final int firstIndex;

  /// 중복 선언의 0 기반 인덱스다.
  final int duplicateIndex;
}

/// 유효하지 않은 근거 생성 또는 예상 가능한 대상 없음의 전용 예외다.
/// named 생성자만 제공해 code/상세/경로 조합을 임의로 바꿀 수 없다.
final class GeometryTextBasisException implements Exception {
  GeometryTextBasisException._(this.code, this.fieldPath, this.details);

  /// 직접 생성 시 빈 제품 ID를 거부한다.
  GeometryTextBasisException.emptyProductId()
    : this._(
        GeometryTextBasisErrorCode.emptyProductId,
        'productId',
        const BasisIdentifierDetails(''),
      );

  /// 추출 대상이 없는 정상 업무 거부다. 빈 ID는 이 생성자의 오용이다.
  factory GeometryTextBasisException.unknownProduct(String productId) {
    checkBasisIdentifierArgument(productId, 'productId');
    return GeometryTextBasisException._(
      GeometryTextBasisErrorCode.unknownProduct,
      'productId',
      BasisIdentifierDetails(productId),
    );
  }

  /// 정의/입력의 서로 다른 ID를 보존한다. 동일 ID 상세는 런타임 거부한다.
  factory GeometryTextBasisException.areaInputMismatch({
    required String definitionAreaId,
    required String inputAreaId,
  }) => GeometryTextBasisException._(
    GeometryTextBasisErrorCode.areaInputMismatch,
    'input.areaId',
    BasisAreaInputDetails(
      definitionAreaId: definitionAreaId,
      inputAreaId: inputAreaId,
    ),
  );

  /// areas의 중복 위치를 가리킨다. 잘못된 위치/ID는 ArgumentError다.
  factory GeometryTextBasisException.duplicateArea({
    required String areaId,
    required int firstIndex,
    required int duplicateIndex,
  }) => GeometryTextBasisException._(
    GeometryTextBasisErrorCode.duplicateAreaId,
    'areas[$duplicateIndex].areaId',
    BasisDuplicateDetails(
      identifier: areaId,
      firstIndex: firstIndex,
      duplicateIndex: duplicateIndex,
    ),
  );

  /// cutouts의 중복 위치를 가리킨다. 잘못된 위치/ID는 ArgumentError다.
  factory GeometryTextBasisException.duplicateCutout({
    required String cutoutId,
    required int firstIndex,
    required int duplicateIndex,
  }) => GeometryTextBasisException._(
    GeometryTextBasisErrorCode.duplicateCutoutId,
    'cutouts[$duplicateIndex].cutoutId',
    BasisDuplicateDetails(
      identifier: cutoutId,
      firstIndex: firstIndex,
      duplicateIndex: duplicateIndex,
    ),
  );

  /// 기계적으로 처리할 근거 전용 코드다.
  final GeometryTextBasisErrorCode code;

  /// 생성 인자/근거의 실제 Dart 필드 경로다. 문자 오프셋이 아니다.
  final String fieldPath;

  /// 원인을 판단하는 작은 불변 상세다.
  final GeometryTextBasisErrorDetails details;

  @override
  String toString() =>
      'GeometryTextBasisException(code=${code.name}, fieldPath=$fieldPath, 설명=${code.description}, ${switch (details) {
        BasisIdentifierDetails(:final identifier) => 'identifier=$identifier',
        BasisAreaInputDetails(:final definitionAreaId, :final inputAreaId) => 'definitionAreaId=$definitionAreaId, inputAreaId=$inputAreaId',
        BasisDuplicateDetails(:final identifier, :final firstIndex, :final duplicateIndex) => 'identifier=$identifier, firstIndex=$firstIndex, duplicateIndex=$duplicateIndex',
      }})';
}

// 이 library 내부가 아닌 모델/추출에서도 사용하는 식별 인자 검사다. entry에서 export하지 않는다.
/// 근거 API의 비어 있으면 안 되는 인자를 검사한다. trim하지 않는다.
@internal
void checkBasisIdentifierArgument(String value, String name) {
  if (value.isEmpty) {
    throw ArgumentError.value(value, name, '식별 인자는 빈 문자열일 수 없습니다.');
  }
}
