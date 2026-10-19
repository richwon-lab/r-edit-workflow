# 초기 입력 네이밍과 JSON 정리

확인일: 2026-10-20. 대상 C:/work/richwon/r_edit_workflow, 시작 HEAD b7ee76a. 시작 작업 트리·스테이징은 깨끗했다. 초기 개발 결정이며 이전 API·JSON을 배포된 호환 계약으로 보존하지 않는다. 별칭·구형 형식 지원·마이그레이션은 없다.

## 공개 API와 오류

| 이전 | 현재 |
|---|---|
| LineBreakSpec | LineBreakInput |
| AutoLineBreak | AutomaticLineBreak |
| ManualLineBreak | SpecifiedLineBreak |
| TextInputException | TextInputValidationException |
| 예외 path | fieldPath |
| unknownMode | unknownLineBreakMode |
| emptyManualLines | emptySpecifiedLines |
| emptyManualLine | emptySpecifiedLine |
| manualLineContainsCrLf | specifiedLineContainsCrLf |
| manualTextMismatch | specifiedLinesMismatchSourceText |

TextAreaInput, TextInputErrorCode, 예외 code, areaId/sourceText/lineBreak/lines와 나머지 오류 코드는 유지한다. LineBreakInput은 sealed이며 자동/지정 타입이 분리된다. Specified는 크기·위치까지 수동이라는 뜻이 아니라 줄 조각만 지정한다는 의미다. fieldPath는 JSON 필드/목록 인덱스이고 문자 오프셋이 아니다.

```dart
final input = TextAreaInput(
  areaId: 'area-title', sourceText: 'PUMP A',
  lineBreak: SpecifiedLineBreak(['PUMP ', 'A']),
);
final changed = input.copyWith(
  sourceText: 'VALVE',
  lineBreak: (input.lineBreak as SpecifiedLineBreak).copyWith(lines: ['VAL', 'VE']),
);
try {
  input.copyWith(sourceText: 'OTHER');
} on TextInputValidationException catch (error) {
  print('${error.code.name}: ${error.fieldPath}');
}
```

## JSON과 검증 책임

```json
{"areaId":"area-title","sourceText":"PUMP A","lineBreak":{"mode":"automatic"}}
```

```json
{"areaId":"area-title","sourceText":"PUMP A","lineBreak":{"mode":"specified","lines":["PUMP ","A"]}}
```

직접 지정 한 줄도 specified와 한 요소 목록을 그대로 왕복한다. auto/manual은 unknownLineBreakMode / lineBreak.mode로 거부한다. 방식 누락은 missingField, null/타입 오류는 invalidType이며 기본값으로 보정하지 않는다. 알 수 없는 필드는 unexpectedField다.

TextAreaInput.fromJson은 루트 객체·필수 필드·문자열 타입·추가 필드를 검사한다. 생성된 json_serializable 함수가 필드를 변환하고 lineBreak 변환기가 LineBreakInput.fromJson을 한 번 호출한다. 여기서 객체·mode·lines 구조/타입을 검사한 뒤 구체 값을 생성한다. 원문의 비어 있음/CR·LF와 지정 목록의 비어 있음/줄 CR·LF 및 원문 연결 일치는 실제 업무 값 생성자에서 검사한다. 생성된 copyWith도 같은 생성자를 호출한다.

루트에서 줄 입력을 미리 만들고 버리지 않는다. 필드 변환·값 비교·copyWith 반복 코드는 생성기에 맡긴다. 생성기 예외 문자열은 분석하지 않는다. 단일 오류는 code/fieldPath로 명확히 구분하고 복수 오류 발생 순서는 계약으로 고정하지 않는다.

원문 공백·기호·대소문자·Unicode 표현, 한 줄 지정, 수정 전 값의 불변성과 방어 복사는 유지한다. 반환 JSON의 목록도 분리한다. 빈 원문·빈 줄·CR/LF는 첫 지원 제한으로 구분해 거부하며 전체 제품 정책은 계속 보류한다. 공백만 있는 원문은 빈 문자열로 바꾸지 않는다. 값 검증은 배치·제작 판정이 아니다. 전체 WorkDocument·저장 흐름·문자 오프셋 API는 추가하지 않았다.

## 실제 실행 결과

전용 .toolchains/flutter-3.47.7의 Dart 3.13.5 stable/Windows x64를 사용했다. 의존성·SDK 제약은 바꾸지 않았다. Freezed 4.0.3, json_serializable 6.14.1, build_runner 2.16.2, annotation 3.1.0/4.12.0을 그대로 해결했다. overrides·일괄 업그레이드는 없다.

```powershell
$workflowDart = "$PWD/.toolchains/flutter-3.47.7/bin/cache/dart-sdk/bin/dart.exe"
& $workflowDart pub get
& $workflowDart run build_runner build
& $workflowDart format lib test tool/verify_text_input_release.dart
& $workflowDart analyze
& $workflowDart test
& $workflowDart compile exe tool/verify_text_input_release.dart -o build/verify_text_input_release.exe
& ./build/verify_text_input_release.exe
```

- 코드 생성·포맷·분석 성공, 테스트 74개 통과. 실제 JSON 문자열 왕복, 직접 지정 한 줄·여러 줄, Unicode/공백, 잘못된 원문/지정 줄, 구조/타입/구형 방식 거부, 생성/copyWith/복원 검증 및 외부 목록/반환 JSON 변경 방어를 확인했다.
- 최초 분석은 build/consumer_smoke의 이전 API 참조로 실패했다. 이 임시 소비자 코드를 현재 공개 API로 갱신한 뒤 분석 문제 없음으로 통과했다.
- assert 비활성 AOT에서 정상 왕복·동시 수정·원래 값 보존·외부 목록/반환 JSON 보호와 오류 14건의 code/fieldPath를 확인했다.
- 별도 build/consumer_smoke 패키지에서 루트를 path 의존성으로 사용했다. 현재 AOT 검사 파일을 bin/main.dart로 복사하고 pub get, compile exe bin/main.dart -o consumer.exe, consumer.exe를 실행해 통과했다. 소비자에서 코드 생성은 실행하지 않았다. 의존 그래프에 annotation·collection·meta만 전파되며 Freezed/빌드/JSON 생성기는 없다. 실제 Git 참조 앱은 이번에 실행하지 않았다.
- 생성 파일을 직접 편집하지 않고 재생성 후 포맷한 SHA-256이 직전 결과와 일치했다.

| 생성 파일 | SHA-256 |
|---|---|
| text_area_input.freezed.dart | C41C571490E981755BACA2EE78E07533E1D4C94125DCD383545E997BF40488A1 |
| text_area_input.g.dart | 1BDA9F51974CE3C4E88C4618C410DAD6932919071E4B731E1DBBF29784875B79 |

생성 소스는 Git 관리 대상이다. SDK·캐시·빌드와 소비자 임시 파일은 제외한다. 과거 비교 패키지는 당시 루트 API를 참조하므로 현재 루트에 연결한 재실행 호환성을 주장하지 않는다. [도구 비교](model-tools-comparison.md)와 [Freezed 전환](freezed-migration.md)의 당시 이름·실행 결과는 보존했으며 이번 결과와 구분한다. SDK·IntelliJ 경로 안내는 전환 문서를 계속 참고한다.

현재 계약은 [contract.md](contract.md), 개발 기준은 [development-rules-draft.md](development-rules-draft.md), 다음 한 가지 설계 작업은 [next-step.md](next-step.md)를 따른다. 커밋·푸시는 하지 않는다.
