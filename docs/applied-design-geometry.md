# 도안 구성 데이터와 최소 기하 값 계약

후속 도안 역할 구현은 [도안 구성/입력 연결 계약](design-geometry.md)을 따른다. 이 문서는 하위 최소 기하/진단 계약을 유지한다. 과거 절의 'TextAreaDefinition/영역 조립 미구현'은 당시 상태이며 현재는 DesignGeometry·TextRegion과 입력 ID 대조를 구현했다. 전체 AppliedDesign/제품·엔진/제작은 여전히 미구현이다.

2026-10-25 최신 결정/구현 반영. **기하 값·JSON·단위 환산은 구현했고, 도안의 업무 역할과 배치/가공 기능은 아직 설계다.** 기존 API/JSON은 호환 제약이 아니며 별칭·구형 변환은 없다. 시작 HEAD는 2ef69e0, 작업 트리/스테이징은 깨끗했다. AGENTS·현재 개발 기준·기존 설계·실제 코드를 확인했다.

## 1. 명판 종류·업무 역할·기하 요소

명판 디자인은 지원 기하 요소를 조합한 데이터다. 사각형/모서리를 깎은 외곽/새 디자인마다 클래스나 enum을 추가하지 않는다. 코드의 기하 요소 종류와 데이터의 명판 종류는 별개다. 새 요소/가공/소비자 알고리즘이 필요하면 개발이 필요하며 모든 CAD 형상을 약속하지 않는다.

외곽·관통 구멍·텍스트 영역·장식은 **같은 기하 경계에 붙일 수 있는 서로 다른 업무 역할**이다. 모든 구멍에 중심/지름을 요구하지 않는다. 독립 원, 선분 다각형, 원호를 포함한 장공/자유 경로로 실제 경계를 보존한다. 지원하지 않는 타원/자유 곡선을 원호나 외접 사각형으로 보정하지 않는다.

이전 잘못된 권고를 수정했다. 원을 반드시 두 원호로 저장하지 않고 중심/반지름을 유일 정본으로 갖는 독립 원을 지원한다. 원호를 반원 이하로 제한하지 않는다. 경로의 시작점을 구간마다 중복 저장하지 않는다. 기존 직사각 명판·원형 홀 중심 타입은 제거했다.

## 2. 구현된 공개 모델·책임·이름

모든 값은 불변이고 생성·생성된 copyWith·JSON 복원이 실제 검증을 호출한다. 타입에 달리 적지 않은 필드는 모두 필수이며 임의 기본값이 없다. JSON 숫자는 정수/소수를 받아 double로 처리하고 임의 반올림하지 않는다.

| 공개 타입·필드 | 타입/의미 | 불변식과 검증 책임 |
|---|---|---|
| Point2.x / y | double, 도안 문맥 단위의 좌표 | 각각 유한. 음수 허용. 다른 형상 관계는 모름 |
| LengthUnit | millimeter / inch | 단위 종류이며 명판 종류 enum이 아님 |
| DrawingCoordinateSpace.lengthUnit | LengthUnit | 설계 기준점(0,0), X 오른쪽/Y 위쪽. 원점은 외곽 왼쪽 아래일 필요 없음 |
| PathSegment | sealed LineTo / ArcTo | 같은 library의 구체 구간 합 타입. 업무 역할/단위 태그 없음 |
| LineTo.end | Point2 | 시작점은 소유 경로가 정함. 구간 자체에서 퇴화 여부를 추측하지 않음 |
| ArcTo.end / bulge | Point2 / double | bulge 유한·0 아님. 부호 양수 반시계/음수 시계. abs>1 허용 |
| GeometryPath.start / segments | Point2 / List<PathSegment> | 목록 비어 있지 않음, 방어 복사. 직전 끝점이 다음 시작. 경로가 각 구간 퇴화와 원호 파생 표현 가능성을 검사 |
| ClosedBoundary | sealed CircleBoundary / PathBoundary | 원 또는 닫힌 경로의 기하 경계. 재료 내부 유효성 판정이 아님 |
| CircleBoundary.center / radius | Point2 / double, 문맥 길이 | radius 유한·양수. 중심±반지름 극점의 비유한 결과도 거부. 원호 분해 결과 저장 없음 |
| PathBoundary.path | GeometryPath | 마지막 끝점이 경로 start와 정확히 같아야 함. 자동 선분/틈 보정 없음 |
| DrawingGeometry.coordinateSpace | DrawingCoordinateSpace | 이 기하 묶음의 길이 단위 선언 한 곳 |
| DrawingGeometry.paths / boundaries | List<GeometryPath> / List<ClosedBoundary> | 명시적 빈 목록 허용, 방어 복사. 아직 외곽/가공/영역 역할이나 ID를 부여하지 않음 |

Point2는 Point2D와 달리 Dart/Flutter의 Point/Offset 혼동을 줄이면서 차원을 드러내기 위해 선택했다. LineTo/ArcTo는 시작점 없는 구간이라는 책임을 이름에 드러내며 LineSegment(start,end)보다 새 경로 구조에 맞다. GeometryPath는 단순 Path보다 Flutter/파일 경로와 덜 혼동된다. CircleBoundary/PathBoundary는 CircleHole/PlateGeometry와 달리 업무 역할을 강제하지 않는다. DrawingGeometry는 전체 AppliedDesign이 아니라 단위가 결합된 기하 묶음임을 드러내기 위해 선택했다. GeometryDocument는 파일 저장 구현처럼 읽힐 수 있어 채택하지 않았다.

최신 수치·진단 보완은 12절을 따른다. 9~11절의 105개 테스트/AOT는 초기 최소 기하 구현 당시 기록이다.

### 원호 표현과 수치 검증

bulge=tan(부호 있는 중심각/4)이며 0은 수학적으로 잘못된 원호 값이다. 0을 선분으로 바꾸지 않는다. abs(bulge)>1은 반원을 넘는 원호이며 양쪽 방향 모두 허용한다. 유한한 bulge는 한 바퀴 미만 원호를 표현하고, 시작=끝의 단일 원호를 전체 원으로 해석하지 않는다. 원이 필요하면 CircleBoundary를 사용한다. 원호 구간으로 원을 구성한 경로도 가능하지만 원과 분해 경로를 같은 경계의 이중 정본으로 저장하지 않는다.

ArcTo는 bulge의 유한성/0 여부만 검사한다. 시작점과 끝이 같은지, 현 길이에서 중심·반지름과 실제 원호 위 극점을 double로 표현할 수 있는지는 GeometryPath만 검사한다. 원호 중심/반지름은 파생 검사용이며 JSON에 중복 저장하지 않는다. 큰 좌표/큰 bulge의 불필요한 제곱 오버플로를 피하는 연산을 사용한다. 그럼에도 극단적 double 입력의 반현/반지름/중심 계산이 비유한 또는 0으로 소실되면 numericRepresentationFailure다. 모든 수학적으로 유효한 실수 기하를 double로 처리할 수 있다고 보장하지 않는다. 수치 실패를 엔진 미지원이나 잘못된 bulge=0과 섞지 않는다.

GeometryPath가 각 구간 시작점을 순서대로 정하므로 불연속 시작점을 따로 입력할 수 없다. 구간 순서 변경은 경로 자체가 달라지는 편집이고 그 새 경로를 다시 검증한다. 닫힌 경로는 마지막 구간이 명시적으로 start로 돌아온다. isClosed 플래그·자동 직선 추가·근접 좌표 병합은 없다. exact equality는 구조적 닫힘 검사이며 계산/제작 허용오차 정책이 아니다.

## 3. JSON 계약과 변환 경계

공개 값에 fromJson(Object?)/toJson()을 제공한다. LineTo/ArcTo는 PathSegment.fromJson, 원/경로 경계는 ClosedBoundary.fromJson이 태그를 해석한다. 알려진 타입의 필드 변환·숫자 toDouble·값 비교·copyWith는 생성기에 맡긴다. 구조/필수/타입/태그 검사는 JSON 경계에, 업무 값 검증은 실제 생성자에 둔다. 중첩 객체를 사전 생성해 버렸다가 다시 생성하지 않는다. 오류 문자열을 파싱하지 않는다.

다음은 **실제 구현된 기하 묶음 JSON**이다. 전체 WorkDocument/AppliedDesign 저장 스키마가 아니며 파일 I/O도 없다.

```json
{
  "coordinateSpace":{"lengthUnit":"millimeter"},
  "paths":[],
  "boundaries":[
    {"kind":"circle","center":{"x":10,"y":10},"radius":2},
    {"kind":"path","path":{
      "start":{"x":0,"y":0},
      "segments":[
        {"kind":"line","end":{"x":36,"y":0}},
        {"kind":"line","end":{"x":36,"y":36}},
        {"kind":"line","end":{"x":0,"y":36}},
        {"kind":"line","end":{"x":0,"y":0}}
      ]
    }}
  ]
}
```

kind의 circle/path/line/arc는 실제 구분이 필요한 기하 태그다. rectanglePlate/slotPlate 같은 디자인 종류가 아니다. unit 누락·알 수 없는 태그·필드 누락을 보정하지 않는다. 숫자 문자열/null/bool은 숫자로 받지 않고 unknown 필드도 거부한다. 반환 Map·목록과 모델의 목록은 분리되어 외부 변경으로 모델이 바뀌지 않는다.

## 4. 단위·좌표계와 환산 API

단위는 DrawingGeometry.coordinateSpace에 한 번 선언하고 x/y/radius 등에 *Mm 또는 단위 태그를 반복하지 않는다. Point2/GeometryPath/ClosedBoundary를 단독 사용할 때는 호출자가 원본 문맥을 명시해야 한다. 화면 픽셀·줌·DPI·출력 배열 좌표는 저장 기하에 넣지 않는다.

`DrawingGeometry.convertedTo(target)`는 단위 선언과 모든 시작점/끝점/중심/반지름을 함께 환산하고 bulge를 유지한다. 단위만 바꾸는 copyWith는 DrawingGeometry와 DrawingCoordinateSpace에 생성하지 않는다. 명시적으로 새 데이터 묶음을 생성하는 것은 새 내용 작성이며 기존 내용의 환산과 구분한다. 단독 값의 `converted(from:,to:)`도 원본/대상을 필수로 받아 환산한다.

inch→millimeter는 25.4배, 반대는 25.4로 나눈다. 예를 들어 중심(1,0.5)inch·반지름0.25inch는(25.4,12.7)mm·반지름6.35mm다. 원문/ID/라벨은 기하 묶음에 없으며 환산하지 않는다. 저장 값 임의 반올림·태그만 교체·축 반전은 없다. 변환의 비유한 결과/0 소실은 numericRepresentationFailure이며 원래 값은 그대로다. 환산 후 서로 다른 점이 같은 double 좌표로 합쳐지면 경로 검증 실패를 환산의 numericRepresentationFailure로 구분해 전달한다.

계산 내부 기준 단위는 향후 엔진 공개 계약에서 mm로 정할 것을 추천하며 workflow 어댑터가 명시 변환한다. 화면은 앱이 표시 단위·줌·Y 반전을 처리하고 외부 파일은 입출력 어댑터가 파일 단위와 좌표계를 해석한다. 이번에는 길이 환산만 구현했고 화면 변환·출력 이동/배열·회전·반전·비균등 축척은 구현하지 않았다. 단위 환산/형상 편집·계산 공차/제작 최소 여백은 별개다.

## 5. 정의 오류·진단·소비자 미지원

| GeometryErrorCode | 발생 조건 | 유사 오류와 차이 |
|---|---|---|
| missingField | JSON 필수 필드 없음 | null은 invalidType |
| invalidType | 객체/문자열/목록/숫자 타입이 다름 | 수학적 값 오류와 별도 |
| unexpectedField | 알려진 타입의 불필요한 키 | 모르는 kind/unit는 unsupportedTag |
| unsupportedTag | 데이터 계약에 없는 kind/unit | 소비자가 이미 표현된 기하를 계산하지 못하는 것과 별도 |
| nonFiniteNumber | 입력 좌표/반지름/bulge가 NaN·무한대 | 유한 입력의 파생 실패는 numericRepresentationFailure |
| nonPositiveRadius | 원의 반지름<=0 | 원호 bulge=0과 구분 |
| zeroArcBulge | 원호 bulge=0 | 음수/abs>1은 유효 |
| emptyPath | 구간 없음 | 마지막 끝점이 안 닫힌 경우와 별도 |
| degenerateSegment | 경로에서 구간의 시작=끝 | 구간 단독 생성자는 시작점이 없어 검사하지 않음 |
| openBoundary | 마지막 끝점!=경로 시작점 | 자동 선분을 추가하지 않음 |
| numericRepresentationFailure | 파생 반현/반지름/중심·원 극점·환산이 double로 처리 불가 | 수학적 잘못·소비자 미지원으로 바꾸지 않음 |

전용 geometry_errors.dart의 GeometryValidationException은 code, fieldPath, 한국어 기본 설명과 GeometryDiagnostic을 출력한다. 진단은 operation과 작은 역할별 details의 합으로 구성한다. 타입·수치·태그·구간·원호 계산·원/원호 극점 상세를 나누어 관련 없는 nullable 필드를 누적하지 않는다. 상세 필드에는 의미와 단위 문맥을 주석으로 설명한다. 임의 Map·UI 다국어/로깅·범용 오류 프레임워크는 없다. prefixed는 같은 diagnostic/details 객체와 코드를 유지하고 fieldPath만 붙인다. 실제 타입과 원 중심·극점 방향도 12절처럼 제공한다.

예: `boundaries[0].path.segments[0]`, code=numericRepresentationFailure, operation=deriveArcRadius, start=(0,0), end=(2,0), bulge=double.minPositive. 이는 미등록 엔진이 아니라 수치 파생 실패다. `path.segments[1].end`, code=openBoundary는 기대 시작점과 실제 마지막 끝점을 진단에 갖는다. 직접/생성 copyWith에서의 오류는 검증하는 하위 값 기준 경로이며 JSON 복원에서는 부모 경로를 붙인다. 여러 오류가 동시 발생할 때 순서를 호환 계약으로 고정하지 않는다.

표현 가능한 경계도 엔진이 지원하지 않으면 향후 변환 단계에서 unsupportedTextRegion/unsupportedObstacle 같은 **엔진 경계 전용 진단**으로 돌려줘야 한다. 이 코드들은 이번 기하 enum에 추가하지 않았다. 외접 직사각형·빈 장애물로 대체하거나 noFit/정상 빈 결과로 바꾸지 않는다. DXF 미지원도 출력 경계에서 별도로 알려야 한다. 이번에 소비자 지원 검사기나 엔진을 구현한 것은 아니다.

## 6. 파일 구성과 검증 책임

```text
lib/src/geometry/geometry_errors.dart  정의 오류·예외·수치/태그 진단
lib/src/geometry/geometry_json.dart    이 JSON 계약의 구조 검사 (공개 export 아님)
lib/src/geometry/coordinate_space.dart 길이 단위·설계 좌표 문맥·길이 환산
lib/src/geometry/point2.dart           점 값/변환
lib/src/geometry/path_segments.dart    sealed PathSegment·LineTo·ArcTo
lib/src/geometry/geometry_path.dart    시작점/구간 순서·퇴화/원호 파생 검사
lib/src/geometry/closed_boundary.dart  sealed ClosedBoundary·CircleBoundary·PathBoundary
lib/src/geometry/drawing_geometry.dart 단위 문맥이 결합된 경로/경계와 전체 환산
lib/src/text_area_input.dart          기존 원문·명시적 줄바꿈 입력, 변경 없음
```

관련 파일의 .freezed.dart/.g.dart는 생성기로 만들고 Git 관리한다. 오류는 모델 파일에서 분리했고 함수 이름은 read/check/convert/write의 실제 동작을 드러낸다. PathSegment 하위 타입은 같은 library에, ClosedBoundary 하위 타입도 같은 library에 모아 Dart sealed 제약을 지킨다. 다른 파일의 private 필드에 기대지 않고 공개 검증 생성자를 사용한다. 생성 part는 각 모델 library에 둔다. utils/common이나 공통 geometry 패키지는 없다.

업무 역할은 이 폴더의 기하 타입에 섞지 않는다. AppliedDesign/DesignContent/InternalFeature/TextAreaDefinition/PlanarRegion/장식 같은 업무 조립은 필요할 때 별도 design 책임의 파일로 구현한다. 지금 빈 파일·인터페이스는 만들지 않았다.

## 7. 아직 설계인 도안 업무 관계

재사용 원본은 designId/revision/content, 작업 적용 내용은 appliedDesignId/source/content로 구분하는 기존 원칙을 유지한다. 원본을 재조회하지 않아도 실제 적용 내용을 보존한다. 여러 제품이 같은 불변 적용 내용을 공유할 수 있고, 한 제품 변경은 새 내용/ID로 분리해 그 제품만 재연결한다. 전체 적용은 그 시점의 productId 집합을 명시한다.

향후 DesignContent는 coordinateSpace를 한 번 선언하고 실제 외곽 ClosedBoundary, featureId/purpose/boundary를 가진 내부 가공 목록, areaId/label/region을 가진 텍스트 영역, 별도 장식 목록을 소유한다. 텍스트 면은 외부 경계/제외 경계의 역할로 정의하며 닫힌 경계와 내부 면의 유효성을 혼동하지 않는다. 그 조립에는 기하 묶음을 중복 저장하거나 같은 원과 분해 원호를 함께 정본으로 넣지 않는다.

구멍은 CircularHole이 아니라 실제 ClosedBoundary와 가공 목적을 가진 향후 InternalFeature다. 원형·사각·장공·지원 요소로 만든 자유 외형 모두 가능하다. 다만 경계를 저장하는 것과 가공/출력이 지원하는 것은 다르며 포켓 깊이·장비 전략은 새 개발 범위다. 장식/텍스트 경계를 자재 절단 경계로 해석하지 않는다. 장식의 배치 장애물 여부는 명시 규칙이 필요하다.

제품 TextAreaInput은 areaId와 원문/자동·직접 지정 입력을 소유하고 좌표를 중복 저장하지 않는다. 계산 요청은 해당 적용 도안의 실제 영역·외곽/가공 장애물과 문구/규칙/폰트 측정/그룹 내용을 해석해 결합한다. 같은 영역의 이동/크기 변경은 ID/원문/지정 줄을 유지하고 결과를 다시 검토한다. 영역 추가/삭제/교체는 명시 입력/대응이 필요하며 label/목록 순서로 추정하지 않는다. 수량은 문구 배치 조건이 아니다.

workflow는 도안/저장 계약·수명·변환, 엔진은 자체 입력/지원/계산/진단, DXF는 자체 출력 입력/외부 표현을 소유한다. 어댑터가 값을 변환하고 엔진/DXF가 WorkDocument JSON이나 서로의 내부 클래스를 직접 읽지 않는다. 공유 요구를 확인하기 전 공통 geometry 모듈을 만들지 않는다.

## 8. 사례 확인: 데이터 추가와 기능 개발

| 사례 | 현재 값 모델로 표현 | 별도 개발/판정 |
|---|---|---|
| 직사각 외곽·홀 없음 | start+LineTo4개 PathBoundary, 내부 역할은 후속 | 도안 등록/가공 역할은 미구현 |
| 원형 홀6개 | 중심X20/60/100·Y15/45·반지름2인 CircleBoundary6개 | featureId/목적·외곽 포함/홀 간섭 검사 후속 |
| 원호 외곽 | LineTo/ArcTo를 순서대로 구성하고 명시적으로 닫음 | 새 디자인마다 클래스 추가 없음, 자동 배치/출력 지원은 별도 |
| 장공·비원형 구멍 | 시작(10,8), LineTo(20,8), ArcTo(20,12,b=1), LineTo(10,12), ArcTo(10,8,b=1) | 가공 목적/실제 제작 판정 후속 |
| 새로운 비정형 다각형 | 새 끝점 목록을 가진 같은 LineTo/PathBoundary 데이터 | 타원/Bezier 같은 새 요소가 필요하면 개발 |
| 공유 후 b만 변경 | 새 적용 내용/참조로 b만 연결하는 원칙 | 적용 도안/제품/명령은 이번에 미구현 |
| 같은 실형상 단위 변경 | DrawingGeometry.convertedTo로 모든 길이와 태그 동시 변경 | 화면/외부 파일/출력 배치 변환은 후속 |
| 저장 가능하지만 계산 미지원 영역 | 원/비직사각 경계를 그대로 보존 | 엔진에서 지원 검사·전용 실패. 사각형으로 대체 금지 |

원호 큰 bulge와 양방향은 새 타입 추가 없이 데이터만 달라진다. 타원·자유 곡선은 아직 지원하지 않는다. 자기 교차 경로도 구조적으로 만들 수 있으므로 값 생성 성공을 재료 영역의 유효성으로 표시하지 않는다.

## 9. 교체·검증 결과·다음 범위

이전 lib/src/geometry.dart와 그 생성 파일·export를 제거하고 새 최소 계약으로 교체했다. test/geometry_test.dart와 tool/verify_geometry_release.dart도 새 업무 의미로 교체했다. TextAreaInput 소스/생성 파일/기존 테스트는 유지했다. **TextAreaDefinition/TextAreaBounds는 제거했으며 텍스트 영역 정의/제품 연결을 이번에 대체 구현하지 않았다.** label 빈 문자열 보존·영역 ID/원문 연결은 후속 업무 조립에서 유지할 책임이다. 가짜 완성 영역 모델은 없다.

전용 Flutter3.47.7 포함 Dart3.13.5와 기존 Freezed4.0.3/json_serializable6.14.1을 사용했다. 의존성/형제 앱은 변경하지 않았다. 시작 작업 트리/스테이징은 깨끗했으며 커밋·푸시·git add는 하지 않는다.

전체 105개 테스트(기존 입력 74+새 기하 31) 통과, 생성/포맷/분석 성공. 첫 분석의 중괄호 lint 한 건은 수정 후 문제 없음으로 재검증했다. assert 비활성 AOT는 기하 오류 16건과 정상 왕복/불변성/단위 환산, 기존 입력 오류 14건을 통과했다. 자세한 최종 재생성/소비자 확인은 아래 검사 기록에 보탠다. 이는 새 엔진/배치/가공/제작/저장 기능 검증이 아니다.

다음 한 번의 최소 범위는 ClosedBoundary를 도안의 외곽/내부 가공/텍스트 영역 역할로 묶기 위한 첫 업무 조립 계약을 설계하는 것이다. 자기 교차·포함·간섭·면적·글자 배치·제작 가능성, 전체 AppliedDesign·제작 조건·가공 목적·제품 연결·DXF·파일 저장·UI·동기화는 이번에 구현하지 않았다. 위상/관계 허용오차·접촉 정책·장식의 배치 영향·소비자 지원 범위·공용 출처 규약은 여전히 미정이다.

## 10. 이전 값 모델 구현 기록 (현행 설계와 구분)

이전 mm 고정 네 값 모델의 96개 테스트와 AOT 17건은 당시 코드 기록이다. 이번 교체 후 그 타입·JSON/테스트는 현행 계약이 아니다. 재설계 때의 '원은 반드시 두 원호'·'반원 이하만'·'구간별 start/end 중복' 권고도 최신 사용자 결정으로 제거했다. 과거 실행을 새 타입으로 재실행한 것처럼 바꾸지 않는다.

## 11. 최소 기하 초기 구현 당시 검사 기록과 명령

- 최종 analyze: No issues found. 전체 105개 테스트 통과. 기하 AOT 16건/기존 입력 AOT 14건 통과. 작은 좌표의 환산 소실/구간 붕괴도 수학적 입력 오류와 구분해 검사했다.
- 입력 모델과 새 기하를 포함한 생성 파일 14개의 재생성 후 format 해시가 직전 결과와 일치했다. 생성 파일은 직접 편집하지 않았다.
- 별도 build/geometry_consumer(path 의존성)에서 pub get·AOT 컴파일/실행이 코드 생성 없이 통과했다. 소비자에게 Freezed/build_runner/json_serializable 생성 도구는 전파되지 않았다. 실제 Git 참조 앱/Flutter UI 실행은 하지 않았다.
- 문서 링크·JSON 문법과 git diff --check 확인. TextAreaInput 소스/생성 파일·기존 입력 테스트·기존 입력 AOT·pubspec·비교 패키지는 변경하지 않았고 스테이징은 시작과 같이 비어 있다. 형제 앱·의존성·Git 이력은 변경하지 않았다.

```powershell
$workflowDart = "$PWD/.toolchains/flutter-3.47.7/bin/cache/dart-sdk/bin/dart.exe"
& $workflowDart pub get
& $workflowDart run build_runner build
& $workflowDart format lib test tool/verify_geometry_release.dart
& $workflowDart analyze
& $workflowDart test
& $workflowDart compile exe tool/verify_geometry_release.dart -o build/verify_geometry_release.exe
& ./build/verify_geometry_release.exe
& $workflowDart compile exe tool/verify_text_input_release.dart -o build/verify_text_input_release.exe
& ./build/verify_text_input_release.exe
```

소비자는 같은 AOT 파일을 bin/main.dart로 복사하고, 이 프로젝트 루트의 path 의존성만 선언한 별도 패키지다. 소비자 폴더에서 동일 SDK의 pub get, compile exe bin/main.dart -o consumer.exe, consumer.exe를 실행했다. SDK/캐시/빌드/소비자 파일은 Git에서 제외한다. 새 엔진 계산·충돌 검사·실제 제작 시험을 실행한 것은 아니다. 커밋·푸시는 하지 않았다.

## 12. 수치 회귀·극점·진단 개선 검증 (2026-10-25 후속)

시작 HEAD a4281cc, 변경·스테이징 없음. 기존 코드에서 먼저 두 Dart 회귀를 실행해 극소 bulge 사례는 잘못 거부되고, 큰 원호 극점 사례는 잘못 허용됨을 확인했다. 새 회귀 테스트 두 건이 의도대로 실패한 다음 수정했다. 기존 테스트의 업무 의미를 유지하고 진단 조회만 새 상세 타입에 맞췄다.

### 진단 구조와 실제 출력

GeometryErrorCode.description은 모든 코드에 개발자용 한국어 기본 설명을 제공한다. 예외 출력은 코드·필드 경로·설명·operation·필요한 details를 포함한다. 타입 오류에는 expectedType/actualType이 있고 null은 Null로 표시한다. UI 문구/다국어/로깅을 구현한 것은 아니다.

GeometryDiagnostic은 operation+details 두 필드다. details는 이 기하 오류 전용의 작은 sealed 합으로 나눴다.

| 상세 타입 | 필요한 정보와 단위 |
|---|---|
| GeometryTypeDetails | 기대/실제 타입 문자열. 길이값 아님 |
| GeometryNumberDetails | 입력/환산 전 단일 수치. 해당 문맥 단위 또는 무차원 bulge |
| GeometryTagDetails | 보정하지 않은 원래 태그 |
| GeometrySegmentDetails | 구간 시작/끝점(문맥 단위), 원호일 때 bulge(무차원) |
| GeometryArcCalculationDetails | 원래 구간과 실패 연산의 파생 수치(문맥 길이) |
| GeometryCircleExtremumDetails | 실제 centerX/centerY/radius·direction·극점 좌표 value(문맥 길이) |
| GeometryArcExtremumDetails | 원호의 구간 입력+해당 기반 원의 실패 극점 상세 |

원 중심을 startX/startY로 표현하지 않는다. 원/원호 극점은 중심·반지름·positiveX/negativeX/positiveY/negativeY를 명시한다. segment는 원호 입력에만 쓰인다. 필드별 API 주석에 의미·단위를 적었다. 상세 타입은 필요한 정보만 필수로 가지며 모든 오류에 nullable 필드를 계속 더하는 구조보다 원인별 탐색이 쉽다. 범용 오류 자료 Map/프레임워크나 새 업무 모델은 없다.

assert 비활성 AOT에서 실제 출력한 예:

```text
GeometryValidationException(code=invalidType, fieldPath=boundaries[0].center.x, 설명=필드의 값 타입이 기대 타입과 다릅니다., operation=readNumber, expectedType=num, actualType=String)
GeometryValidationException(code=numericRepresentationFailure, fieldPath=segments[0], 설명=파생 계산 또는 단위 환산 결과를 double로 표현할 수 없습니다., operation=deriveArcExtremum, start=(1e+308, 0.0), end=(1e+308, 1e+308), bulge=2.0, center=(1.375e+308, 5e+307), radius=6.25e+307, direction=positiveX, value=Infinity)
```

중첩 JSON 복원은 하위 진단 객체·코드와 실제 원인값을 보존하고 `boundaries[0].path.segments[0]` 같은 부모 경로만 붙인다. prefixed의 객체 동일성과 복원 후 타입/구간/극점 값도 테스트했다. 예외 문자열을 파싱해 오류를 분류하지 않는다.

### 중간 오버플로 수정

반현 길이를 h, abs(bulge)를 b라 할 때 radius=h*b/2+h/(2*b), 중심의 현 법선 오프셋은 bulge 부호에 따라 h/(2*b)-h*b/2다. 기존처럼 0.5/b를 먼저 만들지 않고 길이와 나눗셈을 결합한다. 곱은 큰 인자를 먼저 반으로 나누고, 몫은 분자의 선행 소실도 피하는 순서를 선택한다. b가 1 부근일 때는 항별 언더플로/상쇄를 피하는 동치식을 사용한다. 이 분기는 연산 안정화를 위한 것이며 bulge 크기 제한·0 보정 정책이 아니다.

start=(0,0), end=(2e-300,0), bulge=±1e-310은 반지름과 중심 오프셋 크기가 약 5e9로 유한해 이제 생성·copyWith·JSON 복원이 통과한다. 실제 반지름/중심이 표현 불가능한 경우는 deriveArcRadius/deriveArcCenterX 등의 numericRepresentationFailure로 계속 거부한다.

### 실제 원호 위의 극점만 검사

중심/반지름을 계산한 뒤 네 축 방향이 **그 원호가 차지하는 현의 반평면**에 있는지 먼저 판정한다. 단위 현 법선 n과 중심의 현 법선 오프셋 d, 반지름 r로 극점 방향 u의 부호는 d/r+n·u다. 양수 bulge의 원호는 유향 현 오른쪽, 음수는 왼쪽 원주다. 이 판정은 중심이 현 어느 쪽에 있는지에 따라 짧은/긴 원호를 자연스럽게 구분한다. 각도 차를 빼서 0/2π 경계를 처리하거나 제작 epsilon을 넣지 않는다.

원호에 포함된 방향에 대해서만 centerX±radius 또는 centerY±radius를 계산해 유한성을 검사한다. 원호 밖의 기반 원 극점은 계산/거부하지 않는다. 이는 기하 관계/충돌 알고리즘이 아니라 기존 원호 수치 표현 검증의 보완이다.

start=(1e308,0), end=(1e308,1e308), bulge=2는 중심=(1.375e308,5e307), 반지름=6.25e307까지 유한하지만 오른쪽 실제 극점이 Infinity이므로 이제 거부한다. 같은 기반 원의 반대쪽 짧은 원호를 전부 거부하지 않는다. 네 방향 회전·시계/반시계 반전, 반원/반원 초과, 각도 0 경계를 가로지르는 짧은 원호, 원호 밖의 극점을 별도로 검사했다.

### 실행 결과

- 전용 Dart3.13.5에서 format·analyze 성공, 전체 136개 테스트(기존 105+수치/진단 회귀 31) 통과. 기존 원문/줄바꿈·기하 정상/오류 사례는 유지했다.
- assert 비활성 AOT: 새 tool/verify_geometry_numeric_release.dart의 정상 원호 5건/오류 7건, 기존 기하 오류 16건·입력 오류 14건 및 정상 동작 통과. 위 실제 오류 예시는 이 새 AOT 출력이다.
- 생성 소스는 직접 편집하지 않았다. build_runner 재생성 후 14개 생성 파일이 직전 해시와 같고 최종 정적 분석도 문제 없음이다. 새 의존성·업무 모델·UI·엔진·DXF는 추가하지 않았다.
- 자기 교차·포함·간섭·면적·제작 공차·일반 CAD 계산 기능은 여전히 미구현이다. 형상·JSON 필드나 단위 환산의 업무 의미는 바뀌지 않았고 진단의 평면 필드는 역할별 details로 바뀌었다. 스테이징·커밋·푸시는 하지 않는다.

기존 11절 명령에 아래 수치 회귀 AOT를 더해 실행했다.

```powershell
& $workflowDart format lib test tool/verify_geometry_numeric_release.dart
& $workflowDart compile exe tool/verify_geometry_numeric_release.dart -o build/verify_geometry_numeric_release.exe
& ./build/verify_geometry_numeric_release.exe
```
