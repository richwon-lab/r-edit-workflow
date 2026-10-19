# 모델 작성 도구 비교

2026-10-20 네이밍·JSON 후속 결정: 이 문서는 당시 이름과 실행 결과를 보존한 과거 기록이다. 현재 API·JSON·오류와 새 검증 결과는 [현재 정리 기록](input-naming-json.md)과 [현재 계약](contract.md)을 따른다. 아래 검사를 새 이름으로 재실행한 것으로 해석하지 않는다. 비교 도구는 당시 공개 API를 참조하므로 현재 루트와의 재실행 호환성을 보장하지 않는다.

이 문서는 2026-10-19 비교 당시 기록이다. 2026-10-20 사용자가 Freezed 채택과 현재 모델 전환을 결정했으며 현재 상태는 [전환 기록](freezed-migration.md)을 따른다. 아래 현재 모델 유지 추천은 당시 평가로 보존한다.

확인일: 2026-10-19 (한국시간). 대상 r_edit_workflow, 시작 HEAD `ffe689b8db566ff3576be60015c8a065a94446e1`, 시작 변경·스테이징 없음.

다음 생성 도구 후보는 **Freezed + json_serializable**을 추천한다. 명명 인자 생성자·copyWith가 읽기 쉽고 기존 List API와 연결하기 쉽다. 현재 작은 공개 TextAreaInput은 유지한다. 이번 비교는 교체 승인이나 모든 모델에 생성 도구를 쓰라는 결정이 아니다.

## 1. 실제 SDK와 프로젝트별 사용

| 구분 | 실제 확인 결과 |
|---|---|
| 현재 PATH | C:/develop/flutter/bin/flutter.bat, dart.bat |
| 기존 환경 | Flutter 3.44.8 stable / Dart 3.12.2 Windows x64 |
| SDK 공유 근거 | r_edit/.idea/libraries/Dart_SDK.xml이 같은 SDK 참조. plate_flutter·r-desk도 Flutter pubspec이 있으나 그 IDE 경로까지 모두 확인한 것은 아님 |
| 공식 최신 안정 태그 | 3.47.7, 태그와 stable ref 모두 abaf9c523780a608bd46686fd5e53740a07077f8 |
| 비교 전용 경로 | C:/Users/sdf75/AppData/Local/Temp/r_edit_model_tools_flutter_3.47.7 |
| 비교 실제 런타임 | Flutter 3.47.7 / 포함 Dart 3.13.5 stable, DevTools 2.60.0 |

공유 SDK를 upgrade하지 않고 별도 폴더에 공식 안정 태그를 복제했다. detached checkout이므로 버전 출력의 channel은 [user-branch]지만 공식 stable과 동일 커밋을 확인했다. 긴 경로 때문에 첫 checkout이 실패해 이 새 복제본에만 core.longpaths=true로 복구했다. BITS 실패 후 Flutter 도구의 WebRequest 재시도로 SDK 준비가 완료됐다. 배포 releases_windows.json 조회는 NoSuchKey로 실패했고 GitHub releases/latest도 오래된 prerelease여서 최신 안정 근거로 사용하지 않았다. 공식 Git stable/tag와 실제 실행을 사용했다.

지속 사용 시 별도 영구 폴더(예: 개발 SDK 보관 위치의 flutter-3.47.7)에 같은 태그를 준비하고, 해당 프로젝트의 IDE Flutter SDK와 Dart SDK를 각각 그 폴더와 bin/cache/dart-sdk로 지정하는 안을 추천한다. 셸에서는 전체 경로로 호출해 전역 PATH를 바꾸지 않는다. 임시 SDK는 정리될 수 있으므로 영구 프로젝트 설정으로 그대로 채택하지 않는다. 이번에 IDE·전역 PATH·공유 SDK·루트 SDK 제약을 변경하지 않았다.

## 2. 후보별 독립 의존성 해결

저장소 안의 [Freezed pubspec](../tool/model_comparison/freezed/pubspec.yaml), [built_value pubspec](../tool/model_comparison/built_value/pubspec.yaml)에서 각각 해결했다. 새 Git 저장소·Dart workspace·dependency_overrides는 없다. 루트 패키지는 공개 오류 타입 참조와 테스트 오라클용 path 의존성이다. 후보 업무 검증을 기존 모델에 위임하지 않고 내부 src를 가져오지 않는다.

| 해결 버전 | Freezed 후보 | built_value 후보 |
|---|---|---|
| 비교 패키지 SDK | ^3.13.0 | ^3.13.0, 같은 비교 환경 |
| 직접 런타임 | freezed_annotation 3.1.0, json_annotation 4.12.0 | built_value 8.13.0, built_collection 5.1.2 |
| 생성기 | freezed 4.0.3, json_serializable 6.14.1 | built_value_generator 8.13.0 |
| build_runner | 2.16.2 | 2.16.2 |
| 주요 생성 도구 | analyzer 14.5.0, build 4.0.11, source_gen 4.3.1 | 동일 |
| 테스트·lint | test 1.33.0, lints 6.1.0 | 동일 |
| 해결 기록 | [70개 의존 패키지](../tool/model_comparison/freezed/resolved-dependencies.json) | [66개 의존 패키지](../tool/model_comparison/built_value/resolved-dependencies.json) |

Freezed 4.0.3은 Dart >=3.13이 필요하다. json_serializable의 build ^4와 built_value_generator의 build <5 때문에 두 후보 모두 허용 범위에서 build_runner 2.16.2가 선택됐다. 최신 2.17.1의 build 5 요구를 강제 우회하지 않았다. runner 제약은 >=2.4.0 <3.0.0이며 실제 버전을 위 표와 JSON에 기록했다. Freezed 그래프의 built_value/built_collection은 build_runner 간접 의존성이고 built_value_generator를 함께 등록한 것이 아니다.

루트 pubspec·공개 lib·기존 test는 변경하지 않았다. 비교 패키지는 각 SDK/의존성으로 분석하므로 루트 analysis_options에서 tool/model_comparison/**만 제외했다. .gitignore에는 비교 build·로그만 더했다. 기존 .dart_tool·라이브러리 lock 제외 정책은 유지한다. resolved-dependencies.json은 실행 기록이지 향후 해결을 강제하는 lock이 아니다.

## 3. 실제 사용 코드 비교

TrialArea/TrialBreak는 비교 전용이며 루트 export에 추가하지 않았다. 이번에는 mode+선택 lines 구조를 양쪽 동일하게 사용하고 명명 생성자·검증으로 자동/직접 의미를 보장했다. 공개 sealed LineBreakSpec을 교체한 것이 아니며 Freezed의 모든 union 생성 모드를 평가한 것도 아니다.

| 작업 | Freezed | built_value |
|---|---|---|
| 선언 | `final class TrialArea with _$TrialArea` | `abstract class TrialArea implements Built<TrialArea, TrialAreaBuilder>` |
| 최초 생성 | `TrialArea(areaId: 'a', sourceText: 'PUMP', lineBreak: TrialBreak.manual(['PUMP']))` | `TrialArea((b) => b..areaId = 'a'..sourceText = 'PUMP'..lineBreak.replace(TrialBreak.manual(['PUMP'])))` |
| 동시 변경 | `value.copyWith(sourceText: 'VALVE', lineBreak: TrialBreak.manual(['VAL', 'VE']))` | `value.rebuild((b) => b..sourceText = 'VALVE'..lineBreak.replace(TrialBreak.manual(['VAL', 'VE'])))` |
| 조회 | `value.sourceText` | `value.sourceText` |
| JSON 저장 | `jsonEncode(value.toJson())` | `jsonEncode(value.toJson())` |
| JSON 복원 | `TrialArea.fromJson(jsonDecode(encoded))` | `TrialArea.fromJson(jsonDecode(encoded))` |
| 업무 검증 | 일반 생성자 본문 | finalizeBuilder 훅 |
| 오류 변환 | readArea/readBreak → 생성 JSON 함수 | 같은 검사 → StandardJsonPlugin serializer |

전체 사용 코드는 [Freezed usage](../tool/model_comparison/freezed/lib/usage.dart), [built_value usage](../tool/model_comparison/built_value/lib/usage.dart)다. 다음은 실제 모델 선언이다.

### Freezed 선언
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'validation.dart';

part 'model.freezed.dart';
part 'model.g.dart';

// 일반 생성자에서 검증하므로 생성된 copyWith/JSON 경로도 같은 검사를 거친다.
@freezed
@JsonSerializable(explicitToJson: true)
final class TrialArea with _$TrialArea {
  TrialArea({
    required this.areaId,
    required this.sourceText,
    required this.lineBreak,
  }) {
    validateArea(areaId, sourceText, lineBreak.mode, lineBreak.lines);
  }
  final String areaId;
  final String sourceText;
  final TrialBreak lineBreak;

  factory TrialArea.fromJson(Object? json) =>
      _$TrialAreaFromJson(readArea(json));
  Map<String, Object?> toJson() => _$TrialAreaToJson(this);
}

// 두 방식은 명시적 mode로 구분한다. 자동의 lines는 JSON에서 생략한다.
@freezed
@JsonSerializable(includeIfNull: false)
final class TrialBreak with _$TrialBreak {
  TrialBreak({required this.mode, List<String>? lines})
    : lines = lines == null ? null : List.unmodifiable(lines) {
    validateBreak(mode, this.lines);
  }
  factory TrialBreak.auto() => TrialBreak(mode: 'auto');
  factory TrialBreak.manual(List<String> lines) =>
      TrialBreak(mode: 'manual', lines: lines);
  final String mode;
  final List<String>? lines;

  factory TrialBreak.fromJson(Object? json) =>
      _$TrialBreakFromJson(readBreak(json));
  Map<String, Object?> toJson() => _$TrialBreakToJson(this);
}
```

### built_value 선언

```dart
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';

import 'validation.dart';

part 'model.g.dart';

abstract class TrialArea implements Built<TrialArea, TrialAreaBuilder> {
  String get areaId;
  String get sourceText;
  TrialBreak get lineBreak;
  TrialArea._();
  factory TrialArea([void Function(TrialAreaBuilder)? updates]) = _$TrialArea;

  // build/rebuild와 생성된 역직렬화가 값을 확정하기 전에 실행한다.
  @BuiltValueHook(finalizeBuilder: true)
  static void validate(TrialAreaBuilder builder) {
    final spec = builder.lineBreak.build();
    validateArea(builder.areaId, builder.sourceText, spec.mode, spec.lines);
  }

  static Serializer<TrialArea> get serializer => _$trialAreaSerializer;
  factory TrialArea.fromJson(Object? json) =>
      _serializers.deserializeWith(TrialArea.serializer, readArea(json))!;
  Map<String, Object?> toJson() => Map<String, Object?>.from(
    _serializers.serializeWith(TrialArea.serializer, this) as Map,
  );
}

@BuiltValue(nestedBuilders: false)
abstract class TrialBreak implements Built<TrialBreak, TrialBreakBuilder> {
  String get mode;
  BuiltList<String>? get lines;
  TrialBreak._();
  factory TrialBreak([void Function(TrialBreakBuilder)? updates]) =
      _$TrialBreak;
  factory TrialBreak.auto() => TrialBreak((b) => b.mode = 'auto');
  factory TrialBreak.manual(List<String> lines) => TrialBreak(
    (b) => b
      ..mode = 'manual'
      ..lines = BuiltList(lines),
  );

  @BuiltValueHook(finalizeBuilder: true)
  static void validate(TrialBreakBuilder builder) =>
      validateBreak(builder.mode, builder.lines);
  static Serializer<TrialBreak> get serializer => _$trialBreakSerializer;
}

// 공개 JSON의 객체 형태를 유지하기 위한 플러그인이다.
final _serializers =
    (Serializers().toBuilder()
          ..add(TrialArea.serializer)
          ..add(TrialBreak.serializer)
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addPlugin(StandardJsonPlugin()))
        .build();
```

## 4. 직접 작성한 검증과 오류 변환

두 [validation.dart](../tool/model_comparison/freezed/lib/validation.dart)는 같은 126줄 코드다. 빈 ID·원문·줄·CR/LF·연결 일치, JSON 필수 누락·타입·모르는 방식·추가 필드를 검사한다. 공개 오류 타입만 기존 패키지에서 재사용한다. 생성기 기본 TypeError/serializer 오류를 사후 문자열 분석하는 대신 **JSON 경계에서 먼저 기존 code/path를 검사**한다. 생성 후 일관성은 생성자/훅에서 다시 검사한다. 예상하지 못한 모든 예외를 정상값으로 바꾸지 않는다.

핵심 직접 작성 로직은 다음과 같으며 전체는 validation.dart에 있다.

```dart
validateBreak(mode, lines);
if (mode == 'manual' && lines!.join() != text) {
  fail(TextInputErrorCode.manualTextMismatch, 'lineBreak.lines');
}
```

Freezed에서 생성 래퍼만 검사하면 생성된 copyWith/JSON이 우회할 수 있다. 그래서 일반 생성자 본문에서 예외를 던지고 final class로 제한했다. 실제 생성 코드의 copyWith와 중첩 copyWith.lineBreak가 이 생성자를 호출함을 검사했다. List.unmodifiable로 외부 목록을 복사하며 수정 불가 getter 뷰에만 의존하지 않는다. @Assert는 릴리스 업무 검증에 사용하지 않는다.

built_value는 finalizeBuilder 훅을 사용해 생성·build·rebuild·역직렬화의 값 확정 전에 검사한다. 초기 nullable lines의 ListBuilder getter가 빈 빌더를 자동 생성하는 차이를 발견했다. TrialBreak의 nestedBuilders:false와 BuiltList? 직접 사용으로 auto와의 충돌을 해결했다. 이 설정, serializer 등록, StandardJsonPlugin과 컬렉션 builder factory는 직접 관리하는 코드다.

우회 검사는 **제공한 생성·수정·JSON API와 생성기가 생성한 정상 경로**를 대상으로 한다. built_value 추상 인터페이스를 외부에서 implements로 위조하는 등 임의 Dart 코드를 금지했다고 주장하지 않는다. 채택 시 신뢰 경계를 명시하고 외부에서 받은 값은 계산/저장 경계에서도 검사해야 한다. 이번 비교를 모든 생성 모드·서브클래싱의 안전성 증명으로 확대하지 않는다.

## 5. 실제 실행 결과

| 검사 | Freezed | built_value | 기존 공개 구현 |
|---|---|---|---|
| 환경 | Dart 3.13.5 | Dart 3.13.5 | Dart 3.12.2 |
| pub get | 성공 | 성공 | 기존 의존성으로 성공 |
| build_runner 생성 | 성공, 최종 생성 파일 2개 | 성공, 최종 생성 파일 1개 | 해당 없음 |
| format/analyze | 성공 / No issues found | 성공 / No issues found | 성공 / No issues found |
| 테스트 | 70개 통과 | 동일 70개 통과 | 기존 64개 통과 |
| compile exe/AOT 실행 | 성공 | 성공 | 이번 비교에서 별도 AOT 실행 안 함 |
| assert 비활성 오류 검사 | 11건 거부 확인 | 동일 11건 거부 확인 | 해당 없음 |

후보별 70개는 유효 원문 사례 9개, 수정/생성/불변성/방식 차이 4개, JSON 오류 code/path 대조 57개다. 기존 테스트의 앞뒤/연속 공백·기호·대소문자·한글·결합형·이모지·반복 문자열·공백만/탭 원문을 재사용했다. 실제 JSON 문자열로 왕복하고 기존 구현을 오류 계약 오라클로 대조했다. 생성·수정 검사는 후보 자체 API를 사용했다.

원문만 바꾼 copyWith/rebuild, 지정 줄만 바꾼 중첩 copyWith/하위 builder, 서로 안 맞는 원문+줄 동시 수정은 모두 거부됐다. 전달 목록과 수정에 사용한 목록을 나중에 비우거나 반환 JSON 목록을 변경해도 기존 값은 유지됐다. 직접 지정 한 줄과 자동 값은 다르다.

AOT 프로그램은 assert가 꺼졌음을 직접 확인하고 조건문/예외로 업무 검증을 검사한다. 정상 원문/왕복/동시 교체·기존 값 보존과 네이밍 예시도 실행했다. **Windows 순수 Dart AOT** 검사이며 Flutter 앱 릴리스 빌드·UI·Type3 검증은 아니다. 초기 lint와 built nullable builder 경고는 수정 후 다시 분석해 최종 문제 없음을 확인했다.

## 6. 비용과 추천

| 평가 | Freezed + json_serializable | built_value + built_collection |
|---|---|---|
| 유지보수 관찰 | Freezed 4.0.3 게시 2026-10-17, JSON 생성기 6.14.1 게시 2026-07-30 | 값/생성기 8.13.0 게시 2026-09-02, 컬렉션 5.1.2 게시 2026-09-28 |
| SDK | Freezed 4는 Dart >=3.13. 기존 3.12.2에서 이 최신 조합 사용 불가 | 런타임 최소 >=3.0, 컬렉션 ^3.11. 실제 최신 생성기/analyzer/runner 해결은 이번 3.13.5에서 검사 |
| 생성 도구 결합 | Freezed+JSON 생성기, analyzer/build/source_gen | 값/serializer 생성기, runtime/collection/serializer |
| 읽기 쉬움 | 일반 명명 인자 생성자와 copyWith가 기존 코드에 가까움 | cascade/replace/rebuild·builder 수명 이해 필요 |
| 직접 모델+검증 | 45+126=171줄 | 62+126=188줄 |
| 직접 사용 예시 | usage.dart 18줄 | usage.dart 27줄 |
| 생성 코드 | 409+27=436줄 | 386줄 |
| 불변 목록 | List.unmodifiable 복사를 직접 유지 | BuiltList와 builder 변환 |
| 오류 계약 | 자동 해결 안 됨. 수동 경계 검사·업무 검증 유지 | 동일. serializer 기본 오류를 바로 공개 계약으로 쓸 수 없음 |
| 모듈 영향 | 공개하면 생성 API/annotation에 결합 가능 | BuiltList/Builder/Serializer를 공개하면 소비자 타입·수정 방식까지 영향 |

줄 수는 빈 줄·주석 포함이며 테스트·네이밍 예시는 별도다. 오류 타입은 기존 타입을 재사용했으므로 기존 수동 구현 전체와 이 숫자만으로 절대 비용을 비교하지 않는다. 최근 배포는 유지보수 활동의 관찰 근거이며 장기 호환 보증은 아니다. 성능·메모리·대규모 생성 시간은 측정하지 않았다.

향후 반복 모델이 늘 때 **Freezed의 일반 생성자 방식**부터 검토할 것을 추천한다. 생성자 런타임 검증·방어 복사·수동 JSON 오류 경계·생성된 수정 경로 테스트를 함께 채택해야 한다. 현재 작은 모델은 유지한다. builder 중심의 큰 중첩 편집과 BuiltList 생태계에 실제 이점이 생기면 built_value를 다시 검토한다. [개발 규칙 초안](development-rules-draft.md)은 별도 검토 자료이며 AGENTS나 기존 이름을 일괄 변경하지 않았다.

## 7. 재실행

두 후보 하위 폴더에서 각각 실행한다. 루트 명령만으로 비교 검사까지 수행했다고 간주하지 않는다.

```powershell
$comparisonDart = "$env:TEMP/r_edit_model_tools_flutter_3.47.7/bin/cache/dart-sdk/bin/dart.exe"
& $comparisonDart pub get
& $comparisonDart run build_runner build
& $comparisonDart format lib test bin
& $comparisonDart analyze
& $comparisonDart test
New-Item -ItemType Directory -Force build | Out-Null
& $comparisonDart compile exe bin/release_probe.dart -o build/release_probe.exe
& ./build/release_probe.exe
```

SDK가 없으면 별도 경로에 같은 안정 태그를 준비해 호출 경로를 바꾼다. 생성 코드는 직접 수정하지 않는다. 라이브러리 lock은 기존 정책대로 제외되어 있으므로 재실행 시 실제 해결 버전과 JSON 기록도 대조한다.

## 8. 공식 근거와 문서로만 확인한 범위

확인일은 모두 2026-10-19다. 실제 실행은 위 1·2·5절에 구분했고, 아래 문서는 도구 사용·버전·작성 기준의 근거다.

- [Flutter SDK archive](https://docs.flutter.dev/install/archive): 안정 채널·포함 Dart 확인 기준.
- [공식 3.47.7 태그](https://github.com/flutter/flutter/tree/3.47.7), [stable](https://github.com/flutter/flutter/tree/stable): 태그/커밋 대조. stable은 이후 변경 가능.
- [Freezed](https://pub.dev/packages/freezed), [버전 목록](https://pub.dev/packages/freezed/versions): 일반 생성자·copyWith·컬렉션·JSON·SDK.
- [json_serializable](https://pub.dev/packages/json_serializable): JSON 생성 역할·의존성.
- [built_value](https://pub.dev/packages/built_value), [built_collection](https://pub.dev/packages/built_collection), [built_value_generator](https://pub.dev/packages/built_value_generator): 공식 배포·사용법.
- [BuiltValueHook](https://pub.dev/documentation/built_value/latest/built_value/BuiltValueHook-class.html): finalizeBuilder 시점. 웹 latest API 하단은 8.12.7로 표시돼 실제 8.13.0 생성 코드·실행과 함께 확인했다.
- [StandardJsonPlugin](https://pub.dev/documentation/built_value/latest/standard_json_plugin/StandardJsonPlugin-class.html): 표준 JSON 변환.
- [Effective Dart Style](https://dart.dev/effective-dart/style): 영어 식별자·약어·포맷.

최신 버전·게시 시각·SDK 제약은 pub.dev/api/packages 응답과 실제 해결 결과로 확인했다. 모든 공식 예제·모든 union/상속 모드를 실행한 것은 아니며 문서의 일반 설명을 업무 불변식 보증으로 간주하지 않았다. 커밋·푸시는 하지 않았다.
