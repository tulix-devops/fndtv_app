import 'dart:async';

import 'package:commons/commons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fndtv/src/data/data.dart';
import 'package:fndtv/src/data/models/ad_model/ad_model.dart';
import 'package:fndtv/src/data/models/content/tv_schedule_model.dart';

part 'video_player_state.dart';
part 'video_player_cubit.freezed.dart';

class VideoPlayerCubit extends Cubit<VideoPlayerState> {
  VideoPlayerCubit({
    required GetAuthTokenUseCase getAuthTokenUseCase,
  })  : _getAuthTokenUseCase = getAuthTokenUseCase,
        super(const VideoPlayerState());

  Timer? _visibilityTimer;
  final GetAuthTokenUseCase _getAuthTokenUseCase;
  void controlVisibility() {
    if (state.isVisible) {
      emit(state.copyWith(isVisible: false));
      return;
    }

    handleVisibility();
  }

  String formatDuration(Duration? duration) {
    if (duration != null) {
      String minutes = duration.inMinutes.toString().padLeft(2, '0');
      String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    }
    return '00:00';
  }

  void changeVisibility(bool visibility) {
    _visibilityTimer?.cancel();
    emit(state.copyWith(isVisible: visibility));
  }

  void setIsPlaying(bool isPlaying) {
    emit(state.copyWith(isPlaying: isPlaying));
    handleVisibility();
  }

  void lockScreen() {
    emit(state.copyWith(isLocked: !state.isLocked));
    handleVisibility();
  }

  void setVolume(double volume) {
    emit(
      state.copyWith(
        videoVolume: (currentVolume: volume, previousVolume: volume),
      ),
    );
  }

  void muteVideo() {
    double newCurrentVolume =
        !state.isMuted ? 0.0 : state.videoVolume.previousVolume;
    emit(
      state.copyWith(
        isMuted: !state.isMuted,
        videoVolume: (
          currentVolume: newCurrentVolume,
          previousVolume: state.videoVolume.previousVolume,
        ),
      ),
    );

    handleVisibility();
  }

  void videoSeekForwardTrigger(bool status) {
    emit(state.copyWith(videoIsSeekingForward: status));
  }

  void videoSeekBackWardTrigger(bool status) {
    emit(state.copyWith(videoIsRewindSeeking: status));
  }

  void handleVisibility({bool forceVisible = false}) {
    if (forceVisible) {
      _visibilityTimer?.cancel();
      emit(state.copyWith(isVisible: true));
      return;
    }
    _visibilityTimer?.cancel();

    emit(state.copyWith(isVisible: true));

    _visibilityTimer = Timer(const Duration(seconds: 6), () {
      emit(state.copyWith(isVisible: false));
    });
  }

  void reset() {
    emit(
      state.copyWith(
        isLocked: false,
        isPlaying: true,
        isMuted: false,
        isVisible: false,
        status: Status.initial,
        isAdDone: false,
      ),
    );
  }

  void selectSpeed(int index) {
    emit(state.copyWith(selectedSpeed: index));
  }

  void setPreviousVolume(double volume) {
    emit(
      state.copyWith(
        videoVolume: (
          currentVolume: state.videoVolume.currentVolume,
          previousVolume: volume,
        ),
      ),
    );
  }

  void setCurrentVolume(double volume) {
    emit(
      state.copyWith(
        videoVolume: (
          currentVolume: volume,
          previousVolume: state.videoVolume.previousVolume,
        ),
      ),
    );
  }

  void setAdDone() {
    emit(state.copyWith(isAdDone: true));
  }
}
