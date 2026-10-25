// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geometry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RectangularPlateGeometry _$RectangularPlateGeometryFromJson(
  Map<String, dynamic> json,
) => RectangularPlateGeometry(
  widthMm: (json['widthMm'] as num).toDouble(),
  heightMm: (json['heightMm'] as num).toDouble(),
  holes: _holesFromJson(json['holes']),
);

Map<String, dynamic> _$RectangularPlateGeometryToJson(
  RectangularPlateGeometry instance,
) => <String, dynamic>{
  'widthMm': instance.widthMm,
  'heightMm': instance.heightMm,
  'holes': _holesToJson(instance.holes),
};

CircularHole _$CircularHoleFromJson(Map<String, dynamic> json) => CircularHole(
  holeId: json['holeId'] as String,
  centerXMm: (json['centerXMm'] as num).toDouble(),
  centerYMm: (json['centerYMm'] as num).toDouble(),
  diameterMm: (json['diameterMm'] as num).toDouble(),
);

Map<String, dynamic> _$CircularHoleToJson(CircularHole instance) =>
    <String, dynamic>{
      'holeId': instance.holeId,
      'centerXMm': instance.centerXMm,
      'centerYMm': instance.centerYMm,
      'diameterMm': instance.diameterMm,
    };

TextAreaBounds _$TextAreaBoundsFromJson(Map<String, dynamic> json) =>
    TextAreaBounds(
      xMm: (json['xMm'] as num).toDouble(),
      yMm: (json['yMm'] as num).toDouble(),
      widthMm: (json['widthMm'] as num).toDouble(),
      heightMm: (json['heightMm'] as num).toDouble(),
    );

Map<String, dynamic> _$TextAreaBoundsToJson(TextAreaBounds instance) =>
    <String, dynamic>{
      'xMm': instance.xMm,
      'yMm': instance.yMm,
      'widthMm': instance.widthMm,
      'heightMm': instance.heightMm,
    };

TextAreaDefinition _$TextAreaDefinitionFromJson(Map<String, dynamic> json) =>
    TextAreaDefinition(
      areaId: json['areaId'] as String,
      label: json['label'] as String,
      bounds: _boundsFromJson(json['bounds']),
    );

Map<String, dynamic> _$TextAreaDefinitionToJson(TextAreaDefinition instance) =>
    <String, dynamic>{
      'areaId': instance.areaId,
      'label': instance.label,
      'bounds': _boundsToJson(instance.bounds),
    };
