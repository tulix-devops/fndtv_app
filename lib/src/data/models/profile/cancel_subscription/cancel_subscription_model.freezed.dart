// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cancel_subscription_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CancelSubscriptionModel _$CancelSubscriptionModelFromJson(
    Map<String, dynamic> json) {
  return _CancelSubscriptionModel.fromJson(json);
}

/// @nodoc
mixin _$CancelSubscriptionModel {
  String get payment => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CancelSubscriptionModelCopyWith<CancelSubscriptionModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CancelSubscriptionModelCopyWith<$Res> {
  factory $CancelSubscriptionModelCopyWith(CancelSubscriptionModel value,
          $Res Function(CancelSubscriptionModel) then) =
      _$CancelSubscriptionModelCopyWithImpl<$Res, CancelSubscriptionModel>;
  @useResult
  $Res call({String payment});
}

/// @nodoc
class _$CancelSubscriptionModelCopyWithImpl<$Res,
        $Val extends CancelSubscriptionModel>
    implements $CancelSubscriptionModelCopyWith<$Res> {
  _$CancelSubscriptionModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? payment = null,
  }) {
    return _then(_value.copyWith(
      payment: null == payment
          ? _value.payment
          : payment // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CancelSubscriptionModelImplCopyWith<$Res>
    implements $CancelSubscriptionModelCopyWith<$Res> {
  factory _$$CancelSubscriptionModelImplCopyWith(
          _$CancelSubscriptionModelImpl value,
          $Res Function(_$CancelSubscriptionModelImpl) then) =
      __$$CancelSubscriptionModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String payment});
}

/// @nodoc
class __$$CancelSubscriptionModelImplCopyWithImpl<$Res>
    extends _$CancelSubscriptionModelCopyWithImpl<$Res,
        _$CancelSubscriptionModelImpl>
    implements _$$CancelSubscriptionModelImplCopyWith<$Res> {
  __$$CancelSubscriptionModelImplCopyWithImpl(
      _$CancelSubscriptionModelImpl _value,
      $Res Function(_$CancelSubscriptionModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? payment = null,
  }) {
    return _then(_$CancelSubscriptionModelImpl(
      payment: null == payment
          ? _value.payment
          : payment // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CancelSubscriptionModelImpl implements _CancelSubscriptionModel {
  const _$CancelSubscriptionModelImpl({this.payment = ''});

  factory _$CancelSubscriptionModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CancelSubscriptionModelImplFromJson(json);

  @override
  @JsonKey()
  final String payment;

  @override
  String toString() {
    return 'CancelSubscriptionModel(payment: $payment)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CancelSubscriptionModelImpl &&
            (identical(other.payment, payment) || other.payment == payment));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, payment);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CancelSubscriptionModelImplCopyWith<_$CancelSubscriptionModelImpl>
      get copyWith => __$$CancelSubscriptionModelImplCopyWithImpl<
          _$CancelSubscriptionModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CancelSubscriptionModelImplToJson(
      this,
    );
  }
}

abstract class _CancelSubscriptionModel implements CancelSubscriptionModel {
  const factory _CancelSubscriptionModel({final String payment}) =
      _$CancelSubscriptionModelImpl;

  factory _CancelSubscriptionModel.fromJson(Map<String, dynamic> json) =
      _$CancelSubscriptionModelImpl.fromJson;

  @override
  String get payment;
  @override
  @JsonKey(ignore: true)
  _$$CancelSubscriptionModelImplCopyWith<_$CancelSubscriptionModelImpl>
      get copyWith => throw _privateConstructorUsedError;
}
