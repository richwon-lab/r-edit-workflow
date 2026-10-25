// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'design_source_reference.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DesignSourceReference {


/// Create a copy of DesignSourceReference
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesignSourceReferenceCopyWith<DesignSourceReference> get copyWith => _$DesignSourceReferenceCopyWithImpl<DesignSourceReference>(this as DesignSourceReference, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DesignSourceReference;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignSourceReference&&(identical(other.sourceDesignId, _this.sourceDesignId) || other.sourceDesignId == _this.sourceDesignId)&&(identical(other.sourceRevision, _this.sourceRevision) || other.sourceRevision == _this.sourceRevision));
}


@override
int get hashCode {
  final _this = this as DesignSourceReference;
  return Object.hash(runtimeType,_this.sourceDesignId,_this.sourceRevision);
}

@override
String toString() {
  final _this = this as DesignSourceReference;
  return 'DesignSourceReference(sourceDesignId: ${_this.sourceDesignId}, sourceRevision: ${_this.sourceRevision})';
}


}

/// @nodoc
abstract mixin class $DesignSourceReferenceCopyWith<$Res>  {
  factory $DesignSourceReferenceCopyWith(DesignSourceReference value, $Res Function(DesignSourceReference) _then) = _$DesignSourceReferenceCopyWithImpl;
@useResult
$Res call({
 String sourceDesignId, String? sourceRevision
});




}
/// @nodoc
class _$DesignSourceReferenceCopyWithImpl<$Res>
    implements $DesignSourceReferenceCopyWith<$Res> {
  _$DesignSourceReferenceCopyWithImpl(this._self, this._then);

  final DesignSourceReference _self;
  final $Res Function(DesignSourceReference) _then;

/// Create a copy of DesignSourceReference
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sourceDesignId = null,Object? sourceRevision = freezed,}) {
  return _then(DesignSourceReference(
sourceDesignId: null == sourceDesignId ? _self.sourceDesignId : sourceDesignId // ignore: cast_nullable_to_non_nullable
as String,sourceRevision: freezed == sourceRevision ? _self.sourceRevision : sourceRevision // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}



// dart format on
