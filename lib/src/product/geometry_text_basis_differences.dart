/// 형상·문구 부분의 차이 종류다. 저장/배치 가능 여부를 뜻하지 않는다.
enum GeometryTextBasisDifferenceCode {
  /// 다른 productId를 비교했다. 같은 제품으로 취급하지 않고 이 진단만 반환한다.
  productMismatch,

  /// 양쪽에 존재하는 필드의 실제 값이 다르다.
  valueChanged,

  /// 경계/구간/입력 방식의 종류가 달라 요소 전체를 가리킨다.
  kindChanged,

  /// 다음 근거에만 존재하는 목록 항목이다.
  elementAdded,

  /// 이전 근거에만 존재하는 목록 항목이다.
  elementRemoved;

  /// 개발자용 해석 안내다. UI 문구나 현재성 판정이 아니다.
  String get description => switch (this) {
    productMismatch => '서로 다른 제품의 근거입니다.',
    valueChanged => '형상·문구 필드의 실제 값이 다릅니다.',
    kindChanged => '요소의 종류가 다릅니다. 하위 필드 대신 요소 전체를 확인하세요.',
    elementAdded => '다음 근거에 목록 항목이 추가됐습니다.',
    elementRemoved => '이전 근거의 목록 항목이 제거됐습니다.',
  };
}

/// 차이를 관찰한 실제 요소 종류다. 저장 태그나 미래 엔진 지원 목록이 아니다.
enum GeometryTextBasisKind {
  /// 중심/반지름 원 경계다.
  circleBoundary,

  /// 닫힌 경로 경계다.
  pathBoundary,

  /// 경로의 선분 구간이다.
  lineTo,

  /// 경로의 원호 구간이다.
  arcTo,

  /// 자동 줄바꿈 입력이다.
  automaticLineBreak,

  /// 직접 지정 줄바꿈 입력이다.
  specifiedLineBreak,
}

/// 양쪽 위치 또는 한쪽의 추가/삭제 위치만 가진 불변 상세다.
sealed class GeometryTextBasisDifferencePosition {
  const GeometryTextBasisDifferencePosition._();

  /// 이전 근거 기준 상대 필드 경로다. 추가 항목에는 없다.
  String? get previousFieldPath;

  /// 다음 근거 기준 상대 필드 경로다. 삭제 항목에는 없다.
  String? get nextFieldPath;
}

/// 양쪽에 존재하는 같은 역할의 필드다. 영역 목록의 인덱스는 서로 다를 수 있다.
final class ComparedBasisFields extends GeometryTextBasisDifferencePosition {
  /// 근거 필드 문법을 검사한다. 외부 객체의 실제 인덱스 범위까지 알 수는 없다.
  ComparedBasisFields({
    required this.previousFieldPath,
    required this.nextFieldPath,
  }) : super._() {
    _checkPath(previousFieldPath, 'previousFieldPath');
    _checkPath(nextFieldPath, 'nextFieldPath');
    if (_removeAreaIndex(previousFieldPath) !=
        _removeAreaIndex(nextFieldPath)) {
      throw ArgumentError.value(
        nextFieldPath,
        'nextFieldPath',
        '양쪽 경로는 같은 영역 역할의 같은 필드여야 합니다.',
      );
    }
  }
  @override
  final String previousFieldPath;
  @override
  final String nextFieldPath;
}

/// 다음에 실제로 존재하는 추가 항목 위치다. 이전 가짜 슬롯을 만들지 않는다.
final class AddedBasisElement extends GeometryTextBasisDifferencePosition {
  /// 목록 항목 전체의 경로만 허용한다.
  AddedBasisElement(this.nextFieldPath) : super._() {
    _checkElementPath(nextFieldPath, 'nextFieldPath');
  }
  @override
  String? get previousFieldPath => null;
  @override
  final String nextFieldPath;
}

/// 이전에 실제로 존재하는 삭제 항목 위치다. 다음 가짜 슬롯을 만들지 않는다.
final class RemovedBasisElement extends GeometryTextBasisDifferencePosition {
  /// 목록 항목 전체의 경로만 허용한다.
  RemovedBasisElement(this.previousFieldPath) : super._() {
    _checkElementPath(previousFieldPath, 'previousFieldPath');
  }
  @override
  final String previousFieldPath;
  @override
  String? get nextFieldPath => null;
}

/// 종류 변경의 양쪽 위치와 실제 종류다. 형상/원문 값은 포함하지 않는다.
final class ChangedBasisKinds extends GeometryTextBasisDifferencePosition {
  /// 같은 계열의 서로 다른 종류와 그 계열의 요소 전체 경로만 허용한다.
  ChangedBasisKinds({
    required this.fields,
    required this.previousKind,
    required this.nextKind,
  }) : super._() {
    final family = previousKind.index ~/ 2;
    if (previousKind == nextKind || family != nextKind.index ~/ 2) {
      throw ArgumentError.value(nextKind, 'nextKind', '같은 계열의 서로 다른 종류여야 합니다.');
    }
    final path = fields.previousFieldPath;
    final correct = switch (family) {
      0 => RegExp(
        r'^outline$|\.boundary$|\.outer$|\.exclusions\[[0-9]+\]$',
      ).hasMatch(path),
      1 => RegExp(r'\.segments\[[0-9]+\]$').hasMatch(path),
      _ => path.endsWith('.input.lineBreak'),
    };
    if (!correct) {
      throw ArgumentError.value(
        path,
        'fields.previousFieldPath',
        '종류 계열의 요소 전체 경로가 필요합니다.',
      );
    }
  }

  /// 양쪽에서 실제로 존재하는 요소 전체다.
  final ComparedBasisFields fields;

  /// 이전 요소의 종류다.
  final GeometryTextBasisKind previousKind;

  /// 다음 요소의 종류다.
  final GeometryTextBasisKind nextKind;
  @override
  String get previousFieldPath => fields.previousFieldPath;
  @override
  String get nextFieldPath => fields.nextFieldPath;
}

/// 특정 제품/영역의 부분 차이다. 외부 변경이 불가능하며 원문·전체 형상을 담지 않는다.
/// named 생성자가 코드/상세 조합을 제한한다. 진단 순서는 계약이 아니다.
final class GeometryTextBasisDifference {
  GeometryTextBasisDifference._(
    this.code,
    this.previousProductId,
    this.nextProductId,
    this.areaId,
    this.position,
  ) {
    _checkId(previousProductId, 'previousProductId');
    _checkId(nextProductId, 'nextProductId');
    if (code == GeometryTextBasisDifferenceCode.productMismatch) {
      if (previousProductId == nextProductId) {
        throw ArgumentError.value(
          nextProductId,
          'nextProductId',
          '제품 불일치에는 서로 다른 ID가 필요합니다.',
        );
      }
    }
    if (code != GeometryTextBasisDifferenceCode.productMismatch &&
        (position.previousFieldPath == 'productId' ||
            position.nextFieldPath == 'productId')) {
      throw ArgumentError.value(
        position,
        'position',
        '제품 ID 차이는 productMismatch로만 표현해야 합니다.',
      );
    }
    final paths = [
      if (position.previousFieldPath case final String p) p,
      if (position.nextFieldPath case final String p) p,
    ];
    final inArea = paths.any((p) => p.startsWith('areas['));
    if (inArea && (areaId == null || areaId!.isEmpty) ||
        !inArea && areaId != null) {
      throw ArgumentError.value(
        areaId,
        'areaId',
        '영역 경로에만 비어 있지 않은 영역 ID가 필요합니다.',
      );
    }
  }

  /// 다른 제품 비교를 명시적으로 표현한다. 영역/형상 차이를 함께 추정하지 않는다.
  factory GeometryTextBasisDifference.productMismatch({
    required String previousProductId,
    required String nextProductId,
  }) => GeometryTextBasisDifference._(
    GeometryTextBasisDifferenceCode.productMismatch,
    previousProductId,
    nextProductId,
    null,
    ComparedBasisFields(
      previousFieldPath: 'productId',
      nextFieldPath: 'productId',
    ),
  );

  /// 같은 제품의 실제 값 차이다. 영역 경로이면 areaId가 필수다.
  factory GeometryTextBasisDifference.value({
    required String productId,
    required ComparedBasisFields fields,
    String? areaId,
  }) => GeometryTextBasisDifference._(
    GeometryTextBasisDifferenceCode.valueChanged,
    productId,
    productId,
    areaId,
    fields,
  );

  /// 같은 제품의 요소 종류 차이다. 존재하지 않는 하위 필드를 가리키지 않는다.
  factory GeometryTextBasisDifference.kind({
    required String productId,
    required ChangedBasisKinds kinds,
    String? areaId,
  }) => GeometryTextBasisDifference._(
    GeometryTextBasisDifferenceCode.kindChanged,
    productId,
    productId,
    areaId,
    kinds,
  );

  /// 다음 근거에 추가된 항목의 실제 경로다.
  factory GeometryTextBasisDifference.added({
    required String productId,
    required AddedBasisElement element,
    String? areaId,
  }) => GeometryTextBasisDifference._(
    GeometryTextBasisDifferenceCode.elementAdded,
    productId,
    productId,
    areaId,
    element,
  );

  /// 이전 근거에서 제거된 항목의 실제 경로다.
  factory GeometryTextBasisDifference.removed({
    required String productId,
    required RemovedBasisElement element,
    String? areaId,
  }) => GeometryTextBasisDifference._(
    GeometryTextBasisDifferenceCode.elementRemoved,
    productId,
    productId,
    areaId,
    element,
  );

  /// 차이의 기계적 분류다.
  final GeometryTextBasisDifferenceCode code;

  /// 이전 근거의 제품 ID다.
  final String previousProductId;

  /// 다음 근거의 제품 ID다.
  final String nextProductId;

  /// 영역 차이에만 존재하는 ID다. 표시명/목록 순서로 추정하지 않는다.
  final String? areaId;

  /// 이전/다음 상대 경로와 종류 변경 시 실제 종류다.
  final GeometryTextBasisDifferencePosition position;

  @override
  String toString() =>
      'GeometryTextBasisDifference(code=${code.name}, previousProductId=$previousProductId, nextProductId=$nextProductId, areaId=$areaId, previousFieldPath=${position.previousFieldPath}, nextFieldPath=${position.nextFieldPath}, 설명=${code.description}${position is ChangedBasisKinds ? ', previousKind=${(position as ChangedBasisKinds).previousKind.name}, nextKind=${(position as ChangedBasisKinds).nextKind.name}' : ''})';
}

void _checkId(String value, String name) {
  if (value.isEmpty) {
    throw ArgumentError.value(value, name, '제품 ID는 빈 문자열일 수 없습니다.');
  }
}

String _removeAreaIndex(String p) =>
    p.replaceFirst(RegExp(r'^areas\[[0-9]+\]'), 'areas');
const _index = r'\[(?:0|[1-9][0-9]*)\]';
const _point = r'\.(?:x|y)';
const _boundary =
    '(?:\\.center$_point|\\.radius|\\.path\\.start$_point|\\.path\\.segments$_index(?:\\.end$_point|\\.bulge)?)';
final _path = RegExp(
  '^(?:productId|coordinateSpace\\.lengthUnit|outline(?:$_boundary)?|cutouts$_index(?:\\.cutoutId|\\.boundary(?:$_boundary)?)?|areas$_index(?:\\.region\\.outer(?:$_boundary)?|\\.region\\.exclusions$_index(?:$_boundary)?|\\.input\\.sourceText|\\.input\\.lineBreak(?:\\.lines)?)?)\$',
);
void _checkPath(String path, String name) {
  if (_path.firstMatch(path)?.end != path.length) {
    throw ArgumentError.value(path, name, '근거의 실제 필드 경로 문법에 맞아야 합니다.');
  }
}

void _checkElementPath(String path, String name) {
  _checkPath(path, name);
  if (!RegExp('$_index\$').hasMatch(path)) {
    throw ArgumentError.value(path, name, '추가/삭제는 목록 항목 전체를 가리켜야 합니다.');
  }
}
