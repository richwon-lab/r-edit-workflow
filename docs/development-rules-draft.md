> 현재 개발 기준(2026-10-26): [공통 기반](development-foundation.md), [라이브러리 계약 감사](library-contract-audit.md).
> 현재 SDK/명령/분석 기준은 위 문서가 우선하며 아래 날짜별 기록은 당시 사실을 보존한다.
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

## 형상·영역 데이터 재설계 기준 (2026-10-25)

[새 설계](applied-design-geometry.md)의 역할/파일/오류 구성을 따른다. 현재 구현·이름·JSON은 배포 호환 제약이 아니다. 명판 디자인은 지원 기하 요소의 데이터 조합이며 디자인별 클래스/enum을 추가하지 않는다. 단위/좌표는 문맥에서 선언하고 각 API 주석이 상속 단위·불변식·검증 실패·미검사 관계를 설명해야 한다.

오류 코드와 예외는 설명 있는 전용 오류 파일에 두며 모델 파일에 섞지 않는다. 입력 정의 오류·관계 검사 issue·엔진/DXF 지원 실패는 원인과 경계를 구분한다. 클래스별 무조건 파일 분리보다 책임의 응집성과 탐색성을 우선한다. sealed 하위 타입은 같은 Dart library에 배치하고 다른 책임 파일은 검증된 공개 생성 API를 import한다. utils/common·범용 오류 프레임워크·아직 필요하지 않은 공통 geometry 패키지는 만들지 않는다. 이 문장은 재설계 당시 기록이다. 후속 최소 구현에서는 lib/src/geometry로 책임별 기하 파일을 구성하고 오류를 별도 파일에 분리했다.

현재 기하의 단위 문맥·검증 책임·JSON·오류 진단은 [최소 기하 계약](applied-design-geometry.md)을 따른다. 경로가 시작점을 소유하므로 구간은 시작점 의존 검증을 하지 않는다. 원의 정본은 중심/반지름이고 원호 분할을 강제하지 않는다. 단위 문맥 소유 묶음에는 태그만 바꾸는 copyWith를 생성하지 않고 전체 환산 API를 둔다. 일반 값의 생성 copyWith·JSON 복원은 실제 검증 생성자를 호출해야 한다.

## 테스트 배치와 이름

- test/geometry·design·text로 공개 책임을 구분하고 대상 타입·동작별 파일에 둔다. 생성 도구나 개발 순서 이름을 쓰지 않는다. [파일 구성과 기존 사례 대응표](test-organization.md)를 따른다.
- group은 타입·공개 동작, test는 한국어로 조건과 기대 결과를 설명한다. 시점 표현을 피하고 매개변수 사례에는 필드·입력값·회전 방향·진입 경로를 드러낸다.
- 한 테스트는 하나의 계약을 검증한다. 독립 오류/입력은 등록 시점에 나누고, 같은 행동의 결과·진단·원본 불변성은 함께 확인한다.
- JSON은 고정 기대 구조와 비교하고 키 순서는 계약이 있을 때만 고정한다. 왕복만으로 필드 손실을 검증하지 않는다. 오류 목록 순서는 계약이 아니면 고정하지 않는다.
- 반복 준비만 support/의 책임별 작은 파일로 공유한다. 단위/형상이 읽히는 이름을 사용하고 검증에 중요한 값은 본문에 둔다. 기대값을 제품 알고리즘으로 다시 계산하지 않는다.
- 테스트 구조 변경 후 format·analyze·전체 실행·파일별 단독 실행을 확인한다. 운영 코드와 생성 입력이 그대로면 생성·AOT는 반복하지 않고 미실행 사유를 기록한다.

## 예외·진단·로깅 경계 (2026-10-27)

[현행 처리 계약](failure-diagnostics-logging.md)을 따른다. 코드별 필수 진단은 직접 작성한 런타임 검사로 보장한다.
같은 예외는 rethrow, 문맥 변환 시 최초 원인/상세/스택을 보존한다. 설명 문자열로 오류를 분류하지 않는다.
값/JSON/참조 검사에 로그를 흩뿌리지 않으며 workflow에는 앱의 root·파일·Flutter 처리기를 넣지 않는다.
Error·예상 밖 결함을 issue/빈 값/성공 결과로 바꾸지 않는다. 진단 설명을 사용자 UI 확정 문구로 취급하지 않는다.
