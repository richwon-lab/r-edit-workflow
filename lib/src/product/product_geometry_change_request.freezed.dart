// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_geometry_change_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReviseAppliedGeometry {


/// Create a copy of ReviseAppliedGeometry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReviseAppliedGeometryCopyWith<ReviseAppliedGeometry> get copyWith => _$ReviseAppliedGeometryCopyWithImpl<ReviseAppliedGeometry>(this as ReviseAppliedGeometry, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ReviseAppliedGeometry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReviseAppliedGeometry&&(identical(other.sourceAppliedGeometryId, _this.sourceAppliedGeometryId) || other.sourceAppliedGeometryId == _this.sourceAppliedGeometryId)&&(identical(other.proposedGeometry, _this.proposedGeometry) || other.proposedGeometry == _this.proposedGeometry)&&const DeepCollectionEquality().equals(other.targets, _this.targets));
}


@override
int get hashCode {
  final _this = this as ReviseAppliedGeometry;
  return Object.hash(runtimeType,_this.sourceAppliedGeometryId,_this.proposedGeometry,const DeepCollectionEquality().hash(_this.targets));
}

@override
String toString() {
  final _this = this as ReviseAppliedGeometry;
  return 'ReviseAppliedGeometry(sourceAppliedGeometryId: ${_this.sourceAppliedGeometryId}, proposedGeometry: ${_this.proposedGeometry}, targets: ${_this.targets})';
}


}

/// @nodoc
abstract mixin class $ReviseAppliedGeometryCopyWith<$Res>  {
  factory $ReviseAppliedGeometryCopyWith(ReviseAppliedGeometry value, $Res Function(ReviseAppliedGeometry) _then) = _$ReviseAppliedGeometryCopyWithImpl;
@useResult
$Res call({
 String sourceAppliedGeometryId, AppliedDesignGeometry proposedGeometry, List<ProductGeometryTarget> targets
});




}
/// @nodoc
class _$ReviseAppliedGeometryCopyWithImpl<$Res>
    implements $ReviseAppliedGeometryCopyWith<$Res> {
  _$ReviseAppliedGeometryCopyWithImpl(this._self, this._then);

  final ReviseAppliedGeometry _self;
  final $Res Function(ReviseAppliedGeometry) _then;

/// Create a copy of ReviseAppliedGeometry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sourceAppliedGeometryId = null,Object? proposedGeometry = null,Object? targets = null,}) {
  return _then(ReviseAppliedGeometry(
sourceAppliedGeometryId: null == sourceAppliedGeometryId ? _self.sourceAppliedGeometryId : sourceAppliedGeometryId // ignore: cast_nullable_to_non_nullable
as String,proposedGeometry: null == proposedGeometry ? _self.proposedGeometry : proposedGeometry // ignore: cast_nullable_to_non_nullable
as AppliedDesignGeometry,targets: null == targets ? _self.targets : targets // ignore: cast_nullable_to_non_nullable
as List<ProductGeometryTarget>,
  ));
}

}



/// @nodoc
mixin _$ReplaceAppliedGeometry {


/// Create a copy of ReplaceAppliedGeometry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReplaceAppliedGeometryCopyWith<ReplaceAppliedGeometry> get copyWith => _$ReplaceAppliedGeometryCopyWithImpl<ReplaceAppliedGeometry>(this as ReplaceAppliedGeometry, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ReplaceAppliedGeometry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReplaceAppliedGeometry&&(identical(other.proposedGeometry, _this.proposedGeometry) || other.proposedGeometry == _this.proposedGeometry)&&const DeepCollectionEquality().equals(other.targets, _this.targets));
}


@override
int get hashCode {
  final _this = this as ReplaceAppliedGeometry;
  return Object.hash(runtimeType,_this.proposedGeometry,const DeepCollectionEquality().hash(_this.targets));
}

@override
String toString() {
  final _this = this as ReplaceAppliedGeometry;
  return 'ReplaceAppliedGeometry(proposedGeometry: ${_this.proposedGeometry}, targets: ${_this.targets})';
}


}

/// @nodoc
abstract mixin class $ReplaceAppliedGeometryCopyWith<$Res>  {
  factory $ReplaceAppliedGeometryCopyWith(ReplaceAppliedGeometry value, $Res Function(ReplaceAppliedGeometry) _then) = _$ReplaceAppliedGeometryCopyWithImpl;
@useResult
$Res call({
 AppliedDesignGeometry proposedGeometry, List<ProductGeometryTarget> targets
});




}
/// @nodoc
class _$ReplaceAppliedGeometryCopyWithImpl<$Res>
    implements $ReplaceAppliedGeometryCopyWith<$Res> {
  _$ReplaceAppliedGeometryCopyWithImpl(this._self, this._then);

  final ReplaceAppliedGeometry _self;
  final $Res Function(ReplaceAppliedGeometry) _then;

/// Create a copy of ReplaceAppliedGeometry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? proposedGeometry = null,Object? targets = null,}) {
  return _then(ReplaceAppliedGeometry(
proposedGeometry: null == proposedGeometry ? _self.proposedGeometry : proposedGeometry // ignore: cast_nullable_to_non_nullable
as AppliedDesignGeometry,targets: null == targets ? _self.targets : targets // ignore: cast_nullable_to_non_nullable
as List<ProductGeometryTarget>,
  ));
}

}



// dart format on
