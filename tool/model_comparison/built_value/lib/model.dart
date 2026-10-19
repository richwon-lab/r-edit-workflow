import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';

import 'validation.dart';

part 'model.g.dart';

abstract class TrialArea implements Built<TrialArea, TrialAreaBuilder> {
  String get areaId;
  String get sourceText;
  TrialBreak get lineBreak;
  TrialArea._();
  factory TrialArea([void Function(TrialAreaBuilder)? updates]) = _$TrialArea;

  // build/rebuild와 생성된 역직렬화가 값을 확정하기 전에 실행한다.
  @BuiltValueHook(finalizeBuilder: true)
  static void validate(TrialAreaBuilder builder) {
    final spec = builder.lineBreak.build();
    validateArea(builder.areaId, builder.sourceText, spec.mode, spec.lines);
  }

  static Serializer<TrialArea> get serializer => _$trialAreaSerializer;
  factory TrialArea.fromJson(Object? json) =>
      _serializers.deserializeWith(TrialArea.serializer, readArea(json))!;
  Map<String, Object?> toJson() => Map<String, Object?>.from(
    _serializers.serializeWith(TrialArea.serializer, this) as Map,
  );
}

@BuiltValue(nestedBuilders: false)
abstract class TrialBreak implements Built<TrialBreak, TrialBreakBuilder> {
  String get mode;
  BuiltList<String>? get lines;
  TrialBreak._();
  factory TrialBreak([void Function(TrialBreakBuilder)? updates]) =
      _$TrialBreak;
  factory TrialBreak.auto() => TrialBreak((b) => b.mode = 'auto');
  factory TrialBreak.manual(List<String> lines) => TrialBreak(
    (b) => b
      ..mode = 'manual'
      ..lines = BuiltList(lines),
  );

  @BuiltValueHook(finalizeBuilder: true)
  static void validate(TrialBreakBuilder builder) =>
      validateBreak(builder.mode, builder.lines);
  static Serializer<TrialBreak> get serializer => _$trialBreakSerializer;
}

// 공개 JSON의 객체 형태를 유지하기 위한 플러그인이다.
final _serializers =
    (Serializers().toBuilder()
          ..add(TrialArea.serializer)
          ..add(TrialBreak.serializer)
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addPlugin(StandardJsonPlugin()))
        .build();
