// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_design_configuration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductDesignConfiguration _$ProductDesignConfigurationFromJson(
  Map<String, dynamic> json,
) => ProductDesignConfiguration(
  appliedGeometries: _readAppliedGeometries(json['appliedGeometries']),
  products: _readProducts(json['products']),
);

Map<String, dynamic> _$ProductDesignConfigurationToJson(
  ProductDesignConfiguration instance,
) => <String, dynamic>{
  'appliedGeometries': _writeAppliedGeometries(instance.appliedGeometries),
  'products': _writeProducts(instance.products),
};
