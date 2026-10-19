// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'text_area_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ManualLineBreak _$ManualLineBreakFromJson(Map<String, dynamic> json) =>
    ManualLineBreak(
      (json['lines'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$ManualLineBreakToJson(ManualLineBreak instance) =>
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
