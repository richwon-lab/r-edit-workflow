# Freezed 전환과 프로젝트 SDK

2026-10-20. r_edit_workflow의 기존 TextAreaInput과 자동/직접 지정 타입을 Freezed로 전환했다. 시작 작업 트리와 스테이징은 깨끗했고 HEAD는 `5eeb3cad3eef2f3dfcfe2fc84a3916197ec8bc06`이었다. 커밋·푸시는 하지 않는다.

## 사용 환경과 설정 안내

영구 프로젝트 SDK는 `C:/work/richwon/r_edit_workflow/.toolchains/flutter-3.47.7`이다. 검증한 SDK를 이 경로에 별도로 복사했고 **이 경로의** Flutter/Dart를 실행했다. 더 이상 임시 SDK를 개발 명령에 사용하지 않는다.

- Flutter 3.47.7, revision abaf9c523780a608bd46686fd5e53740a07077f8.
- 포함 Dart 3.13.5 stable (Windows x64).
- 안정 태그 checkout이므로 채널 출력은 [user-branch]다. 비교에서 확인한 공식 3.47.7 커밋과 일치한다.
- 공유 C:/develop/flutter와 전역 PATH·다른 프로젝트 설정은 변경하지 않았다.
- 프로젝트 SDK 폴더는 .gitignore의 .toolchains/로 제외한다. 다른 체크아웃에서도 같은 버전을 별도로 준비해야 하며 SDK 자체를 Git에 넣지 않는다.

IntelliJ 설정 안내(이번 작업에서 IDE UI를 조작하거나 설정을 변경하지 않음):

| 설정 | 지정 경로 |
|---|---|
| 이 프로젝트의 Settings → Languages & Frameworks → Dart → Dart SDK path | C:/work/richwon/r_edit_workflow/.toolchains/flutter-3.47.7/bin/cache/dart-sdk |
| 이 프로젝트에서 Flutter SDK 설정이 필요한 경우 → Flutter SDK path | C:/work/richwon/r_edit_workflow/.toolchains/flutter-3.47.7 |

순수 Dart 패키지이므로 우선 Dart 지원을 이 프로젝트/모듈에 설정한다. 형제 앱 등 다른 프로젝트 설정을 함께 변경하지 않는다. 전역 PATH의 dart는 여전히 예전 공유 SDK일 수 있으므로 다음 명령처럼 명시 경로를 사용한다.

```powershell
# r_edit_workflow 루트에서 실행
$workflowDart = "$PWD/.toolchains/flutter-3.47.7/bin/cache/dart-sdk/bin/dart.exe"
& ./.toolchains/flutter-3.47.7/bin/flutter.bat --version
& $workflowDart --version
& $workflowDart pub get
& $workflowDart run build_runner build
& $workflowDart format lib test tool/verify_text_input_release.dart
& $workflowDart analyze
& $workflowDart test
New-Item -ItemType Directory -Force build | Out-Null
& $workflowDart compile exe tool/verify_text_input_release.dart -o build/verify_text_input_release.exe
& ./build/verify_text_input_release.exe
```

## 채택한 의존성

| 구분 | 제약 | 실제 해결 버전 |
|---|---|---|
| Dart SDK | ^3.13.5 | 3.13.5 |
| freezed_annotation | ^3.1.0 | 3.1.0 |
| json_annotation | ^4.12.0 | 4.12.0 |
| freezed (개발) | 4.0.3 | 4.0.3 |
| json_serializable (개발) | 6.14.1 | 6.14.1 |
| build_runner (개발) | 2.16.2 | 2.16.2 |

기존 lints ^6.0.0·test ^1.25.6 제약은 유지했다. build 4.0.11, analyzer 14.5.0, source_gen 4.3.1로 해결됐다. dependency_overrides와 전체 패키지 업그레이드는 하지 않았다. 비교에서 검증한 생성기 버전을 명시했으며 새 버전 채택은 별도 재검증한다.

SDK 최소 제약을 올렸으므로 이 패키지를 새 Git 커밋으로 사용하는 소비자는 Dart 3.13.5 이상 환경이 필요하다. 기존 공유 Dart 3.12.2의 앱에서 새 버전을 그대로 해결할 수 있다는 뜻이 아니다. 앱의 실제 Git 의존성 갱신·SDK 전환은 이번 범위 밖이다.

## 보존한 계약과 추가한 수정 API

공개 이름 TextAreaInput, LineBreakSpec, AutoLineBreak, ManualLineBreak, TextInputException, TextInputErrorCode와 기존 생성자·필드·오류 code/path·JSON은 유지했다. 호환 별칭이나 이름 변경은 없다. 기존 공개 export 목록과 테스트 파일도 유지했다.

LineBreakSpec은 sealed이며 AutoLineBreak/ManualLineBreak의 타입 구분을 유지한다. 공통 mode:String·nullable lines로 통합하지 않는다. const AutoLineBreak()도 유지한다. 한 줄 직접 지정은 ManualLineBreak로 남는다.

TextAreaInput·ManualLineBreak의 생성된 copyWith가 추가됐다. 생성자는 런타임 검증을 실행하므로 생성된 수정·JSON 복원도 유효하지 않은 값을 만들 수 없다. AutoLineBreak는 필드가 없어 copyWith가 생성되지 않는다. LineBreakSpec 전체에 공통 lines나 중첩 copyWith.lineBreak를 만들지 않고, 구체 타입을 분기한 수정값을 부모 copyWith에 전달한다.

```dart
final before = TextAreaInput(
  areaId: 'area-title', sourceText: 'PUMP',
  lineBreak: ManualLineBreak(['PUMP']),
);
final after = before.copyWith(
  sourceText: 'VALVE',
  lineBreak: (before.lineBreak as ManualLineBreak).copyWith(lines: ['VAL', 'VE']),
);
// before.copyWith(sourceText: 'VALVE')는 기존 manualTextMismatch 오류다.
```

이전 기본 Object 디버그 문자열 대신 Freezed의 toString이 생성되지만 저장 JSON이나 오류 안내 계약으로 사용하지 않는다. 값 동등성과 원문 보존 의미는 유지한다. hashCode 숫자는 저장 형식이나 안정 ID가 아니다.

## 직접 코드와 생성 코드의 책임

- 직접 코드: 업무 검증, 외부 목록 방어 복사, 기존 오류 순서·code/path를 위한 JSON 경계 검사, sealed 타입의 mode 분기, 출력 목록 분리.
- Freezed 생성: 필드 기반 값 비교·hashCode·디버그 문자열·유효 생성자를 호출하는 copyWith.
- json_serializable 생성: 필드 이름·타입의 JSON 읽기/쓰기. mode 분기에는 자체 sealed 타입 변환기를 연결한다.
- 불필요한 map/when 생성은 비활성화하고 타입 분기는 Dart switch로 유지한다.
- 업무 검증에는 assert/@Assert를 쓰지 않는다. 원문 공백·기호·대소문자·Unicode를 정규화하지 않는다.

JSON 사전 검사는 생성기의 TypeError를 뒤늦게 파싱하지 않고 기존 필드 오류 계약을 유지한다. 오류 우선순서를 보존하기 위해 부모 JSON 복원의 사전 검사와 생성 함수 진입에서 줄 입력을 다시 읽을 수 있다. 두 경로 모두 실제 생성자의 같은 검증을 거치며 별도 업무 모델이나 DTO를 만들지 않았다.

빈 원문·빈 줄·원문/줄의 CR/LF는 첫 지원 범위에서 계속 미지원이다. 공백만·탭은 보존한다. 이 제한을 전체 제품 정책으로 확정하지 않으며 값 검증은 배치/제작 가능 판정이 아니다.

## Git 관리와 소비자 검증

다음 생성 파일은 **Git 관리 대상**이다. 이번 요청에 따라 git add는 실행하지 않았으므로 새 파일은 아직 미추적 상태일 수 있다.

- lib/src/text_area_input.freezed.dart
- lib/src/text_area_input.g.dart

소비 앱이 이 두 파일이 포함된 커밋을 Git 의존성으로 가져오면 라이브러리의 생성기를 별도로 실행할 필요가 없도록 구성했다. 생성기는 dev_dependencies이고 runtime에는 annotation 패키지만 필요하다. 캐시·SDK·build·IDE 설정·라이브러리 pubspec.lock은 제외한다.

build.yaml은 운영 lib 소스만 대상으로 생성하고 비교 하위 패키지는 건드리지 않는다. 초기 생성에서 비교 파일까지 잡힌 것을 확인해 기존 파일을 복원한 뒤 범위를 제한했다. 최종 재생성 후 비교 폴더 변경이 없음을 확인했다.

build/consumer_smoke에 별도 path 소비자를 만들어 **코드 생성 명령 없이** 의존성 해결·AOT 컴파일·실행했다. 소비자 그래프에는 build_runner/freezed/json_serializable이 없고 r_edit_workflow와 collection/freezed_annotation/json_annotation/meta만 있었다. 기존 API·JSON·수정 검증을 그대로 사용할 수 있었다. 아직 커밋하지 않아 실제 새 Git 참조 소비나 Flutter 앱 빌드는 실행하지 않았다. path 소비 검사와 실제 Git 앱 검증을 구분한다.

## 실제 검증 결과

- 영구 경로 Flutter --version / Dart --version: 3.47.7 / 3.13.5 확인.
- pub get: 성공, 위 버전 조합으로 해결.
- build_runner build·format·analyze: 성공, No issues found!.
- 기존 테스트 64개를 수정 없이 실행하고 추가 테스트 6개를 포함해 **70개 통과**.
- 생성자·부모 copyWith·구체 줄 copyWith 후 부모 반영·방식 전환·오류 우선순서·목록 방어 검사 통과.
- assert 비활성 AOT: 원문·JSON 왕복·동시 교체·목록 방어 및 잘못된 생성/수정/복원 **12건의 code/path** 확인.
- 별도 소비자에서 생성 명령 없이 같은 AOT 검증 통과.
- 재생성 전/후 SHA-256 일치: freezed A7F5B8DD4F36B4E92520E0CAC5D4F3DBB9E2D13D98DAC930B88E55E49ECE38C2, JSON 04AAB84212D2C549BDB884534125B7D4D1E83334E35B3A76CD739753FFA3FA83.

초기 테스트에는 무필드 AutoLineBreak의 copyWith를 기대한 호출이 있어 수정했다. 첫 AOT 검사에서는 타입 없는 빈 Map 리터럴을 문자열 키 JSON 객체로 간주한 기대가 맞지 않아 명시적 JSON 객체 타입으로 수정 후 재실행했다. 실패를 성공으로 기록하지 않았으며 최종 검사는 모두 통과했다. 생성 파일은 직접 편집하지 않았다.

IntelliJ UI 설정·실제 Git 앱 소비·Flutter 릴리스 UI는 안내/후속 확인 범위다. 도안·영역 형상·배치 엔진·저장 흐름·수량·그룹·UI·문자 오프셋은 구현하지 않았다. 현재 이름과 후보의 판단은 [개발 기준 문서](development-rules-draft.md)를 따른다.
