part of 'notification_banner_cubit.dart';

@freezed
class NotificationBannerState with _$NotificationBannerState {
  const factory NotificationBannerState({
    @Default(false) bool isNotificationVisible,
    @Default(false) bool shouldHideImmediately,
    @Default(NotificationType.success) NotificationType type,
    @Default('დაფიქსირდა შეცდომა სცადეთ მოგვიანებით') String? message,
  }) = _NotificationBannerState;
}
