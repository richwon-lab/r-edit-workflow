// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'applied_design_geometry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppliedDesignGeometry _$AppliedDesignGeometryFromJson(
  Map<String, dynamic> json,
) => AppliedDesignGeometry(
  appliedGeometryId: json['appliedGeometryId'] as String,
  geometry: _readGeometry(json['geometry']),
  source: _readSource(json['source']),
);

Map<String, dynamic> _$AppliedDesignGeometryToJson(
  AppliedDesignGeometry instance,
) => <String, dynamic>{
  'appliedGeometryId': instance.appliedGeometryId,
  'geometry': _writeGeometry(instance.geometry),
  'source': ?_writeSource(instance.source),
};
