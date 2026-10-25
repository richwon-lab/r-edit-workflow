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
    show
        GeometryErrorCode,
        GeometryErrorExplanation,
        GeometryDiagnostic,
        GeometryValidationException,
        GeometryDiagnosticDetails,
        GeometryTypeDetails,
        GeometryNumberDetails,
        GeometryTagDetails,
        GeometrySegmentDetails,
        GeometryArcCalculationDetails,
        GeometryCircleExtremumDetails,
        GeometryArcExtremumDetails,
        GeometryExtremumDirection;
export 'src/geometry/coordinate_space.dart'
    show LengthUnit, DrawingCoordinateSpace;
export 'src/geometry/point2.dart' show Point2;
export 'src/geometry/path_segments.dart' show PathSegment, LineTo, ArcTo;
export 'src/geometry/geometry_path.dart' show GeometryPath;
export 'src/geometry/closed_boundary.dart'
    show ClosedBoundary, CircleBoundary, PathBoundary;
export 'src/geometry/drawing_geometry.dart' show DrawingGeometry;

export 'src/design/design_geometry.dart' show DesignGeometry;
export 'src/design/cutout_definition.dart' show CutoutDefinition;
export 'src/design/text_area_definition.dart' show TextAreaDefinition;
export 'src/design/text_region.dart' show TextRegion;
export 'src/design/design_errors.dart'
    show
        DesignErrorCode,
        DesignIssueDetails,
        DesignIdentifierDetails,
        DesignDuplicateDetails,
        DesignTypeDetails,
        DesignValidationIssue,
        DesignValidationException;
export 'src/design/text_area_input_validation.dart' show validateTextAreaInputs;

export 'src/design/applied_design_geometry.dart' show AppliedDesignGeometry;
export 'src/design/design_source_reference.dart' show DesignSourceReference;
export 'src/product/product_input.dart' show ProductInput;
export 'src/product/product_design_configuration.dart'
    show ProductDesignConfiguration;
export 'src/product/product_design_validation.dart'
    show validateProductDesignConfiguration;
export 'src/product/product_design_errors.dart'
    show
        ProductDesignErrorCode,
        ProductDesignIssue,
        ProductDesignIssueDetails,
        ProductDesignIdentifierDetails,
        ProductDesignDuplicateDetails,
        ProductDesignReferenceDetails,
        ProductDesignAreaDetails,
        ProductDesignTypeDetails,
        ProductDesignValidationException,
        ProductDesignNestedException;
