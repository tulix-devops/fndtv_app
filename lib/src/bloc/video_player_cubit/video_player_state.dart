part of 'video_player_cubit.dart';

@freezed
class VideoPlayerState with _$VideoPlayerState {
  const factory VideoPlayerState({
    @Default(Status.initial) Status status,
    @Default(true) bool isPlaying,
    @Default(false) bool isVisible,
    @Default(false) bool isLocked,
    @Default(false) bool isMuted,
    @Default(false) bool videoIsSeekingForward,
    @Default(false) bool videoIsRewindSeeking,
    @Default(0) int selectedSpeed,
    @Default(false) bool isAdDone,
    @Default((false, "0.00")) (bool isLive, String minutes) liveStatus,
    @Default(null) AdModel? adModel,
    @Default(null) TvScheduleModel? video,
    @Default((currentVolume: 1.0, previousVolume: 1.0))
    ({double currentVolume, double previousVolume}) videoVolume,
  }) = _VideoPlayerState;
}
