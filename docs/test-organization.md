# 테스트 배치와 계약 검증

제품 참조 구성 후속 구현의 테스트는 test/design의 적용 형상/출처와 test/product의 입력/구성/오류 파일에 추가했다. 기존 배치와 과거 327개 실행 기록은 유지한다. [현재 제품 구성 검증](product-design-configuration.md)을 참고한다.

2026-10-26. 공개 동작을 기준으로 기존 5개 파일을 아래 18개 실행 파일로 재구성했다. lib·JSON·SDK·의존성·기하 알고리즘은 변경하지 않는다.

## 파일 구성

모든 경로는 test/ 기준이다. 테스트는 패키지 공개 진입점만 가져온다.

| 책임 | 파일 | 검증 계약 |
|---|---|---|
| geometry | point_coordinate_space_test.dart | 점 좌표·문맥 JSON·유한 수치·동일 단위 정밀도·환산 실패 |
| geometry | path_segment_test.dart | 선분/원호 태그·bulge·구간 JSON·수정 검증 |
| geometry | geometry_path_test.dart | 시작점과 구간 연결·퇴화·빈 경로·환산 후 퇴화 |
| geometry | closed_boundary_test.dart | 선분 다각형·장공·원·명시적 닫힘·수치 검증의 한계 |
| geometry | arc_representation_test.dart | 극소/대형 bulge·회전 방향·반원 초과·원호 위/밖 극점 |
| geometry | drawing_geometry_test.dart | 전체 단위 환산·원본과 목록/JSON 불변성 |
| geometry | geometry_diagnostics_test.dart | 코드 설명·기대/실제 타입·반지름/원/원호 극점 진단·중첩 경로 |
| design | cutout_definition_test.dart | 관통 ID 생성/수정·필수 JSON 구조 |
| design | text_area_definition_test.dart | 영역 ID·빈/중복 label·공백/Unicode 보존·JSON |
| design | text_region_test.dart | 외부/제외 경계 JSON·제외 목록 수정과 방어 복사 |
| design | design_geometry_test.dart | 비정형 외곽/복수 형상 구멍·영역 역할·소유 ID·전체 환산·불변성 |
| design | text_area_input_validation_test.dart | 정확한 ID 대응·순서 보존·중복/미정의/누락·빈 연결 |
| design | design_diagnostics_test.dart | 업무 오류 상세·타입·중첩 경로·기하 원인 보존 |
| text | text_area_input_test.dart | 원문 공백/기호/Unicode·자동/지정 한 줄/여러 줄·반복 원문의 순서 |
| text | text_input_json_test.dart | 고정 JSON 구조·필수 필드·타입·알 수 없는 필드/방식 |
| text | text_input_validation_test.dart | 빈 ID/원문/지정 목록/줄·CR/LF·원문과 줄 불일치 |
| text | text_input_modification_test.dart | 원문/지정 줄 동시·부분·중첩 수정·기존 값/목록/JSON 보호 |
| text | line_break_input_test.dart | 단독 줄 입력 복원·명시적 방식 전환·지정 줄 수정 검증 |

support/geometry_builders.dart는 문맥을 따르는 점·선분 경로와 inch 묶음, support/design_builders.dart는 inch 비정형 도안·역할 조립, support/text_input_examples.dart는 입력 JSON·입력 오류 matcher를 준비한다. 한 파일에서만 쓰는 원호 방향 좌표 준비는 arc_representation_test.dart 안에 둔다. 기대 결과를 제품 알고리즘으로 다시 계산하지 않는다. 수치·문자열·기대 경로는 테스트 본문에 남긴다.

## 기존 사례 대응표

기존 파일은 모두 test/ 바로 아래에 있었다. 아래 목적지의 파일명은 위 표와 대응한다. 삭제한 파일을 유지하는 호환 실행 파일은 만들지 않는다.

| 기존 파일/사례 | 이동·분리 목적지 |
|---|---|
| geometry_test: 직사각/비정형 닫힌 경계·독립 원·장공·자기 교차/영면적 | closed_boundary |
| geometry_test: 원호 bulge의 양방향/반원 초과/크기 | arc_representation |
| geometry_test: 퇴화 구간·시작점/구간 수정·빈 경로·퇴화 JSON | geometry_path |
| geometry_test: 열린 경계 생성/수정/복원 | closed_boundary |
| geometry_test: isClosed 자동 보정 금지 | geometry_path |
| geometry_test: 전체 단위 환산·목록/반환 JSON 방어 | drawing_geometry |
| geometry_test: 동일 단위 정밀도·점 환산 언더플로 | point_coordinate_space |
| geometry_test: 중심 중첩 수정·0/음수 반지름 | closed_boundary |
| geometry_test: 0 bulge 수정/JSON 거부 | path_segment |
| geometry_test: NaN/양·음 Infinity | 점·구간·원 필드별 해당 파일에 분리 |
| geometry_test: 파생 반지름 진단·중첩 원호 반지름 오류 | geometry_diagnostics |
| geometry_test: 환산 후 구간 퇴화·묶음 환산 오버플로·원 극점 | geometry_path / drawing_geometry / closed_boundary |
| geometry_test: 6개 파서의 필수/null/루트 타입/추가 필드 | 각 대상 파일에 필드·오류 조건별 등록 |
| geometry_test: 미지원 태그·pixel 단위 | path_segment / closed_boundary / point_coordinate_space |
| geometry_numeric_regression: 극소 bulge·4방향/양회전·짧은/긴/반원 원호·반지름/중심 오버플로 | arc_representation, 각 회전·방향·오류 연산을 별도 사례로 등록 |
| geometry_numeric_regression: 코드 설명·타입 6종·원 극점·중첩 원호 진단 | geometry_diagnostics, 코드·타입별 사례로 분리 |
| design_geometry: 비정형 도안/세 형상 구멍·겹침 표현·전체 환산·목록/JSON 방어 | design_geometry |
| design_geometry: 빈/중복 label·공백 ID·Unicode | text_area_definition, label별 별도 등록 |
| design_geometry: 소유 ID 중복 | design_geometry, 구멍/영역 × 생성/수정/복원을 각각 등록 |
| design_geometry: 빈 ID | cutout_definition / text_area_definition, 중첩 영역 JSON은 design_geometry |
| design_geometry: 공백 ID 연결·입력 순서·지정 한 줄·세 진단·영역/입력 0건 | text_area_input_validation |
| design_geometry: 4개 모델 JSON 필수/추가/객체 타입 | 각 모델 파일 |
| design_geometry: 업무 상세·목록 타입·중첩 label/exclusions/기하 오류 | design_diagnostics |
| design_geometry: 제외 목록 중첩 수정 방어 | 집계 도안 불변성은 design_geometry에 유지하고 TextRegion 직접 수정 책임은 text_region에서 확인 |
| text_area_input: 원문 8종 × 3가지 줄 방식·유사 Unicode·동일 원문의 방식 구분·반복 문자열 순서 | text_area_input, 각 원문/방식을 독립 등록 |
| text_area_input: 입력/공개/JSON 목록 보호·유효한 값 교체 | text_input_modification |
| text_area_input: 필수/타입/모르는 방식/줄 구조·추가 필드 | text_input_json, 서로 다른 추가 필드 위치도 독립 등록 |
| text_area_input: 빈 ID/원문/목록/줄·CR/LF·불일치 줄 목록 | text_input_validation, 생성/복원·필드·개행별 등록 |
| freezed_text_area_input: JSON 문자열 자동/지정 한 줄 | text_input_json, 방식별 고정 구조 비교로 전환 |
| freezed_text_area_input: 단독 줄 복원·방식 전환·지정 줄 수정/방어 복사 | line_break_input |
| freezed_text_area_input: 동시/부분/중첩 수정·ID/원문 수정 오류 | text_input_modification, 잘못된 수정 조건별 분리 |
| freezed_text_area_input: 지정 줄 수정의 빈 목록/빈 줄/CR 오류 | line_break_input |
| freezed_text_area_input: 지정 방식 루트 추가 필드 | text_input_json (기존 자동 방식 루트 추가 필드와 서로 다른 분기) |

동일한 생성 경로/오류인 빈 원문·빈 areaId 입력 검사를 각각 기존 text_area_input의 검사로 통합했다. 이들은 design_geometry의 입력 연결 사례에 섞여 있었으므로 입력 값 검증 책임으로 모았다. 동작 범위를 제거하지 않았다. 생성·수정·중첩 수정·JSON 복원은 별도 진입 경로이므로 같은 오류라도 통합하지 않는다. 도안 전체 소유권 방어와 하위 영역 직접 수정은 책임이 달라 둘 다 유지한다.

## 약한 검증 보완

- 모든 구간에 start가 없는지 every(!containsKey('start'))로 확인한다. 일부 구간에만 start가 있어도 실패한다.
- JSON 문자열 키 순서는 계약이 아니므로 고정된 기대 Map과 toJson 및 decode(encode(...))를 비교한다. 입력 문자열은 다른 키 순서로 작성한다. 원문 보존 사례도 전체 기대 필드 구조를 별도로 검사하므로 왕복 양쪽이 같은 오류를 내는 것만으로 통과하지 않는다.
- 연결 진단 순서는 계약이 아니다. unorderedEquals로 코드 집합/개수를 확인하고 코드별 singleWhere로 경로·ID·중복 위치를 검사한다.
- 필드·오류 종류·생성/수정/복원·원호 회전 방향을 등록 시점의 독립 테스트로 드러낸다. 같은 계약의 진단·원본 불변성은 한 테스트에서 함께 확인한다.

## 실행 기준

프로젝트 전용 Dart로 format test, analyze, test를 실행하고 모든 *_test.dart를 각각 단독 실행한다. 운영 코드가 그대로여서 코드 생성·AOT·소비자 재검증은 이번 작업에서 반복하지 않는다. 이 기록은 값/참조 계약 시험이며 배치·제작 시험이 아니다.

## 실제 실행 결과 (2026-10-26)

- 프로젝트 전용 Flutter 3.47.7 포함 Dart 3.13.5로 pub get·format test·analyze 통과.
- 최종 전체 테스트 327개 통과. 기존 153개를 개수 목표로 유지한 것이 아니라 필드/오류/수정 경로/원문 방식/회전 방향의 독립 등록을 드러낸 결과다.
- 실행 파일 18개 모두 단독 실행 통과. 마지막 정리 후 변경된 원호 파일과 입력 연결 파일도 다시 단독 실행했다. 테스트 파일 이동 자체를 확인하는 형식 테스트는 추가하지 않았다.
- 초기 재배치 과정의 import/지역 변수 범위·테스트 구문 오류는 수정한 뒤 최종 분석/실행을 통과했다. 운영 코드 결함은 발견하지 않았다.
- lib(생성 파일 포함)·pubspec.yaml·build.yaml·SDK·기하 알고리즘·형제 앱 변경 없음. 시작 작업 트리/인덱스는 깨끗했고 스테이징·커밋·푸시는 하지 않았다.
- 코드 생성·AOT·생성 없는 소비자 검증은 운영 코드/생성 입력이 그대로이므로 이번에 실행하지 않았다.

명령은 프로젝트 루트에서 실행한다.

~~~powershell
$workflowDart = "$PWD/.toolchains/flutter-3.47.7/bin/cache/dart-sdk/bin/dart.exe"
& $workflowDart pub get
& $workflowDart format test
& $workflowDart analyze
& $workflowDart test --reporter expanded
Get-ChildItem test -Recurse -Filter '*_test.dart' | ForEach-Object {
  & $workflowDart test $_.FullName --reporter expanded
  if ($LASTEXITCODE -ne 0) { throw "단독 실행 실패: $($_.FullName)" }
}
~~~

## 제품 도안 변경 준비 테스트 추가 (2026-10-28)

기존 사례를 이동/삭제하지 않고 새 책임에 다음 파일을 추가했다.
- test/product/product_geometry_change_request_test.dart: 불변 요청·방어 복사·미완료 식별자.
- test/product/product_geometry_change_preparation_test.dart: 명시 대상·공유·ID 내용·전체 준비 결과·요약.
- test/product/text_area_input_change_preparation_test.dart: 실제 준비 내부 입력 투영의 원문/줄/순서·영역 선택 검증.
- test/product/product_geometry_change_errors_test.dart: 전용 진단의 필수 상세·잘못된 조합·위치·방어.
비공개 후보를 테스트용 공개 getter로 노출하지 않는다. 공통 준비는 support/product_geometry_changes.dart에 한정한다.