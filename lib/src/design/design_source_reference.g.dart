// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'design_source_reference.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DesignSourceReference _$DesignSourceReferenceFromJson(
  Map<String, dynamic> json,
) => DesignSourceReference(
  sourceDesignId: json['sourceDesignId'] as String,
  sourceRevision: json['sourceRevision'] as String?,
);

Map<String, dynamic> _$DesignSourceReferenceToJson(
  DesignSourceReference instance,
) => <String, dynamic>{
  'sourceDesignId': instance.sourceDesignId,
  'sourceRevision': ?instance.sourceRevision,
};
