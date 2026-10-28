/// R-edit의 영역별 원문·줄 입력과 최소 기하 값을 위한 공개 API.
// dart doc의 include가 라이브러리 이름을 사용하므로 공개 진입점 이름을 명시한다.
// ignore: unnecessary_library_name
library r_edit_workflow;

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
export 'src/product/applied_geometry_id_conflict.dart'
    show AppliedGeometryIdConflict, AppliedGeometryIdConflictCode;
export 'src/product/applied_geometry_id_consistency.dart'
    show validateAppliedGeometryIdConsistency;
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
export 'src/product/product_geometry_change_errors.dart'
    show
        ChangeAppliedReferenceDetails,
        ChangeAreaInputDetails,
        ChangeAreaSelectionDetails,
        ChangeAreaSide,
        ChangeConfigurationDetails,
        ChangeDuplicateTargetsDetails,
        ChangeEmptyTargetsDetails,
        ChangeIdentifierDetails,
        ChangeSnapshotConflictDetails,
        ChangeSourceDetails,
        ChangeTargetDetails,
        ProductGeometryChangeCode,
        ProductGeometryChangeDetails,
        ProductGeometryChangeIssue;
export 'src/product/product_geometry_change_preparation.dart'
    show
        BlockedProductGeometryChange,
        ProductGeometryChangePreparation,
        ReadyProductGeometryChange,
        UnchangedProductGeometryChange,
        prepareProductGeometryChange;
export 'src/product/product_geometry_change_request.dart'
    show
        ProductGeometryChangeRequest,
        ReplaceAppliedGeometry,
        ReviseAppliedGeometry;
export 'src/product/product_geometry_change_summary.dart'
    show ProductGeometryChangeSummary, ProductGeometryTargetSummary;
export 'src/product/product_geometry_target.dart' show ProductGeometryTarget;
export 'src/product/product_input.dart' show ProductInput;
export 'src/product/text_area_input_mapping.dart' show TextAreaInputMapping;
export 'src/text_area_input.dart'
    show AutomaticLineBreak, LineBreakInput, SpecifiedLineBreak, TextAreaInput;
export 'src/text_input_errors.dart'
    show
        TextInputCharacterDetails,
        TextInputDetails,
        TextInputErrorCode,
        TextInputMismatchDetails,
        TextInputModeDetails,
        TextInputTypeDetails,
        TextInputValidationException;
