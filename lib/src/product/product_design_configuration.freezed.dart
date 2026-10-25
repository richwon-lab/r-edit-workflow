// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_design_configuration.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductDesignConfiguration {


/// Create a copy of ProductDesignConfiguration
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductDesignConfigurationCopyWith<ProductDesignConfiguration> get copyWith => _$ProductDesignConfigurationCopyWithImpl<ProductDesignConfiguration>(this as ProductDesignConfiguration, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ProductDesignConfiguration;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductDesignConfiguration&&const DeepCollectionEquality().equals(other.appliedGeometries, _this.appliedGeometries)&&const DeepCollectionEquality().equals(other.products, _this.products));
}


@override
int get hashCode {
  final _this = this as ProductDesignConfiguration;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.appliedGeometries),const DeepCollectionEquality().hash(_this.products));
}

@override
String toString() {
  final _this = this as ProductDesignConfiguration;
  return 'ProductDesignConfiguration(appliedGeometries: ${_this.appliedGeometries}, products: ${_this.products})';
}


}

/// @nodoc
abstract mixin class $ProductDesignConfigurationCopyWith<$Res>  {
  factory $ProductDesignConfigurationCopyWith(ProductDesignConfiguration value, $Res Function(ProductDesignConfiguration) _then) = _$ProductDesignConfigurationCopyWithImpl;
@useResult
$Res call({
 List<AppliedDesignGeometry> appliedGeometries, List<ProductInput> products
});




}
/// @nodoc
class _$ProductDesignConfigurationCopyWithImpl<$Res>
    implements $ProductDesignConfigurationCopyWith<$Res> {
  _$ProductDesignConfigurationCopyWithImpl(this._self, this._then);

  final ProductDesignConfiguration _self;
  final $Res Function(ProductDesignConfiguration) _then;

/// Create a copy of ProductDesignConfiguration
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appliedGeometries = null,Object? products = null,}) {
  return _then(ProductDesignConfiguration(
appliedGeometries: null == appliedGeometries ? _self.appliedGeometries : appliedGeometries // ignore: cast_nullable_to_non_nullable
as List<AppliedDesignGeometry>,products: null == products ? _self.products : products // ignore: cast_nullable_to_non_nullable
as List<ProductInput>,
  ));
}

}



// dart format on
