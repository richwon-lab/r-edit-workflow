// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cutout_definition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CutoutDefinition _$CutoutDefinitionFromJson(Map<String, dynamic> json) =>
    CutoutDefinition(
      cutoutId: json['cutoutId'] as String,
      boundary: _readCutoutBoundary(json['boundary']),
    );

Map<String, dynamic> _$CutoutDefinitionToJson(CutoutDefinition instance) =>
    <String, dynamic>{
      'cutoutId': instance.cutoutId,
      'boundary': writeBoundary(instance.boundary),
    };
