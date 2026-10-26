# 제품 입력과 적용 도안의 참조·변경 계약

2026-10-27 변경 동작의 현행 설계는 [제품 적용 도안 변경 계약](product-design-change.md)이다. 요청/준비/반영 API는 미구현이며 아래 2026-10-26 제안·이름·검증 기록과 구분한다.

현재 값·참조 부분의 구현은 [제품 구성 구현 계약](product-design-configuration.md)을 따른다. 아래 변경·출처/ID 정책의 과거 제안과 현재 보장 범위를 구분하며 안전한 변경 반영은 여전히 미구현이다.

2026-10-26 최초 설계 당시 기록. 값·참조 부분은 위 후속 구현 계약으로 구체화했고 변경 동작은 미구현이다. 당시 구현은 [도안 구성](design-geometry.md), TextAreaInput과 validateTextAreaInputs까지다. 아래 JSON은 관계 검토용이며 전체 작업 파일 스키마가 아니다.

## 1. 기준과 결정 상태

최신 사용자 요구가 이전 문서의 이름·필드 후보보다 우선한다.

| 상태 | 내용 |
|---|---|
| 확정 원칙 | 불변 적용 내용 공유, 개별 변경의 참조 분리, 명시 제품 ID 집합에만 일괄 적용, 실제 내용과 출처 분리, areaId 연결, 원문·지정 줄 보존 |
| 현재 구현 | DesignGeometry의 문맥·외곽·관통·영역, TextAreaInput, 영역 입력 중복·미정의·누락 검사 |
| 이번 추천 | AppliedDesignGeometry / ProductInput / ProductDesignConfiguration과 선택적 DesignSourceReference, 아래 ID·참조·변경 준비 계약 |
| 미정 | 최종 이름, ID 발급, 공용 원본의 버전·위치·식별 범위, 제작 조건의 첫 필드, 미사용 스냅샷 정리, 변경 API |
| 미구현 | 추천 모델 모두, 변경·무효화 실행, 공용 등록·동기화, WorkDocument/WorkSession, 결과·확인·저장·UI·엔진·DXF |

[기존 모델 설계](model-design.md)의 공유·분리 원칙을 현재 구현 위에서 구체화한다. 과거 AppliedDesign.production·areas 후보를 현재 필수 필드로 되살리지 않는다. 영역은 이미 DesignGeometry.textAreas가 소유하며 바깥에서 중복 소유하지 않는다.

확인 기준은 workflow HEAD 09238b26d372e15fd26956c14631b904d9cfe441이며 시작 작업 트리·스테이징은 깨끗했다. AGENTS.md, README.md, docs/contract.md, docs/model-design.md, docs/next-step.md, docs/development-rules-draft.md, docs/design-geometry.md와 lib/r_edit_workflow.dart, lib/src/design의 구성·영역·오류·입력 검증, lib/src/text_area_input.dart를 확인했다. 형제 앱 docs/decisions.md·docs/module-boundaries.md를 읽기 전용으로 참고했다. 앱 HEAD는 358a66ab3b307b5e91671d98875228a4ae25b149다. Office 원본 전체를 이번에 다시 대조한 것은 아니며 과거 원본 대조를 새 검사로 보고하지 않는다.

## 2. 데이터 소유 관계 추천

~~~text
공용 ReusableDesign (작업 밖, 등록부 미구현)
  └─ 선택 시 실제 형상·영역 캡처 + 출처 별도 기록

ProductDesignConfiguration (참조를 검사하는 작은 구성, 작업 파일 아님)
  ├─ appliedGeometries: AppliedDesignGeometry 목록
  │    ├─ appliedGeometryId
  │    ├─ geometry: DesignGeometry (문맥·외곽·관통·영역의 실제 내용)
  │    └─ source: DesignSourceReference? (공용 원본 출처)
  └─ products: ProductInput 목록
       ├─ productId
       ├─ appliedGeometryId ── 같은 구성의 적용 형상 참조
       └─ textInputs ── 참조한 geometry.textAreas와 areaId 대조
~~~

AppliedDesignGeometry는 **적용 도안의 형상·영역 부분에 대한 불변 스냅샷**이다. 완전한 AppliedDesign이나 제조 사양이 아니다. 여러 제품이 같은 레코드를 참조해도 원문·줄바꿈은 제품별로 소유한다. 제품에 좌표·홀·영역 경계를 중복 저장하지 않는다.

| 모델·필드 후보 | 타입·필수성·기본값 | 책임·불변식 |
|---|---|---|
| ReusableDesign.sourceDesignId | String, 공용 원본 개념의 필수 ID 후보 | 공용 자료 범위에서 원본 식별. 작업 내부 ID와 별개. 공용 범위 식별 규약은 미정 |
| ReusableDesign.geometry | DesignGeometry, 현재 형상 단면 | 재사용할 실제 내용. 공용 원본 모델·등록부 자체는 다음 최소 구현에서 제외 |
| AppliedDesignGeometry.appliedGeometryId | String, 필수·기본값 없음 | 구성 안 불변 적용 형상 ID |
| geometry | DesignGeometry, 필수 | 원본 없이 해석할 실제 적용 내용 |
| source | DesignSourceReference?, 선택 | 기록된 출처가 있을 때만 값. JSON에서는 없으면 생략 추천. 제작 조건의 빈 대체값이 아님 |
| DesignSourceReference.sourceDesignId | String, 출처가 있으면 필수 | 선택한 공용 원본 ID. 제품 참조 해석 키가 아님 |
| sourceRevision | String?, 선택 | 실제 아는 원본 버전만 보존. 모르면 생략하고 latest·임의 버전으로 채우지 않음 |
| ProductInput.productId | String, 필수·기본값 없음 | 구성 안 제품 ID. 같은 문구도 다른 제품 가능 |
| appliedGeometryId | String, 필수 | 같은 구성의 적용 형상 목록에 정확히 하나 존재 |
| textInputs | List<TextAreaInput>, 필수 | 적용된 각 영역 정의에 입력 하나. 영역 0개이면 명시적 빈 목록 가능 |
| ProductDesignConfiguration.appliedGeometries | List<AppliedDesignGeometry>, 필수 | 소유 ID 유일, 방어 복사·수정 불가. 첫 범위에서는 미사용 스냅샷도 허용 추천 |
| products | List<ProductInput>, 필수 | productId 유일, 참조·영역 대응 검증. 빈 목록 허용 추천은 빈 작업 파일 저장 정책이 아님 |

새 ID는 우선 기존 areaId처럼 비어 있지 않은 String을 추천한다. trim·정규화하지 않으며 공백만인 ID를 추가 금지하지 않는다. 표시 이름·문구·좌표·순서로 만들지 않는다. 모든 목록은 필수로 전달하고 누락을 []로 보정하지 않는다. 제품 표시 이름·수량·상태 필드는 최소 구성에 추가하지 않는다.

출처는 “이 원본에서 출발했다”는 기록이다. 적용 후 수정한 geometry가 원본 버전과 동일하다는 보증이 아니다. 파생 스냅샷에도 출처를 유지할 수 있지만 원본을 재조회하거나 덮어쓸 권한이 생기지 않는다. source 없음은 출처 기록 부재이지 반드시 로컬 신규 작성임을 증명하는 값은 아니다. 원본 위치는 식별자가 아니며 경로 규약이 미정이므로 첫 필드에서 제외한다. 공용 원본 ID가 여러 공용 범위에서 충돌할 수 있다면 범위 식별부터 정하고 자동 병합하지 않는다.

### 제작 조건이 연결될 자리

| 후속 책임 | 연결 방향 | 이번 제한 |
|---|---|---|
| 자재·두께·색상·문구 작업 방식 | 후속 제작 조건의 불변 실제 값. 완전한 적용 내용이 형상과 함께 소유하도록 별도 설계 | 타입·필수 필드·기본값 없음 |
| 배치 기준·문구 패턴 | 형상과 별도인 실제 적용 기준. 후속 계산 요청에서 제품 입력·형상과 결합 | 임의 rules Map·가짜 기준 ID 없음 |
| 계산에 영향을 주는 제작 속성 | 지원 필드가 정해질 때 계산 입력으로 명시 전달 | 관리 정보까지 모두 계산 영향이라고 단정하지 않음 |
| 출력·관리 정보 | 해당 출력·관리 책임에서 연결 | 이번 구성에 미리 필드를 추가하지 않음 |

형상이 같아도 제작 조건이 다르면 후속 **완전한 적용 내용**은 달라질 수 있다. 형상 스냅샷은 재사용할 수 있지만 완전한 적용 도안 ID까지 같다는 뜻은 아니다. appliedGeometryId를 제작 조건 전체를 포괄하는 ID로 간주하지 않는다. 후속 제품 참조의 확장은 별도 설계이며 호환 별칭을 미리 만들지 않는다.

## 3. 이름 후보와 예상 사용 코드

| 책임 | 후보 | 추천 이유·혼동 |
|---|---|---|
| 공용 원본 | ReusableDesign / DesignTemplate / SharedDesign | ReusableDesign 추천. Template은 빈 틀, Shared는 작업 안 공유 스냅샷과 혼동 가능 |
| 적용 형상 스냅샷 | AppliedDesignGeometry / AppliedGeometrySnapshot / AppliedDesign | AppliedDesignGeometry 추천. 형상·영역 단면임이 드러남. AppliedDesign은 제작 조건까지 완성된 것처럼 읽힘 |
| 제품 입력 | ProductInput / WorkProduct / ProductDraft | ProductInput 추천. 결과·저장을 가진 완성 제품이 아니며 Draft라는 이유로 잘못된 값을 허용하지 않음 |
| 참조 소유 구성 | ProductDesignConfiguration / ProductDesignSet / WorkDocument | ProductDesignConfiguration 추천. 참조를 검사하지만 파일·세션은 소유하지 않음 |
| 출처 | DesignSourceReference / AppliedSource / DesignOrigin | DesignSourceReference 추천. 실제 내용과 다른 참고 출처이며 제품 연결 키가 아님 |

다음 코드는 미구현 API의 사용 제안이다. 최종 생성 방식과 검증 경로는 구현 시 확인한다.

~~~dart
final shared = AppliedDesignGeometry(
  appliedGeometryId: 'g-1',
  geometry: geometry,
  source: DesignSourceReference(sourceDesignId: 'catalog-42'),
);
final product = ProductInput(
  productId: 'p-a',
  appliedGeometryId: shared.appliedGeometryId,
  textInputs: inputs,
);
final configuration = ProductDesignConfiguration(
  appliedGeometries: [shared],
  products: [product],
);
final applied = configuration.appliedGeometries.singleWhere(
  (value) => value.appliedGeometryId == product.appliedGeometryId,
);
// 제품만의 copyWith는 외부 참조를 보장하지 않는다. 구성 반영 시 다시 검증한다.
~~~

## 4. ID와 참조 불변식

1. productId와 appliedGeometryId는 별도 이름 공간이며 각각 구성의 소유 목록 안에서 유일하다. 두 종류 ID의 문자열이 같아도 충돌은 아니다. 다른 구성에서도 같은 문자열을 쓸 수 있지만 구성 간 참조로 해석하지 않는다.
2. 같은 appliedGeometryId는 같은 geometry와 source에 대응한다. 목록 안 중복 레코드는 내용이 같아도 거부한다. 다른 ID의 같은 내용은 허용하되 자동 병합하지 않는다.
3. 변경 전후의 공통 ID는 모든 필드 값을 비교하여 내용 바꿔치기를 거부한다. JSON 키 순서나 객체 동일성만으로 판단하지 않는다. 기존 목록 순서도 임의로 바꾸지 않으며 해시 ID·정규 JSON은 도입하지 않는다.
4. 초기 구성 하나만 읽으면 과거 같은 ID가 다른 내용이었는지 증명할 수 없다. 단독 검증은 현재 목록·참조를 보장하고 변경 경계는 이전 상태까지 비교한다. 새 ID만 붙인 뒤 원래 공유 객체를 수정해도 된다는 뜻이 아니다.
5. 하위 값까지 불변으로 공유한다. 변하지 않은 불변 경계의 물리적 깊은 복제를 강제하지는 않지만 외부 목록·반환 JSON으로 옛 내용이 변하는 경로는 없어야 한다.
6. 적용 ID는 소유 구성의 수명 동안 다른 내용에 재사용하지 않는다. 최소 단계에서는 미사용 스냅샷을 자동 정리하지 않는 방안을 추천한다. 제거 이력·재사용·실행 취소 정책은 후속 판단이다. 임의 파일 편집의 역사까지 증명하는 감사 기능은 설계하지 않는다.
7. 제품의 영역은 (구성, appliedGeometryId, areaId) 문맥에서 해석한다. 다른 도안의 같은 areaId 문자열은 의미 동일성의 근거가 아니다. 파생 영역 유지와 다른 도안 교체를 변경 의도로 구분해야 한다.

### 상위 구성의 검증

- 빈 ID·소유 ID 중복·적용 참조 존재를 확인한다. 중복 참조 대상 중 하나를 last-wins로 선택하지 않는다.
- 참조가 유일하게 해석된 제품마다 기존 validateTextAreaInputs(design: applied.geometry, inputs: product.textInputs)를 호출한다.
- 하위 duplicateInputAreaId / unknownInputAreaId / missingAreaInput의 코드·상세를 보존하고 관련 productId·appliedGeometryId·상위 위치를 더한다.
- 적용 참조가 없거나 모호한 제품은 영역을 대조할 수 없다. 해당 제품의 모든 입력을 미정의 영역으로 오진하지 않는다. 다른 해석 가능한 제품은 독립 진단할 수 있다.
- ProductInput 단독은 자기 ID·입력 값·입력 ID 중복을 검사할 수 있다. 참조 존재와 정의 대비 누락은 상위 구성의 책임이다. 구성의 생성·copyWith·JSON 복원에서도 같은 관계 검증을 권장한다.
- 제품 입력 순서·원문·방식을 바꾸지 않는다. 정의·참조 성공은 형상 포함·간섭·면적·글자 충돌·배치·제작·저장 판정이 아니다.

## 5. 변경 전후의 계약

| 동작 | 준비하는 새 상태 | 유지·반영 조건 |
|---|---|---|
| 두 제품 공유 | p-a와 p-b가 g-1 참조, 각자 입력 소유 | 한 제품 입력이 다른 제품으로 전파되지 않음 |
| p-a의 형상만 변경 | 새 geometry와 새 ID g-2를 만들고 p-a만 참조 교체 | g-1과 p-b 참조·입력 유지. 같은 업무 영역의 위치·크기 변경이면 areaId·원문·지정 줄 유지 |
| 선택한 여러 제품 변경 | 시작 시 구체적인 제품 ID 집합을 확정하고 새 스냅샷에 한 번에 연결 | 나중에 추가한 제품 제외. 대상 소멸은 무시하지 않고 실패. 서로 다른 도안을 암묵 통합하지 않음 |
| p-a 원문·지정 줄 변경 | 새 유효 TextAreaInput을 만들고 p-a 입력 교체 | 형상이 같으면 기존 적용 참조 유지. 원문·지정 줄의 중간 불일치 반영 금지. 패턴 자동 등록 없음 |
| 다른 도안 교체 | 이전·새 적용 ID와 명시 영역 대응·새 입력으로 후보 구성 | 같은 areaId·label·문구·좌표·순서만으로 자동 대응하지 않음 |
| 영역 추가 | 새 영역별 명시 입력 필요 | 빈 원문·자동 방식으로 채우지 않음. 입력 부족은 미완료 제안 |
| 영역 삭제 | 남는 이전 입력을 미해결 자료로 보존 | 조용히 삭제·합치지 않음. 명시 대응 또는 제외 의사가 정해질 때까지 유효 구성에 반영하지 않음 |

명시 대상 전체 적용도 원래 도안이 다르면 제품별 대응이 필요하다. 한 새 도안으로 통합할지 도안별로 파생시킬지는 호출자가 명시한다. 범용 전체 변환 명령을 미리 만들지 않는다.

같은 업무 영역의 위치·크기만 바꾸는 파생 변경은 유지한 areaId로 입력을 계속 연결할 수 있다. 의미가 다른 영역은 새 ID를 부여하거나 명시적 대응을 선택한다. ID만으로 의미의 연속성을 증명할 수 있다고 하지 않는다. 외곽 치수 변경으로 홀·영역을 자동 비례 확대하지 않는다.

### 영역 교체 예시

g-1의 title을 g-3의 heading으로 명시 대응한다. g-3에도 title이라는 다른 역할의 영역이 있지만 자동으로 그곳에 연결하지 않는다.

~~~json
{
  "productId":"p-a",
  "fromAppliedGeometryId":"g-1",
  "toAppliedGeometryId":"g-3",
  "areaMappings":[
    {"fromAreaId":"title","toAreaId":"heading"}
  ],
  "newTextInputs":[
    {"areaId":"title","sourceText":"NO. 7","lineBreak":{"mode":"automatic"}}
  ]
}
~~~

변경 준비를 설명하는 자료이며 저장 필드나 구현된 명령이 아니다. 새 g-3에는 heading/title 정의가 있다고 가정한다. 이전 title의 입력은 areaId만 heading으로 바꾸며 sourceText="PUMP  A "와 지정 한 줄 ["PUMP  A "]를 그대로 유지한다. 새 title에는 명시된 NO. 7 입력을 쓴다.

첫 대응은 일대일을 추천한다. 이전 영역·대상 영역 모두 중복 대응을 거부하고, 대상마다 기존 연속 영역 유지·명시 대응·신규 입력 중 하나만 선택한다. 없는 이전/새 영역은 거부한다. 자동 분할·결합·복제는 하지 않는다. 서로 무관한 도안 교체에서는 같은 ID의 identity 대응도 명시해야 한다.

삭제되는 이전 원문은 제외 의사가 명시될 때까지 미완료 제안에 보존한다. 명시 제외의 구체 API·실행 취소는 미정이며 유효 구성에 임의 보관 Map을 추가하지 않는다. 현재 TextAreaInput의 빈 원문·빈 줄·CR/LF 제한을 편집 상태를 이유로 완화하지 않는다.

## 6. 일관된 반영과 미완료 제안

유효 참조 구성과 반영 전 미완료 제안을 구분한다. 후자는 개념이며 WorkSession·ProductDraft 전체를 이번에 정의하거나 구현하는 요구가 아니다.

1. 현재 불변 구성을 기준으로 잡고 구체 대상 제품 ID 집합·이전 적용 ID를 확정한다.
2. 이전 공유 값을 변경하지 않고 새 geometry·스냅샷·후보 제품 입력을 별도 값으로 준비한다.
3. 대응 부족·이전 입력 미처리·중복 대상이 있으면 후보와 원래 입력을 보존한 미완료 제안을 남긴다. 현재 구성은 바꾸지 않는다.
4. 후보 구성 전체의 ID·참조·기존 영역 검증과 변경 전후 공통 ID 내용 불변을 확인한다.
5. 준비 기준과 현재 구성이 같은지 대조한다. 기준 변경·대상 소멸을 오래된 제안으로 덮어쓰지 않는다. 첫 동기 구현에서는 캡처한 불변 값 대조로 시작할 수 있고 범용 트랜잭션·세대 프레임워크는 필요 없다.
6. 성공한 새 구성 하나를 한 번에 반영한다. 스냅샷만 먼저 추가하거나 제품 참조만 먼저 교체하지 않는다. 실패하면 모든 대상의 이전 구성·원문을 유지한다.

입력이 모두 대응하더라도 참조 구성으로서 유효할 뿐이다. canSave/isLayoutComplete 플래그를 만들지 않는다. 미완료 제안의 파일 저장도 범위 밖이다.

## 7. 결과 무효화 영향표 — 실행은 미구현

| 변경 | 향후 결과·작업자 확인 영향 | 구분·한계 |
|---|---|---|
| 외곽·홀·영역·제외 경계의 실제 변경 | 대상 영향 영역과 실제 의존 대상, 이전·새 자동 그룹의 영향을 검토. 변경 결과에 기존 확인 재사용 금지 | 공유 도안이라는 이유만으로 다른 제품 입력·참조를 변경하지 않음 |
| 원문·방식·지정 줄 변경 | 해당 영역과 실제 계산 의존 대상의 결과 무효화 | 직접 지정 한 줄 유지. 공용 패턴으로 전파하지 않음 |
| 제품 추가·삭제·영역 참여 변경 | 이전·새 참여자와 실제 의존 범위 검토 | 적용 ID를 자동 그룹 키로 확정하지 않음 |
| label·출처 등 계산 무관 정보만 변경 | 계산 내용이 같으면 ID 변경만으로 재계산을 강제하지 않음 | 같은 스냅샷 ID 내용 교체 금지는 유지. 출처 필드 변경도 새 레코드·새 ID 추천 |
| 수량만 변경 | 문구 배치 조건과 분리, 기존 원칙상 배치 결과·확인 무효화 없음 | 수량 타입·0·기본값·출력 표현의 상세는 미정 |
| 공용 원본만 변경 | 현재 적용 내용에 자동 반영하지 않고 그 이유만으로 무효화하지 않음 | 새 버전 채택은 명시 대상·새 스냅샷 변경 |
| 화면 표시 단위만 변경 | 표시 책임이며 배치 입력 변경 아님 | 실제 데이터 환산의 결과 재사용 동등성은 별도 판단. 임의 허용오차로 재사용하지 않음 |

LayoutResult·OperatorReview를 생성하거나 JSON에 채우지 않는다. 구조 검증만으로 계산 의존·그룹을 알아낸다고 하지 않는다. 결과 없음·계산 미완료를 확인으로 완료 처리하지 않는 기존 원칙도 유지한다.

## 8. 두 제품 공유에서 한 제품 변경으로

두 예시는 실제 geometry를 포함하므로 공용 원본 없이 형상·영역·제품 입력 관계를 해석할 수 있다. 원은 예시를 짧게 쓰기 위한 선택이며 형상을 원으로 제한하는 업무 모델이 아니다. 제작 조건·결과·수량·저장 버전은 넣지 않았다.

변경 전에는 두 제품이 g-1을 공유한다.

~~~json
{
  "appliedGeometries":[
    {
      "appliedGeometryId":"g-1",
      "source":{"sourceDesignId":"catalog-42","sourceRevision":"r7"},
      "geometry":{
        "coordinateSpace":{"lengthUnit":"millimeter"},
        "outline":{"kind":"circle","center":{"x":0,"y":0},"radius":30},
        "cutouts":[],
        "textAreas":[
          {"areaId":"title","label":"","region":{
            "outer":{"kind":"circle","center":{"x":0,"y":0},"radius":10},
            "exclusions":[]
          }}
        ]
      }
    }
  ],
  "products":[
    {"productId":"p-a","appliedGeometryId":"g-1","textInputs":[
      {"areaId":"title","sourceText":"PUMP  A ","lineBreak":{"mode":"specified","lines":["PUMP  A "]}}
    ]},
    {"productId":"p-b","appliedGeometryId":"g-1","textInputs":[
      {"areaId":"title","sourceText":"VALVE B","lineBreak":{"mode":"automatic"}}
    ]}
  ]
}
~~~

변경 후 p-a만 외곽 반지름을 35로 바꾼 g-2를 참조한다. g-1은 그대로다. title은 같은 업무 영역을 유지한다고 명시한 파생 변경이다. g-2의 출처 r7은 수정 출발점이며 원본과 내용이 같다는 표시는 아니다.

~~~json
{
  "appliedGeometries":[
    {
      "appliedGeometryId":"g-1",
      "source":{"sourceDesignId":"catalog-42","sourceRevision":"r7"},
      "geometry":{
        "coordinateSpace":{"lengthUnit":"millimeter"},
        "outline":{"kind":"circle","center":{"x":0,"y":0},"radius":30},
        "cutouts":[],
        "textAreas":[
          {"areaId":"title","label":"","region":{
            "outer":{"kind":"circle","center":{"x":0,"y":0},"radius":10},
            "exclusions":[]
          }}
        ]
      }
    },
    {
      "appliedGeometryId":"g-2",
      "source":{"sourceDesignId":"catalog-42","sourceRevision":"r7"},
      "geometry":{
        "coordinateSpace":{"lengthUnit":"millimeter"},
        "outline":{"kind":"circle","center":{"x":0,"y":0},"radius":35},
        "cutouts":[],
        "textAreas":[
          {"areaId":"title","label":"","region":{
            "outer":{"kind":"circle","center":{"x":0,"y":0},"radius":10},
            "exclusions":[]
          }}
        ]
      }
    }
  ],
  "products":[
    {"productId":"p-a","appliedGeometryId":"g-2","textInputs":[
      {"areaId":"title","sourceText":"PUMP  A ","lineBreak":{"mode":"specified","lines":["PUMP  A "]}}
    ]},
    {"productId":"p-b","appliedGeometryId":"g-1","textInputs":[
      {"areaId":"title","sourceText":"VALVE B","lineBreak":{"mode":"automatic"}}
    ]}
  ]
}
~~~

## 9. 오류와 진단 후보

제품 참조 오류는 GeometryErrorCode·TextInputErrorCode에 넣지 않는다. 전용 ProductDesignErrorCode / ProductDesignValidationException / ProductDesignIssue를 추천하되 구체 반환 API는 구현 전에 선택한다. 오류 순서는 계약으로 고정하지 않는다.

| 코드 후보 | 발생 조건·구분 | 진단 정보 |
|---|---|---|
| emptyProductId / emptyAppliedGeometryId | 빈 ID. 존재하지 않는 참조와 별개 | 필드 경로·원래 ID |
| duplicateProductId / duplicateAppliedGeometryId | 소유 목록에 같은 ID 선언 | ID·firstIndex·duplicateIndex·관련 제품 |
| unknownAppliedGeometryId | 제품의 적용 참조가 없음 | productId·적용 ID·products[i].appliedGeometryId |
| appliedGeometryContentConflict | 변경 전후 같은 ID의 geometry/source가 다름 | 적용 ID·이전/새 위치·차이 필드. 초기 단독 구성으로 과거 변경 검증 불가 |
| textAreaInputMismatch (상위 분류 후보) | 해석한 도안과 입력이 불일치 | productId·적용 ID·원래 DesignValidationIssue |
| unknownTargetProductId / staleConfiguration | 명시 대상이 없거나 준비 기준이 달라짐 | 대상 ID·선택 위치·기준과 현재 차이. 임의 세대 필드 없음 |
| unknownSourceAreaId / unknownTargetAreaId | 대응의 이전/새 영역이 없음 | 제품·이전/새 적용 ID·대응 위치·이전/새 areaId |
| duplicateSourceAreaMapping / duplicateTargetAreaMapping | 일대일 대응의 원본/대상 중복 | 영역 ID·두 대응 위치 |
| unresolvedPreviousInput / missingTargetInput | 이전 원문 미처리/새 영역 입력 부족 | 제품·areaId·원래 입력/새 정의 위치. 자동 삭제·빈 값 보정 없음 |

하위 영역 코드는 duplicateInputAreaId / unknownInputAreaId / missingAreaInput을 그대로 보존한다. 상위 분류를 쓰더라도 원인을 일반 오류 하나로 뭉개지 않고 타입이 있는 상세에 원래 issue를 가진다. 작은 상세 후보는 ProductReferenceDetails(제품·적용 ID), OwnedIdConflictDetails(ID와 두 위치), AreaBindingDetails(제품·적용 ID와 원래 issue), AreaMappingDetails(이전/새 참조·대응 위치)다. 임의 Map이나 모든 필드가 nullable인 거대 진단형은 만들지 않는다.

경로의 기준도 분리한다. 하위 unknownInputAreaId의 inputs[2].areaId는 상위 products[0].textInputs[2].areaId로 연결한다. missingAreaInput은 입력이 없으므로 적용 도안 정의의 위치를 주고 관련 제품 ID를 함께 제공한다. 하위 textAreas 경로를 제품 아래에 단순 접두사로 붙여 존재하지 않는 경로를 만들지 않는다. 원래 issue.fieldPath도 유지한다.

~~~text
unknownAppliedGeometryId
fieldPath=products[0].appliedGeometryId
productId=p-a, appliedGeometryId=g-missing
설명=제품이 참조하는 적용 형상이 구성에 없습니다.

cause.code=missingAreaInput
fieldPath=appliedGeometries[1].geometry.textAreas[0].areaId
productId=p-a, appliedGeometryId=g-2, areaId=title
cause.fieldPath=textAreas[0].areaId
설명=적용 영역 정의에 대응하는 제품 입력이 없습니다.
~~~

예상 출력이며 실제 제품 오류 API는 아직 없다. 중첩 JSON의 기하 오류는 원래 GeometryValidationException의 code/diagnostic, 입력 값 오류는 TextInputValidationException의 code/fieldPath를 잃지 않고 상위 위치를 제공한다.

## 10. 예상 파일과 검토 테스트

구현 시 필요한 파일만 만든다. [테스트 배치 기준](test-organization.md)을 따른다.

~~~text
lib/src/design/applied_design_geometry.dart       적용 형상 ID·실제 내용·출처
lib/src/design/design_source_reference.dart       필요한 최소 출처
lib/src/product/product_input.dart               제품 ID·참조·영역 입력
lib/src/product/product_design_configuration.dart 소유·참조·영역 검증
lib/src/product/product_design_errors.dart        제품 참조 오류·상세
test/design/applied_design_geometry_test.dart
test/design/design_source_reference_test.dart
test/product/product_input_test.dart
test/product/product_design_configuration_test.dart
test/product/product_design_change_test.dart      변경 구현 단계에서만
~~~

product/는 실제 책임이 추가될 때의 후보이며 지금 빈 폴더를 만들지 않는다. 공개 값은 lib/r_edit_workflow.dart로 노출하고 기존 생성 도구와 런타임 검증을 쓴다. 범용 명령 기반형·공통 패키지는 필요 없다.

| 향후 테스트 조건 | 막아야 하는 잘못된 구현 |
|---|---|
| 두 제품이 g-1 공유, p-a만 g-2로 변경 후 g-1 전체·p-b 참조/입력이 이전과 같음 | 새 ID만 만들고 원래 공유 객체의 내용을 수정 |
| 이전/새 스냅샷에 전달한 목록·하위 경계·반환 JSON 외부 변경 방어 | 표면적인 final만으로 가변 내용을 공유 |
| 같은 ID의 geometry/source 바꿔치기를 변경 전후 비교로 거부 | ID만 같으면 다른 내용도 재사용 |
| p-a 원문·지정 줄 변경이 p-b에 영향 없음 | 같은 도안이므로 제품 입력까지 공유 |
| 제품/적용 ID 중복·참조 없음 구분 | last-wins Map으로 중복 삭제 |
| label·문구·좌표·순서를 같게 하고 ID만 다르게 하면 미대응 진단 | 표시 내용으로 자동 연결 |
| 무관한 g-3:title로 교체 시 명시 대응이 없으면 변경 준비 미완료 | 같은 areaId 문자열로 의미 추정 |
| title→heading 명시 대응 후 연속·끝 공백·결합 문자·지정 한 줄 보존 | ID 변경 때 원문 정규화·자동 방식 전환 |
| 영역 추가·삭제·중복 대상 미해결이면 모든 이전 구성과 원문 유지 | 부분 반영·무단 삭제·빈 원문 보충 |
| 대상 {p-a,p-b} 확정 뒤 추가된 p-c에는 변경 미적용 | 실행 시 같은 ID 전체를 다시 검색해 암묵 전파 |
| 선택 대상 하나가 잘못되거나 없어지면 전체 반영 안 함 | 일부 성공을 보통 성공으로 처리 |
| 공용 원본 삭제·변경에도 로컬 실제 내용 해석 유지 | 원본 ID만 두고 내용 재조회 |
| 고정 기대 JSON 구조와 왕복·하위 오류 원인 모두 검사 | 양쪽 변환이 같은 누락을 해도 왕복만으로 통과 |

첫 구성의 JSON만으로 의미가 다른 동명 ID 영역을 알아낼 수 있다고 하지 않는다. 명시 대응을 요구하는 변경 API 테스트와 구조 참조 테스트는 별개다. 위 사례는 값·참조·변경 계약 검토이며 배치·제작 성공 시험이 아니다.

## 11. 다음 한 번의 최소 구현과 미정

**다음 구현은 변경 명령보다 먼저 적용 형상 스냅샷·제품 입력·구성의 값과 참조 검증을 만드는 것을 추천한다.**

- AppliedDesignGeometry(ID/geometry/선택 출처), 최소 DesignSourceReference, ProductInput, ProductDesignConfiguration과 전용 오류.
- 기존 validateTextAreaInputs를 결합해 중복·없는 참조·영역 입력 불일치를 진단. 구성의 생성·수정·JSON 복원에서 같은 조건과 방어 복사 보장.
- 고정 JSON 구조·공유/독립 원문·오참조·ID 중복·입력 부족·수정 전 불변성 테스트.
- 변경 전후 ID 내용 비교와 명시 영역 대응 반영 API는 그다음 최소 범위. 단독 구성 생성 성공을 과거 같은 ID의 불변성이나 안전한 도안 교체 명령 완성으로 부르지 않음.
- 공용 등록부·제작 조건·수량·결과·확인·저장·공유 명령·UI는 제외.

| 남은 판단 | 선택지와 추천 |
|---|---|
| 이름·참조 필드 | 좁은 AppliedDesignGeometry/appliedGeometryId 추천. 완전한 AppliedDesign 선점 방지 |
| ID 발급 | 호출자 명시 발급 vs 패키지 발급. 첫 구현은 명시 String 수신 추천. 알고리즘·의존성 미정 |
| 출처의 버전·범위 | 버전 필수 vs 아는 경우만. 선택/생략 추천. 여러 공용 범위 연결 전 ID 이름 공간 결정 필요 |
| 미사용 스냅샷 | 자동 삭제 vs 유지. 첫 단계는 유지 추천. 삭제·ID 재사용·실행 취소는 후속 |
| 오류 수집 | 첫 예외 vs 독립 issue 수집. 참조 검사는 독립 제품별 수집 추천, 잘못된 구성 생성은 거부. 구체 API는 구현 전 결정 |
| 영역 삭제의 명시 제외 | 이동 vs 명시 제외. 의사 미확정이면 미반영. 구체 API·실행 취소는 미정 |
| 제작 조건 | 첫 속성과 계산 영향은 별도 설계. null·범용 Map·가짜 정상값으로 채우지 않음 |
| 수량·의존성 | 수량 상세 보류. 수량만으로 배치 무효화하지 않는 원칙 유지. 그룹·실제 의존 판별 미구현 |

## 12. 문서 검증과 한계

문서 JSON 3개 블록의 문법, 공유/개별 변경 예시의 ID 유일성·참조 존재·영역 대응·지정 줄 연결, g-1/p-b 유지와 g-2 외곽 변경·입력 보존을 문서용 검사로 확인한다. 대응 예시는 새 영역 {heading,title}에 대한 일대일 대응과 새 입력을 대조한다. 실제 Dart 제품 모델·저장·배치·제작 실행 검증은 아니다.

사용자 지정에 따라 코드 변경이 없으므로 Dart 생성·분석·테스트·AOT·pub get은 실행하지 않는다. 코드·테스트·생성 파일·의존성·SDK·형제 앱·스테이징·커밋 이력은 변경하지 않는다. 수정 대상은 이 문서와 관련 링크·다음 작업뿐이다.

실제 검사 결과: Node의 JSON 구문/구조 비교로 위 JSON 3개 블록의 관계 검사를 통과했다. 수정한 문서 5개의 상대 링크 41개는 대상 파일이 존재했다. git diff --check를 통과했고 문서 외 추적 파일과 인덱스의 차이가 없음을 확인했다. 형제 앱 작업 트리도 깨끗했다. 이 검사는 문서 예시의 대조이며 Dart API 실행 시험이 아니다.
