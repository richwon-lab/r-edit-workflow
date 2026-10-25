/// R-edit의 영역별 원문·줄 입력과 최소 기하 값를 위한 공개 API.
library;

export 'src/design/applied_design_geometry.dart' show AppliedDesignGeometry;
export 'src/design/cutout_definition.dart' show CutoutDefinition;
export 'src/design/design_errors.dart'
    show
        DesignDuplicateDetails,
        DesignErrorCode,
        DesignIdentifierDetails,
        DesignIssueDetails,
        DesignTypeDetails,
        DesignValidationException,
        DesignValidationIssue;
export 'src/design/design_geometry.dart' show DesignGeometry;
export 'src/design/design_source_reference.dart' show DesignSourceReference;
export 'src/design/text_area_definition.dart' show TextAreaDefinition;
export 'src/design/text_area_input_validation.dart' show validateTextAreaInputs;
export 'src/design/text_region.dart' show TextRegion;
export 'src/geometry/closed_boundary.dart'
    show CircleBoundary, ClosedBoundary, PathBoundary;
export 'src/geometry/coordinate_space.dart'
    show DrawingCoordinateSpace, LengthUnit;
export 'src/geometry/drawing_geometry.dart' show DrawingGeometry;
export 'src/geometry/geometry_errors.dart'
    show
        GeometryArcCalculationDetails,
        GeometryArcExtremumDetails,
        GeometryCircleExtremumDetails,
        GeometryDiagnostic,
        GeometryDiagnosticDetails,
        GeometryErrorCode,
        GeometryErrorExplanation,
        GeometryExtremumDirection,
        GeometryNumberDetails,
        GeometrySegmentDetails,
        GeometryTagDetails,
        GeometryTypeDetails,
        GeometryValidationException;
export 'src/geometry/geometry_path.dart' show GeometryPath;
export 'src/geometry/path_segments.dart' show ArcTo, LineTo, PathSegment;
export 'src/geometry/point2.dart' show Point2;
export 'src/product/product_design_configuration.dart'
    show ProductDesignConfiguration;
export 'src/product/product_design_errors.dart'
    show
        ProductDesignAreaDetails,
        ProductDesignDuplicateDetails,
        ProductDesignErrorCode,
        ProductDesignIdentifierDetails,
        ProductDesignIssue,
        ProductDesignIssueDetails,
        ProductDesignNestedException,
        ProductDesignReferenceDetails,
        ProductDesignTypeDetails,
        ProductDesignValidationException;
export 'src/product/product_design_validation.dart'
    show validateProductDesignConfiguration;
export 'src/product/product_input.dart' show ProductInput;
export 'src/text_area_input.dart'
    show
        AutomaticLineBreak,
        LineBreakInput,
        SpecifiedLineBreak,
        TextAreaInput,
        TextInputErrorCode,
        TextInputValidationException;
