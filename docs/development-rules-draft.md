# 모델 개발 규칙 초안

2026-10-19. [도구 비교 결과](model-tools-comparison.md)에 근거한 검토안이다. AGENTS.md나 기존 공개 구현을 대체하는 확정 규칙은 아니다.

## 문장과 식별자

직접 작성하는 주석·API 설명·개발 문서·테스트 설명은 한국어 중심으로 쓴다. 식별자는 영어로 하고 타입은 UpperCamelCase, 필드·함수·상수는 lowerCamelCase, 파일·패키지는 lowercase_with_underscores를 따른다. 약어는 Json/Dto처럼 단어로 취급한다. 실제 원문·프로토콜 필드명은 임의 번역·정규화하지 않는다.

생성기 주석·라이선스·외부 API 표기는 직접 고치지 않는다. 기존 영어 주석을 이번 범위와 무관하게 일괄 번역하지 않는다. 과거 예시 이름을 확정 API로 간주하지 않는다.

## 이름은 생성·수정·조회 코드로 비교한다

업무 개념마다 2~3개 후보를 실제 사용 코드에 넣고 책임·정보 범위를 검토한다. 이번에는 TextAreaInput / AreaText / TextAreaContent와 LineBreakSpec / LineBreakInput / LineBreakChoice를 비교했다. 비교용 별칭만 추가했으며 운영 이름은 바꾸지 않았다.

[Freezed 전체 예시](../tool/model_comparison/freezed/lib/naming_examples.dart)와 [built_value 전체 예시](../tool/model_comparison/built_value/lib/naming_examples.dart)는 실제 생성·동시 수정·조회 코드를 포함하며 분석·AOT 실행했다.

| 후보 | Freezed 생성 → 수정 → 조회 | built_value 생성 → 수정 → 조회 |
|---|---|---|
| TextAreaInput | `TextAreaInput(areaId: 'a', sourceText: 'PUMP', lineBreak: LineBreakSpec.manual(['PUMP']))` → `input.copyWith(sourceText: 'VALVE', lineBreak: LineBreakSpec.manual(['VALVE']))` → `changedInput.sourceText` | `TextAreaInput((b) => b..areaId='a'..sourceText='PUMP'..lineBreak.replace(LineBreakSpec.manual(['PUMP'])))` → `input.rebuild((b) => b..sourceText='VALVE'..lineBreak.replace(LineBreakSpec.manual(['VALVE'])))` → `changedInput.sourceText` |
| AreaText | `AreaText(...)` → `text.copyWith(...)` → `changedText.sourceText` | `AreaText((b) => ...)` → `text.rebuild(...)` → `changedText.sourceText` |
| TextAreaContent | `TextAreaContent(...)` → `content.copyWith(...)` → `changedContent.sourceText` | `TextAreaContent((b) => ...)` → `content.rebuild(...)` → `changedContent.sourceText` |

표에서 생략한 코드를 포함한 완전한 실행 예시는 위 naming_examples.dart에 있다.

| 이름 | 판단 |
|---|---|
| TextAreaInput | 영역의 문구와 입력 방식이라는 현재 책임이 명확하다. 기존 공개 이름도 있으므로 유지 추천 |
| AreaText | 짧지만 문자열만 뜻하는 듯하여 직접 지정 줄과 입력 방식의 책임이 약하다 |
| TextAreaContent | 내용의 불변 값이라는 의미는 있으나 배치 결과까지 포함하는지 모호하다 |
| LineBreakSpec | 명시적 줄 구성 조건을 나타내며 현재 이름 유지 후보 |
| LineBreakInput | 입력임이 명확하다. 향후 계산 결과 표현과 대비할 때 후보 |
| LineBreakChoice | 선택만 뜻하는 듯하여 실제 지정 줄을 보관하는 책임이 약하다 |

## 책임을 나타내는 명칭

| 명칭 | 사용할 책임 | 피할 오용 |
|---|---|---|
| Input | 사용자·원본·호출자에게 받은 처리 조건. 검증 성공은 결과 판정이 아님 | 계산 결과·저장 완료 의미 혼합 |
| Setting | 사용자가 정하는 설정값·기본값·적용 지정, 범위와 유효성 명시 | 모든 값 객체를 모호하게 묶기 |
| Rule | 업무 제약·허용 조건·선택 기준, 적용 범위·출처 구분 | 형상이나 단순 설정을 전부 Rule로 부르기 |
| Result | 처리 산출물과 판정·근거·입력 연결 | 입력 검증 성공을 배치 가능 Result로 부르기 |
| Builder | 확정 전 임시 가변 조립. build에서 전체 조건 검사 | 미완료 중간 상태를 유효 업무 값처럼 사용 |
| Dto | 파일·API 경계의 운반·변환 표현, 업무 모델과 차이가 있을 때 | JSON이 된다는 이유만으로 같은 모양의 Dto 계층 추가 |

## 생성 도구 채택과 확인

현재 공개 모델은 유지한다. 반복 값 모델이 늘 때 Freezed의 일반 생성자 방식을 우선 검토하되 실제 책임과 구현 범위로 판단한다. built_value는 큰 중첩 조립과 BuiltList 생태계가 필요할 때 재검토한다.

업무 조건을 assert/@Assert만으로 검사하지 않는다. 생성·copyWith/rebuild·JSON 복원에서 동일 조건과 오류 code/path를 유지한다. 원문과 줄 구성은 함께 확정하고 외부 목록 변경으로 기존 값이 달라지지 않게 한다. 값 검증과 배치·제작 가능 판정을 구분한다.

생성 모드·중첩 방식·공개 타입 경계를 바꾸면 잘못된 부분 수정·JSON 오류·외부 목록 변경·assert 비활성 AOT를 다시 확인한다. 생성 파일은 직접 수정하지 않는다. 의존성·SDK 버전을 기록하고 dependency_overrides로 충돌을 강제 우회하지 않는다. SDK는 공유 프로젝트 영향을 확인하고 별도 설치·프로젝트 설정으로 분리한다.

이 규칙은 [Effective Dart](https://dart.dev/effective-dart/style)의 이름·포맷 기준을 따른다. 공식 자료 확인일: 2026-10-19.
