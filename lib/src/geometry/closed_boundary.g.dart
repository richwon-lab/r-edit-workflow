// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'closed_boundary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CircleBoundary _$CircleBoundaryFromJson(Map<String, dynamic> json) =>
    CircleBoundary(
      center: _readCircleCenter(json['center']),
      radius: (json['radius'] as num).toDouble(),
    );

Map<String, dynamic> _$CircleBoundaryToJson(CircleBoundary instance) =>
    <String, dynamic>{
      'center': writeGeometryPoint(instance.center),
      'radius': instance.radius,
    };

PathBoundary _$PathBoundaryFromJson(Map<String, dynamic> json) =>
    PathBoundary(path: _readBoundaryPath(json['path']));

Map<String, dynamic> _$PathBoundaryToJson(PathBoundary instance) =>
    <String, dynamic>{'path': _writeBoundaryPath(instance.path)};
