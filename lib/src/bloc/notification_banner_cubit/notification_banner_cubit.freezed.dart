// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_banner_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$NotificationBannerState {
  bool get isNotificationVisible => throw _privateConstructorUsedError;
  bool get shouldHideImmediately => throw _privateConstructorUsedError;
  NotificationType get type => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $NotificationBannerStateCopyWith<NotificationBannerState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationBannerStateCopyWith<$Res> {
  factory $NotificationBannerStateCopyWith(NotificationBannerState value,
          $Res Function(NotificationBannerState) then) =
      _$NotificationBannerStateCopyWithImpl<$Res, NotificationBannerState>;
  @useResult
  $Res call(
      {bool isNotificationVisible,
      bool shouldHideImmediately,
      NotificationType type,
      String? message});
}

/// @nodoc
class _$NotificationBannerStateCopyWithImpl<$Res,
        $Val extends NotificationBannerState>
    implements $NotificationBannerStateCopyWith<$Res> {
  _$NotificationBannerStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isNotificationVisible = null,
    Object? shouldHideImmediately = null,
    Object? type = null,
    Object? message = freezed,
  }) {
    return _then(_value.copyWith(
      isNotificationVisible: null == isNotificationVisible
          ? _value.isNotificationVisible
          : isNotificationVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      shouldHideImmediately: null == shouldHideImmediately
          ? _value.shouldHideImmediately
          : shouldHideImmediately // ignore: cast_nullable_to_non_nullable
              as bool,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as NotificationType,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NotificationBannerStateImplCopyWith<$Res>
    implements $NotificationBannerStateCopyWith<$Res> {
  factory _$$NotificationBannerStateImplCopyWith(
          _$NotificationBannerStateImpl value,
          $Res Function(_$NotificationBannerStateImpl) then) =
      __$$NotificationBannerStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isNotificationVisible,
      bool shouldHideImmediately,
      NotificationType type,
      String? message});
}

/// @nodoc
class __$$NotificationBannerStateImplCopyWithImpl<$Res>
    extends _$NotificationBannerStateCopyWithImpl<$Res,
        _$NotificationBannerStateImpl>
    implements _$$NotificationBannerStateImplCopyWith<$Res> {
  __$$NotificationBannerStateImplCopyWithImpl(
      _$NotificationBannerStateImpl _value,
      $Res Function(_$NotificationBannerStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isNotificationVisible = null,
    Object? shouldHideImmediately = null,
    Object? type = null,
    Object? message = freezed,
  }) {
    return _then(_$NotificationBannerStateImpl(
      isNotificationVisible: null == isNotificationVisible
          ? _value.isNotificationVisible
          : isNotificationVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      shouldHideImmediately: null == shouldHideImmediately
          ? _value.shouldHideImmediately
          : shouldHideImmediately // ignore: cast_nullable_to_non_nullable
              as bool,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as NotificationType,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$NotificationBannerStateImpl implements _NotificationBannerState {
  const _$NotificationBannerStateImpl(
      {this.isNotificationVisible = false,
      this.shouldHideImmediately = false,
      this.type = NotificationType.success,
      this.message = 'დაფიქსირდა შეცდომა სცადეთ მოგვიანებით'});

  @override
  @JsonKey()
  final bool isNotificationVisible;
  @override
  @JsonKey()
  final bool shouldHideImmediately;
  @override
  @JsonKey()
  final NotificationType type;
  @override
  @JsonKey()
  final String? message;

  @override
  String toString() {
    return 'NotificationBannerState(isNotificationVisible: $isNotificationVisible, shouldHideImmediately: $shouldHideImmediately, type: $type, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationBannerStateImpl &&
            (identical(other.isNotificationVisible, isNotificationVisible) ||
                other.isNotificationVisible == isNotificationVisible) &&
            (identical(other.shouldHideImmediately, shouldHideImmediately) ||
                other.shouldHideImmediately == shouldHideImmediately) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, isNotificationVisible, shouldHideImmediately, type, message);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationBannerStateImplCopyWith<_$NotificationBannerStateImpl>
      get copyWith => __$$NotificationBannerStateImplCopyWithImpl<
          _$NotificationBannerStateImpl>(this, _$identity);
}

abstract class _NotificationBannerState implements NotificationBannerState {
  const factory _NotificationBannerState(
      {final bool isNotificationVisible,
      final bool shouldHideImmediately,
      final NotificationType type,
      final String? message}) = _$NotificationBannerStateImpl;

  @override
  bool get isNotificationVisible;
  @override
  bool get shouldHideImmediately;
  @override
  NotificationType get type;
  @override
  String? get message;
  @override
  @JsonKey(ignore: true)
  _$$NotificationBannerStateImplCopyWith<_$NotificationBannerStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
