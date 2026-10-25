// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coordinate_space.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DrawingCoordinateSpace _$DrawingCoordinateSpaceFromJson(
  Map<String, dynamic> json,
) => DrawingCoordinateSpace(
  lengthUnit: $enumDecode(_$LengthUnitEnumMap, json['lengthUnit']),
);

Map<String, dynamic> _$DrawingCoordinateSpaceToJson(
  DrawingCoordinateSpace instance,
) => <String, dynamic>{'lengthUnit': _$LengthUnitEnumMap[instance.lengthUnit]!};

const _$LengthUnitEnumMap = {
  LengthUnit.millimeter: 'millimeter',
  LengthUnit.inch: 'inch',
};
