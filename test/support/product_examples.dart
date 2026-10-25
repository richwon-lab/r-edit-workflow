import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

/// mm 문맥의 반지름 30 원형 외곽과 지정 영역 ID들을 준비한다.
DesignGeometry millimeterDesignWithAreaIds(List<String> areaIds) {
  final boundary = CircleBoundary(center: Point2(x: 0, y: 0), radius: 10);
  return DesignGeometry(
    coordinateSpace: DrawingCoordinateSpace(lengthUnit: LengthUnit.millimeter),
    outline: CircleBoundary(center: Point2(x: 0, y: 0), radius: 30),
    cutouts: [],
    textAreas: [
      for (final id in areaIds)
        TextAreaDefinition(
          areaId: id,
          label: '',
          region: TextRegion(outer: boundary, exclusions: []),
        ),
    ],
  );
}

AppliedDesignGeometry appliedMillimeterDesign(
  String id,
  List<String> areaIds,
) => AppliedDesignGeometry(
  appliedGeometryId: id,
  geometry: millimeterDesignWithAreaIds(areaIds),
);

TextAreaInput automaticAreaText(String areaId, String sourceText) =>
    TextAreaInput(
      areaId: areaId,
      sourceText: sourceText,
      lineBreak: const AutomaticLineBreak(),
    );

/// 생성 결과를 복사하지 않는 고정 기대 JSON 구조다.
Map<String, Object?> expectedTitleGeometryJson() => {
  'coordinateSpace': {'lengthUnit': 'millimeter'},
  'outline': {
    'kind': 'circle',
    'center': {'x': 0, 'y': 0},
    'radius': 30,
  },
  'cutouts': <Object?>[],
  'textAreas': [
    {
      'areaId': 'title',
      'label': '',
      'region': {
        'outer': {
          'kind': 'circle',
          'center': {'x': 0, 'y': 0},
          'radius': 10,
        },
        'exclusions': <Object?>[],
      },
    },
  ],
};

Matcher productFailure(ProductDesignErrorCode code, String fieldPath) =>
    throwsA(
      isA<ProductDesignValidationException>().having(
        (e) => e.issues,
        'issues',
        contains(
          isA<ProductDesignIssue>()
              .having((i) => i.code, 'code', code)
              .having((i) => i.fieldPath, 'fieldPath', fieldPath),
        ),
      ),
    );
