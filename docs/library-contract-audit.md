# 라이브러리 개발 계약 감사

확인일: 2026-10-26. 공개 진입점·실제 구현·기존 417개 테스트·5개 AOT 검사·독립 소비자를 대조했다.
이번 변경은 분석 기준·타입 명시·import/표기 정리와 개발 도구다. 업무 의미·공개 오류·JSON을 새로 설계하지 않았다.

| 계약 | 실제 보장과 확인 | 남은 차이·한계 |
|---|---|---|
| 공개 API | 공개 진입점만 import하는 예제·생성기 없는 소비자 실행 | 현재 값/참조 구성이며 전체 WorkDocument 아님 |
| 원문·줄바꿈 | 공백/Unicode 보존, automatic/specified sealed 구분, 한 줄 specified, 수정 검증 | 빈 원문/빈 줄/CRLF는 기존 첫 지원 제한 |
| 최소 기하 | 유한 값·파생 수치·실제 원호 극점 검증, 단위 환산 | 포함/간섭/자기 교차/면적/제작 미검사 |
| 도안 역할·입력 | 외곽/관통/텍스트 구분, areaId 대응·진단 | 전체 제작 조건·자동 배치 아님 |
| 제품 참조 | 중복/없는/모호 참조·입력 대응 독립 issue, 수정 불가 목록 | 과거/새 구성의 같은 ID 내용 변경·안전한 변경 명령 미구현 |
| 스냅샷 불변성 | AppliedDesignGeometry에 일반 내용 교체 copyWith 없음 | 생성/복원만으로 역사적 ID 불변성까지 보장하지 않음 |
| JSON·오류 | 고정 기대 구조·복원·code/fieldPath/하위 진단, 출처 생략/null 기존 규약 검증 | 조각 JSON이며 전체 저장 형식 아님 |
| 소비자 | example/product_configuration.dart를 별도 path 패키지에서 AOT 실행 | 원격 Git fetch/호스팅 배포 미실행 |
| 생성 소스 | 기존 30개 생성 파일 최종 재생성 안정성, 소비자 생성기 의존성 없음 | 라이브러리 lock 미추적으로 미래 dev 해결은 재검증 필요 |
| 공개 API 설명 | 타입/업무/오류 코드 설명은 존재 | 개별 공개 멤버 설명 누락 141건, 아래 목록 |

## 분석 기준 적용 범위

strict-casts/inference/raw-types를 켰다. raw List JSON 도우미를 List<Object?>로 명시하고
빈 목록/Map 테스트 입력 타입을 명시했다. import 정렬·package import·const·테스트 회전 로컬 변수만 정리했다.
기하 알고리즘·오류 발생 조건·원문 보존 정책은 바꾸지 않았다.
public_member_api_docs는 기존 누락 추적 중 명시적 예외다. 새/수정 API 설명은 필수다.
나머지 예외와 기술 선택은 [개발 기반](development-foundation.md)을 따른다.

## 실행한 검증

Windows / Flutter 3.47.7 포함 Dart 3.13.5:
의존성 해결·생성·포맷·분석 성공, 전체 417개 테스트 성공, 최종 재생성 안정성 성공.
assert 비활성 AOT 5개(원문, 기하, 원호 수치, 도안, 제품 구성) 성공.
독립 소비자는 생성기 3종이 package_config에 없음을 검사한 뒤 예제 AOT 컴파일·실행에 성공했다.
원격 CI/Linux 실행·새 업무 기능 검증으로 해석하지 않는다.

## 기존 문서 누락 목록

일시적으로 public_member_api_docs만 활성화하여 machine 형식 분석을 실행하고 원래 설정을 복원했다.
아래는 직접 작성한 공개 멤버별 위치다. 생성 소스는 제외했다.
API 동작 결함 수가 아니라 개별 API 설명 누락 수다.
다음 작업에서 생성자/JSON/진단 필드의 의미·실패 조건을 기존 계약과 대조해 보완한다.

| 파일:줄 | 멤버 선언 |
|---|---|
| lib/src/design/applied_design_geometry.dart:22 | AppliedDesignGeometry({ |
| lib/src/design/applied_design_geometry.dart:44 | factory AppliedDesignGeometry.fromJson(Object? json) { |
| lib/src/design/applied_design_geometry.dart:55 | Map<String, Object?> toJson() => _$AppliedDesignGeometryToJson(this); |
| lib/src/design/cutout_definition.dart:21 | CutoutDefinition({required this.cutoutId, required this.boundary}) { |
| lib/src/design/cutout_definition.dart:39 | factory CutoutDefinition.fromJson(Object? json) { |
| lib/src/design/cutout_definition.dart:46 | Map<String, Object?> toJson() => _$CutoutDefinitionToJson(this); |
| lib/src/design/design_errors.dart:55 | const DesignIdentifierDetails(this.identifier); |
| lib/src/design/design_errors.dart:65 | const DesignDuplicateDetails({ |
| lib/src/design/design_errors.dart:86 | const DesignTypeDetails({ |
| lib/src/design/design_errors.dart:102 | const DesignValidationIssue({ |
| lib/src/design/design_errors.dart:130 | const DesignValidationException(this.issue); |
| lib/src/design/design_geometry.dart:24 | DesignGeometry({ |
| lib/src/design/design_geometry.dart:85 | factory DesignGeometry.fromJson(Object? json) { |
| lib/src/design/design_geometry.dart:98 | Map<String, Object?> toJson() => _$DesignGeometryToJson(this); |
| lib/src/design/design_json.dart:7 | Map<String, Object?> readDesignObject(Object? json) { |
| lib/src/design/design_json.dart:23 | Object? requireDesignField(Map<String, Object?> object, String key) { |
| lib/src/design/design_json.dart:32 | void readDesignString(Map<String, Object?> object, String key) { |
| lib/src/design/design_json.dart:48 | void checkDesignFields(Map<String, Object?> object, Set<String> allowed) { |
| lib/src/design/design_json.dart:61 | List<Object?> readDesignList(Object? json, String fieldPath) { |
| lib/src/design/design_json.dart:77 | ClosedBoundary readBoundary(Object? json, String fieldPath) { |
| lib/src/design/design_json.dart:85 | Map<String, Object?> writeBoundary(ClosedBoundary boundary) => |
| lib/src/design/design_source_reference.dart:19 | DesignSourceReference({required this.sourceDesignId, this.sourceRevision}) { |
| lib/src/design/design_source_reference.dart:41 | factory DesignSourceReference.fromJson(Object? json) { |
| lib/src/design/design_source_reference.dart:48 | Map<String, Object?> toJson() => _$DesignSourceReferenceToJson(this); |
| lib/src/design/text_area_definition.dart:21 | TextAreaDefinition({ |
| lib/src/design/text_area_definition.dart:47 | factory TextAreaDefinition.fromJson(Object? json) { |
| lib/src/design/text_area_definition.dart:55 | Map<String, Object?> toJson() => _$TextAreaDefinitionToJson(this); |
| lib/src/design/text_region.dart:20 | TextRegion({required this.outer, required List<ClosedBoundary> exclusions}) |
| lib/src/design/text_region.dart:30 | factory TextRegion.fromJson(Object? json) { |
| lib/src/design/text_region.dart:37 | Map<String, Object?> toJson() => _$TextRegionToJson(this); |
| lib/src/geometry/closed_boundary.dart:15 | Map<String, Object?> toJson(); |
| lib/src/geometry/closed_boundary.dart:16 | ClosedBoundary converted({required LengthUnit from, required LengthUnit to}); |
| lib/src/geometry/closed_boundary.dart:53 | CircleBoundary({required this.center, required this.radius}) { |
| lib/src/geometry/closed_boundary.dart:91 | final Point2 center; |
| lib/src/geometry/closed_boundary.dart:92 | final double radius; |
| lib/src/geometry/closed_boundary.dart:123 | PathBoundary({required this.path}) { |
| lib/src/geometry/closed_boundary.dart:142 | final GeometryPath path; |
| lib/src/geometry/coordinate_space.dart:9 | enum LengthUnit { millimeter, inch } |
| lib/src/geometry/coordinate_space.dart:9 | enum LengthUnit { millimeter, inch } |
| lib/src/geometry/coordinate_space.dart:22 | DrawingCoordinateSpace({required this.lengthUnit}); |
| lib/src/geometry/coordinate_space.dart:23 | final LengthUnit lengthUnit; |
| lib/src/geometry/coordinate_space.dart:24 | factory DrawingCoordinateSpace.fromJson(Object? json) { |
| lib/src/geometry/coordinate_space.dart:40 | Map<String, Object?> toJson() => _$DrawingCoordinateSpaceToJson(this); |
| lib/src/geometry/coordinate_space.dart:44 | double convertGeometryLength( |
| lib/src/geometry/drawing_geometry.dart:23 | DrawingGeometry({ |
| lib/src/geometry/drawing_geometry.dart:30 | final DrawingCoordinateSpace coordinateSpace; |
| lib/src/geometry/drawing_geometry.dart:32 | final List<GeometryPath> paths; |
| lib/src/geometry/drawing_geometry.dart:34 | final List<ClosedBoundary> boundaries; |
| lib/src/geometry/drawing_geometry.dart:35 | factory DrawingGeometry.fromJson(Object? json) { |
| lib/src/geometry/drawing_geometry.dart:47 | Map<String, Object?> toJson() => _$DrawingGeometryToJson(this); |
| lib/src/geometry/geometry_errors.dart:39 | String get description => switch (this) { |
| lib/src/geometry/geometry_errors.dart:62 | const GeometryTypeDetails({ |
| lib/src/geometry/geometry_errors.dart:78 | const GeometryNumberDetails(this.value); |
| lib/src/geometry/geometry_errors.dart:88 | const GeometryTagDetails(this.tag); |
| lib/src/geometry/geometry_errors.dart:98 | const GeometrySegmentDetails({ |
| lib/src/geometry/geometry_errors.dart:127 | const GeometryArcCalculationDetails({ |
| lib/src/geometry/geometry_errors.dart:142 | enum GeometryExtremumDirection { positiveX, negativeX, positiveY, negativeY } |
| lib/src/geometry/geometry_errors.dart:142 | enum GeometryExtremumDirection { positiveX, negativeX, positiveY, negativeY } |
| lib/src/geometry/geometry_errors.dart:142 | enum GeometryExtremumDirection { positiveX, negativeX, positiveY, negativeY } |
| lib/src/geometry/geometry_errors.dart:142 | enum GeometryExtremumDirection { positiveX, negativeX, positiveY, negativeY } |
| lib/src/geometry/geometry_errors.dart:146 | const GeometryCircleExtremumDetails({ |
| lib/src/geometry/geometry_errors.dart:175 | const GeometryArcExtremumDetails({ |
| lib/src/geometry/geometry_errors.dart:191 | const GeometryDiagnostic({required this.operation, this.details}); |
| lib/src/geometry/geometry_errors.dart:206 | const GeometryValidationException(this.code, this.fieldPath, this.diagnostic); |
| lib/src/geometry/geometry_json.dart:4 | Map<String, Object?> readGeometryObject(Object? json) { |
| lib/src/geometry/geometry_json.dart:21 | Object? requireGeometryField(Map<String, Object?> object, String key) { |
| lib/src/geometry/geometry_json.dart:32 | String readGeometryString(Map<String, Object?> object, String key) { |
| lib/src/geometry/geometry_json.dart:50 | void checkGeometryNumber(Map<String, Object?> object, String key) { |
| lib/src/geometry/geometry_json.dart:67 | void checkGeometryFields(Map<String, Object?> object, Set<String> allowed) { |
| lib/src/geometry/geometry_json.dart:79 | void checkFiniteGeometryNumber(double value, String fieldPath) { |
| lib/src/geometry/geometry_path.dart:24 | GeometryPath({required this.start, required List<PathSegment> segments}) |
| lib/src/geometry/geometry_path.dart:60 | final Point2 start; |
| lib/src/geometry/geometry_path.dart:62 | final List<PathSegment> segments; |
| lib/src/geometry/geometry_path.dart:64 | factory GeometryPath.fromJson(Object? json) { |
| lib/src/geometry/geometry_path.dart:71 | Map<String, Object?> toJson() => _$GeometryPathToJson(this); |
| lib/src/geometry/path_segments.dart:15 | Map<String, Object?> toJson(); |
| lib/src/geometry/path_segments.dart:52 | LineTo({required this.end}); |
| lib/src/geometry/path_segments.dart:71 | ArcTo({required this.end, required this.bulge}) { |
| lib/src/geometry/path_segments.dart:87 | final double bulge; |
| lib/src/geometry/point2.dart:19 | Point2({required this.x, required this.y}) { |
| lib/src/geometry/point2.dart:29 | factory Point2.fromJson(Object? json) { |
| lib/src/geometry/point2.dart:36 | Map<String, Object?> toJson() => _$Point2ToJson(this); |
| lib/src/geometry/point2.dart:46 | Point2 readGeometryPoint(Object? json, String fieldPath) { |
| lib/src/geometry/point2.dart:54 | Map<String, Object?> writeGeometryPoint(Point2 point) => point.toJson(); |
| lib/src/product/product_design_configuration.dart:24 | ProductDesignConfiguration({ |
| lib/src/product/product_design_configuration.dart:41 | factory ProductDesignConfiguration.fromJson(Object? json) { |
| lib/src/product/product_design_configuration.dart:48 | Map<String, Object?> toJson() => _$ProductDesignConfigurationToJson(this); |
| lib/src/product/product_design_errors.dart:65 | const ProductDesignIdentifierDetails(this.identifier); |
| lib/src/product/product_design_errors.dart:66 | final String identifier; |
| lib/src/product/product_design_errors.dart:73 | const ProductDesignDuplicateDetails({ |
| lib/src/product/product_design_errors.dart:78 | final String identifier; |
| lib/src/product/product_design_errors.dart:92 | ProductDesignReferenceDetails({ |
| lib/src/product/product_design_errors.dart:97 | final String productId; |
| lib/src/product/product_design_errors.dart:98 | final String appliedGeometryId; |
| lib/src/product/product_design_errors.dart:109 | const ProductDesignAreaDetails({ |
| lib/src/product/product_design_errors.dart:114 | final String productId; |
| lib/src/product/product_design_errors.dart:115 | final String appliedGeometryId; |
| lib/src/product/product_design_errors.dart:126 | const ProductDesignTypeDetails({ |
| lib/src/product/product_design_errors.dart:130 | final String expectedType; |
| lib/src/product/product_design_errors.dart:131 | final String actualType; |
| lib/src/product/product_design_errors.dart:138 | const ProductDesignIssue({ |
| lib/src/product/product_design_errors.dart:143 | final ProductDesignErrorCode code; |
| lib/src/product/product_design_errors.dart:147 | final ProductDesignIssueDetails? details; |
| lib/src/product/product_design_errors.dart:148 | ProductDesignIssue prefixed(String prefix) => ProductDesignIssue( |
| lib/src/product/product_design_errors.dart:160 | ProductDesignValidationException(List<ProductDesignIssue> issues) |
| lib/src/product/product_design_errors.dart:165 | ProductDesignValidationException prefixed(String prefix) => |
| lib/src/product/product_design_errors.dart:177 | const ProductDesignNestedException({ |
| lib/src/product/product_design_errors.dart:181 | final String fieldPath; |
| lib/src/product/product_design_errors.dart:185 | ProductDesignNestedException prefixed(String prefix) => |
| lib/src/product/product_input.dart:20 | ProductInput({ |
| lib/src/product/product_input.dart:46 | factory ProductInput.fromJson(Object? json) { |
| lib/src/product/product_input.dart:58 | Map<String, Object?> toJson() => _$ProductInputToJson(this); |
| lib/src/product/product_json.dart:7 | Never rejectProductValue( |
| lib/src/product/product_json.dart:15 | void checkProductIdentifier( |
| lib/src/product/product_json.dart:25 | Map<String, Object?> readProductObject(Object? json) { |
| lib/src/product/product_json.dart:39 | Object? requireProductField(Map<String, Object?> object, String key) { |
| lib/src/product/product_json.dart:46 | void checkProductString( |
| lib/src/product/product_json.dart:65 | void checkProductFields(Map<String, Object?> object, Set<String> allowed) { |
| lib/src/product/product_json.dart:73 | List<Object?> readProductList(Object? value, String path) { |
| lib/src/text_area_input.dart:8 | missingField, |
| lib/src/text_area_input.dart:9 | invalidType, |
| lib/src/text_area_input.dart:10 | unknownLineBreakMode, |
| lib/src/text_area_input.dart:11 | unexpectedField, |
| lib/src/text_area_input.dart:12 | emptyAreaId, |
| lib/src/text_area_input.dart:13 | emptySourceText, |
| lib/src/text_area_input.dart:14 | emptySpecifiedLines, |
| lib/src/text_area_input.dart:15 | emptySpecifiedLine, |
| lib/src/text_area_input.dart:16 | sourceContainsCrLf, |
| lib/src/text_area_input.dart:17 | specifiedLineContainsCrLf, |
| lib/src/text_area_input.dart:18 | specifiedLinesMismatchSourceText, |
| lib/src/text_area_input.dart:25 | const TextInputValidationException(this.code, this.fieldPath); |
| lib/src/text_area_input.dart:27 | final TextInputErrorCode code; |
| lib/src/text_area_input.dart:28 | final String fieldPath; |
| lib/src/text_area_input.dart:85 | const AutomaticLineBreak(); |
| lib/src/text_area_input.dart:101 | SpecifiedLineBreak(List<String> lines) : lines = List.unmodifiable(lines) { |
| lib/src/text_area_input.dart:125 | final List<String> lines; |
| lib/src/text_area_input.dart:144 | TextAreaInput({ |
| lib/src/text_area_input.dart:170 | final String areaId; |
| lib/src/text_area_input.dart:171 | final String sourceText; |
| lib/src/text_area_input.dart:173 | final LineBreakInput lineBreak; |
| lib/src/text_area_input.dart:175 | Map<String, Object?> toJson() => _$TextAreaInputToJson(this); |

## 최종 문서·구성 확인

두 저장소의 신규/갱신 문서 상대 링크와 CI YAML의 job/시간 제한/Action SHA 구조를 로컬에서 검사했다.
공개 진입점의 export 이름 집합이 기존 HEAD와 동일하며 기존 생성 소스에 추가 diff가 없음을 확인했다.
git diff --check와 빈 기존 인덱스 보존 확인이 통과했다.
이 구성 검사는 원격 Actions 실행·Linux 동작 확인을 대신하지 않는다.
