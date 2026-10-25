import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/design_builders.dart'
    show
        circleCenteredAt2,
        designError,
        inchDesignWithIrregularOutline,
        textAreaWithCircularRegion;

void main() {
  group('DesignValidationException의 상세 보존', () {
    {
      test('중복 영역 오류에 ID·첫 위치·중복 위치와 설명을 제공한다', () {
        final h = CutoutDefinition(
          cutoutId: 'same',
          boundary: circleCenteredAt2(),
        );
        final a = textAreaWithCircularRegion('same');
        final original = inchDesignWithIrregularOutline(
          cutouts: [h],
          areas: [a],
        );
        try {
          original.copyWith(textAreas: [a, a]);
          fail('중복 허용');
        } on DesignValidationException catch (e) {
          final details = e.issue.details as DesignDuplicateDetails;
          expect(details.firstIndex, 0);
          expect(details.duplicateIndex, 1);
          expect(details.identifier, 'same');
          expect(
            e.toString(),
            allOf(
              contains('same'),
              contains('firstIndex=0'),
              contains(e.code.description),
            ),
          );
        }
      });
    }

    {
      test('label 타입 오류의 기대·실제 타입을 접두사 연결에서도 보존한다', () {
        try {
          TextAreaDefinition.fromJson({
            'areaId': 'a',
            'label': null,
            'region': textAreaWithCircularRegion('a').region.toJson(),
          });
          fail('잘못된 타입 허용');
        } on DesignValidationException catch (e) {
          final details = e.issue.details as DesignTypeDetails;
          expect(details.expectedType, 'String');
          expect(details.actualType, 'Null');
          expect(
            identical(e.prefixed('textAreas[0]').issue.details, details),
            isTrue,
          );
        }
      });
    }

    {
      test('cutouts=null의 타입 오류 위치를 제공한다', () {
        expect(
          () => DesignGeometry.fromJson({
            ...inchDesignWithIrregularOutline().toJson(),
            'cutouts': null,
          }),
          designError(DesignErrorCode.invalidType, 'cutouts'),
        );
      });
    }

    {
      test('textAreas=false의 타입 오류 위치를 제공한다', () {
        expect(
          () => DesignGeometry.fromJson({
            ...inchDesignWithIrregularOutline().toJson(),
            'textAreas': false,
          }),
          designError(DesignErrorCode.invalidType, 'textAreas'),
        );
      });
    }

    {
      test('중첩 영역의 label=null 위치를 제공한다', () {
        final original = inchDesignWithIrregularOutline(
          areas: [textAreaWithCircularRegion('a')],
        );
        expect(
          () => DesignGeometry.fromJson({
            ...original.toJson(),
            'textAreas': [
              {
                'areaId': 'a',
                'label': null,
                'region': textAreaWithCircularRegion('a').region.toJson(),
              },
            ],
          }),
          designError(DesignErrorCode.invalidType, 'textAreas[0].label'),
        );
      });
    }

    {
      test('중첩 영역에서 제외 경계 목록 누락을 보정하지 않는다', () {
        final original = inchDesignWithIrregularOutline(
          areas: [textAreaWithCircularRegion('a')],
        );
        expect(
          () => DesignGeometry.fromJson({
            ...original.toJson(),
            'textAreas': [
              {
                'areaId': 'a',
                'label': '',
                'region': {'outer': circleCenteredAt2().toJson()},
              },
            ],
          }),
          designError(
            DesignErrorCode.missingField,
            'textAreas[0].region.exclusions',
          ),
        );
      });
    }

    {
      test('중첩 관통 경계의 반지름 오류 코드·경로·기하 진단을 보존한다', () {
        final original = inchDesignWithIrregularOutline(
          areas: [textAreaWithCircularRegion('a')],
        );
        try {
          DesignGeometry.fromJson({
            ...original.toJson(),
            'cutouts': [
              {
                'cutoutId': 'h',
                'boundary': {
                  'kind': 'circle',
                  'center': {'x': 0, 'y': 0},
                  'radius': 0,
                },
              },
            ],
          });
          fail('기하 오류 허용');
        } on GeometryValidationException catch (e) {
          expect(e.code, GeometryErrorCode.nonPositiveRadius);
          expect(e.fieldPath, 'cutouts[0].boundary.radius');
          expect((e.diagnostic.details as GeometryNumberDetails).value, 0);
          expect(
            identical(e.prefixed('root').diagnostic, e.diagnostic),
            isTrue,
          );
        }
      });
    }
  });
}
