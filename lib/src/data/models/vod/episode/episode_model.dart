import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fndtv/src/data/data.dart';

part 'episode_model.freezed.dart';
part 'episode_model.g.dart';

@freezed
class EpisodeModel with _$EpisodeModel {
  const factory EpisodeModel({
    required int id,
    required int videoId,
    required String title,
    required String description,
    required StorageRecordModel storageRecord,
    required int seasonNumber,
    required int episodeNumber,
    required String language,
    required String chapters,
  }) = _EpisodeModel;

  factory EpisodeModel.fromJson(Map<String, dynamic> json) =>
      _$EpisodeModelFromJson(json);

  static const empty = EpisodeModel(
    id: 0,
    videoId: 0,
    title: '',
    description: '',
    seasonNumber: 0,
    episodeNumber: 0,
    language: '',
    chapters: '',
    storageRecord: StorageRecordModel.empty,
  );
}
