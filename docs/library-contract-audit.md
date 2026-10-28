# 라이브러리 개발 계약 감사

현재 확인일: 2026-10-27. 공개 진입점·실제 구현·테스트를 대조했다.
이 문서는 현재 보장과 미구현 범위를 구분한다. 과거 141건은 아래 접힌 초기 목록에 보존한다.

## 공개 설명 감사 결과

설명 보완 전에 public_member_api_docs를 켜고 machine 형식으로 재측정한 결과는 **141건**으로 초기 감사와 일치했다.
이 수치는 소비자용 공개 export만 세는 것이 아니라 Dart library 사이의 비공개 진입점 도우미도 포함했다.

| 현재 책임                  | 보완 전 누락 | 외부 export API | 내부 도우미 | 보완 후 |
|----------------------------|-------------:|----------------:|------------:|--------:|
| 도안 구성·영역·출처·진단   |           30 |              23 |           7 |       0 |
| 기하 값·단위·경로·진단     |           54 |              45 |           9 |       0 |
| 제품 값·참조·진단          |           35 |              28 |           7 |       0 |
| 영역 원문·줄바꿈·문구 오류 |           22 |              22 |           0 |       0 |
| 합계                       |          141 |             118 |          23 |       0 |

내부 23건은 design_json의 7개, geometry_json의 6개, product_json의 7개,
점 읽기/쓰기의 2개와 단위 환산 도우미 1개다. 이들은 library privacy 때문에 이름이 공개지만
패키지 진입점에서 export하지 않는다. 내부 용도·호출자 검증 책임을 설명했고 소비자 API로 승격하거나 이름을 바꾸지 않았다.
기존 문서가 있던 공개 검증 함수도 인덱스/경로 기준을 재검토해 보완했다.

생성자·필드·복원·변환 설명은 단위/ID 소유 범위/불변식/실패 조건과 검사하지 않는 책임을 다룬다.
상세 규약은 각 타입에 모으고 멤버가 수행하는 조건만 보완했다.
public_member_api_docs를 계속 활성화했으며 생성 소스 제외를 유지했다. 새 광범위 ignore는 없다.
test/geometry/arc_representation_test.dart의 위치 인자 ignore는 회전/역전 회귀 행렬의 호출 순서 보존에
필요한 테스트 전용 예외이므로 바로 위에 근거를 적었다. document_ignores 안내도 해소했다.

## 실제 계약과 남은 책임

| 계약        | 실제 보장·설명                                                            | 현재 보장하지 않는 것                            |
|-------------|---------------------------------------------------------------------------|--------------------------------------------------|
| 공개 진입점 | lib/r_edit_workflow.dart의 기존 export 이름 유지                          | 내부 src 직접 import의 호환성                    |
| 원문·줄바꿈 | 공백/Unicode 보존, automatic/specified 구분, 한 줄 specified, 일관된 교체 | 빈 원문/빈 줄/CRLF의 제품 전체 정책, 문자 오프셋 |
| 최소 기하   | 문맥 단위·유한 값·원호 파생/실제 극점·전체 단위 환산                      | 포함/간섭/자기 교차/면적/제작 공차               |
| 도안·입력   | 소유 ID, 외곽/관통/텍스트 역할, areaId 대응                               | 자동 홀 제외·자동 배치·제작 판정                 |
| 제품 참조   | 별도 ID 이름 공간, 독립 issue, 모호한 참조 생략, 하위 원인 보존           | 안전한 변경 명령·이력 추적     |
| 스냅샷      | 일반 내용 교체 copyWith 없음, 불변 값/목록 공유                           | 역사적 ID 불변성을 단독 생성자로 보장            |
| JSON        | 기존 구조·필수/선택/null/추가 키·원문 보존                                | 전체 WorkDocument 저장 스키마·파일 I/O           |
| 오류 출력   | 개발자 설명·코드·상대/상위 경로·원래 진단                                 | 사용자 화면 확정 문구·다국어·로깅 체계           |
| 생성·소비자 | 시작 상태/첫 생성 일치·반복 안정성, 생성기 없는 소비자                    | 원격 Git fetch/호스팅 배포                       |

문서 lint 누락은 현재 0건이다. 이것이 업무 기능·배치·저장·제작 계약의 완성을 뜻하지 않는다.
위 미구현 업무 책임은 추가하지 않았다. 오류 상세/스택의 공개 API 변경은 아래 현행 계약을 따른다.

## 문구 오류 파일과 개발자 진단

TextInputErrorCode와 TextInputValidationException을 lib/src/text_input_errors.dart에 분리했다.
모델은 기존 lib/src/text_area_input.dart에 둔다. 소비자는 여전히 공개 진입점에서 같은 이름을 import한다.
기존 코드/fieldPath와 JSON·값 검증 조건은 유지한다. 예외 생성자의 필수 상세/런타임 조합 검사는 2026-10-27에 보완했다.
TextInputDetails의 타입·방식·문자 위치·길이 상세와 description을 제공한다. 원문은 보관하지 않는다.
입력 원문을 덤프하거나 임의 Map 상세를 만들지 않았다.

예를 들어 areaId의 JSON 값이 숫자라면 다음처럼 출력한다.

~~~text
TextInputValidationException(code=invalidType, fieldPath=areaId, 설명=문구 입력의 JSON 값 타입이 기대 타입과 다릅니다., details=expectedType=String, actualType=int)
~~~

TextAreaInput 객체 자체의 타입 오류 경로는 $다. LineBreakInput 단독 복원도 lineBreak 접두 경로를 사용한다.
지정 줄 인덱스는 0 기반 목록 위치이며 문자 위치가 아니다.
제품 중첩 복원은 상위 textInputs[0].lineBreak.lines와 원래 cause의 lineBreak.lines를 함께 제공한다.
cause는 새 코드로 덮어쓰지 않고 같은 예외 객체로 보존한다.

기하·도안·제품의 모든 기존 오류 코드를 발생 지점과 대조했다.
기하 수학 오류/파생 표현 불가/소비자 미지원은 구분한다. numericRepresentationFailure는
환산의 0 소실뿐 아니라 정밀도 소실로 구간 끝점이 같아진 경우도 포함함을 주석에 명시했다.
설명만 보완했으며 코드·기하 알고리즘·진단 payload를 변경하지 않았다.
기존 기하/도안/제품의 타입·중첩 경로·진단 객체 보존 테스트를 유지했고,
문구 개발자 출력 2개와 기존 제품 중첩 사례의 원인/설명/객체 보존 검사를 추가했다.

## 실제 실행과 미실행

프로젝트 FVM Dart 3.13.5에서 명시적 build_runner 재생성 후 전체 tool/verify.dart를 실행했다.

- 포맷·정적 분석: No issues found. public_member_api_docs·document_ignores 포함.
- 테스트: 전체 431개 통과. 새 진단 파일 2개 사례와 기존 제품 입력 회귀를 확인했다.
- 생성: 검증 시작 상태/첫 생성 일치와 반복 생성 안정성 통과. 생성 소스는 재생성했고 추가 diff는 없었다.
- assert 비활성 AOT: 기존 5개 검사 통과.
- 독립 소비자: 생성기 없이 컴파일·실행 성공.
- 기존 공개 export 이름, 모델/JSON/기하 선언 보존을 읽기 전용 대조했다.
- 문서 상대 링크·git diff --check·기존 인덱스 보존 확인.

SDK·의존성·형제 앱·CI 조건은 바꾸지 않았다. 커밋·푸시·스테이징하지 않았다.
원격 Actions·실제 Linux 러너·원격 Git 의존성 fetch는 실행하지 않았다.
Dartdoc HTML 렌더링은 실행하지 않았으며 API 설명과 lint/분석 확인을 HTML 시각 검증으로 보고하지 않는다.

## 초기 141건의 원본 위치

아래 줄 번호와 선언은 보완 전 감사 기록이며 현재 위치 링크가 아니다.
모든 항목을 현재 코드와 대조해 위 책임별 결과로 정리했다.
문구 오류 14건은 전용 오류 파일로 이동했고 나머지 문구 모델 8건은 기존 모델 파일에 남았다.

<details>
<summary>해결한 초기 진단 141건의 이전 선언 보기</summary>

| 파일:줄                                              | 멤버 선언                                                                        |
|------------------------------------------------------|----------------------------------------------------------------------------------|
| lib/src/design/applied_design_geometry.dart:22       | `AppliedDesignGeometry({`                                                        |
| lib/src/design/applied_design_geometry.dart:44       | `factory AppliedDesignGeometry.fromJson(Object? json) {`                         |
| lib/src/design/applied_design_geometry.dart:55       | `Map<String, Object?> toJson() => _$AppliedDesignGeometryToJson(this);`          |
| lib/src/design/cutout_definition.dart:21             | `CutoutDefinition({required this.cutoutId, required this.boundary}) {`           |
| lib/src/design/cutout_definition.dart:39             | `factory CutoutDefinition.fromJson(Object? json) {`                              |
| lib/src/design/cutout_definition.dart:46             | `Map<String, Object?> toJson() => _$CutoutDefinitionToJson(this);`               |
| lib/src/design/design_errors.dart:55                 | `const DesignIdentifierDetails(this.identifier);`                                |
| lib/src/design/design_errors.dart:65                 | `const DesignDuplicateDetails({`                                                 |
| lib/src/design/design_errors.dart:86                 | `const DesignTypeDetails({`                                                      |
| lib/src/design/design_errors.dart:102                | `const DesignValidationIssue({`                                                  |
| lib/src/design/design_errors.dart:130                | `const DesignValidationException(this.issue);`                                   |
| lib/src/design/design_geometry.dart:24               | `DesignGeometry({`                                                               |
| lib/src/design/design_geometry.dart:85               | `factory DesignGeometry.fromJson(Object? json) {`                                |
| lib/src/design/design_geometry.dart:98               | `Map<String, Object?> toJson() => _$DesignGeometryToJson(this);`                 |
| lib/src/design/design_json.dart:7                    | `Map<String, Object?> readDesignObject(Object? json) {`                          |
| lib/src/design/design_json.dart:23                   | `Object? requireDesignField(Map<String, Object?> object, String key) {`          |
| lib/src/design/design_json.dart:32                   | `void readDesignString(Map<String, Object?> object, String key) {`               |
| lib/src/design/design_json.dart:48                   | `void checkDesignFields(Map<String, Object?> object, Set<String> allowed) {`     |
| lib/src/design/design_json.dart:61                   | `List<Object?> readDesignList(Object? json, String fieldPath) {`                 |
| lib/src/design/design_json.dart:77                   | `ClosedBoundary readBoundary(Object? json, String fieldPath) {`                  |
| lib/src/design/design_json.dart:85                   | `Map<String, Object?> writeBoundary(ClosedBoundary boundary) =>`                 |
| lib/src/design/design_source_reference.dart:19       | `DesignSourceReference({required this.sourceDesignId, this.sourceRevision}) {`   |
| lib/src/design/design_source_reference.dart:41       | `factory DesignSourceReference.fromJson(Object? json) {`                         |
| lib/src/design/design_source_reference.dart:48       | `Map<String, Object?> toJson() => _$DesignSourceReferenceToJson(this);`          |
| lib/src/design/text_area_definition.dart:21          | `TextAreaDefinition({`                                                           |
| lib/src/design/text_area_definition.dart:47          | `factory TextAreaDefinition.fromJson(Object? json) {`                            |
| lib/src/design/text_area_definition.dart:55          | `Map<String, Object?> toJson() => _$TextAreaDefinitionToJson(this);`             |
| lib/src/design/text_region.dart:20                   | `TextRegion({required this.outer, required List<ClosedBoundary> exclusions})`    |
| lib/src/design/text_region.dart:30                   | `factory TextRegion.fromJson(Object? json) {`                                    |
| lib/src/design/text_region.dart:37                   | `Map<String, Object?> toJson() => _$TextRegionToJson(this);`                     |
| lib/src/geometry/closed_boundary.dart:15             | `Map<String, Object?> toJson();`                                                 |
| lib/src/geometry/closed_boundary.dart:16             | `ClosedBoundary converted({required LengthUnit from, required LengthUnit to});`  |
| lib/src/geometry/closed_boundary.dart:53             | `CircleBoundary({required this.center, required this.radius}) {`                 |
| lib/src/geometry/closed_boundary.dart:91             | `final Point2 center;`                                                           |
| lib/src/geometry/closed_boundary.dart:92             | `final double radius;`                                                           |
| lib/src/geometry/closed_boundary.dart:123            | `PathBoundary({required this.path}) {`                                           |
| lib/src/geometry/closed_boundary.dart:142            | `final GeometryPath path;`                                                       |
| lib/src/geometry/coordinate_space.dart:9             | `enum LengthUnit { millimeter, inch }`                                           |
| lib/src/geometry/coordinate_space.dart:9             | `enum LengthUnit { millimeter, inch }`                                           |
| lib/src/geometry/coordinate_space.dart:22            | `DrawingCoordinateSpace({required this.lengthUnit});`                            |
| lib/src/geometry/coordinate_space.dart:23            | `final LengthUnit lengthUnit;`                                                   |
| lib/src/geometry/coordinate_space.dart:24            | `factory DrawingCoordinateSpace.fromJson(Object? json) {`                        |
| lib/src/geometry/coordinate_space.dart:40            | `Map<String, Object?> toJson() => _$DrawingCoordinateSpaceToJson(this);`         |
| lib/src/geometry/coordinate_space.dart:44            | `double convertGeometryLength(`                                                  |
| lib/src/geometry/drawing_geometry.dart:23            | `DrawingGeometry({`                                                              |
| lib/src/geometry/drawing_geometry.dart:30            | `final DrawingCoordinateSpace coordinateSpace;`                                  |
| lib/src/geometry/drawing_geometry.dart:32            | `final List<GeometryPath> paths;`                                                |
| lib/src/geometry/drawing_geometry.dart:34            | `final List<ClosedBoundary> boundaries;`                                         |
| lib/src/geometry/drawing_geometry.dart:35            | `factory DrawingGeometry.fromJson(Object? json) {`                               |
| lib/src/geometry/drawing_geometry.dart:47            | `Map<String, Object?> toJson() => _$DrawingGeometryToJson(this);`                |
| lib/src/geometry/geometry_errors.dart:39             | `String get description => switch (this) {`                                      |
| lib/src/geometry/geometry_errors.dart:62             | `const GeometryTypeDetails({`                                                    |
| lib/src/geometry/geometry_errors.dart:78             | `const GeometryNumberDetails(this.value);`                                       |
| lib/src/geometry/geometry_errors.dart:88             | `const GeometryTagDetails(this.tag);`                                            |
| lib/src/geometry/geometry_errors.dart:98             | `const GeometrySegmentDetails({`                                                 |
| lib/src/geometry/geometry_errors.dart:127            | `const GeometryArcCalculationDetails({`                                          |
| lib/src/geometry/geometry_errors.dart:142            | `enum GeometryExtremumDirection { positiveX, negativeX, positiveY, negativeY }`  |
| lib/src/geometry/geometry_errors.dart:142            | `enum GeometryExtremumDirection { positiveX, negativeX, positiveY, negativeY }`  |
| lib/src/geometry/geometry_errors.dart:142            | `enum GeometryExtremumDirection { positiveX, negativeX, positiveY, negativeY }`  |
| lib/src/geometry/geometry_errors.dart:142            | `enum GeometryExtremumDirection { positiveX, negativeX, positiveY, negativeY }`  |
| lib/src/geometry/geometry_errors.dart:146            | `const GeometryCircleExtremumDetails({`                                          |
| lib/src/geometry/geometry_errors.dart:175            | `const GeometryArcExtremumDetails({`                                             |
| lib/src/geometry/geometry_errors.dart:191            | `const GeometryDiagnostic({required this.operation, this.details});`             |
| lib/src/geometry/geometry_errors.dart:206            | `const GeometryValidationException(this.code, this.fieldPath, this.diagnostic);` |
| lib/src/geometry/geometry_json.dart:4                | `Map<String, Object?> readGeometryObject(Object? json) {`                        |
| lib/src/geometry/geometry_json.dart:21               | `Object? requireGeometryField(Map<String, Object?> object, String key) {`        |
| lib/src/geometry/geometry_json.dart:32               | `String readGeometryString(Map<String, Object?> object, String key) {`           |
| lib/src/geometry/geometry_json.dart:50               | `void checkGeometryNumber(Map<String, Object?> object, String key) {`            |
| lib/src/geometry/geometry_json.dart:67               | `void checkGeometryFields(Map<String, Object?> object, Set<String> allowed) {`   |
| lib/src/geometry/geometry_json.dart:79               | `void checkFiniteGeometryNumber(double value, String fieldPath) {`               |
| lib/src/geometry/geometry_path.dart:24               | `GeometryPath({required this.start, required List<PathSegment> segments})`       |
| lib/src/geometry/geometry_path.dart:60               | `final Point2 start;`                                                            |
| lib/src/geometry/geometry_path.dart:62               | `final List<PathSegment> segments;`                                              |
| lib/src/geometry/geometry_path.dart:64               | `factory GeometryPath.fromJson(Object? json) {`                                  |
| lib/src/geometry/geometry_path.dart:71               | `Map<String, Object?> toJson() => _$GeometryPathToJson(this);`                   |
| lib/src/geometry/path_segments.dart:15               | `Map<String, Object?> toJson();`                                                 |
| lib/src/geometry/path_segments.dart:52               | `LineTo({required this.end});`                                                   |
| lib/src/geometry/path_segments.dart:71               | `ArcTo({required this.end, required this.bulge}) {`                              |
| lib/src/geometry/path_segments.dart:87               | `final double bulge;`                                                            |
| lib/src/geometry/point2.dart:19                      | `Point2({required this.x, required this.y}) {`                                   |
| lib/src/geometry/point2.dart:29                      | `factory Point2.fromJson(Object? json) {`                                        |
| lib/src/geometry/point2.dart:36                      | `Map<String, Object?> toJson() => _$Point2ToJson(this);`                         |
| lib/src/geometry/point2.dart:46                      | `Point2 readGeometryPoint(Object? json, String fieldPath) {`                     |
| lib/src/geometry/point2.dart:54                      | `Map<String, Object?> writeGeometryPoint(Point2 point) => point.toJson();`       |
| lib/src/product/product_design_configuration.dart:24 | `ProductDesignConfiguration({`                                                   |
| lib/src/product/product_design_configuration.dart:41 | `factory ProductDesignConfiguration.fromJson(Object? json) {`                    |
| lib/src/product/product_design_configuration.dart:48 | `Map<String, Object?> toJson() => _$ProductDesignConfigurationToJson(this);`     |
| lib/src/product/product_design_errors.dart:65        | `const ProductDesignIdentifierDetails(this.identifier);`                         |
| lib/src/product/product_design_errors.dart:66        | `final String identifier;`                                                       |
| lib/src/product/product_design_errors.dart:73        | `const ProductDesignDuplicateDetails({`                                          |
| lib/src/product/product_design_errors.dart:78        | `final String identifier;`                                                       |
| lib/src/product/product_design_errors.dart:92        | `ProductDesignReferenceDetails({`                                                |
| lib/src/product/product_design_errors.dart:97        | `final String productId;`                                                        |
| lib/src/product/product_design_errors.dart:98        | `final String appliedGeometryId;`                                                |
| lib/src/product/product_design_errors.dart:109       | `const ProductDesignAreaDetails({`                                               |
| lib/src/product/product_design_errors.dart:114       | `final String productId;`                                                        |
| lib/src/product/product_design_errors.dart:115       | `final String appliedGeometryId;`                                                |
| lib/src/product/product_design_errors.dart:126       | `const ProductDesignTypeDetails({`                                               |
| lib/src/product/product_design_errors.dart:130       | `final String expectedType;`                                                     |
| lib/src/product/product_design_errors.dart:131       | `final String actualType;`                                                       |
| lib/src/product/product_design_errors.dart:138       | `const ProductDesignIssue({`                                                     |
| lib/src/product/product_design_errors.dart:143       | `final ProductDesignErrorCode code;`                                             |
| lib/src/product/product_design_errors.dart:147       | `final ProductDesignIssueDetails? details;`                                      |
| lib/src/product/product_design_errors.dart:148       | `ProductDesignIssue prefixed(String prefix) => ProductDesignIssue(`              |
| lib/src/product/product_design_errors.dart:160       | `ProductDesignValidationException(List<ProductDesignIssue> issues)`              |
| lib/src/product/product_design_errors.dart:165       | `ProductDesignValidationException prefixed(String prefix) =>`                    |
| lib/src/product/product_design_errors.dart:177       | `const ProductDesignNestedException({`                                           |
| lib/src/product/product_design_errors.dart:181       | `final String fieldPath;`                                                        |
| lib/src/product/product_design_errors.dart:185       | `ProductDesignNestedException prefixed(String prefix) =>`                        |
| lib/src/product/product_input.dart:20                | `ProductInput({`                                                                 |
| lib/src/product/product_input.dart:46                | `factory ProductInput.fromJson(Object? json) {`                                  |
| lib/src/product/product_input.dart:58                | `Map<String, Object?> toJson() => _$ProductInputToJson(this);`                   |
| lib/src/product/product_json.dart:7                  | `Never rejectProductValue(`                                                      |
| lib/src/product/product_json.dart:15                 | `void checkProductIdentifier(`                                                   |
| lib/src/product/product_json.dart:25                 | `Map<String, Object?> readProductObject(Object? json) {`                         |
| lib/src/product/product_json.dart:39                 | `Object? requireProductField(Map<String, Object?> object, String key) {`         |
| lib/src/product/product_json.dart:46                 | `void checkProductString(`                                                       |
| lib/src/product/product_json.dart:65                 | `void checkProductFields(Map<String, Object?> object, Set<String> allowed) {`    |
| lib/src/product/product_json.dart:73                 | `List<Object?> readProductList(Object? value, String path) {`                    |
| lib/src/text_area_input.dart:8                       | `missingField,`                                                                  |
| lib/src/text_area_input.dart:9                       | `invalidType,`                                                                   |
| lib/src/text_area_input.dart:10                      | `unknownLineBreakMode,`                                                          |
| lib/src/text_area_input.dart:11                      | `unexpectedField,`                                                               |
| lib/src/text_area_input.dart:12                      | `emptyAreaId,`                                                                   |
| lib/src/text_area_input.dart:13                      | `emptySourceText,`                                                               |
| lib/src/text_area_input.dart:14                      | `emptySpecifiedLines,`                                                           |
| lib/src/text_area_input.dart:15                      | `emptySpecifiedLine,`                                                            |
| lib/src/text_area_input.dart:16                      | `sourceContainsCrLf,`                                                            |
| lib/src/text_area_input.dart:17                      | `specifiedLineContainsCrLf,`                                                     |
| lib/src/text_area_input.dart:18                      | `specifiedLinesMismatchSourceText,`                                              |
| lib/src/text_area_input.dart:25                      | `const TextInputValidationException(this.code, this.fieldPath);`                 |
| lib/src/text_area_input.dart:27                      | `final TextInputErrorCode code;`                                                 |
| lib/src/text_area_input.dart:28                      | `final String fieldPath;`                                                        |
| lib/src/text_area_input.dart:85                      | `const AutomaticLineBreak();`                                                    |
| lib/src/text_area_input.dart:101                     | `SpecifiedLineBreak(List<String> lines) : lines = List.unmodifiable(lines) {`    |
| lib/src/text_area_input.dart:125                     | `final List<String> lines;`                                                      |
| lib/src/text_area_input.dart:144                     | `TextAreaInput({`                                                                |
| lib/src/text_area_input.dart:170                     | `final String areaId;`                                                           |
| lib/src/text_area_input.dart:171                     | `final String sourceText;`                                                       |
| lib/src/text_area_input.dart:173                     | `final LineBreakInput lineBreak;`                                                |
| lib/src/text_area_input.dart:175                     | `Map<String, Object?> toJson() => _$TextAreaInputToJson(this);`                  |

</details>


## 구조화 진단·원인·스택 재점검 (2026-10-27)

[예외·진단·로깅 계약](failure-diagnostics-logging.md)에 타입별 필수 상세와 소비자 예제를 기록했다.
invalidType은 네 오류 계열 모두 기대/실제 타입이 필수다. 미지원 태그/방식은 실제 값과 지원 목록을 제공한다.
코드별 상세 유형이 다르거나 필수 상세/경로가 없으면 ArgumentError다. 제품 예외의 빈 issue 목록도 거부한다.
중첩 변환은 cause/causeStackTrace/contextStackTrace와 Error.throwWithStackTrace를 사용한다.
같은 예외는 rethrow하며 Error를 입력 실패로 잡지 않는다. 정상 값·JSON·기하 알고리즘은 바꾸지 않았다.
예외/issue 생성자는 const가 아니며 새 TextInputDetails와 GeometryTagDetails.supportedValues를 공개한다.
이 변화가 JSON 저장 스키마·업무 값 이름 변경이나 호환 별칭을 뜻하지 않는다.
패키지에는 로거/파일/Flutter 의존성이 없다. 앱 출력/전역 오류 핸들러는 앱 소유다.

최종 실제 검사: 전체 verify에서 생성 일치/반복 안정성·analyze(No issues)·447개 테스트·AOT 6개·생성기 없는 소비자 성공.
문구 진단 10개/제품 진단 8개는 파일별 단독 실행도 성공했다. 공개 설명 lint를 유지했고 새 누락은 없다.
원격 CI·앱 로그의 다른 OS 동작·업무 I/O/배치/저장 검증은 이 라이브러리 성공에 포함하지 않는다.


## 공통 적용 ID 내용 불변 API (2026-10-27)

[현행 변경 계약](product-design-change.md) 12절의 순수 비교 함수를 구현했다.
별도 두 구성의 전체 스냅샷 동등성을 사용하며 기존 참조·JSON·기하 계약은 바꾸지 않았다.
새 공개 진단/함수의 상대 경로·선언 인덱스·목록 방어·정상 충돌/코드 결함 경계를 한국어로 설명했다.
501개 테스트·AOT 7개·생성기 없는 독립 소비자 및 생성 일치/안정성·분석을 통과했다.
공통 ID 내용 비교와 제거 ID의 역사적 재사용 추적·세션 개정·안전 반영은 구분한다.

## 개발 기반 보완 감사 — 2026-10-28

[현행 도구 기준](development-foundation-additions.md)에 따라 검증 진단 반환·불변 값 변환에
직접 의존성 meta 1.19.0의 @useResult를 선별 적용했다.
외부 소비자에서 반환값 무시 2건이 unused_result로 검출됐다. 함수 시그니처·업무 값·JSON·오류 의미는 유지한다.
이는 분석 의도이며 런타임 업무 검증을 대체하지 않는다.

공개 진입점을 named library로 선언해 SDK dartdoc 9.0.6의 include 대상으로 삼는다.
unnecessary_library_name 한 줄 예외는 공개 진입점 선택을 위한 것이며 광범위 제외는 없다.
lib/src의 export 타입은 진입점 소비자 API로 문서화하고 비export 도우미를 별도 library로 노출하지 않는다.
기존 public_member_api_docs와 공식 dart doc --dry-run/모든 경고 거부 경계를 함께 실행한다.
공식 dry-run과 현재 문서 검사 결과는 경고 0·오류 0이다.
깨진 참조 fixture의 실패도 확인했다. HTML 생성/시각 검증과 외부 웹 링크 검증은 수행하지 않았다.

전체 검증: 502개 테스트·AOT 7개·생성 없는 소비자, 생성 일치/반복 안정성·포맷·분석 통과.
IDE 검사·원격 Actions·다른 OS는 미실행이다.
## 제품 적용 형상 변경 준비 (2026-10-28)

[현행 변경 API](product-design-change.md)의 요청/대응/준비/요약/전용 진단을 공개했다.
생성·복원할 요청 JSON API와 최종 apply는 없다. 기존 업무 값 JSON·오류·기하 계약은 유지한다.
새 공개 생성자/필드/코드/함수는 한국어 의미·위치·실패·한계를 설명하고 public_member_api_docs를 유지했다.
공개 진입점에만 소비자 API를 export하며 내부 내용 경로 수집/입력 투영은 export하지 않는다.
Ready는 외부 생성/copyWith/후보 getter 없이 기준·요청·요약만 제공한다.
진단은 코드별 작은 필수 상세·원래 하위 issue를 보존하고 런타임 검증한다.
전체 verify의 문서 경고/오류 0, 분석 및 549개 테스트·AOT 8개·생성 없는 소비자가 통과했다.
141건은 초기 감사 당시 누락 수이며 이번 공개 API 수로 다시 해석하지 않는다.