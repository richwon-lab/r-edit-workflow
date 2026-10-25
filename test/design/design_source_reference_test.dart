import 'dart:convert';

import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/product_examples.dart';

void main() {
  group('DesignSourceReference의 기록과 선택 버전', () {
    for (final json in <Map<String, Object?>>[
      {'sourceDesignId': ' catalog '},
      {'sourceDesignId': ' catalog ', 'sourceRevision': null},
    ]) {
      test('버전 입력 $json은 기록 없음으로 읽고 버전을 생략한다', () {
        final value = DesignSourceReference.fromJson(json);
        expect(value.sourceRevision, isNull);
        expect(value.toJson(), {'sourceDesignId': ' catalog '});
      });
    }
    for (final revision in ['r7', ' v 1 e\u0301 👩‍🔧 ', '   ', 'latest']) {
      test('명시한 버전 "$revision"은 해석·정규화 없이 보존한다', () {
        final expected = {
          'sourceDesignId': 'source',
          'sourceRevision': revision,
        };
        final value = DesignSourceReference(
          sourceDesignId: 'source',
          sourceRevision: revision,
        );
        expect(value.toJson(), expected);
        expect(
          DesignSourceReference.fromJson(jsonDecode(jsonEncode(expected))),
          value,
        );
      });
    }
    for (final route in ['생성', '수정', '복원']) {
      test('$route에서 빈 버전을 거부한다', () {
        final old = DesignSourceReference(
          sourceDesignId: 's',
          sourceRevision: 'r1',
        );
        expect(
          () => switch (route) {
            '생성' => DesignSourceReference(
              sourceDesignId: 's',
              sourceRevision: '',
            ),
            '수정' => old.copyWith(sourceRevision: ''),
            _ => DesignSourceReference.fromJson({
              'sourceDesignId': 's',
              'sourceRevision': '',
            }),
          },
          productFailure(
            ProductDesignErrorCode.emptySourceRevision,
            'sourceRevision',
          ),
        );
        expect(old.sourceRevision, 'r1');
      });
      test('$route에서 빈 공용 원본 ID를 거부한다', () {
        final old = DesignSourceReference(sourceDesignId: 's');
        expect(
          () => switch (route) {
            '생성' => DesignSourceReference(sourceDesignId: ''),
            '수정' => old.copyWith(sourceDesignId: ''),
            _ => DesignSourceReference.fromJson({'sourceDesignId': ''}),
          },
          productFailure(
            ProductDesignErrorCode.emptySourceDesignId,
            'sourceDesignId',
          ),
        );
      });
    }
    test('버전을 null로 수정하면 이전 값을 보존하고 새 JSON에서는 생략한다', () {
      final old = DesignSourceReference(
        sourceDesignId: 's',
        sourceRevision: 'r1',
      );
      final changed = old.copyWith(sourceRevision: null);
      expect(changed.toJson(), {'sourceDesignId': 's'});
      expect(old.sourceRevision, 'r1');
    });
    for (final invalid in [1, true, <Object?>[], <String, Object?>{}]) {
      test('sourceRevision=$invalid의 타입을 거부한다', () {
        expect(
          () => DesignSourceReference.fromJson({
            'sourceDesignId': 's',
            'sourceRevision': invalid,
          }),
          productFailure(ProductDesignErrorCode.invalidType, 'sourceRevision'),
        );
      });
    }
    test('공용 원본 ID 누락과 명시적 null은 다른 원인이다', () {
      expect(
        () => DesignSourceReference.fromJson(<String, Object?>{}),
        productFailure(ProductDesignErrorCode.missingField, 'sourceDesignId'),
      );
      expect(
        () => DesignSourceReference.fromJson({'sourceDesignId': null}),
        productFailure(ProductDesignErrorCode.invalidType, 'sourceDesignId'),
      );
    });
    test('모르는 출처 필드를 버리지 않는다', () {
      expect(
        () =>
            DesignSourceReference.fromJson({'sourceDesignId': 's', 'url': 'x'}),
        productFailure(ProductDesignErrorCode.unexpectedField, 'url'),
      );
    });
  });
}
