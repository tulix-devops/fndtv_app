import 'package:commons/commons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fndtv/src/data/models/channel/channel_model.dart';
import 'package:fndtv/src/data/models/channel/podcast_list_model.dart';
import 'package:fndtv/src/data/models/channel/podcast_model.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/data/models/content/tv_schedule_model.dart';
import 'package:fndtv/src/data/repositories/content/content_repository.dart';

part 'epg_state.dart';
part 'epg_cubit.freezed.dart';

class EpgCubit extends Cubit<EpgState> {
  EpgCubit({
    required ContentRepository contentDataSource,
  })  : _contentRepository = contentDataSource,
        super(const EpgState());

  final ContentRepository _contentRepository;

  void setSelectedChannel(ChannelModel channel) {
    emit(state.copyWith(selectedChannel: channel));
  }

  void setCurrentDvr(TvScheduleModel? dvr) {
    if (state.selectedDvr != dvr) {
      emit(state.copyWith(selectedDvr: dvr));
    }
  }

  Future<void> getCombinedEpg() async {
    emit(state.copyWith(status: Status.loading));

    try {
      final responses = await Future.wait([]);

      final [englishRes, spanishRes] = responses;

      if (englishRes is SuccessModel<ChannelModel> && spanishRes is SuccessModel<ChannelModel>) {
        final combinedChannels = [englishRes.data, spanishRes.data];

        emit(
          state.copyWith(epgContent: combinedChannels, status: Status.success),
        );
      } else {
        emit(state.copyWith(status: Status.failure));
      }
    } catch (e) {
      emit(state.copyWith(status: Status.serverFailure));
    }
  }
}
