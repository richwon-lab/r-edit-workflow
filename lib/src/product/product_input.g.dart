// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductInput _$ProductInputFromJson(Map<String, dynamic> json) => ProductInput(
  productId: json['productId'] as String,
  appliedGeometryId: json['appliedGeometryId'] as String,
  textInputs: _readTextInputs(json['textInputs']),
);

Map<String, dynamic> _$ProductInputToJson(ProductInput instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'appliedGeometryId': instance.appliedGeometryId,
      'textInputs': _writeTextInputs(instance.textInputs),
    };
