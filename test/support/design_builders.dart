import 'dart:convert';

import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import 'geometry_builders.dart' show pointAtCoordinates;

/// 중심 (2,2)이며 수치의 길이 단위는 소유 도안 문맥을 따른다.
CircleBoundary circleCenteredAt2([double radius = 1]) =>
    CircleBoundary(center: pointAtCoordinates(2, 2), radius: radius);
PathBoundary polygonBoundaryThroughVertices(List<Point2> vertices) =>
    PathBoundary(
      path: GeometryPath(
        start: vertices.first,
        segments: [for (final end in vertices.skip(1)) LineTo(end: end)],
      ),
    );
PathBoundary rectangularBoundary4By2() => polygonBoundaryThroughVertices([
  pointAtCoordinates(0, 0),
  pointAtCoordinates(4, 0),
  pointAtCoordinates(4, 2),
  pointAtCoordinates(0, 2),
  pointAtCoordinates(0, 0),
]);
PathBoundary slotBoundaryFrom1To3() => PathBoundary(
  path: GeometryPath(
    start: pointAtCoordinates(1, 1),
    segments: [
      LineTo(end: pointAtCoordinates(3, 1)),
      ArcTo(end: pointAtCoordinates(3, 3), bulge: 1),
      LineTo(end: pointAtCoordinates(1, 3)),
      ArcTo(end: pointAtCoordinates(1, 1), bulge: 1),
    ],
  ),
);
TextAreaDefinition textAreaWithCircularRegion(
  String id, {
  String label = '',
  ClosedBoundary? outer,
  List<ClosedBoundary>? exclusions,
}) => TextAreaDefinition(
  areaId: id,
  label: label,
  region: TextRegion(
    outer: outer ?? circleCenteredAt2(10),
    exclusions: exclusions ?? [],
  ),
);

/// inch 문맥의 비정형 외곽이다. ID·입력 검증에 무관한 외곽 준비만 공유한다.
DesignGeometry inchDesignWithIrregularOutline({
  List<CutoutDefinition>? cutouts,
  List<TextAreaDefinition>? areas,
}) => DesignGeometry(
  coordinateSpace: DrawingCoordinateSpace(lengthUnit: LengthUnit.inch),
  outline: polygonBoundaryThroughVertices([
    pointAtCoordinates(-1, -1),
    pointAtCoordinates(8, -1),
    pointAtCoordinates(9, 3),
    pointAtCoordinates(6, 8),
    pointAtCoordinates(-1, 5),
    pointAtCoordinates(-1, -1),
  ]),
  cutouts: cutouts ?? [],
  textAreas: areas ?? [],
);
TextAreaInput textInputForArea(
  String id, {
  String text = ' PUMP  A ',
  bool specified = false,
}) => TextAreaInput(
  areaId: id,
  sourceText: text,
  lineBreak: specified
      ? SpecifiedLineBreak([text])
      : const AutomaticLineBreak(),
);
Object? designJsonThroughString(Object? json) => jsonDecode(jsonEncode(json));
Matcher designError(DesignErrorCode code, String path) => throwsA(
  isA<DesignValidationException>()
      .having((e) => e.code, 'code', code)
      .having((e) => e.fieldPath, 'path', path),
);
