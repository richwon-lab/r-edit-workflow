# 개발 기준과 네이밍

2026-10-20 사용자 결정. 파일 이름은 유지하지만 아래 내용은 채택된 기준이다. 초기 이름과 JSON을 배포된 호환 계약으로 취급하지 않는다. 과거 후보 비교는 Git 이력과 [전환 기록](freezed-migration.md)에 남고 현재 결정은 [네이밍·JSON 정리](input-naming-json.md)를 따른다.

## 채택한 기준

- 불변 값의 반복 필드·값 비교·copyWith는 Freezed, JSON 필드 변환은 json_serializable로 생성한다. 생성 파일을 직접 편집하지 않는다.
- 업무 검증은 실제 생성자에서 직접 작성한다. 생성·수정·복원 모두 같은 조건을 지키며 assert/@Assert만으로 검증하지 않는다.
- JSON 경계는 구조·필수 필드·타입·지원 방식을 검사한다. 같은 값을 미리 생성해 검증한 뒤 다시 생성하지 않는다. 생성기 예외 메시지를 분석하지 않는다. 복수 오류의 발생 순서는 계약으로 고정하지 않는다.
- 원문 보존·직접 지정 한 줄·방어 복사·sealed 타입 구분을 유지한다. mode:String+nullable lines로 업무 타입을 합치지 않는다.
- 프로젝트 전용 .toolchains/flutter-3.47.7의 Dart 3.13.5를 명시 경로로 사용한다. 다른 SDK·전역 PATH를 바꾸거나 dependency_overrides로 충돌을 우회하지 않는다.
- 직접 작성한 주석·API 설명·테스트 설명·개발 문서는 한국어 중심, 식별자는 Dart 표기 규칙에 맞는 영어로 쓴다.
- 필요한 .freezed.dart/.g.dart는 Git 관리 대상으로 둔다. SDK·캐시·빌드·IDE·라이브러리 lock은 제외한다. 소비자가 코드 생성 없이 쓸 수 있는지 확인한다.
- 새 생성 경로·구조 변경 시 원문/지정 줄 불일치·외부 목록/반환 JSON 변경·오류 구분·assert 비활성 AOT·재생성 일치를 확인한다.

## 이번에 확정한 이름과 표현

| 대상 | 현재 결정과 이유 |
|---|---|
| TextAreaInput | 제품 전체가 아닌 영역의 원문과 입력 조건 |
| LineBreakInput | 줄바꿈의 사용자 입력을 나타내는 sealed 합 타입 |
| AutomaticLineBreak | 자동 줄 경계 선택 요청. JSON mode: automatic |
| SpecifiedLineBreak | 지정한 줄 조각. 한 줄도 지정 상태. JSON mode: specified |
| TextInputValidationException | 값 검증 실패임을 명시. code와 fieldPath 제공 |
| TextInputErrorCode / code | 기계 판별 오류 코드 |
| areaId / sourceText / lineBreak / lines | 영역 식별자·현재 원문·줄 입력·순서 있는 지정 조각 |

구형 이름·auto/manual JSON은 지원하지 않고 호환 별칭·변환 코드를 추가하지 않는다. 현재 범위의 이름은 위 결정대로 사용한다. 향후 다른 업무 개념의 이름은 실제 생성·수정·조회 코드로 2~3개 후보를 검토하며 모든 모델 이름을 미리 만들지 않는다.

```dart
final input = TextAreaInput(
  areaId: 'area-title', sourceText: 'PUMP',
  lineBreak: SpecifiedLineBreak(['PUMP']),
);
final next = input.copyWith(
  sourceText: 'VALVE',
  lineBreak: (input.lineBreak as SpecifiedLineBreak).copyWith(lines: ['VAL', 'VE']),
);
final specifiedLines = switch (next.lineBreak) {
  AutomaticLineBreak() => null,
  SpecifiedLineBreak(:final lines) => lines,
};
try {
  input.copyWith(sourceText: 'VALVE');
} on TextInputValidationException catch (error) {
  print('${error.code.name}: ${error.fieldPath}');
}
```

부모 copyWith는 원문과 지정 줄을 함께 검사한다. 구체 줄 입력은 부모의 원문을 모르므로 부모에 반영할 때 연결 조건을 검사한다. 자동 타입에 공통 nullable lines를 추가하지 않는다. 전체 오류 코드는 [README](../README.md)에 있다.

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
