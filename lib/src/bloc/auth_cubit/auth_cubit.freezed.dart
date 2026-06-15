// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AuthState {
  ({String? error, String? value}) get email =>
      throw _privateConstructorUsedError;
  ({String? error, String? value}) get password =>
      throw _privateConstructorUsedError;
  ({String? error, String? value}) get repeatPassword =>
      throw _privateConstructorUsedError;
  FormStatus get status => throw _privateConstructorUsedError;
  String? get formError => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $AuthStateCopyWith<AuthState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthStateCopyWith<$Res> {
  factory $AuthStateCopyWith(AuthState value, $Res Function(AuthState) then) =
      _$AuthStateCopyWithImpl<$Res, AuthState>;
  @useResult
  $Res call(
      {({String? error, String? value}) email,
      ({String? error, String? value}) password,
      ({String? error, String? value}) repeatPassword,
      FormStatus status,
      String? formError});
}

/// @nodoc
class _$AuthStateCopyWithImpl<$Res, $Val extends AuthState>
    implements $AuthStateCopyWith<$Res> {
  _$AuthStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? email = null,
    Object? password = null,
    Object? repeatPassword = null,
    Object? status = null,
    Object? formError = freezed,
  }) {
    return _then(_value.copyWith(
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as ({String? error, String? value}),
      password: null == password
          ? _value.password
          : password // ignore: cast_nullable_to_non_nullable
              as ({String? error, String? value}),
      repeatPassword: null == repeatPassword
          ? _value.repeatPassword
          : repeatPassword // ignore: cast_nullable_to_non_nullable
              as ({String? error, String? value}),
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as FormStatus,
      formError: freezed == formError
          ? _value.formError
          : formError // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AuthStateImplCopyWith<$Res>
    implements $AuthStateCopyWith<$Res> {
  factory _$$AuthStateImplCopyWith(
          _$AuthStateImpl value, $Res Function(_$AuthStateImpl) then) =
      __$$AuthStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {({String? error, String? value}) email,
      ({String? error, String? value}) password,
      ({String? error, String? value}) repeatPassword,
      FormStatus status,
      String? formError});
}

/// @nodoc
class __$$AuthStateImplCopyWithImpl<$Res>
    extends _$AuthStateCopyWithImpl<$Res, _$AuthStateImpl>
    implements _$$AuthStateImplCopyWith<$Res> {
  __$$AuthStateImplCopyWithImpl(
      _$AuthStateImpl _value, $Res Function(_$AuthStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? email = null,
    Object? password = null,
    Object? repeatPassword = null,
    Object? status = null,
    Object? formError = freezed,
  }) {
    return _then(_$AuthStateImpl(
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as ({String? error, String? value}),
      password: null == password
          ? _value.password
          : password // ignore: cast_nullable_to_non_nullable
              as ({String? error, String? value}),
      repeatPassword: null == repeatPassword
          ? _value.repeatPassword
          : repeatPassword // ignore: cast_nullable_to_non_nullable
              as ({String? error, String? value}),
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as FormStatus,
      formError: freezed == formError
          ? _value.formError
          : formError // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$AuthStateImpl extends _AuthState with DiagnosticableTreeMixin {
  const _$AuthStateImpl(
      {this.email = const (value: null, error: null),
      this.password = const (value: null, error: null),
      this.repeatPassword = const (value: null, error: null),
      this.status = FormStatus.initial,
      this.formError = null})
      : super._();

  @override
  @JsonKey()
  final ({String? error, String? value}) email;
  @override
  @JsonKey()
  final ({String? error, String? value}) password;
  @override
  @JsonKey()
  final ({String? error, String? value}) repeatPassword;
  @override
  @JsonKey()
  final FormStatus status;
  @override
  @JsonKey()
  final String? formError;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'AuthState(email: $email, password: $password, repeatPassword: $repeatPassword, status: $status, formError: $formError)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'AuthState'))
      ..add(DiagnosticsProperty('email', email))
      ..add(DiagnosticsProperty('password', password))
      ..add(DiagnosticsProperty('repeatPassword', repeatPassword))
      ..add(DiagnosticsProperty('status', status))
      ..add(DiagnosticsProperty('formError', formError));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthStateImpl &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.password, password) ||
                other.password == password) &&
            (identical(other.repeatPassword, repeatPassword) ||
                other.repeatPassword == repeatPassword) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.formError, formError) ||
                other.formError == formError));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, email, password, repeatPassword, status, formError);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthStateImplCopyWith<_$AuthStateImpl> get copyWith =>
      __$$AuthStateImplCopyWithImpl<_$AuthStateImpl>(this, _$identity);
}

abstract class _AuthState extends AuthState {
  const factory _AuthState(
      {final ({String? error, String? value}) email,
      final ({String? error, String? value}) password,
      final ({String? error, String? value}) repeatPassword,
      final FormStatus status,
      final String? formError}) = _$AuthStateImpl;
  const _AuthState._() : super._();

  @override
  ({String? error, String? value}) get email;
  @override
  ({String? error, String? value}) get password;
  @override
  ({String? error, String? value}) get repeatPassword;
  @override
  FormStatus get status;
  @override
  String? get formError;
  @override
  @JsonKey(ignore: true)
  _$$AuthStateImplCopyWith<_$AuthStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
