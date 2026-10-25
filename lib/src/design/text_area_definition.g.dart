// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'text_area_definition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TextAreaDefinition _$TextAreaDefinitionFromJson(Map<String, dynamic> json) =>
    TextAreaDefinition(
      areaId: json['areaId'] as String,
      label: json['label'] as String,
      region: _readTextRegion(json['region']),
    );

Map<String, dynamic> _$TextAreaDefinitionToJson(TextAreaDefinition instance) =>
    <String, dynamic>{
      'areaId': instance.areaId,
      'label': instance.label,
      'region': _writeTextRegion(instance.region),
    };
