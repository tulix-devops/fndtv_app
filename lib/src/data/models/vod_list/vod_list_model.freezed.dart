// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vod_list_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

VodListModel _$VodListModelFromJson(Map<String, dynamic> json) {
  return _VodListModel.fromJson(json);
}

/// @nodoc
mixin _$VodListModel {
  @JsonKey(name: 'data')
  List<VodModel> get videos => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $VodListModelCopyWith<VodListModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VodListModelCopyWith<$Res> {
  factory $VodListModelCopyWith(
          VodListModel value, $Res Function(VodListModel) then) =
      _$VodListModelCopyWithImpl<$Res, VodListModel>;
  @useResult
  $Res call({@JsonKey(name: 'data') List<VodModel> videos});
}

/// @nodoc
class _$VodListModelCopyWithImpl<$Res, $Val extends VodListModel>
    implements $VodListModelCopyWith<$Res> {
  _$VodListModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? videos = null,
  }) {
    return _then(_value.copyWith(
      videos: null == videos
          ? _value.videos
          : videos // ignore: cast_nullable_to_non_nullable
              as List<VodModel>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VodListModelImplCopyWith<$Res>
    implements $VodListModelCopyWith<$Res> {
  factory _$$VodListModelImplCopyWith(
          _$VodListModelImpl value, $Res Function(_$VodListModelImpl) then) =
      __$$VodListModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'data') List<VodModel> videos});
}

/// @nodoc
class __$$VodListModelImplCopyWithImpl<$Res>
    extends _$VodListModelCopyWithImpl<$Res, _$VodListModelImpl>
    implements _$$VodListModelImplCopyWith<$Res> {
  __$$VodListModelImplCopyWithImpl(
      _$VodListModelImpl _value, $Res Function(_$VodListModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? videos = null,
  }) {
    return _then(_$VodListModelImpl(
      videos: null == videos
          ? _value._videos
          : videos // ignore: cast_nullable_to_non_nullable
              as List<VodModel>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VodListModelImpl implements _VodListModel {
  const _$VodListModelImpl(
      {@JsonKey(name: 'data') required final List<VodModel> videos})
      : _videos = videos;

  factory _$VodListModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$VodListModelImplFromJson(json);

  final List<VodModel> _videos;
  @override
  @JsonKey(name: 'data')
  List<VodModel> get videos {
    if (_videos is EqualUnmodifiableListView) return _videos;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_videos);
  }

  @override
  String toString() {
    return 'VodListModel(videos: $videos)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VodListModelImpl &&
            const DeepCollectionEquality().equals(other._videos, _videos));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_videos));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$VodListModelImplCopyWith<_$VodListModelImpl> get copyWith =>
      __$$VodListModelImplCopyWithImpl<_$VodListModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VodListModelImplToJson(
      this,
    );
  }
}

abstract class _VodListModel implements VodListModel {
  const factory _VodListModel(
          {@JsonKey(name: 'data') required final List<VodModel> videos}) =
      _$VodListModelImpl;

  factory _VodListModel.fromJson(Map<String, dynamic> json) =
      _$VodListModelImpl.fromJson;

  @override
  @JsonKey(name: 'data')
  List<VodModel> get videos;
  @override
  @JsonKey(ignore: true)
  _$$VodListModelImplCopyWith<_$VodListModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
