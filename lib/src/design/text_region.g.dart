// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'text_region.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TextRegion _$TextRegionFromJson(Map<String, dynamic> json) => TextRegion(
  outer: _readRegionOuter(json['outer']),
  exclusions: _readExclusions(json['exclusions']),
);

Map<String, dynamic> _$TextRegionToJson(TextRegion instance) =>
    <String, dynamic>{
      'outer': writeBoundary(instance.outer),
      'exclusions': _writeBoundaries(instance.exclusions),
    };
