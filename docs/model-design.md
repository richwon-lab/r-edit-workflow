# 첫 업무 모델 설계안

2026-10-19 원본 대조 개정. 대상은 **C:/work/richwon/r_edit_workflow**다. 영역 입력의 초기 구현은 11절, 현재 Freezed 전환은 12절에 기록한다. 나머지는 논리 모델 제안이며 확정 Dart API·전체 저장 스키마·구현 완료 보고가 아니다. 이전 잠정안의 자료 누락 안내와 도안 내장·합성 구분 설계를 이번 대조 결과로 교체한다.

WorkDocument/WorkSession 분리와 제품별 완료 결과에 연결하는 OperatorReview는 유지한다. 주요 수정은 작업 파일 안의 적용 도안 공유, 개별 변경 시 참조 분리, 규칙·패턴의 별도 적용 기록, 추가·삭제를 포함한 그룹 변경, ID뿐 아니라 입력 내용까지 대조하는 결과 수락·읽기 검증이다.

## 1. 작업 대상과 읽은 자료

셸 시작 위치는 앱 C:/work/richwon/r_edit였지만 쓰기 대상은 r_edit_workflow/docs다. 업무 패키지는 master, HEAD는 `31c529090d8b942612594f460ec4997c51ac2ccc`다. 시작 시 docs/next-step.md 수정과 미추적 docs/model-design.md는 이전 설계 작업의 변경으로 존재했다. 이를 기준으로 개정하며 다른 파일의 변경을 되돌리지 않는다.

참고 앱 HEAD는 `ac11bd44cf098f3cc16b69b2d82d67eb94d1844a`다. **추가 기준 자료는 이 커밋에 포함된 자료가 아니라 현재 작업 트리의 자료**다. 시작 시 앱 상태는 docs/README.md 추가 스테이징, docs/next-step.md 수정, docs/development-reference/ 미추적이었다. 이 커밋만으로 추가 자료의 버전을 재현할 수 없으므로 원본 SHA-256도 기록한다. 앱은 읽기 전용으로 참고했다.

### 1.1 실제 경로와 대조 방법

아래 앱 상대 경로의 기준은 `C:/work/richwon/r_edit/`다.

| 읽은 자료 | 실제 경로 | 확인 범위 |
|---|---|---|
| 최신 문서 색인 | docs/README.md | 연결 경로와 우선 적용 순서 |
| 기능 활용 점검표 v0.1 | docs/development-reference/reference/current/리치원_기능활용_점검표_v0.1.xlsx | 기능 활용 점검·남은 연결과 지원 범위 2개 시트 |
| 점검표 셀 추출본 | docs/development-reference/reference/text/리치원_기능활용_점검표_v0.1.txt | F01~F60, N01~N17, D01~D13 전체 |
| 데이터 논리 설계 초안 v0.1 | docs/development-reference/reference/current/리치원_도안데이터_논리설계_초안_v0.1.docx | 2026-10-18 저장본, 본문·표의 1~11장 |
| 논리 설계 추출본 | docs/development-reference/reference/text/리치원_도안데이터_논리설계_초안_v0.1.txt | 본문·표 전체 |
| 현재 결정·경계 | docs/decisions.md, docs/module-boundaries.md | 저장 정책·원문·패턴·책임 |
| 자료 묶음 안내 | docs/development-reference/README.md, docs/development-reference/DECISIONS.md | 과거 자료와 현재 합의의 구분 |
| 앱 상태 | AGENTS.md, README.md, docs/next-step.md | 앱 책임과 현재 구현 범위 |

업무 패키지의 AGENTS.md, README.md, docs/contract.md, docs/next-step.md와 기존 docs/model-design.md도 읽었다. 패키지 파일의 절대 경로 기준은 `C:/work/richwon/r_edit_workflow/`다.

Office 원본은 ZIP/XML을 읽기 전용으로 열었다. DOCX 본문·표의 비어 있지 않은 문단 270개가 제공 추출본에 모두 포함됨을 확인했고, XLSX의 비어 있지 않은 셀 720개(수식 0개)의 값이 추출본에 모두 포함됨을 확인했다. 본문 판단에는 추출본을 사용했다. 이 포함 검사는 렌더링·셀 위치·텍스트 순서의 완전한 동일성 검사가 아니며 도형·이미지·서식은 시각적으로 검토하지 않았다. 이번에 요청된 두 원본과 두 추출본은 모두 실제로 존재한다.

| 원본/추출본 | SHA-256 |
|---|---|
| 점검표 XLSX | C4B98376FE55452C4F5B98DFC5E9598672513D3488B1BB4C8F14D3116B496EBE |
| 논리 설계 DOCX | 665DA4651EE0B68165EACA844BC80E354B094ED4EB039A82E916D6D2DD86D55C |
| 점검표 TXT | 9B076CA1C3135165D00D2E5A259C46279D1A95F72A90982B67D62217D340D22E |
| 논리 설계 TXT | 5F2607EA981BF1AE9B2282C61162E03166F64364BAE2626787D14EABC9AA8CC0 |

사용자의 최신 명시 결정 → 앱 docs/decisions.md → 최신 논리 설계 → 기존 요구사항·시험 기록 순으로 적용한다. 점검표의 F32~F34는 과거 초안 저장 시험이고 현재 초기 제품은 미완료 편집을 저장하지 않는다. F26의 그룹 일부 패턴 매칭 차단 제한도 D05의 현재 합의로 대체한다. 과거 Python 시험 통과는 Dart 구현 완료가 아니다. 색인에 있는 요구사항 v0.7·설계 검토 v0.13·전체 과거 시험 원문까지 이번에 모두 재검토한 것으로 기록하지 않는다.

## 2. 기존 안과 원본의 일치·차이·미정

| 항목 | 대조 결과와 근거 | 이번 반영 |
|---|---|---|
| 완료 문서/편집 세션 구분 | 일치. 논리 3·8장, 현재 결정의 저장 기준 | WorkDocument/WorkSession 유지, 미완료는 메모리 전용 |
| 결과별 확인·원래 판정 보존 | 일치. 논리 3·6장 | OperatorReview.resultId 유지 |
| 여러 제품의 적용 도안 공유 | 기존 안은 제품마다 도안 내장. 논리 2·5장의 참조 공유를 표현하지 못함 | 문서의 appliedDesigns 목록과 제품의 appliedDesignId 참조로 변경 |
| 한 제품/전체 도안 변경 | 기존 안은 명시적 적용 대상·참조 분리 부족. 논리 5장의 36×36 제품 20종 사례 | 불변 도안 복제 후 선택 제품만 참조 교체, 전체 변경도 명시적 대상 집합 사용 |
| 형상·영역과 규칙·패턴 | 기존 AppliedDesign.rules와 제품 bounds의 혼합 소유가 부적절. 논리 5장 표 47, 6장 표 59, 10장 | 형상·영역 정의는 AppliedDesign, 결합 규칙·패턴·출처는 AppliedLayoutCriteria로 분리 |
| 제품 추가·삭제·그룹 이동 | 기존 변경 표는 추가·삭제 누락. 점검표 N08/D09는 구현 기준 초안, F14·논리 6장은 이전/새 그룹 영향 | 그룹 전후 구성과 실제 의존 범위 계산을 명시. 그룹 알고리즘은 확정하지 않음 |
| 입력 ID/내용 검증 | 기존 inputId 및 productId→inputId 맵만으로는 누락 참여자·같은 ID의 내용 교체를 확인하기 어려움. 논리 6장, F37 | 불변 계산 입력 스냅샷, 영역 단위 참여자 전체 집합, 깊은 내용 비교와 검증 한계 명시 |
| 합성 구분 | 기존 EngineIdentity.kind와 운영 저장 거부는 업무 원본에 근거 없음 | 운영 필드·분기에서 제거. 예제 설명·테스트 파일 경로로만 표시 |
| 수량 기본값 | 기존 일괄 기본값 없음은 논리 1장의 신규 수동 입력 제안과 불일치 | 직접 새 항목은 1 제안, 가져오기 실패는 미확정. 양의 정수는 첫 지원 후보, 0·빈 값 정책은 N12 미정 |
| 출력 표현 | 기존 미정 표시 중 의미는 원본으로 해소. 논리 4장·F29 | 수량만큼 도안 복제 / 한 도안+명판 밖 수량 표시. 세부 enum명·배치 위치는 설계 후보 |
| 줄 경계·좌표·일반 도형 | 논리 5장도 문자 위치 단위/직렬화 미정. N05/N10/N09 범위 유의 | 조용히 확정하지 않음. 직사각 예시는 전체 지원 모델이 아님 |

## 3. 문서·제품·도안·적용 기준의 관계

### 3.1 유지하는 문서와 세션

- `WorkDocument`: 한 작업 파일의 저장 가능한 완료 상태. documentId와 formatVersion, 적용 도안·기준, 모든 제품의 현재 입력·완료 결과·필요한 확인을 보존한다. 한 발주에 여러 파일이 가능하고 다른 파일과 자동 그룹을 섞지 않는다.
- `WorkSession`: 열린 파일 하나의 편집·계산 상태. 마지막 저장 문서, 편집 제품, 현재 적용 도안/기준 목록, 진행 요청·실패 진단을 가진다. 미완료 입력·재계산 대상·requestId·sessionId·진행률은 저장하지 않는다.
- `WorkProduct`: 제품별 문구·방식·수량·참조와 완료 결과를 묶는다. 동일 문구라도 productId가 다르면 별도 제품이다.
- `ProductDraft`: 편집 상태에서 결과·확인이 없을 수 있다. 저장 제품으로 변환할 때 전체 조건을 검증한다. 불완전 숫자 문자열·포커스 같은 UI 값은 앱 책임이다.

작업 파일 전체가 저장 단위이며 canSave를 영구 필드로 두지 않는다. 정상 완료 결과는 확인 불필요, 규칙 이탈의 참고 완료 결과는 해당 resultId 확인 필요, 배치 없음·계산 불가·탐색 미완료는 확인만으로 저장 불가다. 저장 실패·취소는 이전 파일과 편집 내용을 보존한다. 열기는 저장 결과를 사용하며 재계산·이전 프로세스 재개를 하지 않는다.

### 3.2 도안은 공유하고 변경 대상은 명시한다

WorkDocument 안에 `appliedDesigns: List<AppliedDesign>`을 두고 WorkProduct가 `appliedDesignId: String`으로 참조한다. 이는 공용 원본 ID가 아니라 **이 작업에 적용한 불변 스냅샷 ID**다. 서로 다른 제품이 같은 ID를 참조할 수 있다. 제품 수량과 문구는 공유하지 않는다. 값이 같다는 이유로 제품이나 도안 참조를 자동 병합하지 않는다.

공용 도안의 itemId/revision과 선택적 상대 경로는 출처로만 보존하며 실제 형상·영역·제작 적용값도 작업 파일에 둔다. 공용 원본의 변경·삭제 또는 다른 PC의 폰트 설치 상태로 저장된 결과를 자동 교체하지 않는다.

| 동작 | 참조와 내용 처리 | 결과·확인 영향 |
|---|---|---|
| 같은 적용값으로 제품 추가 | 기존 appliedDesignId 참조 가능, 새 productId 발급 | 새 제품은 결과 없음. 관련 자동 그룹의 기존 참여자도 확인 |
| 한 제품의 도안 변경 | 새 appliedDesignId와 변경 내용을 생성하고 그 제품만 재연결 | 대상 제품 및 실제 이전/새 그룹 의존 결과 무효화. 기존 공유 도안은 수정하지 않음 |
| 공유 도안의 전체 변경 | 명령 시점에 적용 대상 productId 집합을 명시하고 새 도안 생성 후 그 집합을 한 번에 재연결 | 선택 대상과 그룹 영향 범위만 무효화. 나중에 추가한 제품으로 자동 전파하지 않음 |
| 여러 도안을 쓰는 제품 전체 변경 | 도안별 변경 내용을 별도로 제시. 기존 도안을 단일 도안으로 자동 통합하지 않음 | 새 영역 대응이 모호하면 적용 중단·확인 요구 |
| 공용 원본 새 버전 채택 | 내용·출처가 있는 새 적용 도안/기준 생성, 대상 명시 | 기존 작업과 이전 저장본 유지, 채택 대상만 변경 |

도안 치수만 변경해 홀·영역을 비례 확대하지 않는다. 도안 변경 시 대응되는 areaId의 문구·직접 지정 줄 구성은 유지하고 맞춤을 다시 계산한다. 영역 추가는 명시 입력 필요, 영역 삭제/교체는 문구를 조용히 버리거나 같은 label로 자동 연결하지 않는다. 보존 가능한 영역 ID와 새 영역 매핑을 명시해 검증한 뒤 적용한다. 대응 불가 입력은 세션의 미완료 상태로 남긴다. 기존/새 도안 영역 ID는 제품의 appliedDesignId 범위 안에서 해석하며 전역 유일성을 요구하지 않는다.

### 3.3 형상과 배치 정책의 책임을 구분한다

| 소유 모델 | 담는 내용 | 담지 않는 내용 |
|---|---|---|
| AppliedDesign | 외곽·제작 치수·홀·텍스트 영역 정의와 안정된 영역 ID, 실제 제작 조건과 공용 도안 출처 | 현재 제품 문구·줄 경계·수량, 결합된 배치 규칙·문구 패턴 |
| TextAreaDefinition (도안 내부 값) | areaId, label, 영역 형상·좌표계상의 위치 | 제품별 원문, 자동/직접 방식 |
| TextAreaInput (제품 내부 값) | areaId, sourceText, lineBreak | bounds·도안 치수·홀 복제 |
| AppliedLayoutCriteria | 실제 결합한 영역별 배치 규칙·문구 패턴, 켜기/끄기 의도와 적용 내용·출처 | 외곽·홀·텍스트 영역 형상 |
| CalculationInputSnapshot | 계산에 사용한 도안·제품 입력·적용 기준·그룹·폰트 측정·엔진·탐색 조건의 불변 묶음 | 수량·출력 순서·출력 모드·표시 이름 |
| LayoutResult | 확정 줄·크기·자폭·위치, 원래 판정·진단, 계산 입력 연결 | 패턴 자동 등록, 엔진 내부 객체 |

배치 기준과 문구 패턴은 AppliedLayoutCriteria 안에서 별도 값/목록으로 구분하며 같은 클래스로 합치지 않는다. 도안이 추천 기본 기준을 연결할 수는 있지만 실제 결합 조건의 소유권을 도안 형상에 섞지 않는다. 기준은 별도 지정 없음·값 지정·사용 안 함을 구분하고 속성별 출처를 보존한다. 원문 보존·홀 회피·허용 경계는 선택 규칙을 꺼도 해제하지 않는다. 다중 패턴 일치 자체는 오류가 아니며 양립 가능한 것은 함께 적용, 포함 충돌은 구체 문구 우선, 비포함 충돌 처리는 미정이다.

같은 적용 도안을 쓰는 제품은 그 도안의 제작 조건도 공유한다(논리 11장). 형상이 같아도 자재·두께·색상·문구 작업 방식 등 제작 적용값이 다르면 적용 도안을 구분한다. UV 문구+외곽 CNC라는 이유로 조각용 글자 커터 조건을 적용하지 않는다. 제작 조건 중 계산에 영향을 주는 값만 계산 입력에 포함하며 그 분류는 필드 지원 범위와 함께 명시해야 한다. 단순 관리 메모 변경까지 계산 영향으로 추측하지 않는다.

## 4. 필드와 타입 제안

이름은 검토용 Dart 후보, JSON은 lowerCamelCase 후보다. 모든 목록·값은 외부 변경 불가로 만들며, ID는 우선 비어 있지 않은 String을 제안한다. 자동 발급 방법은 미정이고 표시 이름·목록 순서·원문을 ID로 사용하지 않는다. 특별히 적지 않은 필드는 필수이며 운영 기본값이 없다. 지원하지 않는 값·필수 누락은 오류로 반환한다.

### 4.1 문서와 제품

| 타입·필드 | 타입·필수/기본 | 의미·관계 |
|---|---|---|
| WorkDocument.documentId / formatVersion | String / int, 필수 | 파일 논리 ID / 저장 형식 버전. 엔진 버전과 독립, 최초 버전 값은 아직 미정 |
| orderReference | String?, 기본 null | 발주 미연결 시작 허용. 여러 발주 병합을 허용한다는 뜻 아님 |
| appliedDesigns | List<AppliedDesign>, 필수 | 작업 내 실제 적용 도안. 중복 ID 금지 |
| appliedCriteria | List<AppliedLayoutCriteria>, 필수 | 작업 내 실제 적용 배치 기준·패턴. 도안과 독립된 ID |
| products | List<WorkProduct>, 필수 | 리스트 순서를 출력 순서로 사용. 빈 완료 파일 허용은 미정 |
| WorkProduct.productId / displayName | String / String, 필수 | 제품 ID / 표시 이름. 이름 중복 허용, 표시 이름은 계산 조건 제외 |
| appliedDesignId / appliedCriteriaId | String / String, 필수 | 문서 내 도안·적용 기준의 참조. 단일 제품 변경 시 참조 교체 |
| localInputId | String, 필수 | 제품 자체의 불변 배치 관련 입력 세대. 6절의 완전한 계산 inputId와 구분 |
| textInputs | List<TextAreaInput>, 필수 | 현재 적용 도안의 영역에 연결. 이름으로 자동 매핑 금지 |
| quantities | ProductQuantities, 필수 | orderQuantity:int, fileProductionQuantity:int. 주문량과 이 파일 담당량을 분리 |
| outputMode | OutputMode, 필수 | repeatedGeometry / quantityAnnotation 후보. 명판 밖 수량 표시는 도안 1개, 반복은 파일 제작 수량만큼 |
| layoutResult | LayoutResult, 필수 | 저장 시 현재 입력과 맞는 완료 결과 |
| review | OperatorReview?, 기본 null | 해당 결과에 확인이 필요할 때만 명시 부여 |

직접 새 항목 생성 명령의 수량 초기값은 1을 제안한다(논리 1장). JSON 읽기·발주 가져오기에서 수량을 읽지 못하면 1로 보정하지 않는다. 첫 지원은 명시된 양의 정수 후보이며 0·빈 값·취소 수량 등은 N12처럼 여전히 미정이다. 도안 수는 출력 구성에서 산출하고 저장 상태로 중복하지 않는다. 수량 변경은 배치·확인을 유지하지만 출력 진행 중 변경이나 패턴 적용 미리보기의 유효성은 별도 세대 검사가 필요하다(F27/F43). 배치용 inputId를 이를 위해 수량에 묶지 않는다.

### 4.2 도안·입력·적용 기준

| 타입·필드 | 타입·필수/기본 | 의미·조건 |
|---|---|---|
| AppliedDesign.appliedDesignId | String, 필수 | 불변 스냅샷 ID. 같은 ID의 내용 제자리 변경 금지 |
| source | AppliedSource?, 기본 null | 직접 작성은 공용 출처 없음. itemId:String, revision:String, relativePath:String? 후보 |
| geometry | DesignGeometry, 필수·세부 미정 | 외곽·치수·홀. 미지원 형상을 빈 홀·직사각으로 바꾸지 않음 |
| areas | List<TextAreaDefinition>, 필수 | 임의 개수의 영역 정의. 본문/NO/RAT 고정 금지 |
| production | AppliedProductionConditions, 필수·세부 미정 | 실제 제작 적용값. 불필요한 공정·설비·고객 선행 등록 없음 |
| TextAreaDefinition.areaId / label | String / String, 필수 | 도안 안 영역 ID / 표시 이름 |
| geometry | TextAreaGeometry, 필수·세부 미정 | 영역 형상·위치. label·원문과 독립 |
| TextAreaInput.areaId / sourceText | String / String, 필수 | 도안 영역 참조 / 공백·기호·대소문자·Unicode 표현 그대로 |
| lineBreak | LineBreakInput, 필수·현재 구현 | AutomaticLineBreak 또는 SpecifiedLineBreak. 생략=auto로 보정하지 않음 |
| SpecifiedLineBreak.lines | List<String>, 필수·현재 구현 | 한 줄도 manual. join('')==sourceText, 임의 trim·공백 추가 금지 |
| AppliedLayoutCriteria.appliedCriteriaId | String, 필수 | 불변 실제 적용 기준 스냅샷 ID |
| areaCriteria | 영역 ID별 AppliedAreaCriteria 목록, 필수 | 정렬·줄 수·여백·글꼴/크기·자폭·커터 조건 등 실제 사용 규칙. 세부 단위·타입은 첫 지원 규칙 결정 후 정의 |
| patterns | List<AppliedTextPattern>, 필수 | 실제 적용 후보 범위·문구 조건·줄 제약·출처. 없음은 명시적 빈 목록이며 미해석을 빈 목록으로 바꾸지 않음 |
| AppliedAreaCriteria / AppliedTextPattern의 출처 | 속성/항목별 AppliedSource 목록 | 실제 값과 출처를 함께 보존. 공용 최신값 재조회로 대체하지 않음 |

DesignGeometry·AppliedAreaCriteria 같은 이름은 필요한 업무 내용의 위치를 나타내며 이번에 빈 인터페이스·범용 map을 만들라는 뜻이 아니다. 구체 지원 도형·규칙을 결정한 만큼만 후속 구현한다. 한 영역의 모든 줄은 같은 글자 크기, 줄별 자폭을 사용한다(논리 2장). 이전 예시의 minFontHeightMm/minWidthScale 두 필드만으로 전체 기준·커터·공간 검사·출처를 표현한다고 간주하지 않는다.

### 4.3 결과·계산 스냅샷·확인

| 타입·필드 | 타입·필수/기본 | 의미·관계 |
|---|---|---|
| CalculationInputSnapshot.inputId | String, 필수 | 자체 입력+그룹 구성+계산 환경 전체 불변 내용의 식별자 |
| productId / localInputId | String / String, 필수 | 어떤 제품의 어느 자체 입력 세대인지 |
| design / criteria / textInputs | 도안·적용 기준·입력의 불변 값, 필수 | 실제 사용 내용을 해석 가능하게 보존. 현재 공용값이 아님 |
| groupContexts | List<GroupContextSnapshot>, 필수 | 공동 선택의 전체 참여자와 관련 입력. 독립 계산임이 확인된 경우만 빈 목록 |
| environment | CalculationEnvironmentSnapshot, 필수 | 폰트/측정 자료 식별·엔진 식별·탐색 조건의 실제 내용 또는 재현 가능한 스냅샷 |
| GroupContextSnapshot.members | List<GroupMemberInput>, 필수 | productId+areaId와 관련 자체 입력 내용/세대를 포함. 참여자 집합은 완전해야 하며 순서 의존이면 선택 순서도 보존 |
| groupingContract | 식별/설정 값, 필수·세부 미정 | 어떤 기준·지원 범위로 공동 선택했는지. 문구 유사도 알고리즘을 이 문서에서 확정하지 않음 |
| LayoutResult.resultId / inputId | String / String, 필수 | 결과 ID / 사용한 전체 계산 입력 ID |
| inputSnapshot | CalculationInputSnapshot, 필수 | ID만으로 대체하지 않는 계산 근거. 문서 내 불변 풀 참조로 중복 제거할 수 있으나 해석 시 전체 내용 확보 필수 |
| assessment / diagnostics | LayoutAssessment / List<LayoutDiagnostic>, 필수 | normal/advisory 후보. 원래 판정·사유 보존, 기본 normal 없음 |
| areas | List<AreaLayout>, 필수 | areaId와 실제 줄·크기·자폭·위치. 입력 영역 누락·중복 금지 |
| EngineIdentity.name / version | String / String, 필수 | 실제 계산 환경 식별. 저장 형식 버전과 독립 |
| OperatorReview.resultId | String, 필수 | 같은 제품의 현재 resultId와 일치 |
| reviewedAt / operatorReference | DateTime / String?, 필수 / 기본 null | 명시 확인 시각(UTC JSON 후보) / 선택 작업자 정보. 계정 등록 필수화 없음 |

LayoutDiagnostic은 code·message와 선택 areaId, 원문 구간·대상 홀·영역 정보가 필요한 진단의 구조를 구분한다(F06/F11). 문자 위치 단위는 미정이므로 임의 int offset으로 확정하지 않는다. AreaLayout은 areaId와 줄별 원문 연결·동일 영역 글자 높이·줄별 자폭·위치를 보존한다. 커터·크기 제한을 벗어난 참고 배치도 원문·홀·허용 경계 필수 조건을 위반할 수 없다. 검사 불가를 참고 정상처럼 수락하지 않는다.

배치 없음·계산 불가·탐색 미완료는 WorkSession의 CalculationOutcome으로 구분한다. 미완료 탐색에서 후보가 관찰돼도 완료 LayoutResult로 승격하지 않는다. 다른 영역의 정상 결과는 영역별로 유지할 수 있으나 제품 단위 완료 결과·확인은 영향 영역과 실제 의존성이 모두 해결된 뒤 새로 구성한다. 한 영역 변경 때문에 관련 없는 영역까지 다시 계산해야 한다는 뜻은 아니다(F13~F15).

EngineIdentity.kind의 calculated/syntheticFixture 구분은 제거한다. 실제 업무에서 합성 결과를 제품 파일에 혼합 관리해야 한다는 근거가 없고, 자가 선언 필드는 진실성 보증도 아니다. 합성 예제는 Markdown 설명·테스트 디렉터리·픽스처 메타데이터에서만 구분한다. 테스트가 정상 모델의 직렬화를 검사할 수는 있으나 이를 실제 엔진 검증이라고 보고하지 않는다. 운영 수락은 정해진 엔진 연결 경로·스냅샷 대조·도메인 검사로 제한하며 합성 여부 enum을 승인 대용으로 쓰지 않는다.

## 5. 추가·삭제·그룹 이동과 결과 무효화

도안 공유와 자동 그룹은 별개다. 같은 도안을 쓴다고 모든 문구가 같은 그룹인 것은 아니며 다른 도안을 쓴다고 문구 패턴을 재사용할 수 없는 것도 아니다. 점검표 D12는 같은 디자인·배치 조건의 통일성 검토를 초기 권장안으로 둔다. 구체 그룹 키·유사도·영역 역할 선정은 엔진 계약과 실제 사례에서 결정한다. 표시 label이나 목록 위치를 본문 역할로 사용하지 않는다.

변경 전/후의 참여 집합을 비교하고, 이전 그룹의 남은 참여자와 새 그룹 참여자·실제 의존 영역을 함께 확인한다. 그룹에 참여하는 단위는 단순 productId가 아니라 productId+areaId다. 한 제품의 직접 지정 영역과 자동 영역을 구분한다.

| 변경 | 대상 선정·처리 | 유지할 것 |
|---|---|---|
| 제품 추가 | 새 제품 결과 없음. 새 자동 참여자가 들어가는 그룹과 실제 의존 기존 영역 무효화 | 관계없는 제품, 기존 수량·직접 지정 줄 구성 |
| 제품 삭제 | 삭제 전 그룹 구성 확보 후 제거. 기존 그룹의 남은 참여자와 삭제 항목에 의존한 결과 무효화. 삭제 제품의 요청 취소 | 다른 독립 그룹·파일 |
| 자동 문구·도안·기준 변경으로 그룹 이동 | 이전/새 그룹 영향 영역의 합집합, 자기 영역과 실제 의존 대상 무효화 | 관계없는 영역의 완료 배치 |
| 자동→직접 지정 | 기존 자동 그룹에서 제외하고 남은 구성 재검토, 해당 영역은 지정 줄로 맞춤 필요 | 다른 직접 지정 영역, 패턴 원본 |
| 직접 지정→자동 | 새 자동 그룹과 해당 영역 검토 | 다른 영역의 직접 지정 방식 |
| 직접 지정 문구·줄 변경 | 해당 영역과 실제 계산 의존 대상만 무효화. 공동 자동 줄바꿈 기준으로 전파하지 않음 | 다른 자동 그룹 결과·공용 패턴 |
| 적용 도안 선택 변경 | 선택 제품의 영향 영역 및 이전/새 그룹 재검토 | 명시 대상 밖의 도안 참조·직접 지정 줄 입력 |
| 수량·출력 표현·제품 순서·표시 이름 | 배치 입력 세대 유지, 출력 구성만 갱신 | 현재 결과·판정·사유·확인 |

제품 단위 결과가 달라지면 기존 OperatorReview는 해제한다. 여러 제품 확인을 한 번에 받는 UI도 각각의 resultId에 기록해야 한다. 입력을 되돌려도 새 세대이며 이전 결과/확인을 자동 복구하지 않는다.

그룹 계산이 아직 구현되지 않은 첫 단계에서 전체 자동 제품 무효화를 임시 대안으로 제안했던 내용을 제품 계약으로 고정하지 않는다. 정확한 영향 범위를 판별할 수 없는 기능은 미지원/재계산 필요를 표시하고 기존 결과를 현재로 수락하지 않는다. 첫 구현은 그룹 계산기를 가짜로 만들지 않고 확정된 독립 입력·줄 지정 값부터 시작한다.

## 6. ID와 불변 입력 내용의 대응

### 6.1 ID의 의미와 발급

- appliedDesignId / appliedCriteriaId: 적용 내용의 불변 스냅샷 식별자. 같은 ID로 다른 내용을 덮어쓰지 않는다.
- localInputId: 제품 자체의 배치 입력 세대. 원문·방식·직접 지정 줄·실제 배치 도안/규칙 변경 시 새 값. 단순 수량/출력 순서 변경은 유지한다.
- inputId: 실제 한 결과의 **전체 CalculationInputSnapshot** 식별자. 그룹에 누가 들어오거나 나가도 전체 내용이 바뀌므로 새 값. 자신의 localInputId가 같더라도 그룹 변경으로 inputId는 바뀔 수 있다.
- resultId: 수락된 결과의 식별자. 새 계산 결과 수락 시 새 값. review는 여기에 연결한다.
- sessionId / requestId: 라이브 요청 수락용 메모리 값. 열 때 새 sessionId, 요청 때 새 requestId. 저장 결과를 열기 위해 과거 요청을 재개하지 않는다.

각 ID는 입력 내용의 암호학적 해시라고 가정하지 않는다. 내용 해시·정규 JSON·실수 정밀도 규약은 도입 전 별도 결정한다. 원문에는 정규화·trim을 하지 않으며 구조 비교에서 리스트 순서의 의미와 집합으로 비교할 항목을 구분한다.

### 6.2 스냅샷과 현재 입력의 대조

제품의 참조·문구를 현재 문서의 불변 도안·적용 기준으로 해석한 **현재 배치 입력 내용**과 결과가 보유한 inputSnapshot을 비교한다. 참조 ID 문자열이 같은지만 비교하지 않는다. 저장 시 스냅샷을 중복 제거하더라도 읽을 때 실제 값까지 해석 가능해야 하며 공용 폴더·현재 엔진 기본값 재조회에 의존하지 않는다. 결과의 design/criteria 스냅샷과 현재 문서의 같은 ID 값이 다르면 정합성 오류다.

그룹 스냅샷은 전체 productId+areaId 참여자와 각자의 관련 입력을 담고, 다른 결과의 resultId나 inputSnapshot을 재귀 참조하지 않는다. 자체 입력 스냅샷을 공유 풀로 재사용해도 ID→내용 대응은 하나여야 한다. 참여자 삭제, 같은 ID의 다른 내용, 누락 영역, 중복 참여자는 오류다. 추가 참여자 감지는 저장된 옛 의존 맵만 훑어서 해결할 수 없다. 세션의 변경 전/후 그룹 구성 비교로 새 참여자도 발견해야 한다.

### 6.3 실제 검사 범위와 한계

| 단계 | 반드시 확인 | 이 단계만으로 보장하지 못하는 것 |
|---|---|---|
| 계산 요청 | sessionId·requestId, 현재 자체 입력·완전한 그룹·측정/엔진/탐색 스냅샷 캡처 | 아직 실행하지 않은 계산의 성공 |
| 결과 수락 | 활성 요청·현재 세션·제품 존재, inputId와 캡처 내용 일치, 현재 입력/그룹과 깊은 비교, 영역별 필수 검사·진단 | 자가 선언 ID만으로 실제 엔진 실행 증명 |
| 저장 문서 구성 | 모든 제품 완료·현재 스냅샷 일치, 중복 ID/내용 충돌 없음, 필요한 resultId별 확인 | 디스크 교체·Drive 장애 복구 |
| JSON 열기 | 지원 형식/구조, ID 유일성, 참조 해석, 제품/영역 연결, 현재 입력 대 결과 스냅샷 내용, 그룹 참여자 존재/입력, 원문 연결·수치 범위·판정/확인 연결 | 실제 최적 배치·글리프 공간 검사의 재실행, 적대적 문서의 진실성 |
| 재계산 | 저장 당시 환경 식별을 보존한 채 사용할 측정·엔진과 지원 여부 확인, 변경은 명시적 선택 | 구버전 결과를 현재 엔진 결과로 이름만 바꿔 사용 |

그룹 구성 알고리즘이 없는 오프라인 읽기에서는 저장된 그룹 참여자·입력의 내부 정합성은 검사할 수 있지만 **새로 삽입된 제품이 의미상 그 그룹에 들어가야 하는지**까지 독립 검증했다고 주장하지 않는다. 현재 그룹 정책의 지원 검증기가 있다면 현재 구성과 비교하고, 없다면 그 한계를 표시하며 변경 후 공동 계산·저장을 허용하지 않는다. 원본의 F37처럼 바뀐 입력+오래된 결과는 확인 가능한 내용 비교에서 거부한다. 입력·결과·스냅샷을 함께 위조한 파일까지 증명하는 서명/감사 체계는 현재 요구가 아니다.

재열기는 엔진이나 폰트가 현재 설치되어 있지 않아도 저장 내용의 내부 검증과 표시를 할 수 있게 한다. 재계산 가능 여부와 저장 결과 재개 가능 여부를 혼동하지 않는다. 측정 자료·엔진이 다르면 자동 대체하지 않고 재계산 시 지원/변경을 확인한다(논리 3장, F31/F37).

## 7. 여전히 결정해야 할 사항

| 항목 | 원본 대조로 해소한 것 | 남은 판단과 추천 |
|---|---|---|
| 도안 소유권 | 같은 적용 도안 공유, 한 제품 변경은 분리, 전체 변경은 명시 | ID 발급·복제 도구 API, 영역 추가/삭제 매핑 UI, 사용하지 않는 스냅샷 정리 방식 |
| 형상·규칙·패턴 | 형상/영역과 결합 기준·패턴 분리 | 지원 도형과 영역 표현·좌표 원점·기준점·정밀도. 직사각/원형 홀 시험을 전체 지원으로 확대하지 않음 |
| 줄바꿈 입력 | 자동/직접 구분, 직접 지정 한 줄 유지, 원문 연결·동시 갱신 | 첫 영역 입력 구현은 List<String> 줄 조각을 채택했다. 빈 원문·빈 줄·내장 CR/LF는 구분된 오류로 미지원 처리한다. 이는 첫 지원 제한이며 전체 정책은 보류한다. 부분 경계·실행 취소도 별도다. 문자 위치 단위는 UTF-16/scalar/grapheme 선택과 버전 계약 필요 |
| 결과 진단 | 정상·참고·배치 없음·계산 불가·탐색 미완료 구분 | 엔진 실제 상태 매핑·원문 범위 직렬화·정밀 공간 검사 경계 |
| 그룹 변화 | 추가/삭제·이전/새 그룹 영향 검토 방향 | 점검표 N08/D09/D12는 초안/권장안. 유사도·그룹 키·영역 역할·의존 세분화는 미정 |
| 수량·출력 | 주문량/파일 제작량/그린 개수 분리, 복제/명판 밖 수량 표시, 누락 가져오기 보정 금지 | 직접 신규 항목 1 제안, 0·빈 값·취소 수량 정책, 구체 출력 위치·enum명 |
| 공용 기준 | 실제 결합값·출처·지정 의도 유지, 자동 적용 금지 | 지원할 첫 규칙의 필드/단위, 비포함 패턴 충돌, 측정 자료 식별 규약 |
| 저장·ID | 전체 제품 완료 조건, 결과별 확인, 불변 내용 연결 | 최초 formatVersion·호환 정책·빈 문서·동일 내용 ID 재사용 규약 |

원본에서도 미정인 문자 위치를 Dart String 인덱스에 맞춰 UTF-16으로 조용히 확정하지 않는다. 입력 줄 조각의 정확한 join 비교는 가능하나 진단 위치·엔진 범위 교환 단위 결정은 별도다. 이름과 타입도 원본의 예시를 확정 API로 승격하지 않는다.

## 8. 수정 관계를 보여 주는 두 제품 JSON 예시

**아래는 실제 엔진 결과가 없는 합성 설명 자료이며 완전한 WorkDocument 저장 예제가 아니라 참조 관계를 보여 주는 발췌다.** 형상·적용 기준·계산 환경·결과 입력 스냅샷의 세부 계약이 미정이므로 이를 가짜 정상 결과나 빈 스냅샷으로 채우지 않았다. 운영 객체에 syntheticFixture·exampleKind 필드를 추가하지 않는다. 합성 여부는 이 설명과 향후 테스트 픽스처의 위치/메타데이터에서만 구분한다.

```json
{
  "appliedDesignReferences": ["design-shared-1"],
  "appliedCriteriaReferences": ["criteria-1"],
  "products": [
    {
      "productId": "product-a",
      "appliedDesignId": "design-shared-1",
      "appliedCriteriaId": "criteria-1",
      "localInputId": "local-a-1",
      "textInputs": [{
        "areaId": "area-title",
        "sourceText": "MAIN PUMP",
        "lineBreak": {"mode": "automatic"}
      }],
      "quantities": {"orderQuantity": 10, "fileProductionQuantity": 10},
      "outputMode": "quantityAnnotation"
    },
    {
      "productId": "product-b",
      "appliedDesignId": "design-shared-1",
      "appliedCriteriaId": "criteria-1",
      "localInputId": "local-b-1",
      "textInputs": [{
        "areaId": "area-title",
        "sourceText": "PUMP  A-1 ",
        "lineBreak": {"mode": "specified", "lines": ["PUMP  A-1 "]}
      }],
      "quantities": {"orderQuantity": 2, "fileProductionQuantity": 1},
      "outputMode": "repeatedGeometry"
    }
  ]
}
```

appliedDesignReferences/appliedCriteriaReferences는 이 발췌의 해석 안내용 ID 목록이며 실제 문서 필드가 아니다. 실제 문서는 appliedDesigns/appliedCriteria에 전체 스냅샷을 보존하고 결과마다 완전한 계산 입력·배치·판정·확인을 가진다. 발췌에 없는 결과를 완료로 간주하지 않는다. product-b만 치수 변경하면 design-shared-2를 새로 만들고 b의 참조/localInputId만 교체하며 a의 도안 참조는 그대로다. 그룹에 실제 영향이 있다면 a의 계산 inputId/결과는 별도로 무효화될 수 있다. 직접 지정 한 줄과 원문의 연속·끝 공백은 유지한다.

기존 완전 JSON처럼 보이던 직사각·단순 규칙 예시는 공유 참조·전체 계산 근거를 표현하지 못해 이 발췌로 교체했다. 완전한 저장 JSON은 형상·규칙·환경·위치 표현의 첫 지원 단면을 확정한 뒤 작성한다.

## 9. 원본 대조 당시 제안한 첫 범위 (현재 구현은 13절)

**첫 범위는 영역별 원문과 자동/직접 지정 줄바꿈 값의 모델·검증·JSON 왕복**을 추천한다. TextAreaInput(areaId, sourceText, lineBreak)과 AutoLineBreak/ManualLineBreak 후보만 구현하고 문구+줄 구성의 원자적 변경 및 정확한 join 일치를 확인한다. 직접 지정 한 줄·앞뒤/연속 공백·기호·대소문자·한국어·결합 문자·이모지, 잘못된 줄 조각·알 수 없는 방식·필수 누락을 실제 테스트로 확인한다. 수량·도안·엔진 결과를 가짜로 붙여 WorkDocument 전체를 먼저 구현하지 않는다.

첫 범위 착수 때 줄 조각 표현과 빈 문구/빈 줄/CRLF의 지원·오류 정책을 명시한다. 진단의 문자 오프셋을 구현하지 않아 위치 단위 미정을 숨기지 않는다. 이 작은 왕복 포맷은 전체 작업 파일 형식이나 미완료 작업 저장 기능이 아니다.

그다음 별도 범위로 불변 적용 도안 공유·명시 대상 분리 명령을 구현하려면 먼저 첫 도형·영역·제작 조건 단면을 정한다. 결과/확인 수명 구현은 위 그룹·환경 스냅샷 계약이 지원되는 만큼 순차 진행한다. 실제 엔진·DXF·파일 교체·Drive·UI·공용 등록부·학습은 이번 첫 범위 밖이다.

## 10. 원본 대조 당시 문서 검증과 제한

원본/추출본 존재·값 포함 대조, 관련 문서 상대 링크, JSON 발췌의 문법·제품 2개·공유 도안 ID·기준 참조·원문/직접 지정 한 줄 연결을 확인했고 모두 통과했다. git diff --check도 통과했다. 앱 Git 상태와 두 Office 원본 해시는 시작 시와 같았다. 이는 문서 검사이며 실제 Dart 모델·저장 결과·그룹 계산 검증이 아니다. Dart/Flutter 분석·테스트는 코드 변경이 없어 이번에는 실행하지 않는다. 앱 파일·코드·의존성·Git 이력을 수정하지 않으며 커밋·푸시하지 않는다. 관련 계약과 다음 작업만 이 설계에 맞춘다.

## 11. 최초 영역 입력 구현 기록 (2026-10-19, 현재 도구는 12절)

이 절은 앞 절의 제안 중 이번에 구현한 부분을 구분한다. 설계 후보 ProductTextInput은 제품 전체가 아닌 영역 입력을 뜻하도록 **TextAreaInput**으로 정했다. LineBreakSpec은 자동/직접 지정의 합 타입이고 AutoLineBreak/ManualLineBreak는 명시적 입력 방식이다. 나머지 WorkDocument·도안·그룹·결과 설계는 여전히 미구현이다.

- TextAreaInput(areaId:String, sourceText:String, lineBreak:LineBreakSpec): 모두 필수이고 areaId는 비어 있지 않다. 원문과 ID를 정규화하지 않는다. 표시 이름·원문 기반 ID 발급도 없다.
- ManualLineBreak(List<String>): 비어 있지 않은 지정 목록을 방어 복사해 수정 불가로 보관한다. 빈 줄과 CR/LF는 미지원이다. TextAreaInput 생성 시 join 결과와 sourceText의 정확한 일치를 추가 검사한다. 한 줄도 manual이다.
- 모든 필드는 final이고 원문/지정 줄의 개별 setter·부분 copyWith가 없다. 유효한 새 객체를 구성해 원자적으로 교체한다. 값 동등성과 hashCode를 제공한다.
- 빈 원문·빈 줄·원문/줄 조각의 CR/LF는 각각 emptySourceText·emptyManualLine·sourceContainsCrLf·manualLineContainsCrLf로 구분한다. 공백만 있는 문자열과 탭은 지원한다. 전체 제품의 빈 문구·개행 정책은 보류 상태이며 이번 제한을 확정 정책으로 확장하지 않는다.
- TextInputException(code:TextInputErrorCode, path:String)이 첫 오류를 전달한다. missingField, invalidType, unknownMode, unexpectedField, emptyAreaId, emptyManualLines, manualTextMismatch도 구분한다. path는 필드/지정 줄 목록 위치이며 문자 오프셋이 아니다.
- fromJson(Object?) / toJson()은 areaId, sourceText, lineBreak.mode와 manual의 lines만 다룬다. 누락·알 수 없는 방식은 auto로 바꾸지 않으며 알려지지 않은 필드/auto의 lines도 거부한다. 상세 예시와 오류 계약은 README와 contract.md에 기록했다.
- Dart 기본 JSON 변환을 사용해 새 의존성 없이 구현했다. 이 작은 형식은 전체 작업 파일 스키마·임시 저장·파일 I/O가 아니다. 합성 여부는 테스트/예제 설명에서만 구분한다.

단위 검증 성공은 배치 가능·제작 가능·결과 저장 승인과 무관하다. 문자 위치 단위나 오프셋은 확정/구현하지 않았다. 적용 도안·영역 참조의 실제 존재 검사는 후속 범위다.

실제 검증은 Dart SDK 3.12.2의 pub get·format·analyze·test로 수행했다. 초기 AutoLineBreak hashCode의 정적 접근 오류를 발견해 수정한 뒤 분석 문제 없음, 테스트 64개 통과를 확인했다. 테스트는 공개 진입점을 사용해 자동/직접 한 줄/여러 줄 JSON 문자열 왕복, 공백·기호·Unicode 표현과 반복 원문, 오류 구분·이번 미지원 입력·외부 목록 변경 방어·원자적 교체를 확인한다. 과거 Python 시험이나 실제 엔진 검증과 구분한다.

다음 한 가지 작업은 첫 도형·영역·제작 조건의 지원 단면과 영역 ID 대응을 설계에서 정하는 것이다. 그 뒤에 적용 도안 공유와 명시 대상 분리 모델을 구현할 수 있다. 현재 단계에서 전체 문서·세션·그룹·배치 결과·엔진·DXF·Flutter 연결을 미리 만들지 않는다.

## 12. Freezed 채택과 타입 계약 유지 (2026-10-20)

사용자의 이번 결정으로 불변 값 반복 코드에는 Freezed, JSON 필드 변환에는 json_serializable을 채택했다. 실제 TextAreaInput과 AutoLineBreak/ManualLineBreak에 적용했고 LineBreakSpec은 sealed 타입으로 유지한다. 비교의 mode:String+nullable lines 구조는 운영 모델로 가져오지 않았다.

현재 이름·생성자·필드·JSON·오류 code/path와 첫 미지원 구분은 그대로다. TextAreaInput/ManualLineBreak에 생성된 copyWith가 추가됐으며 두 생성자에서 직접 검증하므로 잘못된 부분 변경은 예외다. 줄 구체 타입 수정 뒤 부모 입력에 반영할 때도 원문 연결을 검사한다. 무필드 AutoLineBreak는 const 생성자를 유지하고 copyWith가 없다. 기존 문서의 부분 copyWith 없음은 초기 수동 구현 당시 기록이다.

필드 변환·값 비교는 생성기에 맡겼고 수동 코드는 업무 검증·오류 경계·sealed 분기·외부 목록 방어에 둔다. 생성 파일은 Git 관리 대상, SDK·캐시·빌드·라이브러리 lock은 제외한다. 문자의 위치/경계 단위, 빈 원문·빈 줄·CR/LF의 전체 정책은 결정하지 않았다. 이번 미지원 처리와 공백만/Unicode 보존은 그대로 유지한다.

영구 .toolchains/flutter-3.47.7의 포함 Dart 3.13.5에서 생성·포맷·분석, 기존 64개+추가 6개 테스트, assert 비활성 AOT 12건과 생성 없는 소비자 검사를 통과했다. 실제 Git 참조 앱·IDE UI·Flutter 릴리스 UI는 이번에 실행하지 않았다. 자세한 선택 버전·명령·재생성 결과·소비자 범위는 [전환 기록](freezed-migration.md), 채택 기준과 현재 이름/필드/오류 후보는 [개발 기준](development-rules-draft.md)에 있다.

다음 한 가지 설계 작업인 도형·영역·제작 조건의 첫 지원 단면은 그대로 남아 있다. 이번에는 새 형상·업무 흐름·엔진·UI를 추가하지 않았다.

## 13. 초기 네이밍·JSON 정리 (2026-10-20)

현재 구현은 [네이밍·JSON 정리](input-naming-json.md)와 [현재 계약](contract.md)을 따른다. 9~12절은 당시 이름과 실행 사실을 보존한 기록이며 현재 API 설명이 아니다.

TextAreaInput의 lineBreak는 sealed LineBreakInput이며 AutomaticLineBreak / SpecifiedLineBreak로 구분한다. JSON mode는 automatic / specified만 지원하고 이전 auto/manual은 거부한다. TextInputValidationException은 code와 fieldPath를 제공한다. 오류 코드 변경은 현재 정리 기록에 명시한다. 구형 형식 지원·별칭·마이그레이션은 없다.

JSON 경계는 구조·필수·타입·방식을 검사하고 생성자는 업무 조건을 검사한다. 루트에서 줄바꿈 값을 미리 생성하지 않으며 생성된 필드 변환을 통해 한 번 복원한다. 복수 오류 순서는 계약으로 정하지 않는다. 생성·copyWith·복원에서 검증, 원문 보존·방어 복사·직접 지정 한 줄·빈 원문/빈 줄/CR/LF의 첫 지원 제한은 유지한다. 전체 제품 정책과 문자 위치 단위는 계속 보류한다.
