import 'package:commons/commons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_banner_state.dart';
part 'notification_banner_cubit.freezed.dart';

class NotificationBannerCubit extends Cubit<NotificationBannerState> {
  NotificationBannerCubit() : super(const NotificationBannerState());

  void showNotification(NotificationType type, String? message) {
    emit(
      state.copyWith(isNotificationVisible: true, type: type, message: message),
    );
  }

  void hideNotification({bool shouldHideImmediately = false}) {
    emit(
      state.copyWith(
        isNotificationVisible: false,
        shouldHideImmediately: shouldHideImmediately,
      ),
    );
  }

  void resetMessage() {
    emit(state.copyWith(message: null));
  }
}
