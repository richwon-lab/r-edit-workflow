// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_input.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductInput {


/// Create a copy of ProductInput
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductInputCopyWith<ProductInput> get copyWith => _$ProductInputCopyWithImpl<ProductInput>(this as ProductInput, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ProductInput;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductInput&&(identical(other.productId, _this.productId) || other.productId == _this.productId)&&(identical(other.appliedGeometryId, _this.appliedGeometryId) || other.appliedGeometryId == _this.appliedGeometryId)&&const DeepCollectionEquality().equals(other.textInputs, _this.textInputs));
}


@override
int get hashCode {
  final _this = this as ProductInput;
  return Object.hash(runtimeType,_this.productId,_this.appliedGeometryId,const DeepCollectionEquality().hash(_this.textInputs));
}

@override
String toString() {
  final _this = this as ProductInput;
  return 'ProductInput(productId: ${_this.productId}, appliedGeometryId: ${_this.appliedGeometryId}, textInputs: ${_this.textInputs})';
}


}

/// @nodoc
abstract mixin class $ProductInputCopyWith<$Res>  {
  factory $ProductInputCopyWith(ProductInput value, $Res Function(ProductInput) _then) = _$ProductInputCopyWithImpl;
@useResult
$Res call({
 String productId, String appliedGeometryId, List<TextAreaInput> textInputs
});




}
/// @nodoc
class _$ProductInputCopyWithImpl<$Res>
    implements $ProductInputCopyWith<$Res> {
  _$ProductInputCopyWithImpl(this._self, this._then);

  final ProductInput _self;
  final $Res Function(ProductInput) _then;

/// Create a copy of ProductInput
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = null,Object? appliedGeometryId = null,Object? textInputs = null,}) {
  return _then(ProductInput(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,appliedGeometryId: null == appliedGeometryId ? _self.appliedGeometryId : appliedGeometryId // ignore: cast_nullable_to_non_nullable
as String,textInputs: null == textInputs ? _self.textInputs : textInputs // ignore: cast_nullable_to_non_nullable
as List<TextAreaInput>,
  ));
}

}



// dart format on
