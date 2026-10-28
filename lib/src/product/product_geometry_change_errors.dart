import 'package:r_edit_workflow/src/design/design_errors.dart';
import 'package:r_edit_workflow/src/product/applied_geometry_id_conflict.dart';
import 'package:r_edit_workflow/src/product/product_design_errors.dart';

/// 준비 요청의 정상 거부 사유다. API 오용/내부 결함을 이 코드로 숨기지 않는다.
enum ProductGeometryChangeCode {
  /// 빈 ID의 요청 필드. 실제 빈 값 상세를 보고 호출자가 명시 ID를 제공한다.
  invalidChangeIdentifier,

  /// request.targets가 비었다. 대상 수 0을 확인하고 제품을 명시한다.
  emptyTargetSet,

  /// 한 productId의 요청 위치가 둘 이상이다. 모든 위치를 보고 하나로 선택한다.
  duplicateTargetProduct,

  /// 요청 productId가 기준에 없다. 요청 위치/ID를 보고 최신 기준에서 선택한다.
  unknownTargetProduct,

  /// Revise source가 기준에 없다. request.sourceAppliedGeometryId를 수정한다.
  unknownSourceAppliedGeometry,

  /// Revise 대상의 기준 적용 ID가 다르다. 기대/실제 ID와 기준 제품 위치를 확인한다.
  unexpectedAppliedGeometry,

  /// 제안 ID가 기존 다른 내용을 가리킨다. 기준 위치/변경 경로를 보고 새 ID를 사용한다.
  snapshotContentConflict,

  /// mapping/제거의 이전 영역이 없다. 해당 요청 위치와 이전 문맥 ID를 수정한다.
  unknownSourceArea,

  /// mapping의 제안 영역이 없다. 해당 toAreaId를 수정한다. 신규 입력 오류와 구분한다.
  unknownTargetArea,

  /// mapping에서 같은 이전 영역을 여러 번 사용했다. source의 모든 대응 위치를 수정한다.
  duplicateSourceMapping,

  /// mapping에서 같은 제안 영역에 여러 입력을 보냈다. target의 모든 위치를 수정한다.
  duplicateTargetMapping,

  /// 유지/대응/제거 또는 유지/대응/신규 공급이 충돌한다. 상세의 문맥과 위치에서 하나만 선택한다.
  conflictingInputDisposition,

  /// 이전 입력에 유지/대응/제거 선택이 없다. baseline 입력 위치를 보고 명시 처리한다.
  unresolvedSourceInput,

  /// 기존 영역 검사의 진단이다. 하위 코드/경로/상세와 상위 실제 위치를 함께 처리한다.
  areaInputMismatch,

  /// 해석 완료된 전체 후보의 구성 진단이다. candidate 위치 및 원래 하위 진단을 수정한다.
  candidateConfigurationInvalid;

  /// 개발자용 기본 설명이다. 사용자 표시 문구나 로그 정책을 결정하지 않는다.
  String get description => switch (this) {
    invalidChangeIdentifier => '변경 요청의 ID는 빈 문자열일 수 없습니다.',
    emptyTargetSet => '변경 대상 제품을 하나 이상 명시해야 합니다.',
    duplicateTargetProduct => '같은 제품이 중복 선택되어 요청을 유일하게 해석할 수 없습니다.',
    unknownTargetProduct => '기준 구성에 변경 대상 제품이 없습니다.',
    unknownSourceAppliedGeometry => '부분 수정의 기준 적용 형상이 없습니다.',
    unexpectedAppliedGeometry => '대상 제품이 부분 수정의 기준 적용 형상을 참조하지 않습니다.',
    snapshotContentConflict => '기존 적용 ID의 내용을 바꿀 수 없습니다. 새 ID가 필요합니다.',
    unknownSourceArea => '이전 입력/영역에 없는 ID를 선택했습니다.',
    unknownTargetArea => '제안 형상에 없는 영역으로 대응했습니다.',
    duplicateSourceMapping => '이전 입력 하나를 여러 영역에 전달할 수 없습니다.',
    duplicateTargetMapping => '새 영역 하나에 여러 이전 입력을 전달할 수 없습니다.',
    conflictingInputDisposition => '같은 입력 또는 영역에 서로 충돌하는 선택이 있습니다.',
    unresolvedSourceInput => '이전 입력의 전달 또는 개별 제거 선택이 필요합니다.',
    areaInputMismatch => '제안 영역과 공급할 입력의 대응이 부족하거나 잘못되었습니다.',
    candidateConfigurationInvalid => '전체 후보의 제품/적용 형상 참조가 유효하지 않습니다.',
  };
}

/// 제품/도안 변경에 한정된 구조화 상세다. 원문·전체 구성을 보관하지 않는다.
sealed class ProductGeometryChangeDetails {
  const ProductGeometryChangeDetails._();
}

/// 빈 식별자 자체다. 다른 유효 식별자나 원문으로 보정하지 않는다.
final class ChangeIdentifierDetails extends ProductGeometryChangeDetails {
  /// 실제 빈 값만 허용한다. 유효 ID를 빈 ID 오류로 보고하는 API 오용은 거부한다.
  ChangeIdentifierDetails(this.identifier) : super._() {
    if (identifier.isNotEmpty) {
      throw ArgumentError.value(identifier, 'identifier', '빈 ID 진단만 허용합니다.');
    }
  }

  /// 보정하지 않은 빈 문자열이다.
  final String identifier;
  @override
  String toString() => 'identifier=""';
}

/// 빈 대상 목록의 진단이다. 임의 count를 받아 잘못된 상세를 만들지 않는다.
final class ChangeEmptyTargetsDetails extends ProductGeometryChangeDetails {
  /// 대상 수가 0인 거부를 표현한다.
  const ChangeEmptyTargetsDetails() : super._();

  /// 이 상세가 나타내는 대상 수다.
  int get targetCount => 0;
  @override
  String toString() => 'targetCount=0';
}

/// 요청 대상 하나의 식별자와 0 기반 위치다.
final class ChangeTargetDetails extends ProductGeometryChangeDetails {
  /// 비어 있지 않은 제품 ID와 음수가 아닌 위치만 허용한다.
  ChangeTargetDetails({required this.productId, required this.targetIndex})
    : super._() {
    _requireId(productId, 'productId');
    _requireIndex(targetIndex, 'targetIndex');
  }

  /// 요청에서 선택한 제품 ID다.
  final String productId;

  /// request.targets의 0 기반 위치다.
  final int targetIndex;
  @override
  String toString() => 'productId=$productId, targetIndex=$targetIndex';
}

/// 한 제품을 중복 선언한 모든 요청 위치다. 어느 항목도 우선 선택하지 않는다.
final class ChangeDuplicateTargetsDetails extends ProductGeometryChangeDetails {
  /// 서로 다른 0 기반 위치 둘 이상을 방어 복사한다.
  ChangeDuplicateTargetsDetails({
    required this.productId,
    required List<int> targetIndices,
  }) : targetIndices = List.unmodifiable(targetIndices),
       super._() {
    _requireId(productId, 'productId');
    if (this.targetIndices.length < 2 ||
        this.targetIndices.toSet().length != this.targetIndices.length) {
      throw ArgumentError.value(
        this.targetIndices.length,
        'targetIndices',
        '서로 다른 위치 둘 이상이 필요합니다.',
      );
    }
    for (final (i, index) in this.targetIndices.indexed) {
      _requireIndex(index, 'targetIndices[$i]');
    }
  }

  /// 중복 선언한 제품 ID다.
  final String productId;

  /// request.targets의 모든 중복 위치다. 반환 목록은 수정 불가다.
  final List<int> targetIndices;
  @override
  String toString() => 'productId=$productId, targetIndices=$targetIndices';
}

/// 존재하지 않는 부분 수정 기준의 ID다.
final class ChangeSourceDetails extends ProductGeometryChangeDetails {
  /// 빈 ID는 별도 식별 진단으로 처리하며 여기서는 거부한다.
  ChangeSourceDetails(this.sourceAppliedGeometryId) : super._() {
    _requireId(sourceAppliedGeometryId, 'sourceAppliedGeometryId');
  }

  /// request.sourceAppliedGeometryId의 실제 값이다.
  final String sourceAppliedGeometryId;
  @override
  String toString() => 'sourceAppliedGeometryId=$sourceAppliedGeometryId';
}

/// 부분 수정 대상의 기대/실제 적용 참조다.
final class ChangeAppliedReferenceDetails extends ProductGeometryChangeDetails {
  /// 유효 ID·0 기반 위치를 검사한다. 기대/실제 값이 같으면 오용이다.
  ChangeAppliedReferenceDetails({
    required this.productId,
    required this.productIndex,
    required this.expectedAppliedGeometryId,
    required this.actualAppliedGeometryId,
  }) : super._() {
    _requireId(productId, 'productId');
    _requireIndex(productIndex, 'productIndex');
    _requireId(expectedAppliedGeometryId, 'expectedAppliedGeometryId');
    _requireId(actualAppliedGeometryId, 'actualAppliedGeometryId');
    if (expectedAppliedGeometryId == actualAppliedGeometryId) {
      throw ArgumentError.value(
        actualAppliedGeometryId,
        'actualAppliedGeometryId',
        '기대 참조와 다른 값이어야 합니다.',
      );
    }
  }

  /// 기준 제품 ID다.
  final String productId;

  /// baseline.products의 위치다.
  final int productIndex;

  /// 요청의 source 적용 ID다.
  final String expectedAppliedGeometryId;

  /// 기준 제품이 실제 참조한 적용 ID다.
  final String actualAppliedGeometryId;
  @override
  String toString() =>
      'productId=$productId, productIndex=$productIndex, expected=$expectedAppliedGeometryId, actual=$actualAppliedGeometryId';
}

/// 같은 ID의 내용 충돌이다. 기존 경로 문법 검증을 재사용한다.
final class ChangeSnapshotConflictDetails extends ProductGeometryChangeDetails {
  /// ID/위치/변경 경로의 방어는 기존 충돌 값과 동일하다.
  ChangeSnapshotConflictDetails({
    required String appliedGeometryId,
    required int baselineIndex,
    required List<String> changedFieldPaths,
  }) : _conflict = AppliedGeometryIdConflict(
         appliedGeometryId: appliedGeometryId,
         previousIndex: baselineIndex,
         nextIndex: baselineIndex,
         changedFieldPaths: changedFieldPaths,
       ),
       super._();
  final AppliedGeometryIdConflict _conflict;

  /// 기준과 요청에 공통인 ID다.
  String get appliedGeometryId => _conflict.appliedGeometryId;

  /// baseline.appliedGeometries의 위치다.
  int get baselineIndex => _conflict.previousIndex;

  /// 요청 스냅샷 기준의 상대 변경 필드다. 수정 불가다.
  List<String> get changedFieldPaths => _conflict.changedFieldPaths;
  @override
  String toString() =>
      'appliedGeometryId=$appliedGeometryId, baselineIndex=$baselineIndex, changedFieldPaths=$changedFieldPaths';
}

/// 같은 문자열이라도 이전 입력과 제안 영역의 문맥을 구분한다.
enum ChangeAreaSide {
  /// 기준 제품이 소유한 이전 입력/영역이다.
  source,

  /// 제안 형상에서 공급받을 영역이다.
  target,
}

/// 영역 선택 오류의 제품·양쪽 적용 문맥·실제 선택 위치다.
final class ChangeAreaSelectionDetails extends ProductGeometryChangeDetails {
  /// ID와 실제 request/baseline 위치 목록을 검사하고 방어 복사한다.
  ChangeAreaSelectionDetails({
    required this.productId,
    required this.previousAppliedGeometryId,
    required this.proposedAppliedGeometryId,
    required this.areaId,
    required this.side,
    required List<String> selectionPaths,
  }) : selectionPaths = List.unmodifiable(selectionPaths),
       super._() {
    _requireId(productId, 'productId');
    _requireId(previousAppliedGeometryId, 'previousAppliedGeometryId');
    _requireId(proposedAppliedGeometryId, 'proposedAppliedGeometryId');
    _requireId(areaId, 'areaId');
    if (this.selectionPaths.isEmpty) {
      throw ArgumentError.value(0, 'selectionPaths', '위치 하나 이상이 필요합니다.');
    }
    if (this.selectionPaths.toSet().length != this.selectionPaths.length) {
      throw ArgumentError.value(
        this.selectionPaths.length,
        'selectionPaths',
        '위치는 중복될 수 없습니다.',
      );
    }
    for (final (i, path) in this.selectionPaths.indexed) {
      _requirePath(path, 'selectionPaths[$i]');
    }
  }

  /// 기준 제품의 ID다.
  final String productId;

  /// 이전 영역을 해석하는 적용 ID다.
  final String previousAppliedGeometryId;

  /// 새 영역을 해석하는 제안 ID다.
  final String proposedAppliedGeometryId;

  /// 오류에 관련된 원래 영역 ID다.
  final String areaId;

  /// source/target 문맥이다.
  final ChangeAreaSide side;

  /// 충돌/선택의 실제 0 기반 필드 위치들이다. 원문은 포함하지 않는다.
  final List<String> selectionPaths;
  @override
  String toString() =>
      'productId=$productId, previous=$previousAppliedGeometryId, proposed=$proposedAppliedGeometryId, areaId=$areaId, side=${side.name}, selectionPaths=$selectionPaths';
}

/// 기존 영역 연결 진단을 변형 없이 보존하는 상위 문맥이다.
final class ChangeAreaInputDetails extends ProductGeometryChangeDetails {
  /// 유효 문맥 ID와 연결 검사 전용 하위 코드를 검사한다.
  ChangeAreaInputDetails({
    required this.productId,
    required this.previousAppliedGeometryId,
    required this.proposedAppliedGeometryId,
    required this.cause,
  }) : super._() {
    _requireId(productId, 'productId');
    _requireId(previousAppliedGeometryId, 'previousAppliedGeometryId');
    _requireId(proposedAppliedGeometryId, 'proposedAppliedGeometryId');
    if (!{
      DesignErrorCode.missingAreaInput,
      DesignErrorCode.unknownInputAreaId,
      DesignErrorCode.duplicateInputAreaId,
    }.contains(cause.code)) {
      throw ArgumentError.value(cause.code, 'cause', '영역 입력 연결 진단만 허용합니다.');
    }
  }

  /// 기준 제품 ID다.
  final String productId;

  /// 기준 적용 ID다.
  final String previousAppliedGeometryId;

  /// 제안 적용 ID다.
  final String proposedAppliedGeometryId;

  /// 원래 코드·상대 경로·상세 객체다.
  final DesignValidationIssue cause;
  @override
  String toString() =>
      'productId=$productId, previous=$previousAppliedGeometryId, proposed=$proposedAppliedGeometryId, cause=($cause)';
}

/// 전체 후보의 기존 참조 진단이다. 원래 하위 코드를 덮어쓰지 않는다.
final class ChangeConfigurationDetails extends ProductGeometryChangeDetails {
  /// 기존 불변 진단을 그대로 보관한다.
  const ChangeConfigurationDetails(this.cause) : super._();

  /// 원래 상대 위치와 상세를 가진 구성 진단이다.
  final ProductDesignIssue cause;
  @override
  String toString() => 'cause=($cause)';
}

/// 준비의 정상 거부 한 건이다. 목록 순서는 계약이 아니며 메시지 파싱이 필요 없다.
final class ProductGeometryChangeIssue {
  /// 코드/상세의 허용 조합과 필수 위치·중복 선택 수를 런타임 검사한다.
  ProductGeometryChangeIssue({
    required this.code,
    required this.fieldPath,
    required this.details,
  }) {
    _requirePath(fieldPath, 'fieldPath');
    final valid = switch (code) {
      ProductGeometryChangeCode.invalidChangeIdentifier =>
        details is ChangeIdentifierDetails,
      ProductGeometryChangeCode.emptyTargetSet =>
        details is ChangeEmptyTargetsDetails,
      ProductGeometryChangeCode.duplicateTargetProduct =>
        details is ChangeDuplicateTargetsDetails,
      ProductGeometryChangeCode.unknownTargetProduct =>
        details is ChangeTargetDetails,
      ProductGeometryChangeCode.unknownSourceAppliedGeometry =>
        details is ChangeSourceDetails,
      ProductGeometryChangeCode.unexpectedAppliedGeometry =>
        details is ChangeAppliedReferenceDetails,
      ProductGeometryChangeCode.snapshotContentConflict =>
        details is ChangeSnapshotConflictDetails,
      ProductGeometryChangeCode.areaInputMismatch =>
        details is ChangeAreaInputDetails,
      ProductGeometryChangeCode.candidateConfigurationInvalid =>
        details is ChangeConfigurationDetails,
      ProductGeometryChangeCode.unknownSourceArea ||
      ProductGeometryChangeCode.unknownTargetArea ||
      ProductGeometryChangeCode.unresolvedSourceInput =>
        details is ChangeAreaSelectionDetails,
      ProductGeometryChangeCode.duplicateSourceMapping ||
      ProductGeometryChangeCode.duplicateTargetMapping ||
      ProductGeometryChangeCode.conflictingInputDisposition =>
        details is ChangeAreaSelectionDetails &&
            (details as ChangeAreaSelectionDetails).selectionPaths.length >= 2,
    };
    if (!valid) {
      throw ArgumentError.value(
        details.runtimeType,
        'details',
        '오류 코드에 맞는 필수 상세가 필요합니다.',
      );
    }
    if (details case final ChangeAreaSelectionDetails area) {
      if ((code == ProductGeometryChangeCode.unknownSourceArea ||
                  code == ProductGeometryChangeCode.unresolvedSourceInput ||
                  code == ProductGeometryChangeCode.duplicateSourceMapping) &&
              area.side != ChangeAreaSide.source ||
          (code == ProductGeometryChangeCode.unknownTargetArea ||
                  code == ProductGeometryChangeCode.duplicateTargetMapping) &&
              area.side != ChangeAreaSide.target) {
        throw ArgumentError.value(
          area.side,
          'details.side',
          '코드의 이전/새 영역 문맥과 일치해야 합니다.',
        );
      }
    }
  }

  /// 정상 거부의 기계 판별 코드다.
  final ProductGeometryChangeCode code;

  /// request/baseline/candidate의 실제 필드 위치다. 인덱스는 모두 0 기반이다.
  final String fieldPath;

  /// 해당 코드가 요구하는 구체 상세다. 원문/전체 구성은 보관하지 않는다.
  final ProductGeometryChangeDetails details;
  @override
  String toString() =>
      'ProductGeometryChangeIssue(code=${code.name}, fieldPath=$fieldPath, 설명=${code.description}, $details)';
}

void _requireId(String value, String name) {
  if (value.isEmpty) {
    throw ArgumentError.value(value, name, 'ID는 빈 문자열일 수 없습니다.');
  }
}

void _requireIndex(int value, String name) {
  if (value < 0) throw ArgumentError.value(value, name, '인덱스는 0 이상이어야 합니다.');
}

final _changePath = RegExp(
  r'^(request|baseline|candidate)(\.[A-Za-z][A-Za-z0-9]*(\[(0|[1-9][0-9]*)\])?)+$',
);
void _requirePath(String value, String name) {
  if (_changePath.firstMatch(value)?.end != value.length) {
    throw ArgumentError.value(
      value,
      name,
      'request/baseline/candidate 기준 필드 경로가 필요합니다.',
    );
  }
}
