# r_edit_workflow

R-edit의 작업 데이터, 변경 영향, 결과 확인 및 저장·출력 흐름을 담당하는 순수 Dart 라이브러리다.

## 현재 구현

영역별 원문·자동/직접 지정 줄바꿈의 불변 값과 검증, JSON 변환만 구현했다.
공개 진입점은 `lib/r_edit_workflow.dart`, 구현은 `lib/src/text_area_input.dart`다.

- `TextAreaInput(areaId:, sourceText:, lineBreak:)`: 영역 원문과 줄바꿈을 하나의 유효한 값으로 생성한다. 제품 전체가 아닌 영역 입력이라는 책임을 드러내기 위해 설계 후보 ProductTextInput 대신 이 이름을 선택했다.
- `LineBreakSpec`: `AutoLineBreak` / `ManualLineBreak`의 sealed 합 타입이다.
- `ManualLineBreak(List<String>)`: 지정 줄을 방어 복사하고 수정 불가 목록으로 보관한다. 한 줄도 직접 지정이다.
- `TextInputException`: `TextInputErrorCode code`, `String path`로 실패 원인과 필드/목록 위치를 전달한다. 이 path는 문자 오프셋이 아니다.
- 값 동등성·hashCode를 제공한다. 원문, 방식, 지정 줄 구성이 다르면 다른 값이다.

```dart
import 'dart:convert';
import 'package:r_edit_workflow/r_edit_workflow.dart';

final input = TextAreaInput(
  areaId: 'area-title',
  sourceText: 'PUMP  A-1 ',
  lineBreak: ManualLineBreak(['PUMP  A-1 ']),
);
final encoded = jsonEncode(input.toJson());
final restored = TextAreaInput.fromJson(jsonDecode(encoded));
assert(restored == input);
```

수정은 원문과 지정 줄을 함께 전달한 새 TextAreaInput을 만들어 교체한다. setter·부분 copyWith·범용 편집 명령 프레임워크는 없다. 실패하면 기존 값은 그대로다.

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
  "lineBreak": {"mode": "manual", "lines": ["PUMP  A-1 "]}
}
```

자동 방식은 `"lineBreak": {"mode": "auto"}`다. 이 형식은 영역 입력 조각이며 WorkDocument 전체 스키마·파일 I/O·미완료 저장 기능이 아니다.

`fromJson(Object?)`는 JSON 디코딩 결과를 받는다. 필수 누락은 missingField, 명시적 null/잘못된 타입은 invalidType, 알 수 없는 문자열 방식은 unknownMode다. 알 수 없는 필드와 자동 방식의 lines도 unexpectedField로 거부해 데이터를 조용히 버리지 않는다. 해석 가능한 첫 오류를 예외로 전달하며 모든 오류를 집계하지 않는다. JSON 문자열 문법 자체는 dart:convert의 jsonDecode가 검사한다.

| 코드 | 의미 / 경로 예 |
|---|---|
| missingField / invalidType | 필수 누락 / 타입 오류, areaId·sourceText·lineBreak.mode·lineBreak.lines[1] 등 |
| unknownMode / unexpectedField | 알 수 없는 방식 / 허용하지 않은 필드 |
| emptyAreaId / emptySourceText | 빈 식별자 / 이번 미지원 빈 원문 |
| emptyManualLines / emptyManualLine | 빈 지정 목록 / 이번 미지원 빈 줄 |
| sourceContainsCrLf / manualLineContainsCrLf | 원문 / 지정 줄 내 CR 또는 LF |
| manualTextMismatch | 지정 줄의 연결 내용과 원문 불일치 |

직접 작성한 toJson/fromJson과 Dart 기본 JSON 기능을 사용한다. 이 작은 구조에 코드 생성·런타임 패키지는 추가하지 않았다. pubspec.yaml과 기존 개발용 lints·test 의존성은 그대로다.

## 개발과 검증

Dart SDK 3.12.2 stable (Windows x64), SDK 제약 `^3.12.2`를 유지한다. Flutter에 의존하지 않는다.

```powershell
dart pub get
dart format lib test
dart analyze
dart test
```

2026-10-19 실제 Dart 검사: pub get 성공, format 적용, analyze 문제 없음, 테스트 64개 통과.
이 결과는 영역 입력 모델 검증이며 실제 배치·저장·출력·Type3 검증이 아니다.
라이브러리 pubspec.lock, .dart_tool, IDE 설정과 로컬 override는 Git 관리에서 제외한다.

## 아직 구현하지 않은 범위

WorkDocument 전체, WorkSession, 적용 도안·수량·그룹·결과·작업자 확인, 엔진·DXF·파일 I/O·Flutter 연결은 미구현이다. 앱 → 업무 흐름 → 배치 엔진·DXF의 공개 API 의존 방향을 유지하며 아직 없는 패키지를 선언하지 않는다.

## 기준 문서

- [개발 지침](AGENTS.md)
- [현재 계약](docs/contract.md)
- [모델 설계](docs/model-design.md)
- [현재 상태와 다음 작업](docs/next-step.md)
- 형제 앱 [문서 색인](../r_edit/docs/README.md), [현재 결정](../r_edit/docs/decisions.md), [모듈 경계](../r_edit/docs/module-boundaries.md)

참고 앱 HEAD는 ac11bd44cf098f3cc16b69b2d82d67eb94d1844a다. 추가 원본 자료의 실제 경로·해시와 해당 앱 작업 트리 상태는 모델 설계에 기록했다. 전체 요구사항·과거 시험 자료를 이 저장소에 반복 복사하지 않는다.

## 모델 도구 비교와 개발 규칙 검토

공개 구현을 유지한 상태에서 [Freezed/built_value 비교](docs/model-tools-comparison.md)와
[개발 규칙 초안](docs/development-rules-draft.md)을 작성했다.
비교 코드는 tool/model_comparison의 별도 두 패키지이며 루트 API·의존성에 포함하지 않는다.
루트의 테스트와 별도로 각 비교 패키지의 생성·분석·테스트·AOT 검사를 실행해야 한다.
