> 후속 설계(2026-10-29): [편집 세션과 최종 반영 경계](product-design-edit-session.md). 5절의 순수 apply(current:, prepared:) 제안은 단일 정본을 가진 세션 메서드 추천으로 대체한다. 현재 구현은 여전히 12·13절까지이며 세션/최종 반영 코드는 없다.

# 제품 적용 도안 변경 계약 — 설계

2026-10-27 설계와 후속 구현 기록이다. 현행 공개 구현은 12절 공통 ID 비교와 13절 요청/전체 후보 준비다. 최종 반영·세션 개정은 여전히 미구현 설계다.
이 문서의 ‘도안 변경’은 AppliedDesignGeometry의 형상·영역·출처 변경이다. 전체 제작 조건을 가진 AppliedDesign 변경이 아니다.

## 1. 기준과 현재 보장

- 최신 사용자 요구가 과거 문서의 제안보다 우선한다.
- 확인한 workflow HEAD: 7dc3538551e62c37889a4a9cf503b48ad879fafb. 시작 시 작업 트리·스테이징은 깨끗했다.
- 읽은 기준: [개발 지침](../AGENTS.md), [README](../README.md), [현재 계약](contract.md),
  [모델 설계](model-design.md), [제품·도안 연결 설계](product-design-binding.md),
  [구현 계약](product-design-configuration.md), [다음 작업](next-step.md),
  [개발 기준](development-rules-draft.md), [공통 기반](development-foundation.md),
  [예외·진단 기준](failure-diagnostics-logging.md).
- 공개 진입점 lib/r_edit_workflow.dart와 실제 AppliedDesignGeometry·DesignSourceReference·DesignGeometry·ProductInput·
  ProductDesignConfiguration, 두 참조 검증 함수 및 생성된 값 비교 코드를 대조했다.
  원본 Office 문서/과거 시험을 이번에 다시 읽거나 Dart 검증을 실행한 것으로 취급하지 않는다.

| 구분 | 현재 상태 |
|---|---|
| 구현됨 | 불변 형상/영역·원문/줄 입력·출처·제품 값, 현재 구성의 소유 ID·참조·영역 대응 검증 |
| 실제 API의 한계 | AppliedDesignGeometry 단독 생성자는 과거 내용을 모르며 전후 비교는 별도 validateAppliedGeometryIdConsistency 호출 책임 |
| 구현됨 | validateTextAreaInputs는 입력 중복/미정의/누락, validateProductDesignConfiguration은 소유 ID와 제품 참조의 독립 issue 수집 |
| 이번 설계 | 요청 → 영향/대응 확인 → 후보 검증 → 현재 기준 재확인 → 명시적 새 구성 반환 |
| 미구현 | 요청/준비/반영 API·변경 실행·세션 개정·이력 추적·결과/확인 무효화 실행·저장/동기화 |

과거 product-design-binding의 변경 제안은 이 문서로 구체화한다. 당시 ‘현재 구현’ 표와 예시를 최신 API 목록으로 읽지 않는다.

## 2. 변경 의도와 고정 대상

일괄 적용은 별도 ‘전체 변경’ 명령/동적 그룹이 아니라 아래 두 의도에 명시적 복수 대상을 전달하는 것이다.

| 의도 후보 | 입력과 대상 제한 추천 | 영역 입력 처리 |
|---|---|---|
| ReviseAppliedGeometry | sourceAppliedGeometryId 하나와 proposedGeometry. 모든 대상 제품이 기준 구성에서 그 ID를 참조해야 함 | 같은 업무 영역으로 유지한 areaId는 계속 사용. 유지 영역을 다른 의미로 재해석하지 않음 |
| ReplaceAppliedGeometry | proposedGeometry 하나. 대상들은 서로 다른 이전 적용 ID를 가져도 됨 | 제품별 명시적 영역 대응/신규 입력/제거 선택을 요구. 같은 문자열의 ID도 자동 대응하지 않음 |

두 의도는 ProductGeometryChangeRequest의 sealed 하위 타입을 추천한다.
ModifyDesign/ChangeDesign은 제작 조건까지 포함하는 것으로 읽히고 Update는 제자리 수정과 혼동되므로 위 이름을 추천한다.
함수명은 prepareProductGeometryChange와 applyPreparedProductGeometryChange를 추천한다.
‘영향 확인’은 준비 결과의 요약과 issue 검토이며 구조 검증만으로 계산 영향을 확정하는 분석기가 아니다.

요청은 순서 있는 targets 목록을 방어 복사해 소유한다. 각 항목은 productId를 명시한다.
유일한 productId 집합이 곧 고정 대상이며 중복은 합치지 않고 진단한다.
빈 대상도 정상 무변경과 구분해 거부하는 방안을 추천한다.
표시 문구·label·좌표·현재 선택 화면·목록 인덱스·같은 도안 참조로 대상을 추정하지 않는다.
준비 후 추가된 제품이나 같은 도안을 공유하는 비대상 제품은 자동 포함하지 않는다.
다른 적용 ID들을 같은 도안으로 추정해 Revise에 넣지 않는다. 그런 일괄 교체는 Replace와 제품별 대응을 사용한다.

### 불변 스냅샷 공유

- 여러 제품은 구성의 같은 appliedGeometryId 하나를 참조하여 같은 불변 geometry/source를 공유할 수 있다.
- 한 제품의 내용 변경은 새 ID의 스냅샷을 만들고 그 제품만 새 ID를 참조한다. 이전 공유 객체는 변경하지 않는다.
- 같은 변경을 받은 명시 대상들은 제안한 불변 스냅샷 하나를 공유한다.
  제품별 원문/줄 입력이 달라도 스냅샷의 geometry/source가 같으면 공유할 수 있다.
- 제품마다 제안 내용이 달라야 한다면 한 요청에 숨기지 않는다. 서로 다른 스냅샷/별도 요청이 필요하며
  여러 요청의 원자적 묶음은 첫 범위가 아니다.
- 이미 등록된 ID를 채택할 때는 실제 내용 전체가 같아야 한다. 출처 일치만으로 공유하지 않는다.
  다른 ID의 같은 내용을 자동 병합하지 않는다.

## 3. 적용 ID와 내용 비교

기준 구성 B와 후보 C의 공통 appliedGeometryId마다 스냅샷 값 전체가 같아야 한다.
geometry의 단위 문맥·외곽·관통 정의·영역 ID/label/경계/제외 목록, source와 sourceRevision을 모두 비교한다.
현재 필드만 일부 골라 ID 불변성을 검사하지 않는다. 이후 스냅샷 필드가 늘면 그 필드도 비교 대상이다.

비교는 실제 값의 구조 비교를 추천한다.
현재 Freezed 값 비교는 필드·하위 값·순서 있는 목록을 대조하므로 이를 기반으로 하되,
참조 동일성/ID/hashCode/JSON 문자열/출처 ID·버전만으로 생략하지 않는다.
JSON 키 순서·정수/소수 표기의 차이는 복원된 값의 비교와 구분한다.
수치는 현재 값 모델의 double 동등성을 사용하며 임의 반올림·허용오차·물리적 동등성 판정은 추가하지 않는다.

| 변경 | 같은 ID 사용 |
|---|---|
| 모든 값 동일 | 가능. 같은 ID 레코드를 중복 선언하지 않고 기존 슬롯을 재사용 |
| 치수/홀/영역/label/목록 순서/source/sourceRevision 중 하나라도 변경 | 불가. 새 ID 필수 |
| mm를 inch로 전체 환산해 실제 크기는 동일 | 저장된 단위/수치 표현이 달라지므로 새 ID 필수. 결과 재사용 판단은 별도 |
| 화면에서만 inch로 표시 | 저장 값이 그대로면 스냅샷 변경 아님 |

이 단계의 후보는 기존 appliedGeometries 전체를 같은 순서/값으로 유지하고 필요한 새 스냅샷 하나만 뒤에 추가한다.
제안 ID가 기존에 있고 내용도 같으면 추가하지 않는다. 내용이 다르면 snapshotContentConflict다.
미사용이 된 이전 스냅샷도 자동 삭제하지 않는 방안을 추천한다.
제품 목록 순서는 그대로이며 대상 제품의 참조와 승인된 입력 대응만 바뀐다.

이 규약은 현재 B와 C 모두에 있는 ID의 내용 변경을 발견한다.
이미 제거되어 B에 없는 ID가 과거에 다른 뜻으로 쓰였는지는 알 수 없다.
생존 기간 동안 ID를 다른 내용에 재사용하지 않는 원칙은 유지하되,
그 이력까지 강제하려면 별도 발급/사용 이력 또는 세션 소유 책임이 필요하다.
ID를 보존한다는 이번 추천이 영구 이력 저장소 구현·외부 파일 조작 방지 보장은 아니다.

## 4. 영역 입력 대응과 명시적 제거

ProductGeometryTarget 후보는 productId와 다음 세 목록을 필수로 받는다. 해당 내용이 없으면 호출자가 []를 명시한다.
필수 목록의 누락을 빈 목록으로 보정하는 요청 JSON API는 설계하지 않는다.

| 필드 후보 | 타입 | 의미 |
|---|---|---|
| productId | String | 기준 구성에서 찾는 제품. ID 규약은 기존처럼 빈 문자열 거부·trim/정규화 없음 |
| areaMappings | List<TextAreaInputMapping> | fromAreaId → toAreaId의 일대일 이전 입력 전달 |
| newTextInputs | List<TextAreaInput> | 새 영역에 호출자가 직접 제공한 유효 입력. 빈 원문 자동 생성 없음 |
| removedInputAreaIds | List<String> | 이 제품의 이전 입력을 새 구성에 넣지 않겠다는 개별·명시적 선택 |

TextAreaInputMapping은 fromAreaId/toAreaId만 가진다.
AreaMapping은 형상 좌표 정렬처럼 읽히고 TextTransfer는 원문 복사로 오해될 수 있어 이 이름을 추천한다.
ID는 표시 문구에서 만들지 않으며 같은 문자열의 areaId도 이전/새 적용 문맥으로 구분한다.

### 이전 입력과 새 정의의 정확한 대응

1. Revise에서는 이전/새 정의 양쪽에 유지된 areaId를 같은 업무 영역으로 선언한 것으로 본다.
   해당 입력의 sourceText·lineBreak·lines와 목록 내 상대 순서를 그대로 보존한다.
   좌표·크기·경계·label의 변화로 문구나 지정 줄을 다시 쓰지 않는다.
   의미가 바뀐 영역은 ID를 유지한 부분 수정으로 위장하지 말고 Replace 의도로 명시 대응한다.
   같은 업무 영역이라는 선언은 호출자 책임이며, ID/경계/label 비교가 실제 업무 의미의 동일성을 증명하지 않는다.
2. 유지 영역은 이미 입력의 소유가 정해져 있으므로 별도 mapping/newTextInput/제거로 덮어쓰지 않는다.
   제거된 이전 ID를 새 ID에 대응시키는 Revise 매핑은 가능하다.
   유지 ID의 입력을 다른 영역으로 옮기는 요구는 첫 Revise 범위 밖이며 Replace로 표현한다.
3. Replace에는 자동 유지가 없다. old.title과 new.title의 문자열/label/좌표가 같아도
   title → title을 명시하거나 이전 입력 제거 + 새 입력 제공을 각각 선택한다.
4. 이전 입력 하나는 유지/명시 mapping/명시 제거 중 정확히 하나로 처리한다.
   새 정의 하나는 유지/mapping/newTextInput 중 정확히 하나에서 입력을 받는다.
   같은 source를 두 번 쓰거나 같은 target에 두 입력을 넣지 않는다.
5. fromAreaId는 해당 제품의 이전 정의/입력, toAreaId와 newTextInputs.areaId는 제안한 정의에 있어야 한다.
   없는 영역·중복 source/target·서로 충돌한 선택은 진단한다. 다대일/일대다도 중복 대응으로 거부한다.
   자동 병합·분할·복제/줄바꿈 재해석 정책은 없다.
6. 이전 입력이 어디에도 대응되지 않으면 unresolvedSourceInput이다.
   삭제할 영역의 입력도 이 진단을 낸다. removedInputAreaIds에 (productId, 이전 areaId)별 선택이 있기 전에는 폐기하지 않는다.
   discardAllUnmapped 같은 포괄 플래그·label 기반 추정은 제공하지 않는 방안을 추천한다.
7. 새 정의에 입력이 없으면 기존 missingAreaInput 진단을 활용한다.
   후보 입력이 정의에 없거나 중복이면 기존 unknownInputAreaId/duplicateInputAreaId를 보존한다.
   모호한 mapping 때문에 만들 수 없었던 입력을 다시 ‘누락’으로 보고하지 않는다.
8. 전달된 직접 지정 한 줄/여러 줄을 그대로 보존한다.
   mapping 시 바뀔 수 있는 TextAreaInput 필드는 areaId뿐이며 원문·방식·순서 있는 줄 조각은 같아야 한다.
   재작성하지 않고 기존 불변 LineBreakInput을 공유할 수 있다.
9. 전달/유지 입력들은 이전 textInputs의 순서대로 배치한다.
   명시 제거된 항목만 빠지고 newTextInputs는 요청 순서대로 뒤에 붙이는 방안을 추천한다.
   변경 없는 경우 입력 인덱스도 유지한다. 제거 시 뒤 항목의 인덱스는 이동하되 상대 순서는 유지한다.
   새 도안의 정의 순서·mapping 목록 순서로 기존 입력을 재정렬하지 않는다.

제거 선택은 관련 원문을 영구히 복구할 수 있다는 보장이 아니다. 실제 반영 전까지 준비 객체의 baseline이 원문을 보존한다.
취소하면 baseline이 현재 구성이며 손실은 없다. 반영 후 실행 취소/이력 보존은 별도 책임이다.
문구만 고치는 동작·범용 편집기·불완전 원문 Builder를 이번에 추가하지 않는다.
TextAreaInput의 빈 원문/빈 줄/CRLF 지원 제한과 Unicode·공백 보존 계약은 그대로다.

## 5. 준비 결과와 반영 API 추천

아래 타입·필드는 전부 미구현 제안이다. 준비/반영 객체를 작업 파일 JSON으로 직렬화하지 않는다.

| 추천 타입/API | 필드 또는 입력/출력 | 책임 |
|---|---|---|
| ProductGeometryChangeRequest | ReviseAppliedGeometry(sourceAppliedGeometryId, proposedGeometry, targets) / ReplaceAppliedGeometry(proposedGeometry, targets) | 실제 불변 AppliedDesignGeometry와 고정 대상별 대응/제거 요청. 공용 원본 재조회 없음 |
| prepareProductGeometryChange | baseline: ProductDesignConfiguration, request → ProductGeometryChangePreparation | 입력 목록을 변경하지 않고 모든 독립 진단·영향 요약을 준비 |
| ReadyProductGeometryChange | baseline, request, summary. 유효 candidate는 private | 기준에서 반영 가능한 변경. 생성자는 비공개이며 외부 임의 생성/수정 경로 없음 |
| BlockedProductGeometryChange | baseline, request, issues, 판단 가능한 범위의 summary | 해결되지 않은 요청. 유효하지 않은 구성/임시 PDC를 소유하지 않음 |
| UnchangedProductGeometryChange | baseline, request, summary | 유효한 요청이나 전체 후보 값이 baseline과 같음. 오류의 대체 성공 아님 |
| ProductGeometryChangeSummary | 제품 ID, 이전/새 적용 ID, 유지·대응·추가·명시 제거한 영역 목록, 실제 변경 필드 경로 | before/after의 계산 가능한 투영. 원문 전체를 로그용 상세에 복제하지 않음 |
| applyPreparedProductGeometryChange | current: ProductDesignConfiguration, prepared: ReadyProductGeometryChange → ProductGeometryChangeApplication | 현재 기준 확인 후 Applied 또는 Rejected를 반환 |
| AppliedProductGeometryChange | configuration: ProductDesignConfiguration, summary | 성공한 새 구성 하나. 함수 자체가 앱 상태를 교체하지는 않음 |
| RejectedProductGeometryChange | issues | 오래된 제안 등의 정상 거부. 기존 current를 변경하지 않음 |

targetProductIds는 targets에서 유일하게 확정한 수정 불가 집합 뷰로 제공하고 별도 가변 정본을 만들지 않는다.
기준의 식별은 baseline의 실제 불변 값 + 각 제품/적용 ID다.
현재 PDC에는 configurationId/revision이 없으므로 가짜 토큰을 만들지 않는다.
요청·대응·요약·issues의 목록도 방어 복사한다.
반영 가능 여부는 Ready/Blocked/Unchanged에서 계산하며 canApply 플래그를 중복 저장하지 않는다.
Ready는 ‘그 baseline에 대해 유효’하다는 뜻이다. 현재에도 반영 가능하다는 보장은 apply 시점에 다시 확인한다.
UI의 미완료 제안 보관은 이 요청/준비 값의 수명이며 WorkSession 전체를 구현했다는 뜻이 아니다.

### 준비 절차

1. 유효한 baseline을 캡처하고 대상 집합·source·제안 스냅샷 ID 관계를 검사한다.
   입력 값 객체 자체는 현재 생성자가 검증한 값을 받는다.
2. 각 제품의 이전 도안/입력을 읽고 mapping/제거/신규 입력을 독립적으로 검사한다.
   같은 원인의 모호함은 last-wins로 해소하지 않는다. 다른 제품의 독립 진단은 계속 수집한다.
3. 대응이 유일하게 해석되는 제품에서는 기존 validateTextAreaInputs를 호출한다.
   입력 누락 등을 확인할 때는 받아들일 수 있는 입력 목록만 대조하고,
   원래 미대응 입력은 baseline/request에 계속 남겨 제거 선택을 요구한다.
   mapping 자체가 모호한 제품은 그 모호함에 종속된 영역 대조를 생략한다.
4. 이전/후 공통 ID 내용 불변과 비대상 보존을 검사한다.
   오류가 있으면 Blocked로 끝내며 어떤 ProductDesignConfiguration도 임시로 만들지 않는다.
5. 모든 대상이 해결되면 순서 보존된 새 제품/적용 목록을 만들고
   validateProductDesignConfiguration으로 구성 전체의 기존 정합성을 검사한다.
   목록 검사 단계에는 유효하지 않은 PDC 객체가 필요 없다.
6. issue가 없을 때만 현재의 검증 생성자로 전체 후보 PDC를 한 번 만든다.
   후보와 기준의 전체 값이 같으면 Unchanged, 다르면 Ready다.
   일부 대상만 성공한 새 구성을 반환하거나 반영하지 않는다.

하위 함수와 다른 검증 알고리즘을 복제하지 않는다. 같은 하위 issue를 준비 단계마다 중복 보고하지 않는다.
요청을 수정하면 기존 준비 값을 부분 편집하지 않고 baseline과 새 요청으로 다시 준비한다.
취소는 준비 결과를 폐기하는 것으로 충분하다. 별도 취소 명령/빈 성공 후보를 만들지 않는다.

### 기준 재확인과 명시적 반영

apply는 current의 실제 전체 값과 prepared.baseline을 구조적으로 대조한다.
제품/도안 ID뿐 아니라 원문·줄 방식·영역·단위·출처·목록 순서·미사용 스냅샷까지 포함한다.
비대상 제품만 바뀌었거나 제품이 하나 추가된 경우도 첫 계약에서는 staleBaseline으로 거부한다.
자동 재기반/병합을 하지 않으며 새 current로 다시 준비한다.

정확한 전체 값이 같으면 준비된 유효 후보를 새 구성으로 반환한다.
호출자는 자신이 소유한 최신 current를 넘기고, 같은 동기 실행 경계에서 반환 성공 값을 한 번 대입한다.
함수가 호출자에게 과거 구성을 ‘현재’라며 넘기는 행위를 감지하거나 다른 isolate의 동시 대입을 잠그지는 않는다.
검사 후 대입 사이에 await/재진입으로 상태가 달라질 수 있다면 앱 소유자가 그 경계를 직렬화해야 한다.

‘수정했다가 원래 값으로 되돌림’(A → B → A)은 값 모델만으로 구별할 수 없다.
현재와 baseline의 내용이 같으면 이 경우도 허용되는 한계가 있다.
구별하려면 앱/후속 세션이 세션 식별과 단조 증가 개정을 소유하고,
본문 전체 비교와 함께 같은 세션/개정인지 확인해야 한다. ID/해시만 비교하는 대체 방안이 아니다.
이번 요청에 revision:0 같은 가짜 필드나 전체 세션 모델을 추가하지 않는다.

Unchanged는 그 기준에서 새 ID 발급/목록 추가/반영이 필요 없다는 결과다. 현재 구성을 교체하지 않는다.
그 후 current가 바뀌었더라도 이전 baseline을 다시 대입하지 않는다. 최신 기준에서 무변경 여부가 필요하면 다시 준비한다.
단, 다른 새 ID를 명시하고 같은 내용을 연결한 요청은 참조 자체가 달라지므로 Unchanged가 아니다.
의도적으로 지정한 새 ID를 자동 병합/무시하지 않는다.
불완전한 Replace 대응을 ‘어차피 같음’이라며 Unchanged로 바꾸지도 않는다.

여기서 원자성은 한 메모리 구성의 전체 교체다.
파일 원자 저장·Drive 동기화·여러 사용자 잠금·내구성·DB 트랜잭션을 보장하지 않는다.

## 6. 영향과 보존 범위

| 대상/변경 | 현재 변경 계약의 보장 | 향후 계산/확인에 대한 제한 |
|---|---|---|
| 비대상 제품 | productId·적용 참조·입력 순서/원문/줄을 값 그대로 보존 | 실제 공동 계산 의존성이 있으면 결과 영향은 별도. 비대상이라고 결과 무효화가 절대 없다고 단정하지 않음 |
| 모든 기존 스냅샷 | 값·ID·순서를 보존. 공유 객체 제자리 변경 금지 | 현재 단일 구성의 참조 보존이 계산 그룹 동일성의 증거는 아님 |
| 대상의 외곽/관통/영역/제외 변경 | 새 스냅샷 ID, 승인된 입력 전달 | 해당 결과/확인과 이전·새 공동 계산 참여 영향 검토 필요 |
| 대상의 새 영역/삭제/명시 대응 | 입력의 사용처가 변했음을 요약 | 실제 입력 의존성이 바뀌면 이전 결과/확인 재사용 금지 |
| 원문/줄 | 유지/전달은 원문·직접 지정 상태/줄 순서를 보존. 새 입력만 호출자 제공 | 입력이 달라진 결과에 이전 작업자 확인 재사용 금지 |
| label/source만 변경 | ID 내용 불변 때문에 새 ID 필요 | 계산 무관 여부를 실제 요청 의존성으로 입증해야 재사용 가능 |
| 저장 단위 전체 환산 | 새 ID 필요, 전체 관련 길이를 환산한 유효 값 사용 | 물리적 형상 같음만으로 결과 재사용을 확정하지 않음. 수치/엔진 정규화 근거 필요 |
| 수량만 변경 | 이번 모델/요청에 수량 없음 | 기존 원칙상 문구 배치/확인 무효화 대상 아님. 수량 세부 정책은 미정 |
| 취소/Blocked/Rejected/Unchanged | 현재 구성이 그대로 | 변경이 반영되지 않았다는 이유 외의 가짜 계산/완료 상태 생성 없음 |

LayoutResult·OperatorReview·WorkSession이 현재 없으므로 위 표는 후속 영향 계약이다.
‘재사용 가능’ 결과/플래그나 새 확인 객체를 합성하지 않는다.
구조/참조 검증 성공은 포함·간섭·글자 충돌·배치 완료·제작·저장 가능 판정이 아니다.

## 7. 진단·실패 계약 추천

정상 변경 거부는 ProductGeometryChangeIssue 목록을 담은 Blocked/Rejected로 반환한다.
목록 순서는 계약이 아니며 외부 수정이 불가능해야 한다.
사용자의 미완료 대응/오래된 제안을 Exception이나 Error로 일괄 취급하지 않는다.
아래 새 코드/상세 이름은 구현 전 추천이다. 기존 GeometryErrorCode/TextInputErrorCode에 추가하지 않는다.

fieldPath는 request/baseline/candidate/current 중 어느 입력의 위치인지 포함하고 모든 인덱스는 0 기반이다.
첫 순수 비교 API는 자신의 매개변수 이름인 previous/next를 위치 접두로 사용한다.
아래 표의 r은 request.targets 인덱스, i는 baseline.products 인덱스, k는 제안 textAreas 인덱스다.
제품 ID·이전/제안 적용 ID를 구조화 상세에 제공하며 원문/전체 객체/전체 JSON을 오류 상세에 넣지 않는다.

| 추천 코드 | 발생 조건·위치 | 필수 상세와 호출자 대응 |
|---|---|---|
| invalidChangeIdentifier | 요청의 ID가 빈 문자열. request.targets[r].productId 등 | 필드 종류·실제 빈 값. 명시 ID를 다시 제공; trim으로 보정하지 않음 |
| emptyTargetSet | request.targets가 비었음 | 대상 수 0. 변경 대상 명시; 무변경 결과와 다름 |
| duplicateTargetProduct | 같은 제품을 targets에 중복 선언 | productId·첫/중복 요청 인덱스. 하나로 명시 선택 |
| unknownTargetProduct | 요청 제품이 baseline에 없음 | productId·요청 인덱스. 최신 기준에서 다시 선택 |
| unknownSourceAppliedGeometry | Revise의 source ID가 baseline에 없음. request.sourceAppliedGeometryId | source ID. 최신 기준에서 다시 지정 |
| unexpectedAppliedGeometry | Revise 대상이 다른 적용 ID를 참조. baseline.products[i].appliedGeometryId | productId·expected/actual 적용 ID. 대상 수정 또는 Replace 의도로 재준비 |
| snapshotContentConflict | 공통 ID의 내용이 다름. request.proposedGeometry | 적용 ID·기준 선언 위치·달라진 필드 경로 목록. 새 ID 사용 |
| unknownSourceArea / unknownTargetArea | mapping/제거가 존재하지 않는 이전 영역, mapping이 존재하지 않는 제안 영역을 가리킴 | productId·이전/제안 적용 ID·areaId·요청 항목 위치. 존재하는 영역을 명시 |
| duplicateSourceMapping / duplicateTargetMapping | 같은 from/to를 두 mapping에서 사용 | productId·해당 areaId·첫/중복 mapping 위치. 다대일/일대다도 거부 |
| conflictingInputDisposition | 유지/전달/제거의 중복, 또는 유지/mapping/신규 입력의 목표 중복. 해당 요청 항목 | productId·areaId·서로 충돌한 선택 종류/위치. 하나만 선택; 유지 영역 덮어쓰기 금지 |
| unresolvedSourceInput | 이전 입력에 유지/mapping/명시 제거가 없음. baseline.products[i].textInputs[j].areaId | productId·이전 적용 ID·areaId·입력 인덱스. mapping 또는 개별 제거 선택 |
| areaInputMismatch | 유일하게 해석되는 입력 투영이 제안 정의와 불일치 | productId·이전/제안 ID·원래 DesignValidationIssue(코드/경로/상세) 보존. 부족/잘못된 입력 해결 |
| candidateConfigurationInvalid | 해석 가능한 후보 목록에 기존 구성 검증 issue가 있음 | 원래 ProductDesignIssue(하위 원인 포함)와 candidate 경로. 요청을 다시 준비 |
| staleBaseline | apply의 current 전체 값이 기준과 다름. current | 현재/기준의 달라진 필드 경로와 관련 ID. 현재 구성으로 재준비; 원문 값을 진단에 복사하지 않음 |

unknownSourceArea/unknownTargetArea의 ‘없는’은 해당 문맥의 실제 정의/입력에 존재하지 않는다는 뜻이다.
요청의 중복 제거 ID도 conflictingInputDisposition으로 보고한다.
신규 입력의 미정의/중복 areaId는 기존 unknownInputAreaId/duplicateInputAreaId를 areaInputMismatch로 전달한다.
같은 신규 입력에 unknownTargetArea를 다시 추가하지 않는다. unknownTargetArea는 mapping의 toAreaId 검사다.
빈 ID에서는 해당 식별 진단만 내고 그 값에 종속된 미존재 진단을 덧붙이지 않는다.
중복 대상 제품은 어느 요청 항목도 first/last-wins로 채택하지 않고 그 제품의 종속 대조를 생략한다.
없는 이전 적용 참조나 모호한 mapping에서도 그에 종속된 누락을 만들지 않되 다른 제품/독립 항목은 계속 검사한다.
입력 누락의 areaInputMismatch는 request.proposedGeometry.geometry.textAreas[k].areaId를 가리킨다.
후보 입력 오류는 candidate.products[i].textInputs[j].areaId를 가리키되,
목록 투영이 아직 없는 단계면 request.targets[r].newTextInputs[j].areaId 등 실제 존재하는 요청 위치를 사용한다.
투영 전/후 인덱스를 혼용하거나 products[i].textAreas 같은 없는 경로를 만들지 않는다.
원래 하위 issue의 상대 경로/상세는 바꾸지 않고 상위 위치와 함께 제공한다.

추가 진단은 작은 구체 타입을 추천한다: TargetSelectionDetails, SnapshotContentConflictDetails,
AreaMappingConflictDetails, UnresolvedInputDetails, AreaInputChangeDetails, StaleConfigurationDetails.
모든 오류를 하나의 nullable 필드 집합이나 임의 Map으로 몰지 않는다.
코드별 허용 상세/필수 관련 ID/인덱스와 경로를 런타임 검사하며 assert에 의존하지 않는다.
단, 진단 생성자가 외부 이력을 재조회하여 모든 사실을 증명하는 것은 아니다.

### 예외와 내부 결함

- 잘못된 기하/문구 값을 만들려는 생성·JSON 오류는 현재의 전용 예외 계약 그대로다.
  이 요청 API는 이미 생성된 값들을 받으며 임의 JSON 파서를 새로 만들지 않는다.
  하위 예외를 정상 변경 거부로 잡아 숨기거나 메시지를 파싱하지 않는다.
- Blocked를 apply에 넘기려는 API 오용은 타입으로 막는다. Ready의 비공개 생성자/불변 필드로 임의 후보 변조를 막는다.
  공개 진단 생성의 잘못된 코드·상세 조합은 ArgumentError, 내부 불가능 상태는 StateError 등 코드 결함이다.
  이들을 일반 issue·null·빈 구성·성공으로 바꾸지 않는다.
- 같은 예외는 rethrow, 실제 문맥 변환이 필요하면 원인 객체·하위 상세·최초 스택을 보존한다.
  준비 함수마다 반복 포장하거나 Logger를 추가하지 않는다.
- UI 문구/선택 확인/정상 취소 표시/로그 레벨과 기록은 앱 경계 책임이다.
  정상 입력 거부를 자동 SEVERE로 기록하지 않는다. 자세한 기준은 [예외·진단 계약](failure-diagnostics-logging.md)을 따른다.

## 8. 관계 예시와 사례 대조

아래 JSON은 현재 값 모델을 사용한 관계 검토 자료이며 새 작업 파일 스키마·실제 실행 결과가 아니다.
명판을 원형으로 제한하는 정책도 아니다. 수량·제작 조건·결과·확인·저장 상태는 넣지 않았다.

### 기준: 두 제품이 g-1 공유

~~~json
{
  "appliedGeometries": [
    {
      "appliedGeometryId": "g-1",
      "geometry": {
        "coordinateSpace": {
          "lengthUnit": "millimeter"
        },
        "outline": {
          "kind": "circle",
          "center": {
            "x": 0,
            "y": 0
          },
          "radius": 30
        },
        "cutouts": [],
        "textAreas": [
          {
            "areaId": "title",
            "label": "",
            "region": {
              "outer": {
                "kind": "circle",
                "center": {
                  "x": 0,
                  "y": 0
                },
                "radius": 10
              },
              "exclusions": []
            }
          }
        ]
      },
      "source": {
        "sourceDesignId": "catalog-42",
        "sourceRevision": "r7"
      }
    }
  ],
  "products": [
    {
      "productId": "p-a",
      "appliedGeometryId": "g-1",
      "textInputs": [
        {
          "areaId": "title",
          "sourceText": " PUMP  A ",
          "lineBreak": {
            "mode": "specified",
            "lines": [
              " PUMP  A "
            ]
          }
        }
      ]
    },
    {
      "productId": "p-b",
      "appliedGeometryId": "g-1",
      "textInputs": [
        {
          "areaId": "title",
          "sourceText": "밸브 é 😀",
          "lineBreak": {
            "mode": "specified",
            "lines": [
              "밸브 ",
              "é 😀"
            ]
          }
        }
      ]
    }
  ]
}
~~~

### p-a만 Revise한 후보: g-1 보존, g-2 추가

~~~json
{
  "appliedGeometries": [
    {
      "appliedGeometryId": "g-1",
      "geometry": {
        "coordinateSpace": {
          "lengthUnit": "millimeter"
        },
        "outline": {
          "kind": "circle",
          "center": {
            "x": 0,
            "y": 0
          },
          "radius": 30
        },
        "cutouts": [],
        "textAreas": [
          {
            "areaId": "title",
            "label": "",
            "region": {
              "outer": {
                "kind": "circle",
                "center": {
                  "x": 0,
                  "y": 0
                },
                "radius": 10
              },
              "exclusions": []
            }
          }
        ]
      },
      "source": {
        "sourceDesignId": "catalog-42",
        "sourceRevision": "r7"
      }
    },
    {
      "appliedGeometryId": "g-2",
      "geometry": {
        "coordinateSpace": {
          "lengthUnit": "millimeter"
        },
        "outline": {
          "kind": "circle",
          "center": {
            "x": 0,
            "y": 0
          },
          "radius": 40
        },
        "cutouts": [],
        "textAreas": [
          {
            "areaId": "title",
            "label": "",
            "region": {
              "outer": {
                "kind": "circle",
                "center": {
                  "x": 0,
                  "y": 0
                },
                "radius": 10
              },
              "exclusions": []
            }
          }
        ]
      },
      "source": {
        "sourceDesignId": "catalog-42",
        "sourceRevision": "r7"
      }
    }
  ],
  "products": [
    {
      "productId": "p-a",
      "appliedGeometryId": "g-2",
      "textInputs": [
        {
          "areaId": "title",
          "sourceText": " PUMP  A ",
          "lineBreak": {
            "mode": "specified",
            "lines": [
              " PUMP  A "
            ]
          }
        }
      ]
    },
    {
      "productId": "p-b",
      "appliedGeometryId": "g-1",
      "textInputs": [
        {
          "areaId": "title",
          "sourceText": "밸브 é 😀",
          "lineBreak": {
            "mode": "specified",
            "lines": [
              "밸브 ",
              "é 😀"
            ]
          }
        }
      ]
    }
  ]
}
~~~

g-2는 외곽 반지름만 30 → 40으로 달라졌다. title은 같은 업무 영역으로 유지하며 자동 비례 확대하지 않는다.
출처 catalog-42/r7은 파생 출발점 기록으로 남는다. 새 외곽이 그 공용 원본과 동일하다는 보장이 아니다.
p-b의 참조/원문/지정 두 줄과 p-a의 앞뒤/연속 공백·지정 한 줄을 그대로 보존한다.
p-b의 é는 e + 결합 악센트다. Unicode 정규화하지 않는다.

### 같은 영역 ID를 가진 다른 도안으로 Replace

별도 실제 스냅샷 g-3에 title 영역이 있다고 하자. 공용 원본/내용은 제안 스냅샷이 실제 값으로 제공하며
아래 대상 항목은 그 스냅샷을 대체하는 파일 포인터가 아니다.
제안한 targets 항목은 다음처럼 identity mapping도 명시한다.

~~~json
{
  "productId": "p-a",
  "areaMappings": [
    {
      "fromAreaId": "title",
      "toAreaId": "title"
    }
  ],
  "newTextInputs": [],
  "removedInputAreaIds": []
}
~~~

이 mapping은 title 입력의 원문/지정 줄을 새 도안의 title에 전달하겠다는 명시적 선택이다.
g-3과 g-1의 areaId/label이 같다는 사실만으로 위 mapping을 생략하면 Blocked다.

| 사례 | 요청/전후 관계 | 준비·반영 결과 |
|---|---|---|
| 공유 도안 한 제품 수정 | 위 B → C, targets={p-a}, g-1 → g-2 | Ready. p-b와 g-1 값 유지, 명시 apply 후 C 반환 |
| 명시 복수 대상에 같은 수정 | B 기준 targets={p-a,p-b}, 제안 g-2 | 둘 다 g-2 하나 공유, 입력은 각 제품 값 그대로. 기존 g-1 유지 |
| 같은 ID 내용 바꿔치기 | 제안 ID g-1의 radius만 40 | snapshotContentConflict. g-1의 출처/label/단위만 바뀌어도 동일 |
| 같은 areaId의 다른 도안 | g-3.title로 Replace, mapping=[] | unresolvedSourceInput와 독립 missingAreaInput. 자동 identity 대응 없음 |
| 같은 areaId 명시 대응 | g-3.title, title → title 명시 | 전달 입력의 areaId만 지정하며 원문/줄 그대로. 다른 제약 없으면 Ready |
| 새 영역 입력 누락 | Revise에 code 정의 추가, newTextInputs=[] | code의 missingAreaInput 원인 보존. 빈 원문 자동 생성 없음 |
| 기존 영역 제거 | 제안에서 title 삭제, 제거 선택 없음 | unresolvedSourceInput. removedInputAreaIds=[title]를 제품별 명시해야 함 |
| 영역 제거 명시 선택 | 위 요청에서 제거 선택, 새 정의 0개/입력 0개 | 유효 구성 후보 가능. 제작/저장 가능의 뜻은 아님 |
| 대응 중복/다대일/일대다 | from 또는 to를 두 번 사용 | duplicateSourceMapping/duplicateTargetMapping. 부분 선택/병합 없음 |
| mapping과 제거 동시 선택 | 같은 이전 title을 mapping하고 제거 | conflictingInputDisposition. 먼저 온 선택을 채택하지 않음 |
| 일괄 중 p-b 입력 부족 | p-a 대응 완료, p-b의 새 영역 입력 미제공 | Blocked. p-a만 성공한 구성 반환/자동 반영 금지 |
| 준비 후 대상/원문/기준 변경 | current에 대상 삭제·입력 수정·새 제품 추가 등 | staleBaseline. 비대상 변경도 재준비 |
| 준비 후 A → B → A | 값 전체가 다시 같음 | 첫 값 계약으로 구분 불가·허용. 금지하려면 세션/개정 추가 결정 |
| 취소 | Ready/Blocked를 버리고 apply하지 않음 | B 유지. 후보 스냅샷도 현재 구성에 추가하지 않음 |
| 실제 변경 없음 | Revise의 제안이 기존 g-1과 같고 모든 입력 선택도 동일 | Unchanged. 새 ID/새 구성 반영 불필요 |
| 내용은 같고 새 ID 지정 | 실제 내용 같은 g-4를 명시해 참조 변경 | Ready. 자동 합치지 않음 |
| 물리적 크기 같은 단위 환산 | g-1을 전체 inch로 환산한 새 스냅샷 | 새 ID 필요. 결과 재사용 판단 미제공 |

이 표의 모든 성공은 값/참조 후보가 유효하다는 뜻이며 실제 배치·제작·저장 성공이 아니다.

## 9. 파일·검증 기준과 다음 최소 구현

첫 변경 API를 구현할 때의 책임별 구성 추천:

~~~text
lib/src/product/product_geometry_change_request.dart
  sealed 변경 의도와 제품별 입력 대응/명시 제거 요청
lib/src/product/product_geometry_change.dart
  준비/반영 함수와 그 sealed 결과, 비공개 Ready 후보
lib/src/product/product_geometry_change_errors.dart
  실제 구현하는 코드와 작은 진단 상세
test/product/product_geometry_change_preparation_test.dart
test/product/product_geometry_change_application_test.dart
test/product/product_geometry_change_diagnostics_test.dart
~~~

sealed 하위 타입과 비공개 후보 접근은 같은 Dart library에 둔다.
오류 파일은 별도 library이며 진단용 공개 타입만 명시 export한다.
private 접근을 위해 모든 파일을 part로 묶거나 공통 command/transaction 프레임워크를 만들지 않는다.
불변 요청/결과의 필요한 반복 코드는 기존 Freezed 구성을 검토하고,
Ready 생성/수정 경로가 검증을 우회하지 않도록 copyWith/JSON 복원을 열지 않는다.
현재 확정 공개 이름을 임의로 바꾸거나 호환 별칭을 만들지 않는다.

### 검토 후 첫 구현 범위 하나

추천은 validateAppliedGeometryIdConsistency(previous:, next:)라는 순수 비교 함수다.
두 유효 ProductDesignConfiguration에서 공통 appliedGeometryId의 전체 내용이 같은지 확인하고
수정 불가 conflict 진단만 반환한다. 이름 후보 SnapshotContinuity는 전체 이력까지 보장하는 것으로 읽힐 수 있다.
이 함수는 현재 구성 검증과 별개인 ‘변경 전후 ID ↔ 내용’ 책임만 가진다.

충돌 위치는 next.appliedGeometries[k]이며 상세에 appliedGeometryId, previous/next의 선언 인덱스와 변경 필드 경로를 제공한다.
공통 ID가 없거나 내용이 같으면 빈 진단 목록이다. 그 결과가 전체 변경/배치/저장 허용이라는 뜻은 아니다.

첫 구현은 geometry/source 전체·목록 순서·단위 환산·sourceRevision 변화,
다른 ID의 동일 내용 허용·공통 ID 없음·입력/비대상 원본 불변성을 확인한다.
새로운/제거된 ID는 충돌 자체로 보지 않으며 과거 제거 ID 재사용 추적을 주장하지 않는다.
요청/준비/반영·영역 매핑·세션 개정·정리·결과 무효화는 이 첫 구현에 끼워 넣지 않는다.
실제로 쓰는 conflict 코드/상세만 만들며 이 문서의 나머지 미구현 코드를 enum에 미리 채우지 않는다.

이후 전체 준비/반영 구현 검토 시 아래 사례가 잘못된 구현을 막아야 한다.
- 새 ID만 붙인 뒤 공유 객체를 변경해 baseline/비대상도 달라지는 경로 거부.
- label/문구/좌표/동일 문자열 ID로 Replace의 mapping을 추정하는 경로 거부.
- 원문 공백·기호·대소문자·Unicode·직접 지정 한 줄/여러 줄과 상대 순서 보존.
- source/단위/영역 목록 순서만 바꾼 같은 ID 충돌, 동일 객체가 아닌 동등한 값의 허용.
- 일괄 중 한 제품 실패/취소/오래된 제안에서 현재 값이 전혀 달라지지 않음.
- 원문/스택을 오류 문자열에서 복구하지 않고 코드·위치·작은 상세로 처리.

## 10. 확정 원칙·추천·남은 결정

| 상태 | 항목 |
|---|---|
| 사용자 요구로 확정 | 명시 대상 집합·불변 공유/개별 분리·공통 ID 전체 내용 불변·원문/줄 보존·다른 도안의 명시 대응·부분 자동 반영 금지 |
| 이번 추천 | Revise/Replace 타입 분리, Revise는 단일 기존 적용 ID 대상, 제품별 개별 제거 목록, 기존 입력 상대 순서 + 신규 입력 뒤 추가 |
| 이번 추천 | 기존 스냅샷 유지/새 ID 뒤 추가, 전체 기준 값 비교로 stale 거부, private Ready 후보, 유효 무변경 별도 결과 |
| 검토 필요 | 추천 API/코드 이름과 결과 타입의 최종 채택, 빈 대상 거부·제거 확인 방식·신규 입력 추가 순서 정책 |
| 추가 사용자 결정 필요 | A → B → A도 거부할 세션/개정 책임을 첫 변경 API 전에 도입할지. 첫 값 계약은 이를 구분하지 못함 |
| 후속 책임 | 제거 ID의 역사적 재사용/실행 취소·미사용 스냅샷 정리 수명·계산 의존성/결과 재사용·제작 조건 확장 |
| 범위 밖 | 전체 이력 저장소·범용 변경 프레임워크·DB·파일/Drive 원자성·동기화/잠금·UI·엔진·DXF |

## 11. 설계 작성 당시 문서 검사와 실행 범위

JSON 블록과 사례 표는 문서용 관계 대조 대상이다.
참조 ID·정의/입력 대응·지정 줄 연결·원문 코드 단위·공통 ID의 기존 내용·비대상 보존을 검사한다.
이 검사는 새 Dart API를 구현/실행한 시험이나 배치·제작 판정이 아니다.
사용자 지정에 따라 Dart 생성·분석·테스트·AOT·pub get은 실행하지 않는다.
코드·테스트·생성 파일·SDK·의존성·형제 앱·스테이징은 변경하지 않는다.


실제 문서 검사: Node로 JSON 블록 3개를 파싱하고 참조/원문/단일·복수 지정 줄/공통 ID/비대상 보존과
표의 변경 사례에 대한 구조 대조를 확인했다. 문서용 보조 검사 79개와 수정 문서 6개의 로컬 링크 74개가 통과했다.
이 수치를 제품 테스트 개수로 취급하지 않는다. git diff --check를 통과했으며 문서 외 변경/스테이징은 없다.
Dart 명령과 형제 앱 변경·커밋·푸시·스테이징은 수행하지 않았다.


## 12. 공통 적용 ID 내용 불변 검증 — 현재 구현

### 실제 공개 API와 책임

- validateAppliedGeometryIdConsistency(previous:, next:) → `List<AppliedGeometryIdConflict>`.
  입력은 현재 생성자가 검증한 유효 ProductDesignConfiguration 두 개다.
- 정상 충돌은 수정 불가 목록으로 반환한다. AppliedGeometryIdConflictCode.snapshotContentConflict만 구현했다.
- 진단 필드는 appliedGeometryId/previousIndex/nextIndex/fieldPath/changedFieldPaths/code다.
  선언 인덱스는 각 구성의 appliedGeometries에서 0 기반이다.
- 한 구성의 값/참조 오류가 아니라 두 구성 사이의 내용 불변 문제이므로 기존 ProductDesignErrorCode와 분리했다.

함수 파일은 lib/src/product/applied_geometry_id_consistency.dart, 진단은 applied_geometry_id_conflict.dart다.
공개 진입점은 lib/r_edit_workflow.dart다. 실제 사용하는 충돌 한 종류만 구현했으며 미래 enum 항목은 없다.
진단은 기존 오류처럼 작은 읽기 전용 타입이다. JSON 복원/값 편집 모델이 아니므로 copyWith/JSON API를 만들지 않았다.
임의 객체 diff·JSON 비교·새 의존성·로깅은 추가하지 않았다.

공통 ID를 연결한 뒤 기존 AppliedDesignGeometry 전체 값 동등성으로 비교한다.
구성의 적용 목록 재정렬은 충돌이 아니며, 스냅샷 내부 목록의 순서는 내용이다.
제품 목록/원문/줄 입력은 검사/변경하지 않는다. 참조 동일성·ID/hashCode·JSON 문자열·출처만으로 내용을 판정하지 않는다.

### 변경 경로의 기준

fieldPath는 next.appliedGeometries[k]다. changedFieldPaths는 그 스냅샷 값 기준의 상대 Dart 필드 경로다.
예를 들어 geometry.outline.radius를 연결하면 next.appliedGeometries[k].geometry.outline.radius다.
목록의 실제 인덱스와 존재하는 필드만 따라가며 JSON 선택 키의 출력 유무와 구분한다.

| 상황 | 상대 경로 |
|---|---|
| 같은 종류의 수치/문자열/ID 변경 | geometry.outline.center.x / geometry.cutouts[0].cutoutId / geometry.textAreas[0].label 등 |
| 같은 종류의 경로/원호 변경 | ...path.start.x / ...path.segments[0].end.x / ...path.segments[0].bulge |
| 목록 길이 변경 | geometry.cutouts / geometry.textAreas / ...exclusions / ...segments처럼 목록 전체 |
| 길이 같은 내부 목록 재정렬 | 같은 인덱스끼리 비교한 실제 변경 필드. 내부 목록을 ID로 정렬하지 않음 |
| circle↔path 또는 line↔arc | 경계/구간 전체. geometry.outline / ...segments[0] |
| source 유무 변경 | source. 존재하지 않는 하위 필드를 나열하지 않음 |
| source 둘 다 있음 | source.sourceDesignId / source.sourceRevision의 실제 차이 |

길이가 바뀌면 기존 항목의 변경도 그 목록 전체 경로가 포괄하며 개별 추가/삭제 인덱스를 덧붙이지 않는다.
종류가 바뀌면 없는 radius/bulge가 있다고 보고하지 않는다.
sourceRevision은 nullable Dart 필드다. 충돌 목록과 변경 경로 목록의 순서는 공개 계약이 아니다.

### 진단의 런타임 조건

code는 고정 getter이므로 다른 코드/상세 조합을 전달할 수 없다.
생성자는 빈 ID·음수 선언 인덱스·빈/중복 경로·현재 스냅샷 필드 문법 밖의 경로를 ArgumentError로 거부한다.
ID는 trim/정규화하지 않고 경로 목록을 방어 복사한다. fieldPath는 nextIndex에서 계산한다.
전체 스냅샷을 보관하지 않으므로 외부에서 직접 만든 진단이 실제 자료와 맞는지,
목록 인덱스가 그 자료의 범위 안인지까지 생성자가 증명하지 않는다.
검증 함수는 실제 타입을 따라 현재 존재하는 위치를 생성한다.
값 동등성과 경로 수집이 어긋나는 새 필드 처리 누락 등의 코드 결함은 StateError로 드러내며 정상 충돌로 숨기지 않는다.
원문/전체 JSON/스냅샷은 진단에 복제하지 않는다.

소비자는 아래처럼 공개 필드를 처리한다. 실행 가능한 소비자 검증 예제는 example/product_configuration.dart다.

~~~dart
final conflicts = validateAppliedGeometryIdConsistency(
  previous: previousConfiguration,
  next: nextConfiguration,
);
for (final conflict in conflicts) {
  final code = conflict.code;
  final appliedId = conflict.appliedGeometryId;
  final oldIndex = conflict.previousIndex;
  final newIndex = conflict.nextIndex;
  final ownerPath = conflict.fieldPath;
  final changedFields = conflict.changedFieldPaths;
  // 앱 경계에서 변경을 거부하고 새 ID를 요구한다. 메시지를 파싱하지 않는다.
}
~~~

### 검사 범위의 한계

두 구성은 각각 유효해도 같은 ID의 내용이 다를 수 있다.
PDC 생성/JSON 복원에 이 함수를 자동 삽입하지 않았다. 전후 두 값을 호출자가 명시적으로 전달해야 한다.
새 ID/제거 ID/공통 ID 없음/다른 ID의 동일 내용은 충돌이 아니며 자동 병합도 하지 않는다.
전체 단위 환산은 실제 크기가 같아도 저장 단위/수치가 달라져 같은 ID이면 충돌이다.
임의 반올림·허용오차·물리적 동등성 판정은 추가하지 않았다.

빈 진단은 공통 ID 내용 충돌이 없다는 뜻일 뿐 전체 변경 허용이 아니다.
제거된 ID의 역사적 재사용·A→B→A·제품 보존·영역 대응·안전 반영·배치/제작/저장은 보장하지 않는다.
실제 준비/반영에는 기준 구성 재확인과 별도 세션/개정 검사가 필요하다.
API 오용/내부 결함을 잡아 빈 진단으로 바꾸지 않는다.

### 실제 검증 (2026-10-27)

새 책임별 테스트 단독 실행: 내용 비교 41개·진단 13개 성공.
명시적 코드 생성 후 전체 verify: 시작 생성 일치·반복 안정성·포맷·분석(No issues)·501개 테스트 성공.
assert 비활성 AOT 7개와 생성기 없는 독립 소비자의 공개 API 사용·컴파일·실행도 성공했다.
기존 원문/줄바꿈·JSON·기하·참조 테스트를 유지했고 새 검사는 실제 모델로 기대 코드/경로/인덱스를 대조한다.
SDK·의존성·CI·앱·로깅은 변경하지 않았다. 원격 CI/다른 OS는 실행하지 않았다.
스테이징·커밋·푸시와 미구현 변경 기능은 수행하지 않았다.

### 생성자 인자 진단 보완 (2026-10-28)

AppliedGeometryIdConflict의 허용 조건·공개 충돌 필드·비교 알고리즘은 유지했다.
생성자의 API 오용은 ArgumentError.value로 구분하고 name/invalidValue/message를 제공한다.

| 위반 | name | invalidValue | 조건 설명 |
|---|---|---|---|
| 빈 ID | appliedGeometryId | 전달한 빈 문자열 | ID는 빈 문자열일 수 없음 |
| 음수 이전 선언 위치 | previousIndex | 전달한 음수 | 이전 인덱스는 0 이상 |
| 음수 다음 선언 위치 | nextIndex | 전달한 음수 | 다음 인덱스는 0 이상 |
| 빈 경로 목록 | changedFieldPaths | 빈 목록 | 경로가 하나 이상 필요 |
| 중복 경로 | changedFieldPaths[i] | 해당 경로 문자열 | 중복임과 첫 등장 위치 changedFieldPaths[j] |
| 잘못된 경로 문법 | changedFieldPaths[i] | 해당 경로 문자열 | 현재 스냅샷 필드 경로 문법 준수 |

항목 위치는 전달된 목록의 0 기반이다. 비어 있지 않은 전체 목록은 오류 값/메시지에 넣지 않는다.
여러 인자/항목이 잘못된 경우 어떤 위반을 먼저 보고할지는 공개 계약이 아니다.
테스트는 단일 위반별 name/invalidValue와 의미 있는 조건 설명을 대조하며 전체 문장을 고정하지 않는다.
이 설명은 개발자 진단이며 사용자 화면의 확정 문구가 아니다.

이번 보완의 실제 검사: 인자 진단 14개·내용 비교 41개 단독 성공, 전체 verify의 502개 테스트·생성 일치/반복 안정성·분석 성공.
assert 비활성 AOT 7개와 생성기 없는 소비자도 통과했으며 적용 ID AOT는 name/invalidValue/조건 설명까지 확인한다.
비교 알고리즘·공개 필드·허용 조건·SDK·의존성은 유지했다. 원격 CI/다른 OS는 실행하지 않았다.

## 13. 요청·영역 입력 대응·전체 후보 준비 구현 (2026-10-28)

현행 구현은 요청 → 영역 선택 검증 → 전체 후보 준비까지다.
1–11절은 설계 당시 기록이며 최종 apply/세션·개정 부분은 여전히 제안이다.
12절의 공통 ID 비교는 유지하며 요청/준비에는 JSON 저장 API가 없다.

### 공개 API와 파일 책임

| 파일 (lib/src/product/) | 현행 책임 |
|---|---|
| product_geometry_change_request.dart | sealed ProductGeometryChangeRequest, ReviseAppliedGeometry, ReplaceAppliedGeometry와 Freezed 값 비교/수정 |
| product_geometry_target.dart | 제품별 명시 targets의 areaMappings/newTextInputs/removedInputAreaIds 방어 복사 |
| text_area_input_mapping.dart | fromAreaId/toAreaId의 명시 일대일 전달 값 |
| text_area_input_change_preparation.dart | 내부 입력 투영·선택 충돌·하위 영역 진단 수집. 공개 진입점에서는 노출하지 않음 |
| product_geometry_change_preparation.dart | prepareProductGeometryChange, 전체 후보 목록 검증/생성 |
| product_geometry_change_result.dart | 같은 library의 part. Ready/Blocked/Unchanged 비공개 생성자·비공개 후보 |
| product_geometry_change_summary.dart | 제품별 참조·유지/대응/신규/제거·결과 입력 ID 순서·내용 변경 경로의 불변 요약 |
| product_geometry_change_errors.dart | 전용 코드·작은 상세 타입·진단 생성자의 런타임 방어 |

sealing과 비공개 후보 접근을 위해 결과만 준비 library의 part로 둔다.
다른 책임 파일 전체를 part로 묶지 않았다.
불변 요청/대응/요약 반복 코드는 Freezed, 준비 함수의 반환값 의도는 meta @useResult로 표현한다.
새 의존성·JSON 스키마·앱 상태·로그 발생 지점은 없다.

### 준비와 보존의 현행 규칙

- 대상은 request.targets의 productId로 고정한다. 빈 대상/빈 ID/없는 제품/중복 대상은 Blocked다.
  중복 제품의 모든 요청 항목을 종속 처리에서 제외하며 first/last-wins가 없다.
- Revise의 source는 기준에 존재하고 각 대상이 참조해야 한다.
  이전/제안 양쪽 areaId는 동일 업무 영역이라는 호출자의 선언으로 유지한다.
  유지 원문·줄·입력 상대 순서는 바꾸지 않으며 mapping/제거/신규 공급으로 덮어쓰면 거부한다.
- Replace에는 자동 유지가 없다. 같은 문자열도 이전 입력 처리와 새 영역 공급을 명시해야 한다.
- 모든 이전 입력은 유지/대응/개별 제거 중 정확히 하나, 새 정의는 유지/대응/신규 공급 중 정확히 하나다.
  입력은 이전 상대 순서로 전달하고 신규 입력만 요청 순서로 뒤에 붙인다.
  mapping은 areaId만 교체하며 원문/Unicode/지정 한 줄·여러 줄을 보존한다.
- 동일 종류 선택의 중복과 서로 다른 종류의 충돌을 구분한다.
  모호한 공급이 이미 지목한 새 영역에는 종속 missingAreaInput을 추가하지 않는다.
  같은 제품의 다른 미공급 영역/미대응 입력 및 다른 제품의 독립 오류는 계속 수집한다.
  미정의/중복 신규 입력은 기존 validateTextAreaInputs 진단을 한 번만 전달한다.
- 모든 기존 스냅샷 값/순서와 비대상 제품/제품 순서를 유지한다.
  새 제안 ID는 하나만 뒤에 추가하고 같은 ID·전체 내용은 기존 슬롯을 재사용한다.
  같은 ID·다른 내용은 거부하며 다른 ID의 동일 내용을 병합하지 않는다. 미사용 이전 스냅샷도 보존한다.
- 기존 내용 비교의 내부 경로 수집 책임만 공유했다. 무효한 임시 PDC로 기존 비교 API를 호출하지 않는다.
- 독립 진단이 있으면 Blocked이며 부분 후보 구성을 반환하지 않는다.
  문제가 없는 전체 목록에 validateProductDesignConfiguration을 호출한 뒤 검증 생성자로 후보를 만든다.
  후보 전체 값이 baseline과 같을 때만 Unchanged, 다르면 Ready다.

### 결과와 요약

세 결과 모두 baseline/request/summary를 제공한다. targetProductIds는 원래 명시 ID의 수정 불가 집합 뷰다.
ReadyProductGeometryChange는 비공개 생성자와 비공개 _candidate만 가지며 candidate getter/copyWith/JSON API가 없다.
후보를 읽기 위해 테스트용 공개 API를 추가하지 않았다.
원문 보존은 실제 준비가 쓰는 내부 입력 투영 책임을 테스트하고, 공개 결과는 타입·요약·기준 불변성을 검증한다.
Blocked의 요약은 유일하게 해석된 제품만 포함하므로 부분적이며, 해당 일부가 반영되었다는 뜻이 아니다.
Unchanged도 유효한 요청에 한정된다. 불완전한 Replace를 값이 비슷하다는 이유로 무변경 처리하지 않는다.

ProductGeometryTargetSummary는 productId, previousAppliedGeometryId, proposedAppliedGeometryId,
retainedAreaIds, areaMappings, newInputAreaIds, removedInputAreaIds, resultingInputAreaIds, changedFieldPaths를 제공한다.
제품 요약은 baseline 제품 순서이며 영역 처리는 실제 입력 상대 순서/신규 요청 순서다.
changedFieldPaths는 이전/제안 스냅샷의 내용 경로이며 적용 ID 변경은 두 ID 필드로 구분한다.
원문·전체 JSON·형상 덤프가 아니며 로그에 자동 기록하지 않는다.

### 진단 위치와 처리

전용 ProductGeometryChangeCode의 각 항목은 발생 조건·호출자 대응을 한국어 API 설명에 명시한다.
ProductGeometryChangeIssue는 code/fieldPath/details가 필수이며 코드별 허용 상세·위치 문법·문맥을 런타임 검사한다.
진단 API 오용은 ArgumentError.value다. 업무 함수에서 Error를 잡아 Blocked로 바꾸지 않는다.
인덱스는 0 기반이며 독립 issue 순서는 계약이 아니다.

| 진단 위치 | 의미 |
|---|---|
| request.targets[r].productId | 없는/빈/중복 명시 대상 |
| request.sourceAppliedGeometryId | 부분 수정의 없는/빈 기준 |
| baseline.products[i].appliedGeometryId | Revise 기대 참조와 실제 참조의 차이 |
| request.proposedGeometry | 같은 ID의 내용 충돌. baselineIndex와 실제 변경 필드 경로 보존 |
| request.targets[r].areaMappings[j].fromAreaId / toAreaId | 이전/새 영역 문맥의 미존재·중복·유지/공급 충돌 |
| request.targets[r].removedInputAreaIds[j] | 개별 제거의 미존재·중복·유지 충돌 |
| baseline.products[i].textInputs[j].areaId | 처리 선택이 없는 이전 입력 |
| request.targets[r].newTextInputs[j].areaId | 신규 입력의 기존 연결 진단 |
| request.proposedGeometry.geometry.textAreas[k].areaId | 독립적으로 공급이 없는 새 정의 |
| candidate 다음의 실제 구성 경로 | 전체 목록 검증의 원래 ProductDesignIssue |

ChangeAreaSelectionDetails는 제품/양쪽 적용 ID·areaId·source/target 문맥·선택 위치 목록을 제공한다.
ChangeAreaInputDetails는 원래 DesignValidationIssue 객체/코드/상대 경로/상세를 보존한다.
ChangeConfigurationDetails도 원래 ProductDesignIssue를 보존한다.
선택 상세·스냅샷 변경 경로·issue/요약 목록은 외부 수정이 불가능하다.
상세에 원문/전체 요청·구성/JSON을 복제하지 않는다.

예: 중복 대응은 duplicateSourceMapping/duplicateTargetMapping으로 다루며 해당 선택 위치 목록을 확인한다.
UI 메시지·재시도·로그 기록은 앱의 실제 처리 경계 책임이며 이번에 앱에 연결하지 않았다.

### 현재 보장하지 않는 것과 다음 작업

Ready는 해당 baseline에서 유효한 준비만 뜻한다. 현재 구성 교체·최신 상태 재확인·세션 개정은 없다.
최종 apply, WorkSession/세션 ID/revision/이력, A→B→A/과거 ID 재사용 감지,
결과/확인 무효화 실행, 배치·간섭·제작·저장·동기화·UI·로그는 미구현이다.
다음 한 가지 작업은 **최종 반영 경계와 세션 개정 연결의 설계**다.

### 구현 검증 기록 (2026-10-28)

고정 SDK의 전체 verify가 생성 시작 일치/반복 안정성·포맷·분석(No issues)·
공식 문서 dry-run(경고 0/오류 0)·전체 549개 테스트를 통과했다.
기존 7개와 신규 준비 검사 1개의 assert 비활성 AOT 및 생성기 없는 소비자 컴파일/실행도 통과했다.
공개 소비자 예제는 실제 prepareProductGeometryChange를 호출하며 기준이 바뀌지 않음을 확인한다.
별도 격리 소비자 분석에서 Ready의 기본 생성자/copyWith/candidate getter 및 요청 toJson 부재가
각각 컴파일 오류로 확인되었다. 의도적 오류 코드는 .tooling의 격리 자료에만 있다.
초기 전체 검증은 신규 AOT 검사 소스의 중괄호 lint 3건으로 중단됐다. 이를 수정한 후의 최종 전체 실행을 성공으로 기록한다.
원격 CI·다른 OS·앱 연결·최종 반영·세션 개정은 실행/구현하지 않았다.

targetProductIds는 원래 요청 ID의 집합 뷰이므로 Blocked에서도 올바른 대상이 확정됐다는 판정이 아니다.
중복/빈 ID 원본은 request.targets에 그대로 남고 issue로 처리한다. 뷰가 진단을 대신하지 않는다.
새 파일 단독 실행도 요청 3개·전체 준비 13개·입력 투영 19개·진단 12개가 각각 통과했다.

## 14. 편집 세션·최종 반영 후속 설계 (2026-10-29)

[단일 설계 문서](product-design-edit-session.md)에 소유권·기준 캡처·개정·반영·진단·검증 계획을 정리했다.
추천은 workflow의 작은 세션 객체가 구성/개정을 한 곳에서 소유하고 prepare 시 Basis를 연결하는 방식이다.
공개 순수 준비 함수를 세션 prepare로 정리하고 apply는 current 인자를 받지 않는 동기 경계로 제안한다.
5절 당시의 앱 후속 대입/순수 apply 제안과 구분한다. ID/영역 대응/비공개 후보·기존 값 계약은 유지한다.
이는 미구현 설계이며 기존 공개 함수·요청·결과·JSON·코드를 변경하지 않았다.
다음 최소 구현은 설계 검토 후 세션 open/prepare/apply/close와 기준 진단·실제 성공 전체 구성 검사까지다.