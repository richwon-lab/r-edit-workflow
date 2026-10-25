# 적용 도안과 텍스트 영역의 첫 데이터 구조 설계

2026-10-21. 문서 제안이며 업무 코드·새 공개 API·전체 작업 파일 스키마가 아니다. **현재 확정한 관계, 이번 첫 지원 제안, 결정이 필요한 정책을 아래에서 구분한다.** 전체 제품의 최종 형상 지원 범위를 정하지 않는다.

## 1. 자료와 현재 상태

대상은 C:/work/richwon/r_edit_workflow, master, 시작 HEAD `5ea2c81694643b21fd266a5e69a67a32f09cc2c5`다. 시작 작업 트리와 스테이징은 깨끗했다. AGENTS.md, README.md, docs/contract.md, docs/model-design.md, docs/development-rules-draft.md, docs/next-step.md를 읽었다. 기존 입력 API는 [현재 네이밍·JSON](input-naming-json.md)을 따른다.

형제 앱 C:/work/richwon/r_edit의 HEAD는 `358a66ab3b307b5e91671d98875228a4ae25b149`이며 시작 작업 트리·스테이징은 깨끗했다. docs/README.md가 연결한 다음 자료의 제공 텍스트 추출본을 읽었다. 원본은 실제 존재와 해시를 확인했고 Office 렌더링·이미지·도형은 이번에 검사하지 않았다. 이전 원본 XML 대조 결과는 model-design.md 1절의 과거 기록이며 이번 재실행 결과가 아니다.

| 자료 | 앱 루트 기준 실제 경로 | 이번에 읽은 범위 |
|---|---|---|
| 데이터 논리 설계 | docs/development-reference/reference/current/리치원_도안데이터_논리설계_초안_v0.1.docx | 아래 추출본 사용 |
| 논리 설계 추출본 | docs/development-reference/reference/text/리치원_도안데이터_논리설계_초안_v0.1.txt | 1~11장 본문·표 |
| 기능 점검표 | docs/development-reference/reference/current/리치원_기능활용_점검표_v0.1.xlsx | 아래 추출본 사용 |
| 점검표 추출본 | docs/development-reference/reference/text/리치원_기능활용_점검표_v0.1.txt | 두 시트 F01~60, N01~17, D01~13 |
| 현재 결정·모듈 경계 | docs/decisions.md, docs/module-boundaries.md | 최신 합의와 책임 |

원본 SHA-256: 점검표 `C4B98376FE55452C4F5B98DFC5E9598672513D3488B1BB4C8F14D3116B496EBE`, 논리 설계 `665DA4651EE0B68165EACA844BC80E354B094ED4EB039A82E916D6D2DD86D55C`. 요구사항 정의서·설계 검토서·모든 과거 시험 원문까지 이번에 재검토한 것은 아니다. 최신 사용자 결정이 자료보다 우선한다.

## 2. 확정·제안·미정

| 구분 | 내용 | 근거·적용 범위 |
|---|---|---|
| 확정된 관계 | 적용 도안이 외곽·홀·영역과 제작 적용값을 소유. 제품이 문구·줄바꿈 입력을 소유 | 논리 2·5·11장, 현재 계약 |
| 확정된 변경 원칙 | 불변 도안 공유, 개별 변경은 새 참조, 전체 변경은 명시적 대상 집합, 자동 비례 확대 없음 | 논리 5장 |
| 확정된 경계 | 규칙·문구 패턴은 형상과 별도. 엔진·DXF는 작업 파일 저장 형식에 의존하지 않음 | 논리 5·6·10장, 모듈 경계 |
| 이번 제안 | mm, 명판 왼쪽 아래 원점, 오른쪽 +X/위쪽 +Y, 축에 평행한 직사각 외곽·영역, 원형 홀 목록 | 사용자 설계 출발점을 첫 지원안으로 구체화. 아직 구현 승인·최종 제품 지원 범위가 아님 |
| 이번 제안 | 단순 명시 필드와 불변 목록, double, 영역/홀의 안정 ID, 아래 값 검증 | 새 모델 이름·세부 JSON은 제안 |
| 미정 | 홀-외곽 접촉, 홀끼리 접촉/중첩, 영역끼리 겹침의 정책·계산 허용오차·제작 최소 여백 | 값을 채워 확정하지 않음 |
| 미정 | 첫 제작 조건의 구체 타입/필드·필수 여부, 출처 규약, 형상 오류 코드와 진단 API, 형상 JSON 판별 방식 | 이번에 범용 map·빈 인터페이스·가짜 production을 만들지 않음 |

N09는 일반 도안 편집 연결 미확인, N10은 곡선 외곽·장식·영역 간 충돌 범위 밖이다. 이번 안으로 표현할 수 없는 라운드 모서리, 다각형/곡선/복수 외곽, 장공·사각 홀, 회전/비직사각 텍스트 영역, 장식·기존 DXF 태그/선폭/곡선 계수 보존은 미지원으로 드러낸다. 외접 직사각이나 빈 홀로 치환하지 않는다. F58의 기존 CAD 읽기 시험을 이 구조의 임의 CAD 재현 보장으로 해석하지 않는다. N11의 글자 획 빈 공간에 홀 끼워 넣기 제외도 유지한다.

원본과 직접 충돌하는 사항은 찾지 못했다. 다만 단순 형상 구조로 전체 CAD 형상·제작 공정·F45의 정렬/고정 기준선·커터 조건을 표현할 수는 없다. 정렬·여백·기준선·폰트·줄 수·커터는 영역 사각형의 필드가 아니라 별도 적용 배치 기준에 둔다. 기존 Python 시험 통과를 새 Dart 제품 구현 완료로 바꾸지 않는다.

## 3. 좌표와 단위

모든 길이·명판 내 좌표는 mm다. 외곽은 (0,0)~(widthMm,heightMm), 영역의 xMm/yMm는 **명판 좌표의 왼쪽 아래**, 홀은 중심 centerXMm/centerYMm와 diameterMm로 표현한다. 영역 로컬 좌표를 저장하지 않아 이 단계의 이중 원점을 피한다. 회전값은 지금 필드·기본 0으로 만들지 않고 축 평행 형상만 지원한다고 명시한다. 반지름은 diameterMm/2로 계산하며 중복 저장하지 않는다.

화면 픽셀·Flutter 논리 픽셀·줌/패닝은 앱 상태다. 회전 없는 화면의 예로 원점 화면 위치를 (ox,oy), 축척을 s 픽셀/mm라 하면 화면점은 (ox+s*x, oy-s*y)다. 사각형 화면 위쪽은 yMm+heightMm를 써서 변환한다. 화면 역변환도 앱 책임이다. DPI나 줌을 도안 치수에 곱해 저장하지 않는다. 순수 Dart 모델은 Flutter Rect/Offset/Size나 dart:ui를 가져오지 않는다.

DXF 문서 안에서 여러 명판을 배열할 때도 명판 좌표는 유지한다. 출력 구성에서 명판별 배치 변환을 정하고 DXF 경계에서 외곽·홀·완료 글자 좌표에 동일하게 적용한다. 단순 이동 예는 (dx+x,dy+y)다. 회전·반전·축척 지원과 문자 방향 규약은 향후 별도 결정이며 자동 보정하지 않는다. DXF 단계에서 문구 맞춤을 다시 계산하지 않는다.

## 4. 모델·필드·불변식 제안

다음은 Dart 타입 후보다. '필수'는 값을 명시해야 한다는 뜻이며 자동 0/빈 목록 기본값을 뜻하지 않는다. 숫자에는 저장용 반올림을 하지 않는다. 컬렉션은 전달 목록을 방어 복사하고 외부 수정 불가로 보관하며 출력 JSON도 분리한다. 실제 구현 시 Freezed/json_serializable과 런타임 검증을 사용한다.

| 모델·필드 | 타입·단위 | 필수/기본 | 의미·불변식 |
|---|---|---|---|
| AppliedDesign.appliedDesignId | String | 필수, 기본 없음 | 작업 안 불변 적용 스냅샷 ID. 같은 ID로 내용 교체 금지. 문구·표시명에서 만들지 않음 |
| AppliedDesign.geometry | RectangularPlateGeometry | 필수 | 외곽과 홀을 소유. 직사각 외곽 종류는 구체 타입에 드러남 |
| AppliedDesign.areas | List<TextAreaDefinition> | 필수 | 임의 개수, 순서로 식별하지 않음. areaId는 이 도안 안 유일 |
| AppliedDesign.production | AppliedProductionConditions (논리 후보) | 상세 미정, 가짜 기본 없음 | 동일 적용 도안의 공유 제작 조건. 구체 지원 전 최소 형상 구현에 억지로 포함하지 않음 |
| AppliedDesign.source | AppliedSource? (기존 논리 후보) | 직접 작성은 명시적 출처 없음 가능 | 공용 출처와 실제 적용 내용은 구분. 출처만으로 내용을 재조회하지 않음. 필드 규약 후속 |
| RectangularPlateGeometry.widthMm / heightMm | double / mm | 모두 필수 | 각각 유한하고 >0. 외곽 원점은 이 지원안의 고정 규약이므로 x/y 중복 저장 안 함 |
| RectangularPlateGeometry.holes | List<CircularHole> | 필수 | 개수 고정 없음. []는 명시적 '홀 없음', 미해석/누락과 구분 |
| CircularHole.holeId | String | 필수 제안 | 도안 안 유일한 홀 식별자. 진단·변경 대상 연결. 중심/목록 위치에서 생성하지 않음 |
| CircularHole.centerXMm / centerYMm | double / mm | 모두 필수 | 유한 좌표. 단독 값 모델은 음수도 표현 가능, 명판 포함은 별도 관계 검사 |
| CircularHole.diameterMm | double / mm | 필수 | 유한하고 >0. 반지름 동시 저장 금지 |
| TextAreaDefinition.areaId | String | 필수 | 비어 있지 않음. 기존 TextAreaInput.areaId와 같은 식별 규칙. 전역 유일 요구 없음 |
| TextAreaDefinition.label | String | 필수 제안, 자동 ID 대체 없음 | 표시 이름, 중복 허용. 빈 label 허용 여부는 미정이며 새 검증을 몰래 추가하지 않음 |
| TextAreaDefinition.bounds | TextAreaBounds | 필수 | 명판 좌표의 영역 사각형. 원문·폰트·정렬·패턴은 보관하지 않음 |
| TextAreaBounds.xMm / yMm | double / mm | 모두 필수 | 왼쪽 아래 좌표, 유한. 단독 값에서 음수 자체를 잘못된 숫자로 취급하지 않음 |
| TextAreaBounds.widthMm / heightMm | double / mm | 모두 필수 | 유한하고 >0. x+width, y+height도 유한한 범위여야 함 |
| 제품의 appliedDesignId | String (기존 논리 후보) | 필수 | 현재 문서 안 적용 도안 하나를 참조. 해석 실패는 오류 |
| 제품의 textInputs | List<TextAreaInput> (기존 논리 후보) | 필수 | 제품 안 areaId 중복 없음. 선택 도안의 정의와 연결, 입력 누락을 빈 원문/자동 방식으로 채우지 않음 |
| TextAreaInput.areaId / sourceText / lineBreak | 기존 공개 타입 | 기존 조건 유지 | 영역 ID·원문·명시적 줄 입력만 소유. bounds나 도안 치수를 넣지 않음 |

ID는 우선 빈 문자열을 거부하고 전달 문자열을 그대로 보존하는 기존 규약을 추천한다. 전역 ID 발급 방법·공백만인 ID에 대한 추가 정책은 이번에 만들지 않는다. areas도 개수의 고정 상한을 두지 않는 목록을 제안한다. [] 형상 데이터의 표현은 가능하되 텍스트 없는 제품의 계산/완료 문서 허용 정책을 확정한 뜻은 아니다. 실제 텍스트 계산은 대상 영역과 입력이 명시되어야 한다.

AppliedDesign은 소유 관계의 논리 모델이다. production·출처를 지원하지 않은 채 완전한 적용 도안이라고 구현 완료 처리하지 않는다. 첫 구현은 아래의 형상·영역 값까지이며 전체 AppliedDesign/제품/문서 조립은 다음 단계다.

### 이름 후보와 사용 문맥

다음 코드는 문서상 호출 모양이며 컴파일/실행한 API가 아니다. 기존 TextAreaInput 등 공개 이름은 변경하지 않는다.

| 책임 | 후보 2~3개 | 추천과 이유 |
|---|---|---|
| 적용된 불변 도안 | AppliedDesign / DesignSnapshot / AppliedTemplate | AppliedDesign. 이미 공유 관계 설명에 쓰이며 공용 원본 Template과 구분. Snapshot은 무엇의 스냅샷인지 추가 문맥 필요 |
| 직사각 외곽+홀 | RectangularPlateGeometry / PlateGeometry / PlateShape | RectangularPlateGeometry. 미지원 형상을 담을 듯한 범용 이름을 피하며 첫 지원 범위 표시 |
| 원형 홀 | CircularHole / RoundHole / HoleDefinition | CircularHole. 원이라는 수학적 형상을 명시, HoleDefinition은 형상 종류가 흐림 |
| 텍스트 영역 정의 | TextAreaDefinition / DesignTextArea / TextRegion | TextAreaDefinition. 기존 TextAreaInput과 정의/입력의 책임 대비 |
| 영역 위치·크기 | TextAreaBounds / PlateRectangle / RectangleMm | TextAreaBounds. 실제 사용 책임과 판 좌표를 문서화, RectangleMm는 여러 책임의 범용 도형처럼 커질 수 있음 |

```dart
// 미구현 API의 읽기 비교. Freezed copyWith 도입 시 호출 모양 제안.
final hole = CircularHole(
  holeId: 'hole-1', centerXMm: 10, centerYMm: 10, diameterMm: 4,
);
final area = TextAreaDefinition(
  areaId: 'area-title', label: '본문',
  bounds: TextAreaBounds(xMm: 4, yMm: 4, widthMm: 28, heightMm: 28),
);
final moved = area.copyWith(bounds: area.bounds.copyWith(xMm: 5));
final sameAreaId = moved.areaId; // 위치 수정은 영역 정체성을 바꾸지 않음
final geometry = RectangularPlateGeometry(widthMm: 36, heightMm: 36, holes: [hole]);
final wider = geometry.copyWith(widthMm: 40);
final unchangedHoleCenter = wider.holes.single.centerXMm; // 10, 자동 확대 없음
```

대안은 `DesignTextArea(rectangle: PlateRectangle(...))` / `TextRegion(bounds: RectangleMm(...))`처럼 읽힌다. 생성·수정·조회 시 Definition/Input 대비와 위치·크기 책임이 더 분명한 추천안을 제시하되 승인된 공개 API로 승격하지 않는다. 단일 사용을 위해 Point/Length/공통 Geometry 인터페이스까지 미리 만들지 않는다. 홀은 diameterMm를 추천하고 radiusMm는 대안이며 둘을 동시에 저장하지 않는다.

## 5. 검증 책임을 나누는 기준

| 단계 | 검사/처리 | 보장하지 않는 것 |
|---|---|---|
| JSON 경계 (향후) | 객체·필수·숫자 타입·지원 형상 구분. NaN/Infinity 비표준 표현 거부. 누락/알 수 없는 형상 오류 | 알 수 없는 형상을 rectangle로 보정하지 않음 |
| 값 생성자·copyWith·복원 | 유한한 좌표, 양수 길이, 빈 ID, 목록 방어 복사. 중심±반지름·영역 끝점 등 표현 가능한 파생 경계의 유한성 | 다른 형상과의 포함·간섭, 글자 배치 성공 |
| 도안 조립 | 영역/홀 ID 중복, 같은 스냅샷 ID에 다른 내용 연결 방지 | 숫자 검증만으로 제작 가능 판정 안 함 |
| 제품과 도안 연결 | 해당 appliedDesignId 존재, areaId 존재·중복 없음, 계산 대상 영역의 입력/기준 누락 검사 | TextAreaInput 단독 생성자가 도안을 조회하지 않음 |
| 형상 관계 검사 (후속) | 명판 안 영역/홀 포함, 홀끼리 관계·영역끼리 관계를 구분한 진단 | 아직 없는 검사를 통과한 것으로 표시하지 않음 |
| 배치 엔진 (후속) | 글자 후보의 영역/명판 경계·홀 회피, 글꼴 측정·규칙·크기·자폭·탐색 상태 검사 | 형상 데이터 유효성을 곧 배치·제작 승인으로 취급하지 않음 |
| 제작 검토/출력 (후속) | 실제 자재·가공 조건·출력 가능 형식 검토 | 작업자 확인으로 원래 판정·필수 홀 회피 실패를 덮어쓰지 않음 |

첫 관계 검사 제안은 영역 전체와 원형 홀 전체가 명판 안에 있는지 확인하고 명백히 외부인 항목을 계산 준비 완료로 수락하지 않는 것이다. 영역에는 x>=0, y>=0, x+width<=판 폭, y+height<=판 높이, 홀에는 중심±반지름을 이용한다. **이 식은 후보 정책 설명이며 이번에 검사기를 구현하지 않는다.** 경계에 꼭 닿는 경우 허용·제작 여유값은 미정이다. 관계 검사가 아직 없다면 상태를 '관계 미검사'로 설명하고 생성자 성공만 보고 '도안 정상'이라 부르지 않는다. 값을 잘라 넣거나 중심을 옮겨 고치지 않는다.

홀-홀 중첩/접촉은 독립 원형 홀로서의 제작 의미를 검토해야 하며 단순 허용/거부를 지금 확정하지 않는다. 영역-영역 중첩도 임의 금지하지 않고 N10의 후속 범위로 남긴다. 영역 사각형과 홀이 겹치는 것은 **허용 가능한 정의**이며 그 이유만으로 거부하지 않는다. 실제 글자가 그 홀을 피했는지는 엔진이 실제 후보와 측정 자료로 판단한다. 홀을 영역에서 빼 다각형으로 바꾸거나 겹치는 영역을 자동 분할하지 않는다. 글자 획 내부의 작은 빈 공간을 이용한 홀 끼워 넣기 알고리즘도 만들지 않는다.

저장은 입력된 double 값을 임의 소수 자릿수로 반올림하지 않는 방향이다. JSON 숫자는 복원 시 같은 지원 double 값으로 왕복하도록 향후 검증하고 원래 숫자 토큰의 표기(36.0/36.000)를 보존한다고 약속하지 않는다. 값/ID/입력 스냅샷 비교에 근사 동등성을 적용하지 않는다. 계산의 허용오차는 별도 명시 조건·단위·엔진 버전과 연결해야 하며 숫자를 몰래 이동/반올림하는 규약이 아니다. 구체 epsilon·최소 제작 여백·최대 크기/목록 제한은 미정이며 무제한 계산 자원을 보장하지도 않는다.

## 6. 영역 변경과 입력 대응

| 변경 | ID·입력 처리 | 결과 영향 |
|---|---|---|
| 같은 의미의 영역 위치/크기/label 수정 | 새 적용 도안에 동일 areaId 유지. 제품 원문·지정 줄 유지 | 실제 형상 변경은 영향 결과 무효화. label만 바뀌면 계산 조건에 넣지 않음 |
| 영역 추가 | 새 areaId, 대상 제품마다 명시적 TextAreaInput 필요 | 입력이 준비될 때까지 세션 미완료. 빈 원문/자동 입력 생성 금지 |
| 영역 삭제 | 제거될 입력과 해당 규칙을 보여 주고 명시적 삭제 또는 대응 선택 | 원문을 조용히 버리지 않음. 적용 결정 전 기존 상태 보존, 고아 참조를 유효 상태로 만들지 않음 |
| 영역 교체·다른 도안 선택 | 의미가 다른 영역에는 새 ID. 이전→새 ID 대응을 명시 | 동일 label/좌표/목록 순서로 연결 금지. 대응 없으면 세션에서 해결 대기 |
| 여러 영역 통합/분할 | 일대일 단순 대응으로 해결하지 않음 | 원문 합치기/줄 자동 분할 금지. 후속 편집 절차가 필요하며 첫 범위 밖 |
| 판 치수 변경 | 새 appliedDesignId. 홀·영역 수치와 안정 ID 유지 | 포함 관계와 영향 배치 재검토. 밖으로 나간 형상을 자동 축소/이동하지 않음 |

같은 areaId의 유지는 '같은 업무 영역을 이동/수정했다'는 명시적 판단에 따른다. 다른 영역으로 교체하면서 ID만 재사용하지 않는다. 서로 다른 적용 도안에서 우연히 같은 areaId가 나타나도 같은 영역으로 추정하지 않는다. 한 도안의 새 불변 판본에 같은 영역을 유지했거나 별도 명시 대응이 있을 때만 입력을 이어 준다.

추천 연결 조건은 제품별 모든 현재 영역에 입력을 정확히 하나씩 대응하는 것이다. 사용하지 않을 영역/텍스트 없는 제품의 정책은 미정이므로 임의 optional/disabled 필드를 만들지 않는다. 영역 자체를 아직 안 쓰는 편집 상태는 WorkSession에서 다루고 완료 WorkDocument로 저장하지 않는다. TextAreaInput의 빈 원문 제한을 우회하는 빈 입력을 만들지 않는다.

스냅샷 ID·참조·입력의 일관된 새 상태를 준비하고 대상 집합에 함께 반영하는 방향이다. 범용 편집 명령 프레임워크는 만들지 않는다. 결과 무효화는 실제 변경된 형상·입력·규칙과 이전/새 자동 그룹 의존성을 기준으로 한다. 새 도안 참조를 만들었다는 이유만으로 관계없는 제품을 전부 무효화하지 않는다. 입력을 되돌려도 이전 결과·확인을 자동 복구하지 않는 기존 정책을 유지한다.

## 7. 공유 관계와 변경 설명 예시

다음은 **구조 설명용 JSON 발췌**다. 완전한 AppliedDesign/WorkDocument 스키마가 아니며 production·출처·기준·결과를 생략했다. 누락된 값을 null·빈 정상 결과로 채우지 않는다. 실제 엔진 결과·제작 가능 판정은 없다. 새 geometry JSON의 타입 판별자·정식 필드 구조는 구현 전에 별도 정한다.

```json
{
  "appliedDesigns": [{
    "appliedDesignId": "design-1",
    "geometry": {"widthMm": 36, "heightMm": 36, "holes": []},
    "areas": [{
      "areaId": "area-title", "label": "본문",
      "bounds": {"xMm": 4, "yMm": 4, "widthMm": 28, "heightMm": 28}
    }]
  }],
  "products": [
    {
      "productId": "product-a", "appliedDesignId": "design-1",
      "textInputs": [{"areaId": "area-title", "sourceText": "MAIN PUMP", "lineBreak": {"mode": "automatic"}}]
    },
    {
      "productId": "product-b", "appliedDesignId": "design-1",
      "textInputs": [{"areaId": "area-title", "sourceText": "PUMP A", "lineBreak": {"mode": "specified", "lines": ["PUMP A"]}}]
    }
  ]
}
```

이는 홀 없는 36×36mm 명판 예시이기도 하다. holes:[]는 의도한 명시 값이다. 두 제품은 형상·영역을 공유하고 문구·방식은 각각 가진다. product-b의 한 줄은 지정 상태를 유지한다.

product-b만 폭을 40mm로 바꾸려면 design-1을 수정하지 않고 design-2를 만든다. 새 geometry는 폭 40/높이 36, holes:[], area-title의 bounds는 (4,4,28,28) 그대로다. product-b의 appliedDesignId만 design-2로 바꾸고 product-a는 design-1을 유지한다. product-b의 원문·지정 한 줄은 보존하지만 이전 결과를 현재로 재사용하지 않고 영향을 재계산한다. product-a에 실제 공동 계산 의존성이 있다면 그 영향은 별도로 무효화한다.

전체 제품의 폭을 변경하려면 그 시점의 대상 {product-a,product-b}를 명시한다. 변경 내용·영역 대응이 같다면 같은 design-2를 참조할 수 있다. 나중에 추가한 제품을 암묵적 대상으로 삼지 않는다. 서로 다른 원래 도안/조건은 자동 통합하지 않고 변경 내용을 별도로 확인한다.

### 3열×2행 원형 홀 예시

외곽 120×60mm, 지름 4mm인 원형 홀 6개다. 아래에서 중심 Y는 15/45, 왼쪽에서 중심 X는 20/60/100이다. 배열 행렬 파라미터를 운영 모델에 추가하지 않고 다음 실제 좌표 목록을 정본으로 삼는다. 행렬 생성 편집 기능은 이번에 만들지 않는다.

| holeId | centerXMm | centerYMm | diameterMm |
|---|---:|---:|---:|
| hole-1 | 20 | 15 | 4 |
| hole-2 | 60 | 15 | 4 |
| hole-3 | 100 | 15 | 4 |
| hole-4 | 20 | 45 | 4 |
| hole-5 | 60 | 45 | 4 |
| hole-6 | 100 | 45 | 4 |

영역은 예를 들어 area-title, bounds=(5,5,110,50)으로 둔다. 모든 홀이 영역과 겹치지만 정의는 그대로 표현할 수 있다. 실제 글자와 홀의 비간섭, 읽을 수 있는 글자 크기, 제작 여백을 이 예시로 판단하지 않는다. 형상 포함의 산술 예시와 글자 배치 성공을 구분한다.

## 8. 제작 조건과 모듈 사이의 변환

논리 11장의 문구 작업 방식·자재/두께/색상·형상 가공/마감은 공유 적용 내용이다. 이번에 전체 공정 관리 체계나 필수 마스터 등록, 빈 AppliedProductionConditions 클래스를 만들지는 않는다. 후속 구현 전에 실제 필요한 항목을 정한다. 미정 값을 '제작 방법 없음', 두께 0, 표준 색상, 기본 커터로 채우지 않는다.

| 조건 예 | 영향 대상 | 전달/보관할 값의 구분 |
|---|---|---|
| 제작 폭/높이·홀·영역 | 형상·배치·출력 | 위 mm 형상이 실제 적용 내용. 고객의 원래 규격과 구분하고 동일 실형상을 엔진/출력 경계에서 변환 |
| 문구 작업 방식(CNC 조각/UV/솔벤 인쇄 등) | 계산 조건 선택·출력 분류 | 채택한 방식과 실제 사용할 규칙을 해석. 방식만으로 미등록 값을 생성하지 않음 |
| 문구 조각용 커터·크기별 자폭 하한 | 문구 배치 | 조각에 필요한 실제 값/대응표. 하한 미등록은 계산 불가로 알림. UV 문구+외곽 CNC에 조각용 값을 강제하지 않음 |
| 자재·두께·색상 | 공유 제작 조건·출력/관리. 계산 영향은 실제 규칙에 따름 | 이름/두께만 보고 배치 규칙을 추측하지 않음. 명시 규칙이 있다면 해석한 영향 값만 계산으로 전달. 구체 타입/단위/필수 여부는 후속 |
| 외곽 CNC·펀칭·샤링·양면테이프 등 | 가공/마감·출력 지시, 경우에 따라 형상 요구 | 문구 작업과 별도. 공정 순서·설비 배정은 만들지 않음. 추가 여백/홀 변경은 명시된 형상/규칙으로 반영 |
| 글꼴·정렬·여백·줄 수·패턴 | 별도 적용 배치 기준 | 도안의 label/형상에 섞지 않음. 실제 규칙/출처와 측정 자료를 계산에서 결합 |
| 거래처·프로젝트·발주 원규격·관리 메모 | 출처·관리/출력 정보 | 원칙적으로 문구 배치에 전달하지 않음. 거래처 규칙을 적용했다면 실제 값/출처를 별도로 기록 |
| 수량·복제/수량 표시·출력 배열 | 출력 | 문구 배치 조건에서 제외. DXF 내 배치 변환·수량 표현에 사용 |

이 표는 분류 제안이며 새 enum/필수 필드를 도입한 것이 아니다. 같은 적용 도안을 쓰는 제품은 제작 조건도 공유하고, 형상이 같아도 실제 조건이 다르면 적용값을 분리한다. 단순 관리 메모로 배치 입력 세대를 변경하거나 모든 조건 차이를 재배치 요인으로 추측하지 않는다.

계산 요청에서 workflow는 적용 도안과 제품의 areaId를 해석한다. 외곽 치수/원형 홀/실제 직사각 영역, 원문·명시적 자동/지정 줄, 결합된 규칙·패턴·글꼴 측정·실제 그룹 의존 조건을 엔진의 공개 입력 값으로 변환한다. 관련 ID는 요청/진단 대응에 사용하고 workflow JSON Map이나 WorkDocument를 엔진에 읽히지 않는다. 측정/그룹 조건이 아직 없다면 가짜 빈 조건으로 계산 완료를 만들지 않는다.

엔진 출력은 workflow가 영역 ID와 현재 입력 내용에 대조하고 완료 배치·진단·실행 조건으로 변환한다. DXF 경계에는 원래 실형상과 완료 글자의 줄/위치/크기/자폭/스타일, 수량/출력 변환과 필요한 출력 지시를 전달한다. DXF 패키지는 WorkDocument 저장 스키마나 엔진 내부 클래스에 의존하지 않으며 workflow가 DXF 공개 입력으로 변환한다. 저장 JSON에 엔진 내부 객체를 그대로 저장하지 않는다.

이는 향후 경계 설명이며 이번에 연결·계산·DXF 출력을 구현하지 않는다. 공통 geometry 패키지나 빈 경계 인터페이스를 미리 만들지 않는다.

## 9. 다음 최소 구현 제안과 검증

다음은 **형상과 영역 정의의 값 모델만** 구현할 것을 추천한다. 후보 RectangularPlateGeometry·CircularHole·TextAreaBounds·TextAreaDefinition을 승인한 이름/필드로 lib/src에 구현한다. 목록 방어 복사, 유한 수치·양수 치수·ID, 생성/copyWith/JSON 왕복의 런타임 검증에 한정한다. JSON 형상 식별과 오류 타입/코드는 구현 전에 정하고 TextInputErrorCode에 관계없는 형상 오류를 억지로 추가하지 않는다.

AppliedDesign 전체·production·제품 참조 해석·변경 명령·포함/간섭 판정·엔진·DXF·파일 저장·UI는 이 최소 구현에 넣지 않는다. 직사각/원형 값이 유효해도 관계는 미검사로 명시한다. 영역 ID 중복은 향후 AppliedDesign 조립 책임이며 단독 TextAreaDefinition만으로 다른 영역의 중복을 검출했다고 주장하지 않는다.

그 구현에서는 0/음수 치수·NaN/Infinity·파생 경계의 오버플로·빈 ID·외부 목록/반환 JSON 변경·소수 반올림 없음·홀 0/6개·영역 ID 유지/변경 전 불변성을 확인한다. 영역과 홀이 겹치는 데이터도 정의할 수 있음을 확인하되 배치 가능성 검사라 부르지 않는다. 생성·format·analyze·test·assert 비활성 AOT·재생성 일치·생성 없는 소비자는 기존 개발 기준을 따른다.

이번에는 자료 참조·문서 링크·JSON 발췌/수치 예시·차분의 문서 검사만 수행한다. Dart pub get/format/analyze/test/AOT와 Flutter 검증은 업무 코드 변경이 없어 실행하지 않는다. 이전 74개 테스트·AOT 성공은 새 형상 모델 검증 결과가 아니다. 전체 기능 점검표나 과거 시험을 이번 작업으로 완료 처리하지 않는다.

문서 검사 결과: 상대 링크 존재, JSON 발췌 문법·두 제품의 공유 도안/영역 참조·지정 한 줄의 원문 일치, 6개 홀 수치와 외곽 포함 예시의 산술 검사를 통과했다. git diff --check 통과, 스테이징은 시작과 같이 비어 있고 lib/test/tool/pubspec/AGENTS 및 형제 앱의 변경은 없다. 이는 새 도형 모델·관계 검사기·배치 엔진의 실행 검증이 아니다. 커밋·푸시는 하지 않았다.
