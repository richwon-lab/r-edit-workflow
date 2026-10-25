// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geometry_path.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeometryPath _$GeometryPathFromJson(Map<String, dynamic> json) => GeometryPath(
  start: _readPathStart(json['start']),
  segments: _readPathSegments(json['segments']),
);

Map<String, dynamic> _$GeometryPathToJson(GeometryPath instance) =>
    <String, dynamic>{
      'start': writeGeometryPoint(instance.start),
      'segments': _writePathSegments(instance.segments),
    };
