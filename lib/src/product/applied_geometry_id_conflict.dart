/// 공통 적용 ID를 다른 내용으로 사용한 충돌이다. 한 구성의 참조 오류와 구분한다.
enum AppliedGeometryIdConflictCode {
  /// 두 유효 구성의 같은 ID에 서로 다른 geometry/source가 연결되었다.
  /// 내용을 변경하려면 새 ID를 발급해야 한다.
  snapshotContentConflict;

  /// 개발자 진단 설명이다. 사용자 화면의 확정 문구나 로그 메시지가 아니다.
  String get description => '공통 적용 ID의 내용이 변경되었습니다. 변경한 스냅샷에는 새 ID가 필요합니다.';
}

/// 두 구성의 공통 적용 ID 하나에 대한 내용 충돌이다.
/// 스냅샷·원문·JSON을 보관하지 않으며 내용 변경의 위치만 제공한다.
final class AppliedGeometryIdConflict {
  /// 필수 ID·0 기반 인덱스·중복 없는 비어 있지 않은 경로 목록을 검사한다.
  /// 잘못된 진단 구성은 assert 비활성 환경에서도 ArgumentError다.
  AppliedGeometryIdConflict({
    required this.appliedGeometryId,
    required this.previousIndex,
    required this.nextIndex,
    required List<String> changedFieldPaths,
  }) : changedFieldPaths = List.unmodifiable(changedFieldPaths) {
    if (appliedGeometryId.isEmpty ||
        previousIndex < 0 ||
        nextIndex < 0 ||
        this.changedFieldPaths.isEmpty ||
        this.changedFieldPaths.toSet().length !=
            this.changedFieldPaths.length ||
        this.changedFieldPaths.any(
          (path) => _snapshotFieldPath.firstMatch(path)?.end != path.length,
        )) {
      throw ArgumentError('적용 ID 충돌의 ID·인덱스·변경 경로가 잘못되었습니다.');
    }
  }

  /// 현재 지원하는 충돌은 한 종류다. 코드/상세의 잘못된 조합을 입력받지 않는다.
  AppliedGeometryIdConflictCode get code =>
      AppliedGeometryIdConflictCode.snapshotContentConflict;

  /// 두 구성의 소유 범위 안에서 연결한 공통 ID다. trim/정규화하지 않는다.
  final String appliedGeometryId;

  /// previous.appliedGeometries에서의 0 기반 선언 위치다.
  final int previousIndex;

  /// next.appliedGeometries에서의 0 기반 선언 위치다.
  final int nextIndex;

  /// 충돌 스냅샷의 실제 다음 구성 위치다. 제품 목록 위치가 아니다.
  String get fieldPath => 'next.appliedGeometries[$nextIndex]';

  /// 스냅샷 값 기준의 상대 Dart 필드 경로다. [fieldPath] 뒤에 연결해 해석한다.
  ///
  /// 길이 변화는 목록 전체, 종류 변화는 경계/구간 전체, source 유무는 source로 요약한다.
  /// 그 밖에는 다음 구성에도 존재하는 필드/인덱스다. JSON 키의 존재 여부가 아니며
  /// sourceRevision은 nullable Dart 필드다. 목록 순서는 계약이 아니다.
  /// 문법/현재 필드 종류만 검사하며 외부 구성의 실제 인덱스 범위는 이 생성자가 알 수 없다.
  final List<String> changedFieldPaths;

  @override
  String toString() =>
      'AppliedGeometryIdConflict(code=${code.name}, '
      'fieldPath=$fieldPath, appliedGeometryId=$appliedGeometryId, '
      'previousIndex=$previousIndex, nextIndex=$nextIndex, '
      '설명=${code.description}, changedFieldPaths=$changedFieldPaths)';
}

// 현재 스냅샷의 필드 계약만 표현한다. 임의 객체 탐색/JSON diff 도구가 아니다.
const _index = r'\[(?:0|[1-9][0-9]*)\]';
const _pointFields = r'(?:\.x|\.y)';
const _segmentFields = '(?:\\.end$_pointFields|\\.bulge)';
const _boundaryFields =
    '(?:\\.center$_pointFields|\\.radius|\\.path\\.start$_pointFields'
    '|\\.path\\.segments(?:$_index(?:$_segmentFields)?)?)';
final _snapshotFieldPath = RegExp(
  r'^(?:source(?:\.sourceDesignId|\.sourceRevision)?|'
  r'geometry\.coordinateSpace\.lengthUnit|'
  'geometry\\.outline(?:$_boundaryFields)?|'
  'geometry\\.cutouts(?:$_index(?:\\.cutoutId|\\.boundary(?:$_boundaryFields)?))?|'
  'geometry\\.textAreas(?:$_index(?:\\.areaId|\\.label|\\.region\\.outer(?:$_boundaryFields)?|'
  '\\.region\\.exclusions(?:$_index(?:$_boundaryFields)?)?))?)'
  r'$',
);
