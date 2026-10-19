# 개발 기준과 네이밍 검토

2026-10-20 사용자 결정 반영. 파일 이름은 development-rules-draft.md를 유지하지만 **아래 기술·언어·검증 기준은 채택된 개발 기준**이다. 네이밍 후보는 별도 검토 사항이며 이름 변경 승인이 아니다.

## 이번에 확정한 기준

- 불변 값 모델의 반복 필드·값 비교·복사 코드는 Freezed로, JSON 필드 변환은 json_serializable로 생성한다. 현재 TextAreaInput과 구체 줄바꿈 타입에 적용한다.
- 업무 검증은 실제 생성자에서 직접 작성하고 생성·copyWith·부모/구체 타입의 수정·JSON 복원 모두 같은 조건을 지킨다. assert/@Assert만으로 검증하지 않는다.
- 원문 보존·직접 지정 한 줄·목록 방어 복사·sealed 타입 구분·기존 JSON/오류 계약을 유지한다. 도구 편의를 위해 mode:String+nullable lines로 업무 타입을 합치지 않는다.
- SDK는 프로젝트 전용 .toolchains/flutter-3.47.7의 포함 Dart 3.13.5를 명시 경로로 사용한다. 전역 PATH·다른 프로젝트 SDK를 변경하지 않는다. 임시 SDK를 영구 설정으로 지정하지 않는다.
- 직접 작성하는 주석·API 설명·테스트 설명·개발 문서는 한국어 중심, 식별자는 영어로 쓴다. Dart의 UpperCamelCase·lowerCamelCase·lowercase_with_underscores와 Json/Dto 약어 표기를 따른다.
- 생성 파일·라이선스·외부 API 표기는 직접 수정하지 않는다. 생성 파일 .freezed.dart/.g.dart는 라이브러리 Git 관리 대상에 포함한다. SDK·캐시·빌드·로컬 IDE 설정·라이브러리 lock은 제외한다.
- JSON 경계의 필수/타입/방식/추가 필드 오류는 기존 code/path를 유지한다. 생성기 내부 예외 문자열을 해석하거나 오류를 정상값으로 바꾸지 않는다.
- 새 생성 모드·중첩 구조·공개 타입 경계를 바꿀 때 원문/지정 줄 불일치·외부 목록 변경·JSON 오류와 assert 비활성 AOT를 확인한다. dependency_overrides로 충돌을 우회하지 않는다.

구현·환경·명령·검증의 실제 근거는 [전환 기록](freezed-migration.md), 이전 두 도구 비교는 [과거 비교 기록](model-tools-comparison.md)에 있다. 이전 비교의 현재 모델 유지 추천은 이번 사용자 결정으로 대체됐다.

## 현재 공개 이름과 네이밍 후보

현재 이름·생성자·필드·오류 코드는 **이번에 유지할 호환 계약**이다. 그 이름이 모든 향후 모델에 대한 영구 용어로 확정된 것은 아니다. 승인되지 않은 rename·호환 별칭·자동 치환을 추가하지 않는다. 이름 길이 자체보다 책임과 오해 가능성을 본다.

| 현재 이름 | 구체 후보(미구현) | 의미·혼동 가능성 / 추천 |
|---|---|---|
| TextAreaInput | TextAreaContent, AreaTextInput | 현재 영역 원문과 입력 조건을 표현. Content는 결과도 포함할 듯하고 AreaTextInput은 도안 영역 종류가 흐려질 수 있어 현재 이름 유지 추천 |
| LineBreakSpec | LineBreakInput, LineBreakInstruction | Spec은 조건, Input은 사용자가 준 값, Instruction은 처리 명령처럼 읽힐 수 있음. 현재 이름 유지, 입력/결과 대비가 필요할 때 Input 재검토 |
| AutoLineBreak | AutomaticLineBreak, AutomaticLineBreakInput | 모두 자동 입력 방식. Auto가 이미 익숙하고 베이스 타입 문맥이 있으므로 현재 이름 유지 |
| ManualLineBreak | SpecifiedLineBreak, ManualLineBreakInput | Manual은 크기·위치 수동까지 뜻하는 오해 가능. Specified는 지정 줄 의미가 선명하나 이번 변경 없이 문서에서 줄만 지정함을 명시 |
| areaId | textAreaId, areaReference | 부모 타입에서 영역이 이미 드러남. Reference는 ID 외 경로까지 암시하므로 현재 areaId 추천 |
| sourceText | originalText, text | 현재 편집 기준 원문. originalText는 최초 수입 원본 이력을 뜻할 수 있고 text는 계산 결과와 모호하여 sourceText 유지 추천 |
| lineBreak | lineBreakInput, lineBreakSpec | 부모가 Input이고 타입도 Spec이어서 현재 문맥으로 책임이 읽힘. 현재 유지 |
| lines | specifiedLines, lineTexts | ManualLineBreak 안에서 명시적 줄 조각임이 드러남. 반복 수식보다 현재 lines 유지 |
| TextInputErrorCode | TextAreaInputErrorCode, TextInputValidationCode | 영역 입력뿐 아니라 단독 줄 지정 오류도 포함하므로 현재 이름 유지 추천 |
| TextInputException | TextInputValidationException, InvalidTextInputException | ValidationException은 업무 검증 목적을 더 명확히 함. 현 code/path 계약과 사용자 합의 전에는 현재 이름 유지 |
| code / path | reasonCode / fieldPath | 현재 code는 기계 판별, path는 JSON 필드·목록 위치. fieldPath가 문자 위치와 덜 혼동되지만 이번에는 변경하지 않음 |

### 실제 생성·수정·조회·오류 처리

다음은 현재 구현과 테스트에서 사용하는 실제 API다. 후보는 위 표의 검토 용어일 뿐 아래 코드의 호환 별칭으로 제공하지 않는다.

```dart
final input = TextAreaInput(
  areaId: 'area-title', sourceText: 'PUMP',
  lineBreak: ManualLineBreak(['PUMP']),
);
final next = input.copyWith(
  sourceText: 'VALVE',
  lineBreak: (input.lineBreak as ManualLineBreak).copyWith(lines: ['VAL', 'VE']),
);
final text = next.sourceText;
final specifiedLines = switch (next.lineBreak) {
  AutoLineBreak() => null,
  ManualLineBreak(:final lines) => lines,
};
try {
  input.copyWith(sourceText: 'VALVE');
} on TextInputException catch (error) {
  switch (error.code) {
    case TextInputErrorCode.manualTextMismatch:
      print('원문과 지정 줄이 다릅니다: ${error.path}');
    default:
      print('${error.code.name}: ${error.path}');
  }
}
```

원문만 바꾸는 마지막 수정은 거부된다. 유효한 새 원문과 줄은 한 번의 부모 copyWith로 함께 교체한다. 구체 타입의 lines를 바꾸는 일과 영역의 sourceText를 바꾸는 일은 책임이 다르므로 부모 검증을 생략하지 않는다. LineBreakSpec에는 공통 lines가 없고 AutoLineBreak는 바꿀 필드가 없어 copyWith가 생성되지 않는다. 중첩 수정은 구체 타입을 분기한 뒤 부모 값에 반영한다. nullable 공통 lines로 타입을 약화시켜 체이닝 문법을 얻지 않는다.

아래 후보 코드는 **이름이 승인될 경우의 읽기 비교**이며 현재 컴파일 대상이 아니다. 현재 명칭 코드만 구현·실행했다.

| 후보 문맥 | 생성·변경·조회에서 읽히는 표현 |
|---|---|
| TextAreaContent + originalText | `TextAreaContent(originalText: ...)`, `content.copyWith(originalText: ...)`, `content.originalText`: 최초 원본을 바꾸는 것처럼 읽힐 위험 |
| AreaTextInput + text | `AreaTextInput(text: ...)`, `input.copyWith(text: ...)`, `input.text`: 짧지만 원문과 확정 배치 줄의 차이가 약함 |
| TextInputValidationException + fieldPath | `catch (error)`, `error.code`, `error.fieldPath`: 역할은 선명하나 기존 오류 타입/필드를 바꾸므로 별도 합의 필요 |

### 현재 오류 코드의 후보와 구분

| 현재 코드 | 후보(미구현) | 유지할 의미 |
|---|---|---|
| missingField | requiredFieldMissing | 필수 필드 자체 없음, null과 구분 |
| invalidType | fieldTypeMismatch | 값이 있지만 타입이 다름 |
| unknownMode | unsupportedLineBreakMode | 알 수 없는 방식 문자열 |
| unexpectedField | unrecognizedField | 알 수 없는 키 또는 auto의 lines |
| emptyAreaId | emptyTextAreaId | 식별자 빈 문자열 |
| emptySourceText | unsupportedEmptySource | 이번 미지원 빈 원문, 전체 제품 금지 정책이 아님 |
| emptyManualLines | emptySpecifiedLines | 직접 지정 목록 0개, 필드 누락과 구분 |
| emptyManualLine | unsupportedEmptyLine | 목록 안 빈 줄, 빈 목록과 구분 |
| sourceContainsCrLf | unsupportedSourceLineEnding | 원문 CR/LF, Unicode 전체 줄 구분 정책으로 확대하지 않음 |
| manualLineContainsCrLf | specifiedLineContainsCrLf | 지정 조각 CR/LF, 원문과 오류 위치 구분 |
| manualTextMismatch | specifiedLinesDoNotMatchSource | 순서대로 연결한 조각과 현재 원문이 정확히 다름 |

모든 오류 코드는 이번에 유지한다. 긴 후보가 더 자세해도 code+path+안내문을 함께 읽었을 때 충분한지 판단해야 하며 길이만으로 교체하지 않는다.

## 책임을 나타내는 명칭

| 명칭 | 사용할 책임 | 피할 오용 |
|---|---|---|
| Input | 사용자·원본·호출자가 제공한 처리 조건 | 검증 성공을 배치/저장 완료 결과로 부르기 |
| Setting | 설정값·기본값·적용 지정과 범위 | 모든 불변 값을 모호하게 묶기 |
| Rule | 업무 제약·선택 기준과 적용 범위·출처 | 형상이나 단순 설정을 전부 Rule로 부르기 |
| Result | 실제 산출물과 판정·근거·입력 연결 | 입력 값의 존재만으로 정상 Result 생성 |
| Builder | 확정 전 임시 가변 조립, build에서 전체 조건 검사 | 중간 상태를 유효 업무 값으로 사용 |
| Dto | 파일·API 경계에서 업무 모델과 다른 운반/변환 표현 | JSON이 된다는 이유만으로 동일 구조 계층 추가 |

현재 범위 밖의 도안·세션·엔진 이름을 미리 확정하지 않는다. [Effective Dart](https://dart.dev/effective-dart/style)의 이름·포맷 기준을 따르며 생성·수정·조회·오류 처리 코드와 함께 후보를 검토한다.
