// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AppState {
  AuthStatus get authStatus => throw _privateConstructorUsedError;
  BottomBarTab get currentTab => throw _privateConstructorUsedError;
  AppThemeColor get themeColor => throw _privateConstructorUsedError;
  bool get isOnboardingComplete => throw _privateConstructorUsedError;
  bool get hasOverlay =>
      throw _privateConstructorUsedError; // For init function tracking
  InitializationStatus get initializationStatus =>
      throw _privateConstructorUsedError;
  Status get userInitStatus => throw _privateConstructorUsedError;
  Status get paymentStatus => throw _privateConstructorUsedError;
  String? get userInfoError => throw _privateConstructorUsedError;
  CustomerInfoModel? get customerInfo => throw _privateConstructorUsedError;
  ProfileModel? get userInfo => throw _privateConstructorUsedError;
  ThemeStatus get themeStatus => throw _privateConstructorUsedError;
  bool get canPop => throw _privateConstructorUsedError;
  bool get isLogoutVisible => throw _privateConstructorUsedError;
  AppDialogType get appDialogType => throw _privateConstructorUsedError;
  bool get isSubscribed => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $AppStateCopyWith<AppState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppStateCopyWith<$Res> {
  factory $AppStateCopyWith(AppState value, $Res Function(AppState) then) =
      _$AppStateCopyWithImpl<$Res, AppState>;
  @useResult
  $Res call(
      {AuthStatus authStatus,
      BottomBarTab currentTab,
      AppThemeColor themeColor,
      bool isOnboardingComplete,
      bool hasOverlay,
      InitializationStatus initializationStatus,
      Status userInitStatus,
      Status paymentStatus,
      String? userInfoError,
      CustomerInfoModel? customerInfo,
      ProfileModel? userInfo,
      ThemeStatus themeStatus,
      bool canPop,
      bool isLogoutVisible,
      AppDialogType appDialogType,
      bool isSubscribed});

  $ProfileModelCopyWith<$Res>? get userInfo;
}

/// @nodoc
class _$AppStateCopyWithImpl<$Res, $Val extends AppState>
    implements $AppStateCopyWith<$Res> {
  _$AppStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? authStatus = null,
    Object? currentTab = null,
    Object? themeColor = null,
    Object? isOnboardingComplete = null,
    Object? hasOverlay = null,
    Object? initializationStatus = null,
    Object? userInitStatus = null,
    Object? paymentStatus = null,
    Object? userInfoError = freezed,
    Object? customerInfo = freezed,
    Object? userInfo = freezed,
    Object? themeStatus = null,
    Object? canPop = null,
    Object? isLogoutVisible = null,
    Object? appDialogType = null,
    Object? isSubscribed = null,
  }) {
    return _then(_value.copyWith(
      authStatus: null == authStatus
          ? _value.authStatus
          : authStatus // ignore: cast_nullable_to_non_nullable
              as AuthStatus,
      currentTab: null == currentTab
          ? _value.currentTab
          : currentTab // ignore: cast_nullable_to_non_nullable
              as BottomBarTab,
      themeColor: null == themeColor
          ? _value.themeColor
          : themeColor // ignore: cast_nullable_to_non_nullable
              as AppThemeColor,
      isOnboardingComplete: null == isOnboardingComplete
          ? _value.isOnboardingComplete
          : isOnboardingComplete // ignore: cast_nullable_to_non_nullable
              as bool,
      hasOverlay: null == hasOverlay
          ? _value.hasOverlay
          : hasOverlay // ignore: cast_nullable_to_non_nullable
              as bool,
      initializationStatus: null == initializationStatus
          ? _value.initializationStatus
          : initializationStatus // ignore: cast_nullable_to_non_nullable
              as InitializationStatus,
      userInitStatus: null == userInitStatus
          ? _value.userInitStatus
          : userInitStatus // ignore: cast_nullable_to_non_nullable
              as Status,
      paymentStatus: null == paymentStatus
          ? _value.paymentStatus
          : paymentStatus // ignore: cast_nullable_to_non_nullable
              as Status,
      userInfoError: freezed == userInfoError
          ? _value.userInfoError
          : userInfoError // ignore: cast_nullable_to_non_nullable
              as String?,
      customerInfo: freezed == customerInfo
          ? _value.customerInfo
          : customerInfo // ignore: cast_nullable_to_non_nullable
              as CustomerInfoModel?,
      userInfo: freezed == userInfo
          ? _value.userInfo
          : userInfo // ignore: cast_nullable_to_non_nullable
              as ProfileModel?,
      themeStatus: null == themeStatus
          ? _value.themeStatus
          : themeStatus // ignore: cast_nullable_to_non_nullable
              as ThemeStatus,
      canPop: null == canPop
          ? _value.canPop
          : canPop // ignore: cast_nullable_to_non_nullable
              as bool,
      isLogoutVisible: null == isLogoutVisible
          ? _value.isLogoutVisible
          : isLogoutVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      appDialogType: null == appDialogType
          ? _value.appDialogType
          : appDialogType // ignore: cast_nullable_to_non_nullable
              as AppDialogType,
      isSubscribed: null == isSubscribed
          ? _value.isSubscribed
          : isSubscribed // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $ProfileModelCopyWith<$Res>? get userInfo {
    if (_value.userInfo == null) {
      return null;
    }

    return $ProfileModelCopyWith<$Res>(_value.userInfo!, (value) {
      return _then(_value.copyWith(userInfo: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AppStateImplCopyWith<$Res>
    implements $AppStateCopyWith<$Res> {
  factory _$$AppStateImplCopyWith(
          _$AppStateImpl value, $Res Function(_$AppStateImpl) then) =
      __$$AppStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {AuthStatus authStatus,
      BottomBarTab currentTab,
      AppThemeColor themeColor,
      bool isOnboardingComplete,
      bool hasOverlay,
      InitializationStatus initializationStatus,
      Status userInitStatus,
      Status paymentStatus,
      String? userInfoError,
      CustomerInfoModel? customerInfo,
      ProfileModel? userInfo,
      ThemeStatus themeStatus,
      bool canPop,
      bool isLogoutVisible,
      AppDialogType appDialogType,
      bool isSubscribed});

  @override
  $ProfileModelCopyWith<$Res>? get userInfo;
}

/// @nodoc
class __$$AppStateImplCopyWithImpl<$Res>
    extends _$AppStateCopyWithImpl<$Res, _$AppStateImpl>
    implements _$$AppStateImplCopyWith<$Res> {
  __$$AppStateImplCopyWithImpl(
      _$AppStateImpl _value, $Res Function(_$AppStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? authStatus = null,
    Object? currentTab = null,
    Object? themeColor = null,
    Object? isOnboardingComplete = null,
    Object? hasOverlay = null,
    Object? initializationStatus = null,
    Object? userInitStatus = null,
    Object? paymentStatus = null,
    Object? userInfoError = freezed,
    Object? customerInfo = freezed,
    Object? userInfo = freezed,
    Object? themeStatus = null,
    Object? canPop = null,
    Object? isLogoutVisible = null,
    Object? appDialogType = null,
    Object? isSubscribed = null,
  }) {
    return _then(_$AppStateImpl(
      authStatus: null == authStatus
          ? _value.authStatus
          : authStatus // ignore: cast_nullable_to_non_nullable
              as AuthStatus,
      currentTab: null == currentTab
          ? _value.currentTab
          : currentTab // ignore: cast_nullable_to_non_nullable
              as BottomBarTab,
      themeColor: null == themeColor
          ? _value.themeColor
          : themeColor // ignore: cast_nullable_to_non_nullable
              as AppThemeColor,
      isOnboardingComplete: null == isOnboardingComplete
          ? _value.isOnboardingComplete
          : isOnboardingComplete // ignore: cast_nullable_to_non_nullable
              as bool,
      hasOverlay: null == hasOverlay
          ? _value.hasOverlay
          : hasOverlay // ignore: cast_nullable_to_non_nullable
              as bool,
      initializationStatus: null == initializationStatus
          ? _value.initializationStatus
          : initializationStatus // ignore: cast_nullable_to_non_nullable
              as InitializationStatus,
      userInitStatus: null == userInitStatus
          ? _value.userInitStatus
          : userInitStatus // ignore: cast_nullable_to_non_nullable
              as Status,
      paymentStatus: null == paymentStatus
          ? _value.paymentStatus
          : paymentStatus // ignore: cast_nullable_to_non_nullable
              as Status,
      userInfoError: freezed == userInfoError
          ? _value.userInfoError
          : userInfoError // ignore: cast_nullable_to_non_nullable
              as String?,
      customerInfo: freezed == customerInfo
          ? _value.customerInfo
          : customerInfo // ignore: cast_nullable_to_non_nullable
              as CustomerInfoModel?,
      userInfo: freezed == userInfo
          ? _value.userInfo
          : userInfo // ignore: cast_nullable_to_non_nullable
              as ProfileModel?,
      themeStatus: null == themeStatus
          ? _value.themeStatus
          : themeStatus // ignore: cast_nullable_to_non_nullable
              as ThemeStatus,
      canPop: null == canPop
          ? _value.canPop
          : canPop // ignore: cast_nullable_to_non_nullable
              as bool,
      isLogoutVisible: null == isLogoutVisible
          ? _value.isLogoutVisible
          : isLogoutVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      appDialogType: null == appDialogType
          ? _value.appDialogType
          : appDialogType // ignore: cast_nullable_to_non_nullable
              as AppDialogType,
      isSubscribed: null == isSubscribed
          ? _value.isSubscribed
          : isSubscribed // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$AppStateImpl extends _AppState with DiagnosticableTreeMixin {
  const _$AppStateImpl(
      {this.authStatus = AuthStatus.unauthenticated,
      this.currentTab = BottomBarTab.television,
      this.themeColor = AppThemeColor.red,
      this.isOnboardingComplete = false,
      this.hasOverlay = false,
      this.initializationStatus = InitializationStatus.initial,
      this.userInitStatus = Status.initial,
      this.paymentStatus = Status.initial,
      this.userInfoError = null,
      this.customerInfo = null,
      this.userInfo = null,
      this.themeStatus = ThemeStatus.switched,
      this.canPop = false,
      this.isLogoutVisible = false,
      this.appDialogType = AppDialogType.none,
      this.isSubscribed = false})
      : super._();

  @override
  @JsonKey()
  final AuthStatus authStatus;
  @override
  @JsonKey()
  final BottomBarTab currentTab;
  @override
  @JsonKey()
  final AppThemeColor themeColor;
  @override
  @JsonKey()
  final bool isOnboardingComplete;
  @override
  @JsonKey()
  final bool hasOverlay;
// For init function tracking
  @override
  @JsonKey()
  final InitializationStatus initializationStatus;
  @override
  @JsonKey()
  final Status userInitStatus;
  @override
  @JsonKey()
  final Status paymentStatus;
  @override
  @JsonKey()
  final String? userInfoError;
  @override
  @JsonKey()
  final CustomerInfoModel? customerInfo;
  @override
  @JsonKey()
  final ProfileModel? userInfo;
  @override
  @JsonKey()
  final ThemeStatus themeStatus;
  @override
  @JsonKey()
  final bool canPop;
  @override
  @JsonKey()
  final bool isLogoutVisible;
  @override
  @JsonKey()
  final AppDialogType appDialogType;
  @override
  @JsonKey()
  final bool isSubscribed;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'AppState(authStatus: $authStatus, currentTab: $currentTab, themeColor: $themeColor, isOnboardingComplete: $isOnboardingComplete, hasOverlay: $hasOverlay, initializationStatus: $initializationStatus, userInitStatus: $userInitStatus, paymentStatus: $paymentStatus, userInfoError: $userInfoError, customerInfo: $customerInfo, userInfo: $userInfo, themeStatus: $themeStatus, canPop: $canPop, isLogoutVisible: $isLogoutVisible, appDialogType: $appDialogType, isSubscribed: $isSubscribed)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'AppState'))
      ..add(DiagnosticsProperty('authStatus', authStatus))
      ..add(DiagnosticsProperty('currentTab', currentTab))
      ..add(DiagnosticsProperty('themeColor', themeColor))
      ..add(DiagnosticsProperty('isOnboardingComplete', isOnboardingComplete))
      ..add(DiagnosticsProperty('hasOverlay', hasOverlay))
      ..add(DiagnosticsProperty('initializationStatus', initializationStatus))
      ..add(DiagnosticsProperty('userInitStatus', userInitStatus))
      ..add(DiagnosticsProperty('paymentStatus', paymentStatus))
      ..add(DiagnosticsProperty('userInfoError', userInfoError))
      ..add(DiagnosticsProperty('customerInfo', customerInfo))
      ..add(DiagnosticsProperty('userInfo', userInfo))
      ..add(DiagnosticsProperty('themeStatus', themeStatus))
      ..add(DiagnosticsProperty('canPop', canPop))
      ..add(DiagnosticsProperty('isLogoutVisible', isLogoutVisible))
      ..add(DiagnosticsProperty('appDialogType', appDialogType))
      ..add(DiagnosticsProperty('isSubscribed', isSubscribed));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppStateImpl &&
            (identical(other.authStatus, authStatus) ||
                other.authStatus == authStatus) &&
            (identical(other.currentTab, currentTab) ||
                other.currentTab == currentTab) &&
            (identical(other.themeColor, themeColor) ||
                other.themeColor == themeColor) &&
            (identical(other.isOnboardingComplete, isOnboardingComplete) ||
                other.isOnboardingComplete == isOnboardingComplete) &&
            (identical(other.hasOverlay, hasOverlay) ||
                other.hasOverlay == hasOverlay) &&
            (identical(other.initializationStatus, initializationStatus) ||
                other.initializationStatus == initializationStatus) &&
            (identical(other.userInitStatus, userInitStatus) ||
                other.userInitStatus == userInitStatus) &&
            (identical(other.paymentStatus, paymentStatus) ||
                other.paymentStatus == paymentStatus) &&
            (identical(other.userInfoError, userInfoError) ||
                other.userInfoError == userInfoError) &&
            (identical(other.customerInfo, customerInfo) ||
                other.customerInfo == customerInfo) &&
            (identical(other.userInfo, userInfo) ||
                other.userInfo == userInfo) &&
            (identical(other.themeStatus, themeStatus) ||
                other.themeStatus == themeStatus) &&
            (identical(other.canPop, canPop) || other.canPop == canPop) &&
            (identical(other.isLogoutVisible, isLogoutVisible) ||
                other.isLogoutVisible == isLogoutVisible) &&
            (identical(other.appDialogType, appDialogType) ||
                other.appDialogType == appDialogType) &&
            (identical(other.isSubscribed, isSubscribed) ||
                other.isSubscribed == isSubscribed));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      authStatus,
      currentTab,
      themeColor,
      isOnboardingComplete,
      hasOverlay,
      initializationStatus,
      userInitStatus,
      paymentStatus,
      userInfoError,
      customerInfo,
      userInfo,
      themeStatus,
      canPop,
      isLogoutVisible,
      appDialogType,
      isSubscribed);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AppStateImplCopyWith<_$AppStateImpl> get copyWith =>
      __$$AppStateImplCopyWithImpl<_$AppStateImpl>(this, _$identity);
}

abstract class _AppState extends AppState {
  const factory _AppState(
      {final AuthStatus authStatus,
      final BottomBarTab currentTab,
      final AppThemeColor themeColor,
      final bool isOnboardingComplete,
      final bool hasOverlay,
      final InitializationStatus initializationStatus,
      final Status userInitStatus,
      final Status paymentStatus,
      final String? userInfoError,
      final CustomerInfoModel? customerInfo,
      final ProfileModel? userInfo,
      final ThemeStatus themeStatus,
      final bool canPop,
      final bool isLogoutVisible,
      final AppDialogType appDialogType,
      final bool isSubscribed}) = _$AppStateImpl;
  const _AppState._() : super._();

  @override
  AuthStatus get authStatus;
  @override
  BottomBarTab get currentTab;
  @override
  AppThemeColor get themeColor;
  @override
  bool get isOnboardingComplete;
  @override
  bool get hasOverlay;
  @override // For init function tracking
  InitializationStatus get initializationStatus;
  @override
  Status get userInitStatus;
  @override
  Status get paymentStatus;
  @override
  String? get userInfoError;
  @override
  CustomerInfoModel? get customerInfo;
  @override
  ProfileModel? get userInfo;
  @override
  ThemeStatus get themeStatus;
  @override
  bool get canPop;
  @override
  bool get isLogoutVisible;
  @override
  AppDialogType get appDialogType;
  @override
  bool get isSubscribed;
  @override
  @JsonKey(ignore: true)
  _$$AppStateImplCopyWith<_$AppStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
