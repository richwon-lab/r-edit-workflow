# 도안 구성 데이터와 형상·텍스트 영역 재설계

2026-10-25. **이번 산출물은 새 설계이며 구현이 아니다.** 실제 lib/src/geometry.dart는 RectangularPlateGeometry/CircularHole/TextAreaBounds/TextAreaDefinition과 *Mm 필드·왼쪽 아래 기준을 그대로 가진다. 아래 새 타입·JSON·오류는 미구현 제안이며 이전 API/JSON의 호환 유지나 변환 코드를 설계 조건으로 두지 않는다. 최신 사용자 결정이 이전 문서·구현보다 우선한다.

## 1. 출발점과 기존 제안의 교체 이유

대상 C:/work/richwon/r_edit_workflow, 시작 HEAD f252d3f3b8043c5cc06506b84b5ae96f96e880f1. AGENTS.md, 현재 계약·업무 모델 설계·개발 기준·다음 작업과 실제 geometry.dart/text_area_input.dart/공개 export를 확인했다. 형제 앱의 현재 결정·모듈 경계도 읽기 전용으로 참고했다. 시작 시 이전 형상 구현/생성 파일/테스트와 문서 변경이 미커밋 상태였고 스테이징은 비어 있었다. 그 코드는 이번에 교체·삭제하지 않는다.

이전 제안의 문제는 명판 종류를 타입으로 잡아 새로운 외곽마다 코드를 추가하게 되는 것, 원형 홀만 내부 가공으로 보는 것, 저장 단위·원점을 필드 이름에 고정하는 것, 오류와 변환 책임이 geometry.dart에 모인 것이다. 새 설계는 **기하 요소의 코드 지원과 명판 디자인의 데이터 등록을 분리**한다. 직사각/원형/모서리 절단/새 외형은 지원 요소로 경로를 구성한 서로 다른 데이터다. PlateKind.rectangle 같은 디자인 분류 enum이나 디자인별 서브클래스를 만들지 않는다.

유지할 것은 불변 적용 내용 공유, 개별 변경 시 참조 분리, 명시 대상 전체 적용, 원문/지정 줄 보존, 안정 ID, 값 검증과 제작 판정의 구분이다. 기존 96개 테스트/AOT는 기존 코드의 당시 검사 결과일 뿐 이 설계의 구현·일반 형상 지원 증거가 아니다.

## 2. 첫 지원 제안과 확장 경계

| 층 | 첫 지원 추천 | 이후 개발이 필요한 것 |
|---|---|---|
| 기하 요소 | 2D 선분과 원호. 원은 두 반원, 장공은 선분+반원으로 구성 | 타원호·Bezier·B-spline/NURBS·3D 등 새로운 요소와 그 검증/변환 |
| 경로 | 순서 있는 요소들의 열린 경로/닫힌 경로 | 불완전 CAD 조각의 자동 이어 붙임·공차 기반 자동 복구 |
| 영역 의미 | 외부 닫힌 경로 하나와 명시적 제외 경로 목록 | 떨어진 여러 재료 섬·겹친 영역 합집합/차집합 같은 일반 Boolean 연산 |
| 도안 역할 | 실제 외곽, 내부 관통 가공, 텍스트 영역, 벡터 장식 분리 | 포켓/깊이 가공·카운터보어·이미지 로고·장비별 가공 전략 |
| 단위/좌표 | 도안 한 곳의 명시적 mm 또는 inch, 설계 기준점 (0,0), X 오른쪽/Y 위쪽 | 다른 축/회전 좌표 프레임 가져오기·중첩 변환 인스턴스 |
| 자동 배치 경계 | 엔진이 실제 지원한다고 밝힌 영역/장애물 조합만 전달 | 원호/비직사각 영역의 자동 배치와 실제 공간 검사 구현 |

이것은 구현 승인을 기다리는 추천 범위다. 현재 Dart 엔진은 없으므로 '직사각이면 이미 계산 지원'이라고 기록하지 않는다. 선분·원호로 표현 가능한 새 디자인은 데이터만 추가한다. 새로운 요소, 가공 의미 또는 엔진 알고리즘이 필요할 때는 관련 코드를 개발한다. 모든 CAD 파일과 객체를 무손실 지원한다고 약속하지 않는다.

## 3. 경로와 내부 영역의 의미

### 3.1 요소와 닫힘

추천 요소는 sealed PathSegment의 LineSegment(start,end), CircularArcSegment(start,end,bulge)다. Point2(x,y)는 같은 도안 좌표 공간의 점이다. 숫자는 유한 double이고 좌표에 임의 반올림/trim 같은 보정을 하지 않는다.

원호는 **서로 다른 두 끝점+bulge**를 추천한다. bulge=tan(부호 있는 중심각/4), 양수는 +Z에서 보아 반시계, 음수는 시계다. 첫 지원은 0<abs(bulge)<=1, 즉 반원 이하로 제한한다. 더 긴 원호/원은 같은 요소 여러 개로 분할한 데이터로 표현할 수 있다. bulge=0을 선분으로 조용히 바꾸지 않고 잘못된 원호 값으로 거부한다. 지름/중심/끝점을 중복 정본으로 저장하지 않는다. 파생 반지름/중심 계산이 비유한·퇴화하면 별도 오류다. 매우 작은 bulge도 자동 0으로 만들지 않는다.

대안 중심+반지름+시작각/회전각은 친숙하지만 삼각함수로 끝점을 구해 경로 연결을 판정해야 한다. 끝점+중심+방향은 끝점의 반지름 일치를 별도로 검증해야 한다. 끝점+bulge는 연결 정합성과 원호의 곡률 책임이 분리되고 DXF로도 경계에서 변환하기 쉬워 추천한다. 구체 표현은 사용자 결정 사항이며 DXF의 내부 객체/필드에 workflow를 종속시키는 선택은 아니다. 자유 곡선은 원호로 근사해 저장하지 않는다.

Path2는 비어 있지 않은 순서 목록이며 각 요소의 end와 다음 start가 같은 좌표값이어야 한다. ClosedPath는 마지막 end와 첫 start도 같아야 한다. isClosed:true만 보고 틈을 메우거나 마지막 선분을 자동 추가하지 않는다. 첫 지원의 연결 검사는 저장된 double 값의 정확한 일치로 하며, CAD 가져오기에서 근접 점을 합칠지는 별도의 명시적 편집/승인 문제다.

선분은 start!=end, 원호도 start!=end여야 한다. 전체 원은 예를 들어 (8,10)→(12,10), (12,10)→(8,10)의 bulge=1 두 원호다. 시작·끝이 같은 단일 원호로 해석하지 않는다. 경로의 순서는 의미가 있고 자동 정렬/방향 반전하지 않는다.

### 3.2 경계는 선, 영역은 면이다

ClosedPath의 닫힘은 내부가 사용 가능한 단순 영역임을 보장하지 않는다. 자기 교차·접촉·겹친 요소·영면적은 **경로 위상 검사**의 별도 책임이다. PlanarRegion(outer, exclusions)은 'outer 내부에서 exclusions 내부를 뺀 면'이라는 명시적 의미다. 경로 방향으로 재료/홀을 추측하지 않는다. 첫 영역 정책은 단순 외부 루프, 그 안의 서로 겹치거나 닿지 않는 제외 루프를 추천하며 구체 접촉/수치 공차는 결정 후 검증한다. 지원 검증기가 없으면 미검사 상태로 보고 유효 영역/계산 가능으로 승격하지 않는다.

데이터 값 생성자는 유한 값·필수 값·요소 조건·구조적 연결/닫힘을 검사한다. 단순 루프/포함·간섭은 이름에 보장을 암시하는 생성자에서 몰래 생략하지 않고 별도 검사 보고서를 받는 설계로 둔다. 예컨대 PlanarRegion 생성 성공은 '구조가 갖춰진 정의'이고 위상 검사 통과는 별도다. isValid/canManufacture 같은 계산 가능한 플래그를 저장하지 않는다.

## 4. 도안·가공·영역·장식과 입력의 관계

| 추천 모델/필드 | 타입·필수성 | 의미·불변식/관계 |
|---|---|---|
| DesignContent.coordinateSpace | CoordinateSpace, 필수 | 내용 전체 좌표·길이 단위의 단일 선언. 중첩 요소는 상속하고 재선언 금지 |
| CoordinateSpace.lengthUnit | LengthUnit, 필수 | millimeter/inch 첫 후보. 모르는 값·누락을 mm로 보정하지 않음. 디자인 종류 enum과 다름 |
| DesignContent.materialBoundary | ClosedPath, 필수 | 재료의 실제 외곽 경계 하나. 폭/높이 직사각형을 정본으로 하지 않음 |
| DesignContent.internalFeatures | List<InternalFeature>, 필수 | 명시적 []는 내부 가공 없음. featureId 중복 거부 |
| InternalFeature.featureId | String, 필수 | 도안 내 안정 식별자. 좌표/문구/목록 위치에서 생성하지 않음 |
| InternalFeature.purpose | FeaturePurpose, 필수 | 첫 값 throughCutout 추천. 관통 제거 의미. 새 포켓/홈 목적은 깊이·공정 의미와 함께 개발 |
| InternalFeature.boundary | ClosedPath, 필수 | 원형·장공·비원형 구멍의 동일한 경로 표현. 목적 없이 단순 장식선에서 추론하지 않음 |
| DesignContent.textAreas | List<TextAreaDefinition>, 필수 | 임의 개수. areaId는 이 내용 안 유일. 본문/NO/RAT 고정 필드 없음 |
| TextAreaDefinition.areaId / label | String / String, 모두 필수 | 독립 ID, label은 빈 문자열 허용·그대로 보존. 이름 변경은 연결 유지 |
| TextAreaDefinition.region | PlanarRegion, 필수 | 텍스트 배치를 허용할 면의 정의. sourceText/크기/정렬/줄 수는 넣지 않음 |
| PlanarRegion.outer / exclusions | ClosedPath / List<ClosedPath>, 필수 | 외부 경계와 명시적 제외 내부. 미해석을 빈 목록으로 보정하지 않음 |
| DesignContent.decorations | List<VectorDecoration>, 필수 | 명시적 [] 가능. decorationId 유일, 절단 경계와 별도 |
| VectorDecoration.decorationId / paths | String / List<Path2>, 필수 | 열린 테두리선·닫힌 로고 윤곽 등. 선 경로이며 자동 면 채움/제거가 아님 |
| VectorDecoration.style | DecorationStyle, 필수·세부 미정 | 출력 선 표시 의미. 실제 출력 지원 전 임의 기본 선폭/공정으로 채우지 않음 |
| ReusableDesign.designId / revision / content | String / String / DesignContent, 필수 | 재사용 원본과 그 내용. 표시 이름과 독립, 실제 값과 출처를 보존 |
| AppliedDesign.appliedDesignId / content | String / DesignContent, 필수 | 작업에 적용한 불변 스냅샷. 원본이 없어도 내용을 해석할 수 있음 |
| AppliedDesign.source | DesignSource?, 명시적 출처 없음 가능 | 원본 designId/revision. 공유 원본을 실시간 재조회하는 계약이 아님 |
| 제품 appliedDesignId / textInputs | String / List<TextAreaInput>, 필수 | 문서 안 적용 도안과 영역 ID로 연결. 좌표 중복 없음 |
| TextAreaInput.areaId / sourceText / lineBreak | 기존 역할 유지 | 원문과 명시적인 자동/직접 지정 줄. 형상/좌표/단위는 저장하지 않음 |

제작 조건은 실제 적용 도안의 별도 명시 내용으로 연결한다. DesignContent는 위 형상·역할 내용의 경계이고 전체 제작/주문 관리 체계가 아니다. 재료/두께/색·문구 작업 방식·가공/마감 요구는 구체 필요 범위를 정한 뒤 별도로 모델링한다. 조건이 달라지면 같은 형상이어도 다른 적용 내용으로 다룬다. UV 문구+외곽 CNC에 조각 커터를 자동 적용하지 않는다.

실제 재료 영역은 materialBoundary 내부에서 purpose=throughCutout인 내부 경계를 뺀 면으로 해석한다. 텍스트 영역 자체에 홀이 겹쳐도 정의를 거부하지 않는다. 계산은 텍스트 영역과 실제 재료/가공 장애물의 관계를 함께 검토한다. 단, 이를 일반 Boolean 형상 자동 생성·저장 기능으로 구현하라는 뜻은 아니다.

장식·텍스트 경계를 자재 절단 경계로 출력하지 않는다. 장식이 실제 인쇄/조각되어야 한다면 명시적 출력 작업으로 연결한다. 장식을 글자 회피 장애물로 삼을지의 규칙도 별도이며 모든 장식을 무시하거나 장애물로 만드는 기본값을 두지 않는다. 첫 자동 배치는 장식이 있는 도안에서 그 배치 영향이 해석되지 않으면 지원 미정으로 차단한다. 이미지 로고/면 채움·복잡한 장식 지원은 후속이다.

AppliedDesign을 여러 제품이 참조할 수 있다. 한 제품만 바꾸면 새 스냅샷 ID/내용을 만들고 그 참조만 바꾼다. 전체 변경은 해당 시점의 productId 집합을 명시한다. 같은 영역의 이동/크기 변경은 areaId를 유지하고 원문/지정 줄을 유지한다. 영역 추가·삭제·교체는 명시적 입력/대응을 요구하며 label/좌표로 자동 매칭하지 않는다. 전체 형상을 바꾸더라도 홀·영역 자동 비례 확대는 없다. 의도적인 디자인 스케일 편집은 모든 대상과 결과 무효화를 별도로 명시해야 한다.

## 5. 단위·좌표·변환의 책임

| 경계 | 추천 기준 | 소유/검사 |
|---|---|---|
| 저장된 DesignContent | coordinateSpace.lengthUnit 한 번 선언, 필드 x/y/start/end 등에 *Mm 없음 | workflow가 내용과 함께 보존, 같은 내용에 혼합 단위 금지 |
| 도안 기준 좌표 | 설계자가 선택한 기준점이 (0,0), X 오른쪽/Y 위쪽인 평면 | 외곽 왼쪽 아래일 필요 없음. 원 중심/설치 기준도 가능, 음수 좌표 허용 |
| 계산 요청 | 엔진 공개 계약의 정규 길이 단위를 mm로 추천 | workflow 경계 어댑터가 한 번 변환. 엔진 요청도 단위 계약을 명시하고 묵시 가정 금지 |
| 화면 | 화면 픽셀·논리 픽셀, 사용자의 표시 단위 | 앱이 mm/inch 표시·줌·패닝·Y 반전을 수행. 저장 숫자에 픽셀을 혼합하지 않음 |
| 외부 CAD/DXF | 파일에 명시된 단위·원점·좌표 축 | 가져오기/출력 어댑터가 해석·변환. 무단위 파일은 사용자 선택 전 유효 도안으로 수락하지 않음 |
| 출력 파일 내부 배열 | 도안 좌표에서 파일 좌표로의 명시적 이동 | workflow 출력 구성이 배치 위치를 정하고 DXF 어댑터가 모든 경계/장식/완료 글자에 같은 변환 적용 |

CoordinateSpace 자체의 초기 축 방향은 위 규약으로 고정하는 추천이다. 'origin=lowerLeft'라는 enum을 저장하지 않는다. 저장 도안의 원점은 내용의 기준점이며 원점의 실제 장비 좌표는 별도 출력 변환이다. 첫 지원은 같은 축의 길이 환산과 출력 이동만, 회전/비균등 축척/반전/계층 인스턴스는 미지원으로 알린다. 기존 CAD 좌표를 가져올 때 축을 모르면 Y를 임의로 뒤집지 않는다.

동일 실형상 예: mm 좌표 경로 (0,0)-(25.4,0)-(25.4,12.7)-(0,12.7)-(0,0)와 inch 좌표 (0,0)-(1,0)-(1,0.5)-(0,0.5)-(0,0)는 같은 실형상의 다른 숫자 표현이다. inch→mm는 모든 점/길이를 25.4배, bulge는 무차원이라 유지한다. 라벨/ID/원문은 변환하지 않는다. 단위 태그만 바꾸면 실형상이 바뀌므로 금지한다. 파생 치수/안전 여백/선폭 등 길이값의 소속 단위도 해당 계약에서 명확히 한다.

단위 환산과 물리적 크기 변경은 다른 명령이다. 순수 환산은 형상/입력의 물리 의미를 바꾸지 않지만 이진 부동소수 오차까지 자동 동일성/결과 재사용의 근거로 삼지 않는다. 계산 입력에는 정규화한 실제 값과 변환 규약을 캡처하며 안정적인 동일성 규약을 결정하기 전에는 근사 비교만으로 이전 결과/확인을 재사용하지 않는다. 저장에 임의 소수 반올림을 하지 않는다. 연결 허용오차·위상 공차·엔진 충돌 공차·제작 최소 여백은 각각 별도 책임/단위/버전이 필요하며 같은 epsilon 하나로 합치지 않는다.

## 6. 형상 보존과 계산 지원을 분리한다

1. JSON 경계는 필수/타입/지원 요소·단위·목적을 해석한다. 알 수 없는 kind를 선분/사각형으로 보정하지 않는다.
2. 값 정의는 유한성·요소 조건·경로 연결/닫힘·소유 ID 중복을 검증한다. 이 성공은 위상/제작/배치 성공이 아니다.
3. 형상 관계 검사는 자기 교차·면적·외곽 포함·내부 가공 간 간섭·영역의 관계를 검사한다. 미실행/미지원과 실제 위반을 분리한다.
4. 엔진 어댑터는 입력의 영역/외곽/가공/장식 영향과 엔진 capabilities를 대조한다. 지원하지 않으면 계산 요청 준비 실패로 돌려준다. 데이터는 보존한다.
5. 엔진은 준비된 실제 영역과 원문/규칙/측정 자료로 후보를 계산하고 글자 충돌·홀 회피·탐색 한도와 판정을 반환한다. 제작 검토는 그와 별도다.

계산 요청의 개념적 값은 productId/areaId, 현재 입력 스냅샷, 정규 단위의 실제 textRegion/materialBoundary/internalFeatures, 원문·명시적 줄 입력, 결합 규칙·패턴·폰트 측정·실제 자동 그룹 의존 내용이다. 제품 입력 안에 영역 좌표를 복제하지 않고 적용 도안 참조를 해석해 이 요청을 구성한다. 장애물 범위를 임의로 줄이거나 다른 제품의 직접 지정 줄을 자동 그룹 기준으로 쓰지 않는다. 수량은 계산 조건에서 제외한다.

첫 엔진이 직사각 텍스트 영역과 원형 관통 홀만 지원한다면, 선분 네 개로 만든 정확한 축 평행 직사각과 두 반원으로 만든 정확한 원임을 증명 가능한 경우에만 전용 입력으로 **무손실 변환**할 수 있다. 단순 boundingBox 변환은 금지한다. 분류/관계 검사가 없으면 지원한다고 추측하지 않는다. 비직사각/원호 영역은 unsupportedTextRegion으로 보고 해당 areaId/요소 위치/엔진 식별/요구 기능을 돌려준다. noFit 또는 정상 빈 결과가 아니다. 같은 원호 요소를 저장하는 기능과 엔진의 원호 영역 계산 기능은 별도의 개발 범위다.

workflow는 도안·식별/역할·저장 표현·입력/결과 수명·변환 요청을 소유한다. 엔진은 자체 공개 입력·지원 기능·측정/탐색·충돌 검사/결과 계약을 소유한다. DXF는 자체 공개 출력 입력과 외부 파일 표현/단위/원호·장식·문자 인코딩 지원을 소유한다. workflow 어댑터가 서로 다른 값으로 변환하며 작업 JSON/내부 객체를 다른 패키지가 직접 읽지 않는다. DXF도 미지원 요소/목적을 무시하지 않고 출력 준비 실패로 알린다. DXF에서 글자 배치를 다시 계산하지 않는다.

workflow와 엔진 사이에 같은 기하 구조가 필요할 수 있지만 실제 두 소비자의 요구/의존성을 확인하기 전 공통 geometry 패키지·빈 인터페이스를 만들지 않는다. 첫 구현은 workflow 내부 데이터 계약이며, 엔진 연결 시 실제 값 변환 비용/정밀도/소유권을 확인해 공유 여부를 다시 결정한다.

## 7. 오류·진단과 탐색 가능한 파일 구성

아래 이름/코드는 **새 계약 후보**다. 기존 GeometryErrorCode를 호환 목록으로 취급하지 않으며 범용 오류 상속 체계를 만들지 않는다.

| 코드 후보 | 발생 조건 | 구분/진단 예 |
|---|---|---|
| missingField / invalidType / unexpectedField | 구조 누락/값 타입/알 수 없는 키 | fieldPath, expectedType. 알려진 요소의 잘못된 필드와 미지원 종류를 구분 |
| unsupportedLengthUnit / unsupportedElement / unsupportedFeaturePurpose | 현재 데이터 계약이 해석할 수 없는 단위/요소/가공 목적 | 원래 태그, entityId, fieldPath. 기본값으로 보정하지 않음 |
| nonFiniteCoordinate / invalidArcBulge | NaN/무한 좌표 / 원호 bulge=0·비유한·지원 범위 밖 | 좌표/요소 인덱스, 허용 범위. 큰 정상 좌표를 임의 크기 제한으로 거부하지 않음 |
| degenerateSegment / derivedGeometryNotFinite | 시작=끝 / 파생 중심·반지름 오버플로/표현 불가 | segmentIndex, 파생 항목. 연결 틈과 별도 |
| emptyPath / disconnectedPath / openBoundary | 요소 없음 / 인접 끝점 불일치 / 끝-처음 닫힘 실패 | 양쪽 요소 위치·기대점/실제점. 자동 선분 추가 없음 |
| emptyIdentifier / duplicateIdentifier / unresolvedReference | 빈 ID / 같은 소유 범위 중복 / 적용 도안/영역 없음 | identifierKind, entityId, relatedFieldPath. label 빈 값은 오류 아님 |
| selfIntersection / degenerateRegion | 위상 검사에서 교차 / 면적 없음·면 정의 불가 | 교차 요소 쌍/위치. 값 생성자 성공으로 면 유효 주장 금지 |
| featureOutsideMaterial / intersectingFeatures | 관계 검사에서 외부 가공 / 금지된 교차·접촉 | 관련 featureId, 검사 규약. textArea와 hole 겹침 자체는 이 오류 아님 |
| geometryCheckUnavailable | 필요한 관계/위상 검사를 지원하지 않거나 아직 실행하지 못함 | 검사 이름·원인·대상. 실제 교차 발견으로 바꾸지 않음 |
| unsupportedTextRegion / unsupportedObstacle / unresolvedDecorationEffect | 저장 표현은 가능하지만 엔진 입력 지원이 부족 | areaId/featureId, engineId, requiredCapability. noFit과 구분 |
| unsupportedOutputElement / unsupportedOutputOperation | DXF 경계의 요소/가공 표현 미지원 | 출력 대상 ID·종류·출력 형식. 자료 누락 출력 금지 |

위 표 중 구조·단위/요소/목적·수치·경로 연결·식별/참조 오류는 DesignGeometryValidationException(code,fieldPath,entityId?,relatedFieldPath?,details) 후보로 묶되 details를 임의 Map 만능 운반체로 만들지 않는다. 필요한 정보(요소 인덱스·관련 ID·기대/실제 점)는 역할에 맞는 명시 필드 또는 구체 진단 값으로 설계한다. 범용 ErrorBase/Result<T> 체계를 추가하지 않는다. 위상/관계 검사는 GeometryCheckIssue 목록으로, 계산/출력 지원 실패는 각 경계의 전용 진단으로 반환하는 방향을 추천한다. 기하 생성 예외에 engine/DXF 코드를 억지로 넣지 않는다.

fieldPath는 JSON/모델의 필드 위치이며 문자 오프셋이 아니다. 예: internalFeatures[2].boundary.segments[1].end. 목록이 바뀌어도 대상 추적이 가능하도록 featureId/areaId/decorationId와 관련 요소 위치를 함께 제공한다. 정상 입력의 원문 전체를 오류 details에 복사하지 않는다. 오류 문자열을 파싱해 분류하지 않으며 여러 오류가 있을 때 발견 순서를 호환 계약으로 고정하지 않는다. 값 구성 실패는 예외 하나, 독립 관계 검사는 여러 issue 반환으로 목적을 구분한다.

### 파일/타입 배치 추천 (아직 폴더를 만들지 않음)

```text
lib/r_edit_workflow.dart                 공개 export
lib/src/design/coordinate_space.dart     Point2·LengthUnit·CoordinateSpace, 단위 문맥
lib/src/design/path_segments.dart        sealed PathSegment + LineSegment/CircularArcSegment
lib/src/design/boundary_paths.dart       Path2·ClosedPath, 연결/닫힘과 그 JSON
lib/src/design/planar_region.dart        면 정의·제외 경로 (위상 검사 결과와 구분)
lib/src/design/design_content.dart       실제 외곽·내부 가공·영역·벡터 장식 역할/소유 ID
lib/src/design/applied_design.dart       재사용 원본/불변 적용 내용/출처 관계를 구현할 때만 추가
lib/src/design/design_geometry_errors.dart  정의 오류 코드·예외·각 원인 설명
lib/src/design/geometry_check_issues.dart    실제 관계 검사 구현 시 전용 진단
lib/src/text/text_area_input.dart        원문·자동/지정 줄 입력 (이동은 후속 구현 범위)
lib/src/integration/layout_input_conversion.dart  실제 엔진 연결 시 변환/지원 검사
lib/src/integration/dxf_output_conversion.dart    실제 DXF 연결 시 출력 변환
```

파일은 클래스 수가 아니라 함께 변경하는 책임으로 묶는다. 오류는 정의 파일에서 설명 없이 섞지 않고 전용 오류 파일에서 발생 조건/경로/다른 오류와 차이를 문서화한다. 별도 utils/common 폴더는 없다. 후속 파일/폴더를 미리 생성하지 않는다.

Dart의 `_private` 접근은 파일 경로가 아니라 library 단위다. PathSegment의 직접 하위 타입들은 같은 library에 있어야 하므로 path_segments.dart 한 파일에 sealed 선언과 두 타입을 함께 둔다. 다른 파일에서 서브타입을 만들 수 있게 base/동적 Map으로 타입 구분을 약화하지 않는다. 다른 책임 파일은 public 검증 생성자/변환 API를 import한다. 여러 파일을 part로 묶어 거대한 private 접근망을 만들 필요는 없다. Freezed/json_serializable 생성 part는 해당 모델 library에 둔다. 관련 타입이 더 늘 때만 실제 library/part 분할 필요를 재검토한다.

공개 생성자·필드·copyWith·fromJson/toJson·단위 변환의 한국어 API 주석에는 좌표 문맥/단위 상속, 정확 연결·원호 제약, 방어 복사, 런타임 검증 실패 코드, 수행하지 않는 위상/관계 검사를 명시한다. 영어 식별자·Dart 표기 규칙을 따르고 수동 반복 비교/변환은 생성 도구를 활용한다. 생성된 copyWith/중첩 수정/복원도 실제 검증을 호출해야 하며 assert만으로 구현하지 않는다.

## 8. 데이터 예시와 8개 사례 검토

다음 JSON은 **관계 검토용 발췌이며 전체 저장 스키마/현재 API가 아니다.** 아래 unit·kind 태그는 필요한 단위/기하 요소 구분이며 명판 종류 구분이 아니다. 출처/제작 조건/규칙/결과는 생략했고 가짜 값으로 채우지 않았다.

```json
{
  "appliedDesigns": [{
    "appliedDesignId": "applied-1",
    "content": {
      "coordinateSpace": {"lengthUnit": "millimeter"},
      "materialBoundary": {"segments": [
        {"kind":"line","start":{"x":0,"y":0},"end":{"x":36,"y":0}},
        {"kind":"line","start":{"x":36,"y":0},"end":{"x":36,"y":36}},
        {"kind":"line","start":{"x":36,"y":36},"end":{"x":0,"y":36}},
        {"kind":"line","start":{"x":0,"y":36},"end":{"x":0,"y":0}}
      ]},
      "internalFeatures": [],
      "textAreas": [{"areaId":"title","label":"","region":{
        "outer":{"segments":[
          {"kind":"line","start":{"x":4,"y":4},"end":{"x":32,"y":4}},
          {"kind":"line","start":{"x":32,"y":4},"end":{"x":32,"y":32}},
          {"kind":"line","start":{"x":32,"y":32},"end":{"x":4,"y":32}},
          {"kind":"line","start":{"x":4,"y":32},"end":{"x":4,"y":4}}
        ]},"exclusions":[]
      }}],
      "decorations": []
    }
  }],
  "products": [
    {"productId":"a","appliedDesignId":"applied-1","textInputs":[
      {"areaId":"title","sourceText":"MAIN PUMP","lineBreak":{"mode":"automatic"}}
    ]},
    {"productId":"b","appliedDesignId":"applied-1","textInputs":[
      {"areaId":"title","sourceText":"PUMP A","lineBreak":{"mode":"specified","lines":["PUMP A"]}}
    ]}
  ]
}
```

같은 요소의 예로 중심(10,10)·반지름2인 내부 구멍은 다음과 같다. 이는 하나의 가공 대상 표현이며 원형 홀 전용 업무 타입이 아니다.

```json
{"featureId":"cutout-1","purpose":"throughCutout","boundary":{"segments":[
  {"kind":"circularArc","start":{"x":8,"y":10},"end":{"x":12,"y":10},"bulge":1},
  {"kind":"circularArc","start":{"x":12,"y":10},"end":{"x":8,"y":10},"bulge":1}
]}}
```

| 사례 | 데이터로 바뀌는 부분 | 개발 필요/제한 |
|---|---|---|
| 직사각 외곽, 홀 없음 | 외곽 선분4개, internalFeatures:[] | 선분/경로/역할 계약 구현 후 디자인별 코드 없음 |
| 외곽+원형 홀6개 | featureId6개. 중심X20/60/100, Y15/45, 반지름2 각각 두 원호(120×60 외곽 예) | 선분+원호 지원 후 데이터 추가. 원형 판정/홀 회피를 지원하는 엔진은 별도 |
| 원호 포함 외곽 | 예: (0,0)→(40,0)→(40,20)의 선분, (40,20)→(0,20)의 bulge=1 원호, (0,20)→(0,0)의 선분 | 같은 요소면 데이터만. 원호 외곽의 관계 검사/출력 지원은 별도 구현 |
| 장공·비원형 내부 구멍 | 장공: (10,8)→(20,8) 선분, (20,8)→(20,12) bulge=1, (20,12)→(10,12) 선분, (10,12)→(10,8) bulge=1. 비원형은 다른 닫힌 경로 | 기존 요소 조합은 데이터. 타원/새 포켓 가공은 요소/목적/검증·출력 개발 필요 |
| 같은 요소의 새 명판 | 예: 모서리를 잘라낸 8개 선분 외곽, 새 영역/가공 경로·ID | 새 ReusableDesign 데이터만. 디자인별 enum/클래스 불필요 |
| 공유 후 b만 형상 변경 | 새 applied-2에 변경한 경로 저장, b만 참조 교체. a는 applied-1 유지 | 편집 적용/무효화 명령은 향후 코드. 원문/영역 ID 유지 또는 명시 대응 필요 |
| 동일 실형상의 단위 변환 | 위 25.4×12.7mm와 1×0.5inch, 문맥 단위와 모든 길이 함께 변환 | 단위 변환기 개발은 필요하나 새 디자인마다 개발 없음. 저장 반올림/태그만 변경 금지 |
| 표현 가능하나 계산 미지원 영역 | 선분+원호로 만든 반원형 textRegion을 그대로 보관 | 엔진이 직사각만 지원하면 unsupportedTextRegion. 외접 사각으로 대체 금지. 새 엔진 기능 개발 필요 |

외곽의 원호/원형·장공은 위상과 가공/출력 지원이 확인될 때만 각 목적에 사용할 수 있다. 관계가 표현된다는 설명을 실제 제작 승인으로 해석하지 않는다. 지원되지 않는 가공 경계/장식을 알면서 누락해 정상 DXF를 만드는 경로도 금지한다.

## 9. 중요한 대안·교체 범위·다음 최소 구현

| 선택 | 대안과 추천 이유 |
|---|---|
| 디자인 구성 | 디자인별 Shape enum/클래스 대신 역할을 가진 경로 데이터. 새 디자인 등록이 코드 변경과 분리됨 |
| 원/직사각 정본 | 전용 Circle/Rectangle과 경로를 함께 정본으로 두기보다 선분/원호 경로로 통일 추천. 편집 도구의 원/사각 생성 명령은 경로 데이터를 만들 수 있음 |
| 원호 | 끝점+bulge 추천. 중심/각도 방식은 대안, 수치/연결 정합성과 개발자 가독성을 보고 결정 |
| 단위 | 항상 mm로 저장은 단순하지만 원본 표현과 변환 의도를 잃기 쉬움. 저장 문맥 mm/inch·계산 mm 변환 추천. 숫자별 Quantity 객체 반복은 현재 불필요 |
| 좌표 원점 | 왼쪽 아래 고정 대신 도안 기준점. 화면/출력 변환에서 목적별 위치 결정 |
| 역할 | 레이어명으로 가공 여부 추측 대신 materialBoundary/internalFeatures/textAreas/decorations로 명시 |
| 저장·엔진 계약 | 공통 모듈을 미리 만들기보다 workflow가 자기 데이터 계약을 소유하고 실제 엔진/DXF 어댑터에서 변환 |

현재 RectangularPlateGeometry/CircularHole/직사각 TextAreaBounds를 새 형상의 정본으로 사용하는 설계는 교체한다. *Mm 필드는 문맥 단위와 일반 좌표로, 원형 홀 ID는 InternalFeature ID로, TextAreaDefinition.bounds는 region으로 교체할 방향이다. 오류를 geometry.dart에 섞은 구성과 소유 범위별 ID/변환 진단도 재설계한다. 기존 명칭/JSON은 보호 대상 호환 계약이 아니므로 별칭/마이그레이션을 만들지 않는다.

유지할 책임은 TextAreaInput의 원문/줄 입력, stable areaId 연결, label 빈 문자열 허용·보존, runtime 검증·불변성·방어 복사·생성 파일 관리, 적용 도안 공유/분리·명시적 전체 적용이다. 타입명 자체를 전부 유지하겠다는 뜻이 아니다. 이번에는 코드/생성 파일/테스트/의존성에 손대지 않는다.

**다음 한 번의 최소 구현 추천:** 좌표 문맥(명시 mm/inch), Point2, sealed 선분/원호, Path2/ClosedPath의 값 모델과 JSON·정의 오류만 구현한다. 단위 환산은 경로/점의 명시적 변환만 지원하고 화면/출력 배열·회전/반전은 넣지 않는다. 유한 값·원호 조건·파생 수치·연결/닫힘·불변성·copyWith·정수/소수 JSON·미지원 태그·AOT를 검증한다. PlanarRegion 위상 검사·DesignContent/가공/영역 조립·도안 공유 명령·엔진/DXF는 그다음이다. ClosedPath를 만들었다고 단순 면/제작 가능이라 주장하지 않는다.

최소 구현 전에 아래 1~3번을 결정하고 기존 미커밋 구현을 어떻게 교체할지 변경 목록을 제시한다. 이번 문서 작업을 코드 교체 승인으로 간주하지 않는다. 승인 후 기존 테스트의 업무 의미는 새 타입에 맞게 옮기되 예전 API·테스트 개수 자체를 유지 목표로 두지 않는다.

## 10. 이전 값 모델 구현 기록 (현행 설계와 구분)

이전 작업은 mm 고정 네 값 모델에서 96개 테스트(입력 74+형상 22), assert 비활성 AOT 형상 오류 17/입력 14건, 생성 일치·별도 path 소비자를 확인했다. 그 코드는 이번 작업 시작 시 미커밋 상태로 존재했고 수정하지 않는다. 이 기록은 새 기하 요소/단위/경로/진단 설계를 검증한 결과가 아니다. 상세 당시 내용은 next-step.md의 첫 형상 값 구현 절에 남긴다. 예전 직사각 중심의 제안은 위 교체 이유로 현행 권고에서 제거했다.

## 11. 사용자가 결정할 사항

1. 첫 기하 요소를 선분+반원 이하 원호로 시작하고, 원/직사각/장공을 경로 데이터로 통일할지. 추천은 통일이다. 타원/자유 곡선·새 가공은 후속 개발로 남긴다.
2. 원호를 끝점+bulge로 할지 중심/각도로 할지. 추천은 명시 끝점+bulge이며 정확 연결과 파생 값 검증을 분리한다.
3. 저장 문맥에 mm/inch를 허용하고 계산은 mm로 변환할지. 추천은 둘을 구분하고 축은 X 오른쪽/Y 위쪽·설계 기준점으로 시작하는 것이다.
4. 첫 도안 목적을 단일 외곽+관통 내부 가공으로 제한할지. 추천은 깊이/포켓/다중 재료 섬을 보류하는 것이다.
5. 위상/관계 검사의 접촉·허용오차와 미지원 장식의 배치 영향 처리. 수치를 임의로 채우지 말고 실제 엔진 계약을 정할 때 명시해야 한다.
6. 첫 자동 배치 영역/장애물 지원 범위와 검사 완료 기준. geometry 저장 지원과 별도로 결정하며 현재 엔진 구현 완료를 전제하지 않는다.

1~3은 다음 최소 값 모델을 구현하기 위한 선택이고 4~6은 그 이후 조립/계산 단계의 결정이다. 이 문서는 추천안을 구체화한 것이며 미응답을 승인으로 해석하지 않는다.

## 12. 이번 작업의 확인 범위

문서의 경로/링크·관계 JSON·요소 연결/닫힘·사례 수치와 기존 변경 보존을 검사한다. 코드/의존성/생성 파일/형제 앱·Git 스테이징은 변경하지 않는다. 코드 변경이 없어 Dart/Flutter 분석·테스트·생성·AOT는 실행하지 않으며 과거 결과를 새 계약 검증으로 사용하지 않는다. 새 배치 결과·제작 판정·저장 기능을 합성해 채우지 않았다. 커밋·푸시는 하지 않는다.

이번 문서 검사 결과: 상대 링크 존재, 두 JSON의 문법·공유 도안/영역 입력 연결·지정 원문 보존·선분/원호의 끝점 연결/닫힘과 단위 환산 예시를 확인했다. git diff --check 통과. 비문서 파일 목록/내용의 합성 SHA-256과 Git index 해시는 시작 시점과 일치했다. 이 검사는 실제 원호/위상 알고리즘·엔진·제작 가능성 검증이 아니다.
