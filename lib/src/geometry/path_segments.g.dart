// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'path_segments.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LineTo _$LineToFromJson(Map<String, dynamic> json) =>
    LineTo(end: _readSegmentEnd(json['end']));

Map<String, dynamic> _$LineToToJson(LineTo instance) => <String, dynamic>{
  'end': writeGeometryPoint(instance.end),
};

ArcTo _$ArcToFromJson(Map<String, dynamic> json) => ArcTo(
  end: _readSegmentEnd(json['end']),
  bulge: (json['bulge'] as num).toDouble(),
);

Map<String, dynamic> _$ArcToToJson(ArcTo instance) => <String, dynamic>{
  'end': writeGeometryPoint(instance.end),
  'bulge': instance.bulge,
};
