// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'text_area_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpecifiedLineBreak _$SpecifiedLineBreakFromJson(Map<String, dynamic> json) =>
    SpecifiedLineBreak(
      (json['lines'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$SpecifiedLineBreakToJson(SpecifiedLineBreak instance) =>
    <String, dynamic>{'lines': _linesToJson(instance.lines)};

TextAreaInput _$TextAreaInputFromJson(Map<String, dynamic> json) =>
    TextAreaInput(
      areaId: json['areaId'] as String,
      sourceText: json['sourceText'] as String,
      lineBreak: _lineBreakFromJson(json['lineBreak']),
    );

Map<String, dynamic> _$TextAreaInputToJson(TextAreaInput instance) =>
    <String, dynamic>{
      'areaId': instance.areaId,
      'sourceText': instance.sourceText,
      'lineBreak': _lineBreakToJson(instance.lineBreak),
    };
