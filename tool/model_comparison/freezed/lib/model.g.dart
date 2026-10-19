// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrialArea _$TrialAreaFromJson(Map<String, dynamic> json) => TrialArea(
  areaId: json['areaId'] as String,
  sourceText: json['sourceText'] as String,
  lineBreak: TrialBreak.fromJson(json['lineBreak']),
);

Map<String, dynamic> _$TrialAreaToJson(TrialArea instance) => <String, dynamic>{
  'areaId': instance.areaId,
  'sourceText': instance.sourceText,
  'lineBreak': instance.lineBreak.toJson(),
};

TrialBreak _$TrialBreakFromJson(Map<String, dynamic> json) => TrialBreak(
  mode: json['mode'] as String,
  lines: (json['lines'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$TrialBreakToJson(TrialBreak instance) =>
    <String, dynamic>{'mode': instance.mode, 'lines': ?instance.lines};
