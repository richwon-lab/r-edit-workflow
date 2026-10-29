# 제품 도안 편집 세션과 최종 반영 경계 — 설계

작성일: 2026-10-29. **문서 설계이며 아래 새 API·세션 보장은 미구현이다.**
현재 구현은 [변경 계약](product-design-change.md) 12·13절의 ID 비교와 요청/전체 후보 준비까지다.
이 문서는 그 이후의 세션 기준 연결·최종 메모리 반영 추천을 한 곳에 정리한다.

## 1. 확정 요구와 실제 코드의 출발점

사용자의 확정 요구:
- 준비 당시와 같은 편집 세션·개정·전체 기준 구성에서만 채택한다.
- A → B → A 및 닫았다가 다시 열기는 이전 준비를 무효화한다.
- 검사와 교체 사이에 다른 명령이 끼어들지 않아야 한다.
- 작업별 독립 세션을 허용하고 정본 구성/개정은 한 곳만 소유한다.
- Ready의 생성자·후보·준비 기준을 외부 생성/copyWith/JSON으로 바꿀 수 없어야 한다.
- 최종 채택은 준비한 후보 그대로다. 영역 대응을 다시 추정하거나 재계산하지 않는다.

대조한 실제 파일:
- lib/src/product/product_geometry_change_request.dart: 불변 Revise/Replace, 실제 AppliedDesignGeometry 제안, 명시 targets.
- lib/src/product/product_geometry_change_preparation.dart: 공개 순수 prepareProductGeometryChange(baseline:, request:).
- lib/src/product/product_geometry_change_result.dart: 같은 library의 part. 세 결과의 baseline/request/summary, Ready의 비공개 _candidate.
- lib/src/product/product_design_configuration.dart: 검증된 불변 전체 값과 Freezed 값 동등성.
- lib/r_edit_workflow.dart: 위 공개 API를 선택적으로 export한다.
- [현재 구성 계약](product-design-configuration.md), [예외·진단 기준](failure-diagnostics-logging.md),
  [개발 기준](development-rules-draft.md), [기반 보완](development-foundation-additions.md), AGENTS.md.

**현재 prepare는 세션 ID/개정을 전혀 받거나 생성하지 않는다.**
현재 Ready가 가진 baseline만으로는 A → B → A나 다시 열기를 판별할 수 없다.
현재에는 최종 반영 함수, 편집 세션 객체, 개정 카운터가 없다.
아래의 ‘추천’은 이 사실을 변경해 설명하는 것이 아니라 후속 구현의 계약이다.

## 2. 소유권: 작은 workflow 편집 세션 객체를 추천

| 대안 | 정본과 호출 흐름 | 장점/위험 |
|---|---|---|
| 불변 상태 반환 | 앱이 현재 상태를 보관하고 순수 반영 함수에 current를 전달한 뒤 반환 상태를 대입 | 값 구조에는 자연스럽지만 await 전에 읽은 옛 current를 넘기거나 검사 후 대입을 미루는 우회가 가능하다. 앱에 별도 직렬화·최신 읽기 계약이 필요하다. |
| workflow 객체가 현재 상태 소유 **추천** | 앱이 세션 객체의 수명을 소유하고 객체가 private 현재 상태를 관리한다. apply는 매개변수 current 없이 내부 정본을 읽고 교체 | 단일 실행 흐름에서 검사/교체를 한 동기 메서드로 제한할 수 있다. 별도 mutex/명령 큐 없이 오래된 앱 스냅샷 대입을 차단한다. |

**최소 추천 모델** (모두 제안):
| 이름/필드 | 소유·유효성 |
|---|---|
| ProductDesignEditSession | workflow의 한 편집 수명 소유 객체. private _state 한 개, open/prepare/apply/close만 제공. 공개 current setter·임의 replaceConfiguration·revision setter는 없다. |
| ProductDesignEditState.configuration: ProductDesignConfiguration | 유효 현재 전체 구성. _state 안이 유일한 정본이다. 읽기 전용 불변 뷰를 반환한다. |
| ProductDesignEditState.sessionId: ProductDesignEditSessionId | 이 실행 중 편집 수명을 식별하는 불투명 토큰. 세션 생성 시 workflow가 새로 발급한다. |
| ProductDesignEditState.revision: int | 0부터 시작하는 음수 아닌 단조 증가 실행 개정. 실제 수락한 서로 다른 전체 구성마다 +1. |
| ProductDesignEditState.isClosed: bool | 앱의 명시 close 이후 true. 닫힌 객체가 남아 있어도 다시 반영하지 못하게 하는 최소 수명 방어다. 저장/배치 상태가 아니다. |
| ProductDesignEditBasis.sessionId / revision / configuration | 준비 시 한 _state에서 동시에 캡처한 불변 기준. 외부 생성자/수정/복원 API가 없다. configuration은 깊은 복제 대신 불변 값을 공유한다. |

ProductDesignEditSession과 state/ID/Basis 및 결과는 외부 상속/구현을 제한하는 타입으로 제안한다.
ProductDesignEditState/ID/Basis의 생성 경로도 세션 library 내부로 제한한다.
state를 읽는 것은 관찰이며 외부에서 읽은 state를 다시 정본으로 설치할 수 없다.
앱은 별도 currentConfiguration/revision 카운터를 두지 않는다.
앱이 표시용 state 뷰를 보관하더라도 파생 관찰값이고 반영 입력이 아니다.
파일별 화면/사용자 명령이 참조하는 **같은 세션 인스턴스**만 정본을 소유한다.

앱은 작업 열기·활성 명령 연결·닫기를 결정하고 세션 객체를 수명에 맞게 생성/해제한다.
workflow는 close의 의미·수락 조건·개정 증가를 강제한다.
워크플로에 Flutter/Riverpod, 파일 경로 해석, UI 이벤트 처리는 추가하지 않는다.

### 세션 식별과 개정의 경계

첫 안은 private 생성자를 가진 불투명 ProductDesignEditSessionId를 매 open마다 새 인스턴스로 발급한다.
토큰 동등성은 그 발급 인스턴스의 동일성이다. 재구성/문자열 입력/JSON 복원은 제공하지 않는다.
이는 실행 중 같은 소유 흐름의 세션 식별이며 **구성 내용 비교를 객체 참조 비교로 바꾼다는 뜻이 아니다.**
새 의존성 없이 다시 열기와 동시 독립 세션을 구별할 수 있다.
다른 isolate/프로세스에 토큰을 전송·복원하는 사용법은 지원하지 않는다. 필요해지면 별도 설계한다.

세션 ID는 파일명·경로·공용 원본 ID에서 만들지 않는다. 시각/내용 해시만으로 대체하지 않는다.
revision은 저장 스키마 버전, sourceRevision, Git 커밋, 영구 이력이 아니다.
증가 연산은 순환/리셋을 허용하지 않는다. int로 다음 값을 표현할 수 없는 경우
채택 전에 내부 한계 오류로 중단하고 상태를 유지한다. 이 오류를 정상 입력 거부로 숨기지 않는다.
임의의 최대 편집 횟수 정책을 만들지는 않는다.

close는 같은 구성/개정을 보존하며 isClosed만 바꾸고 반복 호출은 무해하게 한다.
닫힌 인스턴스를 다시 여는 API는 없다. 다시 열기는 같은 구성 내용이어도 새 ID·revision 0이다.
닫힌 객체의 새 prepare 호출은 수명 API 오용으로 StateError를 제안한다. 순수 요청 검증의 Blocked로 섞지 않는다.
이미 준비해 둔 결과의 지연 apply는 정상적인 closedEditSession 거부다. 앱의 동기 활성 선택 후 준비와 지연 결과 반영을 구분한다.
앱에서 객체 참조를 버리는 것만으로 이미 남은 참조까지 무효화했다고 가정하지 않는다.
앱이 닫을 때 반드시 close를 호출하고 뒤늦은 사용자 확인 콜백도 새 활성 세션으로 연결한다.

### 여러 파일과 향후 WorkSession

파일 A와 B는 각각 세션 객체를 가진다. A의 개정/준비는 B에 영향을 주지 않는다.
같은 파일의 여러 뷰를 하나의 편집으로 취급한다면 앱에서 같은 세션을 공유한다.
이 식별 관계는 앱의 열린 작업 관리 책임이며 workflow에 경로 기반 전역 세션 레지스트리를 만들지 않는다.
같은 파일의 여러 프로세스 동시 편집·외부 파일 변경·Drive 잠금은 보장하지 않는다.

향후 WorkSession은 이 작은 소유자를 구성 요소로 포함하거나 정본 소유 책임을 직접 승계할 수 있다.
승계 시에도 구성/개정은 하나만 남겨야 하며 자식과 부모에 별도 카운터를 복제하지 않는다.
이번에는 WorkDocument·저장 상태·배치/확인·자동 복구를 포함한 세션을 설계하지 않는다.

## 3. 준비 기준 연결: 세션의 공개 prepare로 정리

| 대안 | 중복/우회 |
|---|---|
| 현재 공개 순수 prepare 유지 + 세션 래퍼 | Ready를 받는 별도 bind(sessionId, revision) 경로를 열면 사후 최신 기준 붙이기가 가능하다. 안전한 래퍼는 기준 캡처부터 준비까지 직접 수행해야 하므로 두 공개 준비 결과/진입점의 구분 비용이 생긴다. |
| 세션 문맥에서 prepare만 공개 **추천** | session.prepareGeometryChange(request)가 내부 _state를 먼저 캡처하고 그 기준으로만 기존 순수 알고리즘을 호출한다. 외부에 순수 Ready를 생성하는 병렬 경로를 남기지 않는다. |

추천은 기존 순수 준비 **계산 책임**을 private 함수로 유지하고 공개 진입점을 객체 메서드로 바꾸는 것이다.
현재 함수가 이미 세션을 안다고 설명하지 않는다. 실제 후속 구현에서 export/시그니처를 정리해야 한다.
기존 시그니처를 위한 호환 별칭·이전 Ready를 세션에 등록하는 API는 두지 않는다.

순서:
1. 활성 세션의 _state 한 값을 동기적으로 읽는다.
2. 그 값에서 sessionId/revision/configuration을 함께 캡처해 private Basis를 만든다.
3. Basis.configuration과 request로 현재의 순수 영역 대응/후보 준비를 수행한다.
4. 모든 Ready/Blocked/Unchanged에 동일 Basis를 연결한다.
5. 결과만 반환한다. 현재 상태/개정은 바뀌지 않는다.

호출자가 baseline/sessionId/revision을 따로 넘기거나 이미 만든 Ready를 재결합할 수 없다.
준비 이후에는 새 요청으로 새 준비를 만들 수 있을 뿐 이전 결과의 Basis를 갱신하지 못한다.
준비가 추후 비동기가 되더라도 1–2를 작업 시작 시 수행하고 결과에 원래 Basis를 유지해야 한다.
완료 시점의 최신 개정을 붙이면 안 된다. 첫 구현의 준비는 현재처럼 동기 계산이다.

Ready의 생성자·_candidate는 계속 비공개이며 copyWith/JSON/테스트용 getter를 추가하지 않는다.
현행 baseline getter는 basis.configuration에서 파생하도록 정리해 동일 내용을 중복 정본으로 갖지 않는다.
request/summary·하위 입력/스냅샷 보존 규칙과 기존 값 JSON은 유지한다.

**최종 변경 반영의 입력은 ReadyProductGeometryChange만 받는다.**
Blocked는 요청 수정 대상, Unchanged는 변경 채택 대상이 아니므로 타입으로 분리한다.
Blocked/Unchanged를 Ready로 바꾸거나 기본 후보를 만드는 API는 없다.

## 4. 추천 API와 실제 공개 API에 미치는 영향

아래 이름은 이 문서의 추천이며 사용자 확정 또는 구현 완료 이름이 아니다.

| 추천 API/타입 | 입력·출력/의미 |
|---|---|
| ProductDesignEditSession.open(configuration:) | 유효 초기 구성으로 새 토큰·revision 0의 객체 생성. ID/개정/기존 state를 인자로 받지 않음 |
| session.state | ProductDesignEditState의 읽기 전용 불변 관찰값 |
| session.prepareGeometryChange(request) | 세션 기준이 연결된 ProductGeometryChangePreparation |
| session.applyPreparedGeometryChange(ReadyProductGeometryChange) | ProductGeometryChangeApplication. 내부 최신 상태를 읽고 직접 수락/거부 |
| session.close() | 앱이 수명 종료 시 호출. 현재 구성/개정 유지, 이후 준비/반영 차단 |
| AppliedProductGeometryChange.state / configuration / summary | 실제로 확정한 새 상태, 그 상태에서 파생한 전체 구성, 검토한 요약 |
| RejectedProductGeometryChange.state / issues | 교체하지 않은 현재 상태 뷰와 수정 불가 거부 진단 목록 |
| ProductDesignEditBasis | 준비 당시 세션 ID·개정·전체 기준 값. 읽기 전용, 임의 생성/수정 불가 |

반영 결과의 생성자도 내부에서만 사용한다.
Applied.configuration은 state.configuration의 파생 getter이며 별도 정본이 아니다.
반영 결과/준비/세션 상태에 JSON API는 없다.

기존 API 영향:
- 공개 prepareProductGeometryChange(baseline:, request:)를 위 세션 메서드로 대체한다.
  계산 본체는 내부 순수 함수로 옮기고 export를 제거한다. 호환 계층은 만들지 않는다.
- 준비 결과의 기존 세 이름은 유지 추천. baseline/request/summary 의미와 비공개 후보는 보존하고 Basis를 추가한다.
- Revise/Replace/대상/대응 모델과 순수 참조/ID 내용 검증 함수는 유지한다.
- 아직 없는 순수 apply(current:, prepared:)를 별도로 추가하지 않는다.
  과거 설계의 ‘앱에서 검사 결과를 받아 나중에 대입’ 방식은 이 추천으로 대체한다.
- 소비자 예제·테스트는 세션 open → prepare → apply 흐름으로 갱신해야 한다.
  실행 중에는 같은 소유자만 현재 구성을 교체한다.

### 파일/library 경계 제안

실제 구현 시 product_design_edit_session.dart를 세션/최종 반영 library의 진입 파일로 추천한다.
준비 계산·현재 결과·Basis/state·반영 결과 중 **비공개 기준/후보 접근이 필요한 파일만** 그 library의 part로 구성한다.
현재 product_geometry_change_result.dart의 part of와 준비 파일 import/part 선언이 이에 맞게 바뀔 수 있다.
요청/대응/요약·기존 업무 값·전용 진단은 독립 library를 유지한다.
private 후보 접근 때문에 공개 getter를 만들거나 모든 product/geometry 파일을 part로 묶지 않는다.
반영 진단은 product_geometry_change_application_errors.dart에 별도로 두고
기존 준비 거부 코드·기하/문구 오류 enum에 섞지 않는다.

## 5. 최종 반영의 동기 실행 경계

session.applyPreparedGeometryChange는 current 매개변수를 받지 않는다.
같은 실행 흐름의 동기 메서드 한 호출 안에서 다음을 수행한다.

1. 자신의 최신 _state를 지역 변수 current로 읽는다.
2. 세션 활성 여부와 아래 3종 기준을 검사한다.
3. 거부 진단이 있으면 상태를 한 번도 교체하지 않고 Rejected를 반환한다.
4. 성공이면 prepared._candidate 그대로와 같은 세션 ID, revision + 1, 활성 상태로 새 불변 state를 만든다.
5. 성공 결과 객체까지 준비하고 private _state를 **한 번 대입**한다.
6. 확정한 바로 그 state를 담은 Applied를 반환한다.

개정 표현 한계/내부 결함으로 4–5의 준비가 실패하면 이전 상태를 유지한다.
이 경계에는 await, 호출자 콜백, 공개 listener 호출, I/O, 사용자 정의 comparator를 넣지 않는다.
구성 비교는 현재 불변 값 모델의 구조 동등성을 사용한다.
검사 이후 영역 대응을 다시 실행하거나 다른 후보를 계산하지 않는다.
요약이 아니라 실제 준비 후보 전체를 채택한다.

추천 실행 전제는 한 isolate의 직렬 동기 호출이다.
이 전제에서 검사–대입 사이에 이벤트 루프의 다른 명령이 끼어들지 않도록 호출 경계를 제한한다.
별도 mutex·명령 큐·이벤트 버스·분산 잠금을 도입하지 않는다.
앱의 표시 갱신/알림은 메서드가 반환한 후 수행한다. 알림에서 다른 명령이 실행돼도 이미 원자적 교체는 끝났다.
반환된 state는 그 호출의 결과 관찰값이다. 이후 다른 명령이 바꾼 최신 정본을 이 값으로 덮어쓰면 안 된다.

앱은 await 전에 캡처한 configuration/revision을 apply에 넘길 통로가 없다.
대신 확인 화면을 띄우기 전에 얻은 Ready를 그대로 갖고, 확인 후 **현재 활성 세션 객체**에 전달한다.
그 사이 변경됐으면 그 객체의 내부 개정으로 거부한다.
작업을 닫고 열었으면 새 세션으로 전달해 다른 세션 진단을 받는다.
이전 객체를 붙잡은 콜백도 이미 close된 객체에서는 수락하지 못한다.
앱의 현재 활성 객체 선택은 동기적으로 한 번 수행하고 같은 호출에서 apply한다.

## 6. 세 가지 기준 검사의 의미와 정상 거부

| 검사 | 보장 | 대체하지 못하는 것 |
|---|---|---|
| 세션 ID 일치 | 다른 파일/다시 열린 작업의 결과를 차단 | 같은 세션 안의 이후 편집을 구별하지 못함 |
| 실행 개정 일치 | 같은 세션의 수락된 변경을 지나친 준비를 차단. A → B → A도 거부 | 전체 구성의 동일성 검사를 대체하지 못함 |
| 전체 baseline 값 동등성 | 준비한 모든 값·순서와 실제 최신 구성이 일치함을 대조 | 이력/A → B → A는 값만으로 구별할 수 없음 |

전체 baseline은 미사용 스냅샷까지의 값/순서·단위·출처·제품 순서·비대상·원문·줄 방식/조각 전부다.
객체 참조, ID, hashCode, JSON 문자열, 시각만으로 비교하지 않는다.
같은 세션/개정인데 내용이 다르면 불변식 위반의 방어 진단으로 거부한다.
이를 자동 복구·성공·빈 구성으로 바꾸지 않는다.
그 상황의 내부 원인을 조사하는 일은 별도이며 예상 밖 Error를 catch해 이 진단으로 변환하지 않는다.

진단 타입은 ProductGeometryChangeApplicationIssue / ProductGeometryChangeApplicationCode를 추천한다.
상세는 ClosedEditSessionDetails, EditSessionMismatchDetails, EditRevisionMismatchDetails,
EditBaselineMismatchDetails처럼 아래 조건마다 작은 타입으로 분리한다. 임의 nullable 필드 집합으로 합치지 않는다.

추천 전용 진단 (순서는 공개 계약이 아님):

| 코드 | 조건/fieldPath | 필수 구조화 상세 | 호출자의 대응 |
|---|---|---|---|
| closedEditSession | 현재 소유자가 닫힘 / current.isClosed | 현재 sessionId, prepared의 sessionId, isClosed=true | 닫힌 인스턴스로 재시도하지 말고 활성 작업을 다시 선택 |
| differentEditSession | 같은 반영 경계에서 current.sessionId와 prepared.basis.sessionId가 다름 / prepared.basis.sessionId | expectedSessionId=현재 소유자 ID, actualSessionId=준비 ID | 그 세션 결과를 이 작업에 반영하지 않음. 올바른 활성 세션에서 다시 준비 |
| staleEditRevision | 같은 세션에서 개정이 다름 / prepared.basis.revision | expectedRevision=현재 개정, actualRevision=준비 개정, 공통 sessionId | 현재 상태에서 다시 준비/검토. 최신 개정을 기존 Ready에 붙이지 않음 |
| baselineConfigurationMismatch | 같은 세션에서 전체 기준 값이 다름 / prepared.basis.configuration | sessionId, currentRevision, preparedRevision, expectedPath=current.configuration, actualPath=prepared.basis.configuration | 채택 중단·원인 조사·새 기준에서 재준비. 전체 값을 진단에 복제하지 않음 |

baselineConfigurationMismatch 상세는 불일치 사실/비교 위치를 제공한다.
첫 범위에 범용 객체 diff나 새 전체 구성 경로 수집 엔진을 만들지 않는다.
실제 기대/기준 구성은 session.state와 원래 prepared.basis에서 조회할 수 있으나 진단/로그에 덤프하지 않는다.
다른 진단과 달리 기대/실제 원문을 저장하지 않는다는 제한을 명시한다.

**독립/종속 수집 정책**:
- closed이면 closedEditSession을 반환하고 세션/개정/내용 대조는 생략한다. 더 이상 반영 가능한 현재 편집 수명이 아니다.
- 활성이나 세션 ID가 다르면 differentEditSession만 반환한다.
  서로 다른 세션의 revision 3/3을 비교하거나 다른 파일의 내용을 전부 대조하지 않는다.
- 같은 활성 세션이면 개정과 전체 내용은 독립적으로 검사한다.
  A → B → A에서는 staleEditRevision만, 개정·내용이 모두 달라지면 두 진단을 수집한다.
- 같은 개정/다른 내용은 baselineConfigurationMismatch만 반환한다.
  정상 공개 변경 경로로는 만들 수 없어야 하지만 검사 책임을 제거하지 않는다.
- 상세/코드 조합·필수 ID/음수 개정·위치 오류는 런타임에서 API 오용으로 거부한다.
  assert만 쓰지 않고, 메시지 파싱/임의 Map/원문 덤프를 사용하지 않는다.

정상 요청 거부는 기존 Blocked, 최종 기준 거부는 Rejected다.
개발자용 한국어 설명과 사용자 화면 안내·로그 기록은 구분하며 앱의 실제 처리 경계에서 결정한다.

## 7. 개정·상태 전이

A/B는 전체 구성 값, S/T는 서로 다른 실행 세션이다. 아래는 **설계 표이며 실행 결과가 아니다.**

| 상황 | 전 → 후 | 결과/개정 규칙 |
|---|---|---|
| 유효 Ready 반영 | (S,r,A) → (S,r+1,B) | 세 기준이 모두 맞고 B≠A일 때 Applied. 후보 그대로 채택 |
| 같은 값을 다시 지정 | (S,r,A) → 그대로 | 유효한 요청의 Unchanged. 토큰/개정/구성 교체 없음 |
| 입력/요청 검증 실패 | (S,r,A) → 그대로 | 기존 값 예외 또는 Blocked. 개정 증가 없음 |
| 준비만 수행 | (S,r,A) → 그대로 | Basis(S,r,A)를 캡처할 뿐 변경 없음 |
| 준비 결과 폐기/사용자 취소 | (S,r,A) → 그대로 | 결과 참조 폐기만 수행. 취소 명령/개정 소비 없음 |
| 수락된 A → B → A | (S,r,A) → (S,r+1,B) → (S,r+2,A) | 최초 Basis(S,r,A)는 내용 같아도 staleEditRevision. 두 번째 A는 A의 전 값을 다시 만드는 유효 변경이라는 뜻 |
| 같은 기준의 준비 P/Q 중 P 먼저 반영 | (S,r,A) → (S,r+1,B) | 이후 Q는 개정 거부. 내용도 다르면 그 진단도 수집 |
| 같은 Ready 재반영 | 이미 (S,r+1,B) | staleEditRevision으로 거부. 후보 같다고 중복 성공 처리하지 않음 |
| 다른 파일 결과 혼용 | 현재 (T,q,C), 준비 Basis(S,r,A) | differentEditSession. T는 그대로 |
| 닫기 | (S,r,A,열림) → (S,r,A,닫힘) | 구성/개정 유지. 이전 객체의 후속 prepare/apply 차단 |
| 같은 내용으로 다시 열기 | 새 (T,0,A,열림) | 이전 S 결과는 세션 불일치. S 자체는 계속 닫힘 |
| 준비 이후 현재 변경, 과거 Unchanged를 취급 | 현재 최신 상태 유지 | 과거 baseline 재대입 금지. 과거 무변경을 현재 판단으로 표시하지 않음 |

A → B → A 표는 구성 전체가 실제로 동등하게 복원되는 경우를 뜻한다.
현재 도안 준비는 미사용 스냅샷을 보존하므로 새 ID 추가 뒤에는 전체 값이 A와 같지 않을 수 있다.
그 경우에도 개정 불일치로 거부한다.
회귀 시험은 스냅샷 목록이 그대로인 기존 스냅샷 간 참조 왕복 등으로 **실제 전체 A** 복원을 만들어야 한다.
이 표는 과거 ID 재사용을 허용하거나 오래된 Ready로 되돌리기를 실행한다는 뜻이 아니다.

Unchanged는 apply의 인자가 될 수 없다. 즉시 동기 준비 결과라면 상태를 건드리지 않고 반환한다.
사용자 확인/다른 await를 거친 Unchanged는 폐기한다.
현재에도 무변경인지 필요하면 현재 세션에서 요청을 **새로 준비/검토**한다.
과거 Unchanged의 baseline을 대입하거나 ‘아무 변경 없음’ 판단을 최신 상태에 자동 재사용하지 않는다.
별도 무변경 반영 함수/세션 비교 공개 helper는 첫 범위에 추가하지 않는다.

## 8. 최소 호출 흐름 — 설계용 의사 Dart

아래 코드는 **미구현 추천 API의 검토 예시이며 컴파일/실행 검증하지 않았다.**
앱 상태 프레임워크·UI 구현 예제도 아니다.

~~~dart
// 파일을 열 때: 앱은 이 작업 수명에 세션 객체 하나만 소유한다.
final session = ProductDesignEditSession.open(configuration: loadedConfiguration);
openedWork.session = session;

// 준비 시점: baseline과 개정은 session이 함께 캡처한다.
final prepared = openedWork.session.prepareGeometryChange(request);

switch (prepared) {
  case BlockedProductGeometryChange():
    // 기존 요청 거부 진단을 표시할 수 있다. 정본 상태는 바뀌지 않는다.
    break;
  case UnchangedProductGeometryChange():
    // 이 동기 시점의 무변경. 과거 baseline을 대입하지 않는다.
    break;
  case ReadyProductGeometryChange():
    final accepted = await askForReview(prepared.summary);
    if (!accepted) return; // 폐기만 한다. 개정을 증가시키지 않는다.

    // await 이전의 state/configuration을 current로 넘기지 않는다.
    // 닫혔거나 작업이 교체됐으면 앱의 활성 세션을 다시 선택한다.
    final activeSession = openedWork.session;
    final outcome = activeSession.applyPreparedGeometryChange(prepared);
    switch (outcome) {
      case AppliedProductGeometryChange():
        // outcome.configuration은 실제 확정된 전체 후보다.
        // 관찰/표시 갱신만 한다. activeSession.state = outcome.state 같은 setter는 없다.
        renderFrom(activeSession.state);
      case RejectedProductGeometryChange():
        showChangeDiagnostics(outcome.issues);
    }
}
~~~

실제 앱에서는 열린 작업이 사라진 경우 apply를 호출하지 않고 요청을 폐기한다.
다른 작업을 활성화했다면 원래 작업의 생존/세션 관계를 앱이 명확히 선택해야 하며,
편의상 현재 화면의 다른 작업에 적용시키지 않는다. 실수로 섞어도 세션 진단이 막는다.
후보 검토에는 준비 요약을 쓰고, 반영 성공 후에는 반환한 실제 전체 configuration을 소비할 수 있다.

준비 뒤 다른 편집이 발생할 수 있는 것은 정상이다. 그럴 때 거부하는 것이 이 설계의 역할이다.
반면 apply 내부의 검사/교체는 중간 재진입 없이 끝나야 한다.
한 isolate 안에서도 호출자 콜백을 내부에 넣으면 동기 재진입이 가능하므로 내부 확장 콜백을 받지 않는다.

## 9. 후속 구현 검증 계획

현재 코드에서 얻은 후보를 반영 전에 테스트용 getter로 열지 않는다.
공개 apply 성공 결과의 **실제 전체 구성**을 고정 기대 값과 비교한다.
기대 후보를 현행 준비 알고리즘으로 다시 계산하는 순환 검증도 피한다.

| 공개 계약 시험 | 핵심 기대 |
|---|---|
| 최신 Basis의 정상 반영 | 같은 세션, r→r+1, Applied.state가 세션의 확정 state, configuration이 예상 전체 값과 동등 |
| A→B→A 이후 최초 Ready | 실제 전체 A 복원을 먼저 검증한 뒤 staleEditRevision. 토큰은 같고 개정은 +2 |
| 닫고 같은 구성으로 다시 열기 | 새 세션 토큰/0 개정. 옛 Ready는 새 객체에서 differentEditSession, 닫힌 옛 객체에서도 거부 |
| 같은 기준 P/Q 경쟁 | P만 수락하고 Q는 거부. Q의 기준을 최신 값으로 붙여넣는 생성/수정 API 부재 |
| 같은 Ready 재사용 | 두 번째 수락/개정 증가 없음. 동일 후보라는 이유로 성공하지 않음 |
| 무변경/Blocked/거부/취소 | 구성·개정 보존. 지연된 Unchanged가 이전 baseline을 재대입하지 않음 |
| 다른 파일 세션 | A의 수락이 B의 state/revision/준비 유효성에 영향 없음. 교차 apply는 세션 진단만 |
| 개정+내용 동시 차이 | 같은 세션의 두 독립 진단. 목록 순서는 고정하지 않음 |
| 같은 개정/다른 내용 방어 | 내부 최소 상태 검사 책임을 단위 시험. 이를 만들 공개 setter/JSON/테스트 전용 생성자는 추가하지 않음 |
| 임의 생성/변조 경로 | Ready/Basis/state 생성·copyWith·후보 getter·JSON 및 개정 setter가 소비자에 노출되지 않음 |
| 재진입 경계 | apply에 async/콜백 삽입 경로가 없고 확정 후 앱 알림의 후속 변경은 별도 개정으로 처리 |
| 개정 표현 한계 | 증가 실패 시 구성/개정 모두 보존. 순환·부분 채택 없음 |

정상 반영의 전체 구성 기대에는 다음을 **요약과 별도로** 확인한다.
- 기존 appliedGeometries의 모든 값과 순서, 미사용 이전 스냅샷 보존.
- 새로운 스냅샷 하나만 뒤에 추가 또는 내용이 같은 기존 슬롯 재사용. 다른 ID 동일 내용 병합 없음.
- 제품 목록 순서·비대상 제품의 ID/참조/입력 전체 보존.
- 대상의 원문 공백·Unicode·자동/직접 지정 한 줄·여러 줄·조각 순서 보존.
- 유지/전달 입력 상대 순서와 신규 입력의 요청 순서.
- 명시 복수 대상이 동일 새 appliedGeometryId 하나를 참조하며 각 원문은 독립 소유.
- 실패/반복 준비는 원래 baseline/request 및 이미 반환한 관찰 뷰를 변경하지 않음.
- Applied.configuration이 실제 준비 후보를 그대로 채택한 결과임을 고정 기대 전체 구성으로 입증.

후속 구현 시 기존 생성·포맷·분석·문서·전체/단독 테스트·AOT·생성 없는 소비자 기준을 적용한다.
이번 문서 작업에서는 실행하지 않는다. HTML/앱/CI 검증 결과를 합성하지 않는다.

## 10. 추천 확정점·남은 결정·다음 최소 구현

**이번 사용자 요구로 확정**: 동일 세션/개정/전체 기준, A→B→A/재열기 거부,
한 동기 경계의 검사·교체, 단일 정본, 파일별 독립성, private 후보/준비 기준, 미구현 범위의 분리.

**현행 추천**:
- workflow의 작은 ProductDesignEditSession 객체 + 읽기 전용 불변 state.
- 내부 순수 준비 계산을 유지하며 공개 prepare는 세션 메서드로 대체.
- 토큰은 실행 중 불투명 ID, 개정은 검사된 int 증가.
- 최종 apply는 Ready만 수락하고 자체 최신 정본을 직접 교체.
- 닫힌 세션 방어, 같은 세션의 개정/내용 독립 진단, Unchanged는 채택하지 않음.

**구현 전 사용자 판단이 남은 사항**:
1. 추천한 객체 소유/공개 prepare 대체 및 API 이름 채택 여부. 기존 서명 유지용 별칭은 추천하지 않는다.
2. 실행 중 단일 isolate 불투명 토큰의 지원 경계 수용 여부. 전송/복원이 필요하면 별도 요구가 필요하다.
3. 앱의 동일 파일 중복 열기를 같은 세션의 여러 뷰로 취급할지 여부.
   어느 선택도 다른 프로세스의 파일 잠금을 보장하지 않는다. 첫 workflow 구현은 독립 객체까지만 지원한다.

다음 최소 구현은 **위 추천을 검토한 뒤 작은 편집 세션의 open/prepare/apply/close와
세션 기준 진단, 공개 성공 구성 검증을 한 번에 연결하는 것**이다.
앱 연결·전체 WorkSession·새 업무 명령·저장/자동 복구/영구 이력/실행 취소·
배치 결과 무효화·동기화·UI는 포함하지 않는다.

## 11. 이번 문서 검토 범위

실제 요청/준비/결과·공개 export와 13절 현행 계약을 대조했다.
기준 캡처→사용자 확인→동기 반영의 소유 흐름, 타입별 무변경 처리,
실제 전체 A 복원과 단순 물리적 형상 동일성의 차이, 세션/개정/내용 진단의 종속성을 검토했다.
문서의 로컬 참조는 누락 0건이며 기존 설계의 대체/유지 지점과 호출 흐름을 검토했다.
Dart 생성·분석·테스트·AOT는 문서 전용 요청에 따라 실행하지 않았다.
이 문서는 설계용이며 코드·테스트·생성 파일·의존성·앱·SDK·CI는 변경하지 않는다.
