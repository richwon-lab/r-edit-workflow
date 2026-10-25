// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'design_geometry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DesignGeometry _$DesignGeometryFromJson(Map<String, dynamic> json) =>
    DesignGeometry(
      coordinateSpace: _readDesignSpace(json['coordinateSpace']),
      outline: _readOutline(json['outline']),
      cutouts: _readCutouts(json['cutouts']),
      textAreas: _readTextAreas(json['textAreas']),
    );

Map<String, dynamic> _$DesignGeometryToJson(DesignGeometry instance) =>
    <String, dynamic>{
      'coordinateSpace': _writeDesignSpace(instance.coordinateSpace),
      'outline': _writeBoundary(instance.outline),
      'cutouts': _writeCutouts(instance.cutouts),
      'textAreas': _writeTextAreas(instance.textAreas),
    };

CutoutDefinition _$CutoutDefinitionFromJson(Map<String, dynamic> json) =>
    CutoutDefinition(
      cutoutId: json['cutoutId'] as String,
      boundary: _readCutoutBoundary(json['boundary']),
    );

Map<String, dynamic> _$CutoutDefinitionToJson(CutoutDefinition instance) =>
    <String, dynamic>{
      'cutoutId': instance.cutoutId,
      'boundary': _writeBoundary(instance.boundary),
    };

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

TextRegion _$TextRegionFromJson(Map<String, dynamic> json) => TextRegion(
  outer: _readRegionOuter(json['outer']),
  exclusions: _readExclusions(json['exclusions']),
);

Map<String, dynamic> _$TextRegionToJson(TextRegion instance) =>
    <String, dynamic>{
      'outer': _writeBoundary(instance.outer),
      'exclusions': _writeBoundaries(instance.exclusions),
    };
