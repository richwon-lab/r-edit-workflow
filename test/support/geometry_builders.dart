import 'dart:convert';

import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

/// 좌표 수치 그대로 생성한다. 길이 단위는 이를 소유하는 문맥을 따른다.
Point2 pointAtCoordinates(double x, double y) => Point2(x: x, y: y);
GeometryPath linePathThroughVertices(List<Point2> points) => GeometryPath(
  start: points.first,
  segments: [for (final end in points.skip(1)) LineTo(end: end)],
);

/// 문맥 단위로 폭 4·높이 2인 명시적 닫힌 선분 경로다.
GeometryPath rectangularPath4By2() => linePathThroughVertices([
  pointAtCoordinates(0, 0),
  pointAtCoordinates(4, 0),
  pointAtCoordinates(4, 2),
  pointAtCoordinates(0, 2),
  pointAtCoordinates(0, 0),
]);
DrawingGeometry inchDrawingGeometry({
  List<GeometryPath>? paths,
  List<ClosedBoundary>? boundaries,
}) => DrawingGeometry(
  coordinateSpace: DrawingCoordinateSpace(lengthUnit: LengthUnit.inch),
  paths: paths ?? [],
  boundaries: boundaries ?? [],
);
Object? jsonThroughString(Object? json) => jsonDecode(jsonEncode(json));
Matcher geometryError(GeometryErrorCode code, String path) => throwsA(
  isA<GeometryValidationException>()
      .having((e) => e.code, 'code', code)
      .having((e) => e.fieldPath, 'fieldPath', path),
);
