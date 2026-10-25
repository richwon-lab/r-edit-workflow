# 도안 구성 값과 텍스트 입력 연결 계약

상위 제품의 적용 형상 참조·개별 변경·영역 대응은 [제품·도안 연결 설계](product-design-binding.md)에 정리했다. 설계이며 이 문서의 값 모델/검증 구현 범위를 늘린 것은 아니다.

2026-10-25. 구현 대상은 도안 구성의 값·ID와 입력 참조 검증이다. 배치/제작 성공·완료 저장 판정이 아니다. 시작 HEAD 489c1f3, 변경·스테이징 없음. AGENTS·개발 기준·현재 계약·최소 기하/입력 코드를 확인했고 기존 기하/원문 테스트·의존성과 형제 앱은 변경하지 않았다.

## 공개 API와 소유 관계

| 모델/필드 | 타입·필수성 | 책임/검증 |
|---|---|---|
| DesignGeometry.coordinateSpace | DrawingCoordinateSpace, 필수 | 전체의 단위 선언 한 곳. 하위 경계/구멍/영역이 상속 |
| outline | ClosedBoundary, 필수 | 실제 외곽 경계 하나. 첫 구성 범위이며 최종 프로그램 형상 제한 아님 |
| cutouts | List<CutoutDefinition>, 필수 | 관통 제거 정의. cutoutId는 이 목록 안 유일. [] 명시 가능 |
| textAreas | List<TextAreaDefinition>, 필수 | 텍스트 영역 정의. areaId는 이 목록 안 유일. [] 명시 가능 |
| CutoutDefinition.cutoutId / boundary | String / ClosedBoundary, 필수 | 안정 ID와 실제 관통 경계. 원형·사각·장공 타입으로 나누지 않음 |
| TextAreaDefinition.areaId / label / region | String / String / TextRegion, 필수 | 원문 입력과 영역 ID로 연결. label은 빈 값/중복 허용, trim/정규화 없음 |
| TextRegion.outer / exclusions | ClosedBoundary / List<ClosedBoundary>, 필수 | 배치 허용 영역의 외부/명시 제외 경계. 구멍에서 자동 생성하지 않음 |

ID는 빈 문자열만 거부하고 전달 문자열을 그대로 보존한다. areaId는 기존 TextAreaInput과 같은 규약이다. 공백만인 ID를 trim해 빈 값으로 만들지 않는다. cutoutId와 areaId는 별도 소유 범위라 서로 같은 문자열이어도 가능하다. 표시 이름/좌표/목록 순서로 ID를 생성하거나 연결하지 않는다.

각 목록은 방어 복사·수정 불가이며 toJson의 중첩 Map/목록도 새 값이다. 기하 하위 값은 기존 ClosedBoundary의 검증을 그대로 사용한다. 값 생성 성공은 경계의 포함·간섭·자기 교차·면적·실제 글자 충돌/홀 회피·제작 가능성을 보장하지 않는다. 영역과 구멍이 겹치거나 제외 경계가 외부 경계 밖에 있어도 이번 정의 단계에서는 표현할 수 있다. 구멍을 영역에서 빼거나 영역을 나누지 않는다.

## 이름과 파일 선택

| 이름 | 검토한 대안 | 선택 이유 |
|---|---|---|
| DesignGeometry | DesignContent / PlateGeometry | 필요한 좌표·역할 구성만 뜻하고 생산/장식/출처 전체를 포함한 것처럼 읽히지 않음 |
| CutoutDefinition | HoleDefinition / ThroughCutout | 단순 원형 홀을 연상시키지 않고 관통 제거의 실제 경계를 정의한다는 의미 |
| TextAreaDefinition | DesignTextArea / TextRegionDefinition | 기존 TextAreaInput과 정의/입력 책임 대비. 실제 면 내용은 TextRegion으로 분리 |
| TextRegion | TextAreaBounds / LayoutRegion | 직사각 bounding box가 아닌 실제 외부/제외 경계. 계산 결과가 아니라 입력 정의 |
| validateTextAreaInputs | bindTextAreaInputs / validateProduct | 새 제품/연결 모델을 만드는 기능이 아니라 영역 입력 대조만 수행함 |

```text
lib/src/design/design_geometry.dart       DesignGeometry·소유 ID 중복 검사·전체 환산
lib/src/design/cutout_definition.dart     CutoutDefinition·관통 경계
lib/src/design/text_area_definition.dart  TextAreaDefinition·영역 ID/표시 이름
lib/src/design/text_region.dart           TextRegion·외부/제외 경계
lib/src/design/design_json.dart           공유 JSON 구조 검사·경계 직렬화 (내부)
lib/src/design/design_errors.dart         업무 정의/참조 오류·설명·명시적 상세
lib/src/design/text_area_input_validation.dart  입력 ID 대조
각 모델의 .freezed.dart / .g.dart          모델별 생성 소스
```

네 모델은 각각 독립 Dart library이며 모델 전용 JSON 변환은 해당 파일에 둔다. 실제 공유하는 JSON 구조 검사만 design_json.dart에서 가져오고 공개 진입점에는 export하지 않는다. 모델끼리 private 접근을 위해 part로 묶지 않는다.

기하 요소 폴더의 CircleBoundary/PathBoundary/GeometryPath와 역할 파일을 분리했다. DrawingGeometry는 독립적인 무역할 기하 묶음으로 남지만 DesignGeometry에 포함하지 않는다. 같은 내용의 두 목록을 동기화하거나 이중 정본으로 저장하지 않는다. 전체 AppliedDesign·재사용 출처·도안 공유 명령을 이 모델에 붙이지 않는다.

## 생성·수정·환산

```dart
final boundary = CircleBoundary(center: Point2(x: 0, y: 0), radius: 20);
final design = DesignGeometry(
  coordinateSpace: DrawingCoordinateSpace(lengthUnit: LengthUnit.millimeter),
  outline: boundary,
  cutouts: [CutoutDefinition(cutoutId: 'mount', boundary: boundary)],
  textAreas: [TextAreaDefinition(
    areaId: 'title', label: '',
    region: TextRegion(outer: boundary, exclusions: []),
  )],
);
final changed = design.copyWith(textAreas: [
  design.textAreas.single.copyWith(label: '본문'),
]);
final inches = changed.convertedTo(LengthUnit.inch);
```

이 예시는 같은 경계를 다른 역할에 쓸 수 있음을 보일 뿐 실제 제작 설계가 아니다. label·ID·원문을 환산하지 않는다. convertedTo는 외곽, 모든 관통 경계, 모든 영역 외부/제외 경계와 문맥을 함께 환산한다. 원호 bulge는 무차원으로 유지한다. 화면 변환/출력 배열/회전/반전은 없다.

하위 세 값의 copyWith·값 비교와 필드 JSON 변환은 기존 Freezed/json_serializable이 생성한다. DesignGeometry는 단위만 바꾸는 copyWith가 생기지 않도록 생성 copyWith를 끄고 outline/cutouts/textAreas만 받는 짧은 copyWith를 직접 작성했다. 새 생성자를 호출해 소유 ID를 재검증하며 단위 문맥은 유지한다. 단위 변경은 convertedTo로만 제공한다. 직접 새 문맥/숫자로 값을 작성하는 것은 환산과 다른 신규 데이터 작성이다.

## JSON 예시

모두 필수이며 누락을 빈 목록/기본 단위로 보정하지 않는다. 숫자 처리와 kind 태그는 기존 기하 계약을 따른다. 다음은 도안 구성 조각이며 전체 작업 파일 스키마가 아니다.

```json
{
  "coordinateSpace": {"lengthUnit": "millimeter"},
  "outline": {"kind":"circle","center":{"x":0,"y":0},"radius":50},
  "cutouts": [
    {"cutoutId":"mount","boundary":{"kind":"circle","center":{"x":5,"y":5},"radius":2}}
  ],
  "textAreas": [
    {"areaId":"title","label":"","region":{
      "outer":{"kind":"circle","center":{"x":0,"y":0},"radius":20},
      "exclusions":[{"kind":"circle","center":{"x":-5,"y":-5},"radius":1}]
    }}
  ]
}
```

제외 경계와 구멍은 별도 내용이다. 자동 차집합이나 배치 가능 판정은 하지 않는다. 포켓/깊이·설비/공정 순서·자재/두께/색상·장식 필드/임의 기본값은 없다.

## 입력 연결 API

```dart
final inputs = [TextAreaInput(
  areaId: 'title', sourceText: ' PUMP A ',
  lineBreak: SpecifiedLineBreak([' PUMP A ']),
)];
final issues = validateTextAreaInputs(design: design, inputs: inputs);
for (final issue in issues) {
  print(issue); // code, fieldPath, 한국어 설명, ID/목록 위치
}
```

정의된 각 영역에 입력 하나가 정확히 대응해야 한다. 입력 순서가 달라도 areaId만 맞으면 된다. input 목록/원문/공백/Unicode/지정 줄/자동·직접 지정 방식을 변경하지 않는다. 반환 issue 목록은 수정 불가다. 입력을 만들어 채우거나 정렬한 새 입력 목록을 반환하지 않는다.

중복 입력, 정의 없는 입력, 누락을 독립적으로 모아 반환한다. 중복된 미정의 입력에는 중복과 미정의가 모두 나올 수 있다. 중복된 기존 ID는 존재하므로 그 ID의 누락 진단을 더하지 않는다. 진단 순서를 영구 호환 계약으로 보장하지 않는다.

영역 0개/입력 0개는 표현 가능하고 연결 issue도 없다. 이는 제품 계산 완료/저장 가능을 뜻하지 않는다. 빈 원문은 현재 TextAreaInput의 미지원 규약을 그대로 유지한다. 공백만인 원문은 보존하며 입력 누락을 빈 원문/자동 방식으로 채우지 않는다.

## 오류와 진단

정의 구성 실패는 DesignValidationException이며 code/fieldPath/issue를 제공한다. 입력 연결은 예외 대신 List<DesignValidationIssue>를 반환한다. 같은 업무 전용 오류 파일을 사용하지만 GeometryErrorCode에 업무 코드를 추가하지 않았다.

| DesignErrorCode | 발생 조건/구분 | 위치·상세 |
|---|---|---|
| missingField / invalidType / unexpectedField | 필수 누락 / 기대·실제 타입 불일치 / 알려지지 않은 필드 | label, exclusions 등. 타입 상세는 expectedType/actualType |
| emptyCutoutId / emptyAreaId | 빈 ID. label 빈 값은 해당하지 않음 | cutoutId/areaId와 원래 ID |
| duplicateCutoutId / duplicateAreaId | 도안의 각 소유 목록 안 중복 | cutouts[1].cutoutId 등과 ID·firstIndex·duplicateIndex |
| duplicateInputAreaId | 입력 목록의 areaId 중복 | inputs[1].areaId와 ID·두 인덱스 |
| unknownInputAreaId | 도안에 없는 영역의 입력 | inputs[2].areaId와 원래 ID |
| missingAreaInput | 정의된 영역의 입력 없음 | textAreas[1].areaId와 누락 ID |

DesignIssueDetails는 식별자(DesignIdentifierDetails), 중복 두 위치(DesignDuplicateDetails), 타입(DesignTypeDetails)의 작은 합이다. 임의 Map·범용 오류 프레임워크는 없다. 업무 중첩 오류는 원래 issue 상세를 유지하고 필드 경로만 붙인다.

하위 기하 오류는 업무 예외로 바꾸지 않고 **GeometryValidationException 자체의 코드/diagnostic을 보존**하며 경로만 붙인다. 예: `textAreas[0].region.exclusions[0].radius`의 nonPositiveRadius. 원호 수치/불명 태그도 기존 기하 진단 그대로다. JSON 복원에서 하위 값을 한 번씩 생성하고 생성기 오류 문자열을 분석하지 않는다.

assert 비활성 실행에서 실제 출력한 연결 예:

```text
duplicateInputAreaId, fieldPath=inputs[1].areaId, 설명=입력 목록의 영역 ID가 중복됩니다., id=" a ", firstIndex=0, duplicateIndex=1
unknownInputAreaId, fieldPath=inputs[2].areaId, 설명=입력에 연결할 도안 영역이 없습니다., id="unknown"
missingAreaInput, fieldPath=textAreas[1].areaId, 설명=도안 영역에 대응하는 입력이 없습니다., id="b"
```

## 검증 결과와 미구현 범위

전용 Flutter3.47.7 포함 Dart3.13.5와 기존 생성기를 사용했다. pub get·코드 생성·format·analyze 성공, 기존 136+새 17=153개 테스트 통과. 비정형 외곽/원형·사각·장공 내부 경계, 비직사각 영역·명시 제외, 겹침 표현, ID/입력 대응, Unicode·빈 label, 방어 복사·반환 JSON 분리, 생성/copyWith/중첩 복원과 전체 환산을 확인했다. 값/연결 검증이며 실제 배치·제작 성공 시험이 아니다.

새 assert 비활성 도안 AOT는 정의 오류 8건·하위 기하 오류 1건, 정상 왕복/변경 방어/전체 환산/입력 연결과 세 진단을 확인했다. 최종 기존 AOT·재생성 일치·생성 없는 소비자 확인은 아래 기록을 따른다.

전체 제품/작업 문서·AppliedDesign·도안 공유 명령·결과 무효화·가공 목적 체계·제작 조건/장식·배치 엔진·DXF·파일 저장·UI·동기화는 미구현이다. 정의와 참조 성공을 제작/배치/저장 승인으로 표시하지 않는다. 다음 한 가지 작업은 이 도안/입력에서 배치 요청을 준비할 때 필요한 첫 규칙·폰트 측정·엔진 지원 조건을 문서로 정하는 것이다. 이번 성공을 근거로 아직 없는 엔진/가짜 계산 결과를 붙이지 않는다.

### 최종 실행 기록

생성 소스 16개(기존 14+새 업무 역할 2)의 재생성 후 format 해시가 직전 값과 일치했다. 생성 파일을 직접 편집하지 않았고 새 .freezed.dart/.g.dart는 Git 관리 대상이다. 기존 수치/진단 AOT 정상 5/오류 7건, 기하 AOT 오류 16건, 입력 AOT 오류 14건도 현재 코드로 컴파일/실행해 통과했다.

별도 build/design_consumer(path 의존성)에서 코드 생성 없이 pub get·AOT 컴파일/실행을 통과했다. 도안 정의 오류 8/하위 기하 오류 1건과 정상 왕복/불변성/환산/연결을 재확인했다. 소비자 그래프에는 annotation·collection·meta만 전파되고 Freezed/build_runner/json_serializable 생성기는 없다. 실제 Git 참조 앱이나 Flutter UI/제작 장비 검증은 수행하지 않았다.

```powershell
$workflowDart = "$PWD/.toolchains/flutter-3.47.7/bin/cache/dart-sdk/bin/dart.exe"
& $workflowDart pub get
& $workflowDart run build_runner build
& $workflowDart format lib test tool/verify_design_geometry_release.dart
& $workflowDart analyze
& $workflowDart test
& $workflowDart compile exe tool/verify_design_geometry_release.dart -o build/verify_design_geometry_release.exe
& ./build/verify_design_geometry_release.exe
```

기존 verify_geometry_numeric_release.dart, verify_geometry_release.dart, verify_text_input_release.dart도 각각 같은 SDK의 compile exe와 assert 비활성 실행으로 확인했다. 소비자는 위 새 AOT 파일을 bin/main.dart로 복사해 동일 SDK에서 pub get, compile exe bin/main.dart -o consumer.exe, consumer.exe를 실행했다. SDK·캐시·빌드/소비자·라이브러리 lock은 제외한다. 커밋·푸시·스테이징은 하지 않았다.
