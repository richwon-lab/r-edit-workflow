
# 개발 기반 보완 — 2026-10-28

이 문서는 r_edit / r_edit_workflow의 이번 채택 기준이다. 각 저장소에 독립적으로 보관한다.
[공통 개발 기반](development-foundation.md), 실제 pubspec·생성/검증 설정을 함께 따른다.
업무 값·JSON·기하·변경 계약·로그 정책은 바꾸지 않는다. Dependabot 및 다른 자동 갱신 도구는 보류다.

## 확정 버전과 역할

| 항목 | 적용 | 버전/역할 | 기존/신규 |
|---|---|---|---|
| Flutter / Dart | 두 저장소 | 3.47.7 / 3.13.5, 기존 FVM 고정 | 유지 |
| Freezed / json_serializable / build_runner | 두 저장소 | 4.0.3 / 6.15.2 / 2.16.2 | 유지 |
| Riverpod / annotation / generator | 앱 | 3.4.3 / 4.0.7 / 4.0.9 | 유지 |
| riverpod_lint | 앱 dev + 공식 analyzer plugin | 3.1.9, Provider 사용 규칙 | 신규 |
| go_router | 앱 runtime | 17.3.0, 기존 Router/Provider 수명 | 17.1.0에서 필요한 API만 업데이트 |
| go_router_builder | 앱 dev | 4.5.2, 현재 시작 경로의 타입/이동 메서드 생성 | 신규 |
| flutter_localizations / gen_l10n | 앱 | Flutter 3.47.7 포함 SDK 도구, 한국어 기본 위젯/문구 | 신규 |
| intl | 앱 direct runtime | 0.20.3, SDK flutter_localizations의 ^0.20.3과 일치 | 신규 |
| meta | workflow direct runtime | 1.19.0, 선택 API의 반환값 사용 의도 | 전이 의존성을 직접 선언 |
| dart doc | workflow 검증 | 고정 SDK에 포함된 dartdoc 9.0.6, --dry-run | 신규 검사, 별도 pub 패키지 없음 |

선정일에 pub.dev 공식 배포 메타데이터·archive의 pubspec/CHANGELOG/LICENSE와 SDK 소스를 확인했다.
riverpod_lint는 MIT, go_router/go_router_builder/meta/intl/Flutter는 BSD-3-Clause다.
실제 해결은 analyzer 14.6.0/build 4.0.11/source_gen 4.3.1/source_helper 1.4.0을 유지했다.
riverpod_lint 3.1.9는 Dart >=3.13.0-0, analyzer >=13 <15, Riverpod 3.4.3과 utils dev.12를 사용한다.
go_router_builder 4.5.2는 Dart ^3.13/Flutter >=3.47, analyzer >=8.2 <15, build >=3 <5와 호환된다.
더 최신이라는 이유로 SDK/build_runner/Freezed 등을 일괄 업그레이드하지 않았고 overrides도 없다.

### 라우터 호환 문제와 최소 변경

analyzer 14를 지원하는 go_router_builder는 hasOverriddenOnExit 인자를 생성한다.
기존 go_router 17.1.0 및 확인한 17.2.0의 GoRouteData.$route에는 그 인자가 없다.
17.3.0에서 제공하는 실제 API와 builder의 공식 사용 버전을 확인하고 17.3.0으로 선택했다.
18.x의 추가 UI 패키지 전환은 하지 않았다. 의존성 해결 성공만으로 호환을 단정하지 않고 실제 생성·분석·경로 테스트를 수행했다.

앱 pub get에서 추가된 전이 패키지는 analysis_server_plugin 0.3.25, analyzer_plugin 0.14.19,
yaml_edit 2.2.4와 SDK flutter_localizations다. 다른 기존 패키지는 유지했다.
workflow는 이미 해결된 meta 1.19.0을 직접 runtime 의존성으로 선언해 해결 버전 변화가 없었다.
앱 lock은 관리하고 라이브러리 lock은 기존처럼 무시한다.

## riverpod_lint의 실제 설치·실행 경계

공식 analysis_server_plugin 방식으로 analysis_options.yaml의 최상위 plugins에 riverpod_lint: 3.1.9를 선언한다.
같은 버전을 dev_dependencies에도 직접 선언한다. 과거 analyzer.plugins/custom_lint 설정·custom_lint CLI는 추가하지 않는다.
very_good_analysis 11과 strict-casts/inference/raw-types는 그대로다.

~~~powershell
./tool/fvm.ps1 flutter analyze --fatal-infos
# 공식 플러그인은 고정 Dart CLI에서도 실행된다.
./tool/fvm.ps1 dart analyze --fatal-infos
./tool/fvm.ps1 dart tool/verify.dart --windows
~~~

플러그인의 일부 진단은 info이므로 fatal-infos를 명시한다.
IntelliJ는 프로젝트 .fvm/flutter_sdk와 그 아래 bin/cache/dart-sdk를 사용하고 Dart 분석 서버를 재시작한다.
같은 analysis_options가 적용되는 분석 서버 방식이며 IDE의 inspection 별도 실행은 이번 CLI 검증과 구분한다.
IDE에서 실제 진단을 확인했다고 주장하지 않는다. 플러그인 최초 설치/컴파일은 추가 시간이 걸릴 수 있다.

격리 Flutter 패키지의 @riverpod 함수에 BuildContext를 전달해
avoid_build_context_in_providers가 발생하고 strict CLI가 exit 1로 거부함을 확인했다.
자료는 .tooling 아래 별도 패키지이며 운영 Provider/업무 코드에 오용을 남기지 않는다.
현재 앱 Provider의 신규 오용은 없었고 광범위 ignore는 추가하지 않았다.

## workflow meta의 선별 적용

@useResult는 validateTextAreaInputs / validateProductDesignConfiguration /
validateAppliedGeometryIdConsistency와 불변 converted/convertedTo,
직접 작성한 DesignGeometry.copyWith에 적용했다.
Freezed가 이미 생성한 copyWith의 useResult 표시는 중복해서 직접 수정하지 않는다.
Freezed annotation이 재수출하는 이름에 불필요한 import를 추가하지 않되,
직접 사용하는 meta 자체는 pubspec에 명시했다.

반환값을 버리면 검증/변환 목적이 사라지는 API의 분석 의도다.
업무 조건·불변성·런타임 방어/JSON 검사를 대체하지 않는다.
단순히 모든 클래스에 @immutable을 중복하지 않고, 현재 별도 보호가 필요 없는 @internal도 추가하지 않는다.
내부 도우미는 공개 진입점에서 export하지 않는 기존 경계를 유지한다.

외부의 격리된 소비자가 진단 목록과 Point2.converted의 반환값을 버리면
unused_result 경고 2건과 strict 분석 exit 2가 발생했다.
기존 음성 테스트 두 곳은 잘못된 입력에서 정상 반환하면 그 반환 타입과 함께 fail하도록 바꿨다.
파일 전체 ignore로 검사를 우회하지 않았다.
소비자는 기존처럼 결과를 보관/반환/전달해야 하며 JSON·업무 값·예외 의미는 바뀌지 않는다.

## 타입 라우트와 한국어 단일 언어

- lib/app/routing/app_routes.dart: `@TypedGoRoute<StartRoute>(path: '/')`가 현재 경로의 유일한 선언이다.
- lib/app/providers/app_router.dart: $appRoutes 연결, 오류 화면, 로거, ref.onDispose(router.dispose)를 소유한다.
- 정상 이동은 const StartRoute().go(context) 등 생성 메서드를 사용한다.
  미등록 경로 문자열은 음성 테스트에만 사용한다. 업무 화면/탭/새 Router 프레임워크는 없다.
- lib/l10n/app_ko.arb: 현재 시작·오류 안내 문구와 한국어 설명이다.
- l10n.yaml: 공식 gen_l10n 출력은 lib/l10n/generated/app_localizations*.dart다.
- MaterialApp은 Locale('ko')와 생성된 delegates/supportedLocales를 사용한다.
  GlobalMaterial/GlobalCupertino/GlobalWidgets를 함께 지원한다.
- R-edit는 고정 브랜드로 Dart/Windows에 유지한다.
  고객 명판 원문·업무 ID·오류 코드·개발자 설명·로그 이벤트는 ARB로 옮기지 않는다.
  추가 언어/언어 선택 UI는 없다.

생성 파일은 직접 편집하지 않는다. route .g.dart와 지역화 Dart 파일을 Git 관리한다.
지역화 생성기는 SDK 제공 파일 주석/코드를 사용하며 lib/l10n/generated만 분석 제외한다.
수동 ARB/라우트/앱 코드는 제외하지 않는다. 생성 파일 LF는 .gitattributes로 고정한다.
공식 l10n.yaml format 옵션으로 지역화 Dart도 포맷된 상태로 생성한다.

## 생성·검증 순서

~~~powershell
# 명시적으로 생성 결과를 준비하고 diff를 검토할 때
./tool/fvm.ps1 flutter pub get
./tool/fvm.ps1 flutter gen-l10n
./tool/fvm.ps1 dart run build_runner build
# 준비한 결과가 현재 선언과 일치하는지 검사
./tool/fvm.ps1 dart tool/verify.dart --windows
~~~

앱 verify는 다음 순서다.
1. pub get 전에 g.dart/freezed.dart와 lib/l10n/generated의 모든 Dart 파일 경로/바이트를 캡처한다.
2. flutter pub get(지역화 자동 생성 포함) → flutter gen-l10n → build_runner.
3. 시작 스냅샷과 비교한다. 생성이 고쳤더라도 수정/추가/삭제가 있으면 경로·명령과 함께 실패한다.
4. 포맷 검사 → gen-l10n + build_runner 반복 → 안정성 비교.
5. CI는 생성 소스의 Git 변경/삭제/미추적(ignored 포함)도 확인한다.
6. strict 분석(플러그인 포함)·전체 테스트·요청 시 Windows 빌드.

생성 적용과 성공 판정은 다르다. 실패 후 결과를 검토하고 명시적 재생성 뒤 verify를 다시 실행한다.
로컬 기본 검사는 HEAD가 아닌 시작 상태를 기준으로 하므로 유효한 미커밋 생성 결과를 무조건 거부하지 않는다.
CI는 필요한 생성 파일을 Git에 포함해야 한다. 검사 도구는 stage/commit/reset/checkout을 수행하지 않는다.
workflow는 기존 build_runner/AOT/독립 소비자 순서를 유지하고 앱 지역화/라우터 도구를 넣지 않는다.

## 공식 dart doc 검사

~~~powershell
./tool/fvm.ps1 dart doc --dry-run
./tool/fvm.ps1 dart tool/api_documentation.dart
./tool/fvm.ps1 dart tool/verify.dart
~~~

workflow에만 dartdoc_options.yaml을 두고 include: [r_edit_workflow]로 공개 진입점을 문서화한다.
기존 unnamed library는 include로 구별되지 않아 공개 진입점에 library r_edit_workflow를 명시했다.
unnecessary_library_name의 한 줄 예외만 이유와 함께 두었다. 공개 타입/함수/진단의 import URI와 업무 의미는 그대로다.
내부 도우미를 소비자 문서의 별도 library로 승격하지 않으며, 공개 타입이 lib/src에 정의되어 있어도 entry export를 통해 문서화한다.
공개 문서 lint는 기존 public_member_api_docs를 계속 적용한다.

SDK dartdoc 9.0.6은 일부 경고에서도 exit 0이다.
unresolved-doc-reference는 공식 errors 옵션으로 승격하고,
tool/api_documentation.dart가 같은 공식 dry-run의 모든 warning/error 진단 행과 exit code를 실패로 전달한다.
별도 문서 패키지/HTML 도구는 추가하지 않았다.
기존 README의 맨문장 lineBreak.lines[1]이 참조 [1]로 해석되던 경고는 inline code로 바로잡았다.
현재 문서 검사는 경고/오류 0건이다.

공식 dry-run은 --validate-links와 함께 사용할 수 없다.
이번 검사는 선언/문서 참조와 경고/오류를 다루며 HTML을 생성·열어본 시각 검증은 아니다.
외부 웹 링크 도달 가능성이나 HTML 링크를 전부 검사했다고 주장하지 않는다.
깨진 문서 참조가 있는 별도 패키지는 공식 오류 승격 및 문서 검사 경계에서 실패함을 확인했다.

## 공식 자료·라이선스 확인 경로

확인일 2026-10-28. 배포 archive의 LICENSE와 pubspec/CHANGELOG를 직접 대조했다.
- [riverpod_lint 3.1.9](https://pub.dev/packages/riverpod_lint/versions/3.1.9), [설치·변경 기록](https://pub.dev/packages/riverpod_lint/changelog)
- [Dart 분석 플러그인](https://dart.dev/tools/analyzer-plugins)
- [go_router_builder 4.5.2](https://pub.dev/packages/go_router_builder/versions/4.5.2), [변경 기록](https://pub.dev/packages/go_router_builder/changelog)
- [go_router 17.3.0](https://pub.dev/packages/go_router/versions/17.3.0)
- [meta 1.19.0](https://pub.dev/packages/meta/versions/1.19.0), [useResult](https://pub.dev/documentation/meta/1.19.0/meta/useResult-constant.html)
- [Flutter 공식 한국어화 구성](https://docs.flutter.dev/ui/internationalization)
- [Cupertino 기본 언어](https://api.flutter.dev/flutter/flutter_localizations/GlobalCupertinoLocalizations-class.html)
- [dart doc](https://dart.dev/tools/dart-doc), [문서 설정](https://pub.dev/packages/dartdoc#dartdoc_optionsyaml)


## 실제 검증 기록

- 앱: 전체 verify --windows 성공. 생성 시작 일치/반복 안정성·포맷·분석, 테스트 46개, Windows debug 빌드.
  위젯 테스트 파일 5개 사례와 생성 파일 검사 파일 16개 사례도 각각 단독 실행 성공.
- workflow: 전체 verify 성공. 생성 일치/반복 안정성·포맷·분석, 테스트 502개, AOT 검사 프로그램 7개,
  생성기 없는 독립 소비자 컴파일/실행. 문서 최종 재검사 경고 0·오류 0.
- 격리된 분석 자료: Provider BuildContext 오용은 avoid_build_context_in_providers 및 exit 1,
  외부 소비자의 반환값 무시는 unused_result 2건 및 exit 2로 거부했다.
  끊어진 문서 참조는 공식 오류 승격과 동일 문서 검사 경계에서 거부했다.
- 격리된 앱 복사본: 오래된 지역화 생성 파일은 내용 변경, 누락 파일은 추가 경로로 검출했다.
  첫 pub get이 자동 복구한 뒤에도 verify는 실패하며 재생성 명령과 해당 경로를 출력했다.
  CI의 지역화 미추적/변경/삭제 검사는 격리 Git fixture에서 확인했다.
- Windows 정상 시작 화면은 시각 확인했다. 기본 위젯 검사 전용 앱은 실행했지만
  화면 도구가 no monitor found for window로 실패하여 시각 확인은 미완료다.
  Material 취소/ Cupertino 복사 한국어 리소스는 위젯 테스트로 확인했다.
  검사 앱 종료 후 lib/main.dart의 정상 진입점으로 Windows debug 실행 파일을 다시 빌드했다.
- IDE 검사 실행, 원격 Actions, 다른 OS, HTML 생성/시각 검증은 하지 않았다.

새 생성 소스는 Git 포함 대상이다. 이번 작업은 stage하지 않으므로 사용자가 이후 커밋할 때
라우트 및 지역화 생성 파일을 함께 포함해야 한다. 미커밋 상태의 실제 작업 트리를 CI 성공으로 보고하지 않는다.
## Windows 고정 SDK의 Git 메타데이터 소비 (2026-11-01)

현재 Windows Git 소비를 위해 **이 패키지 pubspec.yaml의 메타데이터·주석은 ASCII로 유지한다.**
파일 저장은 UTF-8(BOM 없음)·LF다. 한국어 코드·API 주석·문서·업무 데이터에는 이 제한을 적용하지 않는다.
설명은 작업 데이터·변경 영향·결과 확인·저장/출력 흐름이라는 목적을 유지한 영문으로 변경했다.
이 설명이 저장/출력 기능의 구현 완료를 뜻하지는 않는다.
이름·버전·SDK 제약·의존성·업무 코드·생성 소스는 변경하지 않았다.

### 실패 근거와 고정 pub 구현

Flutter 3.47.7(프레임워크 abaf9c523780a608bd46686fd5e53740a07077f8), Dart 3.13.5를 유지했다.
설치 SDK의 revision 파일은 04bcd1036cdc799ac6564988f159ee454d42c822이다.
이 [SDK DEPS](https://github.com/dart-lang/sdk/blob/04bcd1036cdc799ac6564988f159ee454d42c822/DEPS)에 고정된
pub revision은 ec276d10a7fa0f6c6ec005340fb9ad29f3b012d0이다.
해당 [Git 실행 코드](https://github.com/dart-lang/pub/blob/ec276d10a7fa0f6c6ec005340fb9ad29f3b012d0/lib/src/git.dart)의
기본 stdoutEncoding은 systemEncoding이며,
[Git source 코드](https://github.com/dart-lang/pub/blob/ec276d10a7fa0f6c6ec005340fb9ad29f3b012d0/lib/src/source/git.dart)는
pubspec을 git show로 읽을 때 이를 별도 UTF-8로 지정하지 않는다.
이것은 설치 바이너리를 패치하거나 내부 코드를 추출한 검사가 아니라, 설치 revision→DEPS→고정 소스 대조다.
이전 조사에서 본 pub master는 비교 자료이며 고정 SDK의 포함 구현이라는 근거로 사용하지 않는다.

원격 기존 SHA 6213a211095ba6fc869d42abcfce542c986ca217은 실제 fetch되지만,
이 Windows 환경의 새 PUB_CACHE에서도 dart pub get --verbose가 exit 65로 실패했다.
오류는 `Error on line 20, column 1: Unexpected end of file.`이다.
같은 git show 출력을 고정 Dart Process.run으로 비교하면 원래 한국어 description의 따옴표는
UTF-8에서 2개/닫힘 정상, systemEncoding에서 1개/닫힘 손실이었다.
이는 이 Windows 환경에서 재현한 결과이며 모든 Windows 코드 페이지의 실패를 뜻하지 않는다.
pubspec의 비ASCII 내용은 description 한 줄뿐이었으며 이것만 영문으로 변경했다.
기존 파일의 CRLF 한 곳도 LF로 통일했다. CP949로 재저장하지 않았다.

### 실제 격리 검증

실제 작업 트리의 추적 파일을 복사하고 수정 pubspec을 포함한 임시 Git 저장소에서만 검증 커밋을 만들었다.
임시 고정 ref는 ba9f7afc9f2b0c66091ab60552f4ef1b8c32e7bc이며 **원격 배포 SHA가 아니다.**
소비자는 file:// Git URL + 전체 ref를 사용했다. path 의존성·override는 사용하지 않았다.
기존 원격 SHA 소비자와 수정 임시 SHA 소비자는 각각 새 별도 PUB_CACHE를 사용했다.
FVM wrapper의 기본 캐시 대입을 피하려고 .fvm/flutter_sdk/bin/cache/dart-sdk/bin/dart.exe를 직접 실행하고,
PUB_CACHE는 해당 검사 프로세스에만 설정했다. SDK/캐시 패치·전역 Git 설정/코드 페이지 변경은 하지 않았다.

| 검사 | 실제 결과 |
|---|---|
| 기존 원격 SHA, 새 캐시 pub get | exit 65, 위 YAML 오류 재현 |
| 수정 임시 Git SHA, 새 캐시 pub get | exit 0, lock의 source: git 및 ref/resolved-ref 일치 |
| 수정 Git blob의 전체 문자열 | UTF-8/systemEncoding 결과가 실제 수정 파일과 정확히 일치 |
| 실제 수정 pubspec 및 임시 Git blob | ASCII만 포함, 유효 UTF-8·BOM 없음·CR 없음(LF) |
| pub 캐시 checkout 내용 | 설명과 모든 메타데이터 무손실. 기존 Git checkout 설정에 의해 CRLF 19개이며 캐시를 수정하지 않음 |
| 생성기 없는 소비자 | build_runner/freezed/json_serializable 없음, 기존 example/product_configuration.dart를 AOT 컴파일·실행 성공 |
| 실제 세션 소비 | open→prepare→apply, 개정 1·새 스냅샷 참조·원문/직접 지정 한 줄 보존 확인 |
| 실제 workflow 전체 verify | 시작 생성 일치·반복 안정성·포맷·분석 성공, 문서 경고/오류 0, 테스트 576개·AOT 9개·기존 독립 소비자 성공 |

캐시 내용 검사의 줄바꿈 구분은 메타데이터 무손실 확인용이다.
기존 생성 파일 바이트 검사를 완화하거나 정규화한 것이 아니다.
격리 증거는 검사한 앱 checkout의 .tooling/ascii-git-consumption/ 아래 old-pub-get.log,
fixed-pub-get.log, fixed/pubspec.lock, metadata_probe.dart와 fixed/consumer.exe에 남겼다.
이는 로컬 임시 증거이며 라이브러리 소비에 형제 앱이나 이 경로를 요구하지 않는다.

### 게시 후 앱 연결 절차

1. 사용자가 실제 workflow의 이 수정과 기록을 검토·커밋·원격 게시한다. 이번 작업은 stage/commit/push하지 않는다.
2. 게시된 실제 전체 SHA를 원격에서 새 fetch하여 메타데이터·세션 API·생성 소스를 다시 확인한다.
3. 앱 pubspec에 그 실제 SHA를 고정하고 앱 lock을 갱신한다. 임시 검증 SHA나 브랜치 최신값으로 대신하지 않는다.
4. override 없이 Windows pub get 및 독립 checkout 검증 후 등록·소유/활성화·준비·확인/취소·관찰 통지·close Provider 구현을 이어간다.

수정본의 원격 GitHub 소비는 아직 게시되지 않아 미검증이다. 앱 의존성/Provider·SDK·CI는 변경하지 않았다.
