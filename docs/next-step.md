# 완료 범위와 다음 작업

현재 상태는 아래 초기 네이밍·JSON 정리와 [현재 정리 기록](input-naming-json.md)을 따른다. 앞선 날짜별 기록의 이름·검사 결과는 당시 사실이며 새 API로 재실행한 기록이 아니다.
## 이번에 완료한 초기 정리

- 순수 Dart 패키지의 이름을 유지하고 설명, 비공개 게시 설정, 초기 버전 0.1.0을 정리했다.
- 앱과 같은 SDK 제약 ^3.12.2 및 기존 lints·test 제약을 유지했다.
- 생성된 Awesome 구현과 해당 테스트·실행 예제를 제거하고 공개 진입점을 유지했다.
- 책임·외부 경계·개발 규칙·기준 문서 위치를 기록하고 로컬 생성 파일의 무시 규칙을 정리했다.

현재 영역 원문·줄바꿈 입력 모델과 JSON 조각을 구현했고 실제 테스트가 있다. 전체 문서·세션·도안·수량·그룹·배치·저장·출력 기능은 아직 미구현이다.
최신 실제 검증 결과는 아래 영역 입력 구현 기록을 따른다. 커밋·푸시하지 않는다.

## 다음 작업 한 가지

첫 도형·텍스트 영역·제작 조건의 지원 단면과 도안 변경 시 영역 ID 대응을 설계에서 정한다. 이후 적용 도안 공유와 명시 대상 분리 모델을 구현한다. 이번에 완료한 영역 입력 JSON을 WorkDocument 전체 형식이나 임시 저장 기능으로 확장 해석하지 않는다.

빈 원문·빈 줄·CR/LF는 영역 입력 첫 구현에서 미지원으로 구분했으며 전체 제품 정책은 계속 보류한다. 문자 위치 단위·오프셋, 그룹 알고리즘·결과/확인 수명은 아직 구현하지 않는다. 코드·API가 실제로 필요한 범위만 순차 추가한다.

## 초기 패키지 정리 당시 검증 결과

2026-10-19, Dart SDK 3.12.2 stable (Windows x64)에서 확인했다.

- dart pub get: 성공. 기존 개발 의존성 제약을 유지했고 일괄 업그레이드하지 않았다.
- dart format lib: 실제 존재하는 Dart 소스 1개를 포맷했다.
- dart analyze: No issues found.
- dart test: 테스트 없음. 생성 예제 전용 테스트를 제거했으므로 실행하지 않았다.

PATH의 dart.bat 버전 조회가 완료되지 않아 Flutter SDK 내부의 dart.exe를 직접 사용했다.
최초 pub get은 샌드박스의 사용자 프로필 진단 설정 생성 권한 때문에 실패했으나,
권한을 허용한 실행에서 위 검증을 완료했다.
업무 동작과 JSON 왕복은 미구현이므로 아직 검증하지 않았다.

## 최초 잠정 설계 당시 기록 (2026-10-19)

- docs/model-design.md에 잠정 클래스·필드·관계·저장/세션 구분·불변식과 두 제품 합성 JSON을 작성했다. Dart 구현은 아직 하지 않았다.
- 참고 앱 커밋: ac11bd44cf098f3cc16b69b2d82d67eb94d1844a. 읽은 파일의 절대 경로는 설계안에 기록했다.
- 앱 docs에는 decisions.md, module-boundaries.md, next-step.md만 있었다. 요청된 XLSX·DOCX·텍스트 추출본과 docs/README.md는 찾지 못했다. 전체 설계 자료 검토는 미완료다.
- 원문 조각 목록을 직접 지정 줄바꿈 표현의 후보로 제안했으나 문자 위치 단위·좌표·정밀도·수량 출력 표현은 확정하지 않았다.
- 이번에는 문서와 예시 JSON만 확인한다. Dart/Flutter 명령은 코드 변경이 없어 실행하지 않으며 과거 분석 결과를 새 모델 검증으로 간주하지 않는다.
- 형제 앱 파일·코드·의존성·Git 이력은 변경하지 않는다. 이번 작업은 커밋·푸시하지 않는다.

## 전체 기준 추가 후 원본 대조 (2026-10-19)

- 작업 대상은 C:/work/richwon/r_edit_workflow다. 시작 시 이전 설계 문서 변경을 보존하고 docs/model-design.md, docs/contract.md, 이 문서만 개정했다.
- 앱 docs/README.md가 연결한 점검표 XLSX·논리 설계 DOCX와 두 TXT 추출본을 확인했다. 과거 누락 상태는 해소됐다. 실제 경로·원본 SHA-256과 참고 앱 HEAD ac11bd44cf098f3cc16b69b2d82d67eb94d1844a를 모델 설계에 기록했다. 추가 자료는 해당 커밋에 없는 앱 작업 트리 자료다.
- DOCX 본문/표 문단 270개와 XLSX 두 시트의 비어 있지 않은 셀 720개(수식 0개)의 값이 추출본에 포함됨을 읽기 전용 XML 대조로 확인했다. 도형·이미지·서식은 시각 검토하지 않았다.
- WorkDocument/WorkSession 분리, 결과별 OperatorReview 연결은 유지했다. 적용 도안 공유 참조·개별 변경 시 분리·명시 대상 전체 적용, 형상/영역 대 규칙/패턴의 소유권을 보완했다.
- 추가·삭제·이전/새 그룹·자동/직접 전환의 영향과 영역별 결과 재사용을 구분했다. 자체 localInputId와 전체 계산 inputId를 나누고 불변 내용 대조·저장 정합성 검사의 한계를 명시했다.
- EngineIdentity.kind의 합성 구분과 운영 저장 거부 분기는 근거가 없어 제거했다. JSON은 공유 도안과 자동/직접 한 줄 입력의 관계 발췌로 교체했으며, 완전한 완료 파일·실제 계산 결과로 간주하지 않는다.
- 원본에서도 미정인 문자 위치/줄 경계 단위, 형상·좌표 지원 범위, 그룹 알고리즘과 수량 0/빈 값 정책은 계속 미정이다. 원본 대조로 모든 API·형식이 확정된 것은 아니다.
- 문서 상대 링크와 예시 JSON 문법·도안 공유·기준 참조·원문 연결·직접 지정 한 줄을 검사했고 모두 통과했다. git diff --check도 통과했다. 코드 변경이 없어 Dart/Flutter 명령은 실행하지 않는다. 실제 업무 테스트·과거 시험 재실행은 하지 않았다.
- 형제 앱의 기존 스테이징/미추적 자료와 수정 파일, 코드·의존성·Git 이력은 보존한다. 커밋·푸시하지 않는다.

## 영역 원문·줄바꿈 입력 구현 (2026-10-19)

- 시작 시 docs/contract.md와 docs/next-step.md에 기존 변경이 있었고 docs/model-design.md는 스테이징된 추가 파일이었다. 기존 문서를 보존해 필요한 구현 기록을 더했으며 이번에 git add·커밋·푸시하지 않았다.
- lib/src/text_area_input.dart에 TextAreaInput·LineBreakSpec·AutoLineBreak·ManualLineBreak와 TextInputException/TextInputErrorCode를 구현하고 lib/r_edit_workflow.dart에서 공개했다.
- TextAreaInput은 영역 입력 자체의 책임을 나타내므로 ProductTextInput 후보 대신 선택했다. 원문·줄 지정은 하나의 불변 객체로 생성·교체하고 목록은 방어 복사한다.
- 명시적 auto/manual, 직접 지정 한 줄/여러 줄, 원문 정확한 연결을 지원한다. 빈 원문·빈 줄·원문/줄의 CR/LF는 원인을 구분해 미지원 처리하며 공백만 있는 문자열은 그대로 지원한다.
- JSON 필수 누락·타입 오류·모르는 방식·추가 필드·줄 불일치를 code/path가 있는 예외로 구분한다. Dart 기본 JSON 변환만 사용했고 pubspec.yaml·개발 의존성은 변경하지 않았다.
- test/text_area_input_test.dart는 공개 API로 실제 왕복·원문/Unicode 보존·반복 문자열·불변성·원자적 교체·오류/미지원 입력을 확인한다. 실제 배치·제작 가능 검증은 아니다.
- SDK: C:/develop/flutter/bin/cache/dart-sdk/bin/dart.exe, Dart 3.12.2 stable. 초기 정적 접근 오류(hashCode)로 분석/테스트 로딩이 실패했으며 수정 후 아래 검사를 통과했다.
- dart pub get: 종료 코드 0. 기존 의존성으로 해결, 일괄 업그레이드 없음.
- dart format lib test: 종료 코드 0. 최종 3개 Dart 파일 확인.
- dart analyze: 종료 코드 0, No issues found!.
- dart test: 종료 코드 0, 테스트 64개 통과.
- 형제 앱·엔진·DXF·Flutter·파일 I/O·전체 문서·세션·도안·수량·그룹·결과 모델은 변경/구현하지 않았다. 문자 오프셋 API도 없다.

## 모델 도구 비교·개발 규칙 초안 (2026-10-19)

- 시작 HEAD ffe689b8db566ff3576be60015c8a065a94446e1, 변경·스테이징 없음. 공개 lib·기존 test·pubspec·AGENTS는 변경하지 않았다.
- tool/model_comparison/freezed와 built_value의 별도 pubspec으로 비교했다. 실제 모델 선언·생성·수정·JSON·검증 코드와 결과는 model-tools-comparison.md에, 이름·주석·책임 명칭 초안은 development-rules-draft.md에 기록했다.
- 공유 Flutter 3.44.8/Dart 3.12.2는 유지했다. 공식 안정 3.47.7 태그와 stable 커밋을 확인하고 별도 임시 경로의 포함 Dart 3.13.5로 두 후보를 실행했다. 지속 사용용 프로젝트별 SDK 방안은 비교 문서에 남겼다.
- Freezed 4.0.3 + json_serializable 6.14.1, built_value/생성기 8.13.0 + built_collection 5.1.2, build_runner 2.16.2를 후보별로 해결했다. dependency_overrides는 사용하지 않았다. 전체 해결 그래프는 후보별 resolved-dependencies.json에 있다.
- 두 후보 모두 코드 생성·포맷·분석 성공, 동일 테스트 70개 통과, assert 비활성 AOT에서 오류 11건 거부와 정상 왕복·동시 교체·네이밍 예시 실행을 확인했다.
- 기존 공개 구현도 기존 Dart 3.12.2에서 pub get·format·analyze 성공, 기존 테스트 64개 통과를 확인했다. 비교 패키지는 루트 분석 대상에서 제외하고 각각 별도 분석했다.
- 향후 생성 도구는 Freezed 일반 생성자 방식을 우선 검토하되 현재 작은 공개 모델은 유지할 것을 추천한다. 생성 도구·규칙의 일괄 채택은 아직 확정하지 않았다.
- 다음 구현 전 이 추천·규칙 초안을 검토한다. 기존 다음 설계 과제인 첫 도형·영역·제작 조건 단면은 그대로 남아 있으며 새 업무 모델·UI·엔진은 구현하지 않았다.
- 이번 변경은 비교 도구·문서·분석/산출물 제외 설정뿐이다. 커밋·푸시하지 않는다.

## Freezed 전환·개발 기준 채택 (2026-10-20)

- 시작 HEAD 5eeb3cad3eef2f3dfcfe2fc84a3916197ec8bc06, 변경·스테이징 없음. 이번 작업에서도 git add·커밋·푸시하지 않는다.
- 영구 프로젝트 경로 .toolchains/flutter-3.47.7에 SDK를 별도로 준비했다. 해당 경로에서 Flutter 3.47.7/Dart 3.13.5 실행과 커밋을 확인했다. 공유 SDK·전역 PATH·다른 프로젝트 설정은 변경하지 않았다.
- pubspec SDK를 ^3.13.5로 정리하고 annotation 3.1.0/4.12.0, Freezed 4.0.3, json_serializable 6.14.1, build_runner 2.16.2를 선택했다. overrides는 없다.
- 운영 TextAreaInput과 구체 줄바꿈 타입을 Freezed로 전환했다. 공개 이름과 JSON/code/path, LineBreakSpec의 sealed 분기·직접 지정 한 줄·미지원 구분을 유지한다. 생성된 copyWith도 실제 생성자의 업무 검증을 호출한다.
- build.yaml로 운영 모델만 생성한다. lib/src/text_area_input.freezed.dart와 .g.dart는 Git 관리 대상이며 재생성 SHA-256 일치를 확인했다. SDK·캐시·빌드는 제외하고 생성 파일은 직접 편집하지 않았다. 비교 패키지는 원래대로 보존했다.
- 생성·포맷·정적 분석 성공, 기존 테스트 64개를 수정 없이 유지하고 추가 6개를 포함해 70개 통과했다. assert 비활성 AOT에서 정상 왕복·교체·목록 방어와 오류 계약 12건을 확인했다.
- 별도 path 소비자에서 코드 생성 없이 의존성 해결·AOT 실행을 확인했고 소비자에게 생성 도구가 전파되지 않았다. 아직 새 커밋이 없어 실제 Git 참조 앱 검증은 하지 않았다.
- docs/freezed-migration.md에 SDK·IntelliJ 안내·명령·의존성·변경·검증 한계를 기록했다. 개발 규칙 문서의 기술 기준은 이번 결정으로 채택하고 AGENTS에 연결했다. 이름·필드·오류 후보는 구체 코드와 비교했으나 rename·별칭은 추가하지 않았다.
- 기존 비교의 현재 모델 유지 추천은 이번 사용자 결정으로 대체한다. 이름의 영구 확정, 빈 원문/빈 줄/개행의 전체 정책, 문자 위치 단위는 계속 미정이다.
- 다음 한 가지 작업은 도형·영역·제작 조건의 첫 지원 단면과 영역 ID 대응을 설계하는 것이다. 새 도안·저장 흐름·그룹·엔진·UI는 구현하지 않았다.

## 초기 네이밍·JSON 정리 (2026-10-20)

- 시작 HEAD b7ee76a, 작업 트리·스테이징 없음. 요청한 현재 이름을 공개 export·구현·테스트·AOT·문서에 적용했다. 구형 지원·별칭·마이그레이션은 없다.
- LineBreakInput / AutomaticLineBreak / SpecifiedLineBreak, TextInputValidationException.code/fieldPath를 사용한다. JSON mode는 automatic/specified이며 auto/manual은 거부한다. 변경한 오류 코드는 [현재 정리 기록](input-naming-json.md)을 따른다.
- 루트 JSON 사전 검사에서 줄 입력 중복 생성을 제거했다. 구조/타입 검사와 생성자의 업무 검증을 나눴으며 복수 오류 순서 보존 테스트를 단일 원인 검사로 정리했다.
- 전용 Dart 3.13.5로 pub get·생성·포맷·분석 성공, 테스트 74개 통과. assert 비활성 AOT 오류 14건 및 정상 문자열 왕복·목록/반환 JSON 보호 확인. 별도 path 소비자도 생성 없이 같은 AOT 검사 통과. 생성 파일 재생성 해시 일치.
- 최초 분석은 이전 임시 소비자의 옛 API 참조로 실패했다. 소비자 코드를 새 공개 API로 갱신한 뒤 재분석 성공. 과거 비교 패키지는 당시 사실 보존을 위해 수정·재실행하지 않았다.
- 의존성·SDK 제약 변경 없음. 문서와 필요한 코드만 수정했으며 스테이징·커밋·푸시하지 않는다. 앱·도안·배치·저장 흐름·UI는 변경하지 않았다.
- 다음 한 가지 작업은 도형·영역·제작 조건의 첫 지원 단면과 영역 ID 대응을 설계하는 것이다. 빈 원문·빈 줄·CR/LF의 전체 제품 정책과 문자 위치 단위는 여전히 보류한다.
