import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/geometry_builders.dart' show pointAtCoordinates;
import '../support/design_builders.dart'
    show
        circleCenteredAt2,
        rectangularBoundary4By2,
        slotBoundaryFrom1To3,
        textAreaWithCircularRegion,
        inchDesignWithIrregularOutline,
        designJsonThroughString,
        designError;

void main() {
  group('DesignGeometry의 소유권과 전체 환산', () {
    {
      test('비정형 외곽과 원형·사각형·장공 구멍을 같은 경계 타입으로 구성하고 왕복한다', () {
        final cutouts = [
          CutoutDefinition(cutoutId: 'circle', boundary: circleCenteredAt2()),
          CutoutDefinition(
            cutoutId: 'rectangle',
            boundary: rectangularBoundary4By2(),
          ),
          CutoutDefinition(cutoutId: 'slot', boundary: slotBoundaryFrom1To3()),
        ];
        final original = inchDesignWithIrregularOutline(
          cutouts: cutouts,
          areas: [
            textAreaWithCircularRegion(
              'rect',
              outer: rectangularBoundary4By2(),
            ),
            textAreaWithCircularRegion(
              'round',
              outer: circleCenteredAt2(10),
              exclusions: [slotBoundaryFrom1To3()],
            ),
          ],
        );
        final restored = DesignGeometry.fromJson(
          designJsonThroughString(original.toJson()),
        );
        expect(restored, original);
        expect(restored.hashCode, original.hashCode);
        expect(restored.cutouts.map((c) => c.cutoutId), [
          'circle',
          'rectangle',
          'slot',
        ]);
        expect(
          restored.textAreas[1].region.exclusions.single,
          slotBoundaryFrom1To3(),
        );
        expect(
          original.toJson().keys,
          unorderedEquals([
            'coordinateSpace',
            'outline',
            'cutouts',
            'textAreas',
          ]),
        );
      });
    }

    {
      test('영역·홀 겹침과 영역 밖 제외 경계를 보정하지 않는다', () {
        final boundary = circleCenteredAt2();
        final outside = CircleBoundary(
          center: pointAtCoordinates(-100, -100),
          radius: 2,
        );
        final original = inchDesignWithIrregularOutline(
          cutouts: [CutoutDefinition(cutoutId: 'h', boundary: boundary)],
          areas: [
            textAreaWithCircularRegion(
              'a',
              outer: boundary,
              exclusions: [outside],
            ),
            textAreaWithCircularRegion('b', outer: boundary),
          ],
        );
        expect(
          original.textAreas.first.region.outer,
          original.cutouts.single.boundary,
        );
        expect(original.textAreas.first.region.exclusions, [outside]);
        final without = original.copyWith(cutouts: []);
        expect(without.textAreas, original.textAreas);
        expect(without.textAreas.first.region.exclusions, [outside]);
      });
    }

    {
      test('구성·영역 copyWith의 수정 전 값을 보존하고 중첩 목록도 방어 복사한다', () {
        final holes = [
          CutoutDefinition(cutoutId: 'h', boundary: circleCenteredAt2()),
        ];
        final excluded = <ClosedBoundary>[slotBoundaryFrom1To3()];
        final areas = [textAreaWithCircularRegion('a', exclusions: excluded)];
        final original = inchDesignWithIrregularOutline(
          cutouts: holes,
          areas: areas,
        );
        holes.clear();
        excluded.clear();
        areas.clear();
        expect(original.cutouts, hasLength(1));
        expect(original.textAreas.single.region.exclusions, [
          slotBoundaryFrom1To3(),
        ]);
        expect(() => original.cutouts.clear(), throwsUnsupportedError);
        expect(() => original.textAreas.clear(), throwsUnsupportedError);
        expect(
          () => original.textAreas.single.region.exclusions.clear(),
          throwsUnsupportedError,
        );
        final replacements = <ClosedBoundary>[rectangularBoundary4By2()];
        final changed = original.textAreas.single.copyWith.region(
          exclusions: replacements,
        );
        replacements.clear();
        expect(changed.region.exclusions, [rectangularBoundary4By2()]);
        expect(original.textAreas.single.region.exclusions, [
          slotBoundaryFrom1To3(),
        ]);
        final nextAreas = [changed];
        final next = original.copyWith(textAreas: nextAreas);
        nextAreas.clear();
        expect(next.textAreas.single, changed);
        expect(original.textAreas.single.region.exclusions, [
          slotBoundaryFrom1To3(),
        ]);
        expect(next.coordinateSpace, original.coordinateSpace);
      });
    }

    {
      test('반환 JSON과 복원에 사용한 목록/Map의 외부 변경으로 도안을 바꿀 수 없다', () {
        final original = inchDesignWithIrregularOutline(
          cutouts: [
            CutoutDefinition(cutoutId: 'h', boundary: circleCenteredAt2()),
          ],
          areas: [
            textAreaWithCircularRegion('a', exclusions: [circleCenteredAt2()]),
          ],
        );
        final json = original.toJson();
        final restored = DesignGeometry.fromJson(json);
        (json['coordinateSpace'] as Map)['lengthUnit'] = 'unknown';
        ((json['outline'] as Map)['path'] as Map)['start'] = {
          'x': 999,
          'y': 999,
        };
        final areas = json['textAreas'] as List;
        final first = areas.single as Map;
        first['label'] = 'changed';
        final region = first['region'] as Map;
        (region['outer'] as Map)['radius'] = 999;
        (region['exclusions'] as List).clear();
        areas.clear();
        final cutouts = json['cutouts'] as List;
        (cutouts.single as Map)['cutoutId'] = 'changed';
        cutouts.clear();
        expect(restored, original);
        expect(
          DesignGeometry.fromJson(designJsonThroughString(original.toJson())),
          original,
        );
      });
    }

    {
      test('단위 환산은 외곽·모든 구멍·영역 외부/제외 경계를 함께 바꾸고 식별 문자열을 보존한다', () {
        final original = inchDesignWithIrregularOutline(
          cutouts: [
            CutoutDefinition(cutoutId: 'h1', boundary: circleCenteredAt2()),
            CutoutDefinition(
              cutoutId: 'h2',
              boundary: rectangularBoundary4By2(),
            ),
            CutoutDefinition(cutoutId: 'h3', boundary: slotBoundaryFrom1To3()),
          ],
          areas: [
            textAreaWithCircularRegion(
              'a',
              label: '  e\u0301  ',
              outer: rectangularBoundary4By2(),
              exclusions: [circleCenteredAt2(), slotBoundaryFrom1To3()],
            ),
            textAreaWithCircularRegion('b', outer: circleCenteredAt2(10)),
          ],
        );
        final mm = original.convertedTo(LengthUnit.millimeter);
        expect(mm.coordinateSpace.lengthUnit, LengthUnit.millimeter);
        expect(
          (mm.outline as PathBoundary).path.start,
          pointAtCoordinates(-25.4, -25.4),
        );
        expect(
          (mm.cutouts[0].boundary as CircleBoundary).center,
          pointAtCoordinates(50.8, 50.8),
        );
        expect((mm.cutouts[0].boundary as CircleBoundary).radius, 25.4);
        expect(
          (mm.cutouts[1].boundary as PathBoundary).path.segments.first.end,
          pointAtCoordinates(101.6, 0),
        );
        final slotPath = (mm.cutouts[2].boundary as PathBoundary).path;
        expect(slotPath.start, pointAtCoordinates(25.4, 25.4));
        expect((slotPath.segments[1] as ArcTo).bulge, 1);
        expect(
          (mm.textAreas[0].region.outer as PathBoundary).path.segments[1].end,
          pointAtCoordinates(101.6, 50.8),
        );
        expect(
          (mm.textAreas[0].region.exclusions[0] as CircleBoundary).radius,
          25.4,
        );
        expect(
          (mm.textAreas[0].region.exclusions[1] as PathBoundary).path.start,
          pointAtCoordinates(25.4, 25.4),
        );
        expect((mm.textAreas[1].region.outer as CircleBoundary).radius, 254);
        expect(mm.cutouts.map((h) => h.cutoutId), ['h1', 'h2', 'h3']);
        expect(mm.textAreas[0].label, '  e\u0301  ');
        expect(mm.textAreas[0].areaId, 'a');
        expect(original.coordinateSpace.lengthUnit, LengthUnit.inch);
        expect((original.cutouts[0].boundary as CircleBoundary).radius, 1);
        expect(
          DesignGeometry.fromJson(designJsonThroughString(mm.toJson())),
          mm,
        );
      });
    }

    {
      test('환산 실패의 하위 기하 원인과 위치를 보존하고 원래 값은 유지한다', () {
        final huge = CircleBoundary(
          center: pointAtCoordinates(0, 0),
          radius: double.maxFinite,
        );
        final original = inchDesignWithIrregularOutline(
          areas: [
            textAreaWithCircularRegion('a', exclusions: [huge]),
          ],
        );
        try {
          original.convertedTo(LengthUnit.millimeter);
          fail('수치 실패 누락');
        } on GeometryValidationException catch (e) {
          expect(e.fieldPath, 'textAreas[0].region.exclusions[0].radius');
          expect(e.code, GeometryErrorCode.numericRepresentationFailure);
          expect(e.diagnostic.operation, 'convertLength:inch->millimeter');
          expect(
            (e.diagnostic.details as GeometryNumberDetails).value,
            double.maxFinite,
          );
        }
        expect(original.textAreas.single.region.exclusions.single, huge);
      });
    }

    {
      final h = CutoutDefinition(
        cutoutId: 'same',
        boundary: circleCenteredAt2(),
      );
      final a = textAreaWithCircularRegion('same');
      final original = inchDesignWithIrregularOutline(cutouts: [h], areas: [a]);
      var caseIndex = 0;
      for (final run in <void Function()>[
        () => inchDesignWithIrregularOutline(
          cutouts: [
            h,
            h.copyWith(boundary: slotBoundaryFrom1To3()),
          ],
        ),
        () => original.copyWith(cutouts: [h, h]),
        () => DesignGeometry.fromJson({
          ...original.toJson(),
          'cutouts': [h.toJson(), h.toJson()],
        }),
      ]) {
        final path = ['생성', '수정', 'JSON 복원'][caseIndex++];
        test('관통 구멍 $path에서 소유 ID 중복을 거부한다', () {
          expect(
            run,
            designError(
              DesignErrorCode.duplicateCutoutId,
              'cutouts[1].cutoutId',
            ),
          );
        });
      }
    }

    {
      final h = CutoutDefinition(
        cutoutId: 'same',
        boundary: circleCenteredAt2(),
      );
      final a = textAreaWithCircularRegion('same');
      final original = inchDesignWithIrregularOutline(cutouts: [h], areas: [a]);
      var caseIndex = 0;
      for (final run in <void Function()>[
        () => inchDesignWithIrregularOutline(
          areas: [
            a,
            a.copyWith(label: '다른 이름'),
          ],
        ),
        () => original.copyWith(textAreas: [a, a]),
        () => DesignGeometry.fromJson({
          ...original.toJson(),
          'textAreas': [a.toJson(), a.toJson()],
        }),
      ]) {
        final path = ['생성', '수정', 'JSON 복원'][caseIndex++];
        test('텍스트 영역 $path에서 소유 ID 중복을 거부한다', () {
          expect(
            run,
            designError(DesignErrorCode.duplicateAreaId, 'textAreas[1].areaId'),
          );
        });
      }
    }

    {
      test('중첩 JSON에서 빈 영역 ID의 전체 경로를 제공한다', () {
        expect(
          () => DesignGeometry.fromJson({
            ...inchDesignWithIrregularOutline().toJson(),
            'textAreas': [
              {
                'areaId': '',
                'label': '',
                'region': textAreaWithCircularRegion('a').region.toJson(),
              },
            ],
          }),
          designError(DesignErrorCode.emptyAreaId, 'textAreas[0].areaId'),
        );
      });
    }

    {
      test('영역 없는 도안 JSON을 빈 영역 목록으로 복원한다', () {
        expect(
          DesignGeometry.fromJson(
            designJsonThroughString(inchDesignWithIrregularOutline().toJson()),
          ).textAreas,
          isEmpty,
        );
      });
    }

    {
      final json = inchDesignWithIrregularOutline().toJson();
      for (final key in json.keys) {
        test('DesignGeometry JSON에서 $key 누락을 보정하지 않는다', () {
          final missing = Map<String, Object?>.of(json)..remove(key);
          expect(
            () => DesignGeometry.fromJson(missing),
            designError(DesignErrorCode.missingField, key),
          );
        });
      }
      test('DesignGeometry JSON의 최상위 목록을 거부한다', () {
        expect(
          () => DesignGeometry.fromJson([]),
          designError(DesignErrorCode.invalidType, r'$'),
        );
      });
      test('DesignGeometry JSON의 알 수 없는 필드를 거부한다', () {
        expect(
          () => DesignGeometry.fromJson({...json, 'extra': true}),
          designError(DesignErrorCode.unexpectedField, 'extra'),
        );
      });
    }
  });
}
