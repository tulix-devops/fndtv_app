// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vod_home_list_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

VodHomeListModel _$VodHomeListModelFromJson(Map<String, dynamic> json) {
  return _VodHomeListModel.fromJson(json);
}

/// @nodoc
mixin _$VodHomeListModel {
  @JsonKey(name: 'data')
  Map<String, List<VodModel>> get videos => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $VodHomeListModelCopyWith<VodHomeListModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VodHomeListModelCopyWith<$Res> {
  factory $VodHomeListModelCopyWith(
          VodHomeListModel value, $Res Function(VodHomeListModel) then) =
      _$VodHomeListModelCopyWithImpl<$Res, VodHomeListModel>;
  @useResult
  $Res call({@JsonKey(name: 'data') Map<String, List<VodModel>> videos});
}

/// @nodoc
class _$VodHomeListModelCopyWithImpl<$Res, $Val extends VodHomeListModel>
    implements $VodHomeListModelCopyWith<$Res> {
  _$VodHomeListModelCopyWithImpl(this._value, this._then);

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
              as Map<String, List<VodModel>>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VodHomeListModelImplCopyWith<$Res>
    implements $VodHomeListModelCopyWith<$Res> {
  factory _$$VodHomeListModelImplCopyWith(_$VodHomeListModelImpl value,
          $Res Function(_$VodHomeListModelImpl) then) =
      __$$VodHomeListModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'data') Map<String, List<VodModel>> videos});
}

/// @nodoc
class __$$VodHomeListModelImplCopyWithImpl<$Res>
    extends _$VodHomeListModelCopyWithImpl<$Res, _$VodHomeListModelImpl>
    implements _$$VodHomeListModelImplCopyWith<$Res> {
  __$$VodHomeListModelImplCopyWithImpl(_$VodHomeListModelImpl _value,
      $Res Function(_$VodHomeListModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? videos = null,
  }) {
    return _then(_$VodHomeListModelImpl(
      videos: null == videos
          ? _value._videos
          : videos // ignore: cast_nullable_to_non_nullable
              as Map<String, List<VodModel>>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VodHomeListModelImpl implements _VodHomeListModel {
  const _$VodHomeListModelImpl(
      {@JsonKey(name: 'data')
      required final Map<String, List<VodModel>> videos})
      : _videos = videos;

  factory _$VodHomeListModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$VodHomeListModelImplFromJson(json);

  final Map<String, List<VodModel>> _videos;
  @override
  @JsonKey(name: 'data')
  Map<String, List<VodModel>> get videos {
    if (_videos is EqualUnmodifiableMapView) return _videos;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_videos);
  }

  @override
  String toString() {
    return 'VodHomeListModel(videos: $videos)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VodHomeListModelImpl &&
            const DeepCollectionEquality().equals(other._videos, _videos));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_videos));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$VodHomeListModelImplCopyWith<_$VodHomeListModelImpl> get copyWith =>
      __$$VodHomeListModelImplCopyWithImpl<_$VodHomeListModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VodHomeListModelImplToJson(
      this,
    );
  }
}

abstract class _VodHomeListModel implements VodHomeListModel {
  const factory _VodHomeListModel(
          {@JsonKey(name: 'data')
          required final Map<String, List<VodModel>> videos}) =
      _$VodHomeListModelImpl;

  factory _VodHomeListModel.fromJson(Map<String, dynamic> json) =
      _$VodHomeListModelImpl.fromJson;

  @override
  @JsonKey(name: 'data')
  Map<String, List<VodModel>> get videos;
  @override
  @JsonKey(ignore: true)
  _$$VodHomeListModelImplCopyWith<_$VodHomeListModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
