# r_edit_workflow

현재 기하 값 계약은 [최소 기하 모델](docs/applied-design-geometry.md)이다. 이전 직사각 명판/원형 홀/텍스트 영역 값은 제거했으며, 기하 요소와 업무 역할을 구분한다. 전체 도안·가공·텍스트 영역 조립은 아직 구현하지 않았다.

R-edit의 작업 데이터, 변경 영향, 결과 확인 및 저장·출력 흐름을 담당하는 순수 Dart 라이브러리다.

## 현재 구현

영역별 원문·자동/직접 지정 줄바꿈의 불변 값과 검증, JSON 변환과 점·단위 문맥·선분/원호 경로·원/닫힌 경로 경계와 환산을 구현했다.
공개 진입점은 `lib/r_edit_workflow.dart`, 구현은 `lib/src/text_area_input.dart`다.

- `TextAreaInput(areaId:, sourceText:, lineBreak:)`: 영역 원문과 줄바꿈을 하나의 유효한 값으로 생성한다. 제품 전체가 아닌 영역 입력이라는 책임을 드러내기 위해 설계 후보 ProductTextInput 대신 이 이름을 선택했다.
- `LineBreakInput`: `AutomaticLineBreak` / `SpecifiedLineBreak`의 sealed 합 타입이다.
- `SpecifiedLineBreak(List<String>)`: 지정 줄을 방어 복사하고 수정 불가 목록으로 보관한다. 한 줄도 직접 지정이다.
- `TextInputValidationException`: `TextInputErrorCode code`, `String fieldPath`로 실패 원인과 필드/목록 위치를 전달한다. 이 fieldPath는 문자 오프셋이 아니다.
- 값 동등성·hashCode를 제공한다. 원문, 방식, 지정 줄 구성이 다르면 다른 값이다.

```dart
import 'dart:convert';
import 'package:r_edit_workflow/r_edit_workflow.dart';

final input = TextAreaInput(
  areaId: 'area-title',
  sourceText: 'PUMP  A-1 ',
  lineBreak: SpecifiedLineBreak(['PUMP  A-1 ']),
);
final encoded = jsonEncode(input.toJson());
final restored = TextAreaInput.fromJson(jsonDecode(encoded));
assert(restored == input);
```

수정은 원문과 지정 줄을 함께 전달한 새 TextAreaInput 또는 생성된 copyWith로 교체한다. 생성자와 copyWith 모두 전체 조건을 검사하므로 불일치한 부분 수정은 거부된다. setter·범용 편집 프레임워크는 없다. LineBreakInput의 sealed 구분을 유지하며 구체 줄 타입의 수정값을 부모 copyWith에 전달한다.

## 입력 지원 범위

areaId는 빈 문자열을 허용하지 않고 표시 이름·원문으로 생성하지 않는다. 공백을 trim하지 않으므로 ID도 전달한 값을 그대로 보존한다. 실제 도안 영역 참조 존재 여부는 아직 검사하지 않는다.

원문과 줄 조각은 공백·기호·대소문자·Unicode 표현을 그대로 보존한다. 직접 지정은 1개 이상의 줄을 순서대로 연결한 내용이 원문과 정확히 같아야 한다. 자동/직접 방식은 항상 명시한다.

빈 원문·빈 줄·원문/줄의 CR 또는 LF는 **이번 첫 구현에서는 미지원**이다. 이는 전체 제품 정책의 확정이 아니다. 공백만 있는 문자열과 탭은 빈 문자열로 바꾸지 않으며 지원한다. 이 값의 검증 성공은 배치 가능·제작 가능 판정이 아니다. 문자 위치/오프셋이나 Unicode 분할 단위는 정의하지 않는다.

## JSON과 오류

직접 지정 한 줄 예시:

```json
{
  "areaId": "area-title",
  "sourceText": "PUMP  A-1 ",
  "lineBreak": {"mode": "specified", "lines": ["PUMP  A-1 "]}
}
```

자동 방식은 `"lineBreak": {"mode": "automatic"}`다. 이 형식은 영역 입력 조각이며 WorkDocument 전체 스키마·파일 I/O·미완료 저장 기능이 아니다.

`fromJson(Object?)`는 JSON 디코딩 결과를 받는다. 필수 누락은 missingField, 명시적 null/잘못된 타입은 invalidType, 알 수 없는 문자열 방식은 unknownLineBreakMode다. 알 수 없는 필드와 자동 방식의 lines도 unexpectedField로 거부해 데이터를 조용히 버리지 않는다. 해석 가능한 첫 오류를 예외로 전달하며 모든 오류를 집계하지 않는다. JSON 문자열 문법 자체는 dart:convert의 jsonDecode가 검사한다.

| 코드 | 의미 / 경로 예 |
|---|---|
| missingField / invalidType | 필수 누락 / 타입 오류, areaId·sourceText·lineBreak.mode·lineBreak.lines[1] 등 |
| unknownLineBreakMode / unexpectedField | 알 수 없는 방식 / 허용하지 않은 필드 |
| emptyAreaId / emptySourceText | 빈 식별자 / 이번 미지원 빈 원문 |
| emptySpecifiedLines / emptySpecifiedLine | 빈 지정 목록 / 이번 미지원 빈 줄 |
| sourceContainsCrLf / specifiedLineContainsCrLf | 원문 / 지정 줄 내 CR 또는 LF |
| specifiedLinesMismatchSourceText | 지정 줄의 연결 내용과 원문 불일치 |

값 비교·복사에는 Freezed 4.0.3, JSON 필드 변환에는 json_serializable 6.14.1을 사용한다. 업무 검증과 오류 경계는 직접 작성한다. runtime annotation 3.1.0/4.12.0, build_runner 2.16.2를 채택했고 기존 lints·test 제약은 유지했다. 이 작은 JSON은 전체 문서 형식이 아니다.

## 개발과 검증

프로젝트 전용 `.toolchains/flutter-3.47.7`의 포함 Dart 3.13.5 stable을 사용하며 SDK 제약은 `^3.13.5`다. 패키지 runtime은 Flutter에 의존하지 않는다. 공유 SDK·전역 PATH는 변경하지 않는다. 영구 SDK·IntelliJ 경로와 소비자 영향은 [전환 기록](docs/freezed-migration.md)에 있다.

```powershell
$workflowDart = "$PWD/.toolchains/flutter-3.47.7/bin/cache/dart-sdk/bin/dart.exe"
& $workflowDart pub get
& $workflowDart run build_runner build
& $workflowDart format lib test tool/verify_text_input_release.dart
& $workflowDart analyze
& $workflowDart test
```

현재 네이밍·JSON과 실제 검사 결과는 [초기 정리 기록](docs/input-naming-json.md)에 있다. 이전 70개 테스트·AOT 실행 결과는 [당시 전환 기록](docs/freezed-migration.md)에 보존한다.
이 결과는 영역 입력 모델 검증이며 실제 배치·저장·출력·Type3 검증이 아니다.
라이브러리 pubspec.lock, .dart_tool, .toolchains, build, IDE 설정과 로컬 override는 Git 관리에서 제외한다. 필요한 lib/src/*.freezed.dart와 *.g.dart는 Git 관리 대상이다. 생성 파일을 직접 수정하지 않고 재생성 일치를 확인한다.

## 아직 구현하지 않은 범위

WorkDocument 전체, WorkSession, 적용 도안·수량·그룹·결과·작업자 확인, 엔진·DXF·파일 I/O·Flutter 연결은 미구현이다. 앱 → 업무 흐름 → 배치 엔진·DXF의 공개 API 의존 방향을 유지하며 아직 없는 패키지를 선언하지 않는다.

## 최소 기하 값

공개 API는 Point2, LengthUnit, DrawingCoordinateSpace, PathSegment(LineTo/ArcTo), GeometryPath, ClosedBoundary(CircleBoundary/PathBoundary), DrawingGeometry와 전용 GeometryErrorCode/GeometryDiagnostic/GeometryValidationException이다.

경로는 start 하나와 end를 가진 순서 구간을 소유한다. 원호 bulge는 유한하고 0이 아니며 반원 초과·양쪽 방향을 허용한다. 경로가 퇴화/파생 중심·반지름 표현 가능성을 검사하고 경로 경계가 명시적 닫힘을 검사한다. 원은 중심·양수 반지름을 정본으로 보존한다. 목록·반환 JSON은 모델과 분리된다.

DrawingGeometry는 문맥에 millimeter/inch를 명시한다. 설계 기준점(0,0), X 오른쪽/Y 위쪽이며 외곽 왼쪽 아래 제한이 없다. convertedTo는 문맥과 모든 길이를 함께 환산하고 bulge를 유지한다. 단위만 바꾸는 copyWith는 제공하지 않는다. 화면 변환·출력 배열·회전·반전은 없다.

```dart
final geometry = DrawingGeometry(
  coordinateSpace: DrawingCoordinateSpace(lengthUnit: LengthUnit.inch),
  paths: [],
  boundaries: [CircleBoundary(center: Point2(x: 1, y: 0.5), radius: 0.25)],
);
final millimeters = geometry.convertedTo(LengthUnit.millimeter);
final restored = DrawingGeometry.fromJson(jsonDecode(jsonEncode(millimeters.toJson())));
```

자기 교차·포함·간섭·면적·글자 배치·제작 판정은 검사하지 않는다. TextAreaDefinition/TextAreaBounds는 제거했고, 새 텍스트 영역 정의/제품 연결은 미구현이다. TextAreaInput의 원문·자동/직접 지정 입력은 유지한다.

2026-10-25: 생성·포맷·분석 통과, 기존 입력 74+기하 31=105개 테스트 통과. assert 비활성 AOT 기하 오류 16건/입력 오류 14건과 정상 동작 확인. JSON·오류 진단·파일 구성·수치 한계·재생성/소비자 결과는 [계약 기록](docs/applied-design-geometry.md)에 있다. 이전 96개/직사각 모델 검사 결과와 구분한다.

## 기준 문서

- [개발 지침](AGENTS.md)
- [현재 계약](docs/contract.md)
- [모델 설계](docs/model-design.md)
- [현재 상태와 다음 작업](docs/next-step.md)
- 형제 앱 [문서 색인](../r_edit/docs/README.md), [현재 결정](../r_edit/docs/decisions.md), [모듈 경계](../r_edit/docs/module-boundaries.md)

참고 앱 HEAD는 ac11bd44cf098f3cc16b69b2d82d67eb94d1844a다. 추가 원본 자료의 실제 경로·해시와 해당 앱 작업 트리 상태는 모델 설계에 기록했다. 전체 요구사항·과거 시험 자료를 이 저장소에 반복 복사하지 않는다.

## 모델 도구 비교와 개발 규칙 검토

[과거 Freezed/built_value 비교](docs/model-tools-comparison.md)와 [전환 기록](docs/freezed-migration.md)은 당시 코드·이름·결과를 보존한다. 현재 기준은 [네이밍·JSON 정리](docs/input-naming-json.md)와 [개발 기준](docs/development-rules-draft.md)이다.
비교 코드는 당시 공개 API를 참조하는 과거 검증 자료이며 이번 이름 변경에 맞춰 다시 실행하지 않았다.

JSON 경계에서는 구조·필수·타입·방식을 검사하고 업무 값 생성자에서는 원문과 지정 줄 연결 등의 조건을 검사한다. 줄 입력을 중복 생성하지 않는다. 복수 오류의 발생 순서는 고정하지 않는다. 이전 auto/manual 방식과 이전 공개 이름은 지원하지 않으며 별칭·마이그레이션은 없다.
