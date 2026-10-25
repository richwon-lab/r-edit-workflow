// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drawing_geometry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DrawingGeometry _$DrawingGeometryFromJson(Map<String, dynamic> json) =>
    DrawingGeometry(
      coordinateSpace: _readCoordinateSpace(json['coordinateSpace']),
      paths: _readDrawingPaths(json['paths']),
      boundaries: _readDrawingBoundaries(json['boundaries']),
    );

Map<String, dynamic> _$DrawingGeometryToJson(DrawingGeometry instance) =>
    <String, dynamic>{
      'coordinateSpace': _writeCoordinateSpace(instance.coordinateSpace),
      'paths': _writeDrawingPaths(instance.paths),
      'boundaries': _writeDrawingBoundaries(instance.boundaries),
    };
