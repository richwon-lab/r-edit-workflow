/// R-edit의 영역별 원문·줄 입력과 첫 형상·영역 정의를 위한 공개 API.
library;

export 'src/text_area_input.dart'
    show
        TextAreaInput,
        LineBreakInput,
        AutomaticLineBreak,
        SpecifiedLineBreak,
        TextInputErrorCode,
        TextInputValidationException;

export 'src/geometry.dart'
    show
        RectangularPlateGeometry,
        CircularHole,
        TextAreaBounds,
        TextAreaDefinition,
        GeometryErrorCode,
        GeometryValidationException;
