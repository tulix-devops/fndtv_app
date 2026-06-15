part of 'app_cubit.dart';

enum InitializationStatus { initial, loading, initialized }

enum ThemeStatus { switching, switched }

enum AppDialogType { none, auth, subscribe, payment }

@freezed
abstract class AppState with _$AppState {
  const AppState._();

  const factory AppState({
    @Default(AuthStatus.unauthenticated) AuthStatus authStatus,
    @Default(BottomBarTab.television) BottomBarTab currentTab,
    @Default(AppThemeColor.red) AppThemeColor themeColor,
    @Default(false) bool isOnboardingComplete,
    @Default(false) bool hasOverlay,
    // For init function tracking
    @Default(InitializationStatus.initial) InitializationStatus initializationStatus,
    @Default(Status.initial) Status userInitStatus,
    @Default(Status.initial) Status paymentStatus,
    @Default(null) String? userInfoError,
    @Default(null) CustomerInfoModel? customerInfo,
    @Default(null) ProfileModel? userInfo,
    @Default(ThemeStatus.switched) ThemeStatus themeStatus,
    @Default(false) bool canPop,
    @Default(false) bool isLogoutVisible,
    @Default(AppDialogType.none) AppDialogType appDialogType,
    @Default(false) bool isSubscribed,
  }) = _AppState;

  bool get isInitialized => initializationStatus == InitializationStatus.initialized;
  bool get isNotInitialized =>
      initializationStatus == InitializationStatus.initial || initializationStatus == InitializationStatus.loading;

  bool get isAuthenticated => authStatus == AuthStatus.authenticated;
  bool get isNotAuthenticated => authStatus == AuthStatus.unauthenticated;

  bool get hasPurchaseSetUp => customerInfo?.hasPaymentMethod ?? false;

  bool get shouldNavigateToPaymentPage => appDialogType != AppDialogType.none;
}
