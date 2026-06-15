part of 'epg_cubit.dart';

@freezed
class EpgState with _$EpgState {
  const EpgState._();
  const factory EpgState({
    @Default(Status.initial) Status status,
    @Default(null) TvScheduleModel? selectedDvr,
    @Default(null) List<ChannelModel>? epgContent,
    @Default(null) List<PodcastModel>? podcasts,
    @Default(null) ChannelModel? selectedChannel,
  }) = _EpgState;
}
