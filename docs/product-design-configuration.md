# 제품 입력과 적용 형상 참조 구성 — 구현 계약

2026-10-26. 현재 공개 API와 실제 검증 기록이다. [참조·변경 설계](product-design-binding.md)의 값·현재 참조 부분만 구현했다. 완전한 AppliedDesign/WorkDocument·제작 조건·수량·결과·확인·저장 상태는 아니다.

## 공개 API와 소유권

| API | 보장하는 조건 |
|---|---|
| DesignSourceReference(sourceDesignId:, sourceRevision:) | 공용 원본의 출처 기록. 내용을 재조회하지 않음 |
| AppliedDesignGeometry(appliedGeometryId:, geometry:, source:) | 실제 DesignGeometry와 선택 출처를 가진 불변 적용 형상. 단위는 geometry가 소유 |
| ProductInput(productId:, appliedGeometryId:, textInputs:) | 제품별 ID·참조 문자열·불변 영역 입력 목록. 원문·방식·순서 보존 |
| ProductDesignConfiguration(appliedGeometries:, products:) | 현재 소유 ID·참조·제품별 영역 대응이 유효한 구성만 생성 |
| validateProductDesignConfiguration(appliedGeometries:, products:) | 유효한 구성 객체 없이 원시 목록을 대조하고 수정 불가 List<ProductDesignIssue> 반환 |

모든 ID는 호출자가 명시하며 빈 문자열을 거부한다. 공백만인 문자열을 포함해 trim·Unicode 정규화를 하지 않는다. 이름·문구·좌표·순서로 ID를 발급하지 않는다. 적용 ID와 제품 ID는 별도 이름 공간이다.

출처와 제품 입력은 기존 불변 값과 함께 공유할 수 있다. 값이 같다고 제품/스냅샷을 자동 병합하지 않는다. 이미 불변인 geometry를 불필요하게 깊은 복제하지 않는다. 모든 소유 목록은 방어 복사하며 반환 JSON은 새 Map/목록으로 구성한다.

AppliedDesignGeometry는 생성기의 copyWith를 끄고 일반 내용 교체·중첩 수정 경로를 제공하지 않는다. 파생 API도 아직 없다. DesignSourceReference와 ProductInput의 생성 copyWith는 실제 생성자를 다시 호출한다. ProductInput.copyWith는 외부 참조를 검증하지 않으며 결과를 구성에 반영할 때 구성 검증이 필요하다.

## 선택 출처와 버전의 JSON 정책

- source 생략 또는 명시적 null은 기록 없음이다. 출력에서는 source 필드를 생략한다.
- source가 있다면 객체여야 하고 sourceDesignId는 필수 문자열이다. 빈 값은 emptySourceDesignId, 누락/null·다른 타입은 missingField/invalidType으로 구분한다.
- sourceRevision 생략/null은 버전 기록 없음이며 출력에서는 생략한다.
- 지정한 sourceRevision은 빈 문자열만 거부한다(emptySourceRevision). 공백·기호·Unicode·대소문자·알 수 없는 버전 표현을 그대로 보존하는 불투명 문자열이다. SemVer·최신성·실제 공용 원본 존재는 검사하지 않는다.
- 버전을 모를 때 latest나 임의 값으로 채우지 않는다. 호출자가 명시적으로 "latest"라는 문자열을 주면 그대로 기록할 뿐 최신 버전으로 해석하지 않는다.
- 모르는 JSON 필드는 unexpectedField로 거부한다. 필수 목록을 누락하면 빈 목록으로 보정하지 않는다.

출처 없음은 출처 기록 부재일 뿐 반드시 로컬에서 새로 작성했다는 증명이 아니다. 기록된 버전은 수정 출발점이며 파생 내용과 원본의 동일성 인증이 아니다.

## 구성의 생성과 오류 수집

ProductInput은 빈 ID·하위 문구 값·불변 목록만 검사한다. **입력 areaId 중복은 구성의 책임**으로 두었다. 중복 입력을 단독 제품 생성에서 먼저 거부하면 다른 제품의 독립 오류를 함께 진단하지 못하므로 구성 전까지 목록을 보존한다. 단독 ProductInput을 완전한 참조 구성이라고 설명하지 않는다.

구성 생성자는 목록을 방어 복사한 다음 validateProductDesignConfiguration을 호출하는 준비 함수를 먼저 실행한다. 오류가 없을 때만 private 생성자로 들어간다. 생성된 copyWith와 JSON 복원도 공개 생성자를 통과한다. 검증 없이 외부에 노출할 수 있는 private 생성자 우회 경로는 없다.

검사 순서는 반환 계약이 아니며 다음 독립 원인을 수집한다.

1. 적용 목록의 같은 ID 중복(같은 내용도 거부).
2. 제품 ID 중복.
3. 없는 적용 참조 또는 중복 선언으로 모호한 적용 참조.
4. 제품별 중복 입력, 정의 없는 입력, 정의 대비 입력 누락.

적용 ID마다 선언 위치 목록을 보존하므로 last-wins를 하지 않는다. 참조가 정확히 하나면 기존 validateTextAreaInputs를 호출해 원래 영역 issue를 유지한다. 참조가 없거나 모호하면 영역 대조를 생략하고 참조와 무관한 입력 중복만 검사한다. 가짜 도안·빈 영역으로 대조하지 않으며 다른 제품의 검사도 중단하지 않는다. 유일한 참조에서는 별도 중복 검사를 추가하지 않아 같은 입력 중복을 두 번 보고하지 않는다.

미사용 스냅샷·빈 목록은 허용한다. 영역이 없는 형상을 참조하는 제품은 빈 입력 목록으로 구성할 수 있다. 이것은 빈 작업 파일 저장이나 배치 완료 허용이 아니다.

## 오류 타입과 하위 원인

ProductDesignErrorCode와 ProductDesignIssue, ProductDesignValidationException은 전용 파일에 있다. 기존 GeometryErrorCode/TextInputErrorCode를 변경하지 않았다.

| 코드 | 발생 조건·진단 |
|---|---|
| missingField / invalidType / unexpectedField | JSON 필수 누락·기대/실제 타입·모르는 필드. 타입은 ProductDesignTypeDetails |
| emptyProductId / emptyAppliedGeometryId | 빈 제품/적용 ID와 해당 경로 |
| emptySourceDesignId / emptySourceRevision | 빈 원본 ID/지정 버전. 기록 없음과 구분 |
| duplicateAppliedGeometryId / duplicateProductId | ProductDesignDuplicateDetails에 원래 ID·0 기반 첫/중복 위치 |
| unknownAppliedGeometryId / ambiguousAppliedGeometryId | ProductDesignReferenceDetails에 제품/적용 ID·일치 선언 위치 목록 |
| textAreaInputMismatch | ProductDesignAreaDetails에 productId·appliedGeometryId·원래 DesignValidationIssue |

단독 값의 실패는 issue 하나를 가진 ProductDesignValidationException, 구성 실패는 수집한 전체 issue를 가진 같은 예외다. 반환/예외 issue 목록과 상세의 선언 위치 목록 모두 수정 불가다. 원인 코드를 찾을 때 출력 문자열을 파싱하지 않는다.

하위 영역 cause의 code·fieldPath·details는 그대로 유지한다. 입력 문제는 products[i].textInputs[j].areaId, 누락은 적용 형상의 실제 정의 위치인 appliedGeometries[k].geometry.textAreas[j].areaId를 상위 경로로 제공한다. 제품 ID도 함께 제공하여 같은 정의를 공유하는 여러 제품의 누락을 구분한다.

중첩 JSON의 GeometryValidationException / DesignValidationException / TextInputValidationException은 ProductDesignNestedException의 cause에 원래 예외 객체를 둔다. fieldPath는 최상위 위치이며 cause의 원래 경로·기하 diagnostic·업무 코드/상세를 보존한다. 새 제품 값 예외는 원래 상세 객체를 유지하며 상위 경로를 연결한다. 구조가 잘못되어 하위 값 자체를 만들 수 없는 경우는 구성의 참조 issue 수집과 구분해 즉시 거부한다.

assert 비활성 AOT에서 실제 출력한 독립 오류 중 일부:

~~~text
textAreaInputMismatch, fieldPath=products[0].textInputs[1].areaId, 설명=제품 입력이 적용 형상의 영역 정의와 대응하지 않습니다., productId=broken, appliedGeometryId=g, cause=(duplicateInputAreaId, fieldPath=inputs[1].areaId, 설명=입력 목록의 영역 ID가 중복됩니다., id="a", firstIndex=0, duplicateIndex=1)
textAreaInputMismatch, fieldPath=appliedGeometries[0].geometry.textAreas[1].areaId, 설명=제품 입력이 적용 형상의 영역 정의와 대응하지 않습니다., productId=broken, appliedGeometryId=g, cause=(missingAreaInput, fieldPath=textAreas[1].areaId, 설명=도안 영역에 대응하는 입력이 없습니다., id="b")
unknownAppliedGeometryId, fieldPath=products[1].appliedGeometryId, 설명=제품이 참조하는 적용 형상이 없습니다., productId=missing, appliedGeometryId=not-found, matchingIndices=[]
~~~

같은 실행에서는 위 원인 외에 unknownInputAreaId도 함께 수집했다. 목록 순서를 영구 계약으로 요구하는 예시는 아니다.

## 실제 JSON 조각

공용 원본을 읽지 않아도 실제 형상·영역을 해석할 수 있다. 아래는 고정된 기대 구조를 검사하는 제품 참조 구성 조각이며 전체 작업 파일이나 제작 결과가 아니다.

~~~json
{
  "appliedGeometries":[
    {
      "appliedGeometryId":"g",
      "geometry":{
        "coordinateSpace":{"lengthUnit":"millimeter"},
        "outline":{"kind":"circle","center":{"x":0,"y":0},"radius":30},
        "cutouts":[],
        "textAreas":[
          {"areaId":"title","label":"","region":{
            "outer":{"kind":"circle","center":{"x":0,"y":0},"radius":10},
            "exclusions":[]
          }}
        ]
      }
    }
  ],
  "products":[
    {"productId":"p-a","appliedGeometryId":"g","textInputs":[
      {"areaId":"title","sourceText":" PUMP  A ","lineBreak":{"mode":"specified","lines":[" PUMP  A "]}}
    ]},
    {"productId":"p-b","appliedGeometryId":"g","textInputs":[
      {"areaId":"title","sourceText":"VALVE B","lineBreak":{"mode":"automatic"}}
    ]}
  ]
}
~~~

선택 출처를 기록한다면 적용 스냅샷에 source: {"sourceDesignId":"catalog-42","sourceRevision":"r7"}를 추가한다. 제품은 sourceDesignId로 참조하지 않는다.

## 파일 구성

~~~text
lib/src/design/applied_design_geometry.dart
lib/src/design/design_source_reference.dart
lib/src/product/product_input.dart
lib/src/product/product_design_configuration.dart
lib/src/product/product_design_validation.dart
lib/src/product/product_design_errors.dart
lib/src/product/product_json.dart
~~~

각 값 모델의 .freezed.dart/.g.dart 8개를 생성해 Git 관리 대상으로 둔다. JSON 필드 변환·비교·제공하는 copyWith는 생성기를 활용하고, 제품 JSON 경계에서 실제로 공유하는 검사만 product_json.dart에 둔다. 내부 함수는 공개 진입점에 export하지 않는다. 불필요한 공통 모듈·의존성을 추가하지 않았다.

테스트는 test/design/applied_design_geometry_test.dart, design_source_reference_test.dart와 test/product/product_input_test.dart, product_design_configuration_test.dart, product_design_errors_test.dart다. 반복 준비는 test/support/product_examples.dart, assert 비활성 검사는 tool/verify_product_configuration_release.dart에 있다. 기존 테스트를 재배치하지 않았다.

## 실제 검증과 환경 기록

프로젝트 전용 .toolchains/flutter-3.47.7의 Dart 3.13.5 stable을 사용했다. 선언된 Freezed 4.0.3·json_serializable 6.14.1·build_runner 2.16.2와 annotation 제약은 유지했다. pubspec.yaml·SDK·전역 PATH·공유 패키지 캐시 내용은 수정하지 않았다.

첫 pub get의 로컬 해결 결과에서 source_helper 1.4.0과 json_serializable 6.14.1의 동일 확장/함수 이름 충돌로 생성기 AOT 컴파일이 실패했다. 이 실패를 코드 생성 성공으로 기록하지 않는다. 선언 의존성·dependency_overrides 변경 없이, 캐시에 있던 호환 버전을 선택하는 다음 명령으로 무시 대상 로컬 lock만 복구했다.

~~~powershell
$workflowDart = "$PWD/.toolchains/flutter-3.47.7/bin/cache/dart-sdk/bin/dart.exe"
& $workflowDart pub get
& $workflowDart pub downgrade source_helper --offline
& $workflowDart run build_runner build
& $workflowDart format lib test tool/verify_product_configuration_release.dart
& $workflowDart analyze
& $workflowDart test --reporter expanded
~~~

최종 해결은 source_helper 1.3.13 / analyzer 14.6.0이다. source_helper 1.4.0을 새로 선택하는 깨끗한 개발 환경에서는 같은 생성기 충돌을 다시 만날 수 있다. 이 프로젝트의 라이브러리 lock은 Git 관리에서 제외하므로 이번 생성 명령과 해결 버전을 함께 기록한다. offline 명령은 해당 버전이 로컬 캐시에 있을 때 수행한 실제 명령이다. 제약 추가나 도구 업그레이드는 사용자 범위 밖이므로 이번에 하지 않았다. 소비자에는 생성기가 전파되지 않는다.

최종 확인:

- 코드 생성·포맷·정적 분석 통과.
- 전체 417개(기존 327 + 새 90) 테스트 통과. 새 파일 5개 단독 실행 통과.
- assert 비활성 AOT에서 정상 공유·원문/지정 한 줄·순서·왕복·목록/JSON 방어·복수 진단, 잘못된 값/구성/중첩 원문 복원 10건 거부 확인.
- 최종 생성 소스 30개를 다시 생성·포맷해 추가 차이가 없는지 확인.
- 별도 build/product_consumer의 path 소비자에서 코드 생성 없이 pub get·AOT 컴파일·실행 통과. 소비자 그래프에 Freezed/json_serializable/build_runner가 없음을 확인했다.
- 소비자의 잘못된 snapshot.copyWith 호출을 정적 분석으로 UNDEFINED_METHOD 거부하는 예상 실패 확인. 실행 시험에서도 같은 API 비노출을 확인했다.
- 초기 테스트의 빈 Map 타입 기대와 AOT 검사 스타일 lint는 고친 후 전체 분석·테스트를 재확인했다.

실제 Git 참조 Flutter 앱·UI·제작 장비는 검사하지 않았다. 기존 기하·입력 AOT 파일은 이번에 반복하지 않았으며 기존 Dart 테스트는 전체 실행했다. 새 소비자·lock·SDK·캐시·빌드 결과는 무시 대상이다.

## 보장하지 않는 것과 다음 한 가지 작업

구성 생성·복원은 **현재 상태의 참조**를 보장한다. 같은 ID의 다른 geometry/source를 새로 직접 생성하는 행위나 이전/새 구성 간 내용 충돌까지 판별하지 않는다. 구성 copyWith 역시 현재 참조를 검증하는 값 수정 API이며 안전한 업무 도안 교체 명령이 아니다.

다음 한 가지 작업은 이전/새 적용 ID 내용 비교와 명시 영역 대응을 요구하는 변경 준비·원자적 반영 계약을 구현 가능한 크기로 구체화하는 것이다. 그때 같은 areaId의 의미 연속성과 이전 원문 미처리, 명시 대상 제품 집합을 다룬다.

공용 등록·동기화, 제작 조건, 수량, 영역 대응 변경 명령, 결과 무효화, 배치/제작/저장 판정·파일 저장·UI·엔진·DXF는 이번에 구현하지 않았다.

최종 문서 검사: JSON 관계와 수정 문서의 상대 링크 67개 대상 존재 확인, git diff --check 통과. 새 생성 소스 8개는 Git 무시 대상이 아니며 스테이징은 시작과 같은 빈 상태다. 기존 기하/문구·영역 검증 구현과 기존 테스트, 의존성 선언·형제 앱을 보존했다. 커밋·푸시는 하지 않았다.
