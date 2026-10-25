/// R-edit의 영역별 원문·줄 입력과 최소 기하 값를 위한 공개 API.
library;

export 'src/text_area_input.dart'
    show
        TextAreaInput,
        LineBreakInput,
        AutomaticLineBreak,
        SpecifiedLineBreak,
        TextInputErrorCode,
        TextInputValidationException;

export 'src/geometry/geometry_errors.dart'
    show GeometryErrorCode, GeometryDiagnostic, GeometryValidationException;
export 'src/geometry/coordinate_space.dart'
    show LengthUnit, DrawingCoordinateSpace;
export 'src/geometry/point2.dart' show Point2;
export 'src/geometry/path_segments.dart' show PathSegment, LineTo, ArcTo;
export 'src/geometry/geometry_path.dart' show GeometryPath;
export 'src/geometry/closed_boundary.dart'
    show ClosedBoundary, CircleBoundary, PathBoundary;
export 'src/geometry/drawing_geometry.dart' show DrawingGeometry;
