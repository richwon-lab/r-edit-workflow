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
      'outline': writeBoundary(instance.outline),
      'cutouts': _writeCutouts(instance.cutouts),
      'textAreas': _writeTextAreas(instance.textAreas),
    };
