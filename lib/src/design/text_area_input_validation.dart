import 'package:meta/meta.dart';
import 'package:r_edit_workflow/src/design/design_errors.dart';
import 'package:r_edit_workflow/src/design/design_geometry.dart';
import 'package:r_edit_workflow/src/text_area_input.dart';

/// 각 도안 영역에 입력 하나가 대응하는지 ID로 대조하고 모든 연결 오류를 반환한다.
/// 입력 순서/원문/줄바꿈을 바꾸지 않는다. label/좌표로 추정하지 않는다.
/// 빈 결과는 연결 조건만 충족함을 뜻하며 배치 완료·저장/제작 가능 판정이 아니다.
/// 도안과 입력이 모두 영역 0개인 경우도 빈 결과다. 반환 목록은 수정 불가다.
/// 중복/미정의 입력의 fieldPath는 `inputs[i].areaId`, 누락은 정의의 `textAreas[i].areaId`다.
/// i는 전달 목록의 0 기반 위치이며 같은 ID도 다른 도안의 영역으로 추정하지 않는다.
/// 값 생성 오류를 새로 수집하지 않으며 이미 생성된 입력의 독립 연결 issue만 반환한다.
@useResult
List<DesignValidationIssue> validateTextAreaInputs({
  required DesignGeometry design,
  required List<TextAreaInput> inputs,
}) {
  final definitions = {
    for (var i = 0; i < design.textAreas.length; i++)
      design.textAreas[i].areaId: i,
  };
  final firstIndices = <String, int>{};
  final issues = <DesignValidationIssue>[];
  for (var i = 0; i < inputs.length; i++) {
    final id = inputs[i].areaId;
    final first = firstIndices[id];
    if (first != null) {
      issues.add(
        DesignValidationIssue(
          code: DesignErrorCode.duplicateInputAreaId,
          fieldPath: 'inputs[$i].areaId',
          details: DesignDuplicateDetails(
            identifier: id,
            firstIndex: first,
            duplicateIndex: i,
          ),
        ),
      );
    } else {
      firstIndices[id] = i;
    }
    if (!definitions.containsKey(id)) {
      issues.add(
        DesignValidationIssue(
          code: DesignErrorCode.unknownInputAreaId,
          fieldPath: 'inputs[$i].areaId',
          details: DesignIdentifierDetails(id),
        ),
      );
    }
  }
  for (var i = 0; i < design.textAreas.length; i++) {
    final id = design.textAreas[i].areaId;
    if (!firstIndices.containsKey(id)) {
      issues.add(
        DesignValidationIssue(
          code: DesignErrorCode.missingAreaInput,
          fieldPath: 'textAreas[$i].areaId',
          details: DesignIdentifierDetails(id),
        ),
      );
    }
  }
  return List.unmodifiable(issues);
}
