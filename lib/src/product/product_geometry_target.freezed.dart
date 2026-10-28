// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_geometry_target.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductGeometryTarget {


/// Create a copy of ProductGeometryTarget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductGeometryTargetCopyWith<ProductGeometryTarget> get copyWith => _$ProductGeometryTargetCopyWithImpl<ProductGeometryTarget>(this as ProductGeometryTarget, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ProductGeometryTarget;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductGeometryTarget&&(identical(other.productId, _this.productId) || other.productId == _this.productId)&&const DeepCollectionEquality().equals(other.areaMappings, _this.areaMappings)&&const DeepCollectionEquality().equals(other.newTextInputs, _this.newTextInputs)&&const DeepCollectionEquality().equals(other.removedInputAreaIds, _this.removedInputAreaIds));
}


@override
int get hashCode {
  final _this = this as ProductGeometryTarget;
  return Object.hash(runtimeType,_this.productId,const DeepCollectionEquality().hash(_this.areaMappings),const DeepCollectionEquality().hash(_this.newTextInputs),const DeepCollectionEquality().hash(_this.removedInputAreaIds));
}

@override
String toString() {
  final _this = this as ProductGeometryTarget;
  return 'ProductGeometryTarget(productId: ${_this.productId}, areaMappings: ${_this.areaMappings}, newTextInputs: ${_this.newTextInputs}, removedInputAreaIds: ${_this.removedInputAreaIds})';
}


}

/// @nodoc
abstract mixin class $ProductGeometryTargetCopyWith<$Res>  {
  factory $ProductGeometryTargetCopyWith(ProductGeometryTarget value, $Res Function(ProductGeometryTarget) _then) = _$ProductGeometryTargetCopyWithImpl;
@useResult
$Res call({
 String productId, List<TextAreaInputMapping> areaMappings, List<TextAreaInput> newTextInputs, List<String> removedInputAreaIds
});




}
/// @nodoc
class _$ProductGeometryTargetCopyWithImpl<$Res>
    implements $ProductGeometryTargetCopyWith<$Res> {
  _$ProductGeometryTargetCopyWithImpl(this._self, this._then);

  final ProductGeometryTarget _self;
  final $Res Function(ProductGeometryTarget) _then;

/// Create a copy of ProductGeometryTarget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = null,Object? areaMappings = null,Object? newTextInputs = null,Object? removedInputAreaIds = null,}) {
  return _then(ProductGeometryTarget(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,areaMappings: null == areaMappings ? _self.areaMappings : areaMappings // ignore: cast_nullable_to_non_nullable
as List<TextAreaInputMapping>,newTextInputs: null == newTextInputs ? _self.newTextInputs : newTextInputs // ignore: cast_nullable_to_non_nullable
as List<TextAreaInput>,removedInputAreaIds: null == removedInputAreaIds ? _self.removedInputAreaIds : removedInputAreaIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}



// dart format on
