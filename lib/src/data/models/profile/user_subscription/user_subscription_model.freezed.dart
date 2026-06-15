// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_subscription_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserSubscriptionModel _$UserSubscriptionModelFromJson(
    Map<String, dynamic> json) {
  return _UserSubscriptionModel.fromJson(json);
}

/// @nodoc
mixin _$UserSubscriptionModel {
  int get id => throw _privateConstructorUsedError;
  int? get status_id => throw _privateConstructorUsedError;
  int? get user_id => throw _privateConstructorUsedError;
  String? get expires_at => throw _privateConstructorUsedError;
  DateTime? get created_at => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserSubscriptionModelCopyWith<UserSubscriptionModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserSubscriptionModelCopyWith<$Res> {
  factory $UserSubscriptionModelCopyWith(UserSubscriptionModel value,
          $Res Function(UserSubscriptionModel) then) =
      _$UserSubscriptionModelCopyWithImpl<$Res, UserSubscriptionModel>;
  @useResult
  $Res call(
      {int id,
      int? status_id,
      int? user_id,
      String? expires_at,
      DateTime? created_at});
}

/// @nodoc
class _$UserSubscriptionModelCopyWithImpl<$Res,
        $Val extends UserSubscriptionModel>
    implements $UserSubscriptionModelCopyWith<$Res> {
  _$UserSubscriptionModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? status_id = freezed,
    Object? user_id = freezed,
    Object? expires_at = freezed,
    Object? created_at = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      status_id: freezed == status_id
          ? _value.status_id
          : status_id // ignore: cast_nullable_to_non_nullable
              as int?,
      user_id: freezed == user_id
          ? _value.user_id
          : user_id // ignore: cast_nullable_to_non_nullable
              as int?,
      expires_at: freezed == expires_at
          ? _value.expires_at
          : expires_at // ignore: cast_nullable_to_non_nullable
              as String?,
      created_at: freezed == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserSubscriptionModelImplCopyWith<$Res>
    implements $UserSubscriptionModelCopyWith<$Res> {
  factory _$$UserSubscriptionModelImplCopyWith(
          _$UserSubscriptionModelImpl value,
          $Res Function(_$UserSubscriptionModelImpl) then) =
      __$$UserSubscriptionModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      int? status_id,
      int? user_id,
      String? expires_at,
      DateTime? created_at});
}

/// @nodoc
class __$$UserSubscriptionModelImplCopyWithImpl<$Res>
    extends _$UserSubscriptionModelCopyWithImpl<$Res,
        _$UserSubscriptionModelImpl>
    implements _$$UserSubscriptionModelImplCopyWith<$Res> {
  __$$UserSubscriptionModelImplCopyWithImpl(_$UserSubscriptionModelImpl _value,
      $Res Function(_$UserSubscriptionModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? status_id = freezed,
    Object? user_id = freezed,
    Object? expires_at = freezed,
    Object? created_at = freezed,
  }) {
    return _then(_$UserSubscriptionModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      status_id: freezed == status_id
          ? _value.status_id
          : status_id // ignore: cast_nullable_to_non_nullable
              as int?,
      user_id: freezed == user_id
          ? _value.user_id
          : user_id // ignore: cast_nullable_to_non_nullable
              as int?,
      expires_at: freezed == expires_at
          ? _value.expires_at
          : expires_at // ignore: cast_nullable_to_non_nullable
              as String?,
      created_at: freezed == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserSubscriptionModelImpl implements _UserSubscriptionModel {
  const _$UserSubscriptionModelImpl(
      {required this.id,
      this.status_id,
      this.user_id,
      this.expires_at,
      this.created_at});

  factory _$UserSubscriptionModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserSubscriptionModelImplFromJson(json);

  @override
  final int id;
  @override
  final int? status_id;
  @override
  final int? user_id;
  @override
  final String? expires_at;
  @override
  final DateTime? created_at;

  @override
  String toString() {
    return 'UserSubscriptionModel(id: $id, status_id: $status_id, user_id: $user_id, expires_at: $expires_at, created_at: $created_at)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserSubscriptionModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.status_id, status_id) ||
                other.status_id == status_id) &&
            (identical(other.user_id, user_id) || other.user_id == user_id) &&
            (identical(other.expires_at, expires_at) ||
                other.expires_at == expires_at) &&
            (identical(other.created_at, created_at) ||
                other.created_at == created_at));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, status_id, user_id, expires_at, created_at);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserSubscriptionModelImplCopyWith<_$UserSubscriptionModelImpl>
      get copyWith => __$$UserSubscriptionModelImplCopyWithImpl<
          _$UserSubscriptionModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserSubscriptionModelImplToJson(
      this,
    );
  }
}

abstract class _UserSubscriptionModel implements UserSubscriptionModel {
  const factory _UserSubscriptionModel(
      {required final int id,
      final int? status_id,
      final int? user_id,
      final String? expires_at,
      final DateTime? created_at}) = _$UserSubscriptionModelImpl;

  factory _UserSubscriptionModel.fromJson(Map<String, dynamic> json) =
      _$UserSubscriptionModelImpl.fromJson;

  @override
  int get id;
  @override
  int? get status_id;
  @override
  int? get user_id;
  @override
  String? get expires_at;
  @override
  DateTime? get created_at;
  @override
  @JsonKey(ignore: true)
  _$$UserSubscriptionModelImplCopyWith<_$UserSubscriptionModelImpl>
      get copyWith => throw _privateConstructorUsedError;
}
